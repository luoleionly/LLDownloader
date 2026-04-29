//
//  LLTask.h
//  LLDownloader
//

#import <Foundation/Foundation.h>
#import "LLCommon.h"
#import "LLFileChecksumHelper.h"

NS_ASSUME_NONNULL_BEGIN

@class LLSessionManager;
@class LLCache;
@class LLDownloadTask;

typedef NS_ENUM(NSInteger, LLValidation) {
    LLValidationUnknown = 0,
    LLValidationCorrect,
    LLValidationIncorrect,
};

/// Base class for LL tasks. In practice only LLDownloadTask is used;
/// this class exists so persisted state and callback scaffolding can be shared.
@interface LLTask : NSObject <NSSecureCoding>

@property (nonatomic, weak, nullable) LLSessionManager *manager;
@property (nonatomic, strong) LLCache *cache;
@property (nonatomic, strong) dispatch_queue_t operationQueue;

@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSProgress *progress;

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, copy, nullable) NSString *verificationCode;
@property (nonatomic, assign) LLVerificationType verificationType;
@property (nonatomic, assign) BOOL isRemoveCompletely;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) LLStatus status;                 // setter triggers logging (except will*)
@property (nonatomic, assign) LLValidation validation;
@property (nonatomic, copy) NSURL *currentURL;

@property (nonatomic, assign) NSTimeInterval startDate;       // POSIX seconds
@property (nonatomic, assign) NSTimeInterval endDate;
@property (nonatomic, assign) int64_t speed;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) int64_t timeRemaining;
@property (nonatomic, strong, nullable) NSError *error;

@property (nonatomic, readonly) NSString *startDateString;
@property (nonatomic, readonly) NSString *endDateString;
@property (nonatomic, readonly) NSString *speedString;
@property (nonatomic, readonly) NSString *timeRemainingString;

// Handler types for chainable API
typedef void (^LLDownloadTaskHandler)(LLDownloadTask *task);

// Chainable callbacks. `handler` parameter is the concrete subclass; for LLDownloadTask callers pass LLDownloadTaskHandler-compatible block.
- (instancetype)onProgress:(BOOL)onMainQueue handler:(void (^)(id task))handler;
- (instancetype)onSuccess:(BOOL)onMainQueue handler:(void (^)(id task))handler;
- (instancetype)onFailure:(BOOL)onMainQueue handler:(void (^)(id task))handler;
- (instancetype)onCompletion:(BOOL)onMainQueue handler:(void (^)(id task))handler;

// Designated initializer (internal).
- (instancetype)initWithURL:(NSURL *)url
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                      cache:(LLCache *)cache
             operationQueue:(dispatch_queue_t)operationQueue NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

// Hook overridden by subclasses to invoke the type-specific executer.
- (void)_executeExecuter:(id)executer; // takes LLExecuter *

@end

NS_ASSUME_NONNULL_END
