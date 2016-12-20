//
//  Intralife.m
//  YM
//
//  Created by user on 10/02/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "Intralife.h"
@import Firebase;
#import "intralifePhoto.h"
#import "AppManager.h"
#import "UIImage+Load.h"

typedef void (^ffbt_void_nserror)(NSError *err);
typedef void (^ffbt_void_nserror_dict)(NSError *err, NSDictionary *dict);

@interface FeedHandlers : NSObject

@property (nonatomic) FIRDatabaseHandle childAddedHandle;
@property (nonatomic) FIRDatabaseHandle childRemovedHandle;
@property (strong, nonatomic) IntralifeUser *user;
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation FeedHandlers

@end

@interface Intralife () <IntralifeUserDelegate>

@property (strong, nonatomic) NSMutableDictionary *feeds;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *photos;
@property (nonatomic) long serverTimeOffset;
@property (nonatomic) FIRDatabaseHandle timeOffsetHandle;
@property (strong, nonatomic) FIRDatabaseReference *userRef;

@end

@implementation Intralife

+ (void)logDiagnostics
{
    // Quick dump of some relevant info about the app
//    NSLog(@"Running w/ Firebase %@", [Firebase sdkVersion]); //rb upgrade
    NSLog(@"bundle id: %@", [NSBundle mainBundle].bundleIdentifier);
}


- (id)initIntralife
{
    self = [super init];
    if (self) {
        self.root = [[FIRDatabase database] reference];
        __weak Intralife *weakSelf = self;
        // Get an idea of what the actual time is from the Firebase servers
        self.timeOffsetHandle = [[self.root child:@".info/serverTimeOffset"] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            
            weakSelf.serverTimeOffset = [(NSNumber *)snapshot.value longValue];
            
        }];
        self.serverTimeOffset = 0;
        
        self.feeds = [[NSMutableDictionary alloc] init];
        self.users = [[NSMutableArray alloc] init];
        self.photos = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    // Stop watching the time offset so we don't leak memory
    [[self.root child:@".info/serverTimeOffset"] removeObserverWithHandle:_timeOffsetHandle];
}

- (void)cleanup
{
    // Clean up all of our listeners so we don't leak memory
    for (NSString *url in self.feeds) {
        FeedHandlers *handle = [self.feeds objectForKey:url];
        [self stopObservingFeed:handle];
    }
    [self.feeds removeAllObjects];
//    [self stopObservingLoginStatus];
//    [self cleanupUsers];
    [self cleanupPhotos];
}

- (void)stopObservingFeed:(FeedHandlers *)handle
{
    // We track two separate events, and possibly a user as well. Remove all the listeners
    [handle.ref removeObserverWithHandle:handle.childAddedHandle];
    [handle.ref removeObserverWithHandle:handle.childRemovedHandle];
    if(handle.user) {
        [handle.user stopObserving];
    }
}

- (void)cleanupPhotos
{
    // Remove listeners for all of the photos we're watching
    for (IntralifePhoto *photo in self.photos) {
        [photo stopObserving];
    }
    [self.photos removeAllObjects];
}

- (void)logout
{
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    
    // reset email and password to empty string
    // (cannot just delete plist file because it's cached)
    NSDictionary *loginDetails = @{
                                   @"email" : @"",
                                   @"password" : @""
                                   };
    [[AppManager sharedAppManager] saveLoginDataToPlist:loginDetails];
    
    // FIXME: right now observers from tabs are not released
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // check observers in other view controllers. Make sure that no dangling Firebase observers left
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if (!error) {
        // cleanup
        [self cleanup];
    }
}

//
// ACTIVITY FEED
//
- (void)observeActivityYou:(NSString *)activityUserId
{
    FIRDatabaseReference *ref = [[[self.root child:@"activity"] child:activityUserId] child:@"you"];
    FIRDatabaseQuery *query = [[ref queryOrderedByPriority] queryLimitedToFirst:50];
    
    NSString *feedId = ref.description;
    FeedHandlers *handles = [[FeedHandlers alloc] init];
    handles.ref = ref;
    
    __weak Intralife *weakSelf = self;
    handles.childAddedHandle = [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        if(weakSelf) {
            id rawVal = snapshot.value;
            NSDictionary *val = rawVal;
            NSNumber *timestamp = [val objectForKey:@"timestamp"];
            NSString *activityType = [val valueForKey:@"activityType"];
            
            FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
            if([activityType isEqualToString:@"follow"]) {
                NSString *userId = [val valueForKey:@"userId"];
                IntralifeUser* user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:userId completionBlock:^(IntralifeUser *user) {
                    
                    // retrieve profile image for user from firebase storage
                    NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
                    FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                    [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                        if (error != nil) {
                            NSLog(@"... error downloading profile image... %@", error.description);
                        }
                        user.profileImageUrl = URL;
                        
                        NSDictionary *activityObject = @{
                                                         @"activityType" : @"follow",
                                                         @"user"         : user,
                                                         @"timestamp"    : timestamp
                                                         };
                        [weakSelf.delegate activityYouAdded:activityObject];
                    }];
                }];
                [weakSelf.users addObject:user];
            }
            else if([activityType isEqualToString:@"like"]) {
                NSString *userId = [val valueForKey:@"userId"];
                IntralifeUser* user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:userId completionBlock:^(IntralifeUser *user) {
                    NSString *photoId = [val valueForKey:@"photoId"];
                    __block BOOL loaded = NO;
                    IntralifePhoto *outerPhoto = [IntralifePhoto loadFromRoot:self.root withPhotoId:photoId block:^(IntralifePhoto *photo) { // if nil is returned, photo is deleted
                        if (loaded && photo) { /////////// photo in question was updated ///////////
                            
                        }
                        else if (!loaded && photo) { /////////// photo in question was added ///////////
                            // retrieve photo from firebase storage
                            NSString *photoId = photo.photoId;
                            NSString *photoPath = [@"photos/" stringByAppendingString:photoId];
                            FIRStorageReference *storagePhotoRef = [storageRef child:photoPath];
                            [storagePhotoRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                if (error != nil) {
                                    NSLog(@"... error downloading photo ... %@", error.description);
                                }
                                else {
                                    photo.photoImageUrl = URL;
                                    
                                    // retrieve profile image for photo from firebase storage
                                    NSString *photoAuthorId = photo.authorId;
                                    NSString *photoProfilePath = [@"profiles/" stringByAppendingString:photoAuthorId];
                                    FIRStorageReference *storagePhotoProfileRef = [storageRef child:photoProfilePath];
                                    [storagePhotoProfileRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                        if (error != nil) {
                                            NSLog(@"... error downloading photo ... %@", error.description);
                                        }
                                        else {
                                            photo.profileImageUrl = URL;
                                            
                                            // retrieve profile image for user from firebase storage
                                            NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
                                            FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                                            [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                                if (error != nil) {
                                                    NSLog(@"... error downloading profile image... %@", error.description);
                                                }
                                                user.profileImageUrl = URL;
                                                
                                                NSDictionary *activityObject = @{
                                                                                 @"activityType" : @"like",
                                                                                 @"user"         : user,
                                                                                 @"photo"        : photo,
                                                                                 @"timestamp"    : timestamp
                                                                                 };
                                                [weakSelf.delegate activityYouAdded:activityObject];
                                                loaded = YES;
                                            }];
                                        }
                                    }];
                                }
                            }];
                        }
                        else if (loaded) { /////////// photo in question was deleted ///////////
                            NSLog(@"photo with photoId %@ is nil (was deleted)", photoId);
                            [snapshot.ref removeValue];
                        }
                        else { /////////// photo in question doesn't exist ///////////
                            
                        }
                    }];
                    [weakSelf.photos addObject:outerPhoto];
                }];
                [weakSelf.users addObject:user];
            }
        }
    }];
    
    [self.feeds setObject:handles forKey:feedId];
}

- (void)observeActivityFollowing:(NSString *)activityUserId
{
    FIRDatabaseReference *ref = [[[self.root child:@"activity"] child:activityUserId] child:@"following"];
    FIRDatabaseQuery *query = [[ref queryOrderedByPriority] queryLimitedToFirst:50];
    
    NSString *feedId = ref.description;
    FeedHandlers *handles = [[FeedHandlers alloc] init];
    handles.ref = ref;
    
    __weak Intralife *weakSelf = self;
    handles.childAddedHandle = [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        if(weakSelf) {
            id rawVal = snapshot.value;
            NSDictionary *val = rawVal;
            NSNumber *timestamp = [val objectForKey:@"timestamp"];
            NSString *activityType = [val valueForKey:@"activityType"];
            
            FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
            if([activityType isEqualToString:@"follow"]) {
                NSString *userId = [val valueForKey:@"userId"];
                NSString *followingUserId = [val valueForKey:@"followingUserId"];
                IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:userId completionBlock:^(IntralifeUser *user) {
                    
                    // retrieve profile image for user from firebase storage
                    NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
                    FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                    [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                        if (error != nil) {
                            NSLog(@"... error downloading current user profile image... %@", error.description);
                        }
                        user.profileImageUrl = URL;
                        
                        IntralifeUser *followingUser = [IntralifeUser loadFromRoot:weakSelf.root withUserId:followingUserId completionBlock:^(IntralifeUser *followingUser) {
                            
                            NSDictionary *activityObject = @{
                                                             @"activityType"  : @"follow",
                                                             @"user"          : user,
                                                             @"followingUser" : followingUser,
                                                             @"timestamp"     : timestamp
                                                             };
                            [weakSelf.delegate activityFollowingAdded:activityObject];
                        }];
                        [weakSelf.users addObject:followingUser];
                    }];
                }];
                [weakSelf.users addObject:user];
            }
            else if([activityType isEqualToString:@"like"]) {
                NSString *userId = [val valueForKey:@"userId"];
                IntralifeUser* user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:userId completionBlock:^(IntralifeUser *user) {
                    NSString *photoId = [val valueForKey:@"photoId"];
                    __block BOOL loaded = NO;
                    IntralifePhoto *outerPhoto = [IntralifePhoto loadFromRoot:self.root withPhotoId:photoId block:^(IntralifePhoto *photo) { // if nil is returned, photo is deleted
                        if (loaded && photo) { /////////// photo in question was updated ///////////
                            
                        }
                        else if (!loaded && photo) { /////////// photo in question was added ///////////
                            // retrieve photo from firebase storage
                            NSString *photoId = photo.photoId;
                            NSString *photoPath = [@"photos/" stringByAppendingString:photoId];
                            FIRStorageReference *storagePhotoRef = [storageRef child:photoPath];
                            [storagePhotoRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                if (error != nil) {
                                    NSLog(@"... error downloading photo ... %@", error.description);
                                }
                                else {
                                    photo.photoImageUrl = URL;
                                    
                                    // retrieve profile image for photo from firebase storage
                                    NSString *photoAuthorId = photo.authorId;
                                    NSString *photoProfilePath = [@"profiles/" stringByAppendingString:photoAuthorId];
                                    FIRStorageReference *storagePhotoProfileRef = [storageRef child:photoProfilePath];
                                    [storagePhotoProfileRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                        if (error != nil) {
                                            NSLog(@"... error downloading photo ... %@", error.description);
                                        }
                                        else {
                                            photo.profileImageUrl = URL;
                                            
                                            // retrieve profile image for user from firebase storage
                                            NSString *profileImagePath = [@"profiles/" stringByAppendingString:userId];
                                            FIRStorageReference *storageProfileImageRef = [storageRef child:profileImagePath];
                                            [storageProfileImageRef downloadURLWithCompletion:^(NSURL *URL, NSError *error) {
                                                if (error != nil) {
                                                    NSLog(@"... error downloading profile image... %@", error.description);
                                                }
                                                user.profileImageUrl = URL;
                                                
                                                NSDictionary *activityObject = @{
                                                                                 @"activityType" : @"like",
                                                                                 @"user"         : user,
                                                                                 @"photo"        : photo,
                                                                                 @"timestamp"    : timestamp
                                                                                 };
                                                [weakSelf.delegate activityFollowingAdded:activityObject];
                                                loaded = YES;
                                            }];
                                        }
                                    }];
                                }
                            }];
                        }
                        else if (loaded) { /////////// photo in question was deleted ///////////
                            NSLog(@"photo with photoId %@ is nil (was deleted)", photoId);
                            [snapshot.ref removeValue];
                        }
                        else { /////////// photo in question doesn't exist ///////////
                            
                        }
                    }];
                    [weakSelf.photos addObject:outerPhoto];
                }];
                [weakSelf.users addObject:user];
            }
        }
    }];
    
    [self.feeds setObject:handles forKey:feedId];
}

// This method sets up observers followees being added and removed. Each followee that is added is observed individually
- (void)observeFolloweesForUser:(NSString *)userId
{
    __weak Intralife *weakSelf = self;
    
    [IntralifeUser loadFromRoot:self.root withUserId:userId completionBlock:^(IntralifeUser *followingUser) {
        FIRDatabaseReference *ref = [[[self.root child:@"users"] child:userId] child:@"following"];
        
        NSString *feedId = ref.description;
        FeedHandlers *handles = [[FeedHandlers alloc] init];
        handles.user = followingUser;
        handles.ref = ref;
        
        handles.childAddedHandle = [ref observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
            if (weakSelf) {
                NSString *followerId = snapshot.key;
                IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:followerId completionBlock:^(IntralifeUser *user) {
                    [weakSelf.delegate follower:followingUser startedFollowing:user];
                }];
                [weakSelf.users addObject:user];
            }
        }];
        
        handles.childRemovedHandle = [ref observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
            if (weakSelf) {
                NSString *followerId = snapshot.key;
                IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:followerId completionBlock:^(IntralifeUser *user) {
                    [weakSelf.delegate follower:followingUser stoppedFollowing:user];
                }];
                [weakSelf.users addObject:user];
            }
        }];
        
        [ref observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            [weakSelf.delegate followeesDidLoad:userId];
        }];
        
        [self.feeds setObject:handles forKey:feedId];
    }];
}

// This method sets up observers followers being added and removed. Each follower that is added is observed individually
- (void)observeFollowersForUser:(NSString *)userId
{
    __weak Intralife *weakSelf = self;
    [IntralifeUser loadFromRoot:self.root withUserId:userId completionBlock:^(IntralifeUser *followedUser) {
        FIRDatabaseReference *ref = [[[self.root child:@"users"] child:userId] child:@"followers"];
        
        NSString *feedId = ref.description;
        FeedHandlers *handles = [[FeedHandlers alloc] init];
        handles.user = followedUser;
        handles.ref = ref;
        
        handles.childAddedHandle = [ref observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
            if (weakSelf) {
                NSString *followerId = snapshot.key;
                IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:followerId completionBlock:^(IntralifeUser *user) {
                    [weakSelf.delegate follower:user startedFollowing:followedUser];
                }];
                [weakSelf.users addObject:user];
            }
        }];
        
        handles.childRemovedHandle = [ref observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
            if (weakSelf) {
                NSString *followerId = snapshot.key;
                IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:followerId completionBlock:^(IntralifeUser *user) {
                    [weakSelf.delegate follower:user stoppedFollowing:followedUser];
                }];
                [weakSelf.users addObject:user];
            }
        }];
        
        [ref observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            [weakSelf.delegate followersDidLoad:userId];
        }];
        
        [self.feeds setObject:handles forKey:feedId];
    }];
}

- (NSString *)observeFeed:(FIRDatabaseReference *)ref withCount:(NSUInteger)count
{
    FIRDatabaseQuery *query = [[ref queryOrderedByPriority] queryLimitedToFirst:count];

    NSString *feedId = ref.description;
    __weak Intralife *weakSelf = self;
    FIRDatabaseHandle childAddedHandle = [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        if(weakSelf) {
            NSString* photoId = snapshot.key;
            __block BOOL loaded = NO;
            __block IntralifePhoto *outerPhoto = [IntralifePhoto loadFromRoot:self.root withPhotoId:photoId block:^(IntralifePhoto *photo) {
                if (loaded && photo) {
                    [weakSelf.delegate photo:photo wasUpdatedInTimeline:feedId];
                }
                else if (!loaded && photo) {
                    loaded = YES;
                    [weakSelf.delegate photo:photo wasAddedToTimeline:feedId];
                }
                else if (loaded) {
                    // The photo in question was deleted.
                    [weakSelf.delegate photo:outerPhoto wasRemovedFromTimeline:feedId];
                }
                else {
                    // The photo in question doesn't exist
                    // We can leave it alone, and leave loaded == NO, if it ever starts existing, we'll handle it
                }
                
            }];
            [weakSelf.photos addObject:outerPhoto];
        }
    }];
    
    // remove photo of user x if user x was unfollowed
    FIRDatabaseHandle childRemovedHandle = [query observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        if (weakSelf) {
            NSString* photoId = snapshot.key;
            __block IntralifePhoto *outerPhoto = [IntralifePhoto loadFromRoot:self.root withPhotoId:photoId block:^(IntralifePhoto *photo) {
                // remove photos in FirstViewController
                [weakSelf.delegate userWasUnfollowed:outerPhoto.authorId];
                [AppManager sharedAppManager].followingPressed = NO; // hack - fix later if possible
            }];
            [weakSelf.photos addObject:outerPhoto];
        }
    }];
    
    
//    // remove photo of user x if user x was unfollowed
//    FirebaseHandle childRemovedHandle;
//    if ([AppManager sharedAppManager].followingPressed) { // hack - fix later if possible
//        childRemovedHandle = [query observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
//            if (weakSelf) {
//                NSString* photoId = snapshot.key;
//                __block IntralifePhoto *outerPhoto = [IntralifePhoto loadFromRoot:self.root withPhotoId:photoId block:^(IntralifePhoto *photo) {
//                    // remove photos in FirstViewController
//                    [weakSelf.delegate userWasUnfollowed:outerPhoto.authorId];
//                    [AppManager sharedAppManager].followingPressed = NO; // hack - fix later if possible
//                }];
//            }
//        }];
//    }

    // since value events fire after child events, this observer lets us know when we've gotten a good initial snapshot of the data
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [weakSelf.delegate timelineDidLoad:feedId];
    }];

    FeedHandlers *handlers = [[FeedHandlers alloc] init];
    handlers.ref = ref;
    handlers.childAddedHandle = childAddedHandle;
    handlers.childRemovedHandle = childRemovedHandle;
    [self.feeds setObject:handlers forKey:feedId];
    
    return feedId;
}

- (NSString *)observeUserPhotos
{
    FIRDatabaseReference *ref = [[[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userPhotos"];
    
    return [self observeFeed:ref withCount:50];
}

- (NSString *)observeUserAndFollowingPhotos
{
    FIRDatabaseReference *ref = [[[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userAndFollowingPhotos"];
    
    return [self observeFeed:ref withCount:50];
}

- (NSString *)observePhotosForUserWithId:(NSString *)userId
{
    FIRDatabaseReference *ref = [[[self.root child:@"users"] child:userId] child:@"userPhotos"];
    
    return [self observeFeed:ref withCount:50];
}

- (double)currentTimestamp
{
    // incorporate the timestamp from Firebase to get a good estimate of the time
    return ([[NSDate date] timeIntervalSince1970] * 1000.0) + self.serverTimeOffset;
}

- (void)postPhoto:(UIImage *)photo title:(NSString *)title forUser:(NSString *)userId completionBlock:(ffbt_void_nserror)block
{
    [IntralifeUser loadFromRoot:self.root withUserId:userId completionBlock:^(IntralifeUser *user) {
        NSString *authorId = [FIRAuth auth].currentUser.uid;
        NSString *username = user.username;
        NSNumber* ts = [NSNumber numberWithDouble:[self currentTimestamp]];
        NSString *report = @"0";
        NSDictionary *photoData = @{
                                    @"authorId": authorId,
                                    @"authorUsername": username, // user name
                                    @"title": title,
                                    @"timestamp": ts,
                                    @"report": report
                                    };
        FIRDatabaseReference *photosRef = [self.root child: @"photos"];
        FIRDatabaseReference *photoRef = [photosRef childByAutoId];

        // store photo in Firebase Storage
        FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
        NSString *photoStorageRef = [@"photos/" stringByAppendingString:photoRef.key];
        FIRStorageReference *photoImageRef = [storageRef child:photoStorageRef];
        NSData *imageData = UIImagePNGRepresentation(photo);
        FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
        metadata.contentType = @"image/png";
        FIRStorageUploadTask *uploadTask = [photoImageRef putData:imageData metadata:metadata];
        
        // upload completed successfully
        [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {

            ffbt_void_nserror userBlock = [block copy];
            __weak Intralife* weakSelf = self;
            __block  NSString *photoRefStr = photoRef.key;
            [photoRef setValue:photoData withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                if (error) {
                    userBlock(error);
                } else if (weakSelf) {
                    ///// add photo "userPhotos" /////
                    FIRDatabaseReference *usersRef = [self.root child:@"users"];
                    NSString *currentUID = [FIRAuth auth].currentUser.uid;
                    FIRDatabaseReference *userRef = [usersRef child:currentUID];
                    FIRDatabaseReference *userPhotosRef = [userRef child:@"userPhotos"];
                    NSDictionary *postedPhoto = @{photoRefStr:[FIRAuth auth].currentUser.uid};
                    [userPhotosRef updateChildValues:postedPhoto];
                    
                    // set priority for this photo
                    double priorityDouble = 0 - [self currentTimestamp];
                    NSNumber *priorityNumber = [NSNumber numberWithDouble:priorityDouble];
                    FIRDatabaseReference *userPhotosRefPriority = [userPhotosRef child:photoRefStr];
                    [userPhotosRefPriority setPriority:priorityNumber];
                    
                    
                    ///// add photo to "userAndFollowingPhotos" /////
                    FIRDatabaseReference *userAndFollowingPhotosRef = [userRef child:@"userAndFollowingPhotos"];
                    [userAndFollowingPhotosRef updateChildValues:postedPhoto];
                    
                    // set priority for this photo
                    FIRDatabaseReference *userAndFollowingPhotosRefPriority = [userAndFollowingPhotosRef child:photoRefStr];
                    [userAndFollowingPhotosRefPriority setPriority:priorityNumber];
                    
                    
                    ///// fanout to followers /////
                    [[userRef child:@"followers"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
                        for (FIRDataSnapshot *childSnap in snapshot.children) {
                            NSString *followerId = childSnap.key;
                            [[[[[weakSelf.root child:@"users"] child:followerId] child:@"userAndFollowingPhotos"] child:photoRefStr] setValue:[FIRAuth auth].currentUser.uid];
                            
                            // set priority for this photo
                            [[[[[weakSelf.root child:@"users"] child:followerId] child:@"userAndFollowingPhotos"] child:photoRefStr] setPriority:priorityNumber];
                        }
                    }];
                    
                    userBlock(nil);
                }
            }];
        }];
    }];
}

- (void)observeUserInfo:(NSString *)userId
{
    // Observe the profile data of a single user
    __weak Intralife *weakSelf = self;
    IntralifeUser *user = [IntralifeUser loadFromRoot:weakSelf.root withUserId:userId completionBlock:^(IntralifeUser *user) {
        [weakSelf.delegate userDidUpdate:user];
    }];
    [self.users addObject:user];
    
    user.delegate = self;
}

- (void)startFollowingUser:(NSString *)userId
{
    // Performs the necessary operations to follow a user:
    // 1. Set the followee into the followers list of following
    // 2. Set the follower into the followee's list of followers
    // 3. Copy in some recent photos to fill up the follower's feed
    FIRDatabaseReference *userRef = [[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid];
    
    FIRDatabaseReference *followingRef = [[userRef child:@"following"] child:userId];
    [followingRef setValue:@YES withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        FIRDatabaseReference *followerRef = [[self.root child:@"users"] child:userId];
        
        [[[followerRef child:@"followers"] child:[FIRAuth auth].currentUser.uid] setValue:@YES];
        
        // copy some photos into userAndFollowingPhotos
        FIRDatabaseReference *userAndFollowingPhotosRef = [userRef child:@"userAndFollowingPhotos"];
        [[[followerRef child:@"userPhotos"] queryLimitedToFirst:1] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            
            for(FIRDataSnapshot *childSnap in snapshot.children) {
                [[userAndFollowingPhotosRef child:childSnap.key] setValue:userId];
            }
        }];
    }];
}

- (void)stopFollowingUser:(NSString *)userId
{
    FIRDatabaseReference *userRef = [[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid];
    
    // remove the followee from the follower's list of following
    FIRDatabaseReference *followingRef = [[userRef child:@"following"] child:userId];
    [followingRef removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        // remove the follower from the followee's list of followers
        FIRDatabaseReference *followerRef = [[self.root child:@"users"] child:userId];
        [[[followerRef child:@"followers"] child:[FIRAuth auth].currentUser.uid] removeValue];

        // remove photo from userAndFollowingPhotos
        FIRDatabaseReference *photosRef = [[[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userAndFollowingPhotos"];
        [photosRef  observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            for (FIRDataSnapshot *childSnap in snapshot.children) {
                NSString *photoId = childSnap.key;
                NSString *photoUserId = childSnap.value;
                if([photoUserId isEqualToString:userId]) {
                    FIRDatabaseReference *userAndFollowingPhotosRef = [[[self.root child:@"users"] child:[FIRAuth auth].currentUser.uid] child:@"userAndFollowingPhotos"];
                    [[userAndFollowingPhotosRef child:photoId] removeValue];
                }
            }
        }];
    }];
}

//TODO: currently not being used
- (void)saveUser:(IntralifeUser *)user
{
    // Pass through to the user object to update itself
    [user updateFromRoot:self.root];
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    // Pass through to our delegate that a user was updated
    [self.delegate userDidUpdate:user];
}

@end
