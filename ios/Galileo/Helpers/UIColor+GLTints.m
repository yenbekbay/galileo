#import "UIColor+GLTints.h"

@implementation UIColor (GLTints)

#define AGEColorImplement(COLOR_NAME,RED,GREEN,BLUE)    \
+ (instancetype)COLOR_NAME{    \
static UIColor* COLOR_NAME##_color;    \
static dispatch_once_t COLOR_NAME##_onceToken;   \
dispatch_once(&COLOR_NAME##_onceToken, ^{    \
COLOR_NAME##_color = [UIColor colorWithRed:RED green:GREEN blue:BLUE alpha:1];  \
}); \
return COLOR_NAME##_color;  \
}

AGEColorImplement(gl_primaryColor, 0.18f, 0.19f, 0.26f);
AGEColorImplement(gl_lightGrayColor, 0.6f, 0.6f, 0.6f);
AGEColorImplement(gl_grayColor, 0.5f, 0.5f, 0.5f);
AGEColorImplement(gl_darkGrayColor, 0.26f, 0.26f, 0.26f);

@end
