//
//  LLDownloadTask+Internal.h
//  LLDownloader
//

#import "LLDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

// Completion source
typedef NS_ENUM(NSInteger, LLCompletionKind) {
    LLCompletionKindLocal = 0,
    LLCompletionKindNetwork,
};

// Interrupt classification
typedef NS_ENUM(NSInteger, LLInterruptKind) {
    LLInterruptKindManual = 0,
    LLInterruptKindError,
    LLInterruptKindStatusCode,
};

@interface LLDownloadTask ()

// Setter for response (used by SessionDelegate through DownloadTask itself).
@property (nonatomic, strong, nullable) NSHTTPURLResponse *response;
@property (nonatomic, strong, nullable) NSURLSessionDownloadTask *sessionTask;

- (void)download;

- (void)suspendOnMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)cancelOnMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)removeCompletely:(BOOL)completely onMainQueue:(BOOL)onMainQueue handler:(void (^_Nullable)(LLDownloadTask *task))handler;
- (void)updateHeaders:(nullable NSDictionary<NSString *, NSString *> *)newHeaders newFileName:(nullable NSString *)newFileName;

- (void)succeededFromRunning:(BOOL)fromRunning immediately:(BOOL)immediately;

- (void)didWriteDataOnDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                     bytesWritten:(int64_t)bytesWritten
                totalBytesWritten:(int64_t)totalBytesWritten
        totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)didFinishDownloading:(NSURLSessionDownloadTask *)task toLocation:(NSURL *)location;

- (void)didCompleteLocal;
- (void)didCompleteNetwork:(NSURLSessionTask *)task error:(nullable NSError *)error;

- (void)updateSpeedAndTimeRemaining;

@end

NS_ASSUME_NONNULL_END
