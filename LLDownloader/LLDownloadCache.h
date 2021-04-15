//
//  LLDownLoadCache.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "LLValidObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadCache : NSObject

+ (NSString *)defaultDiskCachePathClosureWithCacheName:(NSString *)cacheName;

- (NSString *)filePathWithFileName:(NSString *)fileName;

- (NSURL *)fileURLWithFileName:(NSString *)fileName;

- (BOOL)fileExistsWithFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
