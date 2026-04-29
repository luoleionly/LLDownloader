//
//  LLError.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const LLErrorDomain;

/// Keys used in NSError.userInfo for structured details.
FOUNDATION_EXPORT NSString *const LLErrorURLKey;       // invalidURL / duplicateURL / fetchDownloadTaskFailed
FOUNDATION_EXPORT NSString *const LLErrorPathKey;      // cache-related errors
FOUNDATION_EXPORT NSString *const LLErrorToPathKey;    // copy/move errors
FOUNDATION_EXPORT NSString *const LLErrorUnderlyingKey;
FOUNDATION_EXPORT NSString *const LLErrorStatusCodeKey;

typedef NS_ERROR_ENUM(LLErrorDomain, LLErrorCode) {
    LLErrorCodeUnknown = -1,
    LLErrorCodeUnacceptableStatusCode = 1001,
    LLErrorCodeInvalidURL = -2,
    LLErrorCodeDuplicateURL = -3,
    LLErrorCodeIndexOutOfRange = -4,
    LLErrorCodeFetchDownloadTaskFailed = -5,
    LLErrorCodeHeadersMatchFailed = -6,
    LLErrorCodeFileNamesMatchFailed = -7,
    LLErrorCodeCacheCannotCreateDirectory = -100,
    LLErrorCodeCacheCannotRemoveItem = -101,
    LLErrorCodeCacheCannotCopyItem = -102,
    LLErrorCodeCacheCannotMoveItem = -103,
    LLErrorCodeCacheCannotRetrieveAllTasks = -104,
    LLErrorCodeCacheCannotEncodeTasks = -105,
    LLErrorCodeCacheFileDoesNotExist = -106,
    LLErrorCodeCacheReadDataFailed = -107,
};

@interface LLError : NSObject

+ (NSError *)unknown;
+ (NSError *)invalidURLWithURL:(id)url;
+ (NSError *)duplicateURLWithURL:(id)url;
+ (NSError *)indexOutOfRange;
+ (NSError *)fetchDownloadTaskFailedWithURL:(id)url;
+ (NSError *)headersMatchFailed;
+ (NSError *)fileNamesMatchFailed;
+ (NSError *)unacceptableStatusCode:(NSInteger)code;

+ (NSError *)cacheCannotCreateDirectoryAtPath:(NSString *)path underlying:(NSError *)error;
+ (NSError *)cacheCannotRemoveItemAtPath:(NSString *)path underlying:(NSError *)error;
+ (NSError *)cacheCannotCopyItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath underlying:(NSError *)error;
+ (NSError *)cacheCannotMoveItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath underlying:(NSError *)error;
+ (NSError *)cacheCannotRetrieveAllTasksAtPath:(NSString *)path underlying:(NSError *)error;
+ (NSError *)cacheCannotEncodeTasksAtPath:(NSString *)path underlying:(NSError *)error;
+ (NSError *)cacheFileDoesNotExistAtPath:(NSString *)path;
+ (NSError *)cacheReadDataFailedAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
