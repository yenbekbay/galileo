//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

#import "VLDContextSheetItemView.h"

#import <CoreImage/CoreImage.h>
#import "VLDContextSheetItem.h"
#import "UIView+AYUtils.h"

static const NSInteger VLDTextPadding = 5;

@interface VLDContextSheetItemView ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *highlightedImageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) CGFloat labelWidth;

@end

@implementation VLDContextSheetItemView

@synthesize item = _item;

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame: CGRectMake(0, 0, 50, 83)];
    if (!self) return nil;

    [self createSubviews];
    
    return self;
}

#pragma mark Lifecycle

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0, (self.height - self.width) / 2, self.width, self.width);
    self.highlightedImageView.frame = self.imageView.frame;
    self.label.frame = CGRectMake((self.width - self.labelWidth) / 2, 0, self.labelWidth, 14);
}

#pragma mark Setters

- (void)setItem:(VLDContextSheetItem *)item {
    _item = item;
    [self updateImages];
    [self updateLabelText];
}

#pragma mark Public

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (!self.item.isEnabled) return;
    _highlighted = highlighted;
    
    [UIView animateWithDuration:animated ? 0.3f : 0 delay:0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.highlightedImageView.alpha = (highlighted ? 1 : 0);
                         self.imageView.alpha = 1 - self.highlightedImageView.alpha;
                         self.label.alpha = self.highlightedImageView.alpha;
                     } completion: nil];
}

#pragma mark Private

- (void)createSubviews {
    _imageView = [UIImageView new];
    _imageView.tintColor = [UIColor whiteColor];
    [self addSubview: _imageView];
    
    _highlightedImageView = [UIImageView new];
    _highlightedImageView.tintColor = [UIColor whiteColor];
    _highlightedImageView.alpha = 0;
    [self addSubview: _highlightedImageView];
    
    _label = [[UILabel alloc] init];
    _label.clipsToBounds = YES;
    _label.font = [UIFont systemFontOfSize:10];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.layer.cornerRadius = 7;
    _label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    _label.textColor = [UIColor whiteColor];
    _label.alpha = 0.0;
    [self addSubview: _label];
}

- (void)updateImages {
    self.imageView.image = [self.item.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.highlightedImageView.image = [self.item.highlightedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.alpha = self.item.isEnabled ? 1 : 0.3f;
}

- (void)updateLabelText {
    self.label.text = self.item.title;
    self.labelWidth = 2 * VLDTextPadding + (CGFloat)ceil([self.label.text sizeWithAttributes: @{ NSFontAttributeName: self.label.font }].width);
    [self setNeedsDisplay];
}

@end
