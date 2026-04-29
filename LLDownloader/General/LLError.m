//
//  LLError.m
//  LLDownloader
//

#import "LLError.h"

NSErrorDomain const LLErrorDomain = @"com.Daniels.LL.Error";
NSString *const LLErrorURLKey = @"LLErrorURL";
NSString *const LLErrorPathKey = @"LLErrorPath";
NSString *const LLErrorToPathKey = @"LLErrorToPath";
NSString *const LLErrorUnderlyingKey = @"NSUnderlyingError"; // == NSUnderlyingErrorKey
NSString *const LLErrorStatusCodeKey = @"LLErrorStatusCode";

@implementation LLError

+ (NSError *)errorWithCode:(LLErrorCode)code description:(NSString *)desc userInfo:(nullable NSDictionary *)extra {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[NSLocalizedDescriptionKey] = desc;
    if (extra) [info addEntriesFromDictionary:extra];
    return [NSError errorWithDomain:LLErrorDomain code:code userInfo:info];
}

+ (NSError *)unknown {
    return [self errorWithCode:LLErrorCodeUnknown description:@"unkown error" userInfo:nil];
}

+ (NSError *)invalidURLWithURL:(id)url {
    return [self errorWithCode:LLErrorCodeInvalidURL
                   description:[NSString stringWithFormat:@"URL is not valid: %@", url]
                      userInfo:@{LLErrorURLKey: url ?: [NSNull null]}];
}

+ (NSError *)duplicateURLWithURL:(id)url {
    return [self errorWithCode:LLErrorCodeDuplicateURL
                   description:[NSString stringWithFormat:@"URL is duplicate: %@", url]
                      userInfo:@{LLErrorURLKey: url ?: [NSNull null]}];
}

+ (NSError *)indexOutOfRange {
    return [self errorWithCode:LLErrorCodeIndexOutOfRange description:@"index out of range" userInfo:nil];
}

+ (NSError *)fetchDownloadTaskFailedWithURL:(id)url {
    return [self errorWithCode:LLErrorCodeFetchDownloadTaskFailed
                   description:[NSString stringWithFormat:@"did not find downloadTask in sessionManager: %@", url]
                      userInfo:@{LLErrorURLKey: url ?: [NSNull null]}];
}

+ (NSError *)headersMatchFailed {
    return [self errorWithCode:LLErrorCodeHeadersMatchFailed description:@"HeaderArray.count != urls.count" userInfo:nil];
}

+ (NSError *)fileNamesMatchFailed {
    return [self errorWithCode:LLErrorCodeFileNamesMatchFailed description:@"FileNames.count != urls.count" userInfo:nil];
}

+ (NSError *)unacceptableStatusCode:(NSInteger)code {
    return [self errorWithCode:LLErrorCodeUnacceptableStatusCode
                   description:[NSString stringWithFormat:@"Response status code was unacceptable: %ld", (long)code]
                      userInfo:@{LLErrorStatusCodeKey: @(code)}];
}

+ (NSError *)cacheCannotCreateDirectoryAtPath:(NSString *)path underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotCreateDirectory
                   description:[NSString stringWithFormat:@"can not create directory, path: %@, underlying: %@", path, error]
                      userInfo:@{LLErrorPathKey: path ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheCannotRemoveItemAtPath:(NSString *)path underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotRemoveItem
                   description:[NSString stringWithFormat:@"can not remove item, path: %@, underlying: %@", path, error]
                      userInfo:@{LLErrorPathKey: path ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheCannotCopyItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotCopyItem
                   description:[NSString stringWithFormat:@"can not copy item, atPath: %@, toPath: %@, underlying: %@", fromPath, toPath, error]
                      userInfo:@{LLErrorPathKey: fromPath ?: @"", LLErrorToPathKey: toPath ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheCannotMoveItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotMoveItem
                   description:[NSString stringWithFormat:@"can not move item atPath: %@, toPath: %@, underlying: %@", fromPath, toPath, error]
                      userInfo:@{LLErrorPathKey: fromPath ?: @"", LLErrorToPathKey: toPath ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheCannotRetrieveAllTasksAtPath:(NSString *)path underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotRetrieveAllTasks
                   description:[NSString stringWithFormat:@"can not retrieve all tasks, path: %@, underlying: %@", path, error]
                      userInfo:@{LLErrorPathKey: path ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheCannotEncodeTasksAtPath:(NSString *)path underlying:(NSError *)error {
    return [self errorWithCode:LLErrorCodeCacheCannotEncodeTasks
                   description:[NSString stringWithFormat:@"can not encode tasks, path: %@, underlying: %@", path, error]
                      userInfo:@{LLErrorPathKey: path ?: @"", NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (NSError *)cacheFileDoesNotExistAtPath:(NSString *)path {
    return [self errorWithCode:LLErrorCodeCacheFileDoesNotExist
                   description:[NSString stringWithFormat:@"file does not exist, path: %@", path]
                      userInfo:@{LLErrorPathKey: path ?: @""}];
}

+ (NSError *)cacheReadDataFailedAtPath:(NSString *)path {
    return [self errorWithCode:LLErrorCodeCacheReadDataFailed
                   description:[NSString stringWithFormat:@"read data failed, path: %@", path]
                      userInfo:@{LLErrorPathKey: path ?: @""}];
}

@end
