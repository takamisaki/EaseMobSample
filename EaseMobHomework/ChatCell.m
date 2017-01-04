#import "ChatCell.h"
#import "EMCDDeviceManager.h"

@interface ChatCell ()

/** 气泡消息(其实是个按钮) */
@property (nonatomic, strong) LNButton *messageButton;
/** cell 上面的时间戳 */
@property (nonatomic, strong) UILabel  *timeLabel;
/** 头像 */
@property (nonatomic, strong) LNButton *avatar;
/** cell 的高度 */
@property (nonatomic, assign) CGFloat  rowHeight;

@end

@implementation ChatCell

- (instancetype)initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString*)reuseIdentifier
{
    if (self = [super initWithStyle: style reuseIdentifier: reuseIdentifier])
    {
        //添加控件
        //1. 添加时间记录
        UILabel *timeLabel      = [UILabel new];
        timeLabel.textAlignment = NSTextAlignmentCenter;
        timeLabel.textColor     = [UIColor lightGrayColor];
        timeLabel.font = [UIFont systemFontOfSize:10];
        
        [self.contentView addSubview: timeLabel];
        
        //2. 添加聊天消息
        LNButton *messageButton = [LNButton createButton];
        [messageButton addTarget: self action: @selector(messageButtonClicked:)
                             forControlEvents: UIControlEventTouchUpInside];
        
        [messageButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
         messageButton.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
         messageButton.titleLabel.numberOfLines = 0;
        
        [self.contentView addSubview: messageButton];
        
        //3. 添加头像
        LNButton *avatar = [LNButton createButton];
        [avatar setBackgroundImage: [UIImage imageNamed: @"avatar"] forState: UIControlStateNormal];
        [self.contentView addSubview: avatar];
        
        //保存到属性, 以备调用
        self.messageButton = messageButton;
        self.timeLabel     = timeLabel;
        self.avatar        = avatar;
    }
    return self;
}


//因为无法直接设置气泡消息的大小, 所以需要获取消息的内容先
- (void)setMessage: (EMMessage *)message
{
    _message                       = message;
    CGFloat padding                = 5;
    CGFloat fontSize               = 15.0;
    UIFont  *labelFont             = [UIFont systemFontOfSize: fontSize];
    _messageButton.titleLabel.font = labelFont;
    
    //设置时间的 frame
    CGFloat timeLabelX = 0;
    CGFloat timeLabelY = 0;
    CGFloat timeLableW = SCREEN_WIDTH;
    CGFloat timeLabelH = 15;
    
    _timeLabel.frame = CGRectMake(timeLabelX, timeLabelY, timeLableW, timeLabelH);
    
    //显示时间的内容 (需要转换格式)
    double time = message.timestamp;
    if (message.timestamp > 140000000000) {
        time = message.timestamp / 1000;
    }
    NSDate *date               = [NSDate dateWithTimeIntervalSince1970: time];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat       = @"yyyy 年 MM 月 dd 日 HH:mm:ss";
    NSString *dateString       = [formatter stringFromDate: date];
    _timeLabel.text            = dateString;
    
    //判断消息类型, 文本, 图片, 音频
    id body = message.messageBodies[0];
    
    //如果是文本消息
    if ([body isKindOfClass: [EMTextMessageBody class]]) {
        
        EMTextMessageBody *textBody      = body;
        CGFloat inset                    = 10;
        
        //计算文本 size
        CGSize maxSize  = CGSizeMake(SCREEN_WIDTH/2, MAXFLOAT);
        CGSize textSize = [textBody.text boundingRectWithSize: maxSize
                                                      options: NSStringDrawingUsesLineFragmentOrigin
                                                   attributes: @{NSFontAttributeName:labelFont}
                                                      context: nil].size;
        //根据消息来源设置头像的位置
        NSString *you = [[EaseMob sharedInstance].chatManager loginInfo][@"username"];
        
        //如果是你发的消息, 头像和消息都需要放在右侧
        if ([message.from isEqualToString: you])
        {
            _messageButton.contentEdgeInsets = UIEdgeInsetsMake(inset*2, inset-3, inset-5, inset+3);

            //头像位置
            CGFloat avatarW = 40;
            CGFloat avatarH = avatarW;
            CGFloat avatarX = SCREEN_WIDTH - padding - avatarW;
            CGFloat avatarY = timeLabelH;
            _avatar.frame   = CGRectMake(avatarX,avatarY,avatarW,avatarH);

            //消息位置
            CGFloat messageButtonW = textSize.width + inset*2;
            CGFloat messageButtonH = textSize.height - 5;
            CGFloat messageButtonX = SCREEN_WIDTH - padding - avatarW - messageButtonW;
            CGFloat messageButtonY = avatarY;
            _messageButton.frame   = CGRectMake(messageButtonX, messageButtonY,
                                                messageButtonW, messageButtonH);
            
            //气泡背景
            UIImage *bubbleImage =[UIImage imageNamed: @"chat_sender_bg"];
            bubbleImage          =[bubbleImage stretchableImageWithLeftCapWidth:10 topCapHeight:30];

            [_messageButton setBackgroundImage: bubbleImage forState: UIControlStateNormal];
        }
        
        //如果是你收的消息, 头像和消息都需要放在左侧
        else
        {
            _messageButton.contentEdgeInsets = UIEdgeInsetsMake(inset, inset+3, inset, inset-3);
            
            //头像位置
            CGFloat avatarW = 40;
            CGFloat avatarH = avatarW;
            CGFloat avatarX = padding;
            CGFloat avatarY = timeLabelH;
            _avatar.frame   = CGRectMake(avatarX,avatarY,avatarW,avatarH);

            //消息位置
            CGFloat messageButtonW = textSize.width + inset*2;
            CGFloat messageButtonH = textSize.height + inset*2;
            CGFloat messageButtonX = padding + avatarW;
            CGFloat messageButtonY = avatarY;
            _messageButton.frame   = CGRectMake(messageButtonX, messageButtonY,
                                                messageButtonW, messageButtonH);

            UIImage *bubbleImage =[UIImage imageNamed: @"chat_receiver_bg"];
            bubbleImage          =[bubbleImage stretchableImageWithLeftCapWidth:30 topCapHeight:30];

            [_messageButton setBackgroundImage: bubbleImage forState: UIControlStateNormal];
        }
        
        //显示消息的文本内容
        [_messageButton setTitle: textBody.text forState: UIControlStateNormal];
    }
    
    //如果是语音消息
    else if([body isKindOfClass: [EMVoiceMessageBody class]])
    {
        
        EMVoiceMessageBody *voiceBody = body;
        
        [_messageButton setImage: [UIImage imageNamed: @"recorder"]
                        forState: UIControlStateNormal];
        [_messageButton setTitle: [NSString stringWithFormat: @"%ld秒",voiceBody.duration]
                        forState: UIControlStateNormal];
        
        NSString *you = [[EaseMob sharedInstance].chatManager loginInfo][@"username"];
        
        if ([message.from isEqualToString: you])
        {
            CGFloat avatarW = 40;
            CGFloat avatarH = avatarW;
            CGFloat avatarX = SCREEN_WIDTH - padding - avatarW;
            CGFloat avatarY = timeLabelH;
            _avatar.frame   = CGRectMake(avatarX,avatarY,avatarW,avatarH);
            
            CGFloat messageButtonW = 100;
            CGFloat messageButtonH = 40;
            CGFloat messageButtonX = SCREEN_WIDTH - padding - avatarW - messageButtonW;
            CGFloat messageButtonY = timeLabelH;
            _messageButton.frame   = CGRectMake(messageButtonX,messageButtonY,
                                                messageButtonW,messageButtonH);
            
        }else{
            
            CGFloat avatarW = 40;
            CGFloat avatarH = avatarW;
            CGFloat avatarX = padding;
            CGFloat avatarY = timeLabelH;
            _avatar.frame   = CGRectMake(avatarX,avatarY,avatarW,avatarH);
            
            CGFloat messageButtonW = 100;
            CGFloat messageButtonH = 40;
            CGFloat messageButtonX = padding + avatarW;
            CGFloat messageButtonY = timeLabelH;
            _messageButton.frame   = CGRectMake(messageButtonX,messageButtonY,
                                                messageButtonW,messageButtonH);
        }
    }
}

//点击聊天记录里的语音图标, 播放录音
- (void)messageButtonClicked: (LNButton *)button
{
    id body = self.message.messageBodies[0];
    
    
    if ([body isKindOfClass: [EMVoiceMessageBody class]])
    {
        EMVoiceMessageBody *voiceBody = body;
        NSString *path                = voiceBody.localPath;
        
        //如果本地没有该音频, 就从服务器取
        if (![[NSFileManager defaultManager] fileExistsAtPath: path]) {
            path = voiceBody.remotePath;
        }
     
        [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath: path completion: ^(NSError *error)
        {
            [MBProgressHUD showTextHUD: @"录音播放完毕" onView: self.superview];
        }];
    }
}


- (void)setSelected: (BOOL)selected {
    
    [super setSelected: selected];
}

@end
