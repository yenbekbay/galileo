#import "UIImage+GLHelpers.h"

@implementation UIImage (GLHelpers)

+ (instancetype)imageWithGradientOfSize:(CGSize)size startColor:(UIColor *)startColor endColor:(UIColor *)endColor startPoint:(CGFloat)startPoint endPoint:(CGFloat)endPoint {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat locations[2] = {startPoint, endPoint};
    CFArrayRef colors = (__bridge CFArrayRef)@[(id)startColor.CGColor, (id)endColor.CGColor];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
    
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0.5f, 0), CGPointMake(0.5f, size.height), kCGGradientDrawsAfterEndLocation);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    
    return image;
}

+ (instancetype)convertViewToImage:(UIView *)view {
    UIImage *capturedScreen;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return capturedScreen;
}

+ (instancetype)mergeImagesFromArray:(NSArray *)imageArray {
    if ([imageArray count] == 0) return nil;
    
    UIImage *exampleImage = imageArray[0];
    CGSize imageSize = exampleImage.size;
    CGSize finalSize = CGSizeMake(imageSize.width, imageSize.height * imageArray.count);
    
    UIGraphicsBeginImageContext(finalSize);
    
    for (UIImage *image in imageArray) {
        [image drawInRect:CGRectMake(0, imageSize.height * [imageArray indexOfObject:image], imageSize.width, imageSize.height)];
    }
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (instancetype)opaque {
    UIImage *finalImage = self;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    if (alpha == kCGImageAlphaPremultipliedLast || alpha == kCGImageAlphaPremultipliedFirst ||
        alpha == kCGImageAlphaLast || alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaOnly) {
        CGContextRef context = CGBitmapContextCreate(NULL, (size_t)self.size.width, (size_t)self.size.height, CGImageGetBitsPerComponent(self.CGImage), CGImageGetBytesPerRow(self.CGImage), CGImageGetColorSpace(self.CGImage), CGImageGetBitmapInfo(self.CGImage));
        
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, self.size.width, self.size.height));
        CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
        CGImageRef resultNoAlpha = CGBitmapContextCreateImage(context);
        
        finalImage = [UIImage imageWithCGImage:resultNoAlpha];
        
        CGImageRelease(resultNoAlpha);
        CGContextRelease(context);
    }
    return finalImage;
}

@end
