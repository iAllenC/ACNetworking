//
//  ACNetCache.m
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import "ACNetCache.h"

@interface ACMemoryCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType>

@property (nonatomic, strong) NSMutableDictionary<KeyType, NSDate *> *expireDateDict;

@property (nonatomic, strong) NSMutableDictionary<KeyType, NSDate *> *updateDateDict;

@end

@implementation ACMemoryCache

#pragma mark - Override

- (id)objectForKey:(id)key {
    /** 首先检查该key所缓存的对象是否有过期时间,如果有且已过期,则返回nil */
    NSDate *expireDate = [self.expireDateDict objectForKey:key];
    if (expireDate && [expireDate timeIntervalSinceNow] <= 0) return nil;
    return [super objectForKey:key];
}

/**
 缓存对象,移除key对应的过期时间
 
 @param obj 对象
 @param key key
 */
- (void)setObject:(id)obj forKey:(id)key {
    [self setObject:obj forKey:key refreshExpireDate:YES];
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

#pragma mark - Expanded Method
/**
 缓存对象
 
 @param obj 对象
 @param key key
 @param refresh 是否移除key对应的过期时间
 */
- (void)setObject:(id)obj forKey:(id)key refreshExpireDate:(BOOL)refresh {
    [super setObject:obj forKey:key];
    /** 添加缓存的同时缓存该obj的添加时间 */
    [self.updateDateDict setObject:[NSDate date] forKey:key];
    if (refresh && [self.expireDateDict.allKeys containsObject:key]) [self.expireDateDict removeObjectForKey:key];
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
    [self.updateDateDict setObject:[NSDate date] forKey:key];
    if (refresh && [self.expireDateDict.allKeys containsObject:key]) [self.expireDateDict removeObjectForKey:key];
}

/**
 缓存对象并指定过期时间

 @param obj 对象
 @param key key
 @param expire 过期时间
 */
- (void)setObject:(id)obj forKey:(id)key expires:(Expire_Time)expire {
    [self setObject:obj forKey:key expireDate:[NSDate dateWithTimeIntervalSinceNow:expire]];
}

/**
 缓存对象并指定过期时间
 
 @param obj 对象
 @param key key
 @param g 消耗
 @param expire 过期时间
 */
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g expires:(Expire_Time)expire {
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
- (id)objectForKey:(id)key expires:(Expire_Time)expire {
    NSDate *addedDate = [self.updateDateDict objectForKey:key];
    if (addedDate && [[addedDate dateByAddingTimeInterval:expire] timeIntervalSinceNow] <= 0) return nil;
    return [self objectForKey:key];
}

- (NSDate *)updateDateForKey:(NSString *)key {
    return self.updateDateDict[key];
}

#pragma mark - Lazy

/** 用于保存对象的过期日期 */
- (NSMutableDictionary *)expireDateDict {
    if (!_expireDateDict) {
        _expireDateDict = [NSMutableDictionary dictionary];
    }
    return _expireDateDict;
}

/** 用于保存对象的添加日期 */
- (NSMutableDictionary *)updateDateDict {
    if (!_updateDateDict) {
        _updateDateDict = [NSMutableDictionary dictionary];
    }
    return _updateDateDict;
}

@end

@interface ACNetCache()

@property (nonatomic, copy) NSString *diskDirectory;

@property (strong, nonatomic, nonnull) dispatch_queue_t ioQueue;

@property (strong, nonatomic, nonnull) NSFileManager *fileManager;

@property (nonatomic, strong) ACMemoryCache *memoryCache;

@end


@implementation ACNetCache

#pragma mark - Singleton

+ (instancetype)sharedCache {
    static ACNetCache *_sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [ACNetCache cacheWithNamespace:@"defaultCache"];
    });
    return _sharedCache;
}

#pragma mark - Constructor

- (instancetype)initWithNamespace:(NSString *)ns directiory:(NSString *)directory keyGenerator:(ACNetCacheKeyGenerator)keyGenerator {
    if (self = [super init]) {
        _ioQueue = dispatch_queue_create("com.acnetworking.netcache", DISPATCH_QUEUE_SERIAL);
        NSString *fullNamespace = [@"com.acnetworking.netcache." stringByAppendingString:ns];
        if (directory) {
            _diskDirectory = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            _diskDirectory = [self makeDiskCachePath:fullNamespace];
        }
        _memoryCache = [[ACMemoryCache alloc] init];
        _memoryCache.name = fullNamespace;
        if (keyGenerator) _keyGenerator = keyGenerator;
        dispatch_sync(_ioQueue, ^{
            self.fileManager = [NSFileManager new];
        });
    }
    return self;
}

+ (instancetype)cacheWithNamespace:(NSString *)ns {
    return [self cacheWithNamespace:ns directiory:nil];
}

+ (instancetype)cacheWithNamespace:(NSString *)ns directiory:(nullable NSString *)directory {
    return [self cacheWithNamespace:ns directiory:directory keyGenerator:nil];
}

+ (instancetype)cacheWithNamespace:(NSString *)ns directiory:(nullable NSString *)directory keyGenerator:(nullable ACNetCacheKeyGenerator)keyGenerator {
    return [[self alloc] initWithNamespace:ns directiory:directory keyGenerator:keyGenerator];
}

- (NSString *)makeDiskCachePath:(NSString*)fullNamespace {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

#pragma mark - Check

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)cacheExistsForUrl:(NSString *)url param:(NSDictionary *)param {
    return [self cacheExistsForUrl:url param:param keyGenerator:nil];
}

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)cacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire {
    return [self cacheExistsForUrl:url param:param expires:expire keyGenerator:nil];
}

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @param generator 缓存key生成器
 @return 是否有缓存
 */
- (BOOL)cacheExistsForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator {
    return [self cacheExistsForUrl:url param:param expires:Expire_Time_Never keyGenerator:generator];
}

/**
 检查内存或磁盘缓存中是否有缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param generator 缓存key生成器
 @return 是否有缓存
 */
- (BOOL)cacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire keyGenerator:(ACNetCacheKeyGenerator)generator {
    return [self memoryCacheExistsForUrl:url param:param keyGenerator:generator expires:expire] || [self diskCacheExistsForUrl:url param:param keyGenerator:generator expires:expire];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param {
    return [self memoryCacheExistsForUrl:url param:param keyGenerator:nil];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param generator 缓存Key生成器
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator {
    return [self memoryCacheExistsForKey:[self fetchCacheKeyWithUrl:url param:param keyGenerator:generator]];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire {
    return [self memoryCacheExistsForUrl:url param:param keyGenerator:nil expires:expire];
}

/**
 检查内存缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param generator 缓存Key生成器
 @return 是否有缓存
 */
- (BOOL)memoryCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator expires:(Expire_Time)expire {
    return [self memoryCacheExistsForKey:[self fetchCacheKeyWithUrl:url  param:param keyGenerator:generator] expires:expire];
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
- (BOOL)memoryCacheExistsForKey:(NSString *)key expires:(Expire_Time)expire {
    return [self.memoryCache objectForKey:key expires:expire] != nil;
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param {
    return [self diskCacheExistsForUrl:url param:param keyGenerator:nil];
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire {
    return [self diskCacheExistsForUrl:url param:param keyGenerator:nil expires:expire];
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param generator 缓存Key生成器
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator {
    return [self diskCacheExistsForKey:[self fetchCacheKeyWithUrl:url  param:param keyGenerator:generator] expires:Expire_Time_Never];
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param generator 缓存Key生成器
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator expires:(Expire_Time)expire {
    return [self diskCacheExistsForKey:[self fetchCacheKeyWithUrl:url  param:param keyGenerator:generator] expires:expire];
}

/**
 检查磁盘缓存中是否存在对应的response缓存
 
 @param key Key
 @return 是否有缓存
 */
- (BOOL)diskCacheExistsForKey:(NSString *)key expires:(Expire_Time)expire {
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
- (BOOL)_diskCacheExistsForKey:(NSString *)key expires:(Expire_Time)expire {
    if (!key) return NO;
    NSString *filePath = [self filePathForStoreKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    if (exists) exists = ![self fileExpiredAtPath:[self filePathForStoreKey:key] expires:expire];
    return exists;
}

#pragma mark - Store

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 */
- (void)storeResponse:(id)response forUrl:(nonnull NSString *)url param:(NSDictionary *)param {
    [self storeResponse:response forUrl:url param:param toMemory:YES toDisk:YES];
}

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 @param generator 缓存Key生成器
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator {
    [self storeResponse:response forUrl:url param:param keyGenerator:generator toMemory:YES toDisk:YES];
}

/**
 缓存response

 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 @param toMemory 是否缓存到内存
 @param generator 缓存Key生成器
 @param toDisk 是否缓存到磁盘
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator toMemory:(BOOL)toMemory toDisk:(BOOL)toDisk {
    if (!toMemory && !toDisk) return;
    NSString *storeKey = [self fetchCacheKeyWithUrl:url param:param keyGenerator:generator];
    if (toMemory) [self.memoryCache setObject:response forKey:storeKey];
    if (toDisk) [self storeResponseToDisk:response forKey:storeKey];
}

/**
 缓存response
 
 @param response 要缓存的结果
 @param url URL
 @param param 请求参数
 @param toDisk 是否缓存到磁盘
 */
- (void)storeResponse:(id)response forUrl:(NSString *)url param:(NSDictionary *)param toMemory:(BOOL)toMemory toDisk:(BOOL)toDisk {
    [self storeResponse:response forUrl:url param:param keyGenerator:nil toMemory:toMemory toDisk:toDisk];
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

#pragma mark - Fetch

/**
 异步获取本地缓存的response,不过期
 
 @param url URL
 @param param 请求参数
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param completion:(ACNetCacheFetchCompletion)completion {
    [self fetchResponseForUrl:url param:param expires:Expire_Time_Never completion:completion];
}

/**
 异步获取本地缓存的response

 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire completion:(ACNetCacheFetchCompletion)completion {
    [self fetchResponseForUrl:url param:param expires:expire  async:YES completion:completion];
}

/**
 获取本地缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 @param generator 缓存Key生成器
 @param async 是否异步
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator expires:(Expire_Time)expire async:(BOOL)async completion:(ACNetCacheFetchCompletion)completion {
    if (!completion) return;
    if (!url) return completion(ACNetCacheTypeNone, nil, nil);
    NSString *storeKey = [self fetchCacheKeyWithUrl:url param:param keyGenerator:generator];
    __block id result = [self.memoryCache objectForKey:storeKey expires:expire];
    if (result) return completion(ACNetCacheTypeMemroy, result, [self.memoryCache updateDateForKey:storeKey]);
    NSString *filePath = [self filePathForStoreKey:storeKey];
    if (async) {
        dispatch_async(self.ioQueue, ^{
            if (!filePath) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(ACNetCacheTypeNone, nil, nil);
                });
            }
            if ([self fileExpiredAtPath:filePath expires:expire]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(ACNetCacheTypeNone, nil, nil);
                });
            } else {
                result = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(ACNetCacheTypeDisk, result, [self fileModificationDateAtPath:filePath]);
                });
            }
        });
    } else {
        __block ACNetCacheType type = ACNetCacheTypeNone;
        __block NSDate *date = nil;
        dispatch_sync(self.ioQueue, ^{
            if (filePath && ![self fileExpiredAtPath:filePath expires:expire]) {
                result = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                date = [self fileModificationDateAtPath:filePath];
                type = ACNetCacheTypeDisk;
            }
        });
        completion(type, result, date);
    }
}

/**
 获取本地缓存的response
 
 @param url URL
 @param param 请求参数
 @param expire 过期时间
 @param completion 回调
 @param async 是否异步
 */
- (void)fetchResponseForUrl:(NSString *)url param:(NSDictionary *)param expires:(Expire_Time)expire async:(BOOL)async completion:(ACNetCacheFetchCompletion)completion {
    [self fetchResponseForUrl:url param:param keyGenerator:nil expires:expire async:async completion:completion];
}

#pragma mark - Delete

/**
 删除本地内存缓存和磁盘缓存的response
 
 @param url URL
 @param param 请求参数
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param {
    [self deleteResponseForUrl:url param:param fromMemory:YES fromDisk:YES];
}

/**
 删除本地内存缓存和磁盘缓存的response
 
 @param url URL
 @param param 请求参数
 @param generator 缓存Key生成器
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(nullable ACNetCacheKeyGenerator)generator {
    [self deleteResponseForUrl:url param:param keyGenerator:generator fromMemory:YES fromDisk:YES];
}

/**
 删除本地response缓存
 
 @param url URL
 @param param 请求参数
 @param generator 缓存Key生成器
 @param fromMemory 是否删除内存缓存
 @param fromDisk 是否删除磁盘缓存
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk {
    NSString *storeKey = [self fetchCacheKeyWithUrl:url  param:param keyGenerator:generator];
    if (fromMemory && [self memoryCacheExistsForKey:storeKey]) [self.memoryCache removeObjectForKey:storeKey];
    if (fromDisk && [self diskCacheExistsForKey:storeKey expires:Expire_Time_Never]) {
        dispatch_async(self.ioQueue, ^{
            NSString *filePath = [self filePathForStoreKey:storeKey];
            if ([self.fileManager fileExistsAtPath:filePath]) [self.fileManager removeItemAtPath:filePath error:nil];
        });
    }
}

/**
 删除本地response缓存
 
 @param url URL
 @param param 请求参数
 @param fromMemory 是否删除内存缓存
 @param fromDisk 是否删除磁盘缓存
 */
- (void)deleteResponseForUrl:(NSString *)url param:(NSDictionary *)param fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk {
    [self deleteResponseForUrl:url param:param keyGenerator:nil fromMemory:fromMemory fromDisk:fromDisk];
}


#pragma mark - Helper
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
 根据url和paramc生成存储Key
 
 @param url url
 @param param param
 @return key
 */
- (NSString *)fetchCacheKeyWithUrl:(NSString *)url param:(NSDictionary *)param keyGenerator:(ACNetCacheKeyGenerator)generator {
    NSString *key = generator ? generator(url, param) : self.keyGenerator(url, param);
    return key ?: DefaultKeyGenerator(url, param);
}

/**
 检查文件是否过期

 @param filePath 文件路径
 @param expire 过期时间
 @return 是否过期
 */
- (BOOL)fileExpiredAtPath:(NSString *)filePath expires:(Expire_Time)expire {
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

#pragma mark - Lazy

- (ACNetCacheKeyGenerator)keyGenerator {
    return _keyGenerator ?: DefaultKeyGenerator;
}

@end


