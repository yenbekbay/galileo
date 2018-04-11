@interface GLMenuListViewCell : UITableViewCell

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *iconImageView;
@property (nonatomic, getter=isAnimating) BOOL animating;

@end
