//
//  LLSessionConfiguration.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLSessionConfiguration : NSObject <NSCopying>

@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest; // default 60.0

/// Clamped to [1, 6]. Default is 6.
@property (nonatomic, assign) NSInteger maxConcurrentTasksLimit;

@property (nonatomic, assign) BOOL allowsExpensiveNetworkAccess;    // default YES
@property (nonatomic, assign) BOOL allowsConstrainedNetworkAccess;  // default YES
@property (nonatomic, assign) BOOL allowsCellularAccess;            // default NO

@end

NS_ASSUME_NONNULL_END
