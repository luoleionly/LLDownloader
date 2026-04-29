//
//  NSArray+LLSafe.m
//  LLDownloader
//

#import "NSArray+LLSafe.h"

@implementation NSArray (LLSafe)
- (id)ll_safeObjectAtIndex:(NSInteger)index {
    if (index >= 0 && (NSUInteger)index < self.count) {
        return self[(NSUInteger)index];
    }
    return nil;
}
@end
