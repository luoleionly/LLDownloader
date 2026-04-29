//
//  NSArray+LLSafe.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant ObjectType> (LLSafe)
- (nullable ObjectType)ll_safeObjectAtIndex:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
