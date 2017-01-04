#import "LNButton.h"

@implementation LNButton

- (instancetype)initWithFrame: (CGRect)frame {
    
    if (self = [super initWithFrame: frame]) {
        [self addTarget: self
                 action: @selector(clicked:)
       forControlEvents: UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)clicked: (LNButton *)button {
    if (_block) {
        _block(button);
    }
}

+ (instancetype)createButton {
    return [LNButton buttonWithType: UIButtonTypeCustom];
}

@end
