//
//  NSFileManager+LLAvailableCapacity.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (LLAvailableCapacity)
@property (nonatomic, readonly) int64_t ll_freeDiskSpaceInBytes;
@end

NS_ASSUME_NONNULL_END
