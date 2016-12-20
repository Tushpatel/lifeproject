//
//  SignUp6ViewController.m
//  YM
//
//  Created by user on 24/03/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "SignUp6ViewController.h"
#import "SignUp7ViewController.h"
#import "Intralife.h"
#import "Reachability.h"

@interface SignUp6ViewController ()

- (IBAction)nextPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;
- (IBAction)profilePressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *profileImageBtn;

@property (nonatomic, strong) Intralife *intralife;

@end

@implementation SignUp6ViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden = NO;
    
    // set navigation controller title
    self.navigationItem.title = @"Set Profile Picture";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    // profile image
    if(!self.profileImage) {
        self.profileImage = [UIImage imageNamed:@"profile-profile.png"];
    }
    [self.profileImageBtn setImage:self.profileImage forState:UIControlStateNormal];
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueToImages" sender:self];
}

- (IBAction)nextPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // add profile image to userData dictionary (it will be added to firebase storage)
    self.userData[@"profileImage"] = self.profileImage;
    
    // go to the next screen
    [self performSegueWithIdentifier:@"SegueToFollow" sender:self];
}

- (IBAction)signinPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToFollow"]) {
        SignUp7ViewController *signUp7ViewController = segue.destinationViewController;
        signUp7ViewController.userData = self.userData;
    }
}

@end
