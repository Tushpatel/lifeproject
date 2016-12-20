//
//  LoginRegisterViewController.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "LoginRegisterViewController.h"
#import "Reachability.h"
#import "AppManager.h"
#import "MBProgressHUD.h"

@interface LoginRegisterViewController ()

- (IBAction)loginPressed:(id)sender;
- (IBAction)registerPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *registerBtn;

@end

@implementation LoginRegisterViewController

#pragma mark - Internet Connection

- (BOOL)isInternetConnection
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if(internetStatus == NotReachable) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Error"
                                              message:@"Please check your internet connection."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // get login email and password from plist file
    // (if runing first time, plist file does not exist yet so null is returned)
    NSDictionary *loginDetails = [[AppManager sharedAppManager] getLoginPlistData];
    NSString *email = [loginDetails valueForKey:@"email"];
    NSString *password = [loginDetails valueForKey:@"password"];
    
    if((!email.length && !password.length) || ![self isInternetConnection]) {
        self.loginBtn.hidden = NO;
        self.registerBtn.hidden = NO;
    }
    else {
        self.loginBtn.hidden = YES;
        self.registerBtn.hidden = YES;
        
        // add progress indicator
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)loginPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToSignIn" sender:self];
}

- (IBAction)registerPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToRegister" sender:self];
}

@end
