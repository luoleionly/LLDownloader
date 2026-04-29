//
//  LLCommon.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LLSessionManager;
@class LLDownloadTask;

typedef NS_ENUM(NSInteger, LLLogOption) {
    LLLogOptionDefault = 0,
    LLLogOptionNone,
};

typedef NS_ENUM(NSInteger, LLLogTypeKind) {
    LLLogTypeKindSessionManager = 0,
    LLLogTypeKindDownloadTask,
    LLLogTypeKindError,
};

// Status strings (mirroring Swift enum rawValues)
FOUNDATION_EXPORT NSString *const LLStatusWaiting;
FOUNDATION_EXPORT NSString *const LLStatusRunning;
FOUNDATION_EXPORT NSString *const LLStatusSuspended;
FOUNDATION_EXPORT NSString *const LLStatusCanceled;
FOUNDATION_EXPORT NSString *const LLStatusFailed;
FOUNDATION_EXPORT NSString *const LLStatusRemoved;
FOUNDATION_EXPORT NSString *const LLStatusSucceeded;
FOUNDATION_EXPORT NSString *const LLStatusWillSuspend;
FOUNDATION_EXPORT NSString *const LLStatusWillCancel;
FOUNDATION_EXPORT NSString *const LLStatusWillRemove;

typedef NSString *LLStatus NS_TYPED_EXTENSIBLE_ENUM;

@interface LLLogType : NSObject
@property (nonatomic, readonly) LLLogTypeKind kind;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, weak, readonly, nullable) LLSessionManager *manager;
@property (nonatomic, weak, readonly, nullable) LLDownloadTask *downloadTask;
@property (nonatomic, strong, readonly, nullable) NSError *error;

+ (instancetype)sessionManagerLogWithMessage:(NSString *)message manager:(LLSessionManager *)manager;
+ (instancetype)downloadTaskLogWithMessage:(NSString *)message task:(LLDownloadTask *)task;
+ (instancetype)errorLogWithMessage:(NSString *)message error:(NSError *)error;
@end

@protocol LLLogable <NSObject>
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, assign) LLLogOption option;
- (void)log:(LLLogType *)type;
@end

@interface LLLogger : NSObject <LLLogable>
- (instancetype)initWithIdentifier:(NSString *)identifier option:(LLLogOption)option;
@end

NS_ASSUME_NONNULL_END
