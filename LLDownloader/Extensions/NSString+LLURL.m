//
//  NSString+LLURL.m
//  LLDownloader
//

#import "NSString+LLURL.h"
#import "NSString+LLHash.h"
#import "LLError.h"

NSURL *LLAsURL(id urlOrString, NSError **error) {
    if (!urlOrString) {
        if (error) *error = [LLError invalidURLWithURL:[NSNull null]];
        return nil;
    }
    if ([urlOrString isKindOfClass:[NSURL class]]) {
        return (NSURL *)urlOrString;
    }
    if ([urlOrString isKindOfClass:[NSString class]]) {
        NSURL *u = [NSURL URLWithString:(NSString *)urlOrString];
        if (!u) {
            if (error) *error = [LLError invalidURLWithURL:urlOrString];
            return nil;
        }
        return u;
    }
    if ([urlOrString isKindOfClass:[NSURLComponents class]]) {
        NSURL *u = ((NSURLComponents *)urlOrString).URL;
        if (!u) {
            if (error) *error = [LLError invalidURLWithURL:urlOrString];
            return nil;
        }
        return u;
    }
    if (error) *error = [LLError invalidURLWithURL:urlOrString];
    return nil;
}

@implementation NSURL (LL)

- (NSString *)ll_fileName {
    NSString *name = self.absoluteString.ll_md5;
    NSString *ext = self.pathExtension;
    if (ext.length > 0) {
        name = [name stringByAppendingFormat:@".%@", ext];
    }
    return name;
}

@end
