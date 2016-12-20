//
//  ActivityFollowingFollowTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivityFollowingFollowTableCell;

@protocol ActivityFollowingFollowTableCellDelegate

- (void)profileButtonOnFollowWasPressed:(ActivityFollowingFollowTableCell *)cell;

@end

@interface ActivityFollowingFollowTableCell : UITableViewCell

@property (weak, nonatomic) id<ActivityFollowingFollowTableCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIButton *profileImageBtn;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *username1Label; // person who followed somebody
@property (nonatomic, weak) IBOutlet UILabel *username2Label; // person which was followed

@end
