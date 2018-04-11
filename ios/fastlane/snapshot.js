#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(15);
captureLocalizedScreenshot("0-ArticleView");
window.scrollViews()[0].scrollViews()[0].images()["Article View Image"].tap();
target.delay(1);
captureLocalizedScreenshot("1-GalleryView");
target.dragFromToForDuration({x:200.00, y:200.00}, {x:200.00, y:400.00}, 0.5);
window.scrollViews()[0].scrollViews()[0].doubleTap();
target.delay(1);
captureLocalizedScreenshot("2-MenuView");
window.tableViews()[0].cells()[0].tap();
target.delay(1);
captureLocalizedScreenshot("3-FavoritesView");
