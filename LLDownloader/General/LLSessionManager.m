//
//  LLSessionManager.m
//  LLDownloader
//

#import "LLSessionManager.h"
#import "LLSessionDelegate.h"
#import "LLDownloadTask.h"
#import "LLDownloadTask+Internal.h"
#import "LLTask+Internal.h"
#import "LLCache.h"
#import "LLProtected.h"
#import "LLExecuter.h"
#import "LLError.h"
#import "LLNotifications.h"
#import "NSString+LLURL.h"
#import "NSNumber+LLTaskInfo.h"
#import "NSArray+LLSafe.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

static NSTimeInterval const kRefreshInterval = 1.0;

@interface LLSessionManager () {
    // Lock-protected state.
    LLUnfairLock *_lock;
    LLSessionConfiguration *_configuration_;
    NSURLSession *_session_;
    BOOL _shouldCreatSession_;
    dispatch_source_t _timer_;
    LLStatus _status_;
    NSMutableArray<LLDownloadTask *> *_tasks_;
    NSMutableDictionary<NSString *, LLDownloadTask *> *_taskMapper_;
    NSMutableDictionary<NSURL *, NSURL *> *_urlMapper_;
    NSMutableArray<LLDownloadTask *> *_runningTasks_;
    NSMutableArray<LLDownloadTask *> *_restartTasks_;
    NSMutableArray<LLDownloadTask *> *_succeededTasks_;
    int64_t _speed_;
    int64_t _timeRemaining_;
    LLExecuter *_progressExecuter_;
    LLExecuter *_successExecuter_;
    LLExecuter *_failureExecuter_;
    LLExecuter *_completionExecuter_;
    LLExecuter *_controlExecuter_;

    NSProgress *_progress;
}
@end

@implementation LLSessionManager

#pragma mark - init

- (instancetype)initWithIdentifier:(NSString *)identifier configuration:(LLSessionConfiguration *)configuration {
    return [self initWithIdentifier:identifier configuration:configuration logger:nil cache:nil operationQueue:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                     configuration:(LLSessionConfiguration *)configuration
                            logger:(id<LLLogable>)logger
                             cache:(LLCache *)cache
                    operationQueue:(dispatch_queue_t)operationQueue {
    if ((self = [super init])) {
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier ?: @"com.Daniels.LL";
        _identifier = [[NSString stringWithFormat:@"%@.%@", bundleIdentifier, identifier] copy];
        _lock = [[LLUnfairLock alloc] init];
        _configuration_ = [configuration copy];
        _status_ = LLStatusWaiting;
        _tasks_ = [NSMutableArray array];
        _taskMapper_ = [NSMutableDictionary dictionary];
        _urlMapper_ = [NSMutableDictionary dictionary];
        _runningTasks_ = [NSMutableArray array];
        _restartTasks_ = [NSMutableArray array];
        _succeededTasks_ = [NSMutableArray array];
        _logger = logger ?: [[LLLogger alloc] initWithIdentifier:_identifier option:LLLogOptionDefault];
        _isControlNetworkActivityIndicator = YES;
        _progress = [NSProgress progressWithTotalUnitCount:0];

        _operationQueue = operationQueue ?: dispatch_queue_create("com.LL.SessionManager.operationQueue", DISPATCH_QUEUE_SERIAL);
        _cache = cache ?: [[LLCache alloc] initWithIdentifier:identifier];
        _cache.manager = self;

        for (LLDownloadTask *t in [_cache retrieveAllTasks]) {
            [self maintainAppendTask:t];
        }
        NSMutableArray *succ = [NSMutableArray array];
        for (LLDownloadTask *t in _tasks_) {
            if ([t.status isEqualToString:LLStatusSucceeded]) [succ addObject:t];
        }
        [_lock around:^{ self->_succeededTasks_ = succ; }];
        [self log:[LLLogType sessionManagerLogWithMessage:@"retrieveTasks" manager:self]];

        [_lock around:^{
            for (LLDownloadTask *t in self->_tasks_) {
                t.manager = self;
                t.operationQueue = self->_operationQueue;
                self->_urlMapper_[t.currentURL] = t.url;
            }
            self->_shouldCreatSession_ = YES;
        }];
        dispatch_sync(_operationQueue, ^{
            [self createSessionCompletion:nil];
            [self restoreStatus];
        });
    }
    return self;
}

- (void)dealloc { [self invalidate]; }

- (void)invalidate {
    NSURLSession *s = [self _session];
    [s invalidateAndCancel];
    [self _setSession:nil];
    [_cache invalidate];
    [self invalidateTimer];
}

#pragma mark - locked accessors

- (LLSessionConfiguration *)configuration {
    __block LLSessionConfiguration *c;
    [_lock around:^{ c = [self->_configuration_ copy]; }];
    return c;
}

- (void)setConfiguration:(LLSessionConfiguration *)configuration {
    dispatch_sync(_operationQueue, ^{
        __block BOOL wasRunning = NO;
        __block LLSessionConfiguration *oldValue = nil;
        [self->_lock around:^{
            oldValue = self->_configuration_;
            self->_configuration_ = [configuration copy];
            if (self->_shouldCreatSession_) return;
            self->_shouldCreatSession_ = YES;
            if ([self->_status_ isEqualToString:LLStatusRunning]) {
                NSMutableArray *restart = [NSMutableArray array];
                if (configuration.maxConcurrentTasksLimit <= oldValue.maxConcurrentTasksLimit) {
                    [restart addObjectsFromArray:self->_runningTasks_];
                    for (LLDownloadTask *t in self->_tasks_) if ([t.status isEqualToString:LLStatusWaiting]) [restart addObject:t];
                } else {
                    for (LLDownloadTask *t in self->_tasks_) {
                        if ([t.status isEqualToString:LLStatusWaiting] || [t.status isEqualToString:LLStatusRunning]) [restart addObject:t];
                    }
                }
                self->_restartTasks_ = restart;
                wasRunning = YES;
            } else {
                [self->_session_ invalidateAndCancel];
                self->_session_ = nil;
            }
        }];
        if (wasRunning) {
            [self totalSuspendOnMainQueue:YES handler:nil];
        }
    });
}

- (NSURLSession *)_session { __block NSURLSession *s; [_lock around:^{ s = self->_session_; }]; return s; }
- (void)_setSession:(NSURLSession *)s { [_lock around:^{ self->_session_ = s; }]; }

- (BOOL)_shouldCreatSession { __block BOOL v; [_lock around:^{ v = self->_shouldCreatSession_; }]; return v; }

- (LLStatus)status { __block LLStatus s; [_lock around:^{ s = self->_status_; }]; return s; }
- (void)_setStatusSilently:(LLStatus)status { [_lock around:^{ self->_status_ = [status copy]; }]; }
- (void)setStatus:(LLStatus)status {
    [_lock around:^{ self->_status_ = [status copy]; }];
    if ([status isEqualToString:LLStatusWillSuspend] ||
        [status isEqualToString:LLStatusWillCancel] ||
        [status isEqualToString:LLStatusWillRemove]) return;
    [self log:[LLLogType sessionManagerLogWithMessage:status manager:self]];
}

- (NSArray<LLDownloadTask *> *)tasks {
    __block NSArray *t;
    [_lock around:^{ t = [self->_tasks_ copy]; }];
    return t;
}

- (NSArray<LLDownloadTask *> *)succeededTasks {
    __block NSArray *t;
    [_lock around:^{ t = [self->_succeededTasks_ copy]; }];
    return t;
}

- (NSProgress *)progress {
    __block int64_t total = 0, done = 0;
    [_lock around:^{
        for (LLDownloadTask *t in self->_tasks_) {
            total += t.progress.totalUnitCount;
            done += t.progress.completedUnitCount;
        }
    }];
    _progress.totalUnitCount = total;
    _progress.completedUnitCount = done;
    return _progress;
}

- (int64_t)speed { __block int64_t v; [_lock around:^{ v = self->_speed_; }]; return v; }
- (int64_t)timeRemaining { __block int64_t v; [_lock around:^{ v = self->_timeRemaining_; }]; return v; }
- (NSString *)speedString { return [@(self.speed) ll_convertSpeedToString]; }
- (NSString *)timeRemainingString { return [@(self.timeRemaining) ll_convertTimeToString]; }

- (BOOL)shouldRun {
    __block NSInteger running; __block NSInteger limit;
    [_lock around:^{ running = self->_runningTasks_.count; limit = self->_configuration_.maxConcurrentTasksLimit; }];
    return running < limit;
}

#pragma mark - session

- (void)createSessionCompletion:(dispatch_block_t)completion {
    if (![self _shouldCreatSession]) return;
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
    LLSessionConfiguration *my = self.configuration;
    cfg.timeoutIntervalForRequest = my.timeoutIntervalForRequest;
    cfg.HTTPMaximumConnectionsPerHost = 100000;
    cfg.allowsCellularAccess = my.allowsCellularAccess;
    if (@available(iOS 13.0, macOS 10.15, *)) {
        cfg.allowsConstrainedNetworkAccess = my.allowsConstrainedNetworkAccess;
        cfg.allowsExpensiveNetworkAccess = my.allowsExpensiveNetworkAccess;
    }
    LLSessionDelegate *delegate = [[LLSessionDelegate alloc] init];
    delegate.manager = self;
    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    q.maxConcurrentOperationCount = 1;
    q.underlyingQueue = _operationQueue;
    q.name = @"com.LL.SessionManager.delegateQueue";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg delegate:delegate delegateQueue:q];
    [_lock around:^{
        self->_session_ = session;
        for (LLDownloadTask *t in self->_tasks_) t.session = session;
        self->_shouldCreatSession_ = NO;
    }];
    if (completion) completion();
}

#pragma mark - download

- (LLDownloadTask *)downloadWithURL:(id)url {
    return [self downloadWithURL:url headers:nil fileName:nil onMainQueue:YES handler:nil];
}

- (LLDownloadTask *)downloadWithURL:(id)url
                             headers:(NSDictionary<NSString *,NSString *> *)headers
                            fileName:(NSString *)fileName
                         onMainQueue:(BOOL)onMainQueue
                             handler:(void (^)(LLDownloadTask *))handler {
    NSError *err = nil;
    NSURL *validURL = LLAsURL(url, &err);
    if (!validURL) {
        [self log:[LLLogType errorLogWithMessage:@"create dowloadTask failed" error:err ?: [LLError invalidURLWithURL:url]]];
        return nil;
    }
    __block LLDownloadTask *task = nil;
    dispatch_sync(_operationQueue, ^{
        task = [self fetchTaskForURL:validURL];
        if (task) {
            [task updateHeaders:headers newFileName:fileName];
        } else {
            task = [[LLDownloadTask alloc] initWithURL:validURL
                                                headers:headers
                                               fileName:fileName
                                                  cache:self.cache
                                         operationQueue:self->_operationQueue];
            task.manager = self;
            task.session = [self _session];
            [self maintainAppendTask:task];
        }
        [self storeTasks];
        [self _startTask:task onMainQueue:onMainQueue handler:handler];
    });
    return task;
}

- (NSArray<LLDownloadTask *> *)multiDownloadWithURLs:(NSArray *)urls
                                         headersArray:(NSArray<NSDictionary<NSString *,NSString *> *> *)headersArray
                                            fileNames:(NSArray<NSString *> *)fileNames
                                          onMainQueue:(BOOL)onMainQueue
                                              handler:(void (^)(LLSessionManager *))handler {
    if (headersArray.count != 0 && headersArray.count != urls.count) {
        [self log:[LLLogType errorLogWithMessage:@"create multiple dowloadTasks failed" error:[LLError headersMatchFailed]]];
        return @[];
    }
    if (fileNames.count != 0 && fileNames.count != urls.count) {
        [self log:[LLLogType errorLogWithMessage:@"create multiple dowloadTasks failed" error:[LLError fileNamesMatchFailed]]];
        return @[];
    }
    NSMutableSet<NSURL *> *urlSet = [NSMutableSet set];
    NSMutableArray<LLDownloadTask *> *uniqueTasks = [NSMutableArray array];
    dispatch_sync(_operationQueue, ^{
        NSInteger i = 0;
        for (id raw in urls) {
            NSString *fileName = [fileNames ll_safeObjectAtIndex:i];
            NSDictionary *headers = [headersArray ll_safeObjectAtIndex:i];
            NSError *err = nil;
            NSURL *validURL = LLAsURL(raw, &err);
            if (!validURL) {
                [self log:[LLLogType errorLogWithMessage:@"create dowloadTask failed" error:[LLError invalidURLWithURL:raw]]];
                i++; continue;
            }
            if ([urlSet containsObject:validURL]) {
                [self log:[LLLogType errorLogWithMessage:@"create dowloadTask failed" error:[LLError duplicateURLWithURL:raw]]];
                i++; continue;
            }
            [urlSet addObject:validURL];

            LLDownloadTask *task = [self fetchTaskForURL:validURL];
            if (task) {
                [task updateHeaders:headers newFileName:fileName];
            } else {
                task = [[LLDownloadTask alloc] initWithURL:validURL
                                                    headers:headers
                                                   fileName:fileName
                                                      cache:self.cache
                                             operationQueue:self->_operationQueue];
                task.manager = self;
                task.session = [self _session];
                [self maintainAppendTask:task];
            }
            [uniqueTasks addObject:task];
            i++;
        }
        [self storeTasks];
        [[[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler] execute:self];
        dispatch_async(self->_operationQueue, ^{
            for (LLDownloadTask *t in uniqueTasks) {
                if (![t.status isEqualToString:LLStatusSucceeded]) [self _startTask:t onMainQueue:YES handler:nil];
            }
        });
    });
    return uniqueTasks;
}

#pragma mark - single task control

- (LLDownloadTask *)fetchTaskForURL:(id)url {
    NSError *err = nil;
    NSURL *validURL = LLAsURL(url, &err);
    if (!validURL) {
        [self log:[LLLogType errorLogWithMessage:@"fetch task failed" error:[LLError invalidURLWithURL:url]]];
        return nil;
    }
    __block LLDownloadTask *t;
    [_lock around:^{ t = self->_taskMapper_[validURL.absoluteString]; }];
    return t;
}

- (LLDownloadTask *)mapTaskForCurrentURL:(NSURL *)currentURL {
    __block LLDownloadTask *t;
    [_lock around:^{
        NSURL *url = self->_urlMapper_[currentURL] ?: currentURL;
        t = self->_taskMapper_[url.absoluteString];
    }];
    return t;
}

- (void)startWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        LLDownloadTask *t = [self fetchTaskForURL:url];
        if (!t) {
            [self log:[LLLogType errorLogWithMessage:@"can't start downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:url]]];
            return;
        }
        [self _startTask:t onMainQueue:onMainQueue handler:handler];
    });
}

- (void)startTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        if (![self fetchTaskForURL:task.url]) {
            [self log:[LLLogType errorLogWithMessage:@"can't start downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:task.url]]];
            return;
        }
        [self _startTask:task onMainQueue:onMainQueue handler:handler];
    });
}

- (void)_startTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    task.controlExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    [self didStart];
    if (![self _shouldCreatSession]) {
        [task download];
    } else {
        task.status = LLStatusSuspended;
        [_lock around:^{
            if (![self->_restartTasks_ containsObject:task]) [self->_restartTasks_ addObject:task];
        }];
    }
}

- (void)suspendWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        LLDownloadTask *t = [self fetchTaskForURL:url];
        if (!t) {
            [self log:[LLLogType errorLogWithMessage:@"can't suspend downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:url]]];
            return;
        }
        [t suspendOnMainQueue:onMainQueue handler:handler];
    });
}

- (void)suspendTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        if (![self fetchTaskForURL:task.url]) {
            [self log:[LLLogType errorLogWithMessage:@"can't suspend downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:task.url]]];
            return;
        }
        [task suspendOnMainQueue:onMainQueue handler:handler];
    });
}

- (void)cancelWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        LLDownloadTask *t = [self fetchTaskForURL:url];
        if (!t) {
            [self log:[LLLogType errorLogWithMessage:@"can't cancel downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:url]]];
            return;
        }
        [t cancelOnMainQueue:onMainQueue handler:handler];
    });
}

- (void)cancelTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        if (![self fetchTaskForURL:task.url]) {
            [self log:[LLLogType errorLogWithMessage:@"can't cancel downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:task.url]]];
            return;
        }
        [task cancelOnMainQueue:onMainQueue handler:handler];
    });
}

- (void)removeWithURL:(id)url completely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        LLDownloadTask *t = [self fetchTaskForURL:url];
        if (!t) {
            [self log:[LLLogType errorLogWithMessage:@"can't remove downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:url]]];
            return;
        }
        [t removeCompletely:completely onMainQueue:onMainQueue handler:handler];
    });
}

- (void)removeTask:(LLDownloadTask *)task completely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *))handler {
    dispatch_async(_operationQueue, ^{
        if (![self fetchTaskForURL:task.url]) {
            [self log:[LLLogType errorLogWithMessage:@"can't remove downloadTask" error:[LLError fetchDownloadTaskFailedWithURL:task.url]]];
            return;
        }
        [task removeCompletely:completely onMainQueue:onMainQueue handler:handler];
    });
}

- (void)moveTaskFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    dispatch_sync(_operationQueue, ^{
        NSInteger count = self.tasks.count;
        if (sourceIndex < 0 || sourceIndex >= count || destinationIndex < 0 || destinationIndex >= count) {
            [self log:[LLLogType errorLogWithMessage:[NSString stringWithFormat:@"move task failed, sourceIndex: %ld, destinationIndex: %ld",
                                                       (long)sourceIndex, (long)destinationIndex]
                                                error:[LLError indexOutOfRange]]];
            return;
        }
        if (sourceIndex == destinationIndex) return;
        [self->_lock around:^{
            LLDownloadTask *t = self->_tasks_[sourceIndex];
            [self->_tasks_ removeObjectAtIndex:sourceIndex];
            [self->_tasks_ insertObject:t atIndex:destinationIndex];
        }];
    });
}

#pragma mark - total task control

- (void)totalStartOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    dispatch_async(_operationQueue, ^{
        for (LLDownloadTask *t in self.tasks) {
            if (![t.status isEqualToString:LLStatusSucceeded]) [self _startTask:t onMainQueue:YES handler:nil];
        }
        [[[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler] execute:self];
    });
}

- (void)totalSuspendOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    dispatch_async(_operationQueue, ^{
        LLStatus s = self.status;
        if (!([s isEqualToString:LLStatusRunning] || [s isEqualToString:LLStatusWaiting])) return;
        self.status = LLStatusWillSuspend;
        [self->_lock around:^{ self->_controlExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
        for (LLDownloadTask *t in self.tasks) [t suspendOnMainQueue:YES handler:nil];
    });
}

- (void)totalCancelOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    dispatch_async(_operationQueue, ^{
        LLStatus s = self.status;
        if ([s isEqualToString:LLStatusSucceeded] || [s isEqualToString:LLStatusCanceled]) return;
        self.status = LLStatusWillCancel;
        [self->_lock around:^{ self->_controlExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
        for (LLDownloadTask *t in self.tasks) [t cancelOnMainQueue:YES handler:nil];
    });
}

- (void)totalRemoveCompletely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    dispatch_async(_operationQueue, ^{
        if ([self.status isEqualToString:LLStatusRemoved]) return;
        self.status = LLStatusWillRemove;
        [self->_lock around:^{ self->_controlExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
        for (LLDownloadTask *t in self.tasks) [t removeCompletely:completely onMainQueue:YES handler:nil];
    });
}

- (void)tasksSortUsingComparator:(NSComparator)comparator {
    dispatch_sync(_operationQueue, ^{
        [self->_lock around:^{
            [self->_tasks_ sortUsingComparator:comparator];
        }];
    });
}

#pragma mark - maintain

- (void)maintainAppendTask:(LLDownloadTask *)task {
    [_lock around:^{
        [self->_tasks_ addObject:task];
        self->_taskMapper_[task.url.absoluteString] = task;
        self->_urlMapper_[task.currentURL] = task.url;
    }];
}

- (void)maintainRemoveTask:(LLDownloadTask *)task {
    [_lock around:^{
        if ([self->_status_ isEqualToString:LLStatusWillRemove]) {
            [self->_taskMapper_ removeObjectForKey:task.url.absoluteString];
            [self->_urlMapper_ removeObjectForKey:task.currentURL];
            if (self->_taskMapper_.count == 0) {
                [self->_tasks_ removeAllObjects];
                [self->_succeededTasks_ removeAllObjects];
            }
        } else if ([self->_status_ isEqualToString:LLStatusWillCancel]) {
            [self->_taskMapper_ removeObjectForKey:task.url.absoluteString];
            [self->_urlMapper_ removeObjectForKey:task.currentURL];
            if (self->_taskMapper_.count == self->_succeededTasks_.count) {
                self->_tasks_ = [self->_succeededTasks_ mutableCopy];
            }
        } else {
            [self->_taskMapper_ removeObjectForKey:task.url.absoluteString];
            [self->_urlMapper_ removeObjectForKey:task.currentURL];
            NSMutableArray *filtered = [NSMutableArray array];
            for (LLDownloadTask *t in self->_tasks_) {
                if (![t.url.absoluteString isEqualToString:task.url.absoluteString]) [filtered addObject:t];
            }
            self->_tasks_ = filtered;
            if ([task.status isEqualToString:LLStatusRemoved]) {
                NSMutableArray *fs = [NSMutableArray array];
                for (LLDownloadTask *t in self->_succeededTasks_) {
                    if (![t.url.absoluteString isEqualToString:task.url.absoluteString]) [fs addObject:t];
                }
                self->_succeededTasks_ = fs;
            }
        }
    }];
}

- (void)maintainSucceededTask:(LLDownloadTask *)task {
    [_lock around:^{ [self->_succeededTasks_ addObject:task]; }];
}

- (void)maintainAppendRunningTask:(LLDownloadTask *)task {
    [_lock around:^{ [self->_runningTasks_ addObject:task]; }];
}

- (void)maintainRemoveRunningTask:(LLDownloadTask *)task {
    [_lock around:^{
        NSMutableArray *f = [NSMutableArray array];
        for (LLDownloadTask *t in self->_runningTasks_) {
            if (![t.url.absoluteString isEqualToString:task.url.absoluteString]) [f addObject:t];
        }
        self->_runningTasks_ = f;
    }];
}

- (void)updateUrlMapperWithTask:(LLDownloadTask *)task {
    [_lock around:^{ self->_urlMapper_[task.currentURL] = task.url; }];
    [self storeTasks];
}

#pragma mark - restore

- (void)restoreStatus {
    if (self.tasks.count == 0) return;
    __weak typeof(self) wself = self;
    [[self _session] getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *dataTasks,
                                                     NSArray<NSURLSessionUploadTask *> *uploadTasks,
                                                     NSArray<NSURLSessionDownloadTask *> *downloadTasks) {
        __strong typeof(wself) self_ = wself;
        if (!self_) return;
        for (NSURLSessionDownloadTask *dt in downloadTasks) {
            if (dt.state == NSURLSessionTaskStateRunning) {
                NSURL *currentURL = dt.currentRequest.URL;
                if (!currentURL) continue;
                LLDownloadTask *t = [self_ mapTaskForCurrentURL:currentURL];
                if (!t) continue;
                [self_ didStart];
                [self_ maintainAppendRunningTask:t];
                t.status = LLStatusRunning;
                t.sessionTask = dt;
            }
        }
        [self_ storeTasks];
        if (![self_ shouldComplete]) {
            [self_ shouldSuspend];
        }
    }];
}

- (BOOL)shouldComplete {
    BOOL isSucceeded = YES;
    BOOL isCompleted = YES;
    for (LLDownloadTask *t in self.tasks) {
        if (![t.status isEqualToString:LLStatusSucceeded]) isSucceeded = NO;
        if (!([t.status isEqualToString:LLStatusSucceeded] || [t.status isEqualToString:LLStatusFailed])) isCompleted = NO;
    }
    if (!isCompleted) return NO;
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusSucceeded] || [s isEqualToString:LLStatusFailed]) return YES;
    [_lock around:^{ self->_timeRemaining_ = 0; }];
    [[self _progressExecuter] execute:self];
    self.status = isSucceeded ? LLStatusSucceeded : LLStatusFailed;
    [self executeCompletionSucceeded:isSucceeded];
    return YES;
}

- (void)shouldSuspend {
    BOOL isSuspended = YES;
    for (LLDownloadTask *t in self.tasks) {
        if (!([t.status isEqualToString:LLStatusSuspended] || [t.status isEqualToString:LLStatusSucceeded] || [t.status isEqualToString:LLStatusFailed])) {
            isSuspended = NO; break;
        }
    }
    if (!isSuspended) return;
    if ([self.status isEqualToString:LLStatusSuspended]) return;
    self.status = LLStatusSuspended;
    [self executeControl];
    [self executeCompletionSucceeded:NO];
    if ([self _shouldCreatSession]) {
        NSURLSession *s = [self _session];
        [s invalidateAndCancel];
        [self _setSession:nil];
    }
}

- (void)didStart {
    if (![self.status isEqualToString:LLStatusRunning]) {
        [self createTimer];
        self.status = LLStatusRunning;
        [[self _progressExecuter] execute:self];
    }
}

- (void)updateProgress {
    if (self.isControlNetworkActivityIndicator) {
#if __has_include(<UIKit/UIKit.h>) && !TARGET_OS_OSX && !TARGET_OS_VISION
        LLExecuteOnMain(^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
#endif
    }
    [[self _progressExecuter] execute:self];
    [[NSNotificationCenter defaultCenter] ll_postNotificationName:LLSessionManagerRunningNotification sessionManager:self];
}

- (void)didCancelOrRemove:(LLDownloadTask *)task {
    [self maintainRemoveTask:task];
    if (self.tasks.count == 0) {
        if ([task.status isEqualToString:LLStatusCanceled]) self.status = LLStatusWillCancel;
        if ([task.status isEqualToString:LLStatusRemoved]) self.status = LLStatusWillRemove;
    }
}

- (void)storeTasks { [self.cache storeTasks:self.tasks]; }

- (void)determineStatusFromRunningTask:(BOOL)fromRunningTask {
    if (self.isControlNetworkActivityIndicator) {
#if __has_include(<UIKit/UIKit.h>) && !TARGET_OS_OSX && !TARGET_OS_VISION
        LLExecuteOnMain(^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
#endif
    }
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusWillRemove]) {
        if (self.tasks.count == 0) {
            self.status = LLStatusRemoved;
            [self executeControl];
            [self endingSucceeded:NO];
        }
        return;
    }
    if ([s isEqualToString:LLStatusWillCancel]) {
        __block NSInteger mapCount;
        [_lock around:^{ mapCount = self->_taskMapper_.count; }];
        if (self.tasks.count == mapCount) {
            self.status = LLStatusCanceled;
            [self executeControl];
            [self endingSucceeded:NO];
        }
        return;
    }
    BOOL isCompleted = YES, isSucceeded = YES;
    for (LLDownloadTask *t in self.tasks) {
        if (!([t.status isEqualToString:LLStatusSucceeded] || [t.status isEqualToString:LLStatusFailed])) { isCompleted = NO; }
        if (![t.status isEqualToString:LLStatusSucceeded]) isSucceeded = NO;
    }
    if (isCompleted) {
        if ([s isEqualToString:LLStatusSucceeded] || [s isEqualToString:LLStatusFailed]) { [self storeTasks]; return; }
        [_lock around:^{ self->_timeRemaining_ = 0; }];
        [[self _progressExecuter] execute:self];
        self.status = isSucceeded ? LLStatusSucceeded : LLStatusFailed;
        [self endingSucceeded:isSucceeded];
        return;
    }
    BOOL isSuspended = YES;
    for (LLDownloadTask *t in self.tasks) {
        if (!([t.status isEqualToString:LLStatusSuspended] || [t.status isEqualToString:LLStatusSucceeded] || [t.status isEqualToString:LLStatusFailed])) { isSuspended = NO; break; }
    }
    if (isSuspended) {
        if ([s isEqualToString:LLStatusSuspended]) { [self storeTasks]; return; }
        self.status = LLStatusSuspended;
        if ([self _shouldCreatSession]) {
            NSURLSession *ss = [self _session];
            [ss invalidateAndCancel];
            [self _setSession:nil];
        } else {
            [self executeControl];
            [self endingSucceeded:NO];
        }
        return;
    }
    if ([s isEqualToString:LLStatusWillSuspend]) return;
    [self storeTasks];
    if (fromRunningTask) {
        dispatch_async(_operationQueue, ^{ [self startNextTask]; });
    }
}

- (void)endingSucceeded:(BOOL)isSucceeded {
    [self executeCompletionSucceeded:isSucceeded];
    [self storeTasks];
    [self invalidateTimer];
}

- (void)startNextTask {
    for (LLDownloadTask *t in self.tasks) {
        if ([t.status isEqualToString:LLStatusWaiting]) { [t download]; return; }
    }
}

#pragma mark - timer

- (void)createTimer {
    [_lock around:^{
        if (self->_timer_) return;
        self->_timer_ = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, self->_operationQueue);
        dispatch_source_set_timer(self->_timer_, DISPATCH_TIME_NOW,
                                  (uint64_t)(kRefreshInterval * NSEC_PER_SEC), 0);
        __weak typeof(self) wself = self;
        dispatch_source_set_event_handler(self->_timer_, ^{
            [wself updateSpeedAndTimeRemaining];
        });
        dispatch_resume(self->_timer_);
    }];
}

- (void)invalidateTimer {
    [_lock around:^{
        if (self->_timer_) {
            dispatch_source_cancel(self->_timer_);
            self->_timer_ = nil;
        }
    }];
}

- (void)updateSpeedAndTimeRemaining {
    __block int64_t speed = 0;
    [_lock around:^{
        for (LLDownloadTask *t in self->_runningTasks_) {
            [t updateSpeedAndTimeRemaining];
            speed += t.speed;
        }
    }];
    double timeRemaining;
    if (speed != 0) {
        timeRemaining = ((double)self.progress.totalUnitCount - (double)self.progress.completedUnitCount) / (double)speed;
        if (timeRemaining >= 0.8 && timeRemaining < 1) timeRemaining += 1;
    } else {
        timeRemaining = 0;
    }
    [_lock around:^{
        self->_speed_ = speed;
        self->_timeRemaining_ = (int64_t)timeRemaining;
    }];
}

- (void)log:(LLLogType *)type { [self.logger log:type]; }

#pragma mark - chainable

- (LLExecuter *)_progressExecuter { __block LLExecuter *e; [_lock around:^{ e = self->_progressExecuter_; }]; return e; }
- (LLExecuter *)_successExecuter { __block LLExecuter *e; [_lock around:^{ e = self->_successExecuter_; }]; return e; }
- (LLExecuter *)_failureExecuter { __block LLExecuter *e; [_lock around:^{ e = self->_failureExecuter_; }]; return e; }
- (LLExecuter *)_completionExecuter { __block LLExecuter *e; [_lock around:^{ e = self->_completionExecuter_; }]; return e; }
- (LLExecuter *)_controlExecuter { __block LLExecuter *e; [_lock around:^{ e = self->_controlExecuter_; }]; return e; }

- (instancetype)onProgress:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    [_lock around:^{ self->_progressExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
    return self;
}
- (instancetype)onSuccess:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    [_lock around:^{ self->_successExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
    if ([self.status isEqualToString:LLStatusSucceeded] && ![self _completionExecuter]) {
        dispatch_async(_operationQueue, ^{ [[self _successExecuter] execute:self]; });
    }
    return self;
}
- (instancetype)onFailure:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    [_lock around:^{ self->_failureExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
    LLStatus s = self.status;
    if (![self _completionExecuter] &&
        ([s isEqualToString:LLStatusSuspended] ||
         [s isEqualToString:LLStatusCanceled] ||
         [s isEqualToString:LLStatusRemoved] ||
         [s isEqualToString:LLStatusFailed])) {
        dispatch_async(_operationQueue, ^{ [[self _failureExecuter] execute:self]; });
    }
    return self;
}
- (instancetype)onCompletion:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *))handler {
    [_lock around:^{ self->_completionExecuter_ = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler]; }];
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusSuspended] ||
        [s isEqualToString:LLStatusCanceled] ||
        [s isEqualToString:LLStatusRemoved] ||
        [s isEqualToString:LLStatusSucceeded] ||
        [s isEqualToString:LLStatusFailed]) {
        dispatch_async(_operationQueue, ^{ [[self _completionExecuter] execute:self]; });
    }
    return self;
}

- (void)executeCompletionSucceeded:(BOOL)isSucceeded {
    LLExecuter *ce = [self _completionExecuter];
    if (ce) [ce execute:self];
    else if (isSucceeded) [[self _successExecuter] execute:self];
    else [[self _failureExecuter] execute:self];
    [[NSNotificationCenter defaultCenter] ll_postNotificationName:LLSessionManagerDidCompleteNotification sessionManager:self];
}

- (void)executeControl {
    LLExecuter *ce = [self _controlExecuter];
    [ce execute:self];
    [_lock around:^{ self->_controlExecuter_ = nil; }];
}

#pragma mark - callbacks

- (void)didBecomeInvalidationWithError:(NSError *)error {
    __weak typeof(self) wself = self;
    [self createSessionCompletion:^{
        __strong typeof(wself) self_ = wself;
        if (!self_) return;
        __block NSArray<LLDownloadTask *> *toRestart;
        [self_->_lock around:^{
            toRestart = [self_->_restartTasks_ copy];
            [self_->_restartTasks_ removeAllObjects];
        }];
        for (LLDownloadTask *t in toRestart) [self_ _startTask:t onMainQueue:YES handler:nil];
    }];
}

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    LLExecuteOnMain(^{
        dispatch_block_t h = self.completionHandler;
        if (h) h();
        self.completionHandler = nil;
    });
}

@end
