//
//  ActivityYouViewController.m
//  YM
//
//  Created by user on 18/01/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "ActivityYouViewController.h"
#import "ActivityYouLikeTableCell.h"
#import "ActivityYouFollowTableCell.h"
#import "Intralife.h"
#import "Reachability.h"
#import "AppManager.h"
#import "PhotoPickerViewController.h"
#import "PhotoPickerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ActivityYouViewController () <IntralifeDelegate, UITableViewDataSource, UITableViewDelegate, ActivityYouLikeTableCellDelegate, ActivityYouFollowTableCellDelegate>

@property(nonatomic, weak) IBOutlet UITableView *youTableView;
@property(nonatomic, weak) IBOutlet UILabel *noActivityLabel;

@property (strong, nonatomic) NSMutableSet *users;
@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) NSMutableArray *activities;

@end

@implementation ActivityYouViewController
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
    
    [self.intralife observeActivityYou:[FIRAuth auth].currentUser.uid];
    
    self.noActivityLabel.hidden = NO;
}

#pragma mark - <IntralifeDelegate>

- (void)activityYouAdded:(NSDictionary *)activityObject
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
    
    [self.youTableView reloadData];
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
    
    [self.youTableView reloadData];
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
        
        static NSString *profileTableCell = @"ActivityYouLikeTableCell";
        ActivityYouLikeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:profileTableCell];
        
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
                                                                                            action:@selector(tapUsername:)];
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
        
        static NSString *profileTableCell = @"ActivityYouFollowTableCell";
        ActivityYouFollowTableCell *cell = [tableView dequeueReusableCellWithIdentifier:profileTableCell];
        
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
                                                                                            action:@selector(tapUsername:)];
        [cell.usernameLabel setUserInteractionEnabled:YES];
        [cell.usernameLabel addGestureRecognizer:gestureRecognizer];
        cell.usernameLabel.tag = indexPath.row;
        
        return cell;
    }

    return nil;
}

- (void)tapUsername:(UIGestureRecognizer*)gestureRecognizer
{
    if(![self isInternetConnection]) return;
    
    UILabel *usernameLabel = (UILabel *)gestureRecognizer.view;
    NSInteger tag = usernameLabel.tag;
    chosenCellIndex = tag;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0;
}

#pragma mark - Cell delegates

- (void)profileButtonOnLikeWasPressed:(ActivityYouLikeTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.youTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)profileButtonOnFollowWasPressed:(ActivityYouFollowTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.youTableView indexPathForCell:cell];
    chosenCellIndex = indexPath.row;
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}

- (void)photoButtonWasPressed:(ActivityYouLikeTableCell *)cell
{
    if(![self isInternetConnection]) return;
    
    NSIndexPath *indexPath = [self.youTableView indexPathForCell:cell];
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
}

@end
