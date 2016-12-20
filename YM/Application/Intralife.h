//
//  Intralife.h
//  YM
//
//  Created by user on 10/02/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IntralifeUser.h"
#import "IntralifePhoto.h"

@protocol IntralifeDelegate;

@interface Intralife : NSObject

+ (void) logDiagnostics;

- (id)initIntralife;
//- (void)login;
- (void)observeActivityYou:(NSString *)userId;
- (void)observeActivityFollowing:(NSString *)userId;
- (NSString *)observeUserPhotos;
- (NSString *)observeUserAndFollowingPhotos;
- (NSString *)observePhotosForUserWithId:(NSString *)userId;
- (void)postPhoto:(UIImage *)photo title:(NSString *)title forUser:(NSString *)userId completionBlock:(void (^)(NSError* err))block;
- (void)observeUserInfo:(NSString *)userId;
- (void)observeFollowersForUser:(NSString *)userId;
- (void)observeFolloweesForUser:(NSString *)userId;
- (void)startFollowingUser:(NSString *)userId;
- (void)stopFollowingUser:(NSString *)userId;
- (void)saveUser:(IntralifeUser *)user;
- (void)logout;
- (void)cleanup;
- (double)currentTimestamp;

@property (strong, nonatomic) FIRDatabaseReference *root;
@property (weak, nonatomic) id <IntralifeDelegate> delegate;

@end

@protocol IntralifeDelegate <NSObject>

@optional
- (void)photo:(IntralifePhoto *)photo wasAddedToTimeline:(NSString *)timeline;
- (void)userWasUnfollowed:(NSString *)userId;
- (void)photo:(IntralifePhoto *)photo wasOverflowedFromTimeline:(NSString *)timeline;
- (void)photo:(IntralifePhoto *)photo wasUpdatedInTimeline:(NSString *)timeline;
- (void)photo:(IntralifePhoto *)photo wasRemovedFromTimeline:(NSString *)timeline;
- (void)follower:(IntralifeUser *)follower startedFollowing:(IntralifeUser *)followee;
- (void)follower:(IntralifeUser *)follower stoppedFollowing:(IntralifeUser *)followee;
- (void)userDidUpdate:(IntralifeUser *)user;
- (void)timelineDidLoad:(NSString *)feedId;
- (void)followersDidLoad:(NSString *)userId;
- (void)followeesDidLoad:(NSString *)userId;
- (void)activityYouAdded:(NSDictionary *)dict;
- (void)activityFollowingAdded:(NSDictionary *)dict;

@end







