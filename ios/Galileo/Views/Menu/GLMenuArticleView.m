#import "GLMenuArticleView.h"

#import "UIView+AYUtils.h"
#import <pop/POP.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

static CGSize const kMenuArticleViewButtonSize = {40, 40};
static CGFloat const kMenuArticleViewPadding = 20;

@interface GLMenuArticleView ()

@property (nonatomic) UIView *infoView;
@property (nonatomic) UIButton *favoriteButton;
@property (nonatomic) UIButton *shareButton;

@end

@implementation GLMenuArticleView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame article:(GLArticle *)article {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    _article = article;
    self.backgroundColor = [UIColor clearColor];
    [self setUpButtons];
    [self setUpImageViewAndTitleLabel];
    
    return self;
}

#pragma mark Public

- (void)updateFavoriteButton {
    [self.favoriteButton setImage:self.article.isFavorite ? [[UIImage imageNamed:@"StarIconFill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : [[UIImage imageNamed:@"StarIconOutline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.favoriteButton.tintColor = self.article.favorite ? [UIColor colorWithRed:1 green:0.8f blue:0 alpha:1] : [UIColor colorWithWhite:1 alpha:0.75f];
}

#pragma mark Private

- (void)setUpButtons {
    self.favoriteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.width - kMenuArticleViewButtonSize.width - kMenuArticleViewPadding * 2, 0, kMenuArticleViewButtonSize.width + kMenuArticleViewPadding * 2, self.height/2)];
    [self updateFavoriteButton];
    [self.favoriteButton addTarget:self action:@selector(favoriteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.favoriteButton];
    
    self.shareButton = [[UIButton alloc] initWithFrame:self.favoriteButton.frame];
    self.shareButton.top = self.favoriteButton.bottom;
    [self.shareButton setImage:[[UIImage imageNamed:@"ShareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.shareButton.tintColor = [UIColor colorWithWhite:1 alpha:0.75f];
    [self.shareButton addTarget:self action:@selector(shareButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.shareButton];
    
    for (UIButton *button in @[self.favoriteButton, self.shareButton]) {
        [button addTarget:self action:@selector(scaleToSmall:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [button addTarget:self action:@selector(scaleAnimation:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(scaleToDefault:) forControlEvents:UIControlEventTouchDragExit];
    }
}

- (void)setUpImageViewAndTitleLabel {
    [[[self.article getSharingViewWithSize:CGSizeMake(self.width - self.favoriteButton.width - kMenuArticleViewPadding, self.height) forDisplay:YES]
        deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(UIView *sharingView) {
            self.infoView = sharingView;
            self.infoView.left = kMenuArticleViewPadding;
            [self addSubview:self.infoView];
        }];
}

- (void)favoriteButtonTapped {
    if (self.delegate) {
        [self.delegate articleView:self didTapOnButtonType:GLMenuArticleViewButtonTypeFavorite];
    }
}

- (void)shareButtonTapped {
    if (self.delegate) {
        [self.delegate articleView:self didTapOnButtonType:GLMenuArticleViewButtonTypeShare];
    }
}

#pragma mark Animations

- (void)scaleToSmall:(UIButton *)button {
    POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(0.95f, 0.95f)];
    [button.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

- (void)scaleAnimation:(UIButton *)button {
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3, 3)];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    scaleAnimation.springBounciness = 18;
    [button.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

- (void)scaleToDefault:(UIButton *)button {
    POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    [button.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleDefaultAnimation"];
}

@end
