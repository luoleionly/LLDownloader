//
//  NSData+LLHash.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (LLHash)
@property (nonatomic, readonly) NSString *ll_md5;
@property (nonatomic, readonly) NSString *ll_sha1;
@property (nonatomic, readonly) NSString *ll_sha256;
@property (nonatomic, readonly) NSString *ll_sha512;
@end

NS_ASSUME_NONNULL_END
