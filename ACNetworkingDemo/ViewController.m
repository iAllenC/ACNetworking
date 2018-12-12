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
@property (nonatomic, strong) ACNetworkingManager *networkinManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.networkinManager = [ACNetworkingManager manager];
//    [self.networkinManager postRequest:@"https://free-api.heweather.com/v5/weather" parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//        NSLog(@"%@",responseObject);
//    }];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.networkinManager postData:@"https://free-api.heweather.com/v5/weather" expires:5 parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
//            NSLog(@"%@",responseObject);
//        }];
//    });
    [self.networkinManager getLocal:@"https://free-api.heweather.com/v5/weather" parameters:@{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118"} completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@",responseObject);
    }];
}

@end
