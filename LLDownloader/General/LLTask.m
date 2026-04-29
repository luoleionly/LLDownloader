//
//  LLTask.m
//  LLDownloader
//

#import "LLTask.h"
#import "LLTask+Internal.h"
#import "LLCache.h"
#import "LLSessionManager.h"
#import "LLDownloadTask.h"
#import "NSString+LLURL.h"
#import "NSNumber+LLTaskInfo.h"

@implementation LLTask

@synthesize url = _url;
@synthesize progress = _progress;

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithURL:(NSURL *)url
                    headers:(NSDictionary<NSString *, NSString *> *)headers
                      cache:(LLCache *)cache
             operationQueue:(dispatch_queue_t)operationQueue {
    if ((self = [super init])) {
        _stateLock = [[LLUnfairLock alloc] init];
        _url = [url copy];
        _cache = cache;
        _operationQueue = operationQueue;
        _progress = [NSProgress progressWithTotalUnitCount:0];
        _status_ = LLStatusWaiting;
        _validation_ = LLValidationUnknown;
        _verificationType_ = LLVerificationTypeMD5;
        _currentURL_ = [url copy];
        _fileName_ = [url.ll_fileName copy];
        _headers_ = [headers copy];
    }
    return self;
}

- (void)_withState:(NS_NOESCAPE void (^)(void))block {
    [_stateLock around:block];
}

- (id)_readState:(NS_NOESCAPE id _Nullable (^)(void))block {
    return [_stateLock aroundReturning:block];
}

#pragma mark - property accessors

#define LL_LOCKED_GETTER(type, name, ivar) \
- (type)name { __block type v; [_stateLock around:^{ v = ivar; }]; return v; }

#define LL_LOCKED_SETTER(type, setter, ivar) \
- (void)setter:(type)value { [_stateLock around:^{ ivar = value; }]; }

LL_LOCKED_GETTER(NSURLSession *, session, _session_)
LL_LOCKED_SETTER(NSURLSession *, setSession, _session_)

LL_LOCKED_GETTER(NSDictionary *, headers, _headers_)
- (void)setHeaders:(NSDictionary<NSString *,NSString *> *)headers { [_stateLock around:^{ self->_headers_ = [headers copy]; }]; }

LL_LOCKED_GETTER(NSString *, verificationCode, _verificationCode_)
- (void)setVerificationCode:(NSString *)verificationCode { [_stateLock around:^{ self->_verificationCode_ = [verificationCode copy]; }]; }

LL_LOCKED_GETTER(LLVerificationType, verificationType, _verificationType_)
LL_LOCKED_SETTER(LLVerificationType, setVerificationType, _verificationType_)

LL_LOCKED_GETTER(BOOL, isRemoveCompletely, _isRemoveCompletely_)
LL_LOCKED_SETTER(BOOL, setIsRemoveCompletely, _isRemoveCompletely_)

LL_LOCKED_GETTER(LLValidation, validation, _validation_)
LL_LOCKED_SETTER(LLValidation, setValidation, _validation_)

- (NSURL *)currentURL { __block NSURL *v; [_stateLock around:^{ v = self->_currentURL_; }]; return v; }
- (void)setCurrentURL:(NSURL *)currentURL { [_stateLock around:^{ self->_currentURL_ = [currentURL copy]; }]; }

LL_LOCKED_GETTER(NSTimeInterval, startDate, _startDate_)
LL_LOCKED_SETTER(NSTimeInterval, setStartDate, _startDate_)

LL_LOCKED_GETTER(NSTimeInterval, endDate, _endDate_)
LL_LOCKED_SETTER(NSTimeInterval, setEndDate, _endDate_)

LL_LOCKED_GETTER(int64_t, speed, _speed_)
LL_LOCKED_SETTER(int64_t, setSpeed, _speed_)

- (NSString *)fileName { __block NSString *v; [_stateLock around:^{ v = self->_fileName_; }]; return v; }
- (void)setFileName:(NSString *)fileName { [_stateLock around:^{ self->_fileName_ = [fileName copy]; }]; }

LL_LOCKED_GETTER(int64_t, timeRemaining, _timeRemaining_)
LL_LOCKED_SETTER(int64_t, setTimeRemaining, _timeRemaining_)

- (NSError *)error { __block NSError *v; [_stateLock around:^{ v = self->_error_; }]; return v; }
- (void)setError:(NSError *)error { [_stateLock around:^{ self->_error_ = error; }]; }

LL_LOCKED_GETTER(LLExecuter *, progressExecuter, _progressExecuter_)
- (void)setProgressExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_progressExecuter_ = e; }]; }
LL_LOCKED_GETTER(LLExecuter *, successExecuter, _successExecuter_)
- (void)setSuccessExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_successExecuter_ = e; }]; }
LL_LOCKED_GETTER(LLExecuter *, failureExecuter, _failureExecuter_)
- (void)setFailureExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_failureExecuter_ = e; }]; }
LL_LOCKED_GETTER(LLExecuter *, completionExecuter, _completionExecuter_)
- (void)setCompletionExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_completionExecuter_ = e; }]; }
LL_LOCKED_GETTER(LLExecuter *, controlExecuter, _controlExecuter_)
- (void)setControlExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_controlExecuter_ = e; }]; }
LL_LOCKED_GETTER(LLExecuter *, validateExecuter, _validateExecuter_)
- (void)setValidateExecuter:(LLExecuter *)e { [_stateLock around:^{ self->_validateExecuter_ = e; }]; }

#pragma mark - status

- (LLStatus)status { __block LLStatus s; [_stateLock around:^{ s = self->_status_; }]; return s; }

- (void)_setStatusSilently:(LLStatus)status {
    [_stateLock around:^{ self->_status_ = [status copy]; }];
}

- (void)setStatus:(LLStatus)status {
    [_stateLock around:^{ self->_status_ = [status copy]; }];
    if ([status isEqualToString:LLStatusWillSuspend] ||
        [status isEqualToString:LLStatusWillCancel] ||
        [status isEqualToString:LLStatusWillRemove]) {
        return;
    }
    if ([self isKindOfClass:[LLDownloadTask class]]) {
        [self.manager log:[LLLogType downloadTaskLogWithMessage:status task:(LLDownloadTask *)self]];
    }
}

#pragma mark - derived string fields

- (NSString *)startDateString { return [@(self.startDate) ll_convertTimeToDateString]; }
- (NSString *)endDateString   { return [@(self.endDate)   ll_convertTimeToDateString]; }
- (NSString *)speedString     { return [@(self.speed)     ll_convertSpeedToString]; }
- (NSString *)timeRemainingString { return [@(self.timeRemaining) ll_convertTimeToString]; }

#pragma mark - chainable

- (instancetype)onProgress:(BOOL)onMainQueue handler:(void (^)(id))handler {
    self.progressExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    return self;
}

- (instancetype)onSuccess:(BOOL)onMainQueue handler:(void (^)(id))handler {
    self.successExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusSucceeded] && self.completionExecuter == nil) {
        dispatch_async(self.operationQueue, ^{ [self _executeExecuter:self.successExecuter]; });
    }
    return self;
}

- (instancetype)onFailure:(BOOL)onMainQueue handler:(void (^)(id))handler {
    self.failureExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    LLStatus s = self.status;
    if (self.completionExecuter == nil &&
        ([s isEqualToString:LLStatusSuspended] ||
         [s isEqualToString:LLStatusCanceled] ||
         [s isEqualToString:LLStatusRemoved] ||
         [s isEqualToString:LLStatusFailed])) {
        dispatch_async(self.operationQueue, ^{ [self _executeExecuter:self.failureExecuter]; });
    }
    return self;
}

- (instancetype)onCompletion:(BOOL)onMainQueue handler:(void (^)(id))handler {
    self.completionExecuter = [[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:handler];
    LLStatus s = self.status;
    if ([s isEqualToString:LLStatusSuspended] ||
        [s isEqualToString:LLStatusCanceled] ||
        [s isEqualToString:LLStatusRemoved] ||
        [s isEqualToString:LLStatusSucceeded] ||
        [s isEqualToString:LLStatusFailed]) {
        dispatch_async(self.operationQueue, ^{ [self _executeExecuter:self.completionExecuter]; });
    }
    return self;
}

- (void)_executeExecuter:(id)executer {
    // Subclasses override.
}

#pragma mark - NSSecureCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    __block NSDictionary *h;
    __block NSString *vc;
    __block NSString *fn;
    __block NSURL *cur;
    __block NSTimeInterval sd = 0, ed = 0;
    __block LLStatus st;
    __block LLVerificationType vt = LLVerificationTypeMD5;
    __block LLValidation val = LLValidationUnknown;
    __block NSError *err;
    typeof(self) me = self;
    [_stateLock around:^{
        h = me->_headers_;
        vc = me->_verificationCode_;
        fn = me->_fileName_;
        cur = me->_currentURL_;
        sd = me->_startDate_;
        ed = me->_endDate_;
        st = me->_status_;
        vt = me->_verificationType_;
        val = me->_validation_;
        err = me->_error_;
    }];
    [coder encodeObject:_url forKey:@"url"];
    [coder encodeObject:cur forKey:@"currentURL"];
    [coder encodeObject:fn forKey:@"fileName"];
    if (h) [coder encodeObject:h forKey:@"headers"];
    [coder encodeDouble:sd forKey:@"startDate"];
    [coder encodeDouble:ed forKey:@"endDate"];
    [coder encodeInt64:_progress.totalUnitCount forKey:@"totalBytes"];
    [coder encodeInt64:_progress.completedUnitCount forKey:@"completedBytes"];
    if (vc) [coder encodeObject:vc forKey:@"verificationCode"];
    [coder encodeInteger:vt forKey:@"verificationType"];
    [coder encodeInteger:val forKey:@"validation"];
    [coder encodeObject:st forKey:@"status"];
    if (err) {
        NSError *archiveErr = nil;
        NSData *errData = [NSKeyedArchiver archivedDataWithRootObject:err
                                                requiringSecureCoding:YES
                                                                error:&archiveErr];
        if (errData) [coder encodeObject:errData forKey:@"error"];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSURL *url = [coder decodeObjectOfClass:[NSURL class] forKey:@"url"];
    NSURL *cur = [coder decodeObjectOfClass:[NSURL class] forKey:@"currentURL"];
    NSString *fn = [coder decodeObjectOfClass:[NSString class] forKey:@"fileName"];

    // cache/operationQueue are intentional placeholders; LLCache.retrieveAllTasks
    // and LLSessionManager.init reassign them after decoding.
    LLCache *cache = [[LLCache alloc] initWithIdentifier:@"default"];
    dispatch_queue_t opQueue = dispatch_queue_create("com.LL.SessionManager.operationQueue", DISPATCH_QUEUE_SERIAL);

    if ((self = [self initWithURL:url headers:nil cache:cache operationQueue:opQueue])) {
        _currentURL_ = [cur copy];
        _fileName_ = [fn copy];
        _progress.totalUnitCount = [coder decodeInt64ForKey:@"totalBytes"];
        _progress.completedUnitCount = [coder decodeInt64ForKey:@"completedBytes"];
        NSSet *strSet = [NSSet setWithObject:[NSString class]];
        NSSet *dictSet = [NSSet setWithObjects:[NSDictionary class], [NSString class], nil];
        _headers_ = [coder decodeObjectOfClasses:dictSet forKey:@"headers"];
        _startDate_ = [coder decodeDoubleForKey:@"startDate"];
        _endDate_ = [coder decodeDoubleForKey:@"endDate"];
        _verificationCode_ = [coder decodeObjectOfClasses:strSet forKey:@"verificationCode"];
        _verificationType_ = (LLVerificationType)[coder decodeIntegerForKey:@"verificationType"];
        _validation_ = (LLValidation)[coder decodeIntegerForKey:@"validation"];
        NSString *st = [coder decodeObjectOfClass:[NSString class] forKey:@"status"];
        _status_ = st ?: LLStatusWaiting;
        NSData *errData = [coder decodeObjectOfClass:[NSData class] forKey:@"error"];
        if (errData) {
            NSError *e = nil;
            _error_ = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSError class] fromData:errData error:&e];
        }
    }
    return self;
}

@end
