//
//  FirstTabViewController.h
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FIRDatabaseReference;

@interface FirstTabViewController : UIViewController

@property (strong, nonatomic) FIRDatabaseReference *firebaseRef;

@end
