@protocol GLPromptViewDelegate <NSObject>

- (void)promptForReview;
- (void)promptForFeedback;
- (void)promptClose;

@end

@interface GLPromptView : UIView

#pragma mark Properties

@property (weak) id<GLPromptViewDelegate> delegate;

#pragma mark Methods

+ (NSNumber *)numberOfUsesForCurrentVersion;
+ (void)incrementUsesForCurrentVersion;

@end
