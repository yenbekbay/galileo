#import "GLMenuListView.h"

#import "GLMenuListViewCell.h"
#import "UIView+AYUtils.h"
#import <pop/POP.h>

@interface GLMenuListView() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSArray *images;
@property (nonatomic) NSArray *titles;

@end

@implementation GLMenuListView

- (instancetype)initWithFrame:(CGRect)frame images:(NSArray *)images titles:(NSArray *)titles {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.images = images;
    self.titles = titles;
    
    self.backgroundColor = [UIColor clearColor];
    [self setUpTableView];
    
    return self;
}

- (void)setUpTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.scrollEnabled = NO;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[GLMenuListViewCell class] forCellReuseIdentifier:NSStringFromClass([GLMenuListViewCell class])];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self addSubview:self.tableView];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    self.animating = YES;
    [super willMoveToWindow:newWindow];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GLMenuListViewCell *cell = (GLMenuListViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([GLMenuListViewCell class])];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.layoutMargins = UIEdgeInsetsZero;
    
    if (self.images.count > (NSUInteger)indexPath.row) {
        cell.iconImageView.image = [self.images[(NSUInteger)indexPath.row] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    cell.titleLabel.text = self.titles[(NSUInteger)indexPath.row];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.height / self.titles.count;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GLMenuListViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self scaleAnimation:cell];
    if (self.delegate) {
        [self.delegate listView:self didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    GLMenuListViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self scaleToSmall:cell];
    cell.titleLabel.alpha = 0.75f;
    cell.iconImageView.alpha = 0.75f;
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    GLMenuListViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self scaleToDefault:cell];
    cell.titleLabel.alpha = 1;
    cell.iconImageView.alpha = 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.isAnimating) return;
    [self performSlideInCellAnimationsWithCell:(GLMenuListViewCell *)cell forRowIndexPath:indexPath];
}

#pragma mark Private

- (void)performSlideInCellAnimationsWithCell:(GLMenuListViewCell *)cell forRowIndexPath:(NSIndexPath *)indexPath {
    if (cell.isAnimating) return;
    cell.animating = YES;
    
    cell.left -= cell.width;
    cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95f, 0.0001f);
    cell.alpha = 0;
    
    [UIView animateWithDuration:0.3f/1.5f delay:0.1f * indexPath.row usingSpringWithDamping:0.7f initialSpringVelocity:1 options:0 animations:^{
        cell.left += cell.width;
        cell.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
    } completion:^(BOOL finished) {
        cell.animating = NO;
        if ((NSUInteger)indexPath.row + 1 == self.titles.count) {
            self.animating = NO;
        }
    }];
}

#pragma mark Animations

- (void)scaleToSmall:(GLMenuListViewCell *)cell {
    POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(0.95f, 0.95f)];
    [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

- (void)scaleAnimation:(GLMenuListViewCell *)cell {
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3, 3)];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    scaleAnimation.springBounciness = 18;
    [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

- (void)scaleToDefault:(GLMenuListViewCell *)cell {
    POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
    [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleDefaultAnimation"];
}

@end
