typedef void (^GLHelpViewDismissHandler)(void);

@interface GLHelpView : UIView

- (void)tapWithLabelText:(NSString *)labelText labelPoint:(CGPoint)labelPoint touchPoint:(CGPoint)touchPoint dismissHandler:(GLHelpViewDismissHandler)dismissHandler doubleTap:(BOOL)doubleTap hideOnDismiss:(BOOL)hideOnDismiss;
- (void)swipeWithLabelText:(NSString *)labelText labelPoint:(CGPoint)labelPoint touchStartPoint:(CGPoint)touchStartPoint touchEndPoint:(CGPoint)touchEndPoint dismissHandler:(GLHelpViewDismissHandler)dismissHandler hideOnDismiss:(BOOL)hideOnDismiss;

@end
