//
//  ActivityFollowingLikeTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ActivityFollowingLikeTableCell.h"

@interface ActivityFollowingLikeTableCell ()

- (IBAction)profilePressed:(id)sender;
- (IBAction)photoPressed:(id)sender;

@end


@implementation ActivityFollowingLikeTableCell

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    [self.delegate profileButtonOnLikeWasPressed:self];
}

- (IBAction)photoPressed:(id)sender
{
    [self.delegate photoButtonWasPressed:self];
}

@end


