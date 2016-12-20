//
//  PickGridViewController.m
//  YM
//
//  Created by user on 16/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "PickGridViewController.h"
#import "PickViewController.h"
#import "PickGridHeader.h"
#import "PickGridCell.h"
#import "PhotoPickerViewController.h"
#import "Intralife.h"
#import "AppManager.h"
#import "UIImage+Bordered.h"
#import "FollowersViewController.h"
#import "FollowingViewController.h"
#import "Reachability.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Load.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface PickGridViewController () <IntralifeDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PickGridHeaderDelegate>

- (IBAction)profilePressed:(id)sender;
- (IBAction)tableVewPressed:(id)sender;
- (IBAction)followersPressed:(id)sender;
- (IBAction)followingPressed:(id)sender;

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) IntralifeUser *user;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *photoImages;
@property (nonatomic) BOOL photosLoaded;
@property (strong, nonatomic) NSMutableArray *followers;
@property (strong, nonatomic) NSMutableArray *following;

@end

@implementation PickGridViewController
{
    BOOL isFollowButton;
    BOOL isFollowingButton;
    BOOL isEditProfileButton;
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
    
    self.photos = [[NSMutableArray alloc] init];
    self.photoImages = [[NSMutableArray alloc] init];
    self.followers = [[NSMutableArray alloc] init];
    self.following = [[NSMutableArray alloc] init];
    
    self.photosLoaded = NO;
    
    [self.intralife observeUserInfo:[AppManager sharedAppManager].uid];
    [self.intralife observePhotosForUserWithId:[AppManager sharedAppManager].uid];
    [self.intralife observeFolloweesForUser:[AppManager sharedAppManager].uid];
    [self.intralife observeFollowersForUser:[AppManager sharedAppManager].uid];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // see if "Edit Profile" or Follow/Following button has to be displayed
    NSString *currentUserId = [AppManager sharedAppManager].uid;
    if([currentUserId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        isEditProfileButton = YES;
        return;
    }
    
    // see if "Follow" or "Following" button has to be displayed
    FIRDatabaseReference *followingRef = [[[self.intralife.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"following"];
    __block BOOL isFollowing = NO;
    [followingRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        for (FIRDataSnapshot *childSnap in snapshot.children) {
            NSString *followingId = childSnap.key;
            if([[AppManager sharedAppManager].uid isEqualToString:followingId]) {
                isFollowing = YES;
                break;
            }
        }
        if(isFollowing) {
            isFollowingButton = YES;
        }
        else {
            isFollowButton = YES;
        }
        
        [self.collectionView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // check if the back button was pressed
    if (self.isMovingFromParentViewController) {
        NSLog(@"Back button was pressed.");
        [self.intralife cleanup];
    }
}

#pragma mark - <IntralifeDelegate>

- (void)photo:(IntralifePhoto *)photo wasAddedToTimeline:(NSString *)timeline
{
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
                
                [self.collectionView reloadData];
            }];
        }
    }];
}

- (void)photo:(IntralifePhoto *)photo wasRemovedFromTimeline:(NSString *)timeline
{
    [self.photos removeObject:photo];
    [self.collectionView reloadData];
}

- (void)photo:(IntralifePhoto *)photo wasUpdatedInTimeline:(NSString *)timeline
{
    [self.collectionView reloadData];
}

- (void)timelineDidLoad:(NSString *)feedId
{
    self.photosLoaded = YES;
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
    
    // get profile image from firebase storage
    NSString *userId = user.userId;
    NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
    FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
    [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
        if (error != nil) {
            NSLog(@"... profile image download error ... %@", error.description);
        }
        user.profileImageUrl = URL;
        self.user = user;
        
        [self.collectionView reloadData];
    }];
}

- (void)follower:(IntralifeUser *)follower startedFollowing:(IntralifeUser *)followee
{
    // is somebody started following current user profile - increase number of followers
    if([followee.userId isEqualToString:[AppManager sharedAppManager].uid]) {
        [self.followers addObject:follower];
        [self.collectionView reloadData];
    }
    
    // if current user profile started following somebody (could be from other device) - increase number of following
    if([follower.userId isEqualToString:[AppManager sharedAppManager].uid]) {
        [self.following addObject:followee];
        [self.collectionView reloadData];
    }
    
    // "Follow" button was pressed - you started following current user profile. Change button into "Following"
    // (at first check if you are not looking at your own profile.
    // If that's the case - "Edit Profile" button will be displayed)
    if(!isEditProfileButton &&[follower.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        isFollowButton = NO;
        isFollowingButton = YES;
        [self.collectionView reloadData];
    }
}

- (void) follower:(IntralifeUser *)follower stoppedFollowing:(IntralifeUser *)followee
{
    // is somebody stoped following current user profile - decrease number of followers
    if ([followee.userId isEqualToString:[AppManager sharedAppManager].uid]) {
        [self.followers removeObject:follower];
        [self.collectionView reloadData];
    }
    
    // if current user profile stoped following somebody (could be from other device) - decrease number of following
    if ([follower.userId isEqualToString:[AppManager sharedAppManager].uid]) {
        [self.following removeObject:followee];
        [self.collectionView reloadData];
    }
    
    // "Following" button was pressed - you stoped following current user profile. Change button into "Follow"
    // (at first check if you are not looking at your own profile.
    // If that's the case - "Edit Profile" button will be displayed)
    if(!isEditProfileButton &&[follower.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        isFollowButton = YES;
        isFollowingButton = NO;
        [self.collectionView reloadData];
    }
}

- (void)followersDidLoad:(NSString *)userId
{
    NSLog(@"... followersDidLoad ...");
    
    [self.collectionView reloadData];
}

- (void)followeesDidLoad:(NSString *)userId
{
    NSLog(@"... followeesDidLoad ...");
    
    [self.collectionView reloadData];
}

// even if it's empty still required as delegate methods

//- (void)photo:(IntralifePhoto *)photo wasUnfollowed:(NSString *)timeline
- (void)userWasUnfollowed:(NSString *)userId
{

}

- (void)photo:(NSDictionary *)photo wasOverflowedFromTimeline:(NSString *)timeline
{
    
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.photos count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PickGridCell";
    PickGridCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.item];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    [cell.imageView sd_setImageWithURL:photoData.photoImageUrl
                      placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];

    return cell;
}

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Header";
    PickGridHeader *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                              withReuseIdentifier:CellIdentifier
                                                                     forIndexPath:indexPath];
    
    [cell setDelegate:self];
    
    
    // photo owner profile image
    cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
    cell.profileImageView.clipsToBounds = YES;
    [cell.profileImageView setImageWithURL:self.user.profileImageUrl
                          placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                   options:SDWebImageDelayPlaceholder
               usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    
    //
    // postsCount
    //
    NSInteger photosCount = [self.photos count];
    cell.postsCount.text = [@(photosCount) stringValue];
    
    
    //
    // followers
    //
    NSInteger followersCount = [self.followers count];
    cell.followersCount.text = [@(followersCount) stringValue];
    
    
    //
    // following
    //
    NSInteger followingCount = [self.following count];
    cell.followingCount.text = [@(followingCount) stringValue];
    
    
    //
    // name
    //
    cell.profileName.text = self.user.name;
    
    
    //
    // bio
    //
    NSString *bio = self.user.bio;
    if([bio length] == 0) {
        cell.bio.hidden = YES;
    }
    else {
        cell.bio.hidden = NO;
        cell.bio.text = bio;
        
        // only way could get working - works for table, bot not for collection (look later for better solution)
        CGFloat bioHeight = [self.user.bio boundingRectWithSize:CGSizeMake(self.collectionView.frame.size.width - 16, MAXFLOAT)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{
                                                                  NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:17]
                                                                  }
                                                        context:nil].size.height;
        cell.bioHeightConstraint.constant = ceil(bioHeight);
    }
    
    
    //
    // website
    //
    NSString *website = self.user.website;
    if([website length] == 0) {
        cell.websiteBtn.hidden = YES;
        cell.bioConstraint.constant = 10.0;
    }
    else {
        cell.websiteBtn.hidden = NO;
        [cell.websiteBtn setTitle:website forState:UIControlStateNormal];
        cell.bioConstraint.constant = 41.0;
    }
    
    
    //
    // flags
    //
    cell.flag1ImageView.hidden = YES;
    cell.flag2ImageView.hidden = YES;
    cell.flag3ImageView.hidden = YES;
    cell.flag4ImageView.hidden = YES;
    cell.flag5ImageView.hidden = YES;
    
    // flags array
    NSArray *countries = self.user.countries;
    
    NSInteger countriesCount = [countries count];
    switch (countriesCount) {
        case 2:
        {
            // flag 1
            NSString *flag1Str = [countries objectAtIndex:0];
            UIImage *flag1Image = [UIImage imageNamed:flag1Str];
            UIImage *borderedFlag1Image = [flag1Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag1ImageView.image = borderedFlag1Image;
            
            // flag 2
            NSString *flag2Str = [countries objectAtIndex:1];
            UIImage *flag2Image = [UIImage imageNamed:flag2Str];
            UIImage *borderedFlag2Image = [flag2Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag2ImageView.image = borderedFlag2Image;
            
            cell.flag1ImageView.hidden = NO;
            cell.flag2ImageView.hidden = NO;
        }
            break;
            
        case 3:
        {
            // flag 1
            NSString *flag1Str = [countries objectAtIndex:0];
            UIImage *flag1Image = [UIImage imageNamed:flag1Str];
            UIImage *borderedFlag1Image = [flag1Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag1ImageView.image = borderedFlag1Image;
            
            // flag 2
            NSString *flag2Str = [countries objectAtIndex:1];
            UIImage *flag2Image = [UIImage imageNamed:flag2Str];
            UIImage *borderedFlag2Image = [flag2Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag2ImageView.image = borderedFlag2Image;
            
            // flag 3
            NSString *flag3Str = [countries objectAtIndex:2];
            UIImage *flag3Image = [UIImage imageNamed:flag3Str];
            UIImage *borderedFlag3Image = [flag3Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag3ImageView.image = borderedFlag3Image;
            
            cell.flag1ImageView.hidden = NO;
            cell.flag2ImageView.hidden = NO;
            cell.flag3ImageView.hidden = NO;
        }
            break;
            
        case 4:
        {
            // flag 1
            NSString *flag1Str = [countries objectAtIndex:0];
            UIImage *flag1Image = [UIImage imageNamed:flag1Str];
            UIImage *borderedFlag1Image = [flag1Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag1ImageView.image = borderedFlag1Image;
            
            // flag 2
            NSString *flag2Str = [countries objectAtIndex:1];
            UIImage *flag2Image = [UIImage imageNamed:flag2Str];
            UIImage *borderedFlag2Image = [flag2Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag2ImageView.image = borderedFlag2Image;
            
            // flag 3
            NSString *flag3Str = [countries objectAtIndex:2];
            UIImage *flag3Image = [UIImage imageNamed:flag3Str];
            UIImage *borderedFlag3Image = [flag3Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag3ImageView.image = borderedFlag3Image;
            
            // flag 4
            NSString *flag4Str = [countries objectAtIndex:3];
            UIImage *flag4Image = [UIImage imageNamed:flag4Str];
            UIImage *borderedFlag4Image = [flag4Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag4ImageView.image = borderedFlag4Image;
            
            cell.flag1ImageView.hidden = NO;
            cell.flag2ImageView.hidden = NO;
            cell.flag3ImageView.hidden = NO;
            cell.flag4ImageView.hidden = NO;
        }
            break;
            
        case 5:
        {
            // flag 1
            NSString *flag1Str = [countries objectAtIndex:0];
            UIImage *flag1Image = [UIImage imageNamed:flag1Str];
            UIImage *borderedFlag1Image = [flag1Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag1ImageView.image = borderedFlag1Image;
            
            // flag 2
            NSString *flag2Str = [countries objectAtIndex:1];
            UIImage *flag2Image = [UIImage imageNamed:flag2Str];
            UIImage *borderedFlag2Image = [flag2Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag2ImageView.image = borderedFlag2Image;
            
            // flag 3
            NSString *flag3Str = [countries objectAtIndex:2];
            UIImage *flag3Image = [UIImage imageNamed:flag3Str];
            UIImage *borderedFlag3Image = [flag3Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag3ImageView.image = borderedFlag3Image;
            
            // flag 4
            NSString *flag4Str = [countries objectAtIndex:3];
            UIImage *flag4Image = [UIImage imageNamed:flag4Str];
            UIImage *borderedFlag4Image = [flag4Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag4ImageView.image = borderedFlag4Image;
            
            // flag 5
            NSString *flag5Str = [countries objectAtIndex:4];
            UIImage *flag5Image = [UIImage imageNamed:flag5Str];
            UIImage *borderedFlag5Image = [flag5Image imageBorderedWithColor:[UIColor lightGrayColor] borderWidth:2.0];
            cell.flag5ImageView.image = borderedFlag5Image;
            
            cell.flag1ImageView.hidden = NO;
            cell.flag2ImageView.hidden = NO;
            cell.flag3ImageView.hidden = NO;
            cell.flag4ImageView.hidden = NO;
            cell.flag5ImageView.hidden = NO;
        }
            break;
            
        default:
            break;
    }
    
    // see which button to display
    if(isEditProfileButton) {
        cell.editProfileBtn.hidden = NO;
    }
    else {
        cell.editProfileBtn.hidden = YES;
    }
    
    if(isFollowButton) {
        cell.followBtn.hidden = NO;
    }
    else {
        cell.followBtn.hidden = YES;
    }
    
    if(isFollowingButton) {
        cell.followingBtn.hidden = NO;
    }
    else {
        cell.followingBtn.hidden = YES;
    }
    
    return cell;
}

// header height
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    CGFloat bioHeight = [self.user.bio boundingRectWithSize:CGSizeMake(self.collectionView.frame.size.width - 16, MAXFLOAT)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{
                                                              NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:17]
                                                              }
                                                    context:nil].size.height;
    
    CGFloat webHeight = 20.0;
    
    CGFloat labelWidth = self.collectionView.frame.size.width;
    
    // just bio
    if(([self.user.bio length] != 0) && ([self.user.website length] == 0)) {
        return CGSizeMake(labelWidth, 400.0 + bioHeight + 10.0);
    }
    
    
    // just url
    if(([self.user.bio length] == 0) && ([self.user.website length] != 0)) {
        return CGSizeMake(labelWidth, 400.0 + webHeight + 10.0);
    }
    
    
    // bio and url
    if(([self.user.bio length] != 0) && ([self.user.website length] != 0)) {
        return CGSizeMake(labelWidth, 400.0 + bioHeight + webHeight + 20.0);
    }
    
    // no bio, no url
    return CGSizeMake(labelWidth, 400.0);
}

#pragma mark – <UICollectionViewDelegateFlowLayout>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 5.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger cellSize = floor((([[UIScreen mainScreen] bounds].size.width) - 20) / 3);
    return CGSizeMake(cellSize, cellSize);
}

#pragma mark - <ProfileTableHeaderDelegate>

- (void)editProfileWasPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToEditProfile" sender:self];
}

- (void)followWasPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self.intralife startFollowingUser:[AppManager sharedAppManager].uid];
    
    //
    // Activity feed
    //
    [IntralifeUser loadFromRoot:self.intralife.root withUserId:[FIRAuth auth].currentUser.uid completionBlock:^(IntralifeUser *currentUser) {
        NSString *userId = self.user.userId;
        NSString *currentUserId = currentUser.userId;
        NSString *followKey = currentUserId; // unigue key: currentUser.userId Prevents adding to database many follows when follow button pressed many times.
        FIRDatabaseReference *activityYouRef = [[[[self.intralife.root child:@"activity"] child:userId] child:@"you"] child:followKey];
        NSString *activityType = @"follow";
        NSNumber *ts = [NSNumber numberWithDouble:self.intralife.currentTimestamp];
        NSDictionary *data = @{
                               @"activityType": activityType,
                               @"userId": currentUserId, // person which is following you
                               @"timestamp": ts
                               };
        [activityYouRef setValue:data];
        
        ///// fanout to followers /////
        FIRDatabaseReference *usersRef = [self.intralife.root child:@"users"];
        NSString *currentUID = [FIRAuth auth].currentUser.uid;
        FIRDatabaseReference *userRef = [usersRef child:currentUID];
        [[userRef child:@"followers"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            for (FIRDataSnapshot *childSnap in snapshot.children) {
                NSString *followerId = childSnap.key;
                NSString *followKey = [currentUser.userId stringByAppendingString:self.user.userId]; // unigue key: currentUser.userId + self.user.userId Prevents adding to database many follows when follow button pressed many times.
                if(![userId isEqualToString:followerId]) { // if somebody you following, followed you - do not show thet follow in "following" (it will be shown in "you")
                    FIRDatabaseReference *activityFollowingRef = [[[[self.intralife.root child:@"activity"] child:followerId] child:@"following"] child:followKey];
                    NSString *activityType = @"follow";
                    NSString *currentUserId = currentUser.userId;
                    NSString *followingUserId = self.user.userId;
                    NSNumber *ts = [NSNumber numberWithDouble:self.intralife.currentTimestamp];
                    NSDictionary *data = @{
                                           @"activityType": activityType,
                                           @"userId": currentUserId, // person which is following somebody
                                           @"followingUserId": followingUserId, // person which is being followed
                                           @"timestamp": ts
                                           };
                    [activityFollowingRef setValue:data];
                }
            }
        }];
    }];
}

- (void)followingWasPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [AppManager sharedAppManager].followingPressed = YES; // hack - fix later if possible
    
    [self.intralife stopFollowingUser:[AppManager sharedAppManager].uid];
}

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // allow to edit just your own profile image
    NSString *currentUserId = [AppManager sharedAppManager].uid;
    if([currentUserId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        [self performSegueWithIdentifier:@"SegueToImages" sender:self];
    }
}

- (IBAction)tableVewPressed:(id)sender
{
    PickViewController *parent = (PickViewController *)self.parentViewController;
    
    parent.containerTableView.hidden = NO;
    parent.containerGridView.hidden = YES;
}

- (IBAction)followersPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // do nothing if you don't have followers
    if([self.followers count] == 0) return;
    
    [self performSegueWithIdentifier:@"SegueToFollowers" sender:self];
}

- (IBAction)followingPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // do nothing if you are not following anybody
    if([self.following count] == 0) return;
    
    [self performSegueWithIdentifier:@"SegueToFollowing" sender:self];
}

- (IBAction)urlPressed:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://www.%@", self.user.website];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToCollectionImage"]) {
        PickGridCell *cell = (PickGridCell *)sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.item];
        PhotoPickerViewController *photoPickerViewController = segue.destinationViewController;
        photoPickerViewController.photoData = photoData;
    }
    else if([segue.identifier isEqualToString:@"SegueToFollowers"]) {
        FollowersViewController *followersViewController = segue.destinationViewController;
        followersViewController.followers = self.followers;
    }
    else if([segue.identifier isEqualToString:@"SegueToFollowing"]) {
        FollowingViewController *followingViewController = segue.destinationViewController;
        followingViewController.following = self.following;
    }
}

@end
