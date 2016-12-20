//
//  PPVCTableCell.h
//  YM
//
//  Created by user on 17/12/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPVCTableCell;

@protocol GridTableCellDelegate

- (void)likeButtonWasPressed:(PPVCTableCell *)cell;
- (void)commentButtonWasPressed:(PPVCTableCell *)cell;
- (void)moreButtonWasPressed:(PPVCTableCell *)cell;

@end

@interface PPVCTableCell : UITableViewCell

@property (weak, nonatomic) id<GridTableCellDelegate> delegate;

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
