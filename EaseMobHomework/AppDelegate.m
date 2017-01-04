#import "AppDelegate.h"
#import "EaseMob.h" //注册 SDK 需要
#import "LoginViewController.h"
#import "LNNavigationController.h"
#import "ConversationsController.h"
#import "ContactsController.h"
#import "ProfileController.h"

@interface AppDelegate ()<EMChatManagerDelegate>

/** 用户注销需要它来回到登录界面 */
@property (nonatomic, strong) LNNavigationController *loginNC;

@end



@implementation AppDelegate

//生成【登录】页面，注册环信，自动登录成功调用 loginSuccess 方法
- (BOOL)application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
    self.window                 = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    LoginViewController *loginVC    = [LoginViewController new];
    LNNavigationController *loginNC = [[LNNavigationController alloc]
                                       initWithRootViewController: loginVC];
    self.loginNC                    = loginNC;
    
    self.window.rootViewController  = loginNC;
    
    [self.window makeKeyAndVisible];
    
    //设置导航条
    [[UINavigationBar appearance] setBackgroundImage: [UIImage imageNamed: @"barBackground"]
                                       forBarMetrics: UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:
                                        @{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    //自动登录
    [[EaseMob sharedInstance] application: application didFinishLaunchingWithOptions: launchOptions];
    
    //注册 SDK
    EMError *error = [[EaseMob sharedInstance] registerSDKWithAppKey: @"1143161023178401#imlearnexample"
                                                        apnsCertName: nil
                                                         otherConfig: @{kSDKConfigEnableConsoleLogger: @NO}];
    if (!error) {
        
        //进行自动登录
        if ([[EaseMob sharedInstance].chatManager isAutoLoginEnabled]) {
           
             self.you = [[EaseMob sharedInstance].chatManager loginInfo][@"username"];
            [self loginSuccess];
        }
    }

    //添加环信代理, 这里用于监视自动登录的进展
    [[EaseMob sharedInstance].chatManager addDelegate: self delegateQueue: nil];
    
    return YES;
}


- (void)applicationWillResignActive: (UIApplication *)application {

}

//App 进入后台
- (void)applicationDidEnterBackground: (UIApplication *)application {
    [[EaseMob sharedInstance] applicationDidEnterBackground: application];
}

//APP 将要从后台返回
- (void)applicationWillEnterForeground: (UIApplication *)application {
    [[EaseMob sharedInstance] applicationWillEnterForeground: application];
}


- (void)applicationDidBecomeActive: (UIApplication *)application {
    
}

//申请处理时间
- (void)applicationWillTerminate: (UIApplication *)application {
    [[EaseMob sharedInstance] applicationWillTerminate: application];
}

#pragma mark 添加的方法
//登录成功后, 生成 tabBarController, 包含三个 Tab:会话, 联系人, 个人设置, 并先跳转到会话 tab
- (void)loginSuccess
{
    UITabBarController *tabBarController    = [UITabBarController new];

    ConversationsController *conversationsC = [ConversationsController new];
    LNNavigationController *conversationNC  = [[LNNavigationController alloc]
                                               initWithRootViewController: conversationsC];
    conversationsC.title                    = @"会话界面";
    conversationsC.tabBarItem.image         = [UIImage imageNamed: @"conversations_de_60"];
    conversationsC.tabBarItem.selectedImage = [UIImage imageNamed: @"conversations_ac_60"];

    ContactsController *contactsC           = [ContactsController new];
    LNNavigationController *contactNC       = [[LNNavigationController alloc]
                                               initWithRootViewController: contactsC];

    contactsC.title                         = @"好友界面";
    contactsC.tabBarItem.image              = [UIImage imageNamed: @"contacts_de_60"];
    contactsC.tabBarItem.selectedImage      = [UIImage imageNamed: @"contacts_ac_60"];

    ProfileController *profileC             = [ProfileController new];
    LNNavigationController *profileNC       = [[LNNavigationController alloc]
                                               initWithRootViewController: profileC];
    profileC.title                          = @"个人设置";
    profileC.tabBarItem.image               = [UIImage imageNamed: @"profile_de_60"];
    profileC.tabBarItem.selectedImage       = [UIImage imageNamed: @"profile_ac_60"];

    tabBarController.viewControllers        = @[conversationNC,contactNC,profileNC];

    self.window.rootViewController          = tabBarController;
}

- (void)logoffSuccess {
    
    self.window.rootViewController = self.loginNC;
    
    [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled: NO];
}

- (void)didAutoLoginWithInfo: (NSDictionary *)loginInfo error: (EMError *)error {

    //NSLog(!error? @"自动登录成功":@"自动登录失败");
}

@end
