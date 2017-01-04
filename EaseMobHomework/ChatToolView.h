#import <UIKit/UIKit.h>
@class ChatToolView;

/** 录音时三种按钮的枚举 */
typedef enum {
    ChatToolViewVoiceButtonStart,   //开始录音
    ChatToolViewVoiceButtonSend,    //发送录音
    ChatToolViewVoiceButtonCancel   //取消录音
} ChatToolViewVoiceButtonType;

/** 定义录音 block */
typedef void (^ChatToolViewVoiceBlock) (ChatToolViewVoiceButtonType voiceButtonType);
/** 定义文字 block */
typedef void (^ChatToolViewTextBlock) (UITextView *textView);

/** 发送录音的代理 */
@protocol ChatToolViewDelegate <NSObject>
- (void)ChatToolViewWithButtonType: (ChatToolViewVoiceButtonType)buttonType;
@end


@interface ChatToolView : UIView

/** 录音按钮点击时回调 */
@property (nonatomic, copy) ChatToolViewVoiceBlock voiceBlock;
/** 文本按钮点击时回调 */
@property (nonatomic, copy) ChatToolViewTextBlock textBlock;
/** 录音处理的代理 */
@property (nonatomic, weak) id<ChatToolViewDelegate> delegate;

@end
