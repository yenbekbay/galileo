#import "GLArticle.h"
@class GLMenuArticleView;

typedef enum {
    GLMenuArticleViewButtonTypeFavorite,
    GLMenuArticleViewButtonTypeShare
} GLMenuArticleViewButtonType;

@protocol GLMenuArticleViewDelegate <NSObject>
@required
- (void)articleView:(GLMenuArticleView *)articleView didTapOnButtonType:(GLMenuArticleViewButtonType)buttonType;
@end

@interface GLMenuArticleView : UIView

#pragma mark Properties

@property (weak, nonatomic) id<GLMenuArticleViewDelegate> delegate;
@property (weak, nonatomic, readonly) GLArticle *article;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame article:(GLArticle *)article;
- (void)updateFavoriteButton;

@end
