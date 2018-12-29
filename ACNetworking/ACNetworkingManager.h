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

/** 网络请求策略 */
typedef NS_ENUM(NSUInteger, ACNetworkingFetchOption) {
    /** 默认option 先取网络,请求失败再取本地,优先级最低.*/
    ACNetworkingFetchOptionNetFirst = 1 << 0,
    /** 以下option优先级逐渐降低 */
    /** 传入这个option只请求网络数据,忽略本地 */
    ACNetworkingFetchOptionNetOnly = 1 << 1,
    /** 传入这个option只获取本地缓存 */
    ACNetworkingFetchOptionLocalOnly = 1 << 2,
    /** 优先取本地缓存,无缓存取网络 */
    ACNetworkingFetchOptionLocalFirst = 1 << 3,
    /** 传入这个option先取本地(如果有的话),然后取网络 */
    ACNetworkingFetchOptionLocalAndNet = 1 << 4,
    /** 以下option无冲突,无优先级区别 */
    /** 默认请求成功后会更新本地缓存的返回结果, 传入这个option将不更新缓存*/
    ACNetworkingFetchOptionNotUpdateCache = 1 << 5,
    /** 传入这个option,将在回调结束后删除本地缓存 */
    ACNetworkingFetchOptionDeleteCache = 1 << 6
};

/**
 请求结果回调

 @param task 请求生成的task,若只取了本地缓存,则为nil
 @param type 缓存类型
 @param responseObject 请求返回结果
 @param error 请求error
 @param cacheDate 缓存时间(可nil)
 */
typedef void(^ACNetworkingCompletion)(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id _Nullable responseObject, NSError * _Nullable error, NSDate * _Nullable cacheDate);

@interface ACNetworkingManager : NSObject

/** AFHTTPSessionManager,用户可以根据自己的需求自定义响应的manager,默认为[AFHTTPSessionManager manager] */
@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;

/** 结果缓存类,默认为ACNetCache.sharedCache */
@property (nonatomic, strong, readonly) ACNetCache *responseCache;

#pragma mark - Constructor

+ (instancetype)manager;

/**
 实例化
 
 @param sessionManager sessionManager
 @return 实例对象
 */
+ (instancetype)managerWithSessionManager:(AFHTTPSessionManager *)sessionManager;


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

#pragma mark - Main

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
                               expires:(Expire_Time)expire
                               options:(ACNetworkingFetchOption)options
                            parameters:(nullable NSDictionary *)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                            completion:(ACNetworkingCompletion)completion;

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
                               expires:(Expire_Time)expire
                               options:(ACNetworkingFetchOption)options
                            parameters:(nullable NSDictionary *)parameters
                          keyGenerator:(nullable ACNetCacheKeyGenerator)generator
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
                                expires:(Expire_Time)expire
                                options:(ACNetworkingFetchOption)options
                             parameters:(nullable NSDictionary *)parameters
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
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
                                expires:(Expire_Time)expire
                                options:(ACNetworkingFetchOption)options
                             parameters:(nullable NSDictionary *)parameters
                           keyGenerator:(nullable ACNetCacheKeyGenerator)generator
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                             completion:(ACNetworkingCompletion)completion;

/** API说明
 以下封装的便利方法均采用self.responseCache.keyGenerator生成存储key,若需要单独生成key请使用上面的方法.
 1.get/post+Net:只走网络请求,不读取本地缓存
 2.get/post+Request:优先走网络请求,网络失败读取本地缓存
 3.get/post+Data:优先读缓存,无缓存走网络请求
 4.get/post+LocalAndNet:先读取本地,然后再走网络请求
 5.get/post+Local:只取本地缓存,不走网络请求
 */

#pragma mark - PUBLIC GET

/**
 get请求(不读缓存)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(优先读网络,失败读缓存,缓存不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 get数据(优先读网络,失败读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

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
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

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
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 读取本地get数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocal:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

#pragma mark - PUBLIC POST

/**
 post请求(不读缓存)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(优先读网络,失败读缓存,缓存不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 post数据(优先读网络,失败读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;
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
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

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
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;

/**
 读取本地post数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocal:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion;


/**
 post表单上传(无缓存)

 @param URLString url
 @param parameters 请求参数
 @param block 用于构建formData的block
 @param uploadProgress 上传进度
 @param completion 完成回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postNet:(NSString *)URLString parameters:(nullable id)parameters constructingBlock:(nullable void (^)(id <AFMultipartFormData> formData))block progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress completion:(ACNetworkingCompletion)completion;


@end

NS_ASSUME_NONNULL_END
