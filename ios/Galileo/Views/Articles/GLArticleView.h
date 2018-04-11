#import "GLArticle.h"
#import "GLLoadingImageView.h"

@protocol GLArticleViewDelegate <NSObject>
@required
- (void)openGalleryWithPictures:(NSArray *)pictures;
- (void)openUrl:(NSURL *)url;
@end

@interface GLArticleView : UIScrollView

#pragma mark Properties

@property (nonatomic, getter=isLoaded) BOOL loaded;
@property (nonatomic, getter=isLoading) BOOL loading;
@property (nonatomic, readonly) GLLoadingImageView *imageView;
@property (weak, nonatomic) id<GLArticleViewDelegate> contentDelegate;
@property (weak, nonatomic, readonly) GLArticle *article;

#pragma mark Methods

- (instancetype)initWithArticle:(GLArticle *)article frame:(CGRect)frame;
- (RACSignal *)loadImages;

@end
