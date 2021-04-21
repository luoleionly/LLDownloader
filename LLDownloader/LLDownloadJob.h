//
//  LLDownloadJob.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import <Foundation/Foundation.h>
#import "LLDownloadCache.h"

typedef NS_ENUM(NSUInteger, LLDownloadJobState) {
    LLDownloadJobStateWaiting,      //等待中
    LLDownloadJobStateDownloading,  //正在下载
    LLDownloadJobStateSuspended,    //暂停
    LLDownloadJobStateCanceled,     //取消
    LLDownloadJobStateFailed,       //下载失败
    LLDownloadJobStateRemoved,      //移除状态
    LLDownloadJobStateSuccessed,    //下载完成
    
    LLDownloadJobStateWillSuspend,  //即将暂停
    LLDownloadJobStateWillCancel,   //即将取消
    LLDownloadJobStateWillRemove,   //即将移除
};

typedef NS_ENUM(NSUInteger, Validation) {
    ValidationUnkown,           //未知
    ValidationCorrect,          //正确
    ValidationIncorrect,        //有误
};

typedef NS_ENUM(NSUInteger, CompletionType) {
    CompletionTypeLocal,        //本地已经存在完成
    CompletionTypeNetwork,      //网络下载完成
};

typedef NS_ENUM(NSUInteger, InterruptType) {
    InterruptTypeManual,        //手动打断
    InterruptTypeError,         //发生错误打断
    InterruptTypeStatusCode,    //错误code打断
};

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadJobInfo : NSObject<NSCoding,NSSecureCoding>
// 文件下载地址
@property (nonatomic, strong) NSURL *url;
// 当前URL
@property (nonatomic, strong) NSURL *currentURL;
// 当前文件名
@property (nonatomic, copy)   NSString *fileName;

@property (nonatomic, strong) NSMutableDictionary <NSString *,NSString *>*headers;
// 开始时间
@property (nonatomic, assign) double startDate;
// 结束时间
@property (nonatomic, assign) double endDate;
// 任务的状态
@property (atomic, assign) LLDownloadJobState state;
// 文件总大小
@property (nonatomic, assign) int64_t totalBytes;
// 文件已经下载的大小
@property (nonatomic, assign) int64_t totalBytesWritten;

@property (nonatomic, copy) NSString *verificationCode;
// 错误信息
@property (nonatomic, strong) NSData *error;
// 断点续传需要设置这个数据
@property (nonatomic, strong) NSData *resumeData;

@property (nonatomic, strong) NSURLResponse *response;

@end


@interface LLDownloadJob : NSObject

@property (nonatomic, weak) LLDownloadCache *cache;

@property (nonatomic, copy) NSString *tmpFileName;

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong, readonly) LLDownloadJobInfo *jobInfo;

- (instancetype)initWithJobInfo:(LLDownloadJobInfo *)jobInfo;

- (void)didWriteData:(int64_t)bytesWritten
   totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)didFinishDownloadingWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
toURL:(NSURL *)location;

- (void)didCompleteBecauseofNetWorkWithTask:(NSURLSessionTask *)task error:(NSError *)error;

- (void)didCompleteBecauseofLocal;

@end

NS_ASSUME_NONNULL_END
