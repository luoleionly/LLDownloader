//
//  LLNotifications.m
//  LLDownloader
//

#import "LLNotifications.h"

NSNotificationName const LLDownloadTaskRunningNotification = @"com.LL.notification.name.downloadTask.running";
NSNotificationName const LLDownloadTaskDidCompleteNotification = @"com.LL.notification.name.downloadTask.didComplete";

NSNotificationName const LLSessionManagerRunningNotification = @"com.LL.notification.name.sessionManager.running";
NSNotificationName const LLSessionManagerDidCompleteNotification = @"com.LL.notification.name.sessionManager.didComplete";

NSString *const LLNotificationDownloadTaskKey = @"com.LL.notification.key.downloadTask";
NSString *const LLNotificationSessionManagerKey = @"com.LL.notification.key.sessionManagerKey";

@implementation NSNotification (LL)
- (LLDownloadTask *)ll_downloadTask {
    return self.userInfo[LLNotificationDownloadTaskKey];
}
- (LLSessionManager *)ll_sessionManager {
    return self.userInfo[LLNotificationSessionManagerKey];
}
@end

@implementation NSNotificationCenter (LL)
- (void)ll_postNotificationName:(NSNotificationName)name downloadTask:(LLDownloadTask *)task {
    [self postNotificationName:name object:nil userInfo:task ? @{LLNotificationDownloadTaskKey: task} : nil];
}
- (void)ll_postNotificationName:(NSNotificationName)name sessionManager:(LLSessionManager *)manager {
    [self postNotificationName:name object:nil userInfo:manager ? @{LLNotificationSessionManagerKey: manager} : nil];
}
@end
