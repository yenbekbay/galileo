@interface GLScrollView : UIScrollView

#pragma mark Properties

@property (nonatomic, readonly) NSUInteger currentPage;

#pragma mark Methods

- (void)loadNextPage:(BOOL)animated;
- (void)loadPreviousPage:(BOOL)animated;
- (void)loadPageIndex:(NSUInteger)index animated:(BOOL)animated;

@end
