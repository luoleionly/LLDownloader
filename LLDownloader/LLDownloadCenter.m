//
//  LLDownloadCenter.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/13.
//

#import "LLDownloadCenter.h"
#import "LLDownloadJobQueue.h"
#import "LLDownloadSessionDelegate.h"
#import "LLDownloadConfig.h"
#import "LLTimer.h"
#import "LLDownloadJob.h"

typedef void(^CompletionHandler)(void);

static NSString * const backGroundSessionIdentifier = @"LLDownLoader_backGroundSessionIdentifier";

@interface LLDownloadCenter ()<NSURLSessionDelegate>

// download session
@property (nonatomic, strong) NSURLSession *session;
// 回调代理的队列
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
// 任务下载队列
@property (nonatomic, strong) LLDownloadJobQueue *jobQueue;
// 缓存模块
@property (nonatomic, strong) LLDownloadCache *cache;
// 
@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) CompletionHandler completionHandler;

@property (nonatomic, strong) LLDownloadConfig *configuration;
// 网络菊花图标控制
@property (nonatomic, assign) BOOL isControlNetworkActivityIndicator;
// 下载速度的timer
@property (nonatomic, strong) LLTimer *timer;
// 所有的任务
@property (nonatomic, strong) NSMutableArray<LLDownloadJob *> *jobs;

@property (nonatomic, strong) NSMutableDictionary<NSString *,LLDownloadJob *> *jobMapper;

@property (nonatomic, strong) NSMutableDictionary<NSURL *,NSURL *> *urlMapper;
// 正在执行的任务
@property (nonatomic, strong) NSMutableArray<LLDownloadJob *> *runningJobs;
// 重新开始的任务
@property (nonatomic, strong) NSMutableArray<LLDownloadJob *> *restartJobs;
// 下载成功的任务
@property (nonatomic, strong) NSMutableArray<LLDownloadJob *> *successedJobs;

@property (nonatomic, assign) int64_t speed;

@property (nonatomic, assign) int64_t timeRemaining;

@end

@implementation LLDownloadCenter
{
    dispatch_queue_t _queue;
    dispatch_semaphore_t _semaphore;
}

//+ (instancetype)center {
//    static LLDownloadCenter *center = nil;
//    static dispatch_once_t once;
//    dispatch_once(&once, ^{
//        center = [[self alloc]init];
//    });
//    return center;
//}

- (instancetype)initWithIdentifier:(NSString *)identifier configuration:(LLDownloadConfig *)configuration cache:(LLDownloadCache *)cache
{
    if (self = [self init]) {
        _identifier = [NSString stringWithFormat:@"%@.%@",[NSBundle mainBundle].bundleIdentifier,identifier];
        _semaphore = dispatch_semaphore_create(0);
        _queue = dispatch_queue_create("com.lldownloader.SessionManager.operationQueue", NULL);
        _cache = [[LLDownloadCache alloc]initWithIdentifier:identifier];
        _cache.downloadCenter = self;
        _jobs = [NSMutableArray new];
        _jobMapper = [NSMutableDictionary new];
        _urlMapper = [NSMutableDictionary new];
        _runningJobs = [NSMutableArray new];
        _restartJobs = [NSMutableArray new];
        _successedJobs = [NSMutableArray new];
        NSArray *jobs = [_cache getAllJobs];
        for (LLDownloadJob *job in jobs) {
            [self appendJob:job];
            if (job.jobInfo.state == LLDownloadJobStateSuccessed) {
                addValidObjectForArray(self.successedJobs, job);
            }
        }
        
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionDelegateQueue = [[NSOperationQueue alloc]init];
        _sessionDelegateQueue.maxConcurrentOperationCount = 1;
        [self configSession];
        [self configJobQueue];
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)configSession {
    NSURLSessionConfiguration *configure = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backGroundSessionIdentifier];
    self.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.sessionDelegateQueue];
}

- (void)configJobQueue {
    self.jobQueue = [[LLDownloadJobQueue alloc]init];
}

#pragma mark - Getter && Setter
// to do somethings
- (void)setConfiguration:(LLDownloadConfig *)configuration
{
    _configuration = configuration;
    
}


#pragma mark - Private helper

- (void)appendJob:(LLDownloadJob *)job
{
    LOCK(_semaphore)
    addValidObjectForArray(self.jobs, job);
    setValidObjectForDictionary(self.jobMapper, job.jobInfo.url.absoluteString,job);
    [self.urlMapper setObject:job.jobInfo.url forKey:job.jobInfo.currentURL];
    UNLOCK(_semaphore)
}

- (void)removeJob:(LLDownloadJob *)job
{
    LOCK(_semaphore)
    
    UNLOCK(_semaphore)
}

- (void)successJob:(LLDownloadJob *)job
{
    
}

- (void)appendRunningJob:(LLDownloadJob *)job
{
    
}

- (void)removeRunningJob:(LLDownloadJob *)job
{
    
}

#pragma mark - callBack

- (void)didBecomeInvalidWithError:(nullable NSError *)error
{
    
}

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}

#pragma mark - Public Help

// 同过当前URL获取下载任务
- (LLDownloadJob *)getJobWithCurrentURL:(NSURL *)currentURL
{
    if (!currentURL) {
        return nil;
    }
    NSURL *url = [self.urlMapper objectForKey:currentURL]?:currentURL;
    return getValidObjectFromDictionary(self.jobMapper, url.absoluteString);
}

@end
