//
//  PPFinalViewController.m
//  YM
//
//  Created by user on 30/03/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "PPFinalViewController.h"
#import "FifthTabViewController.h"
#import "Intralife.h"
#import "Intralife.h"
#import "AppManager.h"
#import "GridLayoutViewController.h"

@interface PPFinalViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *finalImageView;

@property (strong, nonatomic) Intralife *intralife;

@end

@implementation PPFinalViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.intralife = [[Intralife alloc] initIntralife];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden = NO;
    
    // set navigation controller title
    self.navigationItem.title = @"Preview";
    
    //add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    //add navigation bar right button
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *nextBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(nextTapped:)];
    self.navigationItem.rightBarButtonItem = nextBtn;

    // create round image
    self.finalImageView.layer.cornerRadius = self.finalImageView.frame.size.width / 2;
    self.finalImageView.layer.borderWidth = 3.0f;
    self.finalImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.finalImageView.clipsToBounds = YES;
    [self.finalImageView setImage:self.finalImage];
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextTapped:(id)sender
{
    // pop back to photos
    NSArray *navigationControllers = self.navigationController.viewControllers;
    NSInteger previous = navigationControllers.count - 3;
    
    self.finalImageView.layer.cornerRadius = self.finalImageView.frame.size.width / 2;
    self.finalImageView.layer.borderWidth = 3.0f;
    self.finalImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.finalImageView.clipsToBounds = YES;
    [self.finalImageView setImage:self.finalImage];
    
    // compress image before uploading it to Firebase
    self.finalImage = [self compressImage:self.finalImage];
    
    FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
    FIRDatabaseReference *userRef = [peopleRef child:[AppManager sharedAppManager].uid];
    
    // store profile image in Firebase Storage
    FIRStorageReference *storageRef = [[FIRStorage storage] referenceForURL:@"gs://intra-life.appspot.com"];
    NSString *profileStorageRef = [@"profiles/" stringByAppendingString:userRef.key];
    FIRStorageReference *profileImagesRef = [storageRef child:profileStorageRef];
    UIImage *profileImage = self.finalImage;
    NSData *imageData = UIImagePNGRepresentation(profileImage);
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/png";
    FIRStorageUploadTask *uploadTask = [profileImagesRef putData:imageData metadata:metadata];
    
    [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
        // change timestamp in people/uid to indicate that user profile was updated
        FIRDatabaseReference *profileImageRef = [[self.intralife.root child:@"people"] child:[AppManager sharedAppManager].uid];
        NSNumber *ts = [NSNumber numberWithDouble:self.intralife.currentTimestamp];
        NSDictionary *newProfileImage = @{@"imageTimestamp":ts};
        [profileImageRef updateChildValues:newProfileImage withCompletionBlock:^(NSError *error, FIRDatabaseReference *profileImageRef) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            } else {
                NSLog(@"profile image changed for user %@", [AppManager sharedAppManager].uid);
            }
        }];
    }];
    
    // pop back to appropriate tab (do not wait until image is uploaded to firebase)
    UINavigationController *lastNavigationController = [navigationControllers objectAtIndex:previous];
    [self.navigationController popToViewController:lastNavigationController animated:NO];
}

- (UIImage *)compressImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 600.0;
    float maxWidth = 800.0;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        if(imgRatio < maxRatio){
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio){
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }else{
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
}

@end

