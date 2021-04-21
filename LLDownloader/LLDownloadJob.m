//
//  LLDownloadJob.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import "LLDownloadJob.h"

@implementation LLDownloadJobInfo

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        
        
    }
    return self;
}

@end

@interface LLDownloadJob ()
// 下载Task
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
// job模型
@property (nonatomic, strong, readwrite) LLDownloadJobInfo *jobInfo;

@end

@implementation LLDownloadJob


- (instancetype)initWithJobInfo:(LLDownloadJobInfo *)jobInfo
{
    self = [super init];
    if (self) {
        _jobInfo = jobInfo;
    }
    return self;
}

#pragma mark - Delegate callback

- (void)didWriteData:(int64_t)bytesWritten
   totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

- (void)didFinishDownloadingWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
toURL:(NSURL *)location
{
    
}

#pragma mark - Complete 出错的方式来源

- (void)didCompleteBecauseofNetWorkWithTask:(NSURLSessionTask *)task error:(NSError *)error
{
    
}

- (void)didCompleteBecauseofLocal
{
    
}

@end
