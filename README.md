# ACNetworking

## 简介

本框架是基于AFNetworking的网络缓存库，可将请求返回结果缓存的内存及磁盘，且支持自定义生成缓存Key。

## 核心类

* ACNetworkingManager 框架的主入口，封装了基于AFNetworking的各种post和get方法。

* ACNetCache 请求结果缓存工具类，支持结果的写入、读取、删除。可以指定缓存目录及命名空间。

* ACNetCacheKeyGenerator 一个Block定义，负责生成结果缓存的Key。

## 引入
```
pod 'ACNetworking', '~> 1.0.1'
```
## 使用

### 1.创建ACNetworkingManager:
该类的构造方法需要传入一个AFHttpSessionManager,一个ACNetCache，一个ACNetCacheKeyGenerator，均有默认参数

```
ACNetworkingManager  *your_manager = [ACNetworkingManager manager];
ACNetworkingManager  *your_manager = [ACNetworkingManager managerWithSessionManager:your_session_manager]；
ACNetCache  *your_cache = [ACNetCache cacheWithNamespace:@"your_cache_name_space" directiory:@"your_cache_directory" keyGenerator:your_keyGenerator];
ACNetworkingManager  *your_manager = [ACNetworkingManager managerWithSessionManager:your_session_manager 
responseCache:your_cache];
```
### 2.请求API，以POST请求为例：
* 只取网络请求

```
[your_manager postRequest:@"your_api" parameters: your_parameter completion: your_completion];
```

* 优先取缓存，没有缓存取本地：

```
可以传入过期时长：
[your_manager postData:@"your_api" expires:your_expire_time parameters:your_parameter completion:your_completion];
如果不需要过期时长：
[your_manager postData:@"your_api" parameters:your_parameter completion:your_completion];
```

* 只取本地缓存：

```
[your_manager postLocal:@"your_api" parameters: your_parameter completion: your_completion];
```

* 先取本地，然后再取网络：

```
[your_manager postLocalAndNet:@"your_api" parameters: your_parameter completion: your_completion];
```

* 以上方法的完整版本：

```
[your_manager post:@"your_api" expires:your_expire_time options:your_option1 |  your_option2 parameters:your_parameter progress:your_progress completion:your_completion];
```

### 2.以上API均有对应的GET版本
