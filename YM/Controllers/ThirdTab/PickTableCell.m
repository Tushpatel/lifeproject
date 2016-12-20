//
//  PickTableCell.m
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PickTableCell.h"

@interface PickTableCell ()

- (IBAction)likePressed:(id)sender;
- (IBAction)commentPressed:(id)sender;
- (IBAction)morePressed:(id)sender;

@end

@implementation PickTableCell

#pragma mark - IBActions

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
