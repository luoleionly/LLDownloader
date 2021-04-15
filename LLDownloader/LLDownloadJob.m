//
//  LLDownloadJob.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import "LLDownloadJob.h"

@implementation LLDownloadJobInfo

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
@property (nonatomic, strong) LLDownloadJobInfo *jobInfo;

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



@end
