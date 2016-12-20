//
//  OptionsViewController.m
//  YM
//
//  Created by user on 12/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "OptionsViewController.h"
#import "Intralife.h"
@import PermissionScope;
#import <MessageUI/MessageUI.h>

@interface OptionsViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) Intralife *intralife;
@property (nonatomic, strong) PermissionScope *pScope;

@end

@implementation OptionsViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.intralife = [[Intralife alloc] initIntralife];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Options";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && indexPath.row == 0) { // invite via SMS
        [self showInviteSMS];
    }
    else if(indexPath.section == 0 && indexPath.row == 1) { // invite via Email
        [self showInviteEmail];
    }
    else if(indexPath.section == 1 && indexPath.row == 2) { // dissable account via Email
        [self showDissableEmail];
    }
    else if(indexPath.section == 2 && indexPath.row == 0) { // open website
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.firstclickdigital.co.uk"]];
    }
}

// TODO: add link
- (void)showInviteSMS
{
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Your device doesn't support SMS." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSArray *recipents = [[NSArray alloc] init];
    NSString *message = [NSString stringWithFormat:@"Hey,\nDownload IntraLife - Free App for Mixed Heritage Millenials!"];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipents];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

// TODO: add link
- (void)showInviteEmail
{
    if(![MFMailComposeViewController canSendMail]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You need to set up an email account on your device before you can invite via email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSArray *recipents = [[NSArray alloc] init];
    NSString *message = @"Hey,\nDownload IntraLife - Free App for Mixed Heritage Millenials!";
        NSString *emailTitle = @"Download IntraLife for FREE - Social App for Mixed Heritage Millennials";
    
    MFMailComposeViewController *messageController = [[MFMailComposeViewController alloc] init];
    messageController.mailComposeDelegate = self;
    [messageController setSubject:emailTitle];
    [messageController setMessageBody:message isHTML:NO];
    [messageController setToRecipients:recipents];
    
    // Present mail view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)showDissableEmail
{
    NSString *emailTitle = @"Request IntraLife Account Deactivation";
    
    NSString *messageBody = @"Dear IntraLife Support,\n\nPlease disable the account associated with my email address as soon as possible. I understand that this can take up to 30 days to take effect.\n\nKind regards,\nIntraLife User";
    
    NSArray *toRecipents = [NSArray arrayWithObject:@"support@intralife.co"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

#pragma mark - <MFMessageComposeViewControllerDelegate>

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <MFMailComposeViewControllerDelegate>

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - IBActions

- (IBAction)logoutPressed:(id)sender
{
    // logout
    [self.intralife logout];

    // go to login screen
    [self performSegueWithIdentifier:@"SequeToLogin" sender:self];
}

@end
