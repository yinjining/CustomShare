//
//  JNShareSDKSevice.h
//
//  Created by yinjn on 16/3/22.
//  Copyright © 2016年 com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ShareSDK/ShareSDK.h>

//申请的各种分享KEY
#define SinaWeibo_APP_KEY @"4282727078"
#define SinaWeibo_APP_SECRET @"165f734553f2f8712d47e8a3a73bda86"
#define SinaWeibo_RedirectUri @"http://iximo.com"

#define QQ_APP_ID @"2311607630"
#define QQ_APP_KEY @"iximo2016"

#define WeChat_APP_ID @"wx425959b4749ba75b"
#define WeChat_APP_Secret @"a7551fd4f775b6c67b3d360c4a294692"

typedef void (^isCustomShare)();
@interface JNShareSDKSevice : NSObject
#pragma mark - 分享
/**
 *   didFinishLaunchingWithOptions方法中实现的代码
 *   注册ShareSDK
 */
//里面的id都要变
+ (void)registerShareSDK;

/**
 *   分享内容
 *   @param 	text 	    分享内容
 *   @param 	title       分享标题
 *   @param 	images      分享图片
 *   @param 	url         分享链接
 *   @param 	type        分享类型  SSDKContentTypeAuto
 *   @param     customView  是否自定义分享View
 *   @param     isIpd       不是ipd传可以nil，是就传入点击button
 *   @param     stateChangeHandler  系统平台变更回调处理
 *   @param     message     自定义平台回调处理方法
 */
+ (void)shareAppParamsByText:(NSString*)text title:(NSString *)title images:(id)images url:(NSString*)url type:(SSDKContentType)type customView:(BOOL)customView isIpd:(id)sender onStateChanged:(SSDKShareStateChangedHandler)stateChangedHandler CustomShare:(isCustomShare)message;

//隐藏掉自定义的分向平台
+(void)hiddenCustomShare;

#pragma mark - 登录
+ (void)getUserInfo:(SSDKPlatformType)platformType
     onStateChanged:(SSDKGetUserStateChangedHandler)stateChangedHandler;
#pragma mark - 注销
+ (void)thirdLogout:(SSDKPlatformType)loginType;
@end
