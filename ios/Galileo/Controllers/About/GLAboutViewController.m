#import "GLAboutViewController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import <MessageUI/MessageUI.h>

@interface GLAboutViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation GLAboutViewController

#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark Private

- (void)setup {
    self.navigationItem.title = NSLocalizedString(@"About", nil);
    
    [self addSection:[BOTableViewSection sectionWithHeaderTitle:nil handler:^(BOTableViewSection *section) {
        [section addCell:[BOButtonTableViewCell cellWithTitle:NSLocalizedString(@"Rate Galileo", nil) key:nil handler:^(BOButtonTableViewCell *cell) {
            cell.actionBlock = ^{
                [AYAppStore openAppStoreReview];
            };
        }]];
        [section addCell:[BOButtonTableViewCell cellWithTitle:NSLocalizedString(@"Feedback", nil) key:nil handler:^(BOButtonTableViewCell *cell) {
            cell.actionBlock = ^{
                if ([MFMailComposeViewController canSendMail]) {
                    AYFeedback *feedback = [AYFeedback new];
                    MFMailComposeViewController *feedbackViewController = [MFMailComposeViewController new];
                    feedbackViewController.mailComposeDelegate = self;
                    [feedbackViewController setToRecipients:@[@"ayan.yenb@gmail.com"]];
                    [feedbackViewController setSubject:feedback.subject];
                    [feedbackViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
                    [self presentViewController:feedbackViewController animated:YES completion:nil];
                } else {
                    UIAlertController *alertController = [UIAlertController new];
                    alertController.title = NSLocalizedString(@"Configure your mail service", nil);
                    alertController.message = NSLocalizedString(@"You need a configured mail account in order to send us an email.", nil);
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
            };
        }]];
        [section addCell:[BOButtonTableViewCell cellWithTitle:NSLocalizedString(@"Tell a friend", nil) key:nil handler:^(BOButtonTableViewCell *cell) {
            cell.actionBlock = ^{
                NSString *appStoreLink = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", kAppId];
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:NSLocalizedString(@"Check out Galileo - Best way to discover Wikipedia: %@", nil), appStoreLink]] applicationActivities:nil];
                [self presentViewController:activityViewController animated:YES completion:nil];
            };
        }]];
        
        section.footerTitle = [NSString stringWithFormat:NSLocalizedString(@"Galileo %@\r© Ayan Yenbekbay", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }]];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)footerView forSection:(NSInteger)sectionIndex {
    [super tableView:tableView willDisplayFooterView:footerView forSection:sectionIndex];
    footerView.textLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultSent) {
            UIAlertController *alertController = [UIAlertController new];
            alertController.title = NSLocalizedString(@"Thank you!", nil);
            alertController.message = NSLocalizedString(@"We will try to contact you as soon as possible.", nil);
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

@end
