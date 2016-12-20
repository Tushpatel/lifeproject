//
//  ProfileViewController.m
//  YM
//
//  Created by user on 19/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ProfileViewController.h"
#import "AppManager.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [AppManager sharedAppManager].fusumaScreen = kProfileViewController;
    
    self.navigationController.navigationBar.hidden = YES;
}

@end
