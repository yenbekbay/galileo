#import <ReactiveCocoa/ReactiveCocoa.h>

typedef enum {
    GLArticlesViewTypeRandom,
    GLArticlesViewTypeFavorites
} GLArticlesViewType;

@interface GLArticlesViewController : UIViewController

#pragma mark Properties

@property (nonatomic, readonly) GLArticlesViewType type;

#pragma mark Methods

+ (GLArticlesViewController *)sharedRandomArticlesViewController;
- (instancetype)initWithType:(GLArticlesViewType)type;
- (instancetype)initWithType:(GLArticlesViewType)type currentArticleIndex:(NSUInteger)currentArticleIndex;
- (RACSignal *)updateLanguage;
- (RACSignal *)reset;

@end
