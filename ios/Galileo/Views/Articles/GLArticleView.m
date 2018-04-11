#import "GLArticleView.h"

#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import "UIImage+GLHelpers.h"
#import "UILabel+GLHelpers.h"
#import "UIScrollView+VGParallaxHeader.h"
#import "UIView+AYUtils.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

static UIEdgeInsets const kArticleViewPadding = {20, 20, 20, 20};
static CGFloat const kArticleImageViewHeight = 300;

@interface GLArticleView () <UIScrollViewDelegate>

@property (nonatomic) GLLoadingImageView *imageView;
@property (nonatomic) UIImageView *gradientView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITextView *extractTextView;
@property (nonatomic) UIView *imageViewWrapper;

@end

@implementation GLArticleView

#pragma mark Initialization

- (instancetype)initWithArticle:(GLArticle *)article frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.delegate = self;
    self.alwaysBounceVertical = YES;
    self.showsVerticalScrollIndicator = NO;
    _article = article;
    [self setUpImageViews];
    [self setUpTitleLabel];
    [self setUpExtractTextView];
    self.contentSize = CGSizeMake(self.width, self.extractTextView.bottom + kArticleViewPadding.bottom);
    
    return self;
}

#pragma mark Public

- (RACSignal *)loadImages {
    if (self.loaded || self.loading) {
        return [RACSignal return:@NO];
    } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            self.loading = YES;
            [[[self.article getPagePictureImage]
                deliverOn:RACScheduler.mainThreadScheduler]
                subscribeNext:^(RACTuple *tuple) {
                    RACTupleUnpack(NSNumber *loaded, UIImage *image) = tuple;
                    self.loading = NO;
                    self.loaded = YES;
                    [self.imageView stopSpinning];
                    self.imageView.image = image;
                    [subscriber sendNext:loaded];
                    [subscriber sendCompleted];
                }];
            return nil;
        }];
    }
}

#pragma mark Private

- (void)setUpImageViews {
    self.imageViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, kArticleImageViewHeight)];
    self.imageViewWrapper.backgroundColor = [UIColor blackColor];
    self.imageView = [[GLLoadingImageView alloc] initWithFrame:self.imageViewWrapper.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.accessibilityIdentifier = @"Article View Image";
    [self.imageView startSpinning];
    [self.imageViewWrapper addSubview:self.imageView];
    [self addSubview:self.imageViewWrapper];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openGallery)];
    [self.imageView addGestureRecognizer:tapGestureRecognizer];
    
    self.gradientView = [UIImageView new];
    self.gradientView.image = [UIImage imageWithGradientOfSize:CGSizeMake(self.width, kArticleImageViewHeight) startColor:[UIColor clearColor] endColor:[UIColor colorWithWhite:0 alpha:0.5f] startPoint:0.5f endPoint:1];
    
    [self setParallaxHeaderView:self.imageViewWrapper mode:VGParallaxHeaderModeFill height:kArticleImageViewHeight];
    self.parallaxHeader.stickyViewPosition = VGParallaxHeaderStickyViewPositionBottom;
    [self.parallaxHeader setStickyView:self.gradientView withHeight:kArticleImageViewHeight];
}

- (void)setUpTitleLabel {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kArticleViewPadding.left, 0, self.width - kArticleViewPadding.left - kArticleViewPadding.right, 0)];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont fontWithName:@"Roboto-Black" size:[UIFont articleTitleFontSize]];
    self.titleLabel.text = self.article.title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleLabel adjustFontSize:2 fontFloor:[UIFont largeTextFontSize]];
    self.titleLabel.bottom = -kArticleViewPadding.bottom;
    [self addSubview:self.titleLabel];
}

- (void)setUpExtractTextView {
    self.extractTextView = [[UITextView alloc] initWithFrame:CGRectMake(kArticleViewPadding.left, kArticleViewPadding.top, self.width - kArticleViewPadding.left - kArticleViewPadding.right, 0)];
    self.extractTextView.editable = NO;
    self.extractTextView.textContainerInset = UIEdgeInsetsZero;
    self.extractTextView.textContainer.lineFragmentPadding = 0;
    self.extractTextView.attributedText = self.article.extract;
    [self.extractTextView sizeToFit];
    self.extractTextView.contentSize = self.extractTextView.size;
    [self addSubview:self.extractTextView];
}

- (void)openGallery {
    if (self.isLoaded) {
        [[self.article getPictures] subscribeNext:^(NSArray *pictures) {
            [self.contentDelegate openGalleryWithPictures:pictures];
        } error:^(NSError *error) {
            DDLogError(@"Error while getting pictures for an article: %@", error);
        }];
    }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView shouldPositionParallaxHeader];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.parallaxHeader.progress >= 1.2f) {
        [self openGallery];
    }
}

@end
