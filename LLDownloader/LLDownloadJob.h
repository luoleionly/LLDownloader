//
//  LLDownloadJob.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import <Foundation/Foundation.h>
#import "LLDownloadCache.h"

typedef NS_ENUM(NSUInteger, LLDownloadJobState) {
    LLDownloadJobStateReady,        //准备中
    LLDownloadJobStateWaiting,      //等待中
    LLDownloadJobStateDownloading,  //正在下载
    LLDownloadJobStateSuspend,      //暂停
    LLDownloadJobStateComplete,     //下载完成
    LLDownloadJobStateFailed,       //下载失败
    LLDownloadJobStateUnknown,      //未知状态
};

typedef NS_ENUM(NSUInteger, Validation) {
    ValidationUnkown,
    ValidationCorrect,
    ValidationIncorrect,
};

//typedef NS_ENUM(NSUInteger, <#MyEnum#>) {
//    <#MyEnumValueA#>,
//    <#MyEnumValueB#>,
//    <#MyEnumValueC#>,
//};

@interface LLDownloadJobInfo : NSObject<NSCoding,NSSecureCoding>

// 当前标识符
@property (nonatomic, copy)   NSString *requestId;
// 文件下载地址
@property (nonatomic, copy)   NSString *url;
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

@end

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadJob : NSObject

@property (nonatomic, weak) LLDownloadCache *cache;

@property (nonatomic, strong, readonly) LLDownloadJobInfo *jobInfo;

- (instancetype)initWithJobInfo:(LLDownloadJobInfo *)jobInfo;

@end

NS_ASSUME_NONNULL_END
