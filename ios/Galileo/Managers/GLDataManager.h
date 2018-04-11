#import "GLArticle.h"

@interface GLDataManager : NSObject

#pragma mark Methods

+ (GLDataManager *)sharedInstance;
- (RACSignal *)updateLanguage;
- (RACSignal *)getNextArticles;
- (RACSignal *)getFavoriteArticles;
- (RACSignal *)getPictureForTitle:(NSString *)pictureTitle;
- (RACSignal *)getPicturesForArticle:(GLArticle *)article;
- (RACSignal *)getNumberOfFeaturedArticlesForLanguage:(NSString *)language;
- (RACSignal *)archiveArticle:(GLArticle *)article;
- (RACSignal *)favoriteArticle:(GLArticle *)article;
- (RACSignal *)getEnArticlesStorage;
- (RACSignal *)getRuArticlesStorage;
- (RACSignal *)getCurrentArticlesStorage;
+ (NSString *)descriptionForLanguage:(NSString *)language;
+ (void)resetForCurrentLanguageWithViewController:(UIViewController *)viewController cancelHandler:(void (^)(UIAlertAction *action))cancelHandler;

@end
