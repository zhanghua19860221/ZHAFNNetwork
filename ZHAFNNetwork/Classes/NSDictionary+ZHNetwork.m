//
//  NSDictionary+ZHNetwork.m
//  ZHNetWork
//
//  Created by Breeze on 2022/6/22.
//

#import "NSDictionary+ZHNetwork.h"

@implementation NSDictionary (ZHNetwork)
- (NSString *)toString {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSMutableString *responseString = [NSMutableString stringWithString:jsonString];
    NSString *character = nil;
    for (int i = 0; i < responseString.length; i ++) {
        character = [responseString substringWithRange:NSMakeRange(i, 1)];
        if ([character isEqualToString:@"\\"])
        [responseString deleteCharactersInRange:NSMakeRange(i, 1)];
    }
    return responseString;
}

- (NSString *)descriptionWithLocale:(id)locale {
    
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [strM appendFormat:@"\t%@,\n",obj];
    }];
    [strM appendString:@"}\n"];
    return  strM;
}
@end
