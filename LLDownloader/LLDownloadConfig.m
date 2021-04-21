//
//  LLDownloadConfig.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import "LLDownloadConfig.h"

@implementation LLDownloadConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeoutIntervalForRequest = 60;
        _maxConcurrentTasksLimit = [self limit];
        _allowsCellularAccess = NO;
        _allowsExpensiveNetworkAccess = YES;
        _allowsConstrainedNetworkAccess = YES;
    }
    return self;
}

- (void)setMaxConcurrentTasksLimit:(NSInteger)maxConcurrentTasksLimit {
    if (maxConcurrentTasksLimit > _maxConcurrentTasksLimit) {
        return;
    } else if (maxConcurrentTasksLimit < 1) {
        _maxConcurrentTasksLimit = 1;
    } else {
        _maxConcurrentTasksLimit = maxConcurrentTasksLimit;
    }
}

- (NSInteger)limit {
    NSInteger limit = 0;
    if (@available(iOS 11.0, *)) {
        limit = 6;
    } else {
        limit = 3;
    }
    return limit;
}

@end
