#import "GLDataManager.h"

#import "GLArticlesStorage.h"
#import "GLArticlesViewController.h"
#import "GLPicture.h"
#import "Secrets.h"
#import "UIFont+GLSizes.h"
#import <AFNetworking/AFNetworking.h>
#import <DTCoreText/DTCoreText.h>
#import <HTMLReader/HTMLReader.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <YapDatabase/YapDatabase.h>

static NSString * const kWikipediaApiUrl = @"https://%@.wikipedia.org/w/api.php";
static NSUInteger const kNumberOfArticlesToCache = 10;
static NSUInteger const kNumberOfArticlesToPreload = 50;
static NSUInteger const kMaxNumberOfArticlesToLoadAtOnce = 20;

@interface GLDataManager ()

@property (nonatomic) AFHTTPRequestOperationManager *apiManager;
@property (nonatomic) AFHTTPRequestOperationManager *wikiHtmlManager;
@property (nonatomic) AFHTTPRequestOperationManager *wikiJsonManager;
@property (nonatomic) GLArticlesStorage *enArticlesStorage;
@property (nonatomic) GLArticlesStorage *ruArticlesStorage;
@property (nonatomic) NSString *language;
@property (nonatomic) YapDatabase *database;
@property (weak, nonatomic) GLArticlesStorage *currentArticlesStorage;

@end

@implementation GLDataManager

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.wikiJsonManager = [AFHTTPRequestOperationManager manager];
    self.wikiHtmlManager = [AFHTTPRequestOperationManager manager];
    self.apiManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:kBackendServerUrl]];
    self.wikiHtmlManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    self.wikiHtmlManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    for (AFHTTPRequestOperationManager *manager in @[self.wikiJsonManager, self.wikiHtmlManager, self.apiManager]) {
        manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions);
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = [paths count] > 0 ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    NSString *databasePath = [baseDir stringByAppendingPathComponent:@"mainDatabase.sqlite"];
    self.database = [[YapDatabase alloc] initWithPath:databasePath];
    self.enArticlesStorage = [[GLArticlesStorage alloc] initWithLanguage:@"en" database:self.database];
    self.ruArticlesStorage = [[GLArticlesStorage alloc] initWithLanguage:@"ru" database:self.database];
    [[self updateLanguage] subscribeNext:^(NSNumber *updated) {
        if ([updated boolValue]) {
            DDLogVerbose(@"Updated language in data manager");
        }
    }];
    
    return self;
}

+ (GLDataManager *)sharedInstance {
    static GLDataManager *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [GLDataManager new];
    });
    return sharedInstance;
}

#pragma mark Public

- (RACSignal *)updateLanguage {
    NSString *newLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"language"];
    if (![newLanguage isEqualToString:self.language]) {
        self.language = newLanguage;
        if ([self.language isEqualToString:@"ru"]) {
            self.currentArticlesStorage = self.ruArticlesStorage;
        } else {
            self.currentArticlesStorage = self.enArticlesStorage;
        }
        [[self.currentArticlesStorage restore] subscribeCompleted:^{
            DDLogVerbose(@"Restored articles storage for %@", newLanguage);
        }];
        return [RACSignal return:@YES];
    } else {
        return [RACSignal return:@NO];
    }
}

- (RACSignal *)getNextArticles {
    return [[self getCurrentArticlesStorage] then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            if (self.currentArticlesStorage.futureArticles.count >= kNumberOfArticlesToCache) {
                [[self.currentArticlesStorage cacheArticles:kNumberOfArticlesToCache] subscribeNext:^(NSArray *articles) {
                    [subscriber sendNext:RACTuplePack(@NO, articles)];
                }];
            } else {
                [[self.currentArticlesStorage isCompleted] subscribeNext:^(NSNumber *completed) {
                    if ([completed boolValue]) {
                        [subscriber sendNext:RACTuplePack(@YES, nil)];
                    } else {
                        NSNumber *numberOfArticlesToLoad = @(kNumberOfArticlesToPreload);
#ifdef SNAPSHOT
                        numberOfArticlesToLoad = @10;
#endif
                        [[self loadFeaturedArticles:numberOfArticlesToLoad] subscribeNext:^(NSArray *articles) {
                            NSArray *unseenArticles = [self.currentArticlesStorage unseenArticles:articles];
                            if (unseenArticles.count > 0) {
                                [[self.currentArticlesStorage saveArticles:unseenArticles] subscribeCompleted:^{
                                    DDLogVerbose(@"Saved new articles");
                                }];
                                [[self.currentArticlesStorage cacheArticles:MIN(unseenArticles.count, kNumberOfArticlesToCache)] subscribeCompleted:^{
                                    [subscriber sendNext:RACTuplePack(@NO, self.currentArticlesStorage.currentArticles)];
                                    [subscriber sendCompleted];
                                }];
                            } else if (articles > 0) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIAlertController *alertController = [UIAlertController new];
                                    alertController.title = NSLocalizedString(@"Wow! You rock!", nil);
                                    alertController.message = [NSString localizedStringWithFormat:@"You've seen all articles we have at the moment for %@. You can reset now if you want.", [self.class descriptionForLanguage:self.currentArticlesStorage.language]];
                                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, I'd like to bask in my glory", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                        [subscriber sendNext:RACTuplePack(@YES, nil)];
                                    }]];
                                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yeah, let's do it again!", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                        [self.class resetForCurrentLanguageWithViewController:[GLArticlesViewController sharedRandomArticlesViewController] cancelHandler:^(UIAlertAction *innerAction) {
                                            [subscriber sendNext:RACTuplePack(@YES, nil)];
                                        }];
                                    }]];
                                    [[GLArticlesViewController sharedRandomArticlesViewController] presentViewController:alertController animated:YES completion:nil];
                                });
                            }
                        } error:^(NSError *error) {
                            [subscriber sendError:error];
                        }];
                    }
                }];
            }
            return nil;
        }];
    }];
}

- (RACSignal *)getFavoriteArticles {
    return [[self getCurrentArticlesStorage] then:^RACSignal *{
        return [RACSignal return:self.currentArticlesStorage.favoriteArticles];
    }];
}

- (RACSignal *)getPictureForTitle:(NSString *)pictureTitle {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.wikiJsonManager GET:[NSString stringWithFormat:kWikipediaApiUrl, self.language] parameters:@{
            @"action": @"query",
            @"prop": @"imageinfo",
            @"iiprop": @"url",
            @"titles": [@"File:" stringByAppendingString:pictureTitle],
            @"format": @"json"
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                [(NSDictionary *)responseObject[@"query"][@"pages"] enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *pictureDictionary, BOOL *stop) {
                    if (pictureDictionary[@"imageinfo"]) {
                        GLPicture *picture = [[GLPicture alloc] initWithDictionary:@{
                            @"urls": @[[NSURL URLWithString:pictureDictionary[@"imageinfo"][0][@"url"]]],
                            @"titles": @[pictureTitle]
                        }];
                        picture.cacheNamespace = self.language;
                        [subscriber sendNext:picture];
                        [subscriber sendCompleted];
                    } else {
                        [subscriber sendError:nil];
                    }
                }];
            } else {
                [subscriber sendError:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (RACSignal *)getPicturesForArticle:(GLArticle *)article {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        __block GLPicture *pagePicture;
        [self.wikiHtmlManager GET:[article.publicUrl absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *body = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            HTMLDocument *document = [HTMLDocument documentWithString:body];
            HTMLElement *infobox = [document firstNodeMatchingSelector:@".infobox"];
            if (infobox) {
                [self getImageDataFromThumbElement:infobox completionBlock:^(NSDictionary *imageData) {
                    if (imageData[@"title"] && imageData[@"url"]) {
                        pagePicture = [[GLPicture alloc] initWithDictionary:@{
                            @"urls": @[imageData[@"url"]],
                            @"titles": @[imageData[@"title"]]
                        }];
                    }
                }];
            }
            NSMutableArray *pictures = pagePicture ? [@[pagePicture] mutableCopy] : [NSMutableArray new];
            [[document nodesMatchingSelector:@".thumb"] enumerateObjectsUsingBlock:^(HTMLElement *thumbWrapper, NSUInteger thumbWrapperIdx, BOOL *thumbWrapperStop) {
                if ([thumbWrapper hasClass:@"tmulti"]) {
                    __block NSString *pictureCaption;
                    NSMutableArray *pictureUrls = [NSMutableArray new];
                    NSMutableArray *pictureTitles = [NSMutableArray new];
                    [[thumbWrapper nodesMatchingSelector:@".tsingle"] enumerateObjectsUsingBlock:^(HTMLElement *thumb, NSUInteger thumbIdx, BOOL *thumbStop) {
                        [self getImageDataFromThumbElement:thumb completionBlock:^(NSDictionary *imageData) {
                            if (imageData[@"caption"]) {
                                pictureCaption = imageData[@"caption"];
                            }
                            if (imageData[@"title"] && imageData[@"url"]) {
                                [pictureTitles addObject:imageData[@"title"]];
                                [pictureUrls addObject:imageData[@"url"]];
                            }
                        }];
                    }];
                    if (pictureUrls.count > 0 && pictureTitles.count > 0 && pictureCaption) {
                        GLPicture *picture = [[GLPicture alloc] initWithDictionary:@{
                            @"urls": pictureUrls,
                            @"titles": pictureTitles,
                            @"caption": pictureCaption
                        }];
                        [pictures addObject:picture];
                    }
                } else {
                    [self getImageDataFromThumbElement:thumbWrapper completionBlock:^(NSDictionary *imageData) {
                        if (imageData[@"title"] && imageData[@"url"] && imageData[@"caption"]) {
                            GLPicture *picture = [[GLPicture alloc] initWithDictionary:@{
                                @"urls": @[imageData[@"url"]],
                                @"titles": @[imageData[@"title"]],
                                @"caption": imageData[@"caption"]
                            }];
                            [pictures addObject:picture];
                        }
                    }];
                }
            }];
            for (GLPicture *picture in pictures) {
                picture.cacheNamespace = self.language;
            }
            [subscriber sendNext:pictures];
            [subscriber sendCompleted];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (RACSignal *)getNumberOfFeaturedArticlesForLanguage:(NSString *)language {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.apiManager GET:@"articles/count" parameters:@{
            @"where[lang]": language
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                [subscriber sendNext:[(NSDictionary *)responseObject objectForKey:@"count"]];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (RACSignal *)archiveArticle:(GLArticle *)article {
    return [[self getCurrentArticlesStorage] then:^RACSignal *{
        return [self.currentArticlesStorage archiveArticle:article];
    }];
}

- (RACSignal *)favoriteArticle:(GLArticle *)article {
    return [[self getCurrentArticlesStorage] then:^RACSignal *{
        return [self.currentArticlesStorage favoriteArticle:article];
    }];
}

- (RACSignal *)getEnArticlesStorage {
    return [[self.enArticlesStorage restore] then:^RACSignal *{
        return [RACSignal return:self.enArticlesStorage];
    }];
}

- (RACSignal *)getRuArticlesStorage {
    return [[self.ruArticlesStorage restore] then:^RACSignal *{
        return [RACSignal return:self.ruArticlesStorage];
    }];
}

- (RACSignal *)getCurrentArticlesStorage {
    return [[self.currentArticlesStorage restore] then:^RACSignal *{
        return [RACSignal return:self.currentArticlesStorage];
    }];
}

+ (NSString *)descriptionForLanguage:(NSString *)language {
    if ([language isEqualToString:@"ru"]) {
        return NSLocalizedString(@"Russian", nil);
    } else if ([language isEqualToString:@"en"]) {
        return NSLocalizedString(@"English", nil);
    } else {
        return language;
    }
}

+ (void)resetForCurrentLanguageWithViewController:(UIViewController *)viewController cancelHandler:(void (^)(UIAlertAction *action))cancelHandler {
    UIAlertController *alertController = [UIAlertController new];
    alertController.title = NSLocalizedString(@"Are you sure?", nil);
    alertController.message = NSLocalizedString(@"All your favorites will be deleted and your statistics will be reset.", nil);
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, just kidding", nil) style:UIAlertActionStyleCancel handler:cancelHandler]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, do it", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[[GLDataManager sharedInstance] getCurrentArticlesStorage] subscribeNext:^(GLArticlesStorage *articlesStorage) {
            [[articlesStorage reset] subscribeCompleted:^{
                [[GLArticlesViewController sharedRandomArticlesViewController] reset];
            }];
        }];
    }]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark Private

- (RACSignal *)loadFeaturedArticles:(NSNumber *)number {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.apiManager GET:@"articles/random" parameters:@{
            @"number": number,
            @"lang": self.language
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSArray class]]) {
                NSMutableArray *titles = [NSMutableArray new];
                [responseObject enumerateObjectsUsingBlock:^(NSDictionary *articleDictionary, NSUInteger idx, BOOL *stop) {
                    [titles addObject:articleDictionary[@"title"]];
                }];
#ifdef SNAPSHOT
                titles[0] = @"Andriamasinavalona";
#endif
                
                NSMutableArray *splitArrayOfTitles = [NSMutableArray array];
                NSUInteger itemsRemaining = titles.count;
                NSUInteger index = 0;
                
                while (index < titles.count) {
                    NSRange range = NSMakeRange(index, MIN(kMaxNumberOfArticlesToLoadAtOnce, itemsRemaining));
                    NSArray *subarray = [titles subarrayWithRange:range];
                    [splitArrayOfTitles addObject:subarray];
                    itemsRemaining -= range.length;
                    index += range.length;
                }
                
                NSMutableArray *signals = [NSMutableArray new];
                for (NSArray *titlesArray in splitArrayOfTitles) {
                    [signals addObject:[self getArticlesForTitles:titlesArray]];
                }
                
                NSMutableArray *allArticles = [NSMutableArray new];
                [[RACSignal merge:signals] subscribeNext:^(NSArray *articles) {
                    [allArticles addObjectsFromArray:articles];
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                } completed:^{
#ifdef SNAPSHOT
                    __block GLArticle *firstArticle;
                    [allArticles enumerateObjectsUsingBlock:^(GLArticle *article, NSUInteger idx, BOOL *stop) {
                        if ([article.title isEqualToString:@"Andriamasinavalona"]) {
                            firstArticle = article;
                            *stop = YES;
                        }
                    }];
                    [allArticles removeObject:firstArticle];
                    [allArticles insertObject:firstArticle atIndex:0];
#endif
                    [subscriber sendNext:allArticles];
                    [subscriber sendCompleted];
                }];
            } else {
                [subscriber sendError:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (RACSignal *)loadRandomArticles:(NSNumber *)number {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.wikiJsonManager GET:[NSString stringWithFormat:kWikipediaApiUrl, self.language] parameters:@{
            @"action": @"query",
            @"list": @"random",
            @"rnnamespace": @0,
            @"rnlimit": number,
            @"format": @"json"
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSMutableArray *titles = [NSMutableArray new];
                [responseObject[@"query"][@"random"] enumerateObjectsUsingBlock:^(NSDictionary *articleDictionary, NSUInteger idx, BOOL *stop) {
                    [titles addObject:articleDictionary[@"title"]];
                }];
                [[self getArticlesForTitles:titles] subscribeNext:^(NSArray *articles) {
                    articles = [[articles filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLArticle *article, NSDictionary *bindings) {
                        return (article.extract.length > 50 && article.pagePictureTitle.length > 0);
                    }]] mutableCopy];
                    [subscriber sendNext:articles];
                    [subscriber sendCompleted];
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                }];
            } else {
                [subscriber sendError:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (RACSignal *)getArticlesForTitles:(NSArray *)titles {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        DDLogVerbose(@"Getting articles for %@ titles", @(titles.count));
        [self.wikiJsonManager GET:[NSString stringWithFormat:kWikipediaApiUrl, self.language] parameters:@{
            @"action": @"query",
            @"prop": [@[@"extracts", @"pageimages"] componentsJoinedByString:@"|"],
            @"exintro": @"true",
            @"titles": [titles componentsJoinedByString:@"|"],
            @"format": @"json",
            @"exlimit": @(titles.count),
            @"pilimit": @(titles.count)
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *articlesDictionary = responseObject[@"query"][@"pages"];
                NSMutableArray *articlesArray = [NSMutableArray new];
                [articlesDictionary enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *articleDictionary, BOOL *stop) {
                    GLArticle *article = [[GLArticle alloc] initWithDictionary:articleDictionary];
                    article.language = self.language;
                    [articlesArray addObject:article];
                }];
                [subscriber sendNext:articlesArray];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
}

- (void)getImageDataFromThumbElement:(HTMLElement *)element completionBlock:(void (^)(NSDictionary *imageData))completionBlock {
    NSAssert(completionBlock, @"completion block can't be nil");
    NSMutableDictionary *imageData = [NSMutableDictionary new];
    HTMLElement *anchorElement = [element firstNodeMatchingSelector:@".image"];
    if (anchorElement) {
        imageData[@"title"] = [anchorElement.attributes[@"href"] stringByReplacingOccurrencesOfString:@"/wiki/File:" withString:@""];
    }
    HTMLElement *imageElement = [element firstNodeMatchingSelector:@".image img"];
    if (imageElement) {
        NSString *largestThumnailSource = [[imageElement.attributes[@"srcset"] componentsSeparatedByString:@","] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF MATCHES '.*2x$'"]][0];
        if (largestThumnailSource.length > 0) {
            imageData[@"url"] = [NSURL URLWithString:[[[largestThumnailSource stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"//" withString:@"https://"] stringByReplacingOccurrencesOfString:@" 2x" withString:@""]];
        }
    }
    HTMLElement *captionElement = [element firstNodeMatchingSelector:@".thumbcaption"];
    if (captionElement) {
        imageData[@"caption"] = [[captionElement textContent] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    completionBlock(imageData);
}

@end
