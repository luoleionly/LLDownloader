//
//  NSNumber+LLTaskInfo.h
//  LLDownloader
//
//  Replacements for the Swift `Int64+TaskInfo` / `Double+TaskInfo` extensions.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNumber (LLTaskInfo)

/// Interpret as bytes/sec and render as "<size>/s".
- (NSString *)ll_convertSpeedToString;

/// Interpret as seconds and render "00:00:00"-style via DateComponentsFormatter positional style.
- (NSString *)ll_convertTimeToString;

/// Render byte count with ByteCountFormatter (file style).
- (NSString *)ll_convertBytesToString;

/// Interpret as POSIX timestamp (seconds since 1970) and render "yyyy-MM-dd HH:mm:ss".
- (NSString *)ll_convertTimeToDateString;

@end

NS_ASSUME_NONNULL_END
