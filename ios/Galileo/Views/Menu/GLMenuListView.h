@class GLMenuListView;

@protocol GLMenuListViewDelegate <NSObject>
@required
- (void)listView:(GLMenuListView *)listView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface GLMenuListView : UIView

#pragma mark Properties

@property (weak, nonatomic) id<GLMenuListViewDelegate> delegate;
@property (nonatomic) UITableView *tableView;

#pragma mark Methods

- (instancetype)initWithFrame:(CGRect)frame images:(NSArray *)images titles:(NSArray *)titles;

@end
