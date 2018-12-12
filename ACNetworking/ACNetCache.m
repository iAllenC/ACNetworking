//
//  ACNetCache.m
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import "ACNetCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface ACMemoryCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType>

@property (nonatomic, strong) NSMutableDictionary<KeyType, NSDate *> *expireDateDict;

@property (nonatomic, strong) NSMutableDictionary<KeyType, NSDate *> *addedDateDict;

@end

@implementation ACMemoryCache

/**
 缓存对象,移除key对应的过期时间
 
 @param obj 对象
 @param key key
 */
- (void)setObject:(id)obj forKey:(id)key {
    [self setObject:obj forKey:key refreshExpireDate:YES];
}

/**
 缓存对象
 
 @param obj 对象
 @param key key
 @param refresh 是否移除key对应的过期时间
 */
- (void)setObject:(id)obj forKey:(id)key refreshExpireDate:(BOOL)refresh {
    [super setObject:obj forKey:key];
    /** 添加缓存的同时缓存该obj的添加时间 */
    [self.addedDateDict setObject:[NSDate date] forKey:key];
    if (refresh && [self.expireDateDict.allKeys containsObject:key]) [self.expireDateDict removeObjectForKey:key];
}

/**
 缓存对象,移除key对应的过期时间
 
 @param obj 对象
 @param key key
 @param g 消耗
 */
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [self setObject:obj forKey:key cost:g refreshExpireDate:YES];
}

/**
 缓存对象

 @param obj 对象
 @param key key
 @param g 消耗
 @param refresh 是否移除key对应的过期时间
 */
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g refreshExpireDate:(BOOL)refresh {
    [super setObject:obj forKey:key cost:g];
    /** 添加缓存的同时缓存该obj的添加时间 */
    [self.addedDateDict setObject:[NSDate date] forKey:key];
    if (refresh && [self.expireDateDict.allKeys containsObject:key]) [self.expireDateDict removeObjectForKey:key];
}

- (id)objectForKey:(id)key {
    /** 首先检查该key所缓存的对象是否有过期时间,如果有且已过期,则返回nil */
    NSDate *expireDate = [self.expireDateDict objectForKey:key];
    if (expireDate && [expireDate timeIntervalSinceNow] <= 0) return nil;
    return [super objectForKey:key];
}

/**
 缓存对象并指定过期时间

 @param obj 对象
 @param key key
 @param expire 过期时间
 */
- (void)setObject:(id)obj forKey:(id)key expires:(NSTimeInterval)expire {
    [self setObject:obj forKey:key expireDate:[NSDate dateWithTimeIntervalSinceNow:expire]];
}

/**
 缓存对象并指定过期时间
 
 @param obj 对象
 @param key key
 @param g 消耗
 @param expire 过期时间
 */
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g expires:(NSTimeInterval)expire {
    [self setObject:obj forKey:key cost:g expireDate:[NSDate dateWithTimeIntervalSinceNow:expire]];
}

/**
 缓存对象并指定过期时间
 
 @param obj 对象
 @param key key
 @param expireDate 过期日期
 */
- (void)setObject:(id)obj forKey:(id)key expireDate:(NSDate *)expireDate {
    if (expireDate) {
        [self.expireDateDict setObject:expireDate forKey:key];
    } else if ([self.expireDateDict objectForKey:key]) {
        [self.expireDateDict removeObjectForKey:key];
    }
    [self setObject:obj forKey:key refreshExpireDate:NO];
}

/**
 缓存对象并指定过期时间
 
 @param obj 对象
 @param key key
 @param g 消耗
 @param expireDate 过期日期
 */
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g expireDate:(NSDate *)expireDate {
    if (expireDate) {
        [self.expireDateDict setObject:expireDate forKey:key];
    } else if ([self.expireDateDict objectForKey:key]) {
        [self.expireDateDict removeObjectForKey:key];
    }
    [self setObject:obj forKey:key cost:g refreshExpireDate:NO];
}

/**
 根据过期时长获取缓存的对象

 @param key key
 @param expire 过期时间
 @return 缓存的对象
 */
- (id)objectForKey:(id)key expires:(NSTimeInterval)expire {
    NSDate *addedDate = [self.addedDateDict objectForKey:key];
    if (addedDate && [[addedDate dateByAddingTimeInterval:expire] timeIntervalSinceNow] <= 0) return nil;
    return [self objectForKey:key];
}

/** 用于保存对象的过期日期 */
- (NSMutableDictionary *)expireDateDict {
    if (!_expireDateDict) {
        _expireDateDict = [NSMutableDictionary dictionary];
    }
    return _expireDateDict;
}

/** 用于保存对象的添加日期 */
- (NSMutableDictionary *)addedDateDict {
    if (!_addedDateDict) {
        _addedDateDict = [NSMutableDictionary dictionary];
    }
    return _addedDateDict;
}

@end

@interface ACNetCache()

@property (nonatomic, copy) NSString *diskDirectory;

@property (strong, nonatomic, nullable) dispatch_queue_t ioQueue;

@property (strong, nonatomic, nonnull) NSFileManager *fileManager;

@property (nonatomic, strong) ACMemoryCache *memoryCache;

@end


@implementation ACNetCache

+ (instancetype)sharedCache {
    static ACNetCache *_sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [ACNetCache cacheWithNamespace:@"defaultCache" directiory:nil];
    });
    return _sharedCache;
}

- (instancetype)initWithNamespace:(nonnull NSString *)namespace directiory:(NSString *)directory {
    if (self = [super init]) {
        _ioQueue = dispatch_queue_create("com.acnetworking.netcache", DISPATCH_QUEUE_SERIAL);
        NSString *fullNamespace = [@"com.acnetworking.netcache" stringByAppendingString:namespace];
        if (directory) {
            _diskDirectory = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            _diskDirectory = [self makeDiskCachePath:fullNamespace];
        }
        _memoryCache = [[ACMemoryCache alloc] init];
        _memoryCache.name = fullNamespace;
        dispatch_sync(_ioQueue, ^{
            self.fileManager = [NSFileManager new];
        });
    }
    return self;
}

+ (instancetype)cacheWithNamespace:(NSString *)namespace directiory:(NSString *)directory {
    return [[self alloc] initWithNamespace:namespace directiory:directory];
}

- (nullable NSString *)makeDiskCachePath:(nonnull NSString*)fullNamespace {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param params 请求参数
 @return 是否有缓存
 */
- (BOOL)netCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params {
    return [self netCacheExistsForUrl:url params:params expires:MAXFLOAT];
}

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param params 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)netCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params expires:(NSTimeInterval)expire {
    return [self memoryCacheExistsForUrl:url params:params expires:expire] || [self diskCacheExistsForUrl:url params:params expires:expire];
}

/**
 检查内存缓存中是否存在对应的response缓存

 @param url URL
 @param params 请求参数
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params {
    return [self memoryCacheExistsForKey:[self.class fetchCacheKeyWithUrl:url params:params]];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param params 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params expires:(NSTimeInterval)expire {
    return [self memoryCacheExistsForKey:[self.class fetchCacheKeyWithUrl:url params:params] expires:expire];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param key Key
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForKey:(NSString *)key {
    return [self.memoryCache objectForKey:key] != nil;
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param key Key
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForKey:(NSString *)key expires:(NSTimeInterval)expire {
    return [self.memoryCache objectForKey:key expires:expire] != nil;
}


/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param params 请求参数
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params {
    return [self diskCacheExistsForKey:[self.class fetchCacheKeyWithUrl:url params:params] expires:MAXFLOAT];
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param params 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url params:(NSDictionary *)params expires:(NSTimeInterval)expire {
    return [self diskCacheExistsForKey:[self.class fetchCacheKeyWithUrl:url params:params] expires:expire];

}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param key Key
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForKey:(NSString *)key expires:(NSTimeInterval)expire {
    if (!key) return NO;
    __block BOOL exists = NO;
    dispatch_sync(self.ioQueue, ^{
        exists = [self _diskCacheExistsForKey:key expires:expire];
    });
    return exists;
}

/**
 内部方法,检查磁盘缓存中是否存在对应的response缓存,需确保此方法在self.ioQueue中调用

 @param key Key
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)_diskCacheExistsForKey:(NSString *)key expires:(NSTimeInterval)expire {
    if (!key) return NO;
    NSString *filePath = [self filePathForStoreKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    if (!exists) exists = [self.fileManager fileExistsAtPath:filePath.stringByDeletingPathExtension];
    if (exists) exists = ![self fileExpiredAtPath:[self filePathForStoreKey:key] expires:expire];
    return exists;
}

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param params 请求参数
 */
- (void)storeResponse:(id)response forUrl:(nonnull NSString *)url params:(NSDictionary *)params {
    [self storeResponse:response forUrl:url params:params toMemory:YES toDisk:YES];
}

/**
 缓存response

 @param response 要缓存的结果
 @param url URL
 @param params 请求参数
 @param toMemory 是否缓存到内存
 @param toDisk 是否缓存到磁盘
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url params:(NSDictionary *)params toMemory:(BOOL)toMemory toDisk:(BOOL)toDisk {
    if (!toMemory && !toDisk) return;
    NSString *storeKey = [self.class fetchCacheKeyWithUrl:url params:params];
    if (toMemory) [self.memoryCache setObject:response forKey:storeKey];
    if (toDisk) [self storeResponseToDisk:response forKey:storeKey];
}

/**
 缓存response到磁盘

 @param response 要缓存的结果
 @param storeKey 缓存的Key
 */
- (void)storeResponseToDisk:(id)response forKey:(NSString *)storeKey {
    if (!storeKey || !response) return;
    dispatch_async(self.ioQueue, ^{
        [[NSKeyedArchiver archivedDataWithRootObject:response] writeToFile:[self filePathForStoreKey:storeKey] atomically:YES];
    });
}

/**
 删除本地内存缓存和磁盘缓存的response

 @param url URL
 @param params 请求参数
 */
- (void)deleteResponseForUrl:(NSString *)url params:(NSDictionary *)params {
    [self deleteResponseForUrl:url params:params fromMemory:YES fromDisk:YES];
}

/**
 删除本地response缓存

 @param url URL
 @param params 请求参数
 @param fromMemory 是否删除内存缓存
 @param fromDisk 是否删除磁盘缓存
 */
- (void)deleteResponseForUrl:(NSString *)url params:(NSDictionary *)params fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk {
    NSString *storeKey = [self.class fetchCacheKeyWithUrl:url params:params];
    if (fromMemory && [self memoryCacheExistsForKey:storeKey]) [self.memoryCache removeObjectForKey:storeKey];
    if (fromDisk && [self diskCacheExistsForKey:storeKey expires:MAXFLOAT]) {
        dispatch_async(self.ioQueue, ^{
            NSString *filePath = [self filePathForStoreKey:storeKey];
            if ([self.fileManager fileExistsAtPath:filePath]) [self.fileManager removeItemAtPath:filePath error:nil];
        });
    }
}

/**
 获取本地缓存的response,不过期
 
 @param url URL
 @param param 请求参数
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param completion:(ACNetCacheFetchCompletion)completion {
    [self fetchResponseForUrl:url param:param expires:MAXFLOAT completion:completion];
}

/**
 获取本地缓存的response

 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param expires:(NSTimeInterval)expire completion:(ACNetCacheFetchCompletion)completion {
    if (!url || !completion) return;
    NSString *storeKey = [self.class fetchCacheKeyWithUrl:url params:param];
    __block id result = [self.memoryCache objectForKey:storeKey expires:expire];
    if (result) return completion(ACNetCacheTypeMemroy, result);
    dispatch_async(self.ioQueue, ^{
        NSString *filePath = [self filePathForStoreKey:storeKey];
        if (!filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(ACNetCacheTypeNone, nil);
            });
        }
        result = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self fileExpiredAtPath:filePath expires:expire]) {
                completion(ACNetCacheTypeNone, nil);
            } else {
                completion(ACNetCacheTypeDisk, result);
            }
        });
    });
}

/**
 根据key获取文件存储路径

 @param storeKey key
 @return 存储路径
 */
- (NSString *)filePathForStoreKey:(NSString *)storeKey {
    if (![self.fileManager fileExistsAtPath:self.diskDirectory]) {
        [self.fileManager createDirectoryAtPath:self.diskDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return [self.diskDirectory stringByAppendingPathComponent:storeKey];
}

/**
 根据url和paramsc生成存储Key

 @param url url
 @param params params
 @return key
 */
+ (NSString *)fetchCacheKeyWithUrl:(NSString *)url params:(NSDictionary *)params
{
    NSArray *keys = [params allKeys];
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSComparisonResult result = [obj1 compare:obj2];
        return  result == NSOrderedDescending;
    }];
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *key in keys)
    {
        NSString *value = params[key];
        NSString *string = [NSString stringWithFormat:@"%@=%@",key,value];
        [array addObject:string];
    }
    NSString *result = [array componentsJoinedByString:@"&"];
    return [self ac_md5String:[url stringByAppendingString:result]];
}

/**
 MD5加密

 @param string 加密前
 @return 加密后
 */
+ (NSString *)ac_md5String:(NSString *)string {
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
 检查文件是否过期

 @param filePath 文件路径
 @param expire 过期时间
 @return 是否过期
 */
- (BOOL)fileExpiredAtPath:(NSString *)filePath expires:(NSTimeInterval)expire {
    if (expire <= 0 || !filePath) return YES;
    NSDate *modicationDate = [self fileModificationDateAtPath:filePath];
    if (!modicationDate) return YES;
    NSTimeInterval modificationTime = [modicationDate timeIntervalSince1970];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return modificationTime + expire <= now;
}

/**
 获取文件的修改日期

 @param filePath 文件路径
 @return 修改日期
 */
- (NSDate *)fileModificationDateAtPath:(NSString *)filePath
{
    if (![self.fileManager fileExistsAtPath:filePath]) return nil;
    NSDate *date = (NSDate *)[self propertyOfFileAtPath:filePath key:NSFileModificationDate];
    return date;
}

/**
 获取文件相关属性

 @param filePath 文件路径
 @param key 属性对应的key
 @return 属性
 */
- (id)propertyOfFileAtPath:(NSString *)filePath key:(NSString *)key
{
    NSError *error;
    NSDictionary *info = [_fileManager attributesOfItemAtPath:filePath error:&error];
    if (error) return nil;
    id result = [info objectForKey:key];
    return result;
}

@end
