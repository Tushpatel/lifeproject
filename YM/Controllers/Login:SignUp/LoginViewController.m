//
//  LoginViewController.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "LoginViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Intralife.h"
#import "Reachability.h"
#import "AppManager.h"

@interface LoginViewController () <UITextFieldDelegate>

- (IBAction)loginWithUsernamePressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *usernameTxt;
@property (weak, nonatomic) IBOutlet UITextField *passwordTxt;
@property (weak, nonatomic) IBOutlet UIButton *usernameLoginBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *usernameLoginSpinner;

@property (strong, nonatomic) Intralife *intralife;

@end

@implementation LoginViewController

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
    
    self.intralife = [[Intralife alloc] initIntralife];
    
    // keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.usernameTxt.delegate = self;
    self.passwordTxt.delegate = self;
}

#pragma mark - IBActions

- (IBAction)forgottenPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToReset" sender:self];
}

- (IBAction)loginWithUsernamePressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // Disable the Login button to prevent multiple touches
    [self.usernameLoginBtn setEnabled:NO];
    
    // Show an activity indicator
    [self.usernameLoginSpinner startAnimating];
    
    // login user if possible
    NSString *email = self.usernameTxt.text;
    NSString *password = self.passwordTxt.text;
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser *user, NSError *error) {

    
        [self.usernameLoginBtn setEnabled:YES];
        [self.usernameLoginSpinner stopAnimating];
        
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            
            // Show error alert
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Oops!"
                                                  message:@"Please enter correct email and password."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           self.passwordTxt.text = @"";
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else {
            // save login details in plist file for later use
            NSDictionary *loginDetails = @{
                                        @"email" : email,
                                        @"password" : password
                                        };
            [[AppManager sharedAppManager] saveLoginDataToPlist:loginDetails];
            
            self.usernameTxt.text = @"";
            self.passwordTxt.text = @"";
            [self performSegueWithIdentifier:@"loginSuccessful" sender:self];
        }
    }];
}

- (IBAction)registerPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToRegister" sender:self];
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.usernameTxt resignFirstResponder];
    [self.passwordTxt resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

@end
