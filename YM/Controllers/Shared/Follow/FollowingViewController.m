//
//  FollowingViewController.m
//  YM
//
//  Created by user on 23/02/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "FollowingViewController.h"
#import "FollowingGridCell.h"
#import "AppManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface FollowingViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation FollowingViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Following";
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // get images from firebase storage
    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
    
    for(int i = 0; i < [self.following count]; i++) {
        
        IntralifeUser *followerUser = [self.following objectAtIndex:i];
        NSString *followerId = followerUser.userId;
        NSString *profileImagePath = [@"profiles/" stringByAppendingString:followerId];
        FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
        [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
            if (error != nil) {
                NSLog(@"... profile image download error ... %@", error.description);
            }
            followerUser.profileImageUrl = URL;
            [self.collectionView reloadData];
        }];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.following count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FollowingGridCell";
    FollowingGridCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;

    // profile image
    IntralifeUser *followingUser = [self.following objectAtIndex:indexPath.item];
    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.width / 2;
    cell.imageView.clipsToBounds = YES;
    if(!followingUser.profileImageUrl) {
        cell.imageView.image =  [UIImage imageNamed:@"profile-profile-small.png"];
    }
    else {
        [cell.imageView setImageWithURL:followingUser.profileImageUrl
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
        FollowingGridCell *cell = (FollowingGridCell *)sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        NSInteger index = indexPath.item;
        IntralifeUser *user = [self.following objectAtIndex:index];
        [AppManager sharedAppManager].uid = user.userId;
    }
}

@end
