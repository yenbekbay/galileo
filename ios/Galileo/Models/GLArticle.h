#import "GLPicture.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

extern CGSize const kSharingArticleViewSize;

@interface GLArticle : NSObject

#pragma mark Properties

@property (copy, nonatomic, readonly) NSString *pagePictureTitle;
@property (copy, nonatomic, readonly) NSString *title;
@property (nonatomic, getter=isFavorite) BOOL favorite;
@property (nonatomic, readonly) NSArray *pictures;
@property (nonatomic, readonly) NSAttributedString *extract;
@property (nonatomic, readonly) NSInteger pageId;
@property (nonatomic, readonly) NSURL *publicUrl;
@property (nonatomic) NSString *language;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (RACSignal *)getPictures;
- (RACSignal *)getPagePictureImage;
- (RACSignal *)getSharingViewWithSize:(CGSize)size forDisplay:(BOOL)forDisplay;

@end
