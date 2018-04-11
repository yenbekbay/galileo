//
//  Copyright (c) 2013 VG, 2015 Ayan Yenbekbay.
//

typedef NS_ENUM(NSInteger, VGParallaxHeaderMode) {
    VGParallaxHeaderModeCenter = 0,
    VGParallaxHeaderModeFill,
    VGParallaxHeaderModeTop,
    VGParallaxHeaderModeTopFill,
};

typedef NS_ENUM(NSInteger, VGParallaxHeaderStickyViewPosition) {
    VGParallaxHeaderStickyViewPositionBottom = 0,
    VGParallaxHeaderStickyViewPositionTop,
};

typedef NS_ENUM(NSInteger, VGParallaxHeaderShadowBehaviour) {
    VGParallaxHeaderShadowBehaviourHidden = 0,
    VGParallaxHeaderShadowBehaviourAppearing,
    VGParallaxHeaderShadowBehaviourDisappearing,
    VGParallaxHeaderShadowBehaviourAlways,
} __deprecated;

@interface VGParallaxHeader : UIView

@property (nonatomic) NSLayoutConstraint *stickyViewHeightConstraint;
@property (nonatomic) UIView *stickyView;
@property (nonatomic) VGParallaxHeaderStickyViewPosition stickyViewPosition;
@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, readonly) VGParallaxHeaderMode mode;
@property (nonatomic, readonly) VGParallaxHeaderShadowBehaviour shadowBehaviour __deprecated;
@property (nonatomic, readonly, getter=isInsideTableView) BOOL insideTableView;

- (void)setStickyView:(UIView *)stickyView withHeight:(CGFloat)height;

@end

@interface UIScrollView (VGParallaxHeader)

@property (nonatomic, strong, readonly) VGParallaxHeader *parallaxHeader;

- (void)setParallaxHeaderView:(UIView *)view mode:(VGParallaxHeaderMode)mode height:(CGFloat)height;

- (void)setParallaxHeaderView:(UIView *)view mode:(VGParallaxHeaderMode)mode height:(CGFloat)height
              shadowBehaviour:(VGParallaxHeaderShadowBehaviour)shadowBehaviour __deprecated_msg("Use sticky view instead of shadow");

- (void)shouldPositionParallaxHeader;

@end
