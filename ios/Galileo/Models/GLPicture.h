#import <NYTPhotoViewer/NYTPhoto.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface GLPicture : NSObject <NYTPhoto>

#pragma mark Properties

@property (copy, nonatomic, readonly) NSString *caption;
@property (nonatomic, readonly) NSArray *titles;
@property (nonatomic, readonly) NSArray *urls;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic) NSString *cacheNamespace;

#pragma mark Methods

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (RACSignal *)getImage;
- (void)removeFromCache;

@end
