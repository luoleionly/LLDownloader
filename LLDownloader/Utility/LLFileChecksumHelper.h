//
//  LLFileChecksumHelper.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LLVerificationType) {
    LLVerificationTypeMD5 = 0,
    LLVerificationTypeSHA1,
    LLVerificationTypeSHA256,
    LLVerificationTypeSHA512,
};

FOUNDATION_EXPORT NSErrorDomain const LLFileVerificationErrorDomain;

typedef NS_ERROR_ENUM(LLFileVerificationErrorDomain, LLFileVerificationErrorCode) {
    LLFileVerificationErrorCodeCodeEmpty = 1,
    LLFileVerificationErrorCodeCodeMismatch = 2,
    LLFileVerificationErrorCodeFileDoesNotExist = 3,
    LLFileVerificationErrorCodeReadDataFailed = 4,
};

@interface LLFileChecksumHelper : NSObject

/// Validates `filePath` against `code` using `type`. Completion runs on an internal ioQueue.
/// `success` is YES on match; otherwise `error` is non-nil.
+ (void)validateFileAtPath:(NSString *)filePath
                      code:(NSString *)code
                      type:(LLVerificationType)type
                completion:(void (^)(BOOL success, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
