//
//  SignUp1ViewController.m
//  YM
//
//  Created by user on 21/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "SignUp1ViewController.h"
#import "SignUp2ViewController.h"
#import "Reachability.h"

@interface SignUp1ViewController () <UITextFieldDelegate>

- (IBAction)termsPressed:(id)sender;
- (IBAction)conditionsPressed:(id)sender;
- (IBAction)nextPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTxt;

@end

@implementation SignUp1ViewController

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
    
    // create dictionary for user data
    self.userData = [[NSMutableDictionary alloc] init];
    
    // Keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.nameTxt.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Name";
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nameTxt resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)termsPressed:(id)sender
{
     [self performSegueWithIdentifier:@"SegueToTerms" sender:self];
}

- (IBAction)conditionsPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueToPrivacy" sender:self];
}

- (IBAction)nextPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
        // Check if valid name was entered
        if(![self validName:self.nameTxt.text]) {
            [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                        message:@"Please enter valid name."
                                       delegate:self
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
    
            return;
        }
    
    // add name to userData dictionary
    self.userData[@"name"] = [self.nameTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // go to the next screen
    [self performSegueWithIdentifier:@"SegueToEmail" sender:self];
}

- (BOOL)validName:(NSString *)nameString
{
    if([nameString length] == 0) {
        return NO;
    }
    
    // {2,20}   # length at least 2 characters and maximum of 20
    NSString *nameRegex = @".{2,20}";
    NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
    if (![nameTest evaluateWithObject:nameString]) {
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
    if ([segue.identifier isEqualToString:@"SegueToEmail"]) {
        SignUp2ViewController *signUp2ViewController = segue.destinationViewController;
        signUp2ViewController.userData = self.userData;
    }
}

@end
