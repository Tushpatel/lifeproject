//
//  SecondTabViewController.m
//  YM
//
//  Created by user on 19/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "SecondTabViewController.h"
#import "AppManager.h"

@interface SecondTabViewController ()

@end

@implementation SecondTabViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [AppManager sharedAppManager].fusumaScreen = kSecondViewController;
    
    self.navigationController.navigationBar.hidden = YES;
}

@end
