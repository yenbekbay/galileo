//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

#import "VLDContextSheet.h"

#import "VLDContextSheetItemView.h"

typedef struct {
    CGRect rect;
    CGFloat rotation;
} VLDZone;

static const NSInteger VLDMaxTouchDistanceAllowance = 40;
static const NSInteger VLDZonesCount = 10;

static inline VLDZone VLDZoneMake(CGRect rect, CGFloat rotation) {
    VLDZone zone;
    zone.rect = rect;
    zone.rotation = rotation;
    return zone;
}

static CGFloat VLDVectorDotProduct(CGPoint vector1, CGPoint vector2) {
    return vector1.x * vector2.x + vector1.y * vector2.y;
}

static CGFloat VLDVectorLength(CGPoint vector) {
    return (CGFloat)sqrt(vector.x * vector.x + vector.y * vector.y);
}

static CGRect VLDOrientedScreenBounds() {
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && bounds.size.width < bounds.size.height) {
        bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
    }
    
    return bounds;
}

@interface VLDContextSheet ()

@property (nonatomic) NSArray *itemViews;
@property (nonatomic) UIView *centerView;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) VLDContextSheetItemView *selectedItemView;
@property (nonatomic) BOOL openAnimationFinished;
@property (nonatomic) CGPoint touchCenter;
@property (nonatomic) UIGestureRecognizer *starterGestureRecognizer;

@end

@implementation VLDContextSheet {
    VLDZone zones[VLDZonesCount];
}

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithItems:nil];
}

- (instancetype)initWithItems:(NSArray *)items {
    self = [super initWithFrame:VLDOrientedScreenBounds()];
    if (!self) return nil;

    _items = items;
    _radius = 100;
    _rangeAngle = (CGFloat)(M_PI / 1.6f);
    [self createSubviews];
    
    return self;
}

#pragma mark Lifecycle

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundView.frame = self.bounds;
}

- (void)dealloc {
    [self.starterGestureRecognizer removeTarget:self action:@selector(gestureRecognizedStateObserver:)];
}

#pragma mark Public

- (void)startWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)view {
    [view addSubview:self];
    
    self.frame = VLDOrientedScreenBounds();
    [self createZones];
    self.starterGestureRecognizer = gestureRecognizer;
    
    self.touchCenter = [self.starterGestureRecognizer locationInView:self];
    self.centerView.center = self.touchCenter;
    self.selectedItemView = nil;
    [self setCenterViewHighlighted:YES];
    self.rotation = [self rotationForCenter:self.centerView.center];
    
    [self openItemsFromCenterView];
    [self.starterGestureRecognizer addTarget:self action:@selector(gestureRecognizedStateObserver:)];
}

- (void)end {
    [self.starterGestureRecognizer removeTarget:self action:@selector(gestureRecognizedStateObserver:)];
    if (self.selectedItemView && self.selectedItemView.isHighlighted) {
        [self.delegate contextSheet:self didSelectItem:self.selectedItemView.item];
    }
    [self closeItemsToCenterView];
}

#pragma mark Private

- (void)createSubviews {
    _backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6f];
    [self addSubview:self.backgroundView];
    
    _itemViews = [NSMutableArray new];
    
    for (VLDContextSheetItem *item in _items) {
        VLDContextSheetItemView *itemView = [VLDContextSheetItemView new];
        itemView.item = item;
        
        [self addSubview:itemView];
        [(NSMutableArray *)_itemViews addObject:itemView];
    }
    
    VLDContextSheetItemView *sampleItemView = _itemViews[0];
    
    _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sampleItemView.frame.size.width, sampleItemView.frame.size.width)];
    _centerView.layer.cornerRadius = 25;
    _centerView.layer.borderWidth = 2;
    _centerView.layer.borderColor = [UIColor grayColor].CGColor;
    [self addSubview:_centerView];
}

- (void)setCenterViewHighlighted:(BOOL)highlighted {
    _centerView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.5f alpha:0.4f] :nil;
}

- (void)createZones {
    CGRect screenRect = self.bounds;
    CGFloat rowHeight1 = 120;
    
    zones[0] = VLDZoneMake(CGRectMake(0, 0, 70, rowHeight1), 0.8f);
    zones[1] = VLDZoneMake(CGRectMake(zones[0].rect.size.width, 0, 40, rowHeight1), 0.4f);
    
    zones[2] = VLDZoneMake(CGRectMake(zones[1].rect.origin.x + zones[1].rect.size.width, 0, screenRect.size.width - 2 *(zones[0].rect.size.width + zones[1].rect.size.width), rowHeight1), 0);
    
    zones[3] = VLDZoneMake(CGRectMake(zones[2].rect.origin.x + zones[2].rect.size.width, 0, zones[1].rect.size.width, rowHeight1),  -zones[1].rotation);
    zones[4] = VLDZoneMake(CGRectMake(zones[3].rect.origin.x + zones[3].rect.size.width, 0, zones[0].rect.size.width, rowHeight1), -zones[0].rotation);
    
    CGFloat rowHeight2 = screenRect.size.height - zones[0].rect.size.height;
    
    zones[5] = VLDZoneMake(CGRectMake(0, zones[0].rect.size.height, zones[0].rect.size.width, rowHeight2),(CGFloat)(M_PI - zones[0].rotation));
    zones[6] = VLDZoneMake(CGRectMake(zones[5].rect.size.width, zones[5].rect.origin.y, zones[1].rect.size.width, rowHeight2), (CGFloat)(M_PI - zones[1].rotation));
    zones[7] = VLDZoneMake(CGRectMake(zones[6].rect.origin.x + zones[6].rect.size.width, zones[5].rect.origin.y, zones[2].rect.size.width, rowHeight2), (CGFloat)(M_PI - zones[2].rotation));
    zones[8] = VLDZoneMake(CGRectMake(zones[7].rect.origin.x + zones[7].rect.size.width, zones[5].rect.origin.y, zones[3].rect.size.width, rowHeight2), (CGFloat)(M_PI - zones[3].rotation));
    zones[9] = VLDZoneMake(CGRectMake(zones[8].rect.origin.x + zones[8].rect.size.width, zones[5].rect.origin.y, zones[4].rect.size.width, rowHeight2), (CGFloat)(M_PI - zones[4].rotation));
}

/* Only used for testing the touch zones */
- (void)drawZones {
    for (NSUInteger i = 0; i < VLDZonesCount; i++) {
        UIView *zoneView = [[UIView alloc] initWithFrame:zones[i].rect];

        CGFloat hue = (arc4random() % 256 / 256.f);
        CGFloat saturation = (arc4random() % 128 / 256.f) + 0.5f;
        CGFloat brightness = (arc4random() % 128 / 256.f) + 0.5f;
        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
        
        zoneView.backgroundColor = color;
        [self addSubview:zoneView];
    }
}

- (void)updateItemView:(UIView *)itemView touchDistance:(CGFloat)touchDistance animated:(BOOL)animated  {
    if (!animated) {
        [self updateItemViewNotAnimated:itemView touchDistance:touchDistance];
    } else  {
        [UIView animateWithDuration:0.4f delay:0
             usingSpringWithDamping:0.45f initialSpringVelocity:7.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self updateItemViewNotAnimated:itemView
                                               touchDistance:touchDistance];
                         } completion:nil];
    }
}

- (void)updateItemViewNotAnimated:(UIView *)itemView touchDistance:(CGFloat)touchDistance  {
    NSUInteger itemIndex = [self.itemViews indexOfObject:itemView];
    CGFloat angle = -0.65f + self.rotation + itemIndex * (self.rangeAngle / self.itemViews.count);
    
    CGFloat resistanceFactor = 1.f / (touchDistance > 0 ? 6 :3);
    
    itemView.center = CGPointMake((CGFloat)(self.touchCenter.x + (self.radius + touchDistance * resistanceFactor) * sin(angle)),
                                  (CGFloat)(self.touchCenter.y + (self.radius + touchDistance * resistanceFactor) * cos(angle)));
    
    CGFloat scale = (CGFloat)(1 + 0.2f * (fabs(touchDistance) / self.radius));
    itemView.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)openItemsFromCenterView {
    self.openAnimationFinished = NO;
    for (NSUInteger i = 0; i < self.itemViews.count; i++) {
        VLDContextSheetItemView *itemView = self.itemViews[i];
        itemView.transform = CGAffineTransformIdentity;
        itemView.center = self.touchCenter;
        [itemView setHighlighted:NO animated:NO];
        
        [UIView animateWithDuration:0.5f delay:i * 0.01f
             usingSpringWithDamping:0.45f initialSpringVelocity:7.5f
                            options:0 animations:^{
                             [self updateItemViewNotAnimated:itemView touchDistance:0];
                         } completion:^(BOOL finished) {
                             self.openAnimationFinished = YES;
                         }];
    }
}

- (void)closeItemsToCenterView {
    [UIView animateWithDuration:0.1f delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         self.alpha = 1;
                     }];
}

- (CGFloat)rotationForCenter:(CGPoint)center {
    for (NSInteger i = 0; i < 10; i++) {
        VLDZone zone = zones[i];
        if (CGRectContainsPoint(zone.rect, center)) {
            return zone.rotation;
        }
    }
    
    return 0;
}

- (void)gestureRecognizedStateObserver:(UIGestureRecognizer *)gestureRecognizer {
    if (self.openAnimationFinished && gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self];
        [self updateItemViewsForTouchPoint:touchPoint];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            self.selectedItemView = nil;
        }
        [self end];
    }
}

- (CGFloat) signedTouchDistanceForTouchVector:(CGPoint)touchVector itemView:(UIView *)itemView {
    CGFloat touchDistance = VLDVectorLength(touchVector);
    
    CGPoint oldCenter = itemView.center;
    CGAffineTransform oldTransform = itemView.transform;
    
    [self updateItemViewNotAnimated:itemView touchDistance:self.radius + 40];
    
    if (!CGRectContainsRect(self.bounds, itemView.frame)) {
        touchDistance = -touchDistance;
    }
    
    itemView.center = oldCenter;
    itemView.transform = oldTransform;
    
    return touchDistance;
}

- (void)updateItemViewsForTouchPoint:(CGPoint)touchPoint {
    CGPoint touchVector = {touchPoint.x - self.touchCenter.x, touchPoint.y - self.touchCenter.y};
    VLDContextSheetItemView *itemView = [self itemViewForTouchVector:touchVector];
    CGFloat touchDistance = [self signedTouchDistanceForTouchVector:touchVector itemView:itemView];
    
    if (fabs(touchDistance) <= VLDMaxTouchDistanceAllowance) {
        self.centerView.center = CGPointMake(self.touchCenter.x + touchVector.x, self.touchCenter.y + touchVector.y);
        [self setCenterViewHighlighted:YES];
    } else {
        [self setCenterViewHighlighted:NO];
        [UIView animateWithDuration:0.4f delay:0
             usingSpringWithDamping:0.35f initialSpringVelocity:7.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.centerView.center = self.touchCenter;
                         } completion:nil];
    }
    
    if (touchDistance > self.radius + VLDMaxTouchDistanceAllowance) {
        [itemView setHighlighted:NO animated:YES];
        [self updateItemView:itemView touchDistance:0 animated:YES];
        self.selectedItemView = nil;
        
        return;
    }
    
    if (itemView != self.selectedItemView) {
        [self.selectedItemView setHighlighted:NO animated:YES];
        [self updateItemView:self.selectedItemView touchDistance:0 animated:YES];
        [self updateItemView:itemView touchDistance:touchDistance animated:YES];
        [self bringSubviewToFront:itemView];
    } else  {
        [self updateItemView:itemView touchDistance:touchDistance animated:NO];
    }
    
    if (fabs(touchDistance) > VLDMaxTouchDistanceAllowance) {
        [itemView setHighlighted:YES animated:YES];
    }
    
    self.selectedItemView = itemView;
}

- (VLDContextSheetItemView *)itemViewForTouchVector:(CGPoint)touchVector  {
    CGFloat maxCosOfAngle = -2;
    VLDContextSheetItemView *resultItemView = nil;
    
    for (NSUInteger i = 0; i < self.itemViews.count; i++) {
        VLDContextSheetItemView *itemView = self.itemViews[i];
        CGPoint itemViewVector = {
            itemView.center.x - self.touchCenter.x,
            itemView.center.y - self.touchCenter.y
        };
        
        CGFloat cosOfAngle = VLDVectorDotProduct(itemViewVector, touchVector) / VLDVectorLength(itemViewVector);
        
        if (cosOfAngle > maxCosOfAngle) {
            maxCosOfAngle = cosOfAngle;
            resultItemView = itemView;
        }
    }

    return resultItemView;
}

@end
