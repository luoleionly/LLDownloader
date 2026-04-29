//
//  LLCache.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDownloadTask;
@class LLSessionManager;

@interface LLCache : NSObject

@property (nonatomic, copy, readonly) NSString *downloadPath;
@property (nonatomic, copy, readonly) NSString *downloadTmpPath;
@property (nonatomic, copy, readonly) NSString *downloadFilePath;
@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, weak) LLSessionManager *manager;

+ (NSString *)defaultDiskCachePathWithCacheName:(NSString *)cacheName;

- (instancetype)initWithIdentifier:(NSString *)identifier;
- (instancetype)initWithIdentifier:(NSString *)identifier
                      downloadPath:(nullable NSString *)downloadPath
                   downloadTmpPath:(nullable NSString *)downloadTmpPath
                  downloadFilePath:(nullable NSString *)downloadFilePath NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)invalidate;

#pragma mark - file

- (nullable NSString *)filePathForFileName:(NSString *)fileName;
- (nullable NSURL *)fileURLForFileName:(NSString *)fileName;
- (BOOL)fileExistsWithFileName:(NSString *)fileName;

- (nullable NSString *)filePathForURL:(id)url;
- (nullable NSURL *)fileURLForURL:(id)url;
- (BOOL)fileExistsWithURL:(id)url;

- (void)clearDiskCacheOnMainQueue:(BOOL)onMainQueue
                          handler:(void (^_Nullable)(LLCache *cache))handler;

#pragma mark - internal (used by SessionManager/DownloadTask)

- (void)createDirectory;
- (NSArray<LLDownloadTask *> *)retrieveAllTasks;
- (BOOL)retrieveTmpFile:(nullable NSString *)tmpFileName;

- (void)storeTasks:(NSArray<LLDownloadTask *> *)tasks;
- (void)storeFileAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL;
- (void)storeTmpFile:(nullable NSString *)tmpFileName;
- (void)updateFileName:(NSString *)filePath newFileName:(NSString *)newFileName;

- (void)removeTask:(LLDownloadTask *)task completely:(BOOL)completely;
- (void)removeFile:(NSString *)filePath;
- (void)removeTmpFile:(nullable NSString *)tmpFileName;

@end

NS_ASSUME_NONNULL_END
