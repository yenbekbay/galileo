#import "GLArticlesStorage.h"

#import "GLDataManager.h"
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <SDWebImage/SDImageCache.h>

static NSString * const kArchivedArticlesKey = @"archivedArticles";
static NSString * const kSavedArticlesKey = @"savedArticles";
static NSString * const kFavoriteArticlesKey = @"favoriteArticles";
static NSString * const kCompletedKey = @"completed";
static NSUInteger const kNumberOfImagesToPrefetchConcurrently = 3;

@interface GLArticlesStorage ()

@property (nonatomic) RACSignal *imagesPrefetchingSignal;
@property (nonatomic, getter=isImagesPrefetchingFinished) BOOL imagesPrefetchingFinished;
@property (nonatomic) YapDatabase *database;
@property (nonatomic, getter=isRestored) BOOL restored;

@end

@implementation GLArticlesStorage

#pragma mark Initialization

- (instancetype)initWithLanguage:(NSString *)language database:(YapDatabase *)database {
    self = [super init];
    if (!self) return nil;
    
    _language = language;
    self.database = database;
    
    return self;
}

#pragma mark Public

- (NSArray *)unseenArticles:(NSArray *)articles {
    NSMutableArray *allArchivedArticles = [self.archivedArticles mutableCopy];
    [allArchivedArticles addObjectsFromArray:self.futureArticles];
    allArchivedArticles = [[[NSSet setWithArray:allArchivedArticles] allObjects] mutableCopy];
    return [articles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(SELF IN %@)", allArchivedArticles]];
}

- (RACSignal *)restore {
    if (self.restored) {
        return [RACSignal empty];
    } else {
#ifdef SNAPSHOT
        self.futureArticles = [NSMutableArray new];
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[self reset] subscribeCompleted:^{
                self.restored = YES;
                [subscriber sendCompleted];
            }];
            return nil;
        }];
#else
        return [[self restoreArticlesForState:GLArticlesStateSaved] then:^RACSignal *{
            return [[self restoreArticlesForState:GLArticlesStateArchived] then:^RACSignal *{
                return [self restoreArticlesForState:GLArticlesStateFavorite];
            }];
        }];
#endif
    }
}

- (RACSignal *)cacheArticles:(NSUInteger)toCache {
    NSRange range = NSMakeRange(0, MIN(self.futureArticles.count, toCache));
    self.currentArticles = [[self.futureArticles subarrayWithRange:range] mutableCopy];
    [self.futureArticles removeObjectsInRange:range];
#ifdef SNAPSHOT
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        RACSignal *favoriteArticle = [RACSignal empty];
        for (GLArticle *article in self.currentArticles) {
            favoriteArticle = [favoriteArticle then:^RACSignal *{
                return [self favoriteArticle:article];
            }];
        }
        [favoriteArticle subscribeCompleted:^{
            DDLogVerbose(@"Favorited %@ articles", @(self.currentArticles.count));
            [subscriber sendNext:self.currentArticles];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
#else
    return [RACSignal return:self.currentArticles];
#endif
}

- (RACSignal *)saveArticles:(NSArray *)articles {
    [self.futureArticles addObjectsFromArray:articles];
#ifdef SNAPSHOT
    return [RACSignal empty];
#else
    return [self prefetchImagesForArticles:articles];
#endif
}

- (RACSignal *)archiveArticle:(GLArticle *)article {
    if ([self.archivedArticles indexOfObject:article] == NSNotFound) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [self.archivedArticles addObject:article];
            [self.savedArticles removeObject:article];
            for (GLPicture *picture in article.pictures) {
                [picture removeFromCache];
            }
            YapDatabaseConnection *connection = [self.database newConnection];
            [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:self.archivedArticles forKey:kArchivedArticlesKey inCollection:self.language];
                [transaction setObject:self.savedArticles forKey:kSavedArticlesKey inCollection:self.language];
                [subscriber sendNext:@YES];
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    } else {
        return [RACSignal return:@NO];
    }
}

- (RACSignal *)favoriteArticle:(GLArticle *)article {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        article.favorite = !article.favorite;
        [[article getPagePictureImage] subscribeCompleted:^{
            if (article.favorite) {
                [self.favoriteArticles addObject:article];
            } else {
                [self.favoriteArticles removeObject:article];
            }
            YapDatabaseConnection *connection = [self.database newConnection];
            [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:self.favoriteArticles forKey:kFavoriteArticlesKey inCollection:self.language];
                [subscriber sendCompleted];
            }];
        }];
        return nil;
    }];
}

- (RACSignal *)getUserProgress {
    return [[self restore] then:^{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[[GLDataManager sharedInstance] getNumberOfFeaturedArticlesForLanguage:self.language] subscribeNext:^(NSNumber *number) {
                [subscriber sendNext:RACTuplePack(@(self.archivedArticles.count), number)];
                [subscriber sendCompleted];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            }];
            return nil;
        }];
    }];
}

- (RACSignal *)reset {
    self.archivedArticles = [NSMutableArray new];
    self.favoriteArticles = [NSMutableArray new];
    [[[SDImageCache alloc] initWithNamespace:self.language] clearDisk];
    YapDatabaseConnection *connection = [self.database newConnection];
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:NULL forKey:kArchivedArticlesKey inCollection:self.language];
            [transaction setObject:NULL forKey:kFavoriteArticlesKey inCollection:self.language];
            [transaction setObject:@NO forKey:kCompletedKey inCollection:self.language];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (RACSignal *)isCompleted {
    if (self.completed) {
        return [RACSignal return:self.completed];
    } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            YapDatabaseConnection *connection = [self.database newConnection];
            [connection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
                self.completed = [transaction objectForKey:kCompletedKey inCollection:self.language] ?: @NO;
                [subscriber sendNext:self.completed];
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }
}

- (RACSignal *)setCompleted {
    self.completed = @YES;
    YapDatabaseConnection *connection = [self.database newConnection];
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:self.completed forKey:kCompletedKey inCollection:self.language];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

#pragma mark Private

- (RACSignal *)restoreArticlesForState:(GLArticlesState)state {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        YapDatabaseConnection *connection = [self.database newConnection];
        [connection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            switch (state) {
                case GLArticlesStateSaved: {
                    self.savedArticles = [transaction objectForKey:kSavedArticlesKey inCollection:self.language] ?: [NSMutableArray new];
                    self.futureArticles = self.savedArticles;
                }
                    break;
                case GLArticlesStateArchived:
                    self.archivedArticles = [transaction objectForKey:kArchivedArticlesKey inCollection:self.language] ?: [NSMutableArray new];
                    break;
                case GLArticlesStateFavorite: {
                    self.favoriteArticles = [transaction objectForKey:kFavoriteArticlesKey inCollection:self.language] ?: [NSMutableArray new];
                    self.restored = YES;
                }
                    break;
            }
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (RACSignal *)prefetchImagesForArticles:(NSArray *)articles {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if (!self.imagesPrefetchingSignal || self.isImagesPrefetchingFinished) {
            self.imagesPrefetchingSignal = [RACSignal empty];
            self.imagesPrefetchingFinished = NO;
        }
        for (NSUInteger currentIndex = 0; currentIndex < articles.count; currentIndex += kNumberOfImagesToPrefetchConcurrently) {
            self.imagesPrefetchingSignal = [self.imagesPrefetchingSignal then:^{
                NSMutableArray *processedArticles = [NSMutableArray new];
                [@(kNumberOfImagesToPrefetchConcurrently) timesWithIndex:^(NSUInteger index) {
                    if (currentIndex + index < articles.count) {
                        [processedArticles addObject:articles[currentIndex + index]];
                    }
                }];
                if (processedArticles.count > 0) {
                    return [RACSignal merge:[processedArticles.rac_sequence map:^id(GLArticle *article) {
                        DDLogVerbose(@"Prefetching images for article %@", article.title);
                        return [article getPagePictureImage];
                    }]];
                } else {
                    return [RACSignal empty];
                }
            }];
        }
        [self.imagesPrefetchingSignal subscribeCompleted:^{
            self.imagesPrefetchingFinished = YES;
            NSMutableArray *articlesToSave = [[articles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(SELF IN %@)", self.archivedArticles]] mutableCopy];
            YapDatabaseConnection *connection = [self.database newConnection];
            [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:articlesToSave forKey:kSavedArticlesKey inCollection:self.language];
                [subscriber sendCompleted];
            }];
        }];
        return nil;
    }];
}

@end
