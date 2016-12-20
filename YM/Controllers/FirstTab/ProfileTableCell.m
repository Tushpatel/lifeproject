//
//  ProfileTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ProfileTableCell.h"

@interface ProfileTableCell ()

- (IBAction)profilePressed:(id)sender;
- (IBAction)likePressed:(id)sender;
- (IBAction)commentPressed:(id)sender;
- (IBAction)morePressed:(id)sender;

@end

@implementation ProfileTableCell

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    [self.delegate profileButtonWasPressed:self];
}

- (IBAction)likePressed:(id)sender
{
    [self.delegate likeButtonWasPressed:self];
}

- (IBAction)commentPressed:(id)sender
{
    [self.delegate commentButtonWasPressed:self];
}

- (IBAction)morePressed:(id)sender
{
    [self.delegate moreButtonWasPressed:self];
}

@end


