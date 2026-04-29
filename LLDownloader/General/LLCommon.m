//
//  LLCommon.m
//  LLDownloader
//

#import "LLCommon.h"
#import "LLSessionManager.h"
#import "LLDownloadTask.h"

NSString *const LLStatusWaiting = @"waiting";
NSString *const LLStatusRunning = @"running";
NSString *const LLStatusSuspended = @"suspended";
NSString *const LLStatusCanceled = @"canceled";
NSString *const LLStatusFailed = @"failed";
NSString *const LLStatusRemoved = @"removed";
NSString *const LLStatusSucceeded = @"succeeded";
NSString *const LLStatusWillSuspend = @"willSuspend";
NSString *const LLStatusWillCancel = @"willCancel";
NSString *const LLStatusWillRemove = @"willRemove";

@interface LLLogType ()
@property (nonatomic, readwrite) LLLogTypeKind kind;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, weak, readwrite) LLSessionManager *manager;
@property (nonatomic, weak, readwrite) LLDownloadTask *downloadTask;
@property (nonatomic, strong, readwrite) NSError *error;
@end

@implementation LLLogType
+ (instancetype)sessionManagerLogWithMessage:(NSString *)message manager:(LLSessionManager *)manager {
    LLLogType *t = [[self alloc] init];
    t.kind = LLLogTypeKindSessionManager;
    t.message = message;
    t.manager = manager;
    return t;
}
+ (instancetype)downloadTaskLogWithMessage:(NSString *)message task:(LLDownloadTask *)task {
    LLLogType *t = [[self alloc] init];
    t.kind = LLLogTypeKindDownloadTask;
    t.message = message;
    t.downloadTask = task;
    return t;
}
+ (instancetype)errorLogWithMessage:(NSString *)message error:(NSError *)error {
    LLLogType *t = [[self alloc] init];
    t.kind = LLLogTypeKindError;
    t.message = message;
    t.error = error;
    return t;
}
@end

@implementation LLLogger {
    NSString *_identifier;
}
@synthesize option = _option;

- (instancetype)initWithIdentifier:(NSString *)identifier option:(LLLogOption)option {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _option = option;
    }
    return self;
}

- (NSString *)identifier { return _identifier; }

- (void)log:(LLLogType *)type {
    if (self.option != LLLogOptionDefault) return;
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [lines addObject:@"************************ LLLog ************************"];
    [lines addObject:[NSString stringWithFormat:@"identifier    :  %@", self.identifier]];
    switch (type.kind) {
        case LLLogTypeKindSessionManager:
            [lines addObject:[NSString stringWithFormat:@"Message       :  [SessionManager] %@, tasks.count: %lu",
                              type.message, (unsigned long)type.manager.tasks.count]];
            break;
        case LLLogTypeKindDownloadTask: {
            LLDownloadTask *t = type.downloadTask;
            [lines addObject:[NSString stringWithFormat:@"Message       :  [DownloadTask] %@", type.message]];
            [lines addObject:[NSString stringWithFormat:@"Task URL      :  %@", t.url.absoluteString]];
            if (t.error && [t.status isEqualToString:LLStatusFailed]) {
                [lines addObject:[NSString stringWithFormat:@"Error         :  %@", t.error]];
            }
            break;
        }
        case LLLogTypeKindError:
            [lines addObject:[NSString stringWithFormat:@"Message       :  [Error] %@", type.message]];
            [lines addObject:[NSString stringWithFormat:@"Description   :  %@", type.error]];
            break;
    }
    [lines addObject:@""];
    NSLog(@"%@", [lines componentsJoinedByString:@"\n"]);
}

@end
