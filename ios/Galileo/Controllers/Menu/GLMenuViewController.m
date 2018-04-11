#import "GLMenuViewController.h"

#import "AYMacros.h"
#import "GLAboutViewController.h"
#import "GLDataManager.h"
#import "GLFavoritesCollectionViewController.h"
#import "GLMenuArticleView.h"
#import "GLMenuListView.h"
#import "GLSettingsViewController.h"
#import "GLStatisticsViewController.h"
#import "UIFont+GLSizes.h"
#import "UIImage+GLHelpers.h"
#import "UIView+AYUtils.h"
#import "UIWindow+GLHelpers.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

static CGFloat const kArticleViewHeight = 150;
static UIEdgeInsets const kTopBarPadding = {28, 15, 0, 0};
static UIEdgeInsets const kArticleViewPadding = {100, 0, 30, 0};
static UIEdgeInsets const kListViewPadding = {30, 40, 100, 40};

@interface GLMenuViewController () <GLMenuListViewDelegate, GLMenuArticleViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) GLMenuArticleView *articleView;
@property (nonatomic) GLMenuListView *listView;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIImageView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *sharingView;
@property (nonatomic) UIVisualEffectView *blurEffectView;
@property (nonatomic) UIVisualEffectView *vibrancyEffectView;
@property (nonatomic, getter=isAnimating) BOOL animating;
@property (weak, nonatomic) GLArticlesViewController *articlesViewController;

@end

@implementation GLMenuViewController

#pragma mark Initializers

- (instancetype)initWithArticlesViewController:(GLArticlesViewController *)articlesViewController article:(GLArticle *)article {
    self = [super init];
    if (!self) return nil;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.articlesViewController = articlesViewController;
    _article = article;
    [[article getSharingViewWithSize:kSharingArticleViewSize forDisplay:NO]
        subscribeNext:^(UIView *sharingView) {
            self.sharingView = sharingView;
        }];
    
    return self;
}

- (instancetype)initWithArticlesViewController:(GLArticlesViewController *)articlesViewController {
    self = [super init];
    if (!self) return nil;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.articlesViewController = articlesViewController;
    
    return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpBackgroundView];
    [self setUpEffectView];
    [self setUpCloseButton];
    [self setUpTitleLabel];
    [self setUpArticleView];
    [self setUpListView];
}

#pragma mark Public

- (void)show {
    [self.articlesViewController presentViewController:self animated:NO completion:^{
        [self.listView.tableView reloadData];
    }];
}

#pragma mark Private

- (void)setUpBackgroundView {
    self.backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.image = [[[UIApplication sharedApplication].delegate window] snapshot];
    [self.view addSubview:self.backgroundView];
}

- (void)setUpEffectView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blurEffectView.frame = self.view.frame;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
    tapGestureRecognizer.delegate = self;
    [self.blurEffectView addGestureRecognizer:tapGestureRecognizer];
    
    self.vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:blurEffect]];
    self.vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.vibrancyEffectView.frame = self.view.frame;
    [self.blurEffectView.contentView addSubview:self.vibrancyEffectView];
    
    [self.view addSubview:self.blurEffectView];
}

- (void)setUpCloseButton {
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(kTopBarPadding.left, kTopBarPadding.top, 22, 22)];
    [self.closeButton setImage:[[UIImage imageNamed:@"CrossIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.vibrancyEffectView.contentView addSubview:self.closeButton];
}

- (void)setUpTitleLabel {
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont navigationBarTitleFontSize]];
    switch (self.articlesViewController.type) {
        case GLArticlesViewTypeRandom:
            self.titleLabel.text = NSLocalizedString(@"Home", nil);
            break;
        case GLArticlesViewTypeFavorites:
            self.titleLabel.text = NSLocalizedString(@"Favorites", nil);
            break;
    }
    [self.titleLabel sizeToFit];
    self.titleLabel.top = kTopBarPadding.top;
    self.titleLabel.centerX = self.vibrancyEffectView.width / 2;
    [self.vibrancyEffectView.contentView addSubview:self.titleLabel];
}

- (void)setUpArticleView {
    if (self.article) {
        self.articleView = [[GLMenuArticleView alloc] initWithFrame:CGRectMake(kArticleViewPadding.left, kArticleViewPadding.top, self.view.width - kArticleViewPadding.left - kArticleViewPadding.right, kArticleViewHeight) article:self.article];
        self.articleView.delegate = self;
        [self.view addSubview:self.articleView];
    }
}

- (void)setUpListView {
    NSArray *images = @[];
    NSArray *titles = @[self.articlesViewController.type == GLArticlesViewTypeRandom ? NSLocalizedString(@"Favorites", nil) : NSLocalizedString(@"Home", nil), NSLocalizedString(@"Settings", nil), NSLocalizedString(@"Statistics", nil), NSLocalizedString(@"About", nil)];
    self.listView = [[GLMenuListView alloc] initWithFrame:CGRectMake(kListViewPadding.left, 0, self.view.width - kListViewPadding.left - kListViewPadding.right, self.view.height - kArticleViewPadding.top - kArticleViewHeight - kListViewPadding.top - (IS_IPHONE_4_OR_LESS ? kListViewPadding.bottom/3 : kListViewPadding.bottom)) images:images titles:titles];
    if (self.articleView) {
        self.listView.top = kArticleViewPadding.top + kArticleViewHeight + kListViewPadding.top;
    } else {
        self.listView.centerY = self.vibrancyEffectView.contentView.height/2;
    }
    self.listView.delegate = self;
    [self.vibrancyEffectView.contentView addSubview:self.listView];
}

- (void)closeMenu {
    [self closeMenuWithDismissHandler:nil];
}

- (void)closeMenuWithDismissHandler:(void (^ _Nullable)(void))dismissHandler {
    if (self.isAnimating) return;
    
    self.animating = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        self.animating = NO;
        if (dismissHandler) {
            dismissHandler();
        }
    }];
}

#pragma mark GLMenuListViewDelegate

- (void)listView:(GLMenuListView *)listView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self closeMenuWithDismissHandler:^{
        switch (indexPath.row) {
            case 0: {
                switch (self.articlesViewController.type) {
                    case GLArticlesViewTypeRandom:
                        [self.articlesViewController.navigationController pushViewController:[GLFavoritesCollectionViewController new] animated:YES];
                        break;
                    case GLArticlesViewTypeFavorites:
                        [self.articlesViewController.navigationController popToRootViewControllerAnimated:YES];
                        break;
                }
            }
                break;
            case 1:
                [self.articlesViewController.navigationController pushViewController:[GLSettingsViewController new] animated:YES];
                break;
            case 2:
                [self.articlesViewController.navigationController pushViewController:[GLStatisticsViewController new] animated:YES];
                break;
            case 3:
                [self.articlesViewController.navigationController pushViewController:[GLAboutViewController new] animated:YES];
                break;
        }
    }];
}

#pragma mark GLMenuArticleViewDelegate

- (void)articleView:(GLMenuArticleView *)articleView didTapOnButtonType:(GLMenuArticleViewButtonType)buttonType {
    switch (buttonType) {
        case GLMenuArticleViewButtonTypeFavorite:
            [self favoriteArticle];
            break;
        case GLMenuArticleViewButtonTypeShare:
            [self shareArticle];
            break;
    }
}

- (void)favoriteArticle {
    [[[[GLDataManager sharedInstance] favoriteArticle:self.article]
       deliverOn:RACScheduler.mainThreadScheduler]
       subscribeCompleted:^{
           [self.articleView updateFavoriteButton];
       }];
}

- (void)shareArticle {
    NSString *message = [self.article.title stringByAppendingString:@" #galileoapp"];
    if (self.sharingView) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[UIImage convertViewToImage:self.sharingView], message, self.article.publicUrl] applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    } else {
        [[[self.article getSharingViewWithSize:kSharingArticleViewSize forDisplay:NO]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(UIView *sharingView) {
                self.sharingView = sharingView;
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[UIImage convertViewToImage:sharingView], message, self.article.publicUrl] applicationActivities:nil];
                [self presentViewController:activityViewController animated:YES completion:nil];
            }];
    }
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.vibrancyEffectView.contentView) {
        return YES;
    }
    return NO;
}

@end
