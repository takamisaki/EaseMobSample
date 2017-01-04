#import "ContactsController.h"
#import "ChatController.h"
#import "ChatCell.h"
#import "ChatToolView.h"

@interface ContactsController ()
<UITableViewDelegate, UITableViewDataSource, EMChatManagerDelegate>

/** 呈现好友的列表 */
@property (nonatomic, weak  ) UITableView *contactsTableView;
/** 好友数组 */
@property (nonatomic, strong) NSArray     *buddyArray;

@end



@implementation ContactsController

- (void)viewDidLoad {
    [super viewDidLoad];

    //添加加好友的按钮, 位置在 navigationBar 的右边
    LNButton *addContactButton = [LNButton createButton];
    addContactButton.frame = CGRectMake(0, 0, 30, 30); //不用设置 xy
    [addContactButton setImage: [UIImage imageNamed: @"addContact_normal"]
                      forState: UIControlStateNormal];
    [addContactButton setImage: [UIImage imageNamed: @"addContact_touched"]
                      forState: UIControlStateHighlighted];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithCustomView: addContactButton];
    
    //添加按钮动作
    addContactButton.block = ^(LNButton *button)
    {
        //创建弹出框
        //1.1 创建文本输入框
        UIAlertController *addContactAlert = [UIAlertController
                                              alertControllerWithTitle: @"添加好友的请求信息"
                                                               message: @""
                                                        preferredStyle: UIAlertControllerStyleAlert];
        [addContactAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入好友的名称";
        }];
        [addContactAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入请求理由";
        }];
        
        //1.2 获取弹出框里的文本框, 以便获取输入内容
        UITextField *nameField        = [[addContactAlert textFields] firstObject];
        UITextField *descriptionField = [[addContactAlert textFields] lastObject ];
        
        //2. 添加按钮
        UIAlertAction *cancelAction   = [UIAlertAction
                                         actionWithTitle: @"取消"
                                         style: UIAlertActionStyleCancel
                                         handler: ^(UIAlertAction * _Nonnull action) {}];
        UIAlertAction *confirmAction  = [UIAlertAction
                                         actionWithTitle: @"确定"
                                         style: UIAlertActionStyleDefault
                                         handler: ^(UIAlertAction * _Nonnull action)
        {
            if (nameField.text.length == 0) {
                [MBProgressHUD showTextHUD: @"请输入对方名称" onView: self.scrollView];
                return;
            }
            
            //添加好友的申请
            BOOL isSuccess = [[EaseMob sharedInstance].chatManager addBuddy: nameField.text
                                                                    message: descriptionField.text
                                                                      error: nil];
            
            [MBProgressHUD showTextHUD: isSuccess? @"好友请求发送成功" : @"好友请求发送失败"
                                onView: self.scrollView];
        }];
        
        [addContactAlert addAction: cancelAction ];
        [addContactAlert addAction: confirmAction];
        
        //3. 呈现弹出框
        [self presentViewController: addContactAlert animated: YES completion: nil];
    };
    
    //添加环信代理
    [[EaseMob sharedInstance].chatManager addDelegate: self delegateQueue: nil];
    
    //创建好友列表
    CGRect contactsTableViewRect     = CGRectMake(0, 0, self.view.width, self.view.height);
    UITableView *contactsTableView   = [[UITableView alloc] initWithFrame: contactsTableViewRect
                                                                    style: UITableViewStylePlain];
    contactsTableView.delegate       = self;
    contactsTableView.dataSource     = self;
    contactsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contactsTableView           = contactsTableView;
    [self.view addSubview: contactsTableView];
    
    //从服务器获取好友数组, 赋值给数据源属性, 更新 tableView
    [[EaseMob sharedInstance].chatManager
     asyncFetchBuddyListWithCompletion: ^(NSArray *buddyList, EMError *error)
    {
         self.buddyArray        = buddyList;
        [self.contactsTableView reloadData];
    } onQueue: nil];

}


#pragma mark TableViewDelegate & TableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section{
    return self.buddyArray.count;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
    static NSString *identifier = @"contactCell";
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (!cell) {
        cell = [[ChatCell alloc] initWithStyle: UITableViewCellStyleDefault
                               reuseIdentifier: identifier];
    }
    
    EMBuddy *buddy      = self.buddyArray[indexPath.row];
    cell.textLabel.text = buddy.username;
    
    return cell;
}

//滑动某 row 删除该好友
- (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        EMBuddy *buddy = self.buddyArray[indexPath.row];
        BOOL isSuccess = [[EaseMob sharedInstance].chatManager removeBuddy: buddy.username
                                                          removeFromRemote: YES
                                                                     error: nil];

        [MBProgressHUD showTextHUD: isSuccess? @"删除成功" : @"删除失败" onView: self.scrollView];
    }
}

//点击某 row 弹出该好友的聊天窗口
- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    
    ChatController *chatController          = [ChatController new];
    chatController.hidesBottomBarWhenPushed = YES;
    chatController.buddy                    = self.buddyArray[indexPath.row];
    
    [self.navigationController pushViewController: chatController animated: YES];
}



#pragma mark EMChatManagerDelegate Methods

//好友列表发生更新时调用: 更新数据源数组, 更新 tableView
- (void)didUpdateBuddyList: (NSArray *)buddyList
            changedBuddies: (NSArray *)changedBuddies
                     isAdd: (BOOL)isAdd
{
     self.buddyArray = buddyList;
    [self.contactsTableView reloadData];
}

//你发出的好友申请被通过后调用: 更新数据源数组, 更新 tableView
- (void)didAcceptedByBuddy: (NSString *)username
{
    NSString *tip = [NSString stringWithFormat: @"【%@】接受了您的好友请求",username];
    [MBProgressHUD showTextHUD: tip onView: self.scrollView];
    
    [[EaseMob sharedInstance].chatManager asyncFetchBuddyListWithCompletion:
     ^(NSArray *buddyList, EMError *error)
    {
         self.buddyArray = buddyList;
        [self.contactsTableView reloadData];
        
    } onQueue: nil];
}

//你的好友把你删除时调用: 更新数据源数组, 更新 tableView
- (void)didRemovedByBuddy: (NSString *)username
{
    NSString *tip = [NSString stringWithFormat: @"【%@】把你删除了",username];
    [MBProgressHUD showTextHUD: tip onView: self.scrollView];
    
    [[EaseMob sharedInstance].chatManager asyncFetchBuddyListWithCompletion:
     ^(NSArray *buddyList, EMError *error)
    {
         self.buddyArray = buddyList;
        [self.contactsTableView reloadData];
        
    } onQueue: nil];
}

//你同意了别人发给你的好友申请被通过后调用: 更新数据源数组, 更新 tableView
- (void)didAcceptBuddySucceed: (NSString *)username
{
    NSString *tip = [NSString stringWithFormat: @"您同意了【%@】的好友请求",username];
    [MBProgressHUD showTextHUD: tip onView: self.scrollView];
    
    [[EaseMob sharedInstance].chatManager asyncFetchBuddyListWithCompletion:
     ^(NSArray *buddyList, EMError *error)
    {
         self.buddyArray = buddyList;
        [self.contactsTableView reloadData];
        
    } onQueue: nil];
}



@end
