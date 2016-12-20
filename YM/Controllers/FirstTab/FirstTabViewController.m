//
//  FirstTabViewController.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FirstTabViewController.h"
#import "AppManager.h"
#import "ProfileTableCell.h"
#import "CommentsViewController.h"
#import "Intralife.h"
#import "ArrayUtils.h"
#import "PickViewController.h"
#import "IntralifePhoto.h"
#import "Reachability.h"
#import "NSDate+DateTools.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FirstTabViewController ()  <IntralifeDelegate, UITableViewDataSource, UITableViewDelegate, ProfileTableCellDelegate>

@property(nonatomic, weak) IBOutlet UITableView *profileTableView;
@property(nonatomic, weak) IBOutlet UILabel *noPostsLabel;

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) NSMutableSet *users;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *photoImages;
@property (nonatomic) BOOL photosLoaded;

@end

@implementation FirstTabViewController
{
    NSInteger chosenCellIndex;
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
    
    self.intralife = [[Intralife alloc] initIntralife];
    self.intralife.delegate = self;
    
    self.users = [[NSMutableSet alloc] init];
    self.photos = [[NSMutableArray alloc] init];
    self.photoImages = [[NSMutableArray alloc] init];
    
    // needed for autolayout
    self.profileTableView.rowHeight = UITableViewAutomaticDimension;
    self.profileTableView.estimatedRowHeight = 500.0;
    
    self.photosLoaded = NO;

    [self.intralife observeUserAndFollowingPhotos];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden = NO;
    
    // set navigation controller logo
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigation-logo.png"]];
    
    // set navigation controller title
    self.navigationItem.title = @"IntraLife";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    // save current tab in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"previousTab"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - <IntralifeDelegate>

- (void)photo:(IntralifePhoto *)photo wasAddedToTimeline:(NSString *)timeline
{
    // observe every new user
    NSString *userId = photo.authorId;
    if(![self.users containsObject:userId]) {
        [self.users addObject:userId];
        [self.intralife observeUserInfo:userId];
    }

    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];

    // get photo image from firebase storage
    NSString *photoId = photo.photoId;
    NSString *photoPath = [@"photos/" stringByAppendingString:photoId];
    FIRStorageReference *storagePhotoRef = [storageRef child:photoPath];
    [storagePhotoRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
        if (error != nil) {
            NSLog(@"... photo download error ... %@", error.description);
        } else {
            photo.photoImageUrl = URL;

            // get profile image from firebase storage
            NSString *authorId = photo.authorId;
            NSString *profileImagePath = [@"profiles/" stringByAppendingString:authorId];
            FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
            [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                if (error != nil) {
                    NSLog(@"... profile image download error ... %@", error.description);
                }
                    photo.profileImageUrl = URL;
                    [self.photos addObject:photo];
                    
                    // sort according to timestamp (the same as priority)
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
                    NSArray *photosSorted = [self.photos sortedArrayUsingDescriptors:@[timestampDescriptor]];
                    self.photos = [NSMutableArray arrayWithArray:photosSorted];
                    
                    [self.profileTableView reloadData];
            }];
        }
    }];
}

- (void)photo:(IntralifePhoto *)photo wasRemovedFromTimeline:(NSString *)timeline
{
    [self.photos removeObject:photo];
    [self.profileTableView reloadData];
}

- (void)photo:(IntralifePhoto *)photo wasUpdatedInTimeline:(NSString *)timeline
{
    CGPoint contentOffset = self.profileTableView.contentOffset; // for avoiding jumping to the top of the table
    [self.profileTableView reloadData];
    [self.profileTableView layoutIfNeeded];
    [self.profileTableView setContentOffset:contentOffset];
}

- (void)photo:(NSDictionary *)photo wasOverflowedFromTimeline:(NSString *)timeline
{
    
}

- (void)timelineDidLoad:(NSString *)feedId
{
    self.photosLoaded = YES;
}

- (void)userWasUnfollowed:(NSString *)userId
{
    for(int i = 0; i < [self.photos count]; i++) {
        IntralifePhoto *currentPhoto = [self.photos objectAtIndex:i];
        NSString *currentPhotoUserId = currentPhoto.authorId;
        if([currentPhotoUserId isEqual:userId]) {
            [self.photos removeObject:currentPhoto];
        }
    }
    
    [self.profileTableView reloadData];
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    // remove profile image from SDImageCache so that it would be updated
    IntralifePhoto *photo;
    NSString *userId = user.userId;
    for(int i = 0; i < [self.photos count]; i++) {
        photo = [self.photos objectAtIndex:i];
        if([photo.authorId isEqualToString:userId]) {
            [[SDImageCache sharedImageCache] removeImageForKey:[photo.profileImageUrl absoluteString] fromDisk:YES];
        }
    }
    
    [self.profileTableView reloadData];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([self.photos count] > 0) {
        self.noPostsLabel.hidden = YES;
    }
    else {
        self.noPostsLabel.hidden = NO;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.row];

    // likes
    NSArray *likes = [photoData.likes allKeys];
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
    NSArray *commentsData = [photoData.comments allValues];
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
    ProfileTableCell *cell;
    switch (commentsCount) {
            //
            //NO COMMENTS
            //
        case 0:
        {
            static NSString *CellIdentifier = @"ProfileTableCell0";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // time ago
            double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
            double databaseTimestamp = photoData.timestamp;
            double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
            NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
            cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];

            // photo owner profile image
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
            cell.profileImageView.clipsToBounds = YES;
            [cell.profileImageView sd_setImageWithURL:photoData.profileImageUrl
                                     placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                              options:SDWebImageDelayPlaceholder];

            // photo owner username
            cell.profileName.text = photoData.authorUsername;
            
            // title
            cell.title.text = photoData.title;

            // likes count
            cell.likesCount.text = [@([photoData.likes count]) stringValue];
            
            // likes image (filled heart or empty heart)
            [cell.likeBtn setImage:likeImage forState:UIControlStateNormal];
        }
            break;
            
            
            //
            //1 COMMENT
            //
        case 1:
        {
            static NSString *CellIdentifier = @"ProfileTableCell1";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // time ago
            double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
            double databaseTimestamp = photoData.timestamp;
            double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
            NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
            cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // photo owner profile image
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
            cell.profileImageView.clipsToBounds = YES;
            [cell.profileImageView sd_setImageWithURL:photoData.profileImageUrl
                                     placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                              options:SDWebImageDelayPlaceholder];

            // photo owner username
            cell.profileName.text = photoData.authorUsername;
            
            // title
            cell.title.text = photoData.title;
            
            // likes count
            cell.likesCount.text = [@([photoData.likes count]) stringValue];
            
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
            static NSString *CellIdentifier = @"ProfileTableCell2";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // time ago
            double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
            double databaseTimestamp = photoData.timestamp;
            double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
            NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
            cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // photo owner profile image
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
            cell.profileImageView.clipsToBounds = YES;
            [cell.profileImageView sd_setImageWithURL:photoData.profileImageUrl
                                     placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                              options:SDWebImageDelayPlaceholder];
            
            // photo owner username
            cell.profileName.text = photoData.authorUsername;
            
            // title
            cell.title.text = photoData.title;
            
            // likes count
            cell.likesCount.text = [@([photoData.likes count]) stringValue];
            
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
            static NSString *CellIdentifier = @"ProfileTableCell3";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // time ago
            double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
            double databaseTimestamp = photoData.timestamp;
            double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
            NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
            cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;
            
            // main photo
            [cell.collectionImageView sd_setImageWithURL:photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // photo owner profile image
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
            cell.profileImageView.clipsToBounds = YES;
            [cell.profileImageView sd_setImageWithURL:photoData.profileImageUrl
                                     placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                              options:SDWebImageDelayPlaceholder];
            
            // photo owner username
            cell.profileName.text = photoData.authorUsername;
            
            
            // title
            cell.title.text = photoData.title;
            
            // likes count
            cell.likesCount.text = [@([photoData.likes count]) stringValue];
            
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
            static NSString *CellIdentifier = @"ProfileTableCell4";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            [cell setDelegate:self];
            
            // time ago
            double currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
            double databaseTimestamp = photoData.timestamp;
            double timeAgo = (currentTimestamp - databaseTimestamp) / 1000;
            NSDate *timeAgoDate = [NSDate dateWithTimeIntervalSinceNow:timeAgo];
            cell.timeAgo.text = timeAgoDate.shortTimeAgoSinceNow;

            // main photo
            [cell.collectionImageView sd_setImageWithURL:photoData.photoImageUrl
                                        placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];
            
            // photo owner profile image
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
            cell.profileImageView.clipsToBounds = YES;
            [cell.profileImageView sd_setImageWithURL:photoData.profileImageUrl
                                     placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                              options:SDWebImageDelayPlaceholder];
            
            // photo owner username
            cell.profileName.text = photoData.authorUsername;
            
            // title
            cell.title.text = photoData.title;
            
            // likes count
            cell.likesCount.text = [@([photoData.likes count]) stringValue];
            
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

#pragma mark - <ProfileTableCellDelegate>

- (void)profileButtonWasPressed:(ProfileTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)likeButtonWasPressed:(ProfileTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    NSInteger imageIndex = indexPath.row;
    IntralifePhoto *photoData = [self.photos objectAtIndex:imageIndex];
    NSString *photoId = photoData.photoId;
    
    NSArray *likes = [photoData.likes allKeys];
    BOOL likeOn = NO;
    if(likes && [likes indexOfObject:[FIRAuth auth].currentUser.uid] != NSNotFound) {
        likeOn = YES;
    }
    
    if(likeOn) { // like is on right now
        // remove user id from likes for this photo
        FIRDatabaseReference *likeRef = [[[[self.intralife.root child:@"photos"] child:photoId] child:@"likes"] child:[FIRAuth auth].currentUser.uid];
        [likeRef removeValue];
        
        // change button image into empty heart
        UIImage *btnImageEmpty = [UIImage imageNamed:@"profile-heart.png"];
        [cell.likeBtn setImage:btnImageEmpty forState:UIControlStateNormal];
    }
    else { // like is off right now
        // add user id into likes for this photo
        FIRDatabaseReference *likesRef = [[[self.intralife.root child:@"photos"] child:photoId] child:@"likes"];
        NSDictionary *like = @{
                               [FIRAuth auth].currentUser.uid:@"true"
                               };
        [likesRef updateChildValues:like];
        
        // change button image into full heart
        UIImage *btnImageEmpty = [UIImage imageNamed:@"profile-heart-selected.png"];
        [cell.likeBtn setImage:btnImageEmpty forState:UIControlStateNormal];

        //
        // Activity feed
        //
        NSString *authorId = photoData.authorId;
        NSString *userId = [FIRAuth auth].currentUser.uid;
        NSString *likeKey = [/*self.user.userId*/  [FIRAuth auth].currentUser.uid stringByAppendingString:photoData.photoId]; // unigue key: userId + photoId Prevents adding to database many likes when like button pressed many times.
        FIRDatabaseReference *activityYouRef = [[[[self.intralife.root child:@"activity"] child:authorId] child:@"you"] child:likeKey];
        
        
        // add photo to activity feed if it's not there yet
        if(![authorId isEqualToString:userId]) { // do not show when you liked your own photo
            [activityYouRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                if(!snapshot.exists) {
                    NSString *activityType = @"like";
                    NSString *photoId = photoData.photoId;
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
                NSString *likeKey = [userId stringByAppendingString:photoData.photoId]; // unigue key: userId + photoId Prevents adding to database many likes when like button pressed many times.
                FIRDatabaseReference *activityFollowingRef = [[[[self.intralife.root child:@"activity"] child:followerId] child:@"following"] child:likeKey];
                
                // add photo to activity feed if it's not there yet
                if(![authorId isEqualToString:followerId]) {  // if somebody you following liked your photo - do not show thet like in "following" (it will be shown in "you")
                    [activityFollowingRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        if(!snapshot.exists) {
                            NSString *activityType = @"like";
                            NSString *photoId = photoData.photoId;
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

- (void)commentButtonWasPressed:(ProfileTableCell *)cell
{
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    commentPhotoData = [self.photos objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"SegueToComments" sender:self];
}

- (void)moreButtonWasPressed:(ProfileTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.row];
    NSString *currentPhotoUid = photoData.authorId;
    NSString *currentUserUid = [FIRAuth auth].currentUser.uid;
    
    //report other people photos and delete your own
    if([currentPhotoUid isEqualToString:currentUserUid]) {
        [self addDeleteFunction:cell];
    }
    else {
        [self addReportFunction:cell];
    }
}

- (void)addDeleteFunction:(ProfileTableCell *)cell
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil//@"Delete"
                                          message:nil//@"Are you sure?"
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

- (void)addReportFunction:(ProfileTableCell *)cell
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

- (void)performReport:(ProfileTableCell *)cell
{
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.row];
    NSString *photoId = photoData.photoId;
    
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

- (void)performDeletion:(ProfileTableCell *)cell
{
    NSIndexPath *indexPath = [self.profileTableView indexPathForCell:cell];
    IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.row];
    NSString *photoId = photoData.photoId;
    
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
    if([segue.identifier isEqualToString:@"SegueToComments"]) {
        CommentsViewController *commentsViewController = segue.destinationViewController;
        commentsViewController.commentPhotoData = commentPhotoData;
        commentsViewController.userAndFollowingPhotos = YES;
    }
    else if ([segue.identifier isEqualToString:@"SegueToProfile"]) {
        IntralifePhoto *photoData = [self.photos objectAtIndex:chosenCellIndex];
        [AppManager sharedAppManager].uid = photoData.authorId;
    }
}

@end
