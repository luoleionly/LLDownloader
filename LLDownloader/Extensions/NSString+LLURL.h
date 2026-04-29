//
//  NSString+LLURL.h
//  LLDownloader
//
//  Helpers for coercing URL-ish values to NSURL — Objective-C analogue to
//  the Swift `URLConvertible` protocol.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Accepts NSURL, NSString, or NSURLComponents. Returns nil (with optional error) if invalid.
FOUNDATION_EXPORT NSURL *_Nullable LLAsURL(id _Nullable urlOrString, NSError *_Nullable *_Nullable error);

@interface NSURL (LL)
/// Returns `<md5(absoluteString)>[.ext]` used as the default on-disk file name for a URL.
@property (nonatomic, readonly) NSString *ll_fileName;
@end

NS_ASSUME_NONNULL_END
