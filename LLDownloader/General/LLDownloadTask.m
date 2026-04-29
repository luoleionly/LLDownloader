//
//  LLDownloadTask.m
//  LLDownloader
//

#import "LLDownloadTask.h"
#import "LLDownloadTask+Internal.h"
#import "LLTask+Internal.h"
#import "LLSessionManager.h"
#import "LLSessionDelegate.h"
#import "LLCache.h"
#import "LLResumeDataHelper.h"
#import "LLFileChecksumHelper.h"
#import "LLError.h"
#import "LLCommon.h"
#import "LLNotifications.h"
#import "LLExecuter.h"
#import "NSArray+LLSafe.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

static NSString *const kFileCompletedCountKey = @"fileCompletedCountKey";

@interface LLDownloadTask () {
    LLUnfairLock *_downloadLock;
    NSURLSessionDownloadTask *_sessionTask_;
    NSHTTPURLResponse *_response_;
    NSData *_resumeData_;
    NSString *_tmpFileName_;
    BOOL _shouldValidateFile_;
}
@end

@implementation LLDownloadTask

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithURL:(NSURL *)url
                    headers:(NSDictionary<NSString *,NSString *> *)headers
                   fileName:(NSString *)fileName
                      cache:(LLCache *)cache
             operationQueue:(dispatch_queue_t)operationQueue {
    if ((self = [super initWithURL:url headers:headers cache:cache operationQueue:operationQueue])) {
        _downloadLock = [[LLUnfairLock alloc] init];
        if (fileName.length > 0) {
            self.fileName = fileName;
        }
#if __has_include(<UIKit/UIKit.h>) && !TARGET_OS_OSX
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fixDelegateMethodError)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
#endif
    }
    return self;
}

- (void)dealloc {
    NSURLSessionDownloadTask *t = _sessionTask_;
    @try { [t removeObserver:self forKeyPath:@"currentRequest"]; } @catch (__unused id e) {}
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)fixDelegateMethodError {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.sessionTask suspend];
        [self.sessionTask resume];
    });
}

#pragma mark - properties (lock-protected)

- (NSURLSessionDownloadTask *)sessionTask {
    __block NSURLSessionDownloadTask *t;
    [_downloadLock around:^{ t = self->_sessionTask_; }];
    return t;
}

- (void)setSessionTask:(NSURLSessionDownloadTask *)sessionTask {
    [_downloadLock around:^{
        if (self->_sessionTask_) {
            @try { [self->_sessionTask_ removeObserver:self forKeyPath:@"currentRequest"]; } @catch (__unused id e) {}
        }
        self->_sessionTask_ = sessionTask;
        if (sessionTask) {
            [sessionTask addObserver:self forKeyPath:@"currentRequest" options:NSKeyValueObservingOptionNew context:NULL];
            sessionTask.ll_task = self;
        }
    }];
}

- (NSHTTPURLResponse *)response {
    __block NSHTTPURLResponse *r;
    [_downloadLock around:^{ r = self->_response_; }];
    return r;
}

- (void)setResponse:(NSHTTPURLResponse *)response {
    [_downloadLock around:^{ self->_response_ = response; }];
}

- (NSData *)resumeData {
    __block NSData *d;
    [_downloadLock around:^{ d = self->_resumeData_; }];
    return d;
}

- (void)setResumeData:(NSData *)resumeData {
    [_downloadLock around:^{
        self->_resumeData_ = resumeData;
        if (resumeData) {
            self->_tmpFileName_ = [[LLResumeDataHelper getTmpFileName:resumeData] copy];
        }
    }];
}

- (NSString *)tmpFileName {
    __block NSString *s;
    [_downloadLock around:^{ s = self->_tmpFileName_; }];
    return s;
}

- (BOOL)shouldValidateFile {
    __block BOOL v;
    [_downloadLock around:^{ v = self->_shouldValidateFile_; }];
    return v;
}

- (void)setShouldValidateFile:(BOOL)shouldValidateFile {
    [_downloadLock around:^{ self->_shouldValidateFile_ = shouldValidateFile; }];
}

- (NSString *)filePath { return [self.cache filePathForFileName:self.fileName]; }

- (NSString *)pathExtension {
    NSString *ext = [self.filePath pathExtension];
    return ext.length ? ext : nil;
}

#pragma mark - NSSecureCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    NSData *rd = self.resumeData;
    if (rd) [coder encodeObject:rd forKey:@"resumeData"];
    NSHTTPURLResponse *resp = self.response;
    if (resp) {
        NSError *err = nil;
        NSData *respData = [NSKeyedArchiver archivedDataWithRootObject:resp
                                                 requiringSecureCoding:YES error:&err];
        if (respData) [coder encodeObject:respData forKey:@"response"];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        _downloadLock = [[LLUnfairLock alloc] init];
        NSData *rd = [coder decodeObjectOfClass:[NSData class] forKey:@"resumeData"];
        if (rd) self.resumeData = rd;
        NSData *respData = [coder decodeObjectOfClass:[NSData class] forKey:@"response"];
        if (respData) {
            NSError *err = nil;
            NSHTTPURLResponse *r = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSHTTPURLResponse class]
                                                                     fromData:respData error:&err];
            if (r) self.response = r;
        }
    }
    return self;
}

#pragma mark - execute hook

- (void)_executeExecuter:(LLExecuter *)executer {
    [executer execute:self];
}

#pragma mark - control

- (void)download {
    [self.cache createDirectory];
    LLSessionManager *manager = self.manager;
    if (!manager) return;
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWaiting] ||
        [s isEqualToString:LLStatusSuspended] ||
        [s isEqualToString:LLStatusFailed]) {
        if ([self.cache fileExistsWithFileName:self.fileName]) {
            [self prepareForDownloadFileExists:YES];
        } else {
            if ([manager shouldRun]) {
                [self prepareForDownloadFileExists:NO];
            } else {
                self.status = LLStatusWaiting;
                [self.progressExecuter execute:self];
                [self executeControl];
            }
        }
    } else if ([s isEqualToString:LLStatusSucceeded]) {
        [self executeControl];
        [self succeededFromRunning:NO immediately:NO];
    } else if ([s isEqualToString:LLStatusRunning]) {
        self.status = LLStatusRunning;
        [self executeControl];
    }
}

- (void)prepareForDownloadFileExists:(BOOL)fileExists {
    self.status = LLStatusRunning;
    [self _withState:^{
        self->_speed_ = 0;
        if (self->_startDate_ == 0) {
            self->_startDate_ = [[NSDate date] timeIntervalSince1970];
        }
    }];
    self.error = nil;
    self.response = nil;
    [self startFileExists:fileExists];
}

- (void)startFileExists:(BOOL)fileExists {
    if (fileExists) {
        [self.manager log:[LLLogType downloadTaskLogWithMessage:@"file already exists" task:self]];
        NSString *p = [self.cache filePathForFileName:self.fileName];
        if (p) {
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:p error:NULL];
            NSNumber *size = attrs[NSFileSize];
            if (size) self.progress.totalUnitCount = size.longLongValue;
        }
        [self executeControl];
        dispatch_async(self.operationQueue, ^{ [self didCompleteLocal]; });
    } else {
        NSData *rd = self.resumeData;
        if (rd && [self.cache retrieveTmpFile:self.tmpFileName]) {
            self.sessionTask = [self.session downloadTaskWithResumeData:rd];
        } else {
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.url
                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                timeoutInterval:0];
            NSDictionary *h = self.headers;
            if (h) req.allHTTPHeaderFields = h;
            self.sessionTask = [self.session downloadTaskWithRequest:req];
            self.progress.completedUnitCount = 0;
            self.progress.totalUnitCount = 0;
        }
        [self.progress setUserInfoObject:@(self.progress.completedUnitCount) forKey:kFileCompletedCountKey];
        [self.sessionTask resume];
        [self.manager maintainAppendRunningTask:self];
        [self.manager storeTasks];
        [self executeControl];
    }
}

- (void)suspendOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    LLStatus s = self.status;
    if (!([s isEqualToString:LLStatusRunning] || [s isEqualToString:LLStatusWaiting])) return;
    self.controlExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    if ([s isEqualToString:LLStatusRunning]) {
        self.status = LLStatusWillSuspend;
        [self.sessionTask cancelByProducingResumeData:^(NSData *_Nullable rd) {}];
    } else {
        self.status = LLStatusWillSuspend;
        dispatch_async(self.operationQueue, ^{ [self didCompleteLocal]; });
    }
}

- (void)cancelOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusSucceeded]) return;
    self.controlExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    if ([s isEqualToString:LLStatusRunning]) {
        self.status = LLStatusWillCancel;
        [self.sessionTask cancel];
    } else if (![s isEqualToString:LLStatusWillSuspend] &&
               ![s isEqualToString:LLStatusWillCancel] &&
               ![s isEqualToString:LLStatusWillRemove]) {
        self.status = LLStatusWillCancel;
        dispatch_async(self.operationQueue, ^{ [self didCompleteLocal]; });
    }
}

- (void)removeCompletely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    self.isRemoveCompletely = completely;
    self.controlExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusRunning]) {
        self.status = LLStatusWillRemove;
        [self.sessionTask cancel];
    } else if (![s isEqualToString:LLStatusWillSuspend] &&
               ![s isEqualToString:LLStatusWillCancel] &&
               ![s isEqualToString:LLStatusWillRemove]) {
        self.status = LLStatusWillRemove;
        dispatch_async(self.operationQueue, ^{ [self didCompleteLocal]; });
    }
}

- (void)updateHeaders:(NSDictionary<NSString *,NSString *> *)newHeaders newFileName:(NSString *)newFileName {
    self.headers = newHeaders;
    if (newFileName.length > 0) {
        [self.cache updateFileName:self.filePath newFileName:newFileName];
        self.fileName = newFileName;
    }
}

- (void)validateFile {
    LLExecuter *ve = self.validateExecuter;
    if (!ve) return;
    if (!self.shouldValidateFile) { [ve execute:self]; return; }
    NSString *code = self.verificationCode;
    if (!code) return;
    __weak typeof(self) wself = self;
    [LLFileChecksumHelper validateFileAtPath:self.filePath
                                         code:code
                                         type:self.verificationType
                                   completion:^(BOOL success, NSError * _Nullable err) {
        __strong typeof(wself) self_ = wself;
        if (!self_) return;
        self_.shouldValidateFile = NO;
        if (!success) {
            self_.validation = LLValidationIncorrect;
            [self_.manager log:[LLLogType errorLogWithMessage:[NSString stringWithFormat:@"file validation failed, url: %@", self_.url]
                                                          error:err]];
        } else {
            self_.validation = LLValidationCorrect;
            [self_.manager log:[LLLogType downloadTaskLogWithMessage:@"file validation successful" task:self_]];
        }
        [self_.manager storeTasks];
        [ve execute:self_];
    }];
}

- (LLDownloadTask *)validateFileWithCode:(NSString *)code
                                     type:(LLVerificationType)type
                              onMainQueue:(BOOL)onMainQueue
                                  handler:(void (^)(LLDownloadTask *))handler {
    __weak typeof(self) wself = self;
    dispatch_async(self.operationQueue, ^{
        __strong typeof(wself) self_ = wself;
        if (!self_) return;
        NSString *currentCode = self_.verificationCode;
        LLVerificationType currentType = self_.verificationType;
        if ([currentCode isEqualToString:code] && currentType == type && self_.validation != LLValidationUnknown) {
            self_.shouldValidateFile = NO;
        } else {
            self_.shouldValidateFile = YES;
            self_.verificationCode = code;
            self_.verificationType = type;
            [self_.manager storeTasks];
        }
        self_.validateExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
        if ([self_.status isEqualToString:LLStatusSucceeded]) {
            [self_ validateFile];
        }
    });
    return self;
}

#pragma mark - status handling

- (void)didCancelOrRemove {
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWillCancel]) self.status = LLStatusCanceled;
    if ([s isEqualToString:LLStatusWillRemove]) self.status = LLStatusRemoved;
    [self.cache removeTask:self completely:self.isRemoveCompletely];
    [self.manager didCancelOrRemove:self];
}

- (void)succeededFromRunning:(BOOL)fromRunning immediately:(BOOL)immediately {
    if (self.endDate == 0) {
        [self _withState:^{
            self->_endDate_ = [[NSDate date] timeIntervalSince1970];
            self->_timeRemaining_ = 0;
        }];
    }
    self.status = LLStatusSucceeded;
    self.progress.completedUnitCount = self.progress.totalUnitCount;
    [self.progressExecuter execute:self];
    if (immediately) {
        [self executeCompletionSucceeded:YES];
    }
    [self validateFile];
    [self.manager maintainSucceededTask:self];
    [self.manager determineStatusFromRunningTask:fromRunning];
}

- (void)determineStatusWithKind:(LLInterruptKind)kind
                          error:(NSError *)error
                     statusCode:(NSInteger)statusCode
                fromRunningTask:(BOOL)fromRunningTaskIfManual {
    BOOL fromRunning = YES;
    switch (kind) {
        case LLInterruptKindError: {
            self.error = error;
            LLStatus temp = self.status;
            NSData *rd = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if ([rd isKindOfClass:[NSData class]]) {
                self.resumeData = rd;
                [self.cache storeTmpFile:self.tmpFileName];
            }
            if (error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey]) {
                temp = LLStatusSuspended;
            }
            if ([error.domain isEqualToString:NSURLErrorDomain] && error.code != NSURLErrorCancelled) {
                temp = LLStatusFailed;
            }
            self.status = temp;
            break;
        }
        case LLInterruptKindStatusCode:
            self.error = [LLError unacceptableStatusCode:statusCode];
            self.status = LLStatusFailed;
            break;
        case LLInterruptKindManual:
            fromRunning = fromRunningTaskIfManual;
            break;
    }

    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWillSuspend]) {
        self.status = LLStatusSuspended;
        [self.progressExecuter execute:self];
        [self executeControl];
        [self executeCompletionSucceeded:NO];
    } else if ([s isEqualToString:LLStatusWillCancel] || [s isEqualToString:LLStatusWillRemove]) {
        [self didCancelOrRemove];
        [self executeControl];
        [self executeCompletionSucceeded:NO];
    } else if ([s isEqualToString:LLStatusSuspended] || [s isEqualToString:LLStatusFailed]) {
        [self.progressExecuter execute:self];
        [self executeCompletionSucceeded:NO];
    } else {
        self.status = LLStatusFailed;
        [self.progressExecuter execute:self];
        [self executeCompletionSucceeded:NO];
    }
    [self.manager determineStatusFromRunningTask:fromRunning];
}

- (void)executeCompletionSucceeded:(BOOL)isSucceeded {
    LLExecuter *ce = self.completionExecuter;
    if (ce) {
        [ce execute:self];
    } else if (isSucceeded) {
        [self.successExecuter execute:self];
    } else {
        [self.failureExecuter execute:self];
    }
    [[NSNotificationCenter defaultCenter] ll_postNotificationName:LLDownloadTaskDidCompleteNotification downloadTask:self];
}

- (void)executeControl {
    [self.controlExecuter execute:self];
    self.controlExecuter = nil;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"currentRequest"]) {
        NSURLRequest *r = change[NSKeyValueChangeNewKey];
        if ([r isKindOfClass:[NSURLRequest class]] && r.URL) {
            self.currentURL = r.URL;
            [self.manager updateUrlMapperWithTask:self];
        }
    }
}

#pragma mark - speed/time

- (void)updateSpeedAndTimeRemaining {
    int64_t dataCount = self.progress.completedUnitCount;
    NSNumber *last = self.progress.userInfo[kFileCompletedCountKey];
    int64_t lastVal = last ? last.longLongValue : 0;
    if (dataCount > lastVal) {
        int64_t speed = dataCount - lastVal;
        [self updateTimeRemaining:speed];
    }
    [self.progress setUserInfoObject:@(dataCount) forKey:kFileCompletedCountKey];
}

- (void)updateTimeRemaining:(int64_t)speed {
    double timeRemaining;
    if (speed != 0) {
        timeRemaining = ((double)self.progress.totalUnitCount - (double)self.progress.completedUnitCount) / (double)speed;
        if (timeRemaining >= 0.8 && timeRemaining < 1) timeRemaining += 1;
    } else {
        timeRemaining = 0;
    }
    [self _withState:^{
        self->_speed_ = speed;
        self->_timeRemaining_ = (int64_t)timeRemaining;
    }];
}

#pragma mark - callbacks from delegate

- (void)didWriteDataOnDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                      bytesWritten:(int64_t)bytesWritten
                 totalBytesWritten:(int64_t)totalBytesWritten
         totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.progress.completedUnitCount = totalBytesWritten;
    self.progress.totalUnitCount = totalBytesExpectedToWrite;
    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.response = (NSHTTPURLResponse *)downloadTask.response;
    }
    [self.progressExecuter execute:self];
    [self.manager updateProgress];
    [[NSNotificationCenter defaultCenter] ll_postNotificationName:LLDownloadTaskRunningNotification downloadTask:self];
}

- (void)didFinishDownloading:(NSURLSessionDownloadTask *)task toLocation:(NSURL *)location {
    NSInteger statusCode = -1;
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    }
    if (statusCode < 200 || statusCode >= 300) return;
    [self.cache storeFileAtURL:location toURL:[NSURL fileURLWithPath:self.filePath]];
    [self.cache removeTmpFile:self.tmpFileName];
}

- (void)didCompleteLocal {
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWillSuspend] ||
        [s isEqualToString:LLStatusWillCancel] ||
        [s isEqualToString:LLStatusWillRemove]) {
        [self determineStatusWithKind:LLInterruptKindManual error:nil statusCode:0 fromRunningTask:NO];
    } else if ([s isEqualToString:LLStatusRunning]) {
        [self succeededFromRunning:NO immediately:YES];
    }
}

- (void)didCompleteNetwork:(NSURLSessionTask *)task error:(NSError *)error {
    [self.manager maintainRemoveRunningTask:self];
    self.sessionTask = nil;

    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWillCancel] || [s isEqualToString:LLStatusWillRemove]) {
        [self determineStatusWithKind:LLInterruptKindManual error:nil statusCode:0 fromRunningTask:YES];
        return;
    }
    if ([s isEqualToString:LLStatusWillSuspend] || [s isEqualToString:LLStatusRunning]) {
        self.progress.totalUnitCount = task.countOfBytesExpectedToReceive;
        self.progress.completedUnitCount = task.countOfBytesReceived;
        [self.progress setUserInfoObject:@(task.countOfBytesReceived) forKey:kFileCompletedCountKey];
        NSInteger statusCode = -1;
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
        }
        BOOL isAcceptable = (statusCode >= 200 && statusCode < 300);
        if (error) {
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                self.response = (NSHTTPURLResponse *)task.response;
            }
            [self determineStatusWithKind:LLInterruptKindError error:error statusCode:0 fromRunningTask:YES];
        } else if (!isAcceptable) {
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                self.response = (NSHTTPURLResponse *)task.response;
            }
            [self determineStatusWithKind:LLInterruptKindStatusCode error:nil statusCode:statusCode fromRunningTask:YES];
        } else {
            self.resumeData = nil;
            [self succeededFromRunning:YES immediately:YES];
        }
    }
}

@end

#pragma mark - NSArray batch helpers

@implementation NSArray (LLDownloadTaskBatch)

- (NSArray<LLDownloadTask *> *)ll_onProgress:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    for (id t in self) { if ([t isKindOfClass:[LLDownloadTask class]]) [(LLDownloadTask *)t onProgress:onMainQueue handler:(void (^)(id))handler]; }
    return (NSArray<LLDownloadTask *> *)self;
}
- (NSArray<LLDownloadTask *> *)ll_onSuccess:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    for (id t in self) { if ([t isKindOfClass:[LLDownloadTask class]]) [(LLDownloadTask *)t onSuccess:onMainQueue handler:(void (^)(id))handler]; }
    return (NSArray<LLDownloadTask *> *)self;
}
- (NSArray<LLDownloadTask *> *)ll_onFailure:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    for (id t in self) { if ([t isKindOfClass:[LLDownloadTask class]]) [(LLDownloadTask *)t onFailure:onMainQueue handler:(void (^)(id))handler]; }
    return (NSArray<LLDownloadTask *> *)self;
}
- (NSArray<LLDownloadTask *> *)ll_validateFileWithCodes:(NSArray<NSString *> *)codes
                                                     type:(LLVerificationType)type
                                              onMainQueue:(BOOL)onMainQueue
                                                  handler:(void (^)(LLDownloadTask *))handler {
    NSInteger i = 0;
    for (id t in self) {
        if ([t isKindOfClass:[LLDownloadTask class]]) {
            NSString *code = [codes ll_safeObjectAtIndex:i];
            if (code) {
                [(LLDownloadTask *)t validateFileWithCode:code type:type onMainQueue:onMainQueue handler:handler];
            }
        }
        i++;
    }
    return (NSArray<LLDownloadTask *> *)self;
}

@end
