//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

@interface VLDContextSheetItem : NSObject

#pragma mark Properties

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) UIImage *highlightedImage;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readwrite, getter=isEnabled) BOOL enabled;

#pragma mark Methods

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage;

@end
