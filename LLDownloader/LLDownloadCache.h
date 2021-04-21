//
//  LLDownLoadCache.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "LLValidObject.h"
#import "LLDownloadJob.h"
#import "LLDownloadCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadCache : NSObject

@property (nonatomic, weak) LLDownloadCenter *downloadCenter;

- (instancetype)initWithIdentifier:(NSString *)identifier;

+ (NSString *)defaultDiskCachePathClosureWithCacheName:(NSString *)cacheName;

- (NSString *)filePathWithFileName:(NSString *)fileName;

- (NSURL *)fileURLWithFileName:(NSString *)fileName;

- (BOOL)fileExistsWithFileName:(NSString *)fileName;

- (NSArray <LLDownloadJob *>*)getAllJobs;

- (BOOL)getTmpFileWithTmpFileName:(NSString *)tmpFileName;

- (void)storeJobs:(NSArray <LLDownloadJob *>*)jobs;

- (void)removeJob:(LLDownloadJob *)job needRemoveFile:(BOOL)need;

- (void)removeFileWithFilePath:(NSString *)filePtah;

- (void)removeTmpFileWithTmpFileName:(NSString *)tmpFileName;

@end

NS_ASSUME_NONNULL_END
