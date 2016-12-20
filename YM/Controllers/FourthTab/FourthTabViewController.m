//
//  FourthTabViewController.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FourthTabViewController.h"
#import "FourthTabContainerViewController.h"

@interface FourthTabViewController ()

@property (nonatomic, weak) FourthTabContainerViewController *containerViewController;

- (IBAction)swapToYouButtonPressed:(id)sender;
- (IBAction)swapToFollowingButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *swapToYouBtn;
@property (weak, nonatomic) IBOutlet UIView *swapToYouView;
@property (weak, nonatomic) IBOutlet UIButton *swapToFollowingBtn;
@property (weak, nonatomic) IBOutlet UIView *swapToFollowingView;

@end

@implementation FourthTabViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.swapToFollowingBtn.userInteractionEnabled = NO;
    self.swapToYouBtn.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden = NO;
    
    //set navigation controller title
    self.navigationItem.title = @"Activity";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    
    //save current tab in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"previousTab"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.containerViewController = segue.destinationViewController;
    }
}

- (IBAction)swapToYouButtonPressed:(id)sender
{
    [self.containerViewController swapViewControllers];
    
    // change button images
    [self.swapToYouBtn setImage:[UIImage imageNamed:@"activity-you-selected.png"] forState:UIControlStateNormal];
    [self.swapToFollowingBtn setImage:[UIImage imageNamed:@"activity-following.png"] forState:UIControlStateNormal];
    
    // hide/show button backgrounds
    self.swapToYouView.hidden = NO;
    self.swapToFollowingView.hidden = YES;
    
    // handle button user interaction
    self.swapToFollowingBtn.userInteractionEnabled = !self.swapToFollowingBtn.userInteractionEnabled;
    self.swapToYouBtn.userInteractionEnabled = !self.swapToYouBtn.userInteractionEnabled;
}

- (IBAction)swapToFollowingButtonPressed:(id)sender
{
    [self.containerViewController swapViewControllers];
    
    // change button images
    [self.swapToYouBtn setImage:[UIImage imageNamed:@"activity-you.png"] forState:UIControlStateNormal];
    [self.swapToFollowingBtn setImage:[UIImage imageNamed:@"activity-following-selected.png"] forState:UIControlStateNormal];
    
    // hide/show button backgrounds
    self.swapToYouView.hidden = YES;
    self.swapToFollowingView.hidden = NO;
    
    // handle button user interaction
    self.swapToFollowingBtn.userInteractionEnabled = !self.swapToFollowingBtn.userInteractionEnabled;
    self.swapToYouBtn.userInteractionEnabled = !self.swapToYouBtn.userInteractionEnabled;
}

@end
