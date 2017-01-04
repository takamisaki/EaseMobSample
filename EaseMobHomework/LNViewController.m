#import "LNViewController.h"

@implementation LNViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    LNScrollView *scrollView = [LNScrollView new];
    scrollView.frame         = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64);
    self.scrollView          = scrollView;
    
    [self.view addSubview: scrollView];

    AppDelegate *app         = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.appDelegate         = app;
}

@end
