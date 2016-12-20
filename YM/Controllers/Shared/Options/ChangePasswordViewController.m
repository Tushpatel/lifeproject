//
//  ChangePasswordViewController.m
//  YM
//
//  Created by user on 02/12/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "Intralife.h"
#import "Reachability.h"
@import Firebase;
#import "AppManager.h"

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *reenteredNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

@property (strong, nonatomic) UIBarButtonItem *changePasswordBtn;
@property (strong, nonatomic) Intralife *intralife;

@end

@implementation ChangePasswordViewController

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
    
    self.notificationLabel.hidden = YES;
    
    // keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.oldPasswordTextField.delegate = self;
    self.theNewPasswordTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Change Password";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    
    // add navigation bar right button
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.changePasswordBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(rightTapped:)];
    self.navigationItem.rightBarButtonItem = self.changePasswordBtn;
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)validPassword:(NSString*)passwordString
{
    if([passwordString length] == 0) {
        return NO;
    }
    
    // (?=.*\\d)      # must contains one digit from 0-9
    // (?=.*[A-Z])    # must contains one uppercase characters
    // .   # match anything with previous condition checking
    // {5,25}   # length at least 6 characters and maximum of 25
    NSString *passwordRegex = @"((?=.*\\d)(?=.*[A-Z]).{6,25})";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    if (![passwordTest evaluateWithObject:passwordString])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)rightTapped:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    NSString *oldPassword = self.oldPasswordTextField.text;
    NSString *newPassword = self.theNewPasswordTextField.text;
    NSString *reenteredNewPassword = self.reenteredNewPasswordTextField.text;
    
    // one or more fields are empty
    if([oldPassword isEqualToString:@""] ||
       [newPassword isEqualToString:@""] ||
       [reenteredNewPassword isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Make sure all fields are completed."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    
    // new password and reentered new password do not match
    if(![newPassword isEqualToString:reenteredNewPassword]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Make sure new passwords match."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       self.theNewPasswordTextField.text = @"";
                                       self.reenteredNewPasswordTextField.text = @"";
                                       [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    // new password is invalid
    BOOL isValidPassword = [self validPassword:newPassword];
    if(!isValidPassword) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Make sure your new password follows our criteria."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       self.theNewPasswordTextField.text = @"";
                                       self.reenteredNewPasswordTextField.text = @"";
                                       [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    // old password is wrong
    NSDictionary *loginDetails = [[AppManager sharedAppManager] getLoginPlistData];
    NSString *oldPasswordSaved = [loginDetails valueForKey:@"password"];
    if(![oldPassword isEqualToString:oldPasswordSaved]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Old password is wrong."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       self.oldPasswordTextField.text = @"";
                                       [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        self.oldPasswordTextField.text = @"";
        
        return;
    }
    
    // all good - update password
    [[FIRAuth auth].currentUser updatePassword:self.theNewPasswordTextField.text completion:^(NSError *_Nullable error) {
        if(error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        else {
            // update password in plist file
            NSString *email = [FIRAuth auth].currentUser.email;
            NSString *password = self.theNewPasswordTextField.text;
            NSDictionary *loginDetails = @{
                                           @"email" : email,
                                           @"password" : password
                                           };
            [[AppManager sharedAppManager] saveLoginDataToPlist:loginDetails];
            
            self.navigationItem.rightBarButtonItem = nil;
            self.notificationLabel.hidden = NO;
            
            self.oldPasswordTextField.text = @"";
            self.theNewPasswordTextField.text = @"";
            self.reenteredNewPasswordTextField.text = @"";
        }
    }];
}

- (void)goBackToRoot:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.oldPasswordTextField resignFirstResponder];
    [self.theNewPasswordTextField resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

@end
