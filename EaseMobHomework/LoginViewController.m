#import "LoginViewController.h"
#import "AppDelegate.h"

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title              = @"登录";
    UIColor *backgroundBlue = [UIColor colorWithPatternImage: [UIImage imageNamed: @"barBackground"]];

    CGFloat paddingH               = SCREEN_HEIGHT/4;
    CGFloat paddingW               = SCREEN_WIDTH /5;
    
    CGRect userLabelRect           = CGRectMake(paddingW, paddingH, paddingW, paddingH/4);
    UILabel *userLabel             = [[UILabel alloc] initWithFrame: userLabelRect];
    
    CGRect passwordLabelRect       = CGRectMake(paddingW, userLabel.bottom+2,
                                                userLabel.width,userLabel.height);
    UILabel *passwordLabel         = [[UILabel alloc] initWithFrame: passwordLabelRect];
    
    CGRect userTextFieldRect       = CGRectMake(userLabel.right+1,userLabel.top,
                                                userLabel.width*2,userLabel.height);
    UITextField *userTextField     = [[UITextField alloc] initWithFrame: userTextFieldRect];
    
    CGRect passwordTextFieldRect   = CGRectMake(userTextField.left,userTextField.bottom+2,
                                                userTextField.width,userTextField.height);
    UITextField *passwordTextField = [[UITextField alloc] initWithFrame: passwordTextFieldRect];
    
    
    userTextField.borderStyle              = UITextBorderStyleRoundedRect;
    passwordTextField.borderStyle          = UITextBorderStyleRoundedRect;
    passwordTextField.secureTextEntry      = YES;
    userTextField.clearsOnBeginEditing     = YES;
    passwordTextField.clearsOnBeginEditing = YES;
    userLabel.textAlignment                = NSTextAlignmentCenter;
    passwordLabel.textAlignment            = NSTextAlignmentCenter;
    userLabel.textColor                    = backgroundBlue;
    passwordLabel.textColor                = backgroundBlue;
    userLabel.text                         = @"用户名";
    passwordLabel.text                     = @"密    码";

    
    //创建登录按钮
    LNButton *loginButton                  = [LNButton createButton];
    
    loginButton.frame = CGRectMake(passwordTextField.left,passwordTextField.bottom + 2,
                                   passwordTextField.width,passwordTextField.height);
    
    [loginButton setTitle: @"登录" forState: UIControlStateNormal];
    
    [loginButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    
    [loginButton setBackgroundImage: [UIImage imageNamed: @"barBackground"]
                           forState: UIControlStateNormal];
    
     loginButton.block = ^(LNButton *button)
    {
        [userTextField endEditing: YES];
        [passwordTextField endEditing: YES];
        
        if (userTextField.text.length == 0) {
            [MBProgressHUD showTextHUD: @"请输入用户名" onView: self.view];
            return;
        }
        if (passwordTextField.text.length == 0) {
            [MBProgressHUD showTextHUD: @"请输入密码" onView: self.view];
            return;
        }
        
        //异步登录
        [[EaseMob sharedInstance].chatManager
         asyncLoginWithUsername: userTextField.text
                       password: passwordTextField.text
                     completion: ^(NSDictionary *loginInfo, EMError *error)
        {
          if (!error) {
               self.appDelegate.you = [[EaseMob sharedInstance].chatManager loginInfo][@"username"];
              [self.appDelegate loginSuccess];
              [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled: YES];
          
          }else{
              [MBProgressHUD showTextHUD: @"用户登录失败" onView: self.view];
          }
        } onQueue: nil];
    };
    
    
    //创建注册按钮
    LNButton *registerButton = [LNButton createButton];
    registerButton.frame = CGRectMake(loginButton.left, loginButton.bottom+2,
                                      loginButton.width, loginButton.height);
    [registerButton setTitle: @"注册" forState: UIControlStateNormal];
    [registerButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [registerButton setBackgroundImage: [UIImage imageNamed: @"barBackground"]
                              forState: UIControlStateNormal];
    
    registerButton.block = ^(LNButton *button)
    {
        [userTextField     endEditing: YES];
        [passwordTextField endEditing: YES];
        
        if (userTextField.text.length == 0) {
            [MBProgressHUD showTextHUD: @"请输入用户名" onView: self.view];
            return;
        }
        if (passwordTextField.text.length == 0) {
            [MBProgressHUD showTextHUD: @"请输入密码" onView: self.view];
            return;
        }
        
        //异步注册
        [[EaseMob sharedInstance].chatManager
         asyncRegisterNewAccount: userTextField.text
                        password: passwordTextField.text
                  withCompletion: ^(NSString *username, NSString *password, EMError *error)
        {
          [MBProgressHUD showTextHUD: !error? @"注册成功" : @"注册失败" onView: self.view];
        } onQueue: nil];
    };

    [self.scrollView addSubview: userLabel];
    [self.scrollView addSubview: passwordLabel];
    [self.scrollView addSubview: userTextField];
    [self.scrollView addSubview: passwordTextField];
    [self.scrollView addSubview: loginButton];
    [self.scrollView addSubview: registerButton];
}

@end
