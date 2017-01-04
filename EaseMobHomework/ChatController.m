#import "ChatController.h"
#import "ChatCell.h"
#import "ChatToolView.h"
#import "EMCDDeviceManager.h" //发送语音消息用

@interface ChatController ()
<UITableViewDelegate, UITableViewDataSource, ChatToolViewDelegate,
EMChatManagerDelegate, UIScrollViewDelegate, IEMChatProgressDelegate>

/** 当前的聊天记录数组(可变的) */
@property (nonatomic, strong) NSMutableArray *chatRecordArray;
/** 聊天记录呈现的 TableView */
@property (nonatomic, weak  ) UITableView    *chatTableView;

@end



@implementation ChatController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title         = self.buddy.username; //在 NavigationBar 上显示对方名字
    
    //创建聊天记录的 TableView
    CGFloat chatTableViewW        = SCREEN_WIDTH;
    CGFloat chatTableViewH        = SCREEN_HEIGHT-60-self.navigationController.navigationBar.height;
    CGRect chatTableViewRect      = CGRectMake(0, 0, chatTableViewW, chatTableViewH);
    UITableView *chatTableView    = [[UITableView alloc] initWithFrame: chatTableViewRect
                                                                 style: UITableViewStylePlain];
    chatTableView.delegate        = self;
    chatTableView.dataSource      = self;
    chatTableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.chatTableView            = chatTableView;
    [self.scrollView addSubview: chatTableView];
    
    //创建聊天工具(发送语音, 输入框等) view, 设置代理为了传递录制语音时不同的按钮 type
    ChatToolView *toolView = [ChatToolView new];
    toolView.frame         = CGRectMake(0, chatTableView.bottom, chatTableView.width, 40);
    toolView.delegate      = self;
    toolView.textBlock     = ^(UITextView *textView)
    {
        //发送消息
        //1. 生成消息
        EMChatText *text            = [[EMChatText alloc] initWithText: textView.text];
        EMTextMessageBody *textBody = [[EMTextMessageBody alloc] initWithChatObject: text];
        NSString *receiver          = self.buddy.username;
        EMMessage *message          = [[EMMessage alloc] initWithReceiver: receiver
                                                                   bodies: @[textBody]];
        
        //2. 异步发送: 发送后更新聊天记录数组和 tableView, tableView 滚到最后一行, 输入框清空
        [[EaseMob sharedInstance].chatManager
         asyncSendMessage: message
                 progress: self
                  prepare: ^(EMMessage *message, EMError *error) { } onQueue: nil
               completion: ^(EMMessage *message, EMError *error)
                {
                    [MBProgressHUD showTextHUD: @"消息发送成功" onView: self.scrollView];
                    
                    [self.chatRecordArray addObject: message];
                    [self.chatTableView   reloadData];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: _chatRecordArray.count-1
                                                                inSection: 0];
                    [self.chatTableView scrollToRowAtIndexPath: indexPath
                                              atScrollPosition: UITableViewScrollPositionBottom
                                                      animated: YES];
                    textView.text = @"";
                }
               onQueue: nil];
        
    };
    
    [self.scrollView addSubview: toolView];
    
    //添加通知: 用来监测软键盘变动, 为了调用 tableView 随着软键盘一起上移的方法
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillChangeFrame:)
                                                 name: UIKeyboardWillChangeFrameNotification
                                               object: nil];
    
    //获取聊天消息
    NSString *chatter            = self.buddy.username;
    EMConversation *conversation = [[EaseMob sharedInstance].chatManager
                                    conversationForChatter: chatter
                                    conversationType: eConversationTypeChat];
    
    //当进入这个聊天窗口, 该对象的全部消息都标记成已读
    [conversation markAllMessagesAsRead: YES];
    
    self.chatRecordArray = [NSMutableArray arrayWithArray: [conversation loadAllMessages]];
    
    //如果有聊天记录, tableView 就滚到最后一行
    if (self.chatRecordArray.count > 0)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow: self.chatRecordArray.count - 1
                                                    inSection: 0];
        
        [self.chatTableView scrollToRowAtIndexPath: indexPath
                                  atScrollPosition: UITableViewScrollPositionBottom
                                          animated: YES];
    }
    
    //添加环信代理, 获取好友的消息
    [[EaseMob sharedInstance].chatManager addDelegate: self delegateQueue: nil];
}


#pragma mark 键盘弹出时的方法
//获取软键盘frame 变动的终结位置, 让 tableView 一起上移
- (void)keyboardWillChangeFrame: (NSNotification *)notification
{
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    if (keyboardRect.origin.y < self.view.bottom) {
        self.scrollView.top =- keyboardRect.size.height;
    }else{
        self.scrollView.top = 0;
    }
}

#pragma mark ScrollViewDelegate Method

//聊天记录拖动时, 键盘要回收
- (void)scrollViewWillBeginDragging: (UIScrollView *)scrollView
{
    [self.scrollView endEditing: YES];
    [UIView animateWithDuration: 0.3f animations: ^{
        if (self.scrollView.top < 0) {
            self.scrollView.top = 0;
        }
    }];
}

#pragma mark TableViewDelegate & TableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    return self.chatRecordArray.count;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath {
    
    static NSString *identifier = @"chatCell";
    ChatCell *cell = [tableView cellForRowAtIndexPath: indexPath];
    if (!cell) {
        cell = [[ChatCell alloc] initWithStyle: UITableViewCellStyleDefault
                               reuseIdentifier: identifier];
    }
    
    cell.message         = self.chatRecordArray[indexPath.row];
    
    return cell;
}


#pragma mark rowHeight 设置
//获取每个 row 对应的消息内容, 如果是文本消息, 就计算对应的高度, 如果是语音消息, 高度固定.
- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    
    static NSString *identifier = @"chatCell";
    ChatCell *cell              = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (!cell) {
        cell = [[ChatCell alloc] initWithStyle: UITableViewCellStyleDefault
                               reuseIdentifier: identifier];
    }

    CGFloat cellRowHeight = 0;
    CGFloat avatarH       = 40;
    CGFloat timeLabelH    = 15;
    CGFloat inset         = 10;

    EMMessage *message    = self.chatRecordArray[indexPath.row];
    id body               = message.messageBodies[0];
    
    //如果是文本消息
    if ([body isKindOfClass: [EMTextMessageBody class]])
    {
        EMTextMessageBody *textBody = body;
        CGSize maxSize              = CGSizeMake(SCREEN_WIDTH/2, MAXFLOAT);
        NSDictionary *fontAttri     = @{NSFontAttributeName: [UIFont systemFontOfSize: 15.0f]};
        CGSize textSize             = [textBody.text boundingRectWithSize: maxSize
                                                      options: NSStringDrawingUsesLineFragmentOrigin
                                                   attributes: fontAttri
                                                      context: nil].size;
        
        cellRowHeight = MAX(textSize.height + inset*2 + timeLabelH, avatarH + timeLabelH) + 5;
    }else{
        cellRowHeight = avatarH + timeLabelH + 5;
    }
    
    return cellRowHeight;
}


#pragma mark EMChatManagerDelegate Method

//当收到消息的时候调用
- (void)didReceiveMessage: (EMMessage *)message
{
    [self.chatRecordArray addObject: message];
    [self.chatTableView   reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: self.chatRecordArray.count-1
                                                inSection: 0];
    [self.chatTableView scrollToRowAtIndexPath: indexPath
                              atScrollPosition: UITableViewScrollPositionBottom
                                      animated: YES];
}


#pragma mark ChatToolViewDelegate Method

//设置录音操作相关的按钮动作, 三种操作:开始录音, 发送录音, 取消录音, 它们的 Type 写在一个 enum 里
- (void)ChatToolViewWithButtonType: (ChatToolViewVoiceButtonType)buttonType
{
    switch (buttonType)
    {
        case ChatToolViewVoiceButtonStart:
        {
           //生成录音
           //1. 生成录音的名字
           NSDate   *date     = [NSDate date];
           NSString *fileName = [NSString stringWithFormat: @"%d", (int)[date timeIntervalSince1970]];
            
           //2. 开始异步录音
           [[EMCDDeviceManager sharedInstance] asyncStartRecordingWithFileName: fileName
                                                                    completion: ^(NSError*error){}];
           break;
        }
            
        case ChatToolViewVoiceButtonSend:
        {
            [[EMCDDeviceManager sharedInstance] asyncStopRecordingWithCompletion:
             ^(NSString *recordPath, NSInteger aDuration, NSError *error)
            {
                if (!error) {
                    //NSLog(@"录音:%@, 时长:%zd",recordPath,aDuration);
                }
                //发送录音
                [self sendVoiceWithFilePath: recordPath duration: aDuration];
            }];
            break;
        }
            
        case ChatToolViewVoiceButtonCancel: {
            break;
        }
        default:
            break;
    }
}

//发送录音消息的方法: 先生成录音消息, 然后异步发送, 成功后更新聊天记录数组和 tableView
- (void)sendVoiceWithFilePath: (NSString *)recordPath duration: (NSInteger)aDuration
{
    //生成录音消息
    EMChatVoice *voice            = [[EMChatVoice alloc] initWithFile: recordPath
                                                          displayName: @"【语音】"];
    voice.duration                = aDuration;
    EMVoiceMessageBody *voiceBody = [[EMVoiceMessageBody alloc] initWithChatObject: voice];
    EMMessage *message            = [[EMMessage alloc] initWithReceiver: self.buddy.username
                                                                 bodies: @[voiceBody]];
    message.messageType           = eMessageTypeChat;//单聊
    
    [[EaseMob sharedInstance].chatManager
     asyncSendMessage: message
             progress: self
              prepare: ^(EMMessage *message, EMError *error) { } onQueue: nil
           completion: ^(EMMessage *message, EMError *error)
                {
                    if (!error)
                    {
                        [MBProgressHUD showTextHUD: @"语音发送成功" onView: self.scrollView];
                        
                        [self.chatRecordArray addObject: message];
                        [self.chatTableView reloadData];
                        
                        NSIndexPath *indexPath = [NSIndexPath
                                                  indexPathForRow: self.chatRecordArray.count-1
                                                  inSection: 0];
                        [self.chatTableView scrollToRowAtIndexPath: indexPath
                                                  atScrollPosition: UITableViewScrollPositionBottom
                                                          animated: YES];
                    }else{
                        [MBProgressHUD showTextHUD: @"语音发送失败" onView: self.scrollView];
                    }
                } onQueue: nil];
}


#pragma mark IEMChatProgressDelegate Method
//要写一下, 不然发送语音消息会崩溃
- (void)setProgress: (float)progress forMessage: (EMMessage *)message forMessageBody: (id<IEMMessageBody>)messageBody {
}

@end
