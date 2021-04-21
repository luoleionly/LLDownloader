//
//  LLDownloadJobQueue.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadJobQueue : NSObject

// 允许同时下载的数量 
@property (nonatomic, assign) NSInteger maxDownloadCount;




@end

NS_ASSUME_NONNULL_END
