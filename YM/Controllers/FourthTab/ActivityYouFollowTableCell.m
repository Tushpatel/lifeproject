//
//  ActivityYouFollowTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ActivityYouFollowTableCell.h"

@interface ActivityYouFollowTableCell ()

- (IBAction)profilePressed:(id)sender;

@end


@implementation ActivityYouFollowTableCell

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    [self.delegate profileButtonOnFollowWasPressed:self];
}

@end


