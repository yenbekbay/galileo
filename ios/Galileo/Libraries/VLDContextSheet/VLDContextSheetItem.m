//
//  Copyright (c) 2014 Vladimir Angelov, 2015 Ayan Yenbekbay.
//

#import "VLDContextSheetItem.h"

@implementation VLDContextSheetItem

#pragma mark Initialization

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    self = [super init];
    if (!self) return nil;

    _title = title;
    _image = image;
    _highlightedImage = highlightedImage;
    _enabled = YES;
    
    return self;
}

@end
