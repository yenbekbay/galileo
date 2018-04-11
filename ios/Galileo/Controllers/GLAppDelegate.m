#import "GLAppDelegate.h"

#import "GLArticlesViewController.h"
#import "UIColor+GLTints.h"
#import "UIFont+GLSizes.h"
#import <Bohr/Bohr.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>

@implementation GLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] componentsSeparatedByString:@"-"][0];
    if (![language isEqualToString:@"ru"]) {
        language = @"en";
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
       @"language": language
    }];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:[GLArticlesViewController sharedRandomArticlesViewController]];
    self.navigationController.navigationBar.tintColor = [UIColor gl_primaryColor];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    [self setUpAppearances];
    
    return YES;
}

#pragma mark Private

- (void)setUpAppearances {
    [UINavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Roboto-Regular" size:[UIFont navigationBarTitleFontSize]] };
    
    [BOTableViewSection appearance].headerTitleColor = [UIColor gl_grayColor];
    [BOTableViewSection appearance].footerTitleColor = [UIColor gl_lightGrayColor];
    
    [BOTableViewCell appearance].mainFont = [UIFont fontWithName:@"Roboto-Regular" size:[UIFont mediumTextFontSize]];
    [BOTableViewCell appearance].mainColor = [UIColor gl_darkGrayColor];
    [BOTableViewCell appearance].secondaryColor = [UIColor gl_primaryColor];
    [BOTableViewCell appearance].selectedColor = [UIColor gl_primaryColor];
}

@end
