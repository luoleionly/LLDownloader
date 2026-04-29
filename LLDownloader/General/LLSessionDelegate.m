//
//  LLSessionDelegate.m
//  LLDownloader
//

#import "LLSessionDelegate.h"
#import "LLSessionManager.h"
#import "LLDownloadTask.h"
#import "LLDownloadTask+Internal.h"
#import "LLError.h"
#import "LLCommon.h"
#import <objc/runtime.h>

static const void *kLLTaskKey = &kLLTaskKey;

@implementation NSURLSessionTask (LL)

- (LLDownloadTask *)ll_task {
    return objc_getAssociatedObject(self, kLLTaskKey);
}

- (void)setLl_task:(LLDownloadTask *)task {
    objc_setAssociatedObject(self, kLLTaskKey, task, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation LLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self.manager didBecomeInvalidationWithError:error];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    [self.manager didFinishEventsForBackgroundURLSession:session];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    LLSessionManager *manager = self.manager;
    if (!manager) return;
    LLDownloadTask *task = downloadTask.ll_task;
    if (!task) {
        NSURL *currentURL = downloadTask.currentRequest.URL;
        if (!currentURL) return;
        task = [manager mapTaskForCurrentURL:currentURL];
        if (!task) {
            [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)"
                                                   error:[LLError fetchDownloadTaskFailedWithURL:currentURL]]];
            return;
        }
        downloadTask.ll_task = task;
    }
    [task didWriteDataOnDownloadTask:downloadTask
                        bytesWritten:bytesWritten
                   totalBytesWritten:totalBytesWritten
           totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    LLSessionManager *manager = self.manager;
    if (!manager) return;
    LLDownloadTask *task = downloadTask.ll_task;
    if (!task) {
        NSURL *currentURL = downloadTask.currentRequest.URL;
        if (!currentURL) return;
        task = [manager mapTaskForCurrentURL:currentURL];
        if (!task) {
            [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:downloadTask:didFinishDownloadingTo:)"
                                                   error:[LLError fetchDownloadTaskFailedWithURL:currentURL]]];
            return;
        }
        downloadTask.ll_task = task;
    }
    [task didFinishDownloading:downloadTask toLocation:location];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    LLSessionManager *manager = self.manager;
    if (!manager) return;

    LLDownloadTask *downloadTask = task.ll_task;
    if (downloadTask) {
        [downloadTask didCompleteNetwork:task error:error];
        return;
    }

    NSURL *currentURL = task.currentRequest.URL;
    if (currentURL) {
        LLDownloadTask *dt = [manager mapTaskForCurrentURL:currentURL];
        if (!dt) {
            [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:task:didCompleteWithError:)"
                                                   error:[LLError fetchDownloadTaskFailedWithURL:currentURL]]];
            return;
        }
        task.ll_task = dt;
        [dt didCompleteNetwork:task error:error];
    } else if (error) {
        NSURL *errorURL = error.userInfo[NSURLErrorFailingURLErrorKey];
        if ([errorURL isKindOfClass:[NSURL class]]) {
            LLDownloadTask *dt = [manager mapTaskForCurrentURL:errorURL];
            if (!dt) {
                [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:task:didCompleteWithError:)"
                                                       error:[LLError fetchDownloadTaskFailedWithURL:errorURL]]];
                [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:task:didCompleteWithError:)" error:error]];
                return;
            }
            task.ll_task = dt;
            [dt didCompleteNetwork:task error:error];
        } else {
            [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:task:didCompleteWithError:)" error:error]];
        }
    } else {
        [manager log:[LLLogType errorLogWithMessage:@"urlSession(_:task:didCompleteWithError:)" error:[LLError unknown]]];
    }
}

@end
