#import <UIKit/UIKit.h>

@interface ChatCell : UITableViewCell

/** 本 cell 对应的单条聊天记录 */
@property (nonatomic, strong) EMMessage *message;

@end
