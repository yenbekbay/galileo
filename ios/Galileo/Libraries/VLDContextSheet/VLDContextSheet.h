//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

@class VLDContextSheet;
@class VLDContextSheetItem;

@protocol VLDContextSheetDelegate <NSObject>
- (void)contextSheet:(VLDContextSheet *)contextSheet didSelectItem:(VLDContextSheetItem *)item;
@end

@interface VLDContextSheet : UIView

#pragma mark Properties

@property (nonatomic) NSInteger radius;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) CGFloat rangeAngle;
@property (nonatomic) NSArray *items;
@property (nonatomic) id<VLDContextSheetDelegate> delegate;

#pragma mark Methods

- (instancetype)initWithItems:(NSArray *)items;
- (void)startWithGestureRecognizer:(UIGestureRecognizer *) gestureRecognizer inView:(UIView *)view;
- (void)end;

@end
