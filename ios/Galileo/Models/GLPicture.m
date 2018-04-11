#import "GLPicture.h"

#import "UIFont+GLSizes.h"
#import "UIImage+GLHelpers.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageDownloader.h>

@implementation GLPicture

#pragma mark Initialization

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return nil;
    
    _urls = dictionary[@"urls"];
    _titles = dictionary[@"titles"];
    _caption = dictionary[@"caption"];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) return nil;
    
    _urls = [decoder decodeObjectForKey:@"urls"];
    _titles = [decoder decodeObjectForKey:@"titles"];
    _caption = [decoder decodeObjectForKey:@"caption"];
    _cacheNamespace = [decoder decodeObjectForKey:@"cacheNamespace"];
    
    return self;
}

#pragma mark Public

- (RACSignal *)getImage {
    if (self.image) {
        return [RACSignal return:RACTuplePack(@NO, self.image)];
    } else {
        SDImageCache *imageCache = self.cacheNamespace ? [[SDImageCache alloc] initWithNamespace:self.cacheNamespace] : [SDImageCache sharedImageCache];
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSMutableArray *images = [NSMutableArray new];
            if (self.urls.count > 0) {
                [self.urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                    [imageCache queryDiskCacheForKey:url.absoluteString done:^(UIImage *cachedImage, SDImageCacheType cacheType) {
                        if (cachedImage) {
                            [images addObject:cachedImage];
                            if (images.count == self.urls.count) {
                                [self setImageWithImages:images];
                                [subscriber sendNext:RACTuplePack(@NO, self.image)];
                                [subscriber sendCompleted];
                            }
                        } else {
                            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                if (error || !image) {
                                    [subscriber sendNext:RACTuplePack(@NO, [UIImage imageNamed:@"WikipediaPlaceholder"])];
                                    [subscriber sendCompleted];
                                } else {
                                    [imageCache storeImage:image forKey:url.absoluteString];
                                    [images addObject:image];
                                    if (images.count == self.urls.count) {
                                        [self setImageWithImages:images];
                                        [subscriber sendNext:RACTuplePack(@YES, self.image)];
                                        [subscriber sendCompleted];
                                    }
                                }
                            }];
                        }
                    }];
                }];
            } else {
                [subscriber sendNext:RACTuplePack(@NO, [UIImage imageNamed:@"WikipediaPlaceholder"])];
                [subscriber sendCompleted];
            }
            return nil;
        }];
    }
}

- (void)setImageWithImages:(NSArray *)images {
    if (images.count > 1) {
        self->_image = [[UIImage mergeImagesFromArray:images] opaque];
    } else {
        self->_image = [images[0] opaque];
    }
}

- (void)removeFromCache {
    SDImageCache *imageCache = self.cacheNamespace ? [[SDImageCache alloc] initWithNamespace:self.cacheNamespace] : [SDImageCache sharedImageCache];
    for (NSURL *url in self.urls) {
        [imageCache removeImageForKey:url.absoluteString fromDisk:YES];
    }
}

#pragma mark NYPhoto

- (NSAttributedString *)attributedCaptionSummary {
    return self.caption ? [[NSAttributedString alloc] initWithString:self.caption attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:[UIFont mediumTextFontSize]], NSForegroundColorAttributeName: [UIColor whiteColor] }] : nil;
}

- (NSAttributedString *)attributedCaptionTitle {
    return nil;
}

- (NSAttributedString *)attributedCaptionCredit {
    return nil;
}

- (UIImage *)placeholderImage {
    return nil;
}

#pragma mark NSCoder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.urls forKey:@"urls"];
    [coder encodeObject:self.titles forKey:@"titles"];
    [coder encodeObject:self.caption forKey:@"caption"];
    [coder encodeObject:self.cacheNamespace forKey:@"cacheNamespace"];
}

@end
