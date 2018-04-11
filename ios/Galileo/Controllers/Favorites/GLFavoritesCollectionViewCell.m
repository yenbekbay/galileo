#import "GLFavoritesCollectionViewCell.h"

#import "UIView+AYUtils.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface GLFavoritesCollectionViewCell ()

@property (nonatomic) UIView *infoView;

@end

@implementation GLFavoritesCollectionViewCell

#pragma mark Lifecycle

- (void)prepareForReuse {
    if (self.infoView) {
        [self.infoView removeFromSuperview];
        self.infoView = nil;
    }
}

#pragma mark Setters

- (void)setArticle:(GLArticle *)article {
    _article = article;
    [[[article getSharingViewWithSize:self.size forDisplay:YES]
        deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(UIView *sharingView) {
            self.infoView = sharingView;
            [self.contentView addSubview:self.infoView];
        }];
}


@end
