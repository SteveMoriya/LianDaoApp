//
//  ViewController.m
//  smartLianYun
//
//  Created by Steve on 03/08/2017.
//  Copyright © 2017 jianbuwang. All rights reserved.
//

#define kDEVICEWIDTH  [UIScreen mainScreen].bounds.size.width
#define kDEVICEHEIGHT  [UIScreen mainScreen].bounds.size.height

#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import "MBProgressHUD.h"

#import "ViewController.h"
#import "JPUSHService.h"
//#import "LocationViewController.h"

#import "JXMapNavigationView.h"


@interface ViewController ()<WKNavigationDelegate,WKScriptMessageHandler,UIActionSheetDelegate>

@property (nonatomic, strong) WKWebView                *webView;
@property (nonatomic, strong) UIActivityIndicatorView  *indicatorView;
@property (nonatomic, strong) AppDelegate              *appdelegate;
@property (nonatomic, strong) JXMapNavigationView      *mapNavigationView;


@end

@implementation ViewController

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _indicatorView.center = self.view.center;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self.view addSubview:_indicatorView];
    }
    return _indicatorView;
}

- (JXMapNavigationView *)mapNavigationView{
    if (_mapNavigationView == nil) {
        _mapNavigationView = [[JXMapNavigationView alloc]init];
    }
    return _mapNavigationView;
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    //设置监听
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"app"];
    // 设置偏好设置
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userContentController;
    //解决音乐播放问题
    config.allowsInlineMediaPlayback = YES;
    config.mediaPlaybackRequiresUserAction = false;
    //    config.preferences = [[WKPreferences alloc] init]; // 默认为0
    //    config.preferences.minimumFontSize = 10; // 默认认为YES
    //    config.preferences.javaScriptEnabled = YES;
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0,  kDEVICEWIDTH, kDEVICEHEIGHT ) configuration:config];
    //    [_webView sizeToFit];
    
    //设置显示内容，解决顶部状态栏问题
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _webView.scrollView.bounces = YES;
    _webView.navigationDelegate = self;
    _webView.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_webView];
    
    NSString* urlString;
    
    //页面加载逻辑
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
    if (userid) {
//        urlString = [NSString stringWithFormat:@"http://ldjd.eygou.com/weixin/login.jsp?visitType=1&userid=%@",userid];
        urlString = [NSString stringWithFormat:@"http://ldjd.eygou.com/weixin/appIndex.do?visitType=1&userid=%@",userid];
    }
    else {
        urlString = [NSString stringWithFormat:@"http://ldjd.eygou.com/weixin/appIndex.do?visitType=1"];
    }
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    
    
}

#pragma mark-- 加载wkwebview 用于推送数据
- (void)loadWebView:(NSString *)urlString
{
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}


#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
//    NSLog(@"message.name %@",message.name);
//    NSLog(@"message.body %@",message.body);
    
    NSDictionary *dic = message.body;
    NSLog(@"dic %@",dic);
    
//    1、登录成功绑定id
//    var dict = {"function":"gitUserID","content":data.userId};
//    window.webkit.messageHandlers.app.postMessage(dict);
//    2、退出登录
//    var dict = {"function":"gitUserID","content":"null"};
//    window.webkit.messageHandlers.app.postMessage(dict);

    
    
    //获取id方法
    if ([dic[@"function"] isEqualToString:@"gitUserID"] ) {
        
        NSString * userID = [dic objectForKey:@"content"];
        NSString * userIDString = [NSString stringWithFormat:@"%@",userID];
        
        if ([userIDString isEqualToString:@"null"] ) {
            
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"userid"];
        } else {
            
             [[NSUserDefaults standardUserDefaults] setObject:userIDString forKey:@"userid"];
            
            //设置别名和tag
//            [JPUSHService setTags:[NSSet setWithObject:userIDString] alias:userIDString fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
//
//            }];
            
            [JPUSHService setAlias:userIDString completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
                
            } seq:0];
            
        }
        
    }
    
    //打开外部链接方法
    else if ([dic[@"function"] isEqualToString:@"openUrl"] ) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dic[@"content"]]];
        
    } //打开外部链接方法
    else if ([dic[@"function"] isEqualToString:@"addressNavigation"] ) {
//        [self actionSheet];
        
        NSDictionary *addressDic = [dic objectForKey:@"content"];
        NSString * address = [addressDic objectForKey:@"address"];
        NSString * latitude = [addressDic objectForKey:@"latitude"];
        NSString * longitude = [addressDic objectForKey:@"longitude"];
        
        [self.mapNavigationView showMapNavigationViewWithtargetLatitude:latitude.doubleValue targetLongitute:longitude.doubleValue toName:address];
        
        [self.view addSubview:_mapNavigationView];
    }
    
}

//- (void) actionSheet  {
//
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//
//    //这个判断其实是不需要的
//    if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"http://maps.apple.com/"]]) {
//        UIAlertAction *action = [UIAlertAction actionWithTitle:@"苹果地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            NSLog(@"执行跳转");
//
//            LocationViewController* vc = [[LocationViewController alloc] init];
//            [self.navigationController pushViewController:vc animated:YES];
//
//        }];
//        [alert addAction:action];
//    }
//
//
//    UIAlertAction *action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
//    [alert addAction:action];
//
//    [self presentViewController:alert animated:YES completion:^{
//    }];
//}


//如果不实现这个代理方法,默认会屏蔽掉打电话等url

- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}


/// 2 页面开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"1");
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.detailsLabel.text = nil;
    [hud hideAnimated:YES afterDelay:5];
    
    //添加检查网络方法
    NetworkStatus status = _appdelegate.reachability.currentReachabilityStatus;
    
    [self showHUDWithReachabilityStatus:status];
    
    
    //关于拨打电话时的调用问题
    NSString *path= [webView.URL absoluteString];
    NSString * newPath = [path lowercaseString];
    
    if ([newPath hasPrefix:@"sms:"] || [newPath hasPrefix:@"tel:"]) {
        
        UIApplication * app = [UIApplication sharedApplication];
        if ([app canOpenURL:[NSURL URLWithString:newPath]]) {
            [app openURL:[NSURL URLWithString:newPath]];
        }
        
        [self.indicatorView stopAnimating];
        
        return;
    }
}

/// 4 开始获取到网页内容时返回
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"2");
}

/// 5 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"3");
    //    [self.indicatorView stopAnimating];
    [MBProgressHUD hideHUDForView:self.view animated:true];
    
}


/// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"4");
    [MBProgressHUD hideHUDForView:self.view animated:true];
}

#pragma mark-- 执行网络判断
- (void)showHUDWithReachabilityStatus:(NetworkStatus)status
{
    if (status == NotReachable) {
        
        [MBProgressHUD hideHUDForView:self.view animated:true];
        
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:nil message:@"网络已断开，请检查网络！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alterView show];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
