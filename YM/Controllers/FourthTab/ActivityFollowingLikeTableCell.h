//
//  ActivityFollowingLikeTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivityFollowingLikeTableCell;

@protocol ActivityFollowingLikeTableCellDelegate

- (void)profileButtonOnLikeWasPressed:(ActivityFollowingLikeTableCell *)cell;
- (void)photoButtonWasPressed:(ActivityFollowingLikeTableCell *)cell;

@end

@interface ActivityFollowingLikeTableCell : UITableViewCell

@property (weak, nonatomic) id<ActivityFollowingLikeTableCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIButton *profileImageBtn;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIButton *photoBtn;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@end
