//
//  PhotoPickerViewController.m
//  YM
//
//  Created by user on 29/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PhotoPickerViewController.h"
#import "PPVCTableCell.h"
#import "PPVCTableHeader.h"
#import "CommentsViewController.h"
#import "AppManager.h"
#import "Intralife.h"
#import "Reachability.h"
#import "NSDate+DateTools.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface PhotoPickerViewController () <IntralifeDelegate, UITableViewDataSource, UITableViewDelegate, GridTableCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *pickerTable;

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) IntralifeUser *user;
@property (strong, nonatomic) NSMutableArray *photos;
@property (nonatomic) BOOL photosLoaded;

@end

@implementation PhotoPickerViewController
{
    IntralifePhoto *commentPhotoData;
}

#pragma mark - Internet Connection

- (BOOL)isInternetConnection
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if(internetStatus == NotReachable) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Error"
                                              message:@"Please check your internet connection."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // needed for autolayout
    self.pickerTable.rowHeight = UITableViewAutomaticDimension;
    self.pickerTable.estimatedRowHeight = 500.0;
    
    self.intralife = [[Intralife alloc] initIntralife];
    self.intralife.delegate = self;
    
    self.photos = [[NSMutableArray alloc] init];
    
    self.photosLoaded = NO;
    
    [self.intralife observePhotosForUserWithId:self.photoData.authorId];
    [self.intralife observeUserInfo:self.photoData.authorId];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title";
    self.navigationItem.title = @"Photo";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [self.intralife cleanup];
}

#pragma mark - <IntralifeDelegate>

- (void)photo:(IntralifePhoto *)photo wasUpdatedInTimeline:(NSString *)timeline
{
    CGPoint contentOffset = self.pickerTable.contentOffset; // for avoiding jumping to the top of the table
    [self.pickerTable reloadData];
    [self.pickerTable layoutIfNeeded];
    [self.pickerTable setContentOffset:contentOffset];
}

- (void)timelineDidLoad:(NSString *)feedId
{
    self.photosLoaded = YES;
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    [[SDImageCache sharedImageCache] removeImageForKey:[self.photoData.profileImageUrl absoluteString] fromDisk:YES];
    
    self.user = user;
    [self.pickerTable reloadData];
}

// even if it's empty still required as delegate methods

- (void)photo:(IntralifePhoto *)photo wasAddedToTimeline:(NSString *)timeline
{
    
}

- (void)photo:(IntralifePhoto *)photo wasRemovedFromTimeline:(NSString *)timeline
{
    
}

- (void)photo:(NSDictionary *)photo wasOverflowedFromTimeline:(NSString *)timeline
{
    
}

//- (void)photo:(IntralifePhoto *)photo wasUnfollowed:(NSString *)timeline
- (void)userWasUnfollowed:(NSString *)userId
{

}

#pragma mark - <UITableViewDatasource>

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // likes
    NSArray *likes = [self.photoData.likes allKeys];
    BOOL likeOn = NO;
    if(likes && [likes indexOfObject:[FIRAuth auth].currentUser.uid] != NSNotFound) {
        likeOn = YES;
    }
    UIImage *likeImage;
    if(likeOn) {
        likeImage = [UIImage imageNamed:@"profile-heart-selected.png"];
    }
    else {
        likeImage = [UIImage imageNamed:@"profile-heart"];
    }
    
    // comments for this photo
    NSArray *commentsData = [self.photoData.comments allValues];
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *commentsDataSorted = [commentsData sortedArrayUsingDescriptors:@[timestampDescriptor]];
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    NSMutableArray *authorUsernames = [[NSMutableArray alloc] init];
    for(int i = 0; i < [commentsDataSorted count]; i++) {
        NSDictionary *commentData = [commentsDataSorted objectAtIndex:i];
        NSString *commentText = [commentData valueForKey:@"text"];
        [comments addObject:commentText];
        NSString *authorUsername = [commentData valueForKey:@"username"];
        [authorUsernames addObject:authorUsername];
    }
    
    NSInteger commentsCount = [comments count];
    PPVCTableCell *cell;
    switch (commentsCount) {
            //
            //NO COMMENTS
            //
        case 0:
        {
            static NSString *CellIdentifier = @"PPVCTableCell0";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:self.photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // title
            cell.title.text = self.photoData.title;
            
            // likes count
            cell.likesCount.text = [@([self.photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
        }
            break;
            
            
            //
            //1 COMMENT
            //
        case 1:
        {
            static NSString *CellIdentifier = @"PPVCTableCell1";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:self.photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // title
            cell.title.text = self.photoData.title;
            
            // likes count
            cell.likesCount.text = [@([self.photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
            
            // comments
            cell.comment1.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:0]];
            cell.comment1AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:0]];
        }
            break;
            
            
            //
            //2 COMMENTS
            //
        case 2:
        {
            static NSString *CellIdentifier = @"PPVCTableCell2";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:self.photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // title
            cell.title.text = self.photoData.title;
            
            // likes count
            cell.likesCount.text = [@([self.photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
            
            // comments
            cell.comment1.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:0]];
            cell.comment1AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:0]];
            cell.comment2.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:1]];
            cell.comment2AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:1]];
        }
            break;
            
            
            //
            //3 COMMENTS
            //
        case 3:
        {
            static NSString *CellIdentifier = @"PPVCTableCell3";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:self.photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // title
            cell.title.text = self.photoData.title;
            
            // likes count
            cell.likesCount.text = [@([self.photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
            
            // comments
            cell.comment1.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:0]];
            cell.comment1AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:0]];
            cell.comment2.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:1]];
            cell.comment2AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:1]];
            cell.comment3.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:2]];
            cell.comment3AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:2]];
        }
            break;
            
            
            //
            // >3 COMMENTS
            //
        default:
        {
            static NSString *CellIdentifier = @"PPVCTableCell4";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:self.photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // title
            cell.title.text = self.photoData.title;
            
            // likes count
            cell.likesCount.text = [@([self.photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
            
            // comments
            cell.comment1.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:0]];
            cell.comment1AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:0]];
            cell.comment2.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:1]];
            cell.comment2AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:1]];
            cell.comment3.text = [NSString stringWithFormat:@"%@", [comments objectAtIndex:2]];
            cell.comment3AuthorName.text = [NSString stringWithFormat:@"%@", [authorUsernames objectAtIndex:2]];
        }
            break;
    }
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *CellIdentifier = @"PPVCTableHeader";
    PPVCTableHeader *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // time ago
    double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
    double databaseTimestamp = self.photoData.timestamp;
    double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
    NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
    cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;
    
    // photo owner profile image
    cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
    cell.profileImageView.clipsToBounds = YES;
    [cell.profileImageView setImageWithURL:self.photoData.profileImageUrl
                          placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                   options:SDWebImageDelayPlaceholder
               usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    // name
    cell.profileName.text = self.user.username;
    
    return cell;
}

#pragma mark - IBActions


- (void)likeButtonWasPressed:(PPVCTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSString *photoId = self.photoData.photoId;
    
    NSArray *likes = [self.photoData.likes allKeys];
    BOOL likeOn = NO;
    if(likes && [likes indexOfObject:[FIRAuth auth].currentUser.uid] != NSNotFound) {
        likeOn = YES;
    }
    
    if(likeOn) { // like is on right now, so remove your like for this photo
        // remove user id from likes for this photo
        FIRDatabaseReference *likeRef = [[[[self.intralife.root child:@"photos"] child:photoId] child:@"likes"] child:[FIRAuth auth].currentUser.uid];
        [likeRef removeValue];
        
        // change button image into empty heart
        UIImage *btnImageEmpty = [UIImage imageNamed:@"profile-heart.png"];
        [cell.likeBtn setImage:btnImageEmpty forState:UIControlStateNormal];
    }
    else { // like is off right now, so add your like for this photo
        // add user id into likes for this photo
        FIRDatabaseReference *likesRef = [[[self.intralife.root child:@"photos"] child:photoId] child:@"likes"];
        NSDictionary *like = @{
                               [FIRAuth auth].currentUser.uid:@"true"
                               };
        [likesRef updateChildValues:like];
        
        //change button image into full heart
        UIImage *btnImageEmpty = [UIImage imageNamed:@"profile-heart-selected.png"];
        [cell.likeBtn setImage:btnImageEmpty forState:UIControlStateNormal];
        
        
        //
        // Activity feed
        //
        NSString *authorId = self.photoData.authorId;
        NSString *userId = [FIRAuth auth].currentUser.uid;
        NSString *likeKey = [self.user.userId stringByAppendingString:self.photoData.photoId]; // unigue key: userId + photoId Prevents adding to database many likes when like button pressed many times.
        FIRDatabaseReference *activityYouRef = [[[[self.intralife.root child:@"activity"] child:authorId] child:@"you"] child:likeKey];
        
        // add photo to activity feed if it's not there yet
        if(![authorId isEqualToString:userId]) { // do not show when you liked your own photo
            [activityYouRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                if(!snapshot.exists) {
                    NSString *activityType = @"like";
                    NSString *photoId = self.photoData.photoId;
                    NSNumber *ts = [NSNumber numberWithDouble:self.intralife.currentTimestamp];
                    NSDictionary *data = @{
                                           @"activityType": activityType,
                                           @"userId": userId, // person which liked your image
                                           @"photoId": photoId, // id of photo which was liked
                                           @"timestamp": ts
                                           };
                    [activityYouRef setValue:data];
                    // set priority for
                    double priorityDouble = 0 - ([[NSDate date] timeIntervalSince1970] * 1000.0);
                    NSNumber *priorityNumber = [NSNumber numberWithDouble:priorityDouble];
                    [activityYouRef setPriority:priorityNumber];
                }
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSLog(@"%@", error.localizedDescription);
            }];
        }
        
        // fanout to followers
        FIRDatabaseReference *usersRef = [self.intralife.root child:@"users"];
        NSString *currentUID = [FIRAuth auth].currentUser.uid;
        FIRDatabaseReference *userRef = [usersRef child:currentUID];
        [[userRef child:@"followers"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            for (FIRDataSnapshot *childSnap in snapshot.children) {
                NSString *followerId = childSnap.key;
                NSString *userId = [FIRAuth auth].currentUser.uid;
                NSString *likeKey = [userId stringByAppendingString:self.photoData.photoId]; // unigue key: userId + photoId Prevents adding to database many likes when like button pressed many times.
                FIRDatabaseReference *activityFollowingRef = [[[[self.intralife.root child:@"activity"] child:followerId] child:@"following"] child:likeKey];

                // add photo to activity feed if it's not there yet
                if(![authorId isEqualToString:followerId]) {  // if somebody you following liked your photo - do not show thet like in "following" (it will be shown in "you")
                    [activityFollowingRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        if(!snapshot.exists) {
                            NSString *activityType = @"like";
                            NSString *photoId = self.photoData.photoId;
                            NSNumber *ts = [NSNumber numberWithDouble:self.intralife.currentTimestamp];
                            NSDictionary *data = @{
                                                   @"activityType": activityType,
                                                   @"userId": userId, // person which liked somebodys image
                                                   @"photoId": photoId, // id of photo which was liked
                                                   @"timestamp": ts
                                                   };
                            [activityFollowingRef setValue:data];
                            // set priority for
                            double priorityDouble = 0 - ([[NSDate date] timeIntervalSince1970] * 1000.0);
                            NSNumber *priorityNumber = [NSNumber numberWithDouble:priorityDouble];
                            [activityFollowingRef setPriority:priorityNumber];
                        }
                    } withCancelBlock:^(NSError * _Nonnull error) {
                        NSLog(@"%@", error.localizedDescription);
                    }];
                }
            }
        }];   
    }
}

- (void)commentButtonWasPressed:(PPVCTableCell *)cell
{
    [self performSegueWithIdentifier:@"SegueToComments" sender:self];
}

- (void)moreButtonWasPressed:(PPVCTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSString *currentPhotoUid = self.photoData.authorId;
    NSString *currentUserUid = [FIRAuth auth].currentUser.uid;

    //report other people photos and delete your own
    if([currentPhotoUid isEqualToString:currentUserUid]) {
        [self addDeleteFunction:cell];
    }
    else {
        [self addReportFunction:cell];
    }
}

- (void)addDeleteFunction:(PPVCTableCell *)cell
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *deletAction = [UIAlertAction
                                  actionWithTitle:NSLocalizedString(@"Delete", @"OK action")
                                  style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction *action)
                                  {
                                      UIAlertController *alertController = [UIAlertController
                                                                            alertControllerWithTitle:@"Delete"
                                                                            message:@"Are you sure?"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                      
                                      UIAlertAction *cancelAction = [UIAlertAction
                                                                     actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                                                     style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action)
                                                                     {
                                                                         NSLog(@"Cancel action");
                                                                     }];
                                      
                                      UIAlertAction *okAction = [UIAlertAction
                                                                 actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                                                 style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                                                 {
                                                                     [self performDeletion:cell];
                                                                     
                                                                     // image is being deleted, go back
                                                                     [self.navigationController popViewControllerAnimated:YES];
                                                                 }];
                                      
                                      [alertController addAction:cancelAction];
                                      [alertController addAction:okAction];
                                      
                                      [self presentViewController:alertController animated:YES completion:nil];
                                  }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    // add buttons to allert
    [alertController addAction:deletAction];
    [alertController addAction:cancelAction];
    
    // show alert
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)addReportFunction:(PPVCTableCell *)cell
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *reportAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Report", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self performReport:cell];
                                       
                                       //report is being send, dismis modal view controller
                                       [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                   }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    // add buttons to allert
    [alertController addAction:reportAction];
    [alertController addAction:cancelAction];
    
    // show alert
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)performReport:(PPVCTableCell *)cell
{
    NSString *photoId = self.photoData.photoId;
    
    // update report for photo
    FIRDatabaseReference *photoRef = [[self.intralife.root child:@"photos"] child:photoId];
    NSDictionary *newReport = @{@"report": @"1"};
    [photoRef updateChildValues:newReport withCompletionBlock:^(NSError *error, FIRDatabaseReference *reportRef) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:@"Error occured while reporting."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Report"
                                                  message:@"This post has been reported."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)performDeletion:(PPVCTableCell *)cell
{
    NSString *photoId = self.photoData.photoId;
    
    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
    NSString *photoStorageRef = [@"photos/" stringByAppendingString:photoId];
    FIRStorageReference *photoImageRef = [storageRef child:photoStorageRef];
    [photoImageRef deleteWithCompletion:^(NSError *error){
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
            
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:@"Error occured while deleting."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else {
            // remove from "photos"
            FIRDatabaseReference *photosRef = [[self.intralife.root child:@"photos"] child:photoId];
            [photosRef removeValue];
            
            // remove from "userPhotos"
            FIRDatabaseReference *userAndFollowingPhotosRef = [[[[self.intralife.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userPhotos"] child:photoId];
            [userAndFollowingPhotosRef removeValue];
            
            // remove from "userAndFollowingPhotos"
            FIRDatabaseReference *userPhotosRef = [[[[self.intralife.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userAndFollowingPhotos"] child:photoId];
            [userPhotosRef removeValue];
        }
    }];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToComments"]) {
        CommentsViewController *commentsViewController = segue.destinationViewController;
        commentsViewController.commentPhotoData = self.photoData;
    }
}

@end
