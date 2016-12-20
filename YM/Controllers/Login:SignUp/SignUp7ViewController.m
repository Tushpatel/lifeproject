//
//  SignUp7ViewController.m
//  YM
//
//  Created by user on 24/03/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "SignUp7ViewController.h"
#import "FollowTableCell.h"
#import "Intralife.h"
#import "Reachability.h"
@import PermissionScope;
#import <SDWebImage/UIImageView+WebCache.h>
#import "AppManager.h"

@interface SignUp7ViewController () <FollowTableCellDelegate, UITableViewDataSource, UITableViewDelegate>

- (IBAction)nextPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;

@property(nonatomic, weak) IBOutlet UITableView *followTableView;

@property (nonatomic, strong) Intralife *intralife;
@property (nonatomic, strong) PermissionScope *pScope;

@end

@implementation SignUp7ViewController
{
    NSMutableArray *followProfiles;
    NSMutableArray *followUserIds;
    NSString *passwordPlist;
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Who to Follow";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    followUserIds = [[NSMutableArray alloc] init];
    followProfiles = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    // get from Firebase 20 users with the highest followers count
    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
    FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
    [[peopleRef queryLimitedToFirst:20] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) { // queryLimitedToFirst:100 == 100 most recent
        
        [IntralifeUser loadFromRoot:self.intralife.root
                         withUserId:snapshot.key
                    completionBlock:^(IntralifeUser *user) {
                        
                        NSString *userId = user.userId;
                        NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
                        FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                        [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                            if (error != nil) {
                                NSLog(@"... profile image download error ... %@", error.description);
                            } else {
                                user.profileImageUrl = URL;
                                [followProfiles addObject:user];
                                [self.followTableView reloadData];
                            }
                        }];
                    }];
    }];
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [followProfiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FollowTableCell";
    FollowTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setDelegate:self];
    
    IntralifeUser *matchingUser = [followProfiles objectAtIndex:indexPath.item];
    
    // profile image
    cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
    cell.profileImageView.clipsToBounds = YES;
    [cell.profileImageView sd_setImageWithURL:matchingUser.profileImageUrl
                             placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]];
    
    // username
    cell.profileUserName.text = matchingUser.username;
    
    // name
    cell.profileName.text = matchingUser.name;
    
    // follow/following button
    NSString *userId = matchingUser.userId;
    BOOL following = [followUserIds containsObject:userId];
    UIImage *btnImage;
    if(following) {
        btnImage = [UIImage imageNamed:@"signup-following.png"];
    }
    else {
        btnImage = [UIImage imageNamed:@"signup-follow.png"];
    }
    [cell.followBtn setImage:btnImage forState:UIControlStateNormal];
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85;
}

#pragma mark - <ProfileTableCellDelegate>

- (void)followButtonWasPressed:(FollowTableCell *)cell
{
    NSIndexPath *indexPath = [self.followTableView indexPathForCell:cell];
    IntralifeUser *user = [followProfiles objectAtIndex:indexPath.row];
    NSString *userId = user.userId;
    BOOL following = [followUserIds containsObject:userId];
    if(following) {
        [followUserIds removeObject:userId];
    }
    else {
        [followUserIds addObject:userId];
    }
    
    [self.followTableView reloadData];
}

#pragma mark - IBActions

- (IBAction)nextPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    NSString *email = [self.userData objectForKey:@"email"];
    NSString *password = [self.userData objectForKey:@"password"];
    
    // add followersCount (which is 0 at this moment) to userData
    self.userData[@"followersCount"] = [NSNumber numberWithInteger:0];
    
    // create user in Firebase
    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                                 if(error) {
                                     NSLog(@"%@", error.localizedDescription);
                                 }
                                 else {
                                     [[FIRAuth auth] signInWithEmail:email
                                                            password:password
                                                          completion:^(FIRUser *user, NSError *error) {
                                                              if (error) {
                                                                  NSLog(@"%@", error.localizedDescription);
                                                              }
                                                              else {
                                                                  // save password which will be stored in plist
                                                                  passwordPlist = [self.userData objectForKey:@"password"];
                                                                  
                                                                  // remove password from self.userData - we don't wonna store it
                                                                  [self.userData removeObjectForKey:@"password"];
                                                                  
                                                                  
                                                                  FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
                                                                  FIRDatabaseReference *userRef = [peopleRef child:user.uid];
                                                                  
                                                                  // store profile image in Firebase Storage
                                                                  FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
                                                                  NSString *profileStorageRef = [@"profiles/" stringByAppendingString:userRef.key];
                                                                  FIRStorageReference *profileImagesRef = [storageRef child:profileStorageRef];
                                                                  UIImage *profileImage = [self.userData objectForKey:@"profileImage"];
                                                                  NSData *imageData = UIImagePNGRepresentation(profileImage);
                                                                  FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
                                                                  metadata.contentType = @"image/png";
                                                                  FIRStorageUploadTask *uploadTask = [profileImagesRef putData:imageData metadata:metadata];
                                                                  
                                                                  [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
                                                                      // remove profileImage from self.userData - we can't store UIImage in firebase database
                                                                      // (it will be stored in firebase storage)
                                                                      [self.userData removeObjectForKey:@"profileImage"];
                                                                      
                                                                      //store user data in firebase database
                                                                      [userRef setValue:self.userData];
                                                                  }];
                                                                  
                                                                  // add location permission request
                                                                  self.pScope = [[PermissionScope alloc] init];
                                                                  [self.pScope addPermission:[[LocationWhileInUsePermission alloc]init] message:@"we need to register\r\nwhere you are"];
                                                                  [self.pScope show:^(BOOL completed, NSArray *results) {
                                                                      //go to the next screen
                                                                      [self goToApp];
                                                                      NSLog(@"Changed: %@ - %@", @(completed), results);
                                                                  } cancelled:^(NSArray *x) {
                                                                      //go to the next screen
                                                                      [self goToApp];
                                                                      NSLog(@"cancelled");
                                                                  }];
                                                              }
                                                          }];
                                 }
                             }];
}

//add users to follow (if any) and go to the app
- (void)goToApp
{
    // add users to follow
    NSString *userId;
    for(int i = 0; i < [followUserIds count]; i++) {
        userId = [followUserIds objectAtIndex:i];
        [self.intralife startFollowingUser:userId];
    }
    
    // save login details in plist file for later use
    NSString *email = [self.userData objectForKey:@"email"];
    NSDictionary *loginDetails = @{
                                   @"email" : email,
                                   @"password" : passwordPlist
                                   };
    [[AppManager sharedAppManager] saveLoginDataToPlist:loginDetails];
    
    // go to next screen
    [self performSegueWithIdentifier:@"SegueToApp" sender:self];
}

- (IBAction)signinPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
}

@end




////
////  SignUp7ViewController.m
////  YM
////
////  Created by user on 24/03/2016.
////  Copyright © 2016 Your Mixed. All rights reserved.
////
//
//#import "SignUp7ViewController.h"
//#import "FollowTableCell.h"
//#import "Intralife.h"
//#import "Reachability.h"
//@import PermissionScope;
//#import <SDWebImage/UIImageView+WebCache.h>
//#import "AppManager.h"
//
//@interface SignUp7ViewController () <FollowTableCellDelegate, UITableViewDataSource, UITableViewDelegate>
//
//- (IBAction)nextPressed:(id)sender;
//- (IBAction)signinPressed:(id)sender;
//
//@property(nonatomic, weak) IBOutlet UITableView *followTableView;
//
//@property (nonatomic, strong) Intralife *intralife;
//@property (nonatomic, strong) PermissionScope *pScope;
//
//@end
//
//@implementation SignUp7ViewController
//{
//    NSMutableArray *followProfiles;
//    NSMutableArray *followUserIds;
//    NSString *passwordPlist;
//}
//
//#pragma mark - Internet Connection
//
//- (BOOL)isInternetConnection
//{
//    Reachability *reachability = [Reachability reachabilityForInternetConnection];
//    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
//    
//    if(internetStatus == NotReachable) {
//        UIAlertController *alertController = [UIAlertController
//                                              alertControllerWithTitle:@"Error"
//                                              message:@"Please check your internet connection."
//                                              preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *okAction = [UIAlertAction
//                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
//                                   style:UIAlertActionStyleDefault
//                                   handler:^(UIAlertAction *action)
//                                   {
//                                       
//                                   }];
//        [alertController addAction:okAction];
//        [self presentViewController:alertController animated:YES completion:nil];
//        
//        return NO;
//    }
//    
//    return YES;
//}
//
//#pragma mark - View Lifecycle
//
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    self.intralife = [[Intralife alloc] initIntralife];
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:YES];
//    
//    // set navigation controller title
//    self.navigationItem.title = @"Who to Follow";
//    
//    // add navigation bar left button (back)
//    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
//                                                                style:UIBarButtonItemStylePlain
//                                                               target:self
//                                                               action:@selector(goBack:)];
//    self.navigationItem.leftBarButtonItem = leftBtn;
//    
//    followUserIds = [[NSMutableArray alloc] init];
//    followProfiles = [[NSMutableArray alloc] init];
//}
//
//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:YES];
//    
//    // get from Firebase 20 users with the highest followers count
//    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
//    FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
//    [[peopleRef queryLimitedToFirst:20] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) { // queryLimitedToFirst:100 == 100 most recent
//        
//        [IntralifeUser loadFromRoot:self.intralife.root
//                         withUserId:snapshot.key
//                    completionBlock:^(IntralifeUser *user) {
//                        
//                        NSString *userId = user.userId;
//                        NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
//                        FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
//                        [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
//                            if (error != nil) {
//                                NSLog(@"... profile image download error ... %@", error.description);
//                            }
//                            user.profileImageUrl = URL;
//                            [followProfiles addObject:user];
//                            [self.followTableView reloadData];
//                        }];
//                    }];
//    }];
//}
//
//- (void)goBack:(id)sender
//{
//    [self.navigationController popViewControllerAnimated:YES];
//}
//
//#pragma mark - <UITableViewDataSource>
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [followProfiles count];
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"FollowTableCell";
//    FollowTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    
//    [cell setDelegate:self];
//    
//    IntralifeUser *matchingUser = [followProfiles objectAtIndex:indexPath.item];
//    
//    // profile image
//    cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.size.width / 2;
//    cell.profileImageView.clipsToBounds = YES;
//    [cell.profileImageView sd_setImageWithURL:matchingUser.profileImageUrl
//                             placeholderImage:[UIImage imageNamed:@"profile-profile-small.png"]];
//    
//    // username
//    cell.profileUserName.text = matchingUser.username;
//    
//    // name
//    cell.profileName.text = matchingUser.name;
//    
//    // follow/following button
//    NSString *userId = matchingUser.userId;
//    BOOL isFollowing = [followUserIds containsObject:userId];
//    UIImage *btnImage;
//    if(isFollowing) {
//        btnImage = [UIImage imageNamed:@"signup-following.png"];
//    }
//    else {
//        btnImage = [UIImage imageNamed:@"signup-follow.png"];
//    }
//    [cell.followBtn setImage:btnImage forState:UIControlStateNormal];
//
//    return cell;
//}
//
//#pragma mark - <UITableViewDelegate>
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 85;
//}
//
//#pragma mark - <ProfileTableCellDelegate>
//
//- (void)followButtonWasPressed:(FollowTableCell *)cell
//{
//    NSIndexPath *indexPath = [self.followTableView indexPathForCell:cell];
//    IntralifeUser *user = [followProfiles objectAtIndex:indexPath.row];
//    NSString *userId = user.userId;
//    BOOL following = [followUserIds containsObject:userId];
//    if(following) {
//        [followUserIds removeObject:userId];
//    }
//    else {
//        [followUserIds addObject:userId];
//    }
//    
//    [self.followTableView reloadData];
//}
//
//#pragma mark - IBActions
//
//- (IBAction)nextPressed:(id)sender
//{
//    if(![self isInternetConnection]) return;
//    
//    NSString *email = [self.userData objectForKey:@"email"];
//    NSString *password = [self.userData objectForKey:@"password"];
//    
//    // add followersCount (which is 0 at this moment) to userData
//    self.userData[@"followersCount"] = [NSNumber numberWithInteger:0];
//    
//    // create user in Firebase
//    [[FIRAuth auth] createUserWithEmail:email
//                               password:password
//                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
//        if(error) {
//            NSLog(@"%@", error.localizedDescription);
//        }
//        else {
//            [[FIRAuth auth] signInWithEmail:email
//                                   password:password
//                                 completion:^(FIRUser *user, NSError *error) {
//                          if (error) {
//                              NSLog(@"%@", error.localizedDescription);
//                          }
//                          else {
//                              // save password which will be stored in plist
//                              passwordPlist = [self.userData objectForKey:@"password"];
//                              
//                              // remove password from self.userData - we don't wonna store it
//                              [self.userData removeObjectForKey:@"password"];
//                              
//                              
//                              FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
//                              FIRDatabaseReference *userRef = [peopleRef child:user.uid];
//                              
//                              // store profile image in Firebase Storage
//                              FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
//                              NSString *profileStorageRef = [@"profiles/" stringByAppendingString:userRef.key];
//                              FIRStorageReference *profileImagesRef = [storageRef child:profileStorageRef];
//                              UIImage *profileImage = [self.userData objectForKey:@"profileImage"];
//                              NSData *imageData = UIImagePNGRepresentation(profileImage);
//                              FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
//                              metadata.contentType = @"image/png";
//                             FIRStorageUploadTask *uploadTask = [profileImagesRef putData:imageData metadata:metadata];
//                              
//                              [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
//                                  // remove profileImage from self.userData - we can't store UIImage in firebase database
//                                  // (it will be stored in firebase storage)
//                                  [self.userData removeObjectForKey:@"profileImage"];
//                                  
//                                  //store user data in firebase database
//                                  [userRef setValue:self.userData];
//                              }];
//                              
//                              // add location permission request
//                              self.pScope = [[PermissionScope alloc] init];
//                              [self.pScope addPermission:[[LocationWhileInUsePermission alloc]init] message:@"we need to register\r\nwhere you are"];
//                              [self.pScope show:^(BOOL completed, NSArray *results) {
//                                  //go to the next screen
//                                  [self goToApp];
//                                  NSLog(@"Changed: %@ - %@", @(completed), results);
//                              } cancelled:^(NSArray *x) {
//                                  //go to the next screen
//                                  [self goToApp];
//                                  NSLog(@"cancelled");
//                              }];
//                          }
//                      }];
//        }
//    }];
//}
//
////add users to follow (if any) and go to the app
//- (void)goToApp
//{
//    // add users to follow
//    NSString *userId;
//    for(int i = 0; i < [followUserIds count]; i++) {
//        userId = [followUserIds objectAtIndex:i];
//        [self.intralife startFollowingUser:userId];
//    }
//    
//    // save login details in plist file for later use
//    NSString *email = [self.userData objectForKey:@"email"];
//    NSDictionary *loginDetails = @{
//                                   @"email" : email,
//                                   @"password" : passwordPlist
//                                   };
//    [[AppManager sharedAppManager] saveLoginDataToPlist:loginDetails];
//
//    // go to next screen
//    [self performSegueWithIdentifier:@"SegueToApp" sender:self];
//}
//
//- (IBAction)signinPressed:(id)sender
//{
//    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
//}
//
//@end
