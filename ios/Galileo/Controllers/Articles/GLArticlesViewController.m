#import "GLArticlesViewController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import "GLArticle.h"
#import "GLArticleView.h"
#import "GLDataManager.h"
#import "GLHelpView.h"
#import "GLMenuViewController.h"
#import "GLPromptView.h"
#import "GLPullForActionView.h"
#import "GLScrollView.h"
#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import "UIImage+GLHelpers.h"
#import "UILabel+GLHelpers.h"
#import "UIView+AYUtils.h"
#import "VLDContextSheet.h"
#import "VLDContextSheetItem.h"
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>
#import <MessageUI/MessageUI.h>
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <SafariServices/SafariServices.h>
#import <Social/Social.h>

static NSUInteger const kMaxNumberOfArticlesToGoBack = 5;
static NSUInteger const kMinNumberOfArticlesToGoForward = 5;
static CGFloat const kCompletedLabelsSpacing = 10;
static UIEdgeInsets const kArticlesViewPadding = {20, 20, 20, 20};
static NSString * const kSeenHelpKey = @"seenHelp";
static NSInteger const kUsesBeforePrompt = 9;

#define LONG_PRESS_SHARING_ENABLED 0

@interface GLArticlesViewController () <GLArticleViewDelegate, NYTPhotosViewControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, VLDContextSheetDelegate, MFMailComposeViewControllerDelegate, GLPromptViewDelegate>

@property (nonatomic) DGActivityIndicatorView *activityIndicatorView;
@property (nonatomic) GLScrollView *scrollView;
@property (nonatomic) GLPromptView *promptView;
@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) NSMutableArray *articles;
@property (nonatomic) NSMutableArray *articleViews;
@property (nonatomic) NSString *language;
@property (nonatomic) NSUInteger currentArticleIndex;
@property (nonatomic) UILabel *completedMessageLabel;
@property (nonatomic) UILabel *completedTitleLabel;
@property (nonatomic) UIView *completedView;
@property (nonatomic) VLDContextSheet *contextSheet;
@property (nonatomic, getter=isLoadingArticles) BOOL loadingArticles;
@property (weak, nonatomic) GLArticleView *currentArticleView;

@end

@implementation GLArticlesViewController

#pragma mark Initialization

- (instancetype)initWithType:(GLArticlesViewType)type {
    return [self initWithType:type currentArticleIndex:NSNotFound];
}

- (instancetype)initWithType:(GLArticlesViewType)type currentArticleIndex:(NSUInteger)currentArticleIndex {
    self = [super init];
    if (!self) return nil;
    
    _type = type;
    _currentArticleIndex = currentArticleIndex;
    
    return self;
}

+ (GLArticlesViewController *)sharedRandomArticlesViewController {
    static GLArticlesViewController *sharedRandomArticlesViewController = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedRandomArticlesViewController = [[GLArticlesViewController alloc] initWithType:GLArticlesViewTypeRandom];
    });
    return sharedRandomArticlesViewController;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self setUpScrollView];
    [[self updateLanguage] subscribeNext:^(NSNumber *updated) {
        if ([updated boolValue]) {
            DDLogVerbose(@"Updated language in articles view");
        }
    }];
#if LONG_PRESS_SHARING_ENABLED
    [self setUpContextSheet];
#endif
    if (self.type == GLArticlesViewTypeRandom) {
        [GLPromptView incrementUsesForCurrentVersion];
        [self setUpPromptView];
        @weakify(self)
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] subscribeNext:^(id x) {
            @strongify(self)
            [GLPromptView incrementUsesForCurrentVersion];
            DDLogVerbose(@"Checking for prompt view");
            [self setUpPromptView];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.activityIndicatorView) {
        [self.activityIndicatorView startAnimating];
    }
}

#pragma mark Public

- (RACSignal *)updateLanguage {
    NSString *newLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"language"];
    if (![newLanguage isEqualToString:self.language]) {
        self.language = newLanguage;
        [self setUpArticleViews];
        return [RACSignal return:@YES];
    } else {
        return [RACSignal return:@NO];
    }
}

- (RACSignal *)reset {
    [self setUpArticleViews];
    return [RACSignal empty];
}

#pragma mark Private

- (void)setUpScrollView {
    self.scrollView = [[GLScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.clipsToBounds = YES;
    [self.view addSubview:self.scrollView];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self.scrollView addGestureRecognizer:doubleTapGestureRecognizer];
}

- (void)setUpActivityIndicatorView {
    if (!self.activityIndicatorView) {
        self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotate tintColor:[UIColor gl_darkGrayColor] size:50];
        self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:self.activityIndicatorView];
    }
    self.activityIndicatorView.frame = CGRectMake(self.articleViews.count * self.scrollView.width, 0, self.scrollView.width, self.scrollView.height);
}

- (void)setUpCompletedView {
    self.completedView = [UIView new];
    [self.scrollView addSubview:self.completedView];
    
    self.completedTitleLabel = [UILabel new];
    self.completedTitleLabel.font = [UIFont systemFontOfSize:70];
    self.completedTitleLabel.text = @"😎";
    [self.completedTitleLabel sizeToFit];
    [self.completedView addSubview:self.completedTitleLabel];
    
    self.completedMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.completedTitleLabel.bottom + kCompletedLabelsSpacing, self.scrollView.width - kArticlesViewPadding.left - kArticlesViewPadding.right, 0)];
    self.completedMessageLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont mediumTextFontSize]];
    self.completedMessageLabel.textColor = [UIColor gl_darkGrayColor];
    self.completedMessageLabel.text = [NSString localizedStringWithFormat:@"Cool, you've seen all articles we have at the moment for %@. You can reset or change language in Settings.", [GLDataManager descriptionForLanguage:self.language]];
    self.completedMessageLabel.numberOfLines = 0;
    self.completedMessageLabel.textAlignment = NSTextAlignmentCenter;
    [self.completedMessageLabel setFrameToFitWithHeightLimit:0];
    [self.completedView addSubview:self.completedMessageLabel];
    
    self.completedView.frame = CGRectMake(0, 0, self.completedMessageLabel.width, self.completedMessageLabel.bottom);
    self.completedTitleLabel.centerX = self.completedView.width/2;
    self.completedView.center = CGPointMake(self.scrollView.width/2, self.scrollView.height/2);
    self.completedView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
}

- (void)setUpContextSheet {
    VLDContextSheetItem *facebookItem = [[VLDContextSheetItem alloc] initWithTitle:NSLocalizedString(@"Share To Facebook", nil) image:[UIImage imageNamed:@"FacebookIconOutline"] highlightedImage:[UIImage imageNamed:@"FacebookIconFill"]];
    VLDContextSheetItem *twitterItem = [[VLDContextSheetItem alloc] initWithTitle:NSLocalizedString(@"Share To Twitter", nil) image:[UIImage imageNamed:@"TwitterIconOutline"] highlightedImage:[UIImage imageNamed:@"TwitterIconFill"]];
    self.contextSheet = [[VLDContextSheet alloc] initWithItems:@[facebookItem, twitterItem]];
    self.contextSheet.delegate = self;
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(openContextSheet:)];
    longPressGestureRecognizer.minimumPressDuration = 0.25f;
    longPressGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:longPressGestureRecognizer];
}

- (void)setUpArticleViews {
    if (self.articleViews) {
        [self.articleViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    if (self.completedView) {
        [self.completedView removeFromSuperview];
        self.completedView = nil;
    }
    self.articleViews = [NSMutableArray new];
    self.currentArticleView = nil;
    [self updateScrollView];
    switch (self.type) {
        case GLArticlesViewTypeRandom: {
            if (self.currentArticleIndex != NSNotFound) {
                _currentArticleIndex = NSNotFound;
            }
            self.articles = [NSMutableArray new];
            [[self loadArticles] subscribeNext:^(NSArray *articles) {
                DDLogVerbose(@"Loaded %@ new articles", @(articles.count));
            } error:^(NSError *error) {
                UIAlertController *alertController = [UIAlertController new];
                alertController.title = NSLocalizedString(@"Something went wrong", nil);
                alertController.message = NSLocalizedString(@"Please check your internet connection and try again.", ni);
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                DDLogError(@"Error while loading new articles: %@", error);
            }];
        }
            break;
        case GLArticlesViewTypeFavorites: {
            if (self.articles.count > 0) {
                _currentArticleIndex = 0;
            }
            [[[GLDataManager sharedInstance] getFavoriteArticles] subscribeNext:^(NSArray *favoriteArticles) {
                self.articles = [favoriteArticles mutableCopy];
                [self generateArticleViewsForArticles:self.articles];
                [self updateCurrentArticleView];
                [self.scrollView scrollRectToVisible:self.currentArticleView.frame animated:NO];
            }];
        }
            break;
    }
}

- (void)setUpPromptView {
#ifdef SNAPSHOT
    return;
#endif
    if (!self.promptView) {
        if ([[GLPromptView numberOfUsesForCurrentVersion] integerValue] == kUsesBeforePrompt) {
            self.promptView = [[GLPromptView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
            self.promptView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
            self.promptView.delegate = self;
            self.promptView.backgroundColor = [UIColor gl_primaryColor];
            self.promptView.top = self.view.height;
            [self.view addSubview:self.promptView];
            [self performSelector:@selector(slideInFromBottom:) withObject:self.promptView afterDelay:1];
        }
    }
}

- (RACSignal *)loadArticles {
    if (self.isLoadingArticles) {
        return [RACSignal empty];
    } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            self.loadingArticles = YES;
            [[[[GLDataManager sharedInstance] getNextArticles]
                deliverOn:RACScheduler.mainThreadScheduler]
                subscribeNext:^(RACTuple *tuple) {
                    RACTupleUnpack(NSNumber *completed, NSArray *articles) = tuple;
                    if ([completed boolValue]) {
                        [self.activityIndicatorView removeFromSuperview];
                        self.activityIndicatorView = nil;
                        [self setUpCompletedView];
                        self.loadingArticles = NO;
                    } else {
                        articles = [articles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(SELF IN %@)", self.articles]];
                        [self.articles addObjectsFromArray:articles];
                        [self generateArticleViewsForArticles:articles];
                        if (self.currentArticleIndex == NSNotFound) {
                            self.currentArticleIndex = 0;
                        }
#ifndef SNAPSHOT
                        BOOL seenHelp = [[NSUserDefaults standardUserDefaults] boolForKey:kSeenHelpKey];
                        if (!seenHelp) {
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenHelpKey];
                            GLHelpView *helpView = [[GLHelpView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                            [[[UIApplication sharedApplication] delegate].window addSubview:helpView];
                            [helpView tapWithLabelText:NSLocalizedString(@"Double tap to open the menu", ni) labelPoint:CGPointMake(self.view.centerX, self.view.centerY + 70) touchPoint:self.view.center dismissHandler:^{
                                [helpView swipeWithLabelText:NSLocalizedString(@"Swipe to scroll through articles", nil) labelPoint:CGPointMake(self.view.centerX, self.view.centerY + 70) touchStartPoint:CGPointMake(self.view.centerX + 25, self.view.centerY) touchEndPoint:CGPointMake(self.view.centerX - 25, self.view.centerY) dismissHandler:^{
                                    [helpView swipeWithLabelText:NSLocalizedString(@"Pull up to read the article on Wikipedia", nil) labelPoint:CGPointMake(self.view.centerX, self.view.centerY + 70) touchStartPoint:self.view.center touchEndPoint:CGPointMake(self.view.centerX, self.view.centerY - 50) dismissHandler:nil hideOnDismiss:YES];
                                } hideOnDismiss:NO];
                            } doubleTap:YES hideOnDismiss:NO];
                        }
#endif
                        self.loadingArticles = NO;
                        [subscriber sendNext:articles];
                        [subscriber sendCompleted];
                    }
                } error:^(NSError *error) {
                    self.loadingArticles = NO;
                    [subscriber sendError:error];
                }];
            return nil;
        }];
    }
}

- (void)generateArticleViewsForArticles:(NSArray *)articles {
    [articles enumerateObjectsUsingBlock:^(GLArticle *article, NSUInteger idx, BOOL *stop) {
        GLArticleView *articleView = [[GLArticleView alloc] initWithArticle:article frame:CGRectMake([self.articles indexOfObject:article] * self.scrollView.width, 0, self.scrollView.width, self.scrollView.height)];
        articleView.contentDelegate = self;
        [self.scrollView addSubview:articleView];
        [self.articleViews addObject:articleView];
        __weak typeof(self) weakSelf = self;
        GLPullForActionView *pullForActionView = [[GLPullForActionView alloc] initWithArticleView:articleView callback:^{
            [weakSelf openUrl:articleView.article.publicUrl];
        }];
        [articleView addSubview:pullForActionView];
    }];
    [self updateScrollView];
}

- (void)popArticles:(NSUInteger)toPop {
    DDLogVerbose(@"Popping %@ article%@", @(toPop), toPop > 1 ? @"s" : @"");
    NSRange range = NSMakeRange(0, toPop);
    [self.articles removeObjectsInRange:range];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.articleViews removeObjectsInRange:range];
    [self.articleViews enumerateObjectsUsingBlock:^(GLArticleView *articleView, NSUInteger idx, BOOL *stop) {
        articleView.left = [self.articleViews indexOfObject:articleView] * self.scrollView.width;
        [self.scrollView addSubview:articleView];
    }];
    _currentArticleIndex -= toPop;
    [self updateScrollView];
}

- (void)updateScrollView {
    if (self.type == GLArticlesViewTypeRandom) {
        [self setUpActivityIndicatorView];
        self.scrollView.contentSize = CGSizeMake((self.articleViews.count + 1) * self.scrollView.width, self.scrollView.height);
    } else {
        self.scrollView.contentSize = CGSizeMake(self.articleViews.count * self.scrollView.width, self.scrollView.height);
    }
    self.scrollView.contentOffset = CGPointMake(self.currentArticleView ? self.currentArticleView.left : 0, 0);
}

- (void)updateCurrentArticleView {
    self.currentArticleView = self.articleViews[self.currentArticleIndex];
    if (!self.currentArticleView.isLoading && !self.currentArticleView.isLoaded) {
        [[self.currentArticleView loadImages] subscribeNext:^(NSNumber *loaded) {
            if ([loaded boolValue]) {
                DDLogVerbose(@"Loaded images for article %@", self.currentArticleView.article.title);
            }            
        }];
    }
}

- (void)showMenu {
    GLMenuViewController *menuViewController;
    if (self.currentArticleView) {
        menuViewController = [[GLMenuViewController alloc] initWithArticlesViewController:self article:self.currentArticleView.article];
    } else if (self.completedView) {
        menuViewController = [[GLMenuViewController alloc] initWithArticlesViewController:self];
    }
    if (menuViewController) {
        [menuViewController show];
    }
}

- (void)openContextSheet:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.contextSheet startWithGestureRecognizer:gestureRecognizer inView:self.view];
    }
}

- (void)openUrl:(NSURL *)url {
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:safariViewController animated:YES completion:nil];
}

#pragma mark Setters

- (void)setCurrentArticleIndex:(NSUInteger)currentArticleIndex {
    BOOL goingForward = currentArticleIndex > self.currentArticleIndex;
    if (self.currentArticleIndex != currentArticleIndex && currentArticleIndex < self.articles.count) {
        _currentArticleIndex = currentArticleIndex;
        [self updateCurrentArticleView];
        if (self.type == GLArticlesViewTypeRandom) {
            GLArticle *article = self.currentArticleView.article;
            [[[GLDataManager sharedInstance] archiveArticle:article] subscribeNext:^(NSNumber *archived) {
                if ([archived boolValue]) {
                    DDLogVerbose(@"Archived article %@", article.title);
                }                
            }];
        }
    }
    if (self.type == GLArticlesViewTypeRandom) {
        if (goingForward && self.currentArticleIndex > kMaxNumberOfArticlesToGoBack) {
            [self popArticles:1];
        }
        if (self.articles.count - self.currentArticleIndex - 1 < kMinNumberOfArticlesToGoForward) {
            [[self loadArticles] subscribeNext:^(NSArray *articles) {
                DDLogVerbose(@"Loaded %@ new articles", @(articles.count));
            } error:^(NSError *error) {
                DDLogError(@"Error while loading new articles: %@", error);
            }];
        }
    }
}

#pragma mark GLArticleViewDelegate

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id <NYTPhoto>)photo {
    return self.currentArticleView.imageView;
}

- (void)openGalleryWithPictures:(NSArray *)pictures {
    NYTPhotosViewController *galleryViewController = [[NYTPhotosViewController alloc] initWithPhotos:pictures];
    galleryViewController.delegate = self;
    [self presentViewController:galleryViewController animated:YES completion:nil];
    [pictures enumerateObjectsUsingBlock:^(GLPicture *picture, NSUInteger idx, BOOL *stop) {
        [[picture getImage] subscribeCompleted:^{
            [galleryViewController updateImageForPhoto:picture];
        }];
    }];
}

- (NSDictionary *)photosViewController:(NYTPhotosViewController *)photosViewController overlayTitleTextAttributesForPhoto:(id <NYTPhoto>)photo {
    return @{ NSForegroundColorAttributeName: [UIColor blackColor] };
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentArticleIndex = self.scrollView.currentPage;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.currentArticleIndex = self.scrollView.currentPage;
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark VLDContextSheetDelegate

- (void)contextSheet:(VLDContextSheet *)contextSheet didSelectItem:(VLDContextSheetItem *)item {
    [[[self.currentArticleView.article getSharingViewWithSize:kSharingArticleViewSize forDisplay:NO]
        deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(UIView *sharingView) {
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:[item.title isEqualToString:NSLocalizedString(@"Share To Facebook", nil)] ? SLServiceTypeFacebook : SLServiceTypeTwitter];
            [composeViewController setInitialText:[self.currentArticleView.article.title stringByAppendingString:@" #galileoapp"]];
            [composeViewController addImage:[UIImage convertViewToImage:sharingView]];
            [composeViewController addURL:self.currentArticleView.article.publicUrl];
            [self presentViewController:composeViewController animated:YES completion:nil];
        }];
}

#pragma mark MTPromptViewDelegate

- (void)promptForReview {
    [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
        [self.promptView removeFromSuperview];
        [AYAppStore openAppStoreReview];
    }];
}

- (void)promptForFeedback {
    [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
        [self.promptView removeFromSuperview];
        if ([MFMailComposeViewController canSendMail]) {
            AYFeedback *feedback = [AYFeedback new];
            self.mailComposeViewController = [MFMailComposeViewController new];
            self.mailComposeViewController.mailComposeDelegate = self;
            self.mailComposeViewController.toRecipients = @[@"ayan.yenb@gmail.com"];
            self.mailComposeViewController.subject = feedback.subject;
            [self.mailComposeViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
            [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
        } else {
            UIAlertController *alertController = [UIAlertController new];
            alertController.title = NSLocalizedString(@"Configure your mail service and try again through the About menu", nil);
            alertController.message = NSLocalizedString(@"You need a configured mail account in order to send us an email.", nil);
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)promptClose {
    [self slideOutToBottom:self.promptView completion:^(BOOL completed) {
        [self.promptView removeFromSuperview];
    }];
}

- (void)slideInFromBottom:(UIView *)view {
    [UIView animateWithDuration:0.3f animations:^{
        view.top -= view.height;
    } completion:nil];
}

- (void)slideOutToBottom:(UIView *)view completion:(void(^)(BOOL completed))completion {
    [UIView animateWithDuration:0.3f animations:^{
        view.top += view.height;
    } completion:completion];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultSent) {
            UIAlertController *alertController = [UIAlertController new];
            alertController.title = NSLocalizedString(@"Thank you!", nil);
            alertController.message = NSLocalizedString(@"We will try to contact you as soon as possible.", nil);
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

@end
