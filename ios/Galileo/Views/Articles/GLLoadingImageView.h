@interface GLLoadingImageView : UIImageView

#pragma mark Properties

@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UIActivityIndicatorViewStyle spinnerStyle;

#pragma mark Methods

/**
 *  Start animating the activity indicator.
 */
- (void)startSpinning;
/**
 *  Stop animating the activity indicator.
 */
- (void)stopSpinning;

@end
