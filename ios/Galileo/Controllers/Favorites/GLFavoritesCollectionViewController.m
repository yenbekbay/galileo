#import "GLFavoritesCollectionViewController.h"

#import "GLArticlesViewController.h"
#import "GLDataManager.h"
#import "GLFavoritesCollectionViewCell.h"
#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import "UIView+AYUtils.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

static CGFloat const kFavoritesCollectionViewCellHeight = 150;

@interface GLFavoritesCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *articles;

@end

@implementation GLFavoritesCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"Favorite articles", nil);
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self setUpCollectionView];
    [[[GLDataManager sharedInstance] getFavoriteArticles] subscribeNext:^(NSArray *favoriteArticles) {
        self.articles = favoriteArticles;
        [self.collectionView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)setUpCollectionView {
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[GLFavoritesCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([GLFavoritesCollectionViewCell class])];
    [self.view addSubview:self.collectionView];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)self.articles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GLFavoritesCollectionViewCell *cell = (GLFavoritesCollectionViewCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([GLFavoritesCollectionViewCell class]) forIndexPath:indexPath];
    cell.article = self.articles[(NSUInteger)indexPath.row];
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.width/2, kFavoritesCollectionViewCellHeight);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    GLArticlesViewController *articlesViewcontroller = [[GLArticlesViewController alloc] initWithType:GLArticlesViewTypeFavorites currentArticleIndex:(NSUInteger)indexPath.row];
    [self.navigationController pushViewController:articlesViewcontroller animated:YES];
}

#pragma mark DZNEmptyDataSetSource

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return -self.navigationController.navigationBar.height;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"StarPlaceholder"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"You have no favorite articles yet";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Regular" size:[UIFont mediumTextFontSize]],
                                 NSForegroundColorAttributeName: [UIColor gl_grayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

@end
