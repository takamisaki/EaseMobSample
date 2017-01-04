#import <UIKit/UIKit.h>
#import "LNScrollView.h"
#import "AppDelegate.h"

@interface LNViewController : UIViewController

@property (nonatomic, weak  ) LNScrollView *scrollView; //因为要被外界访问
@property (nonatomic, strong) AppDelegate  *appDelegate;

@end
