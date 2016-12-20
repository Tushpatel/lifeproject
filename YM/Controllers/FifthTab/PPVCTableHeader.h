//
//  PPVCTableHeader.h
//  YM
//
//  Created by user on 17/12/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPVCTableHeader : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *timeAgo;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *profileName;

@end
