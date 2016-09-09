//
//  JNShareSDKSevice.m
//
//  Created by yinjn on 16/3/22.
//  Copyright © 2016年 com. All rights reserved.
//

#import "JNShareSDKSevice.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <ShareSDK/ShareSDK+Base.h>
#import <ShareSDKUI/SSUIShareActionSheetCustomItem.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import "WeiboSDK.h"

//注释的这个高再下面定义了，是在分享的时候如果没有安装客户端，可以把客户端隐藏掉
//#define VIEWHEIGHT 244  //分享界面的高
#define VIEWWEIGHT [UIScreen mainScreen].bounds.size.width //分享界面的宽
#define LETFDISTANCE 30 //左边距
#define TOPDISTANCE 25 //上边距
#define ICONHEIGHT 56  //icon 高
#define ICONWEIGHT 56  //icon 宽
#define ICONFONTHEIGHT 15 //icon与文字的距离
#define LINEHEIGHT 25  //行间距

@implementation JNShareSDKSevice

static CGFloat VIEWHEIGHT = 244;//分享界面的高

NSString * _customImageName;//自定义平台的imageName
NSString * _customTitleName;//自定义平台的titleName
NSArray *_customViewIconImageName;//自定义View里面的icon
NSArray *_customViewTitleName;//自定义View里面的title
static id _shareParams;
static SSDKShareStateChangedHandler _stateChangedHandler;
isCustomShare _message;
//对自定义的view或自定义平台界面赋值
+(void)setViewAndIcon:(BOOL)customView{
    if (customView) {//这里改后“+shareBtnClick:”方法里也要对应变动
        _customViewIconImageName = @[@"share_sns_icon_22.png",@"share_sns_icon_23.png",@"share_sns_icon_1.png",@"share_sns_icon_24.png",@"share005-.png"];
        _customViewTitleName =@[@"微信好友",@"朋友圈",@"微博",@"QQ好友",@"我的平台"];
    }else{
        _customImageName = @"share005-.png";
        _customTitleName = @"我的平台";
    }
}
//注册SDK
+ (void)registerShareSDK{
    [ShareSDK registerApp:@"1016f38601040"
          activePlatforms:@[@(SSDKPlatformTypeSinaWeibo),
                            @(SSDKPlatformSubTypeWechatSession),
                            @(SSDKPlatformTypeQQ)]
                 onImport:^(SSDKPlatformType platformType)
     {
         switch (platformType)
         {
             case SSDKPlatformTypeWechat:
                 [ShareSDKConnector connectWeChat:[WXApi class]];
                 break;
             case SSDKPlatformTypeQQ:
                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                 break;
             case SSDKPlatformTypeSinaWeibo:
                 [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                 break;
             default:
                 break;
         }
     }
          onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo){
              switch (platformType){
                  case SSDKPlatformTypeSinaWeibo:
                      [appInfo SSDKSetupSinaWeiboByAppKey:SinaWeibo_APP_KEY appSecret:SinaWeibo_APP_SECRET redirectUri:SinaWeibo_RedirectUri authType:SSDKAuthTypeBoth];
                      break;
                  case SSDKPlatformTypeWechat:
                      [appInfo SSDKSetupWeChatByAppId:WeChat_APP_ID appSecret:WeChat_APP_Secret];
                      break;
                  case SSDKPlatformTypeQQ:
                      [appInfo SSDKSetupQQByAppId:QQ_APP_ID appKey:QQ_APP_KEY authType:SSDKAuthTypeBoth];
                      break;
                  default:
                      break;
              }
          }];
}
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
#pragma mark - 分享
+ (void)shareAppParamsByText:(NSString*)text title:(NSString *)title images:(id)images url:(NSString*)url type:(SSDKContentType)type customView:(BOOL)customView isIpd:(id)sender onStateChanged:(SSDKShareStateChangedHandler)stateChangedHandler CustomShare:(isCustomShare)message{
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    
    [shareParams SSDKSetupShareParamsByText:text images:images url:[NSURL URLWithString:url] title:title type:type];
    
    //微博的分享url是拼到text后面的
    [shareParams SSDKSetupSinaWeiboShareParamsByText:[NSString stringWithFormat:@"%@%@",text,url] title:title image:images url:nil latitude:0.0 longitude:0.0 objectID:nil type:SSDKContentTypeAuto];
    
    if (customView) {//需要自定义分享界面
        _shareParams = shareParams;
        _stateChangedHandler = stateChangedHandler;
        _message = message;
        [[self class]setViewAndIcon:YES];
        [[self class] JNShareView];
    }
    else{
        //自定义分享平台（非必要）
        [[self class]setViewAndIcon:NO];
        NSMutableArray *activePlatforms = [NSMutableArray arrayWithArray:[ShareSDK activePlatforms]];
        SSUIShareActionSheetCustomItem *myItem = [SSUIShareActionSheetCustomItem itemWithIcon:[UIImage imageNamed:_customImageName]label:_customTitleName onClick:^{
            /**
             *自定义平台被点击时的回调方法
             *
             */
            message();
//            NSLog(@"----->自定义平台被点击");
            }];
        [activePlatforms addObject:myItem];
        NSArray *items = @[@(SSDKPlatformSubTypeWechatSession),@(SSDKPlatformSubTypeWechatTimeline),@(SSDKPlatformTypeSinaWeibo),@(SSDKPlatformSubTypeQQFriend),myItem];
        //到这里都是自定义分享平台方法，如果没有自定义平台，下面的items传入nil
        //这里如果是ipad需要把值传过来
        [ShareSDK showShareActionSheet:sender items:items shareParams:shareParams onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData,SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
            stateChangedHandler(state,userData,contentEntity,error);
        }];
    }
}

//用户自定义分享的View
+(void)JNShareView{
    VIEWHEIGHT = 244;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //这个View是背景阴影
    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    blackView.backgroundColor = [UIColor colorWithRed:0/255.f green:0/255.f blue:0/255.f alpha:0.85f];
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blackViewTap:)];
    [blackView addGestureRecognizer:tap];
    blackView.tag = 999999998;
    [window addSubview:blackView];
    
    UIView *shareView = [[UIView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height - VIEWHEIGHT, VIEWWEIGHT, VIEWHEIGHT)];
    shareView.tag = 999999999;
    shareView.backgroundColor = [UIColor whiteColor];
    [window addSubview:shareView];
    
//    //这个是分享Title,坐标需要自己设置，取消分享也是，都是button和label，使用的可以自己调
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
//    titleLabel.hidden = YES;
//    titleLabel.text = @"分享到";
//    titleLabel.textAlignment = NSTextAlignmentCenter;
//    titleLabel.backgroundColor = [UIColor clearColor];
//    [shareView addSubview:titleLabel];
//    //这个是取消分享按钮
//    UIButton *cancleBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
//    [cancleBtn setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
//    cancleBtn.hidden = YES;
//    cancleBtn.tag = 1000;
//    [cancleBtn addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
//    [shareView addSubview:cancleBtn];
    
    //定制View上的分享图标
    for (int i = 0; i < 5; i++) {
        CGFloat fontHeight = 12;//文字高度
        CGFloat iconX = LETFDISTANCE + i%4 * ((VIEWWEIGHT - 4 *ICONWEIGHT - 2 * LETFDISTANCE) / 3 + ICONWEIGHT);
        CGFloat iconY = TOPDISTANCE + i/4 * (ICONHEIGHT +ICONFONTHEIGHT + fontHeight + LINEHEIGHT);
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(iconX,iconY , ICONWEIGHT, ICONHEIGHT);
        button.tag = i + 1;
        [button setBackgroundColor:[UIColor clearColor]];
        [button setBackgroundImage:[UIImage imageNamed:_customViewIconImageName[i]] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [shareView addSubview:button];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(iconX-2 , iconY + ICONHEIGHT + ICONFONTHEIGHT, ICONWEIGHT + 4, fontHeight)];
        label.tag = 21+i;
        label.text = _customViewTitleName[i];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        [shareView addSubview:label];
    }
    
    //判断用户设备上是否安装qq或者微信
    [[self class] WXAppAndQQAppInstalled:shareView];
    
    //弹窗动画
    shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height, VIEWWEIGHT, VIEWHEIGHT);
    blackView.alpha = 0;
    [UIView animateWithDuration:0.35f animations:^{
        shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height - VIEWHEIGHT, VIEWWEIGHT, VIEWHEIGHT);
        blackView.alpha = 0.5;
    } completion:^(BOOL finished) {
        
    }];
}
+(void)shareBtnClick:(UIButton *)button{
    NSUInteger shareType;
    switch (button.tag) {
        case 1:shareType = SSDKPlatformSubTypeWechatSession;break;
        case 2:shareType = SSDKPlatformSubTypeWechatTimeline;break;
        case 3:shareType = SSDKPlatformTypeSinaWeibo;break;
        case 4:shareType = SSDKPlatformSubTypeQQFriend;break;
        case 5:{//自定义平台被点击
            _message();
            [[self class]blackViewTap:nil];
            return;
        };break;
        case 1000:[[self class]blackViewTap:button];break;
        default:
            break;
    }
    [[self class]blackViewTap:nil];
    //新浪微博有编辑界面，qq微信没有编辑界面，如有特殊要求可以自己再改变
    if (shareType != SSDKPlatformTypeSinaWeibo)  {
        //    无编辑界面
        [ShareSDK share:shareType parameters:_shareParams onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
            if (state == SSDKResponseStateFail) {
                //             NSLog(@"------->分享失败，原因：%@",error);
            }
            _stateChangedHandler(state,userData,contentEntity,error);
        }];
        
    }else{
        //有编辑界面
        [ShareSDK showShareEditor:shareType
               otherPlatformTypes:nil
                      shareParams:_shareParams
              onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end)
         {
             if (state == SSDKResponseStateFail) {
                 NSLog(@"------->分享失败，原因：%@",error);
             }
             _stateChangedHandler(state,userData,contentEntity,error);
         }];
    }
}
//取消分享或点击空白位置时
+(void)blackViewTap:(id)sender{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *shareView = [window viewWithTag:999999999];
    UIView *blackView = [window viewWithTag:999999998];
    shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height - VIEWHEIGHT, VIEWWEIGHT, VIEWHEIGHT);
    [UIView animateWithDuration:0.2f animations:^{
        shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height, VIEWWEIGHT, VIEWHEIGHT);
        blackView.alpha = 0;
    } completion:^(BOOL finished) {
        if (sender) {
            NSLog(@"---->取消了分享");
        }
        [shareView removeFromSuperview];
        [blackView removeFromSuperview];
    }];
}
//判断用户设备上是否安装qq或者微信
+(void)WXAppAndQQAppInstalled:(UIView *)shareView{
    if (![WXApi isWXAppInstalled]) {//没有安装微信
        VIEWHEIGHT =  133;
        [shareView viewWithTag:1].hidden = YES;
        [shareView viewWithTag:2].hidden = YES;
        [shareView viewWithTag:21].hidden = YES;
        [shareView viewWithTag:22].hidden = YES;
    }
    if (![QQApiInterface isQQInstalled]) {//没有安装qq
        VIEWHEIGHT =  133;
        [shareView viewWithTag:4].hidden = YES;
        [shareView viewWithTag:24].hidden = YES;
    }
    CGFloat fontHeight = 12;//文字高度
    int i = 0,j = 0;
    for (UIView *shareSub in [shareView subviews]) {
        CGFloat iconX = LETFDISTANCE + i%4 * ((VIEWWEIGHT - 4 *ICONWEIGHT - 2 * LETFDISTANCE) / 3 + ICONWEIGHT);
        CGFloat labelX = LETFDISTANCE + j%4 * ((VIEWWEIGHT - 4 *ICONWEIGHT - 2 * LETFDISTANCE) / 3 + ICONWEIGHT);
        CGFloat iconY = TOPDISTANCE + i/4 * (ICONHEIGHT +ICONFONTHEIGHT + fontHeight + LINEHEIGHT);
        CGFloat labelY = TOPDISTANCE + j/4 * (ICONHEIGHT +ICONFONTHEIGHT + fontHeight + LINEHEIGHT);

        if ([shareSub isKindOfClass:[UIButton class]] && !shareSub.hidden) {//这个是对button进行坐标重绘
            shareSub.frame = CGRectMake(iconX, iconY, ICONWEIGHT, ICONHEIGHT);
            i++;
        }
        if ([shareSub isKindOfClass:[UILabel class]] && !shareSub.hidden) {//这个是对label坐标进行重绘
            shareSub.frame = CGRectMake(labelX-2 , labelY + ICONHEIGHT + ICONFONTHEIGHT, ICONWEIGHT + 4, 12);
            j++;
        }
    }
    
    //这块是如果没有安装微信或qq分享界面会变窄，解开下面的代码别忘记把上面的VIEWWEIGHT注释也给解开
    shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height - VIEWHEIGHT, VIEWWEIGHT, VIEWHEIGHT);
}

//隐藏掉自定义的分向平台
+(void)hiddenCustomShare{
    VIEWHEIGHT =  133;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *shareView = [window viewWithTag:999999999];
    [shareView viewWithTag:5].hidden = YES;
    [shareView viewWithTag:25].hidden = YES;
    //这块代码是如果去掉了自定义平台这个会使shareView变窄，解开下面的代码别忘记把上面的VIEWWEIGHT注释也给解开
        shareView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - VIEWWEIGHT) / 2, [UIScreen mainScreen].bounds.size.height - VIEWHEIGHT, VIEWWEIGHT, VIEWHEIGHT);
}
#pragma mark - 登录
+ (void)getUserInfo:(SSDKPlatformType)platformType
     onStateChanged:(SSDKGetUserStateChangedHandler)stateChangedHandler{
    [ShareSDK getUserInfo:platformType
           onStateChanged:^(SSDKResponseState state, SSDKUser *user, NSError *error)
     {
         stateChangedHandler(state,user,error);
     }];
}
#pragma mark - 注销
+ (void)thirdLogout:(SSDKPlatformType)loginType{
    [ShareSDK cancelAuthorize:loginType];
}

@end
