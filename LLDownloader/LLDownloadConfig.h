//
//  LLDownloadConfig.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadConfig : NSObject

// 超时时长 默认60s
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;
// 最大并发任务数
@property (nonatomic, assign) NSInteger maxConcurrentTasksLimit;
//
@property (nonatomic, assign) BOOL allowsExpensiveNetworkAccess;

@property (nonatomic, assign) BOOL allowsConstrainedNetworkAccess;
// 是否允许蜂窝网络
@property (nonatomic, assign) BOOL allowsCellularAccess;

@end

NS_ASSUME_NONNULL_END
