//
//  LLDownLoadCache.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import "LLDownloadCache.h"
#import "LLDownloadCenter.h"

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
    dispatch_semaphore_t semaphore;
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
        semaphore = dispatch_semaphore_create(0);
        [self createDirectory];
        
    }
    return self;
}

- (void)lock
{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)unlock
{
    dispatch_semaphore_signal(semaphore);
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
    __block NSArray *jobs = [[NSArray alloc]init];
    dispatch_sync(ioQueue, ^{
        NSString *path = [self.downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Tasks.plist",self.identifier]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
            NSError *error = nil;
            NSArray *jobInfos = [[NSArray alloc]init];
            if (@available(iOS 11.0, *)) {
                jobInfos = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:data error:&error];
                if (error) {
                    NSLog(@"unarchivedObject failed");
                }
            } else {
                jobInfos = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            if (isValidNSArray(jobInfos)) {
                NSMutableArray *currentJobs = [[NSMutableArray alloc]init];
                for (LLDownloadJobInfo *jobInfo in jobInfos) {
                    LLDownloadJob *job = [[LLDownloadJob alloc]initWithJobInfo:jobInfo];
                    job.cache = self;
                    if (job.jobInfo.state == LLDownloadJobStateWaiting) {
                        job.jobInfo.state = LLDownloadJobStateSuspend;
                    }
                    addValidObjectForArray(currentJobs, job);
                }
                jobs = currentJobs.copy;
            }
        }
    });
    return jobs;
}

- (BOOL)getTmpFileWithTmpFileName:(NSString *)tmpFileName
{
    __block BOOL fileExists = NO;
    dispatch_sync(ioQueue, ^{
        if (isValidNSString(tmpFileName)) {
            NSString *backupFilePath = [self.downloadTmpPath stringByAppendingPathComponent:tmpFileName];
            NSString *originPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName];
            BOOL backupFileExists = [[NSFileManager defaultManager] fileExistsAtPath:backupFilePath];
            BOOL originFileExists = [[NSFileManager defaultManager]fileExistsAtPath:originPath];
            NSError *error = nil;
            if (originFileExists || backupFileExists) {
                if (originFileExists) {
                    [[NSFileManager defaultManager]removeItemAtPath:backupFilePath error:&error];
                    if (error) {
                        NSLog(@"removeItemAtPath backupFilePath failed...");
                    }
                } else {
                    [[NSFileManager defaultManager]moveItemAtPath:backupFilePath toPath:originPath error:&error];
                    if (error) {
                        NSLog(@"moveItemAtPath moveItemAtPath to originPath failed...");
                    }
                }
            }
            fileExists = YES;
        }
    });
    return fileExists;
}

- (void)storeJobs:(NSArray <LLDownloadJob *>*)jobs
{
    NSString *path = [self.downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Tasks.plist",self.identifier]];
    NSError *error = nil;
    if (@available(iOS 11.0, *)) {
        [NSKeyedArchiver archivedDataWithRootObject:jobs requiringSecureCoding:YES error:&error];
        if (error) {
            NSLog(@"archivedDataWithRootObject failed...");
        }
    } else {
//        PropertyListEncoder
        [NSKeyedArchiver archivedDataWithRootObject:<#(nonnull id)#>];
    }
//    [NSKeyedArchiver ]
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
