//
//  ActivityFollowingViewController.m
//  YM
//
//  Created by user on 18/01/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "ActivityFollowingViewController.h"
#import "ActivityFollowingLikeTableCell.h"
#import "ActivityFollowingFollowTableCell.h"
#import "Intralife.h"
#import "Reachability.h"
#import "AppManager.h"
#import "PhotoPickerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ActivityFollowingViewController () <IntralifeDelegate, UITableViewDataSource, UITableViewDelegate, ActivityFollowingLikeTableCellDelegate, ActivityFollowingFollowTableCellDelegate>

@property(nonatomic, weak) IBOutlet UITableView *followingTableView;
@property(nonatomic, weak) IBOutlet UILabel *noActivityLabel;

@property (strong, nonatomic) NSMutableSet *users;
@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) NSMutableArray *activities;

@end

@implementation ActivityFollowingViewController
{
    NSInteger chosenCellIndex;
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
    self.activities = [[NSMutableArray alloc] init];
    
    [self.intralife observeActivityFollowing:[FIRAuth auth].currentUser.uid];
    
    self.noActivityLabel.hidden = NO;
}

#pragma mark - <IntralifeDelegate>

- (void)activityFollowingAdded:(NSDictionary *)activityObject
{
    // observe every new user
    IntralifeUser *user = [activityObject valueForKey:@"user"];
    NSString *userId = user.userId;
    if(![self.users containsObject:userId]) {
        [self.users addObject:userId];
        [self.intralife observeUserInfo:userId];
    }
    
    [self.activities addObject:activityObject];
    
    // sort according to timestamp (the same as priority)
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *activitiesSorted = [self.activities sortedArrayUsingDescriptors:@[timestampDescriptor]];
    self.activities = [NSMutableArray arrayWithArray:activitiesSorted];
    
    // activity added - hide "no activity" label
    self.noActivityLabel.hidden = NO;
    
    [self.followingTableView reloadData];
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    NSDictionary *activity;
    IntralifeUser *currentUser;
    for(int i = 0; i < [self.activities count]; i++) {
        activity = [self.activities objectAtIndex:i];
        currentUser = [activity valueForKey:@"user"];
        if([currentUser.userId isEqualToString:user.userId]) {
            [[SDImageCache sharedImageCache] removeImageForKey:[user.profileImageUrl absoluteString] fromDisk:YES];
        }
        
    }
    
    [self.followingTableView reloadData];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if([self.activities count] > 0) {
        self.noActivityLabel.hidden = YES;
    }
    else {
        self.noActivityLabel.hidden = NO;
    }
    
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.activities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *activityData = [self.activities objectAtIndex:indexPath.row];
    NSString *activityType = [activityData valueForKey:@"activityType"];
    
    if([activityType isEqualToString:@"like"]) {
        
        static NSString *profileTableCell = @"ActivityFollowingLikeTableCell";
        ActivityFollowingLikeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:profileTableCell];
        
        [cell setDelegate:self];
        
        IntralifeUser *user = [activityData valueForKey:@"user"];
        
        // profile image
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = YES;
        [cell.profileImageView sd_setImageWithURL:user.profileImageUrl
                                 placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                          options:SDWebImageDelayPlaceholder];

        // username
        NSString *username = user.username;
        cell.usernameLabel.text = username;
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(tapUsername1:)];
        [cell.usernameLabel setUserInteractionEnabled:YES];
        [cell.usernameLabel addGestureRecognizer:gestureRecognizer];
        cell.usernameLabel.tag = indexPath.row;

        // photo
        IntralifePhoto *photo = [activityData valueForKey:@"photo"];
        [cell.photoImageView sd_setImageWithURL:photo.photoImageUrl
                               placeholderImage:[UIImage imageNamed:@"photo-placeholder.png"]];

        
        return cell;
    }
    else if([activityType isEqualToString:@"follow"]) {
        
        static NSString *profileTableCell = @"ActivityFollowingFollowTableCell";
        ActivityFollowingFollowTableCell *cell = [tableView dequeueReusableCellWithIdentifier:profileTableCell];
        
        [cell setDelegate:self];
        
        IntralifeUser *user = [activityData valueForKey:@"user"];
        
        // profile image
        cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
        cell.profileImageView.clipsToBounds = YES;
        [cell.profileImageView sd_setImageWithURL:user.profileImageUrl
                                 placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]
                                          options:SDWebImageDelayPlaceholder];

        
        // user 1
        NSString *username = user.username;
        cell.username1Label.text = username;
        UITapGestureRecognizer *gestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(tapUsername1:)];
        [cell.username1Label setUserInteractionEnabled:YES];
        [cell.username1Label addGestureRecognizer:gestureRecognizer1];
        cell.username1Label.tag = indexPath.row;
        
        // user 2
        IntralifeUser *followingUser = [activityData valueForKey:@"followingUser"];
        NSString *username2 = followingUser.username;
        cell.username2Label.text = username2;
        UITapGestureRecognizer *gestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(tapUsername2:)];
        [cell.username2Label setUserInteractionEnabled:YES];
        [cell.username2Label addGestureRecognizer:gestureRecognizer2];
        cell.username2Label.tag = indexPath.row;
        
        return cell;
    }

    return nil;
}

- (void)tapUsername1:(UIGestureRecognizer*)gestureRecognizer
{
    if(![self isInternetConnection]) return;
    
    UILabel *usernameLabel = (UILabel *)gestureRecognizer.view;
    NSInteger tag = usernameLabel.tag;
    chosenCellIndex = tag;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)tapUsername2:(UIGestureRecognizer*)gestureRecognizer
{
    if(![self isInternetConnection]) return;
    
    UILabel *usernameLabel = (UILabel *)gestureRecognizer.view;
    NSInteger tag = usernameLabel.tag;
    chosenCellIndex = tag;
    [self performSegueWithIdentifier:@"SegueToProfile2" sender:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0;
}

#pragma mark - Cell delegates

- (void)profileButtonOnLikeWasPressed:(ActivityFollowingLikeTableCell *)cell
{
    if(![self isInternetConnection]) return;

    NSIndexPath *indexPath = [self.followingTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)profileButtonOnFollowWasPressed:(ActivityFollowingFollowTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.followingTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)photoButtonWasPressed:(ActivityFollowingLikeTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.followingTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    NSDictionary *activityData = [self.activities objectAtIndex:chosenCellIndex];
    IntralifePhoto *photo  = [activityData valueForKey:@"photo"];
    NSString *photoId = photo.photoId;
    
    // if photo exist - show photo
    FIRDatabaseReference *photoRef = [[self.intralife.root child:@"photos"] child:photoId];
    [photoRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if(snapshot.exists) {
            [self performSegueWithIdentifier:@"SegueToImage" sender:self];
        }
        else {
            NSLog(@"......... photo with photoId %@ is nil (was deleted) .........", photoId);
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"SegueToImage"]) {
        // photo data
        NSDictionary *activityData = [self.activities objectAtIndex:chosenCellIndex];
        IntralifePhoto *photo  = [activityData valueForKey:@"photo"];
        PhotoPickerViewController *photoPickerViewController = segue.destinationViewController;
        photoPickerViewController.photoData = photo;
    }
    else if ([segue.identifier isEqualToString:@"SegueToProfile"]) {
        NSDictionary *activityData = [self.activities objectAtIndex:chosenCellIndex];
        IntralifeUser *user = [activityData valueForKey:@"user"];
        [AppManager sharedAppManager].uid = user.userId;
    }
    else if ([segue.identifier isEqualToString:@"SegueToProfile2"]) {
        NSDictionary *activityData = [self.activities objectAtIndex:chosenCellIndex];
        IntralifeUser *user = [activityData valueForKey:@"followingUser"];
        [AppManager sharedAppManager].uid = user.userId;
    }
}

@end
