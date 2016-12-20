//
//  IntralifeUser.h
//  YM
//
//  Created by user on 30/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import Firebase;

@protocol IntralifeUserDelegate;

@interface IntralifeUser : NSObject

+ (IntralifeUser *)loadFromRoot:(FIRDatabaseReference *)root
                     withUserId:(NSString *)userId
                completionBlock:(void (^)(IntralifeUser* user))block;
+ (IntralifeUser *)loadFromRoot:(FIRDatabaseReference *)root
                   withUserData:(NSDictionary *)userData
                completionBlock:(void (^)(IntralifeUser* user))block;

- (void)updateFromRoot:(FIRDatabaseReference *)root;
- (void)stopObserving;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSArray *countries;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *bio;
@property (strong, nonatomic) NSString *website;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSURL *profileImageUrl;
//@property (strong, nonatomic) UIImage *profileImage;

@property (weak, nonatomic) id<IntralifeUserDelegate> delegate;

@end

@protocol IntralifeUserDelegate

- (void) userDidUpdate:(IntralifeUser *)user;

@end
