//
//  FinalImageViewController.m
//  YM
//
//  Created by user on 30/03/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "FinalImageViewController.h"
#import "SignUp6ViewController.h"
#import "FifthTabViewController.h"
#import "Intralife.h"
#import "Intralife.h"

@interface FinalImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *finalImageView;

@property (strong, nonatomic) Intralife *intralife;

@end

@implementation FinalImageViewController

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
    NSArray *navigationControllers = self.navigationController.viewControllers;
    NSInteger previous = navigationControllers.count - 3;
    
    SignUp6ViewController *signUp6ViewController = [navigationControllers objectAtIndex:previous];
    self.finalImage = [self compressImage:self.finalImage]; // compress image before passing to next view controller
    signUp6ViewController.profileImage = self.finalImage;
    [self.navigationController popToViewController:signUp6ViewController animated:NO];
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

