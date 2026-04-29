//
//  NSData+LLHash.m
//  LLDownloader
//

#import "NSData+LLHash.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *LLHexFromBytes(const uint8_t *bytes, NSUInteger len) {
    NSMutableString *s = [NSMutableString stringWithCapacity:len * 2];
    for (NSUInteger i = 0; i < len; i++) {
        [s appendFormat:@"%02x", bytes[i]];
    }
    return s;
}

@implementation NSData (LLHash)

- (NSString *)ll_md5 {
    uint8_t d[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, d);
    return LLHexFromBytes(d, CC_MD5_DIGEST_LENGTH);
}

- (NSString *)ll_sha1 {
    uint8_t d[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, d);
    return LLHexFromBytes(d, CC_SHA1_DIGEST_LENGTH);
}

- (NSString *)ll_sha256 {
    uint8_t d[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(self.bytes, (CC_LONG)self.length, d);
    return LLHexFromBytes(d, CC_SHA256_DIGEST_LENGTH);
}

- (NSString *)ll_sha512 {
    uint8_t d[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(self.bytes, (CC_LONG)self.length, d);
    return LLHexFromBytes(d, CC_SHA512_DIGEST_LENGTH);
}

@end
