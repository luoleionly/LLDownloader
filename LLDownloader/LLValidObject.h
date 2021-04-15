//
//  LLValidObject.h
//  LLDownloaderDemo
//
//  Created by luolei on 2021/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLValidObject : NSObject

BOOL isValidValue(id object);
BOOL isValidObject(id object, Class aClass);
BOOL isValidNSDictionary(id object);
BOOL isValidNSArray(id object);
BOOL isValidNSString(id object);
BOOL isValidNSURL(id object);
BOOL isValidNSNumber(id object);

id getValidObjectFromArray(NSArray *array, NSInteger index);
id getValidObjectFromDictionary(NSDictionary *dic, NSString *key);

void setValidObjectForDictionary(NSMutableDictionary *dic, NSString*key, id value);
void addValidObjectForArray(NSMutableArray *array, id value);
void addValidArrayForArray(NSMutableArray *array, NSArray *value);
void replaceValidObjectForArray(NSMutableArray *array, NSInteger index, id value);

void removeValidObjectFromArray(NSMutableArray *array, NSInteger index);

void dispatch_async_main_safe(void (^ _Nonnull block)(void));


@end

NS_ASSUME_NONNULL_END
