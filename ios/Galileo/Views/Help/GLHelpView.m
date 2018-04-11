#import "GLHelpView.h"
#import "GLTouchView.h"

#import "UIFont+GLSizes.h"
#import "UIView+AYUtils.h"

static UIEdgeInsets const kHelpViewPadding = {20, 20, 20, 20};

@interface GLHelpView ()

@property (copy, nonatomic) GLHelpViewDismissHandler dismissHandler;
@property (nonatomic) BOOL hideOnDismiss;
@property (nonatomic) GLTouchView *touchView;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) UILabel *helpLabel;

@end

@implementation GLHelpView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    [self setUpViews];
    
    return self;
}

#pragma mark Public

- (void)tapWithLabelText:(NSString *)labelText labelPoint:(CGPoint)labelPoint touchPoint:(CGPoint)touchPoint dismissHandler:(GLHelpViewDismissHandler)dismissHandler doubleTap:(BOOL)doubleTap hideOnDismiss:(BOOL)hideOnDismiss {
    self.touchView.center = touchPoint;
    self.helpLabel.text = labelText;
    [self.helpLabel sizeToFit];
    self.helpLabel.center = labelPoint;
    self.dismissHandler = dismissHandler;
    self.hideOnDismiss = hideOnDismiss;
    
    [self showIfNeededWithCompletionBlock:^{
        if (self.timer) {
            [self.timer invalidate];
        }
        if (doubleTap) {
            [self.touchView addDoubleTapAnimation];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self.touchView selector:@selector(addDoubleTapAnimation) userInfo:nil repeats:YES];
        } else {
            [self.touchView addTapAnimation];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self.touchView selector:@selector(addTapAnimation) userInfo:nil repeats:YES];
        }
    }];
}

- (void)swipeWithLabelText:(NSString *)labelText labelPoint:(CGPoint)labelPoint touchStartPoint:(CGPoint)touchStartPoint touchEndPoint:(CGPoint)touchEndPoint dismissHandler:(GLHelpViewDismissHandler)dismissHandler hideOnDismiss:(BOOL)hideOnDismiss {
    self.touchView.center = touchStartPoint;
    self.touchView.startPoint = touchStartPoint;
    self.touchView.endPoint = touchEndPoint;
    self.helpLabel.text = labelText;
    [self.helpLabel sizeToFit];
    self.helpLabel.center = labelPoint;
    self.dismissHandler = dismissHandler;
    self.hideOnDismiss = hideOnDismiss;
    
    [self showIfNeededWithCompletionBlock:^{
        if (self.timer) {
            [self.timer invalidate];
        }
        [self.touchView addSwipeAnimation];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self.touchView selector:@selector(addSwipeAnimation) userInfo:nil repeats:YES];
    }];
}

#pragma mark Private

- (void)setUpViews {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75f];
    self.alpha = 0;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    self.touchView = [[GLTouchView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [self addSubview:self.touchView];
    
    self.helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(kHelpViewPadding.left, 0, self.width - kHelpViewPadding.left - kHelpViewPadding.right, 0)];
    self.helpLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont largeTextFontSize]];
    self.helpLabel.textColor = [UIColor whiteColor];
    self.helpLabel.numberOfLines = 0;
    self.helpLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.helpLabel];
}

- (void)showIfNeededWithCompletionBlock:(void (^ _Nonnull)(void))completionBlock {
    if (self.alpha == 0) {
        [UIView animateWithDuration:0.5f animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        completionBlock();
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (self.hideOnDismiss) {
        [self.timer invalidate];
        [UIView animateWithDuration:0.5f animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
    if (self.dismissHandler) {
        self.dismissHandler();
    }
}

@end
