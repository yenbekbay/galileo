@interface GLTouchView : UIView

#pragma mark Properties

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;

#pragma mark Methods

- (void)addTapAnimation;
- (void)addDoubleTapAnimation;
- (void)addSwipeAnimation;

@end
