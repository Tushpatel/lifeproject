//
//  ResetPasswordViewController.m
//  YM
//
//  Created by user on 30/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "Intralife.h"
#import "Reachability.h"

@interface ResetPasswordViewController () <UITextFieldDelegate>

- (IBAction)resetPressed:(id)sender;
- (IBAction)loginPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *emailTxt;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

@property (strong, nonatomic) Intralife *intralife;

@end

@implementation ResetPasswordViewController

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
    
    self.emailTxt.delegate = self;
    
    self.notificationLabel.hidden = YES;
}

#pragma mark - IBActions

- (IBAction)resetPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // Check if valid email address was entered
    NSString *email = [self.emailTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(![self validEmail:email]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops"
                                    message:@"Please enter valid email address."
                                   delegate:self
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        
        return;
    }
    
    self.resetBtn.userInteractionEnabled = NO;
    
    [[FIRAuth auth] sendPasswordResetWithEmail:email completion:^(NSError *error) {
        if(error) {
            NSLog(@"%@", error.localizedDescription);
            
            // error occured, here we assume that most common error occured - user enetered wrong login email
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Oops!"
                                                  message:@"Please enter correct login email."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           NSLog(@"OK action");
                                       }];
            
            [alertController addAction:okAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
            
            self.resetBtn.userInteractionEnabled = YES;
        }
        else {
            NSLog(@"Email was send !!!");
            
            self.notificationLabel.hidden = NO;
            self.resetBtn.hidden = YES;
            self.emailTxt.hidden = YES;
        }
    }];
}

// @TODO: possibly add GuardPost-ObjectiveC for more accurate validation
- (BOOL)validEmail:(NSString*)emailString
{
    if([emailString length] == 0) {
        return NO;
    }
    
    //TODO: test regex
    // taken from: stackoverflow.com/questions/11760787/regex-for-email-address
    const char cRegex[] = "^(?!(?:(?:\\x22?\\x5C[\\x00-\\x7E]\\x22?)|(?:\\x22?[^\\x5C\\x22]\\x22?)){255,})(?!(?:(?:\\x22?\\x5C[\\x00-\\x7E]\\x22?)|(?:\\x22?[^\\x5C\\x22]\\x22?)){65,}@)(?:(?:[\\x21\\x23-\\x27\\x2A\\x2B\\x2D\\x2F-\\x39\\x3D\\x3F\\x5E-\\x7E]+)|(?:\\x22(?:[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x21\\x23-\\x5B\\x5D-\\x7F]|(?:\\x5C[\\x00-\\x7F]))*\\x22))(?:\\.(?:(?:[\\x21\\x23-\\x27\\x2A\\x2B\\x2D\\x2F-\\x39\\x3D\\x3F\\x5E-\\x7E]+)|(?:\\x22(?:[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x21\\x23-\\x5B\\x5D-\\x7F]|(?:\\x5C[\\x00-\\x7F]))*\\x22)))*@(?:(?:(?!.*[^.]{64,})(?:(?:(?:xn--)?[a-z0-9]+(?:-+[a-z0-9]+)*\\.){1,126}){1,}(?:(?:[a-z][a-z0-9]*)|(?:(?:xn--)[a-z0-9]+))(?:-+[a-z0-9]+)*)|(?:\\[(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){7})|(?:(?!(?:.*[a-f0-9][:\\]]){7,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?)))|(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){5}:)|(?:(?!(?:.*[a-f0-9]:){5,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3}:)?)))?(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))(?:\\.(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))){3}))\\]))$";
    NSString *emailRegex = [NSString stringWithUTF8String:cRegex];
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    if (![emailTest evaluateWithObject:emailString]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (IBAction)loginPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.emailTxt resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

@end
