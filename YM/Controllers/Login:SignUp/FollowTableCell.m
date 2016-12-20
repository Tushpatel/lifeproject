//
//  FollowTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FollowTableCell.h"

@interface FollowTableCell ()

- (IBAction)followPressed:(id)sender;

@end

@implementation FollowTableCell

#pragma mark - IBActions

- (IBAction)followPressed:(id)sender
{
    [self.delegate followButtonWasPressed:self];
}

@end
