//
//  PickTableHeader.m
//  YM
//
//  Created by user on 09/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PickTableHeader.h"

@interface PickTableHeader ()

- (IBAction)editProfilePressed:(id)sender;
- (IBAction)followPressed:(id)sender;
- (IBAction)followingPressed:(id)sender;

@end

@implementation PickTableHeader

#pragma mark - IBActions

- (IBAction)editProfilePressed:(id)sender
{
    [self.delegate editProfileWasPressed:sender];
}

- (IBAction)followPressed:(id)sender
{
    [self.delegate followWasPressed:sender];
}

- (IBAction)followingPressed:(id)sender
{
    [self.delegate followingWasPressed:sender];
}

@end
