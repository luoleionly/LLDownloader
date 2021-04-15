//
//  NSString+Hash.m
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import "NSString+Hash.h"
#import "NSData+Hash.h"

@implementation NSString (Hash)

- (NSString *)md5
{
    return [self dataUsingEncoding:NSUTF8StringEncoding].md5;
}
- (NSString *)sha1
{
    return [self dataUsingEncoding:NSUTF8StringEncoding].sha1;
}
- (NSString *)sha256
{
    return [self dataUsingEncoding:NSUTF8StringEncoding].sha256;
}
- (NSString *)sha512
{
    return [self dataUsingEncoding:NSUTF8StringEncoding].sha512;
}

@end
