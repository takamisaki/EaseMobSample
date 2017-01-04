#import "ConversationsController.h"
#import "ChatController.h"

@interface ConversationsController ()
<UITableViewDelegate, UITableViewDataSource, EMChatManagerDelegate>

/** 呈现对话列表的 tableview */
@property (nonatomic, weak  ) UITableView    *conversationTableView;
/** 对话数组(dataSource) */
@property (nonatomic, strong) NSMutableArray *conversations;

@end



@implementation ConversationsController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //创建显示会话列表的 tableView
    
    //1. 计算出tabBar 和 navigationBar中间距离
    CGFloat viewHeight                 = self.view.height;
    CGFloat naviHeight                 = self.navigationController.navigationBar.height;
    CGFloat tabbHeight                 = self.tabBarController.tabBar.height;
    CGFloat conversationTableViewH     = viewHeight - naviHeight - tabbHeight - 20;
    //2. 创建 tableview并设置
    CGRect conversationTableVIewRect   = CGRectMake(0, 0, SCREEN_WIDTH, conversationTableViewH);
    UITableView *conversationTableView = [[UITableView alloc]initWithFrame: conversationTableVIewRect
                                                                     style: UITableViewStylePlain];
    conversationTableView.delegate       = self;
    conversationTableView.dataSource     = self;
    conversationTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.conversationTableView           = conversationTableView;
    
    [self.scrollView addSubview: conversationTableView];
    
    //添加环信代理, 要监听消息变动
    [[EaseMob sharedInstance].chatManager addDelegate: self delegateQueue: nil];
}


- (void)viewWillAppear: (BOOL)animated
{
    [super viewWillAppear: animated];
    [self.conversations removeAllObjects];
    
    NSArray *removeConversations = [[EaseMob sharedInstance].chatManager
                                    loadAllConversationsFromDatabaseWithAppend2Chat: YES];
     self.conversations          = [NSMutableArray arrayWithArray: removeConversations];
    [self.conversationTableView reloadData];
}


#pragma mark TableViewDelegate

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    return self.conversations.count;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *identifier = @"conversationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                      reuseIdentifier: identifier];
    }
    
    EMConversation *conversation = self.conversations[indexPath.row];
    EMMessage *latestMessage     = conversation.latestMessage;
    NSString *showString         = @"";
    
    id body                      = latestMessage.messageBodies[0];
    
    if ([body isKindOfClass: [EMTextMessageBody class]]) {
        
        EMTextMessageBody *textBody = body;
        showString                  = textBody.text;
        
    }else if([body isKindOfClass: [EMVoiceMessageBody class]]){
        
        EMVoiceMessageBody *voiceBody = body;
        showString                    = voiceBody.displayName;
    }
    
    NSString *chatterAndUnreadCountString = [NSString stringWithFormat: @"%@ - %zd未读",
                                             conversation.chatter,
                                             [conversation unreadMessagesCount]];
    
    cell.textLabel.text                   = chatterAndUnreadCountString;
    cell.detailTextLabel.text             = showString;
    cell.imageView.image                  = [UIImage imageNamed: @"avatar"];
    
    return cell;
}


//点击某行弹出对应的聊天窗口
- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    EMConversation *conversation            = self.conversations[indexPath.row];
    ChatController *chatController          = [ChatController new];
    chatController.hidesBottomBarWhenPushed = YES;
    chatController.buddy                    = [EMBuddy buddyWithUsername: conversation.chatter];
    
    [self.navigationController pushViewController: chatController animated: YES];
}


#pragma mark EMChatManagerDelegate Method

//底部显示未读消息的总数
- (void)didUnreadMessagesCountChanged
{
    [self.conversationTableView reloadData];
    NSInteger count = 0;
    for (EMConversation *conversation in self.conversations) {
        count += [conversation unreadMessagesCount];
    }
    NSString *countString = nil;
    if (count > 0) {
        countString = [NSString stringWithFormat: @"%zd",count];
    }
    
    self.navigationController.tabBarItem.badgeValue = countString;
}

//当收到好友申请时, 弹出 alert 窗口并提供两个选择:同意和拒绝.
- (void)didReceiveBuddyRequest: (NSString *)username message: (NSString *)message
{
    //创建弹窗
    NSString *alertMessage    = [NSString stringWithFormat: @"%@申请加你为好友, 附加消息:%@",
                                                            username,message];
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle: @"收到好友申请"
                                                        message: alertMessage
                                                 preferredStyle: UIAlertControllerStyleActionSheet];
    
    //给弹窗添加按钮
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle: @"拒绝"
                                                           style: UIAlertActionStyleDefault
                                                         handler: ^(UIAlertAction * _Nonnull action)
    {
        BOOL isSuccess = [[EaseMob sharedInstance].chatManager rejectBuddyRequest: username
                                                                           reason: @""
                                                                            error: nil];
        
        [MBProgressHUD showTextHUD: isSuccess? @"拒绝成功" : @"拒绝失败" onView: self.scrollView];
    }];
    
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle: @"同意"
                                                           style: UIAlertActionStyleDefault
                                                         handler: ^(UIAlertAction * _Nonnull action)
    {
        BOOL isSuccess = [[EaseMob sharedInstance].chatManager acceptBuddyRequest: username
                                                                            error: nil];
        
        [MBProgressHUD showTextHUD: isSuccess? @"接受成功" : @"接受失败" onView: self.scrollView];
    }];
    
    [alertC addAction: rejectAction];
    [alertC addAction: acceptAction];
    
    [self presentViewController: alertC animated: YES completion: nil];
}

@end
