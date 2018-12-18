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
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *expireTimeField;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *OptionButtons;
@property (weak, nonatomic) IBOutlet UISegmentedControl *methodSegment;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.networkingManager = [ACNetworkingManager managerWithSessionManager:[AFHTTPSessionManager manager] responseCache:[ACNetCache cacheWithNamespace:@"ac_networking" directiory:nil keyGenerator:^NSString *(NSString *url, NSDictionary *param) {
        return [DefaultKeyGenerator(url, param) stringByAppendingString:@"Allen"];
    }]];
    self.networkingManager.sessionManager.requestSerializer.timeoutInterval = 10;
}

- (IBAction)optionBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
}

- (IBAction)sendAction:(id)sender {
    /** 天气接口场景并不适合做缓存,本demo只是用作实例. */
    NSString *url = @"https://free-api.heweather.com/v5/weather";
    NSDictionary *param = @{@"key": @"d9c261ebfe4644aeaea3028bcf10e149", @"city": @"32,118.5"};
    Expire_Time expire;
    if (self.expireTimeField.text.length == 0) {
        expire = Expire_Time_Never;
    } else if (self.expireTimeField.text.doubleValue <= 0) {
        expire = Expire_Time_Always;
    } else {
        expire = self.expireTimeField.text.doubleValue;
    }
    __weak typeof(self) weakSelf = self;
    /** 示例只演示了两个核心入口方法的调用,实际上针对不同场景,本框架都做了一定的便利封装,使用者可根据需要调用 */
    if (self.methodSegment.selectedSegmentIndex == 0) {
        self.task = [self.networkingManager get:url expires:expire options:[self options] parameters:param progress:nil completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
            [weakSelf processNetCache:type Response:responseObject error:error];
        }];
    } else {
        self.task = [self.networkingManager post:url expires:expire options:[self options] parameters:param progress:nil completion:^(NSURLSessionDataTask * _Nullable task, ACNetCacheType type, id  _Nullable responseObject, NSError * _Nullable error) {
            [weakSelf processNetCache:type Response:responseObject error:error];
        }];
    }
}

- (ACNetworkingFetchOption)options {
    ACNetworkingFetchOption option = 0;
    for (UIButton *optionBtn in self.OptionButtons) {
        if (!optionBtn.selected) continue;
        if (option == 0) {
            option = [self optionForTag:optionBtn.tag];
        } else {
            option = option | [self optionForTag:optionBtn.tag];
        }
    }
    if (option == 0) option = ACNetworkingFetchOptionNetFirst;
    return option;
}

- (ACNetworkingFetchOption)optionForTag:(NSInteger)tag {
    switch (tag) {
        case 0:
            return ACNetworkingFetchOptionNetFirst;
        case 1:
            return ACNetworkingFetchOptionNetOnly;
        case 2:
            return ACNetworkingFetchOptionLocalOnly;
        case 3:
            return ACNetworkingFetchOptionLocalFirst;
        case 4:
            return ACNetworkingFetchOptionLocalAndNet;
        case 5:
            return ACNetworkingFetchOptionNotUpdateCache;
        case 6:
            return ACNetworkingFetchOptionDeleteCache;
        default:
            return ACNetworkingFetchOptionNetFirst;
    }
}

- (void)processNetCache:(ACNetCacheType)cacheType Response:(id)response error:(NSError *)error {
    NSLog(@"Response:%@",response);
    if (cacheType == ACNetCacheTypeNone) {
        self.textView.text = [NSString stringWithFormat:@"%@:\n%@", [self typeNameForCacheType:cacheType], error.localizedDescription];
    } else {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.textView.text = [NSString stringWithFormat:@"%@:\n%@", [self typeNameForCacheType:cacheType], jsonString];
    }
}

- (NSString *)typeNameForCacheType:(ACNetCacheType)type {
    switch (type) {
        case ACNetCacheTypeNet:
            return @"网络返回结果";
        case ACNetCacheTypeMemroy:
            return @"内存缓存结果";
        case ACNetCacheTypeDisk:
            return @"磁盘缓存结果";
        case ACNetCacheTypeNone:
            return @"无结果";
        default:
            return nil;
    }
}

@end
