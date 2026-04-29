//
//  NSFileManager+LLAvailableCapacity.m
//  LLDownloader
//

#import "NSFileManager+LLAvailableCapacity.h"

@implementation NSFileManager (LLAvailableCapacity)

- (int64_t)ll_freeDiskSpaceInBytes {
    NSURL *url = [NSURL fileURLWithPath:NSHomeDirectory()];
    NSError *err = nil;
    NSDictionary *values = [url resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&err];
    NSNumber *n = values[NSURLVolumeAvailableCapacityForImportantUsageKey];
    return n ? n.longLongValue : 0;
}

@end
