//
//  ACNetworkingManager.h
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "ACNetCache.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACNetworkingFetchOption) {
    /** 默认option */
    ACNetworkingFetchOptionDefault = 1 << 0,
    /** 传入这个option只获取本地缓存 */
    ACNetworkingFetchOptionLocalOnly = 1 << 1,
    /** 传入这个option只请求网络数据,忽略本地(传了ACNetworkingFetchOptionLocalOnly时此option不起作用) */
    ACNetworkingFetchOptionNetOnly = 1 << 2,
    /** 传入这个option先取本地(如果有的话),然后取网络 */
    ACNetworkingFetchOptionLocalAndNet = 1 << 3,
    /** 默认请求成功后会更新本地缓存的返回结果, 传入这个option将不更新缓存*/
    ACNetworkingFetchOptionNotUpdateCache = 1 << 4,
    /** 传入这个option,将在回调结束后删除本地缓存 */
    ACNetworkingFetchOptionDeleteCache = 1 << 5
};

typedef void(^ACNetworkingCompletion)(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id _Nullable responseObject, NSError * _Nullable error);

@interface ACNetworkingManager : NSObject

@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong, readonly) ACNetCache *responseCache;

+ (instancetype)manager;

/**
 实例化

 @param sessionManager sessionManager
 @param responseCache 缓存对象
 @return 实例对象
 */
+ (instancetype)managerWithSessionManager:(AFHTTPSessionManager *)sessionManager responseCache:(ACNetCache *)responseCache;

/**
 实例化
 
 @param sessionManager sessionManager
 @param responseCache 缓存对象
 @return 实例对象
 */
- (instancetype)initWithSessionManager:(AFHTTPSessionManager *)sessionManager responseCache:(ACNetCache *)responseCache;

/**
 get方法

 @param URLString URL
 @param expire 过期时间
 @param options options
 @param parameters 请求参数
 @param downloadProgress progress
 @param completion 结果回调
 @return dataTask
 */
- (nullable NSURLSessionDataTask *)get:(NSString *)URLString
                               expires:(NSTimeInterval)expire
                               options:(ACNetworkingFetchOption)options
                            parameters:(nullable NSDictionary *)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                            completion:(ACNetworkingCompletion)completion;

/**
 post方法
 
 @param URLString URL
 @param expire 过期时间
 @param options options
 @param parameters 请求参数
 @param uploadProgress progress
 @param completion 结果回调
 @return dataTask
 */
- (nullable NSURLSessionDataTask *)post:(NSString *)URLString
                                expires:(NSTimeInterval)expire
                                options:(ACNetworkingFetchOption)options
                             parameters:(nullable NSDictionary *)parameters
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                             completion:(ACNetworkingCompletion)completion;

/**
 get请求(不读缓存)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(优先读缓存,不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 读取本地get数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocal:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post请求(不读缓存)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(优先读缓存,不过期)

 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 读取本地post数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocal:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

@end

NS_ASSUME_NONNULL_END
