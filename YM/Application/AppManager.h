//
//  AppManager.h
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntralifeUser.h"

// used to determine which segue should be used when leaving Fusuma view controller
typedef enum {
    kSecondViewController = 1,
    kProfileViewController = 2,
    kPPViewController = 3
} kFusumaScreen;

@interface AppManager : NSObject

@property(nonatomic, strong) NSString *uid; //used to pass uid of the user whose profile we are looking at
@property(nonatomic, assign) NSInteger fusumaScreen;
@property(nonatomic, strong) IntralifeUser *loggedInUser; // currently logged in user. Used in CommentsViewController
@property(nonatomic, assign) BOOL followingPressed; // needed for hack - fix later if possible

+ (AppManager *)sharedAppManager;

- (void)saveLoginDataToPlist:(NSDictionary *)loginDetails;
- (NSDictionary *)getLoginPlistData;

@end
