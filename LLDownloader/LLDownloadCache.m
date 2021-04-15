//
//  LLDownLoadCache.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import "LLDownloadCache.h"
#import "LLDownloadCenter.h"
#import "LLDownloadJob.h"

@interface LLDownloadCache ()

@property (nonatomic, copy) NSString *downloadPath;
@property (nonatomic, copy) NSString *downloadTmpPath;
@property (nonatomic, copy) NSString *downloadFilePath;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, weak) LLDownloadCenter *downloadCenter;

@end

@implementation LLDownloadCache
{
    dispatch_queue_t ioQueue;
}


- (instancetype)initWithIdentifier:(NSString *)identifier downloadPath:(NSString *)downloadPath downloadTmpPath:(NSString *)downloadTmpPath downloadFilePath:(NSString *)downloadFilePath
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        NSString *ioQueueName = [NSString stringWithFormat:@"com.lldownload.Cache.ioQueue%@",identifier];
        ioQueue = dispatch_queue_create(ioQueueName.UTF8String, DISPATCH_QUEUE_SERIAL);
        NSString *cacheName = [NSString stringWithFormat:@"com.lldownload.Cache.cache%@",identifier];
        NSString *diskCachePath = [LLDownloadCache defaultDiskCachePathClosureWithCacheName:cacheName];
        _downloadPath = [diskCachePath stringByAppendingPathComponent:@"Downloads"];
        _downloadFilePath = [_downloadPath stringByAppendingPathComponent:@"File"];
        _downloadTmpPath = [_downloadPath stringByAppendingPathComponent:@"Tmp"];
        [self createDirectory];
        
    }
    return self;
}

#pragma mark - Public File

+ (NSString *)defaultDiskCachePathClosureWithCacheName:(NSString *)cacheName
{
    NSString *dstPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES).firstObject;
    return [dstPath stringByAppendingPathComponent:cacheName];
}

- (NSString *)filePathWithFileName:(NSString *)fileName
{
    if (!isValidNSString(fileName)) {
        return nil;
    }
    return [self.downloadFilePath stringByAppendingPathComponent:fileName];
}

- (NSURL *)fileURLWithFileName:(NSString *)fileName
{
    if (!isValidNSString(fileName)) {
        return nil;
    }
    return [NSURL URLWithString:[self filePathWithFileName:fileName]];
}

- (BOOL)fileExistsWithFileName:(NSString *)fileName
{
    NSString *filePath = [self filePathWithFileName:fileName];
    if (isValidNSString(filePath)) {
        return [[NSFileManager defaultManager]fileExistsAtPath:filePath];
    } else {
        return NO;
    }
}

- (void)clearDiskCacheOnMainQueue:(BOOL)onMainQueue Handler:(void(^)(LLDownloadCache *cache))handler{
    dispatch_async(ioQueue, ^{
        NSFileManager *fileMan = [NSFileManager defaultManager];
        if (![fileMan fileExistsAtPath:self.downloadPath]) {
            return;
        }
        NSError *error = nil;
        [fileMan removeItemAtPath:self.downloadPath error:&error];
        if (error) {
            NSLog(@"removeItemAtPath downloadPath failed...");
        }
        [self createDirectory];
        if (handler) {
            if (onMainQueue) {
                dispatch_async_main_safe(^{
                    handler(self);
                });
            } else {
                handler(self);
            }
        }
    });
}

#pragma mark - Public Get

- (NSArray <LLDownloadJob *>*)getAllJobs
{
    dispatch_async(ioQueue, ^{
        NSString *path = [self.downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Tasks.plist",self.identifier]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
            
        }
    });
}

#pragma mark - Private

- (void)createDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.downloadPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:self.downloadPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"createDirectoryAtPath downloadPath failed..");
        }
    }
    if (![fileManager fileExistsAtPath:self.downloadFilePath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:self.downloadFilePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"createDirectoryAtPath downloadFilePath failed..");
        }
    }
    if (![fileManager fileExistsAtPath:self.downloadTmpPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:self.downloadTmpPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"createDirectoryAtPath downloadTmpPath failed..");
        }
    }
}

@end
