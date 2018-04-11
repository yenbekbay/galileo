#import "GLStatisticsViewController.h"

#import "GLArticlesStorage.h"
#import "GLDataManager.h"
#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import "UILabel+GLHelpers.h"
#import "UIView+AYUtils.h"
#import <ASProgressPopUpView/ASProgressPopUpView.h>
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>

static UIEdgeInsets const kStatisticsViewPadding = {20, 20, 20, 20};
static CGFloat const kStatisticsViewProgressPopUpViewTopMargin = 50;

@interface GLStatisticsViewController () <ASProgressPopUpViewDataSource>

@property (nonatomic) ASProgressPopUpView *enProgressPopUpView;
@property (nonatomic) ASProgressPopUpView *ruProgressPopUpView;
@property (nonatomic) CGFloat enProgress;
@property (nonatomic) CGFloat ruProgress;
@property (nonatomic) DGActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *enProgressLabel;
@property (nonatomic) UILabel *ruProgressLabel;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation GLStatisticsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Statistics", nil);
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUpScrollView];
    [self setUpActivityIndicatorView];
    [self setUpProgressViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark Private

- (void)setUpScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
}

- (void)setUpActivityIndicatorView {
    self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotate tintColor:[UIColor gl_darkGrayColor] size:50];
    self.activityIndicatorView.frame = self.view.bounds;
    self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

- (void)setUpProgressViews {
    self.enProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(kStatisticsViewPadding.left, kStatisticsViewPadding.top, self.view.width - kStatisticsViewPadding.left - kStatisticsViewPadding.right, 0)];
    [self.scrollView addSubview:self.enProgressLabel];
    
    self.enProgressPopUpView = [[ASProgressPopUpView alloc] initWithFrame:self.enProgressLabel.frame];
    self.enProgressPopUpView.height = 10;
    [self.scrollView addSubview:self.enProgressPopUpView];
    
    self.ruProgressLabel = [[UILabel alloc] initWithFrame:self.enProgressLabel.frame];
    [self.scrollView addSubview:self.ruProgressLabel];
    
    self.ruProgressPopUpView = [[ASProgressPopUpView alloc] initWithFrame:self.enProgressPopUpView.frame];
    [self.scrollView addSubview:self.ruProgressPopUpView];
    
    for (UILabel *label in @[self.enProgressLabel, self.ruProgressLabel]) {
        label.hidden = YES;
        label.numberOfLines = 0;
        label.font = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont mediumTextFontSize]];
        label.textColor = [UIColor gl_darkGrayColor];
    }
    
    for (ASProgressPopUpView *progressPopUpView in @[self.enProgressPopUpView, self.ruProgressPopUpView]) {
        progressPopUpView.hidden = YES;
        progressPopUpView.dataSource = self;
        progressPopUpView.popUpViewColor = [UIColor gl_primaryColor];
        progressPopUpView.font = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont largeTextFontSize]];
    }
    
    self.enProgress = CGFLOAT_MAX;
    self.ruProgress = CGFLOAT_MAX;
    [[[RACSignal merge:@[[self getProgressForEn], [self getProgressForRu]]]
        deliverOn:RACScheduler.mainThreadScheduler]
        subscribeError:^(NSError *error) {
            DDLogError(@"Error while getting progress for articles storage: %@", error);
        } completed:^{
            if (self.enProgress != CGFLOAT_MAX && self.ruProgress != CGFLOAT_MAX) {
                DDLogVerbose(@"Calculated progress for articles storages");
                [self.activityIndicatorView removeFromSuperview];
                [self layoutProgressViews];
                for (UIView *view in @[self.enProgressLabel, self.enProgressPopUpView, self.ruProgressLabel, self.ruProgressPopUpView]) {
                    view.hidden = NO;
                }
                [self.enProgressPopUpView showPopUpViewAnimated:YES];
                [self.ruProgressPopUpView showPopUpViewAnimated:YES];
                [self.enProgressPopUpView setProgress:(float)self.enProgress animated:YES];
                [self.ruProgressPopUpView setProgress:(float)self.ruProgress animated:YES];
            }
        }];
}

- (RACSignal *)getProgressForEn {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[[[GLDataManager sharedInstance] getEnArticlesStorage]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(GLArticlesStorage *enArticlesStorage) {
                [[enArticlesStorage getUserProgress] subscribeNext:^(RACTuple *tuple) {
                    RACTupleUnpack(NSNumber *archivedNumber, NSNumber *totalNumber) = tuple;
#ifdef SNAPSHOT
                    archivedNumber = @((arc4random() % [totalNumber unsignedIntValue] - 50) + 50);
#endif
                    self.enProgressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In English, you have seen %@ featured articles out of %@", nil), archivedNumber, totalNumber];
                    self.enProgress = [archivedNumber floatValue] / [totalNumber floatValue];
                    [subscriber sendCompleted];
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                }];
            }];
        return nil;
    }];
}

- (RACSignal *)getProgressForRu {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[[[GLDataManager sharedInstance] getRuArticlesStorage]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(GLArticlesStorage *ruArticlesStorage) {
                [[ruArticlesStorage getUserProgress] subscribeNext:^(RACTuple *tuple) {
                    RACTupleUnpack(NSNumber *archivedNumber, NSNumber *totalNumber) = tuple;
#ifdef SNAPSHOT
                    archivedNumber = @((arc4random() % [totalNumber unsignedIntValue] - 50) + 50);
#endif
                    self.ruProgressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In Russian, you have seen %@ featured articles out of %@", nil), archivedNumber, totalNumber];
                    self.ruProgress = [archivedNumber floatValue] / [totalNumber floatValue];
                    [subscriber sendCompleted];
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                }];
            }];
        return nil;
    }];
}

- (void)layoutProgressViews {
    self.enProgressLabel.height = [self.enProgressLabel sizeToFitWithHeightLimit:0].height;
    self.enProgressPopUpView.top = self.enProgressLabel.bottom + kStatisticsViewProgressPopUpViewTopMargin;
    self.ruProgressLabel.height = [self.ruProgressLabel sizeToFitWithHeightLimit:0].height;
    self.ruProgressLabel.top = self.enProgressPopUpView.bottom + kStatisticsViewPadding.top;
    self.ruProgressPopUpView.top = self.ruProgressLabel.bottom + kStatisticsViewProgressPopUpViewTopMargin;
}

#pragma mark ASProgressPopUpViewDataSource

- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress {
    return [NSString stringWithFormat:@"%.02f%%", progress * 100];
}

@end
