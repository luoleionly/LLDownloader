//
//  LLDownloadSessionDelegate.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "LLDownloadCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLDownloadSessionDelegate : NSObject

@property (nonatomic, weak) LLDownloadCenter *center;

@end

NS_ASSUME_NONNULL_END
