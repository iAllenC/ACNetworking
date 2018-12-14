//
//  ACNetCacheKeyGenerator.m
//  ACNetworkingDemo
//
//  Created by 陈元兵 on 2018/12/13.
//  Copyright © 2018 Allen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACNetCacheKeyGenerator.h"
#import <CommonCrypto/CommonDigest.h>

/**
 MD5加密
 
 @param string 加密前
 @return 加密后
 */
NSString *ac_md5String(NSString *string) {
    if(!string || string.length == 0) return nil;
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    for(i=0;i<CC_MD5_DIGEST_LENGTH;i++)
    {
        [ms appendFormat: @"%02x", (int)(digest[i])];
    }
    return [ms copy];
    
}

/**
 获取jsonString
 
 @param obj 需要序列化的对象
 @return 序列化后的string
 */
NSString *ac_jsonString(id obj) {
    if (![NSJSONSerialization isValidJSONObject:obj]) return nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 根据url和paramc生成存储Key
 
 @param url url
 @param param param
 @return key
 */
NSString *ac_cacheKey(NSString *url, NSDictionary *param) {
    NSArray *keys = [param allKeys];
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return  [obj1 compare:obj2] == NSOrderedDescending;
    }];
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *key in keys)
    {
        id value = param[key];
        NSString *stringValue = nil;
        if ([value isKindOfClass:NSString.class]) {
            stringValue = value;
        } else if ([NSJSONSerialization isValidJSONObject:value]) {
            stringValue = ac_jsonString(value);
        }
        if (!stringValue && [stringValue isKindOfClass:NSObject.class]) stringValue = ((NSObject *)value).description;
        NSString *string = [NSString stringWithFormat:@"%@=%@",key,stringValue ?: value];
        [array addObject:string];
    }
    NSString *result = [array componentsJoinedByString:@"&"];
    return ac_md5String([url stringByAppendingString:result]);
}

/** 默认缓存Key生成器 */
ACNetCacheKeyGenerator const DefaultKeyGenerator = ^NSString *(NSString *url, NSDictionary *param) {
    return ac_cacheKey(url, param);
};
