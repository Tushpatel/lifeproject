//
//  ActivityYouLikeTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ActivityYouLikeTableCell.h"

@interface ActivityYouLikeTableCell ()

- (IBAction)profilePressed:(id)sender;
- (IBAction)photoPressed:(id)sender;

@end


@implementation ActivityYouLikeTableCell

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


