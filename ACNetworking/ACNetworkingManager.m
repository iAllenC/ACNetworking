//
//  ACNetworkingManager.m
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import "ACNetworkingManager.h"

typedef NS_ENUM(NSUInteger, ACNetworkingMethod) {
    ACNetworkingMethodGet,
    ACNetworkingMethodPost
};

@implementation ACNetworkingManager

#pragma mark - Constructor

+ (instancetype)manager {
    return [self managerWithSessionManager:[AFHTTPSessionManager manager] responseCache:ACNetCache.sharedCache];
}

+ (instancetype)managerWithSessionManager:(AFHTTPSessionManager *)sessionManager {
    return [self managerWithSessionManager:sessionManager responseCache:ACNetCache.sharedCache];
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

- (instancetype)init {
    return [self initWithSessionManager:[AFHTTPSessionManager manager] responseCache:ACNetCache.sharedCache];
}

#pragma mark - GET

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
- (NSURLSessionDataTask *)get:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:options parameters:parameters keyGenerator:nil progress:uploadProgress completion:completion];
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
- (NSURLSessionDataTask *)get:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters keyGenerator:(ACNetCacheKeyGenerator)generator progress:(void (^)(NSProgress * _Nonnull))downloadProgress completion:(ACNetworkingCompletion)completion {
    return [self fetch:URLString method:ACNetworkingMethodGet expires:expire options:options param:parameters keyGenerator:generator progress:downloadProgress completion:completion];
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
- (NSURLSessionDataTask *)getTask:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters keyGenerator:(ACNetCacheKeyGenerator)generator progress:(void (^)(NSProgress * _Nonnull))downloadProgress completion:(ACNetworkingCompletion)completion {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager GET:URLString parameters:parameters progress:downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [weakSelf handleHttpSucceessForUrl:URLString parames:parameters task:task responseObject:responseObject expires:expire options:options keyGenerator:generator completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakSelf handleHttpFailureForUrl:URLString parames:parameters task:task error:error expires:expire options:options keyGenerator:generator completion:completion];
    }];
}

#pragma mark - POST

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
- (NSURLSessionDataTask *)post:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:expire options:options parameters:parameters keyGenerator:nil progress:uploadProgress completion:completion];
}


/**
 获取POST数据
 
 @param URLString url
 @param expire 过期时间
 @param options option
 @param parameters 请求参数
 @param generator 存储key生成器
 @param uploadProgress 上传进度
 @param completion 回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)post:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters keyGenerator:(ACNetCacheKeyGenerator)generator progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    return [self fetch:URLString method:ACNetworkingMethodPost expires:expire options:options param:parameters keyGenerator:generator progress:uploadProgress completion:completion];
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
- (NSURLSessionDataTask *)postTask:(NSString *)URLString expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options parameters:(NSDictionary *)parameters keyGenerator:(ACNetCacheKeyGenerator)generator progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager POST:URLString parameters:parameters progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [weakSelf handleHttpSucceessForUrl:URLString parames:parameters task:task responseObject:responseObject expires:expire options:options keyGenerator:generator completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakSelf handleHttpFailureForUrl:URLString parames:parameters task:task error:error expires:expire options:options keyGenerator:generator completion:completion];
    }];
}

#pragma mark - Main
/**
 根据传入的method和options发起(post/get)请求,或获取本地数据

 @param URLString URL
 @param method method(get/post)
 @param expire 过期时长
 @param options options
 @param parameters 请求传参
 @param generator 缓存key生成器
 @param progress progress
 @param completion 回调
 @return dataTask(未发起请求则返回nil)
 */
- (NSURLSessionDataTask *)fetch:(NSString *)URLString method:(ACNetworkingMethod)method expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options param:(NSDictionary *)parameters keyGenerator:(ACNetCacheKeyGenerator)generator progress:(void (^)(NSProgress * _Nonnull))progress completion:(ACNetworkingCompletion)completion {
    if ([self shouldFetchLocalResponseForUrl:URLString options:options param:parameters keyGenerator:generator expires:expire]) {
        __weak typeof(self) weakSelf = self;
        /**
         1.传入了LocalOnly或者LocalFirst则异步获取本地缓存
         2.未传入以上二者,则意味着必然传入了LocalAndNet,需要同步获取本地缓存,并且创建一个新的网络请求,返回对应的task
         */
        BOOL async = options & ACNetworkingFetchOptionLocalOnly || options & ACNetworkingFetchOptionLocalFirst;
        [self.responseCache fetchResponseForUrl:URLString param:parameters keyGenerator:generator expires:expire async:async completion:^(ACNetCacheType type, id response, NSDate *cacheDate) {
            NSError *error = nil;
            if (type == ACNetCacheTypeNone) error = [NSError errorWithDomain:@"com.acnetworking.expire" code:404 userInfo:@{NSLocalizedDescriptionKey: @"本地无缓存或缓存已过期!"}];
            if (completion) completion(nil, type, response, error, cacheDate);
            if(options & ACNetworkingFetchOptionDeleteCache) [weakSelf.responseCache deleteResponseForUrl:URLString param:parameters keyGenerator:generator];
        }];
        /** 同步读取本地缓存,意味着未传LocalOnly或者LocalFirst,传了LocalAndNet,需要新建一个网络请求返回. */
        if (!async) {
            if (method == ACNetworkingMethodGet) {
                return [self getTask:URLString expires:expire options:options parameters:parameters keyGenerator:generator progress:progress completion:completion];
            } else {
                return [self postTask:URLString expires:expire options:options parameters:parameters keyGenerator:generator progress:progress completion:completion];
            }
        } else {
            return nil;
        }
    } else if (method == ACNetworkingMethodGet) {
        return [self getTask:URLString expires:expire options:options parameters:parameters keyGenerator:generator progress:progress completion:completion];
    } else {
        return [self postTask:URLString expires:expire options:options parameters:parameters keyGenerator:generator progress:progress completion:completion];
    }
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
- (void)handleHttpSucceessForUrl:(NSString *)url parames:(NSDictionary *)parameters task:(NSURLSessionDataTask *)task responseObject:(id)response expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options keyGenerator:(ACNetCacheKeyGenerator)generator completion:(ACNetworkingCompletion)completion {
    if (completion) completion(task, ACNetCacheTypeNet, response, nil, nil);
    if(options & ACNetworkingFetchOptionDeleteCache) return [self.responseCache deleteResponseForUrl:url param:parameters keyGenerator:generator];
    if (!(options & ACNetworkingFetchOptionNotUpdateCache)) [self.responseCache storeResponse:response forUrl:url param:parameters keyGenerator:generator];
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
- (void)handleHttpFailureForUrl:(NSString *)url parames:(NSDictionary *)parameters task:(NSURLSessionDataTask *)task error:(NSError *)error expires:(Expire_Time)expire options:(ACNetworkingFetchOption)options keyGenerator:(ACNetCacheKeyGenerator)generator completion:(ACNetworkingCompletion)completion {
    if (options & ACNetworkingFetchOptionNetOnly || options & ACNetworkingFetchOptionLocalFirst || options & ACNetworkingFetchOptionLocalAndNet) {
        //只读网络、优先读本地、先读本地再取网络,直接回调(优先读本地或先读本地走到失败意味着本地没有缓存)
        if(completion) completion(task, ACNetCacheTypeNone, nil, error, nil);
        if(options & ACNetworkingFetchOptionDeleteCache) [self.responseCache deleteResponseForUrl:url param:parameters keyGenerator:generator];
    } else {
        __weak typeof(self) weakSelf = self;
        [self.responseCache fetchResponseForUrl:url param:parameters expires:expire completion:^(ACNetCacheType type, id response, NSDate *cacheDate) {
            if(completion) completion(nil, type, response, type == ACNetCacheTypeNone ? error : nil, cacheDate);
            if(options & ACNetworkingFetchOptionDeleteCache) [weakSelf.responseCache deleteResponseForUrl:url param:parameters keyGenerator:generator];
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
- (BOOL)shouldFetchLocalResponseForUrl:(NSString *)url options:(ACNetworkingFetchOption)options param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator expires:(Expire_Time)expire {
    //option只读网络,返回NO
    if (options & ACNetworkingFetchOptionNetOnly) return NO;
    //option只读本地,返回YES
    if (options & ACNetworkingFetchOptionLocalOnly) return YES;
    //option优先读缓存或先读缓存,返回本地是否有未过期缓存
    if (options & ACNetworkingFetchOptionLocalFirst || options & ACNetworkingFetchOptionLocalAndNet) return [self.responseCache cacheExistsForUrl:url param:param expires:expire keyGenerator:generator];
    //以上option均未传,不读缓存
    return NO;
}

#pragma mark - PUBLIC GET
/** API说明
 1.get/post+Net:只走网络请求,不读取本地缓存
 2.get/post+Request:优先走网络请求,网络失败读取本地缓存
 3.get/post+Data:优先读缓存,无缓存走网络请求
 4.get/post+LocalAndNet:先读取本地,然后再走网络请求
 5.get/post+Local:只取本地缓存,不走网络请求
 */

/**
 get请求

 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getNet:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:Expire_Time_Always options:ACNetworkingFetchOptionNetOnly parameters:parameters progress:nil completion:completion];
}

/**
 get数据(优先读网络,失败读缓存,缓存不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:Expire_Time_Never options:ACNetworkingFetchOptionNetFirst parameters:parameters progress:nil completion:completion];
}

/**
 get数据(优先读网络,失败读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getRequest:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:ACNetworkingFetchOptionNetFirst parameters:parameters progress:nil completion:completion];
}


/**
 get数据(优先读缓存, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self getData:URLString expires:Expire_Time_Never parameters:parameters completion:completion];
}

/**
 get数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getData:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:ACNetworkingFetchOptionLocalFirst parameters:parameters progress:nil completion:completion];
}

/**
 get数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self getLocalAndNet:URLString expires:Expire_Time_Never parameters:parameters completion:completion];
}

/**
 get数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocalAndNet:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:expire options:ACNetworkingFetchOptionLocalAndNet parameters:parameters progress:nil completion:completion];
}

/**
 读取本地get数据
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)getLocal:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self get:URLString expires:Expire_Time_Never options:ACNetworkingFetchOptionLocalOnly parameters:parameters progress:nil completion:completion];
}

#pragma mark - PUBLIC POST

/**
 post请求
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postNet:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:Expire_Time_Always options:ACNetworkingFetchOptionNetOnly parameters:parameters progress:nil completion:completion];
}

/**
 post数据(优先读网络,失败读缓存,缓存不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:Expire_Time_Never options:ACNetworkingFetchOptionNetFirst parameters:parameters progress:nil completion:completion];
}

/**
 post数据(优先读网络,失败读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postRequest:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:expire options:ACNetworkingFetchOptionNetFirst parameters:parameters progress:nil completion:completion];
}

/**
 post数据(优先读缓存, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self postData:URLString expires:Expire_Time_Never parameters:parameters completion:completion];
}

/**
 post数据(优先读缓存)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postData:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self post:URLString expires:expire options:ACNetworkingFetchOptionLocalFirst parameters:parameters progress:nil completion:completion];
}

/**
 post数据(先读缓存,再取网络, 不过期)
 
 @param URLString url
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
    return [self postLocalAndNet:URLString expires:Expire_Time_Never parameters:parameters completion:completion];
}

/**
 post数据(先读缓存,再取网络)
 
 @param URLString url
 @param expire 过期时间
 @param parameters 请求参数
 @param completion 回调
 @return 生成的task
 */
- (nullable NSURLSessionDataTask *)postLocalAndNet:(NSString *)URLString expires:(Expire_Time)expire parameters:(nullable NSDictionary *)parameters completion:(ACNetworkingCompletion)completion {
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
    return [self post:URLString expires:Expire_Time_Never options:ACNetworkingFetchOptionLocalOnly parameters:parameters progress:nil completion:completion];
}

/**
 post表单上传(无缓存)
 
 @param URLString url
 @param parameters 请求参数
 @param block 用于构建formData的block
 @param uploadProgress 上传进度
 @param completion 完成回调
 @return 生成的task
 */
- (NSURLSessionDataTask *)postNet:(NSString *)URLString parameters:(id)parameters constructingBlock:(void (^)(id<AFMultipartFormData> _Nonnull))block progress:(void (^)(NSProgress * _Nonnull))uploadProgress completion:(ACNetworkingCompletion)completion {
    return [self.sessionManager POST:URLString parameters:parameters constructingBodyWithBlock:block progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) completion(task, ACNetCacheTypeNet, responseObject, nil, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) completion(task, ACNetCacheTypeNone, nil, error, nil);
    }];
}

@end
