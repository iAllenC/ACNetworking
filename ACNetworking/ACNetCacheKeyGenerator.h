//
//  ACNetCacheKeyGenerator.h
//  ACNetworkingDemo
//
//  Created by 陈元兵 on 2018/12/13.
//  Copyright © 2018 Allen. All rights reserved.
//

#ifndef ACNetCacheKeyGenerator_h
#define ACNetCacheKeyGenerator_h

/**
 结果缓存Key产生器
 
 @param url url
 @param param 传参
 @return Key
 */
typedef NSString *(^ACNetCacheKeyGenerator)(NSString *url, NSDictionary *param);

/** 默认缓存Key生成器 */
FOUNDATION_EXTERN ACNetCacheKeyGenerator const DefaultKeyGenerator;

#endif /* ACNetCacheKeyGenerator_h */
