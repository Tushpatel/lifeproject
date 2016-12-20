//
//  GridLayoutViewController.m
//  YM
//
//  Created by user on 16/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "GridLayoutViewController.h"
#import "FifthTabViewController.h"
#import "AppManager.h"
#import "FTVCgridCell.h"
#import "FTVCgridHeader.h"
#import "PhotoPickerViewController.h"
#import "Intralife.h"
#import "UIImage+Bordered.h"
#import "FollowersViewController.h"
#import "FollowingViewController.h"
#import "Reachability.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Load.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface GridLayoutViewController () <IntralifeDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

- (IBAction)profilePressed:(id)sender;
- (IBAction)tableVewPressed:(id)sender;
- (IBAction)editProfilePressed:(id)sender;
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

@implementation GridLayoutViewController

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
    
    [self.intralife observeUserInfo:[FIRAuth auth].currentUser.uid];
    [self.intralife observeUserPhotos];
    [self.intralife observeFolloweesForUser:[FIRAuth auth].currentUser.uid];
    [self.intralife observeFollowersForUser:[FIRAuth auth].currentUser.uid];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [self.collectionView reloadData];
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
    self.user = user;
    
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
        //self.user = user;
        
        [self.collectionView reloadData];
        
        // let set current logged in user (it's the first screen current logged in user sees)
        [AppManager sharedAppManager].loggedInUser = self.user;
    }];
}

- (void)follower:(IntralifeUser *)follower startedFollowing:(IntralifeUser *)followee
{
    // is somebody started following you - increase number of followers
    if ([followee.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        [self.followers addObject:follower];
        [self.collectionView reloadData];
    }
    
    // if you started following somebody (could be from other device) - increase number of following
    if ([follower.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        [self.following addObject:followee];
        [self.collectionView reloadData];
    }
}

- (void) follower:(IntralifeUser *)follower stoppedFollowing:(IntralifeUser *)followee
{
    if ([followee.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        [self.followers removeObject:follower];
        [self.collectionView reloadData];
    }
    
    if ([follower.userId isEqualToString:[FIRAuth auth].currentUser.uid]) {
        [self.following removeObject:followee];
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
    static NSString *CellIdentifier = @"FTVCgridCell";
    FTVCgridCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
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
    FTVCgridHeader *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                              withReuseIdentifier:CellIdentifier
                                                                     forIndexPath:indexPath];

    
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

#pragma mark - IBActions

- (IBAction)profilePressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToImages" sender:self];
}

- (IBAction)tableVewPressed:(id)sender
{
    FifthTabViewController *parent = (FifthTabViewController *)self.parentViewController;
    
    parent.containerTableView.hidden = NO;
    parent.containerGridView.hidden = YES;
}

- (IBAction)editProfilePressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    [self performSegueWithIdentifier:@"SegueToEditProfile" sender:self];
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
        FTVCgridCell *cell = (FTVCgridCell *)sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        IntralifePhoto *photoData = [self.photos objectAtIndex:indexPath.item];
        PhotoPickerViewController *photoPickerViewController = segue.destinationViewController;
        photoPickerViewController.photoData = photoData;
    }
    else if([segue.identifier isEqualToString:@"SegueToImages"]) {
        [AppManager sharedAppManager].uid = [FIRAuth auth].currentUser.uid;
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
