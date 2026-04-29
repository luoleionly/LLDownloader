//
//  LLNotifications.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDownloadTask;
@class LLSessionManager;

FOUNDATION_EXPORT NSNotificationName const LLDownloadTaskRunningNotification;
FOUNDATION_EXPORT NSNotificationName const LLDownloadTaskDidCompleteNotification;

FOUNDATION_EXPORT NSNotificationName const LLSessionManagerRunningNotification;
FOUNDATION_EXPORT NSNotificationName const LLSessionManagerDidCompleteNotification;

FOUNDATION_EXPORT NSString *const LLNotificationDownloadTaskKey;
FOUNDATION_EXPORT NSString *const LLNotificationSessionManagerKey;

@interface NSNotification (LL)
@property (nonatomic, readonly, nullable) LLDownloadTask *ll_downloadTask;
@property (nonatomic, readonly, nullable) LLSessionManager *ll_sessionManager;
@end

@interface NSNotificationCenter (LL)
- (void)ll_postNotificationName:(NSNotificationName)name downloadTask:(LLDownloadTask *)task;
- (void)ll_postNotificationName:(NSNotificationName)name sessionManager:(LLSessionManager *)manager;
@end

NS_ASSUME_NONNULL_END
