#import "UIFont+GLSizes.h"

#import "AYMacros.h"

@implementation UIFont (GLSizes)

+ (CGFloat)smallTextFontSize {
    if (IS_IPHONE_6P) {
        return 18;
    } else if (IS_IPHONE_6) {
        return 17;
    } else {
        return 16;
    }
}

+ (CGFloat)mediumTextFontSize {
    if (IS_IPHONE_6P) {
        return 20;
    } else if (IS_IPHONE_6) {
        return 19;
    } else {
        return 18;
    }
}

+ (CGFloat)largeTextFontSize {
    if (IS_IPHONE_6P) {
        return 22;
    } else if (IS_IPHONE_6) {
        return 21;
    } else {
        return 20;
    }
}

+ (CGFloat)articleTitleFontSize {
    if (IS_IPHONE_6P) {
        return 40;
    } else if (IS_IPHONE_6) {
        return 36;
    } else {
        return 32;
    }
}

+ (CGFloat)menuItemTitleFontSize {
    if (IS_IPHONE_6P) {
        return 40;
    } else if (IS_IPHONE_6) {
        return 36;
    } else {
        return 32;
    }
}

+ (CGFloat)sharingArticleTitleFontSize {
    return 60;
}

+ (CGFloat)navigationBarTitleFontSize {
    return 17;
}

@end
