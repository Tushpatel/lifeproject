//
//  MatchingProfilesViewController.m
//  YM
//
//  Created by user on 23/02/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "MatchingProfilesViewController.h"
#import "MatchingProfilesGridCell.h"
#import "PickViewController.h"
#import "Intralife.h"
#import "AppManager.h"
#import "UIImageView+WebCache.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface MatchingProfilesViewController () <IntralifeDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) NSMutableArray *matchingUsers;

@end

@implementation MatchingProfilesViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.intralife = [[Intralife alloc] initIntralife];
    
    self.matchingUsers = [[NSMutableArray alloc] init];
    
    // perform search on countries passed from previous screen
    FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
    [peopleRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [IntralifeUser loadFromRoot:self.intralife.root
                         withUserId:snapshot.key
                    completionBlock:^(IntralifeUser *user) {
                        
                        // countries of cuurent user from firebase
                        NSArray *userCountries = user.countries;
                        
                        // countries passed from previous screen
                        NSArray *requiredCountries = self.selectedCountries;
                        
                        // check if this user satisfies selected countries criteria
                        BOOL isCountriesMatch = [[NSSet setWithArray:requiredCountries] isSubsetOfSet:[NSSet setWithArray:userCountries]];
                        
                        // see if its you
                        NSString *matchUserId = user.userId;
                        NSString *currentUserId = [FIRAuth auth].currentUser.uid;
                        BOOL isCurrentUser = [matchUserId isEqualToString:currentUserId];
                        // selected countries criteria is satisfied (do not add yourself)
                        if(isCountriesMatch && !isCurrentUser) {
                            
                            // retrieve profile image for user from firebase storage
                            FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
                            NSString *profileImagePath = [@"profiles/" stringByAppendingString:matchUserId];
                            FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                            [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                if (error != nil) {
                                    NSLog(@"... error downloading matching user profile image... %@", error.description);
                                }
                                user.profileImageUrl = URL;
                                
                                [self.matchingUsers addObject:user];
                                [self.intralife observeUserInfo:user.userId];
                                [self.collectionView reloadData];
                            }];
                        }
                    }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Search Results";
    
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
}

// stop observing all users when back button is pressed
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // check if the back button was pressed
    if (self.isMovingFromParentViewController) {
        NSLog(@"Back button was pressed.");
        [self.intralife cleanup];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.matchingUsers count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MatchingProfilesGridCell";
    MatchingProfilesGridCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

    // profile image
    IntralifeUser *matchingUser = [self.matchingUsers objectAtIndex:indexPath.item];
    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.width / 2;
    cell.imageView.clipsToBounds = YES;
    if(!matchingUser.profileImageUrl) {
        cell.imageView.image =  [UIImage imageNamed:@"profile-profile-small.png"];
    }
    else {
        [cell.imageView setImageWithURL:matchingUser.profileImageUrl
                       placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                options:SDWebImageDelayPlaceholder
            usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    
    return cell;
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToProfile"]) {
        MatchingProfilesGridCell *cell = (MatchingProfilesGridCell *)sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        NSInteger index = indexPath.item;
        IntralifeUser *user = [self.matchingUsers objectAtIndex:index];
        [AppManager sharedAppManager].uid = user.userId;
    }
}

@end
