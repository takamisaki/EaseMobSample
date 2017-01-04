#import "ChatToolView.h"
#import "QuartzCore/QuartzCore.h"

@interface ChatToolView ()<UITextViewDelegate>

/** 语音按钮 */
@property (nonatomic, strong) LNButton *voiceButton;
/** 文本输入框 */
@property (nonatomic, strong) UITextView *textView;
/** 录音按钮 */
@property (nonatomic, strong) LNButton *recordButton;

@end



@implementation ChatToolView

- (instancetype)initWithFrame: (CGRect)frame {
    
    if (self = [super initWithFrame: frame])
    {
        UIImage *backgroundPic  = [UIImage imageNamed: @"barBackground"];
        UIColor *backgroundBlue = [UIColor colorWithPatternImage: backgroundPic];
        self.backgroundColor    = [UIColor whiteColor];

        //添加语音按钮
        LNButton *voiceButton   = [LNButton createButton];
        
        [voiceButton setBackgroundImage: [UIImage imageNamed: @"chatBar_record"]
                               forState: UIControlStateNormal];
        
        [self addSubview: voiceButton];
        
        //添加文本输入框
        UITextView *textView       = [UITextView new];
        textView.layer.borderWidth = 1;
        textView.layer.borderColor = backgroundBlue.CGColor;
        textView.returnKeyType     = UIReturnKeyDone;
        textView.delegate          = self;
        
        [self addSubview: textView];
        
        //添加录音按钮
        LNButton *recordButton = [LNButton createButton];
        [recordButton setBackgroundColor: backgroundBlue];
        [recordButton setTitle: @"按住开始录音" forState: UIControlStateNormal];
        [recordButton setTitle: @"松开发送录音" forState: UIControlStateHighlighted];
        [recordButton setHidden: YES];
        
        [recordButton addTarget: self action: @selector(startRecord:)
                            forControlEvents: UIControlEventTouchDown];
        
        [recordButton addTarget: self action: @selector(sendRecord:)
                            forControlEvents: UIControlEventTouchUpInside];
        
        [recordButton addTarget: self action: @selector(cancelRecord:)
                            forControlEvents:UIControlEventTouchUpOutside];
        
        [self addSubview: recordButton];
        
        self.voiceButton  = voiceButton;
        self.recordButton = recordButton;
        self.textView     = textView;
        
        //点击语音按钮, 输入框和录音按钮切换, 语音按钮图标切换为键盘图标
        voiceButton.block = ^(LNButton *button)
        {
            textView.hidden     = recordButton.hidden;
            recordButton.hidden = !textView.hidden;
            
            UIImage *backgroundImage = [UIImage imageNamed:
                                        textView.hidden? @"chatBar_keyboard" : @"chatBar_record"];
            
            [voiceButton setBackgroundImage: backgroundImage forState: UIControlStateNormal];
        };
    }
    return self;
}

//布局子控件
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.voiceButton .frame = CGRectMake(5, 5, 30, 30);
    self.textView    .frame = CGRectMake(40, 5, SCREEN_WIDTH - 50, 30);
    self.recordButton.frame = self.textView.frame;
}


#pragma mark 录音按钮的三种事件

- (void)startRecord: (LNButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector: @selector(ChatToolViewWithButtonType:)])
    {
       [self.delegate ChatToolViewWithButtonType: ChatToolViewVoiceButtonStart];
    }
}

- (void)sendRecord: (LNButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector: @selector(ChatToolViewWithButtonType:)])
    {
       [self.delegate ChatToolViewWithButtonType: ChatToolViewVoiceButtonSend];
    }
}

- (void)cancelRecord: (LNButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector: @selector(ChatToolViewWithButtonType:)])
    {
       [self.delegate ChatToolViewWithButtonType: ChatToolViewVoiceButtonCancel];
    }
}


#pragma mark TextViewDelegate Methods
//如果软键盘输入了 done 键就发送消息, 同时收起软键盘
- (void)textViewDidChange: (UITextView *)textView
{
    if (textView.text.length == 0) {
        return;
    }
    
    if ([textView.text hasSuffix: @"\n"]) {
        if (self.textBlock) {
            self.textBlock(textView);
        }
        [textView resignFirstResponder];
    }
}

@end
