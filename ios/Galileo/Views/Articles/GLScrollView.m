#import "GLScrollView.h"

#import "UIView+AYUtils.h"

@interface GLScrollView ()

@property (nonatomic) CGFloat angleRatio;
@property (nonatomic) CGFloat rotationX;
@property (nonatomic) CGFloat translateX;

@end

@implementation GLScrollView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.pagingEnabled = YES;
    self.clipsToBounds = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    return self;
}

#pragma mark Getters

- (NSUInteger)currentPage {
    CGFloat pageWidth = self.width;
    CGFloat fractionalPage = self.contentOffset.x / pageWidth;
    return (NSUInteger)lround(fractionalPage);
}

#pragma mark Public

- (void)loadNextPage:(BOOL)animated {
    [self loadPageIndex:self.currentPage + 1 animated:animated];
}

- (void)loadPreviousPage:(BOOL)animated {
    [self loadPageIndex:self.currentPage - 1 animated:animated];
}

- (void)loadPageIndex:(NSUInteger)index animated:(BOOL)animated {
    CGRect frame = self.frame;
    frame.origin.x = CGRectGetWidth(frame) * index;
    frame.origin.y = 0;
    
    [self scrollRectToVisible:frame animated:animated];
}

@end
