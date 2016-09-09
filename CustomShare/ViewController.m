//
//  ViewController.m
//  CustomShare
//
//  Created by iOS Developer on 16/9/2.
//  Copyright © 2016年 yinjn. All rights reserved.
//

#import "ViewController.h"
#import "JNShareSDKSevice.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    shareBtn.frame = CGRectMake(30, 40, 100, 50);
    shareBtn.backgroundColor = [UIColor redColor];
    [shareBtn setTitle:@"点击分享" forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareBtn];
}

-(void)shareBtnClick:(UIButton *)button{
    //下面customView字段为是否自定义分享UI，如果自定义就写YES，想用shareSDK默认的就写NO
    [JNShareSDKSevice shareAppParamsByText:@"我今天在github上看到了这个shareSDK自定义分享UI的demo" title:@"JNShareSDK" images:[UIImage imageNamed:@"share005-.png"] url:@"www.baidu.com" type:SSDKContentTypeAuto customView:YES isIpd:nil onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
        switch (state) {
            case SSDKResponseStateBegin:
                break;
            case SSDKResponseStateSuccess:
                NSLog(@"分享成功");
                break;
            case SSDKResponseStateFail:
                NSLog(@"%@",[error.userInfo objectForKey:@"error_message"]);
                break;
            case SSDKResponseStateCancel:
                NSLog(@"分享失败");
                break;
            default:
                break;
        }
        
    } CustomShare:^{//自定义的分享平台被点击
        
    }];
    //不想要自定义分享平台可以隐藏掉
    //    //把自定义平台隐藏掉
    //    [JNShareSDKSevice hiddenCustomShare];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
