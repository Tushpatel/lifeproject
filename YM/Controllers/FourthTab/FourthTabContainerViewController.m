//
//  FourthTabContainerViewController.m
//  YM
//
//  Created by user on 19/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FourthTabContainerViewController.h"
#import "ActivityFollowingViewController.h"
#import "ActivityYouViewController.h"

#define SegueIdentifierZero @"initialEmbedFirst"
#define SegueIdentifierFirst @"embedFirst"
#define SegueIdentifierSecond @"embedSecond"

@interface FourthTabContainerViewController ()

@property (strong, nonatomic) NSString *currentSegueIdentifier;
@property (strong, nonatomic) ActivityFollowingViewController *firstViewController;
@property (strong, nonatomic) ActivityYouViewController *secondViewController;
@property (assign, nonatomic) BOOL transitionInProgress;

@end

@implementation FourthTabContainerViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.transitionInProgress = NO;
    self.currentSegueIdentifier = SegueIdentifierFirst;
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Instead of creating new VCs on each seque we want to hang on to existing
    // instances if we have it. Remove the second condition of the following
    // two if statements to get new VC instances instead.
    if ([segue.identifier isEqualToString:SegueIdentifierFirst]) {
        self.firstViewController = segue.destinationViewController;
    }
    
    if ([segue.identifier isEqualToString:SegueIdentifierSecond]) {
        self.secondViewController = segue.destinationViewController;
    }
    
    // If we're going to the first view controller.
    if ([segue.identifier isEqualToString:SegueIdentifierFirst]) {
        // If this is not the first time we're loading this.
        if (self.childViewControllers.count > 0) {
            
            [self swapFromCameraViewController:[self.childViewControllers objectAtIndex:0] toAlbumViewController:self.firstViewController];
        }
        else {
            // If this is the very first time we're loading this we need to do
            // an initial load and not a swap.
            
            [self addChildViewController:segue.destinationViewController];
            UIView* destView = ((UIViewController *)segue.destinationViewController).view;
            destView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            destView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:destView];
            [segue.destinationViewController didMoveToParentViewController:self];
        }
    }
    // By definition the second view controller will always be swapped with the
    // first one.
    else if ([segue.identifier isEqualToString:SegueIdentifierSecond]) {
        [self swapFromAlbumViewController:[self.childViewControllers objectAtIndex:0] toCameraViewController:self.secondViewController];
    }
    else if ([segue.identifier isEqualToString:SegueIdentifierZero]) {
        
    }
}

- (void)swapFromCameraViewController:(UIViewController *)cameraViewController toAlbumViewController:(UIViewController *)albumViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    albumViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [cameraViewController willMoveToParentViewController:nil];
    [self addChildViewController:albumViewController];
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    albumViewController.view.frame = CGRectMake(-width, 0, width, height);
    [self transitionFromViewController:cameraViewController
                      toViewController:albumViewController
                              duration:0.4
                               options:UIViewAnimationOptionTransitionNone
                            animations:^(void) {
                                cameraViewController.view.frame = CGRectMake(0 + width, 0, width, height);
                                albumViewController.view.frame = CGRectMake(0, 0, width, height);
                            }
                            completion:^(BOOL finished){
                                [cameraViewController removeFromParentViewController];
                                [albumViewController didMoveToParentViewController:self];
                                self.transitionInProgress = NO;
                                
                            }
     ];
}

- (void)swapFromAlbumViewController:(UIViewController *)albumViewController toCameraViewController:(UIViewController *)cameraViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    cameraViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [albumViewController willMoveToParentViewController:nil];
    [self addChildViewController:cameraViewController];
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    cameraViewController.view.frame = CGRectMake(width, 0, width, height);
    [self transitionFromViewController:albumViewController
                      toViewController:cameraViewController
                              duration:0.4
                               options:UIViewAnimationOptionTransitionNone
                            animations:^(void) {
                                albumViewController.view.frame = CGRectMake(0 - width, 0, width, height);
                                cameraViewController.view.frame = CGRectMake(0, 0, width, height);
                            }
                            completion:^(BOOL finished){
                                [albumViewController removeFromParentViewController];
                                [cameraViewController didMoveToParentViewController:self];
                                self.transitionInProgress = NO;
                                
                            }
     ];
}

- (void)swapViewControllers
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.transitionInProgress) {
        return;
    }
    
    self.transitionInProgress = YES;
    self.currentSegueIdentifier = ([self.currentSegueIdentifier isEqualToString:SegueIdentifierFirst]) ? SegueIdentifierSecond : SegueIdentifierFirst;
    
    if (([self.currentSegueIdentifier isEqualToString:SegueIdentifierFirst]) && self.firstViewController) {
        [self swapToAlbum];
        return;
    }
    
    if (([self.currentSegueIdentifier isEqualToString:SegueIdentifierSecond]) && self.secondViewController) {
        [self swapToCamera];
        return;
    }
    
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}

- (void)swapToAlbum
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self swapFromCameraViewController:self.secondViewController toAlbumViewController:self.firstViewController];
}

- (void)swapToCamera
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self swapFromAlbumViewController:self.firstViewController toCameraViewController:self.secondViewController];
}

@end

