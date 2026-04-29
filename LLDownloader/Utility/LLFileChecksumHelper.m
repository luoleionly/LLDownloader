//
//  LLFileChecksumHelper.m
//  LLDownloader
//

#import "LLFileChecksumHelper.h"
#import "NSData+LLHash.h"

NSErrorDomain const LLFileVerificationErrorDomain = @"com.LL.FileVerification";

@implementation LLFileChecksumHelper

+ (dispatch_queue_t)ioQueue {
    static dispatch_queue_t q;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        q = dispatch_queue_create("com.LL.FileChecksumHelper.ioQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    return q;
}

+ (NSError *)errorWithCode:(LLFileVerificationErrorCode)code description:(NSString *)desc userInfo:(NSDictionary *)extra {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[NSLocalizedDescriptionKey] = desc;
    if (extra) [info addEntriesFromDictionary:extra];
    return [NSError errorWithDomain:LLFileVerificationErrorDomain code:code userInfo:info];
}

+ (void)validateFileAtPath:(NSString *)filePath
                      code:(NSString *)code
                      type:(LLVerificationType)type
                completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (code.length == 0) {
        completion(NO, [self errorWithCode:LLFileVerificationErrorCodeCodeEmpty
                               description:@"verification code is empty" userInfo:nil]);
        return;
    }
    dispatch_async([self ioQueue], ^{
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            completion(NO, [self errorWithCode:LLFileVerificationErrorCodeFileDoesNotExist
                                   description:[NSString stringWithFormat:@"file does not exist, path: %@", filePath]
                                      userInfo:nil]);
            return;
        }
        NSError *err = nil;
        NSData *data = [NSData dataWithContentsOfFile:filePath
                                              options:NSDataReadingMappedIfSafe
                                                error:&err];
        if (!data) {
            completion(NO, [self errorWithCode:LLFileVerificationErrorCodeReadDataFailed
                                   description:[NSString stringWithFormat:@"read data failed, path: %@", filePath]
                                      userInfo:err ? @{NSUnderlyingErrorKey: err} : nil]);
            return;
        }
        NSString *hash;
        switch (type) {
            case LLVerificationTypeMD5:    hash = data.ll_md5; break;
            case LLVerificationTypeSHA1:   hash = data.ll_sha1; break;
            case LLVerificationTypeSHA256: hash = data.ll_sha256; break;
            case LLVerificationTypeSHA512: hash = data.ll_sha512; break;
        }
        BOOL ok = [hash.lowercaseString isEqualToString:code.lowercaseString];
        if (ok) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorWithCode:LLFileVerificationErrorCodeCodeMismatch
                                   description:[NSString stringWithFormat:@"verification code mismatch, code: %@", code]
                                      userInfo:nil]);
        }
    });
}

@end
