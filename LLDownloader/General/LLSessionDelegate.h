//
//  LLSessionDelegate.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LLSessionManager;

@interface LLSessionDelegate : NSObject <NSURLSessionDownloadDelegate>
@property (nonatomic, weak, nullable) LLSessionManager *manager;
@end

// Associates a LLDownloadTask with a URLSessionTask for identity lookup.
@class LLDownloadTask;
@interface NSURLSessionTask (LL)
@property (nonatomic, weak, nullable) LLDownloadTask *ll_task;
@end

NS_ASSUME_NONNULL_END
