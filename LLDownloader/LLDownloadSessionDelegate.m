//
//  LLDownloadSessionDelegate.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import "LLDownloadSessionDelegate.h"
#import "LLDownloadJob.h"
#import "LLValidObject.h"

@interface LLDownloadSessionDelegate () <NSURLSessionDownloadDelegate>

@end

@implementation LLDownloadSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    [self.center didBecomeInvalidWithError:error];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    [self.center didFinishEventsForBackgroundURLSession:session];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location
{
    if (!self.center || !downloadTask.currentRequest || !downloadTask.currentRequest.URL) {
        return;
    }
    NSURL *currentURL = downloadTask.currentRequest.URL;
    LLDownloadJob *job = [self.center getJobWithCurrentURL:currentURL];
    if (!job) {
        NSLog(@"urlSession (_:downloadTask:didFinishDownloadingTo:) get job failed...");
        return;
    }
    [job didFinishDownloadingWithDownloadTask:downloadTask toURL:location];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (!self.center || !downloadTask.currentRequest || !downloadTask.currentRequest.URL) {
        return;
    }
    NSURL *currentURL = downloadTask.currentRequest.URL;
    LLDownloadJob *job = [self.center getJobWithCurrentURL:currentURL];
    if (!job) {
        NSLog(@"urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:) get job failed...");
        return;
    }
    [job didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(nullable NSError *)error
{
    if (!self.center) {
        return;
    }
    if (task.currentRequest && task.currentRequest.URL) {
        NSURL *currentURL = task.currentRequest.URL;
        LLDownloadJob *job = [self.center getJobWithCurrentURL:currentURL];
        if (!job) {
            NSLog(@"urlSession(_:task:didCompleteWithError:) failed...");
            return;
        }
        [job didCompleteBecauseofNetWorkWithTask:task error:error];
    } else {
        if (error) {
            NSURL *errorURL = error.userInfo[NSURLErrorFailingURLErrorKey];
            if (errorURL) {
                LLDownloadJob *job = [self.center getJobWithCurrentURL:errorURL];
                if (!job) {
                    return;
                }
                [job didCompleteBecauseofNetWorkWithTask:task error:error];
            }
        }
    }
}

@end
