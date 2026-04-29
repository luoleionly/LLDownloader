//
//  LLResumeDataHelper.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLResumeDataHelper : NSObject

+ (nullable NSMutableDictionary *)getResumeDictionary:(NSData *)data;
+ (nullable NSString *)getTmpFileName:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
