//
//  LLDownloadCenter.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#define LOCK(...) dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
#define UNLOCK(...) dispatch_semaphore_signal(_semaphore);

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDownloadJob;

@interface LLDownloadCenter : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *,LLDownloadJob *> *jobMapper;

// 同过当前URL获取下载任务
- (LLDownloadJob *)getJobWithCurrentURL:(NSURL *)currentURL;

- (void)didBecomeInvalidWithError:(nullable NSError *)error;

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
