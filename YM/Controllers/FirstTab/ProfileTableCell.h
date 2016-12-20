//
//  ProfileTableCell.h
//  YM
//
//  Created by user on 02/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProfileTableCell;

@protocol ProfileTableCellDelegate

- (void)profileButtonWasPressed:(ProfileTableCell *)cell;
- (void)likeButtonWasPressed:(ProfileTableCell *)cell;
- (void)commentButtonWasPressed:(ProfileTableCell *)cell;
- (void)moreButtonWasPressed:(ProfileTableCell *)cell;

@end

@interface ProfileTableCell : UITableViewCell

@property (weak, nonatomic) id<ProfileTableCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *timeAgo;
@property (nonatomic, weak) IBOutlet UIButton *profileImageBtn;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *profileName;
@property (nonatomic, weak) IBOutlet UIImageView *collectionImageView;
@property (nonatomic, weak) IBOutlet UIButton *likeBtn;
@property (nonatomic, weak) IBOutlet UILabel *likesCount;
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *comment1;
@property (nonatomic, weak) IBOutlet UILabel *comment2;
@property (nonatomic, weak) IBOutlet UILabel *comment3;
@property (nonatomic, weak) IBOutlet UILabel *comment1AuthorName;
@property (nonatomic, weak) IBOutlet UILabel *comment2AuthorName;
@property (nonatomic, weak) IBOutlet UILabel *comment3AuthorName;

@end
