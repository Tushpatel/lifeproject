//
//  FifthTabViewController.m
//  YM
//
//  Created by user on 20/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FifthTabViewController.h"
#import "Intralife.h"

#pragma mark - View Controller

@interface FifthTabViewController ()

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) IntralifeUser *currentUser;

@end

@implementation FifthTabViewController

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

    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = nil;
    
    // add navigation bar right button
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-options.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *optionsBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(optionsPressed:)];

    self.navigationItem.rightBarButtonItem = optionsBtn;
    
    // set navigationItem title as username
    __weak FifthTabViewController *weakSelf = self;
    self.currentUser = [IntralifeUser loadFromRoot:self.intralife.root withUserId:[FIRAuth auth].currentUser.uid completionBlock:^(IntralifeUser *user) {
        weakSelf.navigationItem.title = user.username;
    }];
}

- (void)optionsPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueToOptions" sender:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    // save current tab in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:4 forKey:@"previousTab"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.currentUser stopObserving];
}
 
@end
