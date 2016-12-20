//
//  PPVCTableCell.m
//  YM
//
//  Created by user on 17/12/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PPVCTableCell.h"

@interface PPVCTableCell ()

- (IBAction)likePressed:(id)sender;
- (IBAction)commentPressed:(id)sender;
- (IBAction)morePressed:(id)sender;

@end

@implementation PPVCTableCell

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
