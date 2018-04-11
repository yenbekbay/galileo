//
//  Copyright (c) 2014 Arkadiusz Holko, 2015 Ayan Yenbekbay.
//
//  Original source: https://github.com/Sumi-Interactive/SIAlertView/blob/master/SIAlertView/UIWindow%2BSIUtils.h
//

#import "UIWindow+GLHelpers.h"

@implementation UIWindow (SEAHelpers)

- (UIImage *)snapshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, self.center.x, self.center.y);
    CGContextConcatCTM(context, self.transform);
    CGContextTranslateCTM(context, -CGRectGetWidth(self.bounds) * self.layer.anchorPoint.x, -CGRectGetHeight(self.bounds) * self.layer.anchorPoint.y);
    
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];

    CGContextRestoreGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
