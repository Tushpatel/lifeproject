//
//  SignUp4ViewController.m
//  YM
//
//  Created by user on 21/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "SignUp4ViewController.h"
#import "SignUp5ViewController.h"
#import "Reachability.h"

@interface SignUp4ViewController () <UITextFieldDelegate>

- (IBAction)nextPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *passwordTxt;

@end

@implementation SignUp4ViewController

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
    
    // keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.passwordTxt.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title";
    self.navigationItem.title = @"Password";

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

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.passwordTxt resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)nextPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // Check if valid password was entered
    if(![self validPassword:self.passwordTxt.text]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                    message:@"Make sure your new password follows our criteria."
                                   delegate:self
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        
        return;
    }
    
    // add username to userData dictionary
    self.userData[@"password"] = [self.passwordTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // go to the next scren
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (BOOL)validPassword:(NSString*)passwordString
{
    if([passwordString length] == 0) {
        return NO;
    }
    
    // (?=.*\\d)      # must contains one digit from 0-9
    // (?=.*[A-Z])    # must contains one uppercase characters
    // .   # match anything with previous condition checking
    // {6,25}   # length at least 6 characters and maximum of 25
    NSString *passwordRegex = @"((?=.*\\d)(?=.*[A-Z]).{6,25})";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    if (![passwordTest evaluateWithObject:passwordString]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (IBAction)signinPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToProfile"]) {
        SignUp5ViewController *signUp5ViewController = segue.destinationViewController;
        signUp5ViewController.userData = self.userData;
    }
}

@end
