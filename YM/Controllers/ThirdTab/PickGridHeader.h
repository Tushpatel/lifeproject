//
//  PickGridHeader.h
//  YM
//
//  Created by user on 09/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PickGridHeaderDelegate

- (void)followWasPressed:(id)sender;
- (void)followingWasPressed:(id)sender;
- (void)editProfileWasPressed:(id)sender;

@end

@interface PickGridHeader : UICollectionReusableView

@property (weak, nonatomic) id<PickGridHeaderDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *profileImageBtn;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *profileName;

@property (weak, nonatomic) IBOutlet UILabel *postsCount;
@property (weak, nonatomic) IBOutlet UILabel *followersCount;
@property (weak, nonatomic) IBOutlet UILabel *followingCount;
@property (weak, nonatomic) IBOutlet UILabel *bio;
@property (weak, nonatomic) IBOutlet UIButton *websiteBtn;

@property (weak, nonatomic) IBOutlet UIImageView *flag1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *flag2ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *flag3ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *flag4ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *flag5ImageView;

@property (nonatomic, weak) IBOutlet UIButton *followBtn;
@property (nonatomic, weak) IBOutlet UIButton *followingBtn;
@property (nonatomic, weak) IBOutlet UIButton *editProfileBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bioConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bioHeightConstraint;

@end
