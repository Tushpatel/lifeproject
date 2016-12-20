//
//  SignUp3ViewController.m
//  YM
//
//  Created by user on 21/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "SignUp3ViewController.h"
#import "SignUp4ViewController.h"
#import "Reachability.h"
#import "Intralife.h"

@interface SignUp3ViewController () <IntralifeDelegate, UITextFieldDelegate>

- (IBAction)nextPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTxt;

@property (strong, nonatomic) Intralife *intralife;

@end

@implementation SignUp3ViewController

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
    self.intralife.delegate = self;
    
    // keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.usernameTxt.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.activityIndicatorView.hidden = YES;
    
    //set navigation controller title";
    self.navigationItem.title = @"Username";

    //add navigation bar left button (back)
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
    [self.usernameTxt resignFirstResponder];
    
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

    // Check if valid username was entered
    if(![self validUsername:self.usernameTxt.text]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                    message:@"Please enter valid username."
                                   delegate:self
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        
        return;
    }

    self.nextBtn.userInteractionEnabled = NO;
    self.activityIndicatorView.hidden = NO;
    [self.activityIndicatorView startAnimating];

    // check if enterd username already exists
    // TODO: see if speed can be improved
    FIRDatabaseReference *usersRef = [self.intralife.root child:@"people"];
    [usersRef  observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        BOOL dublicateFound = NO;
        NSString *enteredUsername = [self.usernameTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for (FIRDataSnapshot *childSnap in snapshot.children) {
            NSString *username = childSnap.value[@"username"];
            if([username isEqualToString:enteredUsername]) {
                dublicateFound = YES;
                break;
            }
        }
        if(dublicateFound) { // entered user name already exists - tell it and do not preceed to the next screen
            self.nextBtn.userInteractionEnabled = YES;
            self.activityIndicatorView.hidden = YES;
            [self.activityIndicatorView stopAnimating];
            
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Oops!"
                                                  message:@"This user name already exists."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else { // entered user name does not exist - preceed to the next screen
            self.nextBtn.userInteractionEnabled = YES;
            self.activityIndicatorView.hidden = YES;
            [self.activityIndicatorView stopAnimating];
            
            // add username to userData dictionary
            self.userData[@"username"] = [self.usernameTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // go to next screen
            [self performSegueWithIdentifier:@"SegueToPassword" sender:self];
        }
    }];
}

- (BOOL)validUsername:(NSString*)usernameString
{
    if([usernameString length] == 0) {
        return NO;
    }
    
    // {3,16}   # length at least 3 characters and maximum of 16
    NSString *usernameRegex = @".{3,16}";
    NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", usernameRegex];
    if (![nameTest evaluateWithObject:usernameString]) {
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
    if ([segue.identifier isEqualToString:@"SegueToPassword"]) {
        SignUp4ViewController *signUp4ViewController = segue.destinationViewController;
        signUp4ViewController.userData = self.userData;
    }
}

@end
