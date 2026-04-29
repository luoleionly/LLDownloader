//
//  LLDownloadTask.h
//  LLDownloader
//

#import <Foundation/Foundation.h>
#import "LLTask.h"
#import "LLFileChecksumHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadTask : LLTask

@property (nonatomic, strong, readonly, nullable) NSHTTPURLResponse *response;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly, nullable) NSString *pathExtension;

// Internal accessor for temporary file name derived from resumeData (used by Cache + SessionManager).
@property (nonatomic, copy, readonly, nullable) NSString *tmpFileName;

// Chainable validation API.
- (LLDownloadTask *)validateFileWithCode:(NSString *)code
                                     type:(LLVerificationType)type
                              onMainQueue:(BOOL)onMainQueue
                                  handler:(void (^)(LLDownloadTask *task))handler;

// Internal init — normally use SessionManager's download APIs.
- (instancetype)initWithURL:(NSURL *)url
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                   fileName:(nullable NSString *)fileName
                      cache:(LLCache *)cache
             operationQueue:(dispatch_queue_t)operationQueue;

@end

@interface NSArray (LLDownloadTaskBatch)
/// Batch helpers operating on arrays of LLDownloadTask.
- (NSArray<LLDownloadTask *> *)ll_onProgress:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *task))handler;
- (NSArray<LLDownloadTask *> *)ll_onSuccess:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *task))handler;
- (NSArray<LLDownloadTask *> *)ll_onFailure:(BOOL)onMainQueue handler:(void (^)(LLDownloadTask *task))handler;
- (NSArray<LLDownloadTask *> *)ll_validateFileWithCodes:(NSArray<NSString *> *)codes
                                                     type:(LLVerificationType)type
                                              onMainQueue:(BOOL)onMainQueue
                                                  handler:(void (^)(LLDownloadTask *task))handler;
@end

NS_ASSUME_NONNULL_END
