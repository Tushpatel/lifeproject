//
//  ActivityYouLikeTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivityYouLikeTableCell;

@protocol ActivityYouLikeTableCellDelegate

- (void)profileButtonOnLikeWasPressed:(ActivityYouLikeTableCell *)cell;
- (void)photoButtonWasPressed:(ActivityYouLikeTableCell *)cell;

@end

@interface ActivityYouLikeTableCell : UITableViewCell

@property (weak, nonatomic) id<ActivityYouLikeTableCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIButton *profileImageBtn;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIButton *photoBtn;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@end
