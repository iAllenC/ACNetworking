//
//  ViewController.m
//  ACNetworkingDemo
//
//  Created by Allen on 2018/12/6.
//  Copyright © 2018 Allen. All rights reserved.
//

#import "ViewController.h"
#import "ACNetworkingManager.h"

@interface ViewController ()
@property (nonatomic, strong) ACNetworkingManager *networkingManager;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.networkingManager = [ACNetworkingManager managerWithSessionManager:[AFHTTPSessionManager manager] responseCache:[ACNetCache cacheWithNamespace:@"ac_networking" directiory:nil keyGenerator:^NSString *(NSString *url, NSDictionary *param) {
        return [DefaultKeyGenerator(url, param) stringByAppendingString:@"Allen"];
    }]];
    self.networkingManager.sessionManager.requestSerializer.timeoutInterval = 10;
//    self.task = [self.networkingManager postRequest:@"https://free-api.heweather.com/v5/weather" parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//        NSLog(@"%@",responseObject);
//    }];
    self.task = [self.networkingManager post:@"https://free-api.heweather.com/v5/weather" expires:Expire_Time_Never options:ACNetworkingFetchOptionLocalFirst | ACNetworkingFetchOptionDeleteCache parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"} progress:nil completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@",responseObject);
    }];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.networkinManager postData:@"https://free-api.heweather.com/v5/weather" expires:5 parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//            NSLog(@"%@",responseObject);
//        }];
//    });
//    self.task = [self.networkinManager getLocal:@"https://free-api.heweather.com/v5/weather" parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5", @"test": @{@"1":@"1",@"2":@"2",@"3":@"3"}} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//        NSLog(@"%@",responseObject);
//    }];
//    self.task = [self.networkingManager postLocalAndNet:@"https://free-api.heweather.com/v5/weather"  parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//        NSLog(@"%@",responseObject);
//    }];
//    self.task = [self.networkingManager post:@"https://free-api.heweather.com/v5/weather" expires:Expire_Time_Never options:ACNetworkingFetchOptionNetOnly | ACNetworkingFetchOptionDeleteCache parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"} progress:nil completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//        NSLog(@"%@",responseObject);
//    }];
    NSLog(@"Task:%@", self.task);
}

@end
