#import "ProfileController.h"

@implementation ProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat paddingH = SCREEN_HEIGHT/4;
    CGFloat paddingW = SCREEN_WIDTH /5;
    
    UIImage *picImage           = [UIImage imageNamed: @"barBackground"];
    UIColor *backgroundBlue     = [UIColor colorWithPatternImage: picImage];

    //创建显示当前用户名字的 label
    CGRect  yourNameLabelRect   = CGRectMake(paddingW, paddingH, paddingW*3, paddingH/4);
    UILabel *yourNameLabel      = [[UILabel alloc] initWithFrame: yourNameLabelRect];
    yourNameLabel.text          = [NSString stringWithFormat:@"当前用户是: %@", self.appDelegate.you];
    yourNameLabel.textColor     = backgroundBlue;
    yourNameLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.scrollView addSubview: yourNameLabel];

    //创建注销功能的 button
    LNButton *logoffButton = [LNButton createButton];
    logoffButton.frame     = CGRectMake(paddingW, yourNameLabel.bottom+5,
                                        yourNameLabel.width, yourNameLabel.height);
    [logoffButton setTitle: @"注销" forState: UIControlStateNormal];
    [logoffButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [logoffButton setBackgroundImage: [UIImage imageNamed:@"barBackground"]
                            forState: UIControlStateNormal];
    
    logoffButton.block = ^(LNButton *button)
    {
        //异步注销
        [[EaseMob sharedInstance].chatManager
         asyncLogoffWithUnbindDeviceToken: YES
            completion: ^(NSDictionary *info, EMError *error)
        {
                if (!error) {
                    [self.appDelegate logoffSuccess];
                }else{
                    [MBProgressHUD showTextHUD: @"注销失败" onView: self.scrollView];
                }
             
        } onQueue: nil];
    };
    
    [self.scrollView addSubview: logoffButton];
}

@end
