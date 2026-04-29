//
//  NSString+LLHash.m
//  LLDownloader
//

#import "NSString+LLHash.h"
#import "NSData+LLHash.h"

@implementation NSString (LLHash)

- (NSString *)ll_md5 {
    NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
    return d ? d.ll_md5 : self;
}

- (NSString *)ll_sha1 {
    NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
    return d ? d.ll_sha1 : self;
}

- (NSString *)ll_sha256 {
    NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
    return d ? d.ll_sha256 : self;
}

- (NSString *)ll_sha512 {
    NSData *d = [self dataUsingEncoding:NSUTF8StringEncoding];
    return d ? d.ll_sha512 : self;
}

@end
