//
//  NSNumber+LLTaskInfo.m
//  LLDownloader
//

#import "NSNumber+LLTaskInfo.h"

@implementation NSNumber (LLTaskInfo)

- (NSString *)ll_convertSpeedToString {
    return [NSString stringWithFormat:@"%@/s", [self ll_convertBytesToString]];
}

- (NSString *)ll_convertTimeToString {
    NSDateComponentsFormatter *f = [[NSDateComponentsFormatter alloc] init];
    f.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
    NSString *s = [f stringFromTimeInterval:(NSTimeInterval)self.longLongValue];
    return s ?: @"";
}

- (NSString *)ll_convertBytesToString {
    return [NSByteCountFormatter stringFromByteCount:self.longLongValue
                                          countStyle:NSByteCountFormatterCountStyleFile];
}

- (NSString *)ll_convertTimeToDateString {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.doubleValue];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [f stringFromDate:date];
}

@end
