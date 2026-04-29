//
//  LLResumeDataHelper.m
//  LLDownloader
//

#import "LLResumeDataHelper.h"

static NSString *const kInfoVersionKey = @"NSURLSessionResumeInfoVersion";
static NSString *const kInfoTempFileNameKey = @"NSURLSessionResumeInfoTempFileName";
static NSString *const kInfoLocalPathKey = @"NSURLSessionResumeInfoLocalPath";
static NSString *const kArchiveRootObjectKey = @"NSKeyedArchiveRootObjectKey";

@implementation LLResumeDataHelper

+ (NSMutableDictionary *)getResumeDictionary:(NSData *)data {
    NSDictionary *object = nil;

    NSError *err = nil;
    NSKeyedUnarchiver *un = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&err];
    if (un) {
        un.requiresSecureCoding = NO;
        @try {
            object = [un decodeObjectOfClass:[NSDictionary class] forKey:kArchiveRootObjectKey];
            if (!object) {
                object = [un decodeObjectOfClass:[NSDictionary class] forKey:NSKeyedArchiveRootObjectKey];
            }
        } @catch (__unused NSException *ex) {
            object = nil;
        }
        [un finishDecoding];
    }

    if (!object) {
        @try {
            object = [NSPropertyListSerialization propertyListWithData:data
                                                               options:NSPropertyListMutableContainersAndLeaves
                                                                format:NULL
                                                                 error:NULL];
        } @catch (__unused NSException *ex) {
            object = nil;
        }
        if (![object isKindOfClass:[NSDictionary class]]) object = nil;
    }

    if (!object) return nil;

    if ([object isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)object;
    }
    return [NSMutableDictionary dictionaryWithDictionary:object];
}

+ (NSString *)getTmpFileName:(NSData *)data {
    NSMutableDictionary *dict = [self getResumeDictionary:data];
    if (!dict) return nil;
    NSNumber *version = dict[kInfoVersionKey];
    if (!version) return nil;
    if (version.integerValue > 1) {
        id v = dict[kInfoTempFileNameKey];
        return [v isKindOfClass:[NSString class]] ? v : nil;
    } else {
        id path = dict[kInfoLocalPathKey];
        if (![path isKindOfClass:[NSString class]]) return nil;
        return [NSURL fileURLWithPath:(NSString *)path].lastPathComponent;
    }
}

@end
