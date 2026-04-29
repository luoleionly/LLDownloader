//
//  LLCache.m
//  LLDownloader
//

#import "LLCache.h"
#import "LLDownloadTask.h"
#import "LLSessionManager.h"
#import "LLError.h"
#import "LLCommon.h"
#import "LLProtected.h"
#import "LLExecuter.h"
#import "NSString+LLURL.h"

@interface LLCache ()
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) LLDebouncer *debouncer;
@property (nonatomic, strong) NSFileManager *fileManager;
@end

@implementation LLCache

+ (NSString *)defaultDiskCachePathWithCacheName:(NSString *)cacheName {
    NSString *dst = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [dst stringByAppendingPathComponent:cacheName];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier downloadPath:nil downloadTmpPath:nil downloadFilePath:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                      downloadPath:(NSString *)downloadPath
                   downloadTmpPath:(NSString *)downloadTmpPath
                  downloadFilePath:(NSString *)downloadFilePath {
    if ((self = [super init])) {
        _identifier = [identifier copy];
        NSString *ioQueueName = [NSString stringWithFormat:@"com.LL.Cache.ioQueue.%@", identifier];
        _ioQueue = dispatch_queue_create([ioQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        _debouncer = [[LLDebouncer alloc] initWithTimeInterval:0.2];
        _fileManager = [NSFileManager defaultManager];

        NSString *cacheName = [NSString stringWithFormat:@"com.Daniels.LL.Cache.%@", identifier];
        NSString *diskCachePath = [[self class] defaultDiskCachePathWithCacheName:cacheName];

        NSString *path = downloadPath ?: [diskCachePath stringByAppendingPathComponent:@"Downloads"];
        _downloadPath = [path copy];
        _downloadTmpPath = [(downloadTmpPath ?: [path stringByAppendingPathComponent:@"Tmp"]) copy];
        _downloadFilePath = [(downloadFilePath ?: [path stringByAppendingPathComponent:@"File"]) copy];

        [self createDirectory];
    }
    return self;
}

- (void)invalidate {
    // Swift version cleared decoder.userInfo[.cache]; NSKeyedUnarchiver-based impl has no per-instance state to clear.
}

#pragma mark - file

- (void)createDirectory {
    for (NSString *p in @[_downloadPath, _downloadTmpPath, _downloadFilePath]) {
        if (![_fileManager fileExistsAtPath:p]) {
            NSError *err = nil;
            if (![_fileManager createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"create directory failed"
                                                             error:[LLError cacheCannotCreateDirectoryAtPath:p underlying:err]]];
            }
        }
    }
}

- (NSString *)filePathForFileName:(NSString *)fileName {
    if (fileName.length == 0) return nil;
    return [_downloadFilePath stringByAppendingPathComponent:fileName];
}

- (NSURL *)fileURLForFileName:(NSString *)fileName {
    NSString *p = [self filePathForFileName:fileName];
    return p ? [NSURL fileURLWithPath:p] : nil;
}

- (BOOL)fileExistsWithFileName:(NSString *)fileName {
    NSString *p = [self filePathForFileName:fileName];
    return p && [_fileManager fileExistsAtPath:p];
}

- (NSString *)filePathForURL:(id)url {
    NSURL *u = LLAsURL(url, NULL);
    if (!u) return nil;
    return [self filePathForFileName:u.ll_fileName];
}

- (NSURL *)fileURLForURL:(id)url {
    NSString *p = [self filePathForURL:url];
    return p ? [NSURL fileURLWithPath:p] : nil;
}

- (BOOL)fileExistsWithURL:(id)url {
    NSString *p = [self filePathForURL:url];
    return p && [_fileManager fileExistsAtPath:p];
}

- (void)clearDiskCacheOnMainQueue:(BOOL)onMainQueue handler:(void (^)(LLCache *))handler {
    dispatch_async(_ioQueue, ^{
        if (![self.fileManager fileExistsAtPath:self.downloadPath]) return;
        NSError *err = nil;
        if (![self.fileManager removeItemAtPath:self.downloadPath error:&err]) {
            [self.manager log:[LLLogType errorLogWithMessage:@"clear disk cache failed"
                                                         error:[LLError cacheCannotRemoveItemAtPath:self.downloadPath underlying:err]]];
        }
        [self createDirectory];
        if (handler) {
            [[[LLExecuter alloc] initWithOnMainQueue:onMainQueue handler:^(LLCache *c) { handler(c); }] execute:self];
        }
    });
}

#pragma mark - retrieve

- (NSArray<LLDownloadTask *> *)retrieveAllTasks {
    __block NSArray<LLDownloadTask *> *result = @[];
    dispatch_sync(_ioQueue, ^{
        NSString *path = [self.downloadPath stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@_Tasks.plist", self.identifier]];
        if (![self.fileManager fileExistsAtPath:path]) { return; }
        NSError *err = nil;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]
                                             options:0
                                               error:&err];
        if (!data) {
            [self.manager log:[LLLogType errorLogWithMessage:@"retrieve all tasks failed"
                                                         error:[LLError cacheCannotRetrieveAllTasksAtPath:path underlying:err]]];
            return;
        }
        NSError *err2 = nil;
        NSSet *allowed = [NSSet setWithObjects:
                          [NSArray class],
                          [LLDownloadTask class],
                          [NSString class], [NSNumber class], [NSData class], [NSURL class],
                          [NSDictionary class], [NSError class], [NSHTTPURLResponse class], nil];
        NSArray *tasks = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowed fromData:data error:&err2];
        if (![tasks isKindOfClass:[NSArray class]]) {
            [self.manager log:[LLLogType errorLogWithMessage:@"retrieve all tasks failed"
                                                         error:[LLError cacheCannotRetrieveAllTasksAtPath:path underlying:err2]]];
            return;
        }
        for (LLDownloadTask *t in tasks) {
            t.cache = self;
            if ([t.status isEqualToString:LLStatusWaiting]) {
                t.status = LLStatusSuspended;
            }
        }
        result = tasks;
    });
    return result;
}

- (BOOL)retrieveTmpFile:(NSString *)tmpFileName {
    __block BOOL ok = NO;
    dispatch_sync(_ioQueue, ^{
        if (tmpFileName.length == 0) return;
        NSString *backupFilePath = [self.downloadTmpPath stringByAppendingPathComponent:tmpFileName];
        NSString *originFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName];
        BOOL backupExists = [self.fileManager fileExistsAtPath:backupFilePath];
        BOOL originExists = [self.fileManager fileExistsAtPath:originFilePath];
        if (!backupExists && !originExists) return;

        NSError *err = nil;
        if (originExists) {
            if (backupExists && ![self.fileManager removeItemAtPath:backupFilePath error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"retrieve tmpFile failed"
                                                             error:[LLError cacheCannotRemoveItemAtPath:backupFilePath underlying:err]]];
            }
        } else {
            if (![self.fileManager moveItemAtPath:backupFilePath toPath:originFilePath error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"retrieve tmpFile failed"
                                                             error:[LLError cacheCannotMoveItemFromPath:backupFilePath toPath:originFilePath underlying:err]]];
            }
        }
        ok = YES;
    });
    return ok;
}

#pragma mark - store

- (void)storeTasks:(NSArray<LLDownloadTask *> *)tasks {
    __weak typeof(self) wself = self;
    [self.debouncer executeOnQueue:_ioQueue work:^{
        __strong typeof(wself) self_ = wself;
        if (!self_) return;
        NSString *path = [self_.downloadPath stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@_Tasks.plist", self_.identifier]];
        NSError *err = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tasks requiringSecureCoding:YES error:&err];
        if (!data) {
            [self_.manager log:[LLLogType errorLogWithMessage:@"store tasks failed"
                                                          error:[LLError cacheCannotEncodeTasksAtPath:path underlying:err]]];
        } else {
            if (![data writeToURL:[NSURL fileURLWithPath:path] options:NSDataWritingAtomic error:&err]) {
                [self_.manager log:[LLLogType errorLogWithMessage:@"store tasks failed"
                                                              error:[LLError cacheCannotEncodeTasksAtPath:path underlying:err]]];
            }
        }
        NSString *legacy = [self_.downloadPath stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@Tasks.plist", self_.identifier]];
        [self_.fileManager removeItemAtPath:legacy error:NULL];
    }];
}

- (void)storeFileAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    dispatch_sync(_ioQueue, ^{
        NSError *err = nil;
        if (![self.fileManager moveItemAtURL:srcURL toURL:dstURL error:&err]) {
            [self.manager log:[LLLogType errorLogWithMessage:@"store file failed"
                                                         error:[LLError cacheCannotMoveItemFromPath:srcURL.absoluteString
                                                                                                     toPath:dstURL.absoluteString
                                                                                                 underlying:err]]];
        }
    });
}

- (void)storeTmpFile:(NSString *)tmpFileName {
    dispatch_sync(_ioQueue, ^{
        if (tmpFileName.length == 0) return;
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName];
        NSString *destination = [self.downloadTmpPath stringByAppendingPathComponent:tmpFileName];
        NSError *err = nil;
        if ([self.fileManager fileExistsAtPath:destination]) {
            if (![self.fileManager removeItemAtPath:destination error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"store tmpFile failed"
                                                             error:[LLError cacheCannotRemoveItemAtPath:destination underlying:err]]];
            }
        }
        if ([self.fileManager fileExistsAtPath:tmpPath]) {
            if (![self.fileManager copyItemAtPath:tmpPath toPath:destination error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"store tmpFile failed"
                                                             error:[LLError cacheCannotCopyItemFromPath:tmpPath toPath:destination underlying:err]]];
            }
        }
    });
}

- (void)updateFileName:(NSString *)filePath newFileName:(NSString *)newFileName {
    dispatch_sync(_ioQueue, ^{
        if (![self.fileManager fileExistsAtPath:filePath]) return;
        NSString *newFilePath = [self filePathForFileName:newFileName];
        NSError *err = nil;
        if (![self.fileManager moveItemAtPath:filePath toPath:newFilePath error:&err]) {
            [self.manager log:[LLLogType errorLogWithMessage:@"update fileName failed"
                                                         error:[LLError cacheCannotMoveItemFromPath:filePath toPath:newFilePath underlying:err]]];
        }
    });
}

#pragma mark - remove

- (void)removeTask:(LLDownloadTask *)task completely:(BOOL)completely {
    [self removeTmpFile:task.tmpFileName];
    if (completely) {
        [self removeFile:task.filePath];
    }
}

- (void)removeFile:(NSString *)filePath {
    dispatch_async(_ioQueue, ^{
        if ([self.fileManager fileExistsAtPath:filePath]) {
            NSError *err = nil;
            if (![self.fileManager removeItemAtPath:filePath error:&err]) {
                [self.manager log:[LLLogType errorLogWithMessage:@"remove file failed"
                                                             error:[LLError cacheCannotRemoveItemAtPath:filePath underlying:err]]];
            }
        }
    });
}

- (void)removeTmpFile:(NSString *)tmpFileName {
    dispatch_async(_ioQueue, ^{
        if (tmpFileName.length == 0) return;
        NSString *p1 = [self.downloadTmpPath stringByAppendingPathComponent:tmpFileName];
        NSString *p2 = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName];
        for (NSString *p in @[p1, p2]) {
            if ([self.fileManager fileExistsAtPath:p]) {
                NSError *err = nil;
                if (![self.fileManager removeItemAtPath:p error:&err]) {
                    [self.manager log:[LLLogType errorLogWithMessage:@"remove tmpFile failed"
                                                                 error:[LLError cacheCannotRemoveItemAtPath:p underlying:err]]];
                }
            }
        }
    });
}

@end
