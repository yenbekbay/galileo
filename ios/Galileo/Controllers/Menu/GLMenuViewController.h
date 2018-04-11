#import "GLArticle.h"
#import "GLArticlesViewController.h"

@interface GLMenuViewController : UIViewController

#pragma mark Properties

@property (weak, nonatomic, readonly) GLArticle *article;

#pragma mark Methods

- (instancetype)initWithArticlesViewController:(GLArticlesViewController *)articlesViewController article:(GLArticle *)article;
- (instancetype)initWithArticlesViewController:(GLArticlesViewController *)articlesViewController;
- (void)show;

@end
