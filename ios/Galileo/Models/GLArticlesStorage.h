#import "GLArticle.h"
#import <YapDatabase/YapDatabase.h>

typedef enum {
    GLArticlesStateSaved,
    GLArticlesStateArchived,
    GLArticlesStateFavorite
} GLArticlesState;

@interface GLArticlesStorage : NSObject

#pragma mark Properties

@property (nonatomic, readonly) NSString *language;
/**
 *  Articles that have been already viewed by the user.
 */
@property (nonatomic) NSMutableArray *archivedArticles;
/**
 *  Articles that are currently cached and are displayed in the articles view.
 */
@property (nonatomic) NSMutableArray *currentArticles;
/**
 *  Articles that are in the line to be displayed in the articles view.
 */
@property (nonatomic) NSMutableArray *futureArticles;
/**
 *  Articles that are saved for offline usage.
 */
@property (nonatomic) NSMutableArray *savedArticles;
/**
 *  Articles that have been starred by the user.
 */
@property (nonatomic) NSMutableArray *favoriteArticles;
/**
 *  Indicates whether or not the user has seen all articles in this storage.
 */
@property (nonatomic) NSNumber *completed;

#pragma mark Methods

- (instancetype)initWithLanguage:(NSString *)language database:(YapDatabase *)database;
- (NSArray *)unseenArticles:(NSArray *)articles;
- (RACSignal *)restore;
- (RACSignal *)cacheArticles:(NSUInteger)toCache;
- (RACSignal *)saveArticles:(NSArray *)articles;
- (RACSignal *)archiveArticle:(GLArticle *)article;
- (RACSignal *)favoriteArticle:(GLArticle *)article;
- (RACSignal *)getUserProgress;
- (RACSignal *)reset;
- (RACSignal *)isCompleted;
- (RACSignal *)setCompleted;

@end
