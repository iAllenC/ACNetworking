//
//  ACNetCache.h
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACNetCacheKeyGenerator.h"

typedef NS_ENUM(NSUInteger, ACNetCacheType) {
    ACNetCacheTypeNone = 0,
    ACNetCacheTypeMemroy,
    ACNetCacheTypeDisk,
    ACNetCacheTypeNet
};

typedef void(^ACNetCacheFetchCompletion)(ACNetCacheType type, id response);

typedef NSTimeInterval Expire_Time;

/** 永不过期 */
static Expire_Time Expire_Time_Never = DBL_MAX;

/** 不取缓存 */
static Expire_Time Expire_Time_Always = 0;

NS_ASSUME_NONNULL_BEGIN

@interface ACNetCache : NSObject

/** 单例类 */
@property (nonatomic, strong, class, readonly) ACNetCache *sharedCache;

/** 缓存Key生成器,默认为DefaultKeyGenerator */
@property (nonatomic, copy) ACNetCacheKeyGenerator keyGenerator;

/**
 实例化
 
 @param ns 命名空间
 @return 实例
 */
+ (instancetype)cacheWithNamespace:(NSString *)ns;

/**
 实例化

 @param ns 命名空间
 @param directory 缓存目录
 @return 实例
 */
+ (instancetype)cacheWithNamespace:(NSString *)ns directiory:(NSString * _Nullable)directory;

/**
 实例化
 
 @param ns 命名空间
 @param directory 缓存目录
 @return 实例
 */
+ (instancetype)cacheWithNamespace:(NSString *)ns directiory:(NSString * _Nullable)directory keyGenerator:(ACNetCacheKeyGenerator _Nullable)keyGenerator;

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)netCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param;

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)netCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire;

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param;

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire;

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param;

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire;

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url param:(NSDictionary *)param;

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 @param toMemory 是否缓存到内存
 @param toDisk 是否缓存到磁盘
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url param:(NSDictionary *)param toMemory:(BOOL)toMemory toDisk:(BOOL)toDisk;

/**
 删除本地内存缓存和磁盘缓存的response
 
 @param url URL
 @param param 请求参数
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param;

/**
 删除本地response缓存
 
 @param url URL
 @param param 请求参数
 @param fromMemory 是否删除内存缓存
 @param fromDisk 是否删除磁盘缓存
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk;

/**
 获取本地缓存的response,不过期
 
 @param url URL
 @param param 请求参数
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param completion:(ACNetCacheFetchCompletion)completion;

/**
 异步获取本地缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire completion:(ACNetCacheFetchCompletion)completion;

/**
 获取本地缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 @param async 是否异步
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire async:(BOOL)async completion:(ACNetCacheFetchCompletion)completion;

@end

NS_ASSUME_NONNULL_END
