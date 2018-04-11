#import "GLArticle.h"

#import "GLDataManager.h"
#import "GLLoadingImageView.h"
#import "GLPicture.h"
#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import "UILabel+GLHelpers.h"
#import <DTCoreText/DTCoreText.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

CGSize const kSharingArticleViewSize = {500, 500};
static UIEdgeInsets const kSharingViewTitleLabelPadding = {10, 10, 10, 10};
static NSString * const kWikipediaPublicUrl = @"https://%@.wikipedia.org/wiki/";

@implementation GLArticle

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return nil;
    
    _title = dictionary[@"title"];
    _extract = [self trimmedExtract:[[NSAttributedString alloc] initWithHTMLData:[dictionary[@"extract"] dataUsingEncoding:NSUTF8StringEncoding] options:@{
        DTUseiOS6Attributes: @YES,
        DTDefaultFontFamily: @"Noto Serif",
        DTDefaultFontSize: @([UIFont mediumTextFontSize]),
        DTDefaultLineHeightMultiplier: @(4.f/3),
        DTDefaultTextColor: [UIColor gl_darkGrayColor]
    } documentAttributes:nil]];
    _pageId = [dictionary[@"pageId"] integerValue];
    _pagePictureTitle = dictionary[@"pageimage"];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) return nil;
    
    _title = [decoder decodeObjectForKey:@"title"];
    _extract = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"extract"]];
    _pageId = [[decoder decodeObjectForKey:@"pageId"] integerValue];
    _favorite = [[decoder decodeObjectForKey:@"favorite"] boolValue];
    _pictures = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"pictures"]];
    _language = [decoder decodeObjectForKey:@"language"];
    
    return self;
}

#pragma mark Getters

- (NSURL *)publicUrl {
    NSString *escapedTitle = [[self.title stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [NSURL URLWithString:[[NSString stringWithFormat:kWikipediaPublicUrl, self.language] stringByAppendingString:escapedTitle]];
}

#pragma mark NSObject

- (NSString *)description {
    return self.title;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[GLArticle class]]) {
        return [[(GLArticle *)object publicUrl].absoluteString isEqualToString:self.publicUrl.absoluteString];
    } else {
        return NO;
    }
}

#pragma mark Public

- (RACSignal *)getPictures {
    if (self.pictures) {
        return [RACSignal return:self.pictures];
    } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[[GLDataManager sharedInstance] getPicturesForArticle:self] subscribeNext:^(NSArray *pictures) {
                if (pictures.count > 0) {
                    self->_pictures = pictures;
                    [subscriber sendNext:pictures];
                    [subscriber sendCompleted];
                } else if (self.pagePictureTitle.length > 0) {
                    [[[GLDataManager sharedInstance] getPictureForTitle:self.pagePictureTitle] subscribeNext:^(GLPicture *picture) {
                        self->_pictures = @[picture];
                        [subscriber sendNext:@[picture]];
                        [subscriber sendCompleted];
                    } error:^(NSError *error) {
                        [subscriber sendError:error];
                        [subscriber sendCompleted];
                    }];
                } else {
                    [subscriber sendCompleted];
                }
            } error:^(NSError *error) {
                [subscriber sendError:error];
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }
}

- (RACSignal *)getPagePictureImage {
    return [[self getPictures] then:^{
        if (self.pictures.count > 0) {
            return [self.pictures[0] getImage];
        } else {
            return [RACSignal return:RACTuplePack(@NO, [UIImage imageNamed:@"WikipediaPlaceholder"])];
        }        
    }];
}

- (RACSignal *)getSharingViewWithSize:(CGSize)size forDisplay:(BOOL)forDisplay {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        UIView *sharingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        sharingView.opaque = YES;
        
        GLLoadingImageView *imageView = [[GLLoadingImageView alloc] initWithFrame:sharingView.frame];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [sharingView addSubview:imageView];
        
        UIView *imageViewOverlay = [[UIView alloc] initWithFrame:imageView.frame];
        imageViewOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
        [sharingView addSubview:imageViewOverlay];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:UIEdgeInsetsInsetRect(imageView.frame, kSharingViewTitleLabelPadding)];
        titleLabel.font = [UIFont fontWithName:@"Roboto-Black" size:forDisplay ? [UIFont largeTextFontSize] : [UIFont sharingArticleTitleFontSize]];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.text = self.title;
        [titleLabel adjustFontSize:4 fontFloor:[UIFont smallTextFontSize]];
        titleLabel.frame = UIEdgeInsetsInsetRect(sharingView.frame, kSharingViewTitleLabelPadding);
        [sharingView addSubview:titleLabel];
        
        if (forDisplay) {
            imageView.spinnerStyle = UIActivityIndicatorViewStyleWhite;
            [imageView startSpinning];
            [subscriber sendNext:sharingView];
            [subscriber sendCompleted];
        }
        
        [[[self getPagePictureImage]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(RACTuple *tuple) {
                RACTupleUnpack(NSNumber *loaded, UIImage *image) = tuple;
                if ([loaded boolValue]) {
                    DDLogVerbose(@"Loaded images for article %@", self.title);
                }
                imageView.image = image;
                if (forDisplay) {
                    [imageView stopSpinning];
                } else {
                    [subscriber sendNext:sharingView];
                    [subscriber sendCompleted];
                }
            }];
        
        return nil;
    }];
}

#pragma mark Private

- (NSAttributedString *)trimmedExtract:(NSAttributedString *)extract {
    NSCharacterSet *invertedSet = NSCharacterSet.whitespaceAndNewlineCharacterSet.invertedSet;
    NSString *string = extract.string;
    NSUInteger loc, len;
    
    NSRange range = [string rangeOfCharacterFromSet:invertedSet];
    loc = (range.length > 0) ? range.location : 0;
    
    range = [string rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];
    len = (range.length > 0) ? NSMaxRange(range) - loc : string.length - loc;
    
    return [extract attributedSubstringFromRange:NSMakeRange(loc, len)];
}

#pragma mark NSCoder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.extract] forKey:@"extract"];
    [coder encodeObject:@(self.pageId) forKey:@"pageId"];
    [coder encodeObject:@(self.favorite) forKey:@"favorite"];
    [coder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.pictures] forKey:@"pictures"];
    [coder encodeObject:self.language forKey:@"language"];
}

@end
