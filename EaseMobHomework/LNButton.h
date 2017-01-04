#import <UIKit/UIKit.h>
@class LNButton;


typedef void(^LNButtonClickBlock)(LNButton *button);

@interface LNButton : UIButton

/** 按钮点击触发的 Block */
@property (nonatomic, copy) LNButtonClickBlock block;
/** 工厂方法生成按钮 */
+ (instancetype)createButton;

@end
