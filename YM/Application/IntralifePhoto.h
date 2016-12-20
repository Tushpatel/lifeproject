//
//  IntralifePhoto.h
//  YM
//
//  Created by user on 30/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Firebase;
#import <UIKit/UIKit.h>

@interface IntralifePhoto : NSObject

+ (IntralifePhoto *)loadFromRoot:(FIRDatabaseReference *)root
                     withPhotoId:(NSString *)photoId
                           block:(void (^)(IntralifePhoto *photo))block;

- (void) stopObserving;

@property (strong, nonatomic) NSString *photoId;
@property (strong, nonatomic) NSString *authorId;
@property (strong, nonatomic) NSString *authorUsername;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *report; // codes for reporting photo
@property (nonatomic)         double timestamp;
@property (strong, nonatomic) NSDictionary *comments;
@property (strong, nonatomic) NSDictionary *likes;
@property (strong, nonatomic) NSURL *photoImageUrl;
@property (strong, nonatomic) NSURL *profileImageUrl;
//@property (strong, nonatomic) UIImage *photoImage;
//@property (strong, nonatomic) UIImage *profileImage;

@end
