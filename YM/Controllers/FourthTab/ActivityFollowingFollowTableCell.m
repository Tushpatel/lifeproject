//
//  ActivityFollowingFollowTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ActivityFollowingFollowTableCell.h"

@interface ActivityFollowingFollowTableCell ()

- (IBAction)profilePressed:(id)sender;

@end


@implementation ActivityFollowingFollowTableCell

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    [self.delegate profileButtonOnFollowWasPressed:self];
}

@end


