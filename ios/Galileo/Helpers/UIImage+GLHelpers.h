@interface UIImage (GLHelpers)

+ (instancetype)imageWithGradientOfSize:(CGSize)size startColor:(UIColor *)startColor endColor:(UIColor *)endColor startPoint:(CGFloat)startPoint endPoint:(CGFloat)endPoint;
+ (instancetype)convertViewToImage:(UIView *)view;
+ (instancetype)mergeImagesFromArray:(NSArray *)imageArray;
- (instancetype)opaque;

@end
