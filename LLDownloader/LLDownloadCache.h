//
//  LLDownLoadCache.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "LLValidObject.h"
#import "LLDownloadJob.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadCache : NSObject

+ (NSString *)defaultDiskCachePathClosureWithCacheName:(NSString *)cacheName;

- (NSString *)filePathWithFileName:(NSString *)fileName;

- (NSURL *)fileURLWithFileName:(NSString *)fileName;

- (BOOL)fileExistsWithFileName:(NSString *)fileName;

- (NSArray <LLDownloadJob *>*)getAllJobs;

- (BOOL)getTmpFileWithTmpFileName:(NSString *)tmpFileName;



@end

NS_ASSUME_NONNULL_END
