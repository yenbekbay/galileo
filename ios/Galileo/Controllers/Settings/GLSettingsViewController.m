#import "GLSettingsViewController.h"

#import "GLArticlesStorage.h"
#import "GLArticlesViewController.h"
#import "GLDataManager.h"
#import "GLLanguageChoiceTableViewCell.h"

@interface GLSettingsViewController () <UIAlertViewDelegate>

@end

@implementation GLSettingsViewController

#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[[GLDataManager sharedInstance] updateLanguage] subscribeNext:^(NSNumber *updated) {
        if ([updated boolValue]) {
            DDLogVerbose(@"Updated language in data manager");
        }
    }];
    [[[GLArticlesViewController sharedRandomArticlesViewController] updateLanguage] subscribeNext:^(NSNumber *updated) {
        if ([updated boolValue]) {
            DDLogVerbose(@"Updated language in articles view");
        }
    }];
}

#pragma mark Private

- (void)setup {
    self.navigationItem.title = NSLocalizedString(@"Settings", nil);

    [self addSection:[BOTableViewSection sectionWithHeaderTitle:NSLocalizedString(@"General", nil) handler:^(BOTableViewSection *section) {
        [section addCell:[GLLanguageChoiceTableViewCell cellWithTitle:NSLocalizedString(@"Wikipedia Language", nil) key:@"language" handler:^(GLLanguageChoiceTableViewCell *cell) {
            cell.languageCodes = @[@"ru", @"en"];
            cell.languageDescriptions = @[@"Русский", @"English"];
        }]];
    }]];
    
    [self addSection:[BOTableViewSection sectionWithHeaderTitle:nil handler:^(BOTableViewSection *section) {
        [section addCell:[BOButtonTableViewCell cellWithTitle:NSLocalizedString(@"Reset for current language", nil) key:nil handler:^(BOButtonTableViewCell *cell) {
            cell.actionBlock = ^{
                [GLDataManager resetForCurrentLanguageWithViewController:self cancelHandler:nil];
            };
        }]];
        section.footerTitle = NSLocalizedString(@"All your favorites will be deleted and your statistics will be reset.", nil);
    }]];
}

@end
