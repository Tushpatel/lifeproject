//
//  CommentsViewController.h
//  YM
//
//  Created by user on 03/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IntralifePhoto.h"

@interface CommentsViewController : UIViewController

@property (strong, nonatomic) IntralifePhoto *commentPhotoData;
@property (assign, nonatomic) BOOL userAndFollowingPhotos; // set to YES for first tab, because it uses "userAndFollowingPhotos" feed

@end

@interface OldCommentCell : UITableViewCell

@end

