//
//  ACNetworkingManager.m
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import "ACNetworkingManager.h"

@implementation ACNetworkingManager

+ (instancetype)manager {
    return [self managerWithSessionManager:[AFHTTPSessionManager manager] responseCache:ACNetCache.sharedCache];
}

+ (instancetype)managerWithSessionManager:(AFHTTPSessionManager *)sessionManager responseCache:(ACNetCache *)responseCache {
    return [[self alloc] initWithSessionManager:sessionManager responseCache:responseCache];
}

- (instancetype)initWithSessionManager:(AFHTTPSessionManager *)sessionManager responseCache:(ACNetCache *)responseCache {
    if (self = [super init]) {
        _sessionManager = sessionManager;
        _responseCache = responseCache;
    }
    return self;
}

/**
 获取Get数据
 
 @param URLString url
 @param expire 过期时间
 @param options option
 @param parameters 请求参数
 @param downloadProgress 上传进度
 @param completion 回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)get:(NSString *)URLString expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))downloadProgress completion:(ACNetworkingCompletion)completion {
    if ([self shouldFetchLocalResponseForUrl:URLString options:options param:parameters expire:expire]) {
        //直接读取本地缓存
        __weak typeof(self) weakSelf = self;
        [self.responseCache fetchResponseForUrl:URLString param:parameters expires:expire async:!(options & ACNetworkingFetchOptionLocalAndNet) completion:^(ACNetCacheType type, id response) {
            if (completion) completion(nil, type, response, nil);
            if(options & ACNetworkingFetchOptionDeleteCache) [weakSelf.responseCache deleteResponseForUrl:URLString param:parameters];
        }];
        if (options & ACNetworkingFetchOptionLocalAndNet) {
            return [self getRequest:URLString expires:expire options:options parameters:parameters progress:downloadProgress completion:completion];
        } else {
            return nil;
        }
    } else {
        return [self getRequest:URLString expires:expire options:options parameters:parameters progress:downloadProgress completion:completion];
    }
}

/**
 发起Get请求
 
 @param URLString url
 @param expire 过期时间
 @param options option
 @param parameters 请求参数
 @param downloadProgress 上传进度
 @param completion 回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)getRequest:(NSString *)URLString expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))downloadProgress completion:(ACNetworkingCompletion)completion {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager GET:URLString parameters:parameters progress:downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [weakSelf handleHttpSucceessForUrl:URLString parames:parameters task:task responseObject:responseObject expires:expire options:options completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakSelf handleHttpFailureForUrl:URLString parames:parameters task:task error:error expires:expire options:options completion:completion];
    }];
}

/**
 获取POST数据
 
 @param URLString url
 @param expire 过期时间
 @param options option
 @param parameters 请求参数
 @param uploadProgress 上传进度
 @param completion 回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)post:(NSString *)URLString expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    if ([self shouldFetchLocalResponseForUrl:URLString options:options param:parameters expire:expire]) {
        //直接读取本地缓存
        __weak typeof(self) weakSelf = self;
        /** 如果没有传入ACNetworkingFetchOptionLocalAndNet则异步获取本地缓存,否则同步获取本地缓存,并且创建一个新的网络请求*/
        [self.responseCache fetchResponseForUrl:URLString param:parameters expires:expire async:!(options & ACNetworkingFetchOptionLocalAndNet) completion:^(ACNetCacheType type, id response) {
            if (completion) completion(nil, type, response, nil);
            if(options & ACNetworkingFetchOptionDeleteCache) [weakSelf.responseCache deleteResponseForUrl:URLString param:parameters];
        }];
        if (options & ACNetworkingFetchOptionLocalAndNet) {
            return [self postRequest:URLString expires:expire options:options parameters:parameters progress:uploadProgress completion:completion];
        } else {
            return nil;
        }
    } else {
        return [self postRequest:URLString expires:expire options:options parameters:parameters progress:uploadProgress completion:completion];
    }
}

/**
 发起POST请求

 @param URLString url
 @param expire 过期时间
 @param options option
 @param parameters 请求参数
 @param uploadProgress 上传进度
 @param completion 回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)postRequest:(NSString *)URLString expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager POST:URLString parameters:parameters progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [weakSelf handleHttpSucceessForUrl:URLString parames:parameters task:task responseObject:responseObject expires:expire options:options completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakSelf handleHttpFailureForUrl:URLString parames:parameters task:task error:error expires:expire options:options completion:completion];
    }];
}

/**
 统一处理请求成功
 
 @param url url
 @param parameters 请求参数
 @param task 请求task
 @param response 返回结果
 @param expire 过期时间
 @param options option
 @param completion 回调
 */
- (void)handleHttpSucceessForUrl:(NSString *)url parames:(NSDictionary *)parameters task:(NSURLSessionDataTask *)task responseObject:(id)response expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options  completion:(ACNetworkingCompletion)completion {
    if (completion) completion(task, ACNetCacheTypeNet, response, nil);
    if(options & ACNetworkingFetchOptionDeleteCache) return [self.responseCache deleteResponseForUrl:url param:parameters];
    if (!(options & ACNetworkingFetchOptionNotUpdateCache)) [self.responseCache storeResponse:response forUrl:url param:parameters];
}

/**
 统一处理请求失败

 @param url url
 @param parameters 请求参数
 @param task 请求task
 @param error error
 @param expire 过期时间
 @param options option
 @param completion 回调
 */
- (void)handleHttpFailureForUrl:(NSString *)url parames:(NSDictionary *)parameters task:(NSURLSessionDataTask *)task error:(NSError *)error expires:(NSTimeInterval)expire options:(ACNetworkingFetchOption)options  completion:(ACNetworkingCompletion)completion {
    if (options & ACNetworkingFetchOptionNetOnly) {
        if(completion) completion(task, ACNetCacheTypeNone, nil, error);
        if(options & ACNetworkingFetchOptionDeleteCache) [self.responseCache deleteResponseForUrl:url param:parameters];
    } else {
        __weak typeof(self) weakSelf = self;
        [self.responseCache fetchResponseForUrl:url param:parameters expires:expire completion:^(ACNetCacheType type, id response) {
            if(completion) completion(nil, type, response, type == ACNetCacheTypeNone ? error : nil);
            if(options & ACNetworkingFetchOptionDeleteCache) [weakSelf.responseCache deleteResponseForUrl:url param:parameters];
        }];
    }
}

/**
 判断请求是否需要读取本地缓存

 @param url url
 @param options option
 @param param 请求参数
 @param expire 过期时间
 @return 是否需要读取缓存
 */
- (BOOL)shouldFetchLocalResponseForUrl:(NSString *)url options:(ACNetworkingFetchOption)options param:(NSDictionary *)param expire:(NSTimeInterval)expire {
    //option只读本地
    if (options & ACNetworkingFetchOptionLocalOnly) return YES;
    //option只取网络
    if (options & ACNetworkingFetchOptionNetOnly) return NO;
    //返回本地是否有未过期缓存
    return [self.responseCache netCacheExistsForUrl:url param:param expires:expire];
}

#pragma mark - API

/**
 get请求

 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:0 options:ACNetworkingFetchOptionNetOnly parameters:parameters progress:nil completion:completion];
}

/**
 get数据(优先读缓存, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self getData:URLString expires:MAXFLOAT parameters:parameters completion:completion];
}

/**
 get数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self getLocalAndNet:URLString expires:MAXFLOAT parameters:parameters completion:completion];
}

/**
 get数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:ACNetworkingFetchOptionLocalAndNet parameters:parameters progress:nil completion:completion];
}

/**
 get数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:ACNetworkingFetchOptionDefault parameters:parameters progress:nil completion:completion];
}

/**
 读取本地get数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocal:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:MAXFLOAT options:ACNetworkingFetchOptionLocalOnly parameters:parameters progress:nil completion:completion];
}

/**
 post请求
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:0 options:ACNetworkingFetchOptionNetOnly parameters:parameters progress:nil completion:completion];
}

/**
 post数据(优先读缓存, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self postData:URLString expires:MAXFLOAT parameters:parameters completion:completion];
}

/**
 post数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:expire options:ACNetworkingFetchOptionDefault parameters:parameters progress:nil completion:completion];
}

/**
 post数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self postLocalAndNet:URLString expires:MAXFLOAT parameters:parameters completion:completion];
}

/**
 post数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString expires:(NSTimeInterval)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:expire options:ACNetworkingFetchOptionLocalAndNet parameters:parameters progress:nil completion:completion];
}

/**
 读取本地post数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocal:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:MAXFLOAT options:ACNetworkingFetchOptionLocalOnly parameters:parameters progress:nil completion:completion];
}

@end
