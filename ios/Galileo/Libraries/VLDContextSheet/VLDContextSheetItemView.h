//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

@class VLDContextSheetItem;

@interface VLDContextSheetItemView : UIView

#pragma mark Properties

@property (nonatomic) VLDContextSheetItem *item;
@property (nonatomic, readonly, getter=isHighlighted) BOOL highlighted;

#pragma mark Methods

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL) animated;

@end
