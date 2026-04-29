//
//  LLSessionManager.h
//  LLDownloader
//

#import <Foundation/Foundation.h>
#import "LLCommon.h"
#import "LLSessionConfiguration.h"
#import "LLDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@class LLCache;

@interface LLSessionManager : NSObject

@property (nonatomic, strong, readonly) dispatch_queue_t operationQueue;
@property (nonatomic, strong, readonly) LLCache *cache;
@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, copy, nullable) dispatch_block_t completionHandler;

@property (nonatomic, copy) LLSessionConfiguration *configuration;

@property (nonatomic, strong) id<LLLogable> logger;
@property (nonatomic, assign) BOOL isControlNetworkActivityIndicator; // default YES

@property (nonatomic, copy, readonly) LLStatus status;
@property (nonatomic, copy, readonly) NSArray<LLDownloadTask *> *tasks;
@property (nonatomic, copy, readonly) NSArray<LLDownloadTask *> *succeededTasks;
@property (nonatomic, strong, readonly) NSProgress *progress;
@property (nonatomic, readonly) int64_t speed;
@property (nonatomic, readonly) int64_t timeRemaining;
@property (nonatomic, readonly) NSString *speedString;
@property (nonatomic, readonly) NSString *timeRemainingString;

- (instancetype)initWithIdentifier:(NSString *)identifier
                     configuration:(LLSessionConfiguration *)configuration;
- (instancetype)initWithIdentifier:(NSString *)identifier
                     configuration:(LLSessionConfiguration *)configuration
                            logger:(nullable id<LLLogable>)logger
                             cache:(nullable LLCache *)cache
                    operationQueue:(nullable dispatch_queue_t)operationQueue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)invalidate;

// MARK: - download

- (nullable LLDownloadTask *)downloadWithURL:(id)url;
- (nullable LLDownloadTask *)downloadWithURL:(id)url
                                      headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                     fileName:(nullable NSString *)fileName
                                  onMainQueue:(BOOL)onMainQueue
                                      handler:(void (^_Nullable)(LLDownloadTask *task))handler;

- (NSArray<LLDownloadTask *> *)multiDownloadWithURLs:(NSArray *)urls
                                         headersArray:(nullable NSArray<NSDictionary<NSString *, NSString *> *> *)headersArray
                                            fileNames:(nullable NSArray<NSString *> *)fileNames
                                          onMainQueue:(BOOL)onMainQueue
                                              handler:(void (^_Nullable)(LLSessionManager *manager))handler;

// MARK: - single task control

- (nullable LLDownloadTask *)fetchTaskForURL:(id)url;

- (void)startWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)startTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;

- (void)suspendWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)suspendTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;

- (void)cancelWithURL:(id)url onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)cancelTask:(LLDownloadTask *)task onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;

- (void)removeWithURL:(id)url completely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)removeTask:(LLDownloadTask *)task completely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;

- (void)moveTaskFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;

// MARK: - total task control

- (void)totalStartOnMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLSessionManager *manager))handler;
- (void)totalSuspendOnMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLSessionManager *manager))handler;
- (void)totalCancelOnMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLSessionManager *manager))handler;
- (void)totalRemoveCompletely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLSessionManager *manager))handler;

- (void)tasksSortUsingComparator:(NSComparator)comparator;

// MARK: - chainable

- (instancetype)onProgress:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *manager))handler;
- (instancetype)onSuccess:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *manager))handler;
- (instancetype)onFailure:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *manager))handler;
- (instancetype)onCompletion:(BOOL)onMainQueue handler:(void (^)(LLSessionManager *manager))handler;

// MARK: - internal (used by delegate / tasks)

- (void)log:(LLLogType *)type;
- (void)updateProgress;
- (void)didCancelOrRemove:(LLDownloadTask *)task;
- (void)determineStatusFromRunningTask:(BOOL)fromRunningTask;
- (void)storeTasks;
- (void)maintainAppendTask:(LLDownloadTask *)task;
- (void)maintainRemoveTask:(LLDownloadTask *)task;
- (void)maintainSucceededTask:(LLDownloadTask *)task;
- (void)maintainAppendRunningTask:(LLDownloadTask *)task;
- (void)maintainRemoveRunningTask:(LLDownloadTask *)task;
- (void)updateUrlMapperWithTask:(LLDownloadTask *)task;
- (nullable LLDownloadTask *)mapTaskForCurrentURL:(NSURL *)currentURL;
- (BOOL)shouldRun;

// Background URLSession delegate entry points
- (void)didBecomeInvalidationWithError:(nullable NSError *)error;
- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
