//
//  FollowTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FollowTableCell;

@protocol FollowTableCellDelegate

- (void)followButtonWasPressed:(FollowTableCell *)cell;

@end

@interface FollowTableCell : UITableViewCell

@property (weak, nonatomic) id<FollowTableCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *profileName;
@property (nonatomic, weak) IBOutlet UILabel *profileUserName;
@property (nonatomic, weak) IBOutlet UIButton *followBtn;

@end
