//
//  NSString+Hash.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Hash)

- (NSString *)md5;

- (NSString *)sha1;

- (NSString *)sha256;

- (NSString *)sha512;

@end

NS_ASSUME_NONNULL_END
