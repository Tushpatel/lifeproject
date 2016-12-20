//
//  PPViewController.m
//  YM
//
//  Created by user on 19/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PPViewController.h"
#import "AppManager.h"

@interface PPViewController ()

@end

@implementation PPViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [AppManager sharedAppManager].fusumaScreen = kPPViewController;
    
    self.navigationController.navigationBar.hidden = YES;
}

@end
