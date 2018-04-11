#import "GLPullForActionView.h"

#import "UIView+AYUtils.h"
#import <KVOController/FBKVOController.h>

static CGSize const kPullForActionViewSize = {50, 50};
static UIEdgeInsets const kPullForActionViewPadding = {10, 0, 20, 0};

@interface GLPullForActionView()

@property (weak, nonatomic) GLArticleView *articleView;
@property (nonatomic) UIImageView *imageView;
@property (copy, nonatomic) GLPullForActionViewCallback callback;
@property (nonatomic, getter=isRunningCallback) BOOL runningCallback;

@end

@implementation GLPullForActionView

#pragma mark Initializaiton

- (instancetype)initWithArticleView:(GLArticleView *)articleView callback:(GLPullForActionViewCallback)callback {
    self = [super init];
    if (!self) return nil;
    
    self.articleView = articleView;
    self.callback = callback;
    
    self.layer.masksToBounds = YES;
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.articleView.width - kPullForActionViewSize.width)/2, kPullForActionViewPadding.top, kPullForActionViewSize.width, kPullForActionViewSize.height)];
    self.imageView.image = [[UIImage imageNamed:@"WikipediaIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.tintColor = [UIColor blackColor];
    [self addSubview:self.imageView];
    
    [self.KVOController observe:self.articleView keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld action:@selector(observeContentOffset:)];
    
    return self;
}

#pragma mark Private

- (void)observeContentOffset:(NSDictionary *)change {
    if (self.isRunningCallback) return;
    CGFloat offset = self.articleView.contentOffset.y;
    CGFloat height = self.articleView.contentSize.height - self.articleView.height;
    if (offset > height) {
        self.frame = CGRectMake(0, self.articleView.contentSize.height, self.articleView.width, kPullForActionViewSize.height + kPullForActionViewPadding.top + kPullForActionViewPadding.bottom);
        
        CGFloat scale = MIN((offset - height)/(kPullForActionViewSize.height + kPullForActionViewPadding.top + kPullForActionViewPadding.bottom), 1);
        self.imageView.transform = CGAffineTransformMakeScale(scale, scale);
        
        if (offset >= height + kPullForActionViewSize.height + kPullForActionViewPadding.top + kPullForActionViewPadding.bottom + 10){
            self.imageView.image = [[UIImage imageNamed:@"WikipediaIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if (!self.articleView.dragging && self.articleView.decelerating) {
                if (self.callback) {
                    self.runningCallback = YES;
                    [self performSelector:@selector(setNotRunningCallback) withObject:nil afterDelay:1];
                    self.callback();
                }
            }
        } else {
            self.imageView.image = [[UIImage imageNamed:@"WikipediaIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
}

- (void)setNotRunningCallback {
    self.runningCallback = NO;
}

@end
