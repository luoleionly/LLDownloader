//
//  LLDownloadCenter.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import "LLDownloadCenter.h"
#import "LLDownloadJobQueue.h"
#import "LLDownloadSessionDelegate.h"

static NSString * const backGroundSessionIdentifier = @"LLDownLoader_backGroundSessionIdentifier";

@interface LLDownloadCenter ()<NSURLSessionDelegate>

// download session
@property (nonatomic, strong) NSURLSession *session;
// 回调代理的队列
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
// 任务下载队列
@property (nonatomic, strong) LLDownloadJobQueue *jobQueue;

@end

@implementation LLDownloadCenter

+ (instancetype)center {
    static LLDownloadCenter *center = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        center = [[self alloc]init];
    });
    return center;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionDelegateQueue = [[NSOperationQueue alloc]init];
        _sessionDelegateQueue.maxConcurrentOperationCount = 1;
        [self configSession];
        [self configJobQueue];
    }
    return self;
}

- (void)configSession {
    NSURLSessionConfiguration *configure = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backGroundSessionIdentifier];
    self.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.sessionDelegateQueue];
}

- (void)configJobQueue {
    self.jobQueue = [[LLDownloadJobQueue alloc]init];
}


@end
