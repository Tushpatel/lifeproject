//
//  PickViewController.m
//  YM
//
//  Created by user on 20/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PickViewController.h"
#import "Intralife.h"
#import "AppManager.h"

#pragma mark - View Controller

@interface PickViewController ()

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) IntralifeUser *currentUser;


@end

@implementation PickViewController

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
    __weak PickViewController *weakSelf = self;
    self.currentUser = [IntralifeUser loadFromRoot:self.intralife.root withUserId:[AppManager sharedAppManager].uid completionBlock:^(IntralifeUser *user) {
        weakSelf.navigationItem.title = user.username;
    }];

    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = nil;
    
    // add navigation bar right button (options) if its not your own profile
    if([[AppManager sharedAppManager].uid isEqualToString:[FIRAuth auth].currentUser.uid]) {
        UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-options.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIBarButtonItem *optionsBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(optionsPressed:)];
        
        self.navigationItem.rightBarButtonItem = optionsBtn;
    }
    
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

- (void)optionsPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueToOptions" sender:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    [self.currentUser stopObserving];
}

@end
