//
//  NSData+Hash.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import "NSData+Hash.h"
#include <CommonCrypto/CommonCrypto.h>

@implementation NSData (Hash)

- (NSString *)md5
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    return [NSString stringWithFormat:
           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
           result[0], result[1], result[2], result[3],
           result[4], result[5], result[6], result[7],
           result[8], result[9], result[10], result[11],
           result[12], result[13], result[14], result[15]
           ];
}

- (NSString *)sha1
{
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, result);
    NSMutableString *hash = [NSMutableString
                             stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

- (NSString *)sha256
{
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(self.bytes, (CC_LONG)self.length, result);
    NSMutableString *hash = [NSMutableString
                             stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

- (NSString *)sha512
{
    unsigned char result[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(self.bytes, (CC_LONG)self.length, result);
    NSMutableString *hash = [NSMutableString
                             stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

@end
