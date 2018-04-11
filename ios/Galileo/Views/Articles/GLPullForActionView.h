#import "GLArticleView.h"

typedef void (^GLPullForActionViewCallback)(void);

@interface GLPullForActionView : UIView

- (instancetype)initWithArticleView:(GLArticleView *)articleView callback:(GLPullForActionViewCallback)callback;

@end
