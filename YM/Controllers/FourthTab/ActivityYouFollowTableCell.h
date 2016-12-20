//
//  ActivityYouFollowTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivityYouFollowTableCell;

@protocol ActivityYouFollowTableCellDelegate

- (void)profileButtonOnFollowWasPressed:(ActivityYouFollowTableCell *)cell;

@end

@interface ActivityYouFollowTableCell : UITableViewCell

@property (weak, nonatomic) id<ActivityYouFollowTableCellDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIButton *profileImageBtn;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;

@end
