#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

/** 当前登录的用户 */
@property (nonatomic, copy  ) NSString *you;

/** 用户登录成功后调用 */
- (void)loginSuccess;

/** 用户注销成功后调用 */
- (void)logoffSuccess;

@end

