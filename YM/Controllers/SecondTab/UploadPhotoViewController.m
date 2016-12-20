//
//  UploadPhotoViewController.m
//  YM
//
//  Created by user on 19/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "UploadPhotoViewController.h"
#import <Social/Social.h>
#import "MBProgressHUD.h"
#import "Intralife.h"
#import "Reachability.h"

#define MAXLENGTH 30

@interface UploadPhotoViewController () <UITextFieldDelegate, IntralifeDelegate>

- (IBAction)postToFacebook:(id)sender;
- (IBAction)postToTwitter:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UIButton *facebookBtn;
@property (weak, nonatomic) IBOutlet UIButton *twitterBtn;

@property (strong, nonatomic) UIBarButtonItem *uploadBtn;
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation UploadPhotoViewController

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
    
    self.ref = [[FIRDatabase database] reference];

    self.intralife = [[Intralife alloc] initIntralife];
    self.intralife.delegate = self;
    
    [self.photoImageView setImage:self.image];

    // keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.titleTextField.delegate = self;
    
    // remove twitter and facebook buttons for iPhone 4 (height 480) because there is no space
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            self.facebookBtn.hidden = YES;
            self.twitterBtn.hidden = YES;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Upload";
    
    // hide navigation bar back button
    self.navigationItem.hidesBackButton = NO;
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    // add navigation bar right button (upload)
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.uploadBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(rightTapped:)];
    self.navigationItem.rightBarButtonItem = self.uploadBtn;
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Buttons

- (IBAction)postToFacebook:(id)sender
{
    if(![self isInternetConnection]) return;
    
//    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
    
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [controller setInitialText:@"Check this out! Posted via IntraLife - Social App for Mixed Heritage Millenials!"];
    [controller addURL:[NSURL URLWithString:@"http://www.IntraLife.co"]];
    [controller addImage:self.photoImageView.image];
    
    [self presentViewController:controller animated:YES completion:Nil];
//    }
}

- (IBAction)postToTwitter:(id)sender
{
    if(![self isInternetConnection]) return;
    
//        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
    
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [controller setInitialText:@"Check this out! Posted via IntraLife - Social App for Mixed Heritage Millenials!"];
    [controller addURL:[NSURL URLWithString:@"http://www.IntraLife.co"]];
    [controller addImage:self.photoImageView.image];
    
    [self presentViewController:controller animated:YES completion:Nil];
//        }
}

- (void)rightTapped:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // Disable the Upload button to prevent multiple touches
    [self.uploadBtn setEnabled:NO];
    
    // Check that we have a comment to go with the image
    if (self.titleTextField.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Image Title"
                                              message:@"Please provide a title for the image before posting."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.uploadBtn setEnabled:YES];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }

    // post photo
    [self.view endEditing:YES]; // dismiss keyboard

    // compress image before uploading it to Firebase
    UIImage *compressedImage = [self compressImage:self.photoImageView.image];
    
    [self.intralife postPhoto:compressedImage title:self.titleTextField.text forUser:[FIRAuth auth].currentUser.uid completionBlock:^(NSError *error) {
        // photo uploaded in background
    }];
    [self.tabBarController setSelectedIndex:0];
    [self.navigationController popToRootViewControllerAnimated:NO];
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

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.titleTextField resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= MAXLENGTH || returnKey;
}

@end
