//
//  FiltersViewController.m
//  YM
//
//  Created by user on 23/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "FiltersViewController.h"
#import "UploadPhotoViewController.h"
#import "AHCarouselItem.h"
#import "AHCarouselView.h"

@interface FiltersViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *vCarousel;

@end

@implementation FiltersViewController {
    NSMutableArray *carouselItemsArr;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.hidden = NO;
    
    // set navigation controller title
    self.navigationItem.title = @"Filters";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    // add navigation bar right button
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *nextBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(nextTapped:)];
    self.navigationItem.rightBarButtonItem = nextBtn;
    
    // iamge from previus screen
    [self.imageView setImage:self.image];
    
    // scroll view
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    carouselItemsArr = [[NSMutableArray alloc] initWithArray:[self placeholderCarouselItems]];
    for (int index = 0; index < [carouselItemsArr count]; index++) {
        AHCarouselItem *item = [carouselItemsArr objectAtIndex:index];
        CGFloat x =     (SIZE * index);
        CGFloat side =  (index == 0) ? SIZE : (SIZE * 0.68);
        item.frame =    CGRectMake(x, 0, side, side);
        item.center =   CGPointMake((x + (SIZE/2)), (SIZE/2));
        
        [self.scrollView addSubview:item];
    }
    [self.scrollView setFrame:CGRectMake(0, 0, SIZE, SIZE)];
    [self.scrollView setContentSize:CGSizeMake(SIZE * [carouselItemsArr count], SIZE)];
    [self.scrollView setCenter:self.vCarousel.center];
    [self.scrollView setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    NSArray *placeholderViews = [self.scrollView subviews];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.intralife.filtersqueue", 0);
    for(int index = 0; index < [placeholderViews count]; index++) {
        dispatch_async(backgroundQueue, ^{
            AHCarouselItem *carouselItem = [self carouselItemAtIndex:index];
            [carouselItemsArr replaceObjectAtIndex:index withObject:carouselItem];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat x = (SIZE * index);
                CGFloat side = (index == 0) ? SIZE : (SIZE * 0.68);
                carouselItem.frame = CGRectMake(x, 0, side, side);
                carouselItem.center = CGPointMake((x + (SIZE/2)), (SIZE/2));
                
                // remove placeholder
                UIView *placeholderView = [placeholderViews objectAtIndex:index];
                [placeholderView removeFromSuperview];
                
                // add filtered image
                [self.scrollView addSubview:carouselItem];
            });
        });
    }
}

- (void)goBack:(id)sender
{
    // fixes issue when self.scrollView stays on screen for short moment
    self.scrollView.hidden = YES;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextTapped:(id)sender
{
    [self performSegueWithIdentifier:@"SegueToUpload" sender:self];
}

- (NSArray*)placeholderCarouselItems
{
    NSString *placeholderImageName = @"filter_placeholder";
    return [NSArray arrayWithObjects:
            
            [AHCarouselItem itemWithTitle:@"original"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"real"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"chromy"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"inkwell"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"jasy"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"water lilly"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"dream"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"sepia"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"lava"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"magna"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            [AHCarouselItem itemWithTitle:@"infinite"
                                    image:[UIImage imageNamed:placeholderImageName]
                                   target:nil
                                   action:nil],
            nil];
}

// title is not used at the moment, but may be needed later
- (AHCarouselItem *)carouselItemAtIndex:(NSInteger)index
{
    AHCarouselItem *carouselItem;
    switch (index) {
        case 0:
            carouselItem = [AHCarouselItem itemWithTitle:@"original"
                                                   image:[self createFilterForButtonAtIndex:0]
                                                  target:nil
                                                  action:nil];
            break;
        case 1:
            carouselItem = [AHCarouselItem itemWithTitle:@"real"
                                                   image:[self createFilterForButtonAtIndex:1]
                                                  target:nil
                                                  action:nil];
            break;
        case 2:
            carouselItem = [AHCarouselItem itemWithTitle:@"chromy"
                                                   image:[self createFilterForButtonAtIndex:2]
                                                  target:nil
                                                  action:nil];
            break;
        case 3:
            carouselItem = [AHCarouselItem itemWithTitle:@"inkwell"
                                                   image:[self createFilterForButtonAtIndex:3]
                                                  target:nil
                                                  action:nil];
            break;
        case 4:
            carouselItem = [AHCarouselItem itemWithTitle:@"jasy"
                                                   image:[self createFilterForButtonAtIndex:4]
                                                  target:nil
                                                  action:nil];
            break;
        case 5:
            carouselItem = [AHCarouselItem itemWithTitle:@"water lilly"
                                                   image:[self createFilterForButtonAtIndex:5]
                                                  target:nil
                                                  action:nil];
            break;
        case 6:
            carouselItem = [AHCarouselItem itemWithTitle:@"dream"
                                                   image:[self createFilterForButtonAtIndex:6]
                                                  target:nil
                                                  action:nil];
            break;
        case 7:
            carouselItem = [AHCarouselItem itemWithTitle:@"sepia"
                                                   image:[self createFilterForButtonAtIndex:7]
                                                  target:nil
                                                  action:nil];
            break;
        case 8:
            carouselItem = [AHCarouselItem itemWithTitle:@"lava"
                                                   image:[self createFilterForButtonAtIndex:8]
                                                  target:nil
                                                  action:nil];
            break;
        case 9:
            carouselItem = [AHCarouselItem itemWithTitle:@"magna"
                                                   image:[self createFilterForButtonAtIndex:9]
                                                  target:nil
                                                  action:nil];
            break;
        case 10:
            carouselItem = [AHCarouselItem itemWithTitle:@"infinite"
                                                   image:[self createFilterForButtonAtIndex:10]
                                                  target:nil
                                                  action:nil];
            break;
        default:
            break;
    }
    
    return carouselItem;
}

- (UIImage *)createFilterForButtonAtIndex:(NSInteger)index
{
    UIImage *buttonImage = self.image; // original image returned as it is
    
    if (index > 0 && index < 11) {
        NSArray *filterNames = @[@"Original", //original image
                                 @"CILinearToSRGBToneCurve",
                                 @"CIPhotoEffectChrome",
                                 @"CIPhotoEffectFade",
                                 @"CIPhotoEffectInstant",
                                 @"CIPhotoEffectMono",
                                 @"CIPhotoEffectNoir",
                                 @"CIPhotoEffectProcess",
                                 @"CIPhotoEffectTonal",
                                 @"CIPhotoEffectTransfer",
                                 @"CISRGBToneCurveToLinear",
                                 ];
        
        UIImageOrientation originalOrientation = self.image.imageOrientation;
        CGFloat originalScale = self.image.scale;
        NSString *filterName = [filterNames objectAtIndex:index];
        CIImage *ciImage = [[CIImage alloc] initWithImage:self.image];
        CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
        [filter setDefaults];
        CIContext *context = [CIContext contextWithOptions:nil];
        CIImage *outputImage = [filter outputImage];
        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
        buttonImage = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
        CGImageRelease(cgImage);
    }
    
    return buttonImage;
}

- (void)setFilter
{
    self.imageView.image = self.image;
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page > 0 && page < [carouselItemsArr count]) {
        NSArray *items = @[@"Original", //original image
                           @"CILinearToSRGBToneCurve",
                           @"CIPhotoEffectChrome",
                           @"CIPhotoEffectFade",
                           @"CIPhotoEffectInstant",
                           @"CIPhotoEffectMono",
                           @"CIPhotoEffectNoir",
                           @"CIPhotoEffectProcess",
                           @"CIPhotoEffectTonal",
                           @"CIPhotoEffectTransfer",
                           @"CISRGBToneCurveToLinear",
                           ];
        
        UIImageOrientation originalOrientation = self.image.imageOrientation;
        CGFloat originalScale = self.image.scale;
        NSString *filterName = [items objectAtIndex:page];
        CIImage *ciImage = [[CIImage alloc] initWithImage:self.image];
        CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
        [filter setDefaults];
        CIContext *context = [CIContext contextWithOptions:nil];
        CIImage *outputImage = [filter outputImage];
        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
        self.imageView.image = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
        CGImageRelease(cgImage);
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (int index = 0; index < [carouselItemsArr count]; index++) {
        UIButton *button = [carouselItemsArr objectAtIndex:index];
        
        if (scrollView.contentOffset.x > (SIZE * (index + 1)) ||
            scrollView.contentOffset.x < (SIZE * (index - 1))) {// if offset is before / after the page bounds of current button, skip and move to the next page
            
            continue;
        }
        
        // adjust size of buttons to the LEFT of UIScrollView
        if (scrollView.contentOffset.x > (index * SIZE)) {
            CGRect frame = button.frame;
            frame.size.width = SIZE - ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
            frame.size.height = SIZE - ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
            button.frame = frame;
            button.center = CGPointMake(((SIZE * index) + (SIZE/2)), (SIZE/2));
            
            continue;
        }
        
        // adjust size of buttons to the RIGHT of UIScrollView
        if (scrollView.contentOffset.x < (index * SIZE)) {
            CGRect frame = button.frame;
            frame.size.width = SIZE + ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
            frame.size.height = SIZE + ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
            button.frame = frame;
            button.center = CGPointMake(((SIZE * index) + (SIZE/2)), (SIZE/2));
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self setFilter];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToUpload"]) {
        UploadPhotoViewController *uploadPhotoViewController = segue.destinationViewController;
        uploadPhotoViewController.image = self.imageView.image;
    }
}

@end



////
////  FiltersViewController.m
////  YM
////
////  Created by user on 23/11/2015.
////  Copyright © 2015 Your Mixed. All rights reserved.
////
//
//#import "FiltersViewController.h"
//#import "UploadPhotoViewController.h"
//#import "AHCarouselItem.h"
//#import "AHCarouselView.h"
//
//@interface FiltersViewController () <UIScrollViewDelegate>
//
//@property (weak, nonatomic) IBOutlet UIImageView *imageView;
//@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (weak, nonatomic) IBOutlet UIView *vCarousel;
//
//@end
//
//@implementation FiltersViewController {
//    NSArray *carouselItemsArr;
//}
//
//#pragma mark - View Lifecycle
//
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:YES];
//    
//    self.navigationController.navigationBar.hidden = NO;
//    
//    //add navigation bar left button (back)
//    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
//                                                                style:UIBarButtonItemStylePlain
//                                                               target:self
//                                                               action:@selector(goBack:)];
//    self.navigationItem.leftBarButtonItem = leftBtn;
//    
//    //add navigation bar right button
//    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    UIBarButtonItem *nextBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
//                                                                style:UIBarButtonItemStylePlain
//                                                               target:self
//                                                               action:@selector(nextTapped:)];
//    self.navigationItem.rightBarButtonItem = nextBtn;
//    
//    // iamge from previus screen
//    [self.imageView setImage:self.image];
//
//    // scroll view
//    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
//    carouselItemsArr = [[NSArray alloc] initWithArray:[self placeholderCarouselItems]];
//    for (int index = 0; index < [carouselItemsArr count]; index++) {
//        AHCarouselItem *item = [carouselItemsArr objectAtIndex:index];
//        CGFloat x =     (SIZE * index);
//        CGFloat side =  (index == 0) ? SIZE : (SIZE * 0.68);
//        item.frame =    CGRectMake(x, 0, side, side);
//        item.center =   CGPointMake((x + (SIZE/2)), (SIZE/2));
//        
//        [self.scrollView addSubview:item];
//    }
//    [self.scrollView setFrame:CGRectMake(0, 0, SIZE, SIZE)];
//    [self.scrollView setContentSize:CGSizeMake(SIZE * [carouselItemsArr count], SIZE)];
//    [self.scrollView setCenter:self.vCarousel.center];
//    [self.scrollView setDelegate:self];
//}
//
//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:YES];
//    
//    NSArray *placeholderViews = [self.scrollView subviews];
//    
//    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.intralife.filtersqueue", 0);
//    
//    for(int index = 0; index < [placeholderViews count]; index++) {
//    
//    dispatch_async(backgroundQueue, ^{
//        //carouselItemsArr = [[NSArray alloc] initWithArray:[self carouselItems]];
//        AHCarouselItem *carouselItem = [self carouselItemAtIndex:index];
//        carouselItemsArr add
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
////            for (int index = 0; index < [carouselItemsArr count]; index++) {
////                AHCarouselItem *item = [carouselItemsArr objectAtIndex:index];
//                CGFloat x = (SIZE * index);
//                CGFloat side = (index == 0) ? SIZE : (SIZE * 0.68);
//                carouselItem.frame = CGRectMake(x, 0, side, side);
//                carouselItem.center = CGPointMake((x + (SIZE/2)), (SIZE/2));
//                
//                // remove placeholder
//                UIView *placeholderView = [placeholderViews objectAtIndex:index];
//                [placeholderView removeFromSuperview];
//                
//                // add filtered image
//                [self.scrollView addSubview:carouselItem];
////            }
//        });
//    });
//        
//    }
//}
//
//// carouselItemAtIndex //rb
////- (void)viewDidAppear:(BOOL)animated
////{
////    [super viewDidAppear:YES];
////    
////    NSArray *placeholderViews = [self.scrollView subviews];
////    
////    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.intralife.filtersqueue", 0);
////    dispatch_async(backgroundQueue, ^{
////        carouselItemsArr = [[NSArray alloc] initWithArray:[self carouselItems]];
////        
////        dispatch_async(dispatch_get_main_queue(), ^{
////            for (int index = 0; index < [carouselItemsArr count]; index++) {
////                AHCarouselItem *item = [carouselItemsArr objectAtIndex:index];
////                CGFloat x = (SIZE * index);
////                CGFloat side = (index == 0) ? SIZE : (SIZE * 0.68);
////                item.frame = CGRectMake(x, 0, side, side);
////                item.center = CGPointMake((x + (SIZE/2)), (SIZE/2));
////
////                // remove placeholder
////                UIView *placeholderView = [placeholderViews objectAtIndex:index];
////                [placeholderView removeFromSuperview];
////                
////                // add filtered image
////                [self.scrollView addSubview:item];
////            }
////        });
////    });
////}
//
//- (void)goBack:(id)sender
//{
//    // fixes issue when self.scrollView stays on screen for short moment
//    self.scrollView.hidden = YES;
//    
//    [self.navigationController popViewControllerAnimated:YES];
//}
//
//- (void)nextTapped:(id)sender
//{
//    [self performSegueWithIdentifier:@"SegueToUpload" sender:self];
//}
//
//- (NSArray*)placeholderCarouselItems
//{
//    NSString *placeholderImageName = @"filter_placeholder";
//    return [NSArray arrayWithObjects:
//            
//            [AHCarouselItem itemWithTitle:@"original"
//                                image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"real"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"chromy"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"inkwell"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"jasy"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"water lilly"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"dream"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"sepia"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"lava"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"magna"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"infinite"
//                                    image:[UIImage imageNamed:placeholderImageName]
//                                   target:nil
//                                   action:nil],
//            nil];
//}
//
//- (AHCarouselItem *)carouselItemAtIndex:(NSInteger)index
//{
//    AHCarouselItem *carouselItem;
//    switch (index) {
//        case 0:
//            carouselItem = [AHCarouselItem itemWithTitle:@"original"
//                                                   image:[self createFilterForButtonAtIndex:0]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 1:
//            carouselItem = [AHCarouselItem itemWithTitle:@"real"
//                                                   image:[self createFilterForButtonAtIndex:1]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 2:
//            carouselItem = [AHCarouselItem itemWithTitle:@"chromy"
//                                                   image:[self createFilterForButtonAtIndex:2]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 3:
//            carouselItem = [AHCarouselItem itemWithTitle:@"inkwell"
//                                                   image:[self createFilterForButtonAtIndex:3]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 4:
//            carouselItem = [AHCarouselItem itemWithTitle:@"jasy"
//                                                   image:[self createFilterForButtonAtIndex:4]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 5:
//            carouselItem = [AHCarouselItem itemWithTitle:@"water lilly"
//                                                   image:[self createFilterForButtonAtIndex:5]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 6:
//            carouselItem = [AHCarouselItem itemWithTitle:@"dream"
//                                                   image:[self createFilterForButtonAtIndex:6]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 7:
//            carouselItem = [AHCarouselItem itemWithTitle:@"sepia"
//                                                   image:[self createFilterForButtonAtIndex:7]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 8:
//            carouselItem = [AHCarouselItem itemWithTitle:@"lava"
//                                                   image:[self createFilterForButtonAtIndex:8]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 9:
//            carouselItem = [AHCarouselItem itemWithTitle:@"magna"
//                                                   image:[self createFilterForButtonAtIndex:9]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        case 10:
//            carouselItem = [AHCarouselItem itemWithTitle:@"infinite"
//                                                   image:[self createFilterForButtonAtIndex:10]
//                                                  target:nil
//                                                  action:nil];
//            break;
//        default:
//            break;
//    }
//
//    return carouselItem;
//}
//
//- (NSArray*)carouselItems
//{
//    return [NSArray arrayWithObjects:
//            [AHCarouselItem itemWithTitle:@"original"
//                                    image:[self createFilterForButtonAtIndex:0]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"real"
//                                    image:[self createFilterForButtonAtIndex:1]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"chromy"
//                                    image:[self createFilterForButtonAtIndex:2]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"inkwell"
//                                    image:[self createFilterForButtonAtIndex:3]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"jasy"
//                                    image:[self createFilterForButtonAtIndex:4]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"water lilly"
//                                    image:[self createFilterForButtonAtIndex:5]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"dream"
//                                    image:[self createFilterForButtonAtIndex:6]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"sepia"
//                                    image:[self createFilterForButtonAtIndex:7]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"lava"
//                                    image:[self createFilterForButtonAtIndex:8]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"magna"
//                                    image:[self createFilterForButtonAtIndex:9]
//                                   target:nil
//                                   action:nil],
//            [AHCarouselItem itemWithTitle:@"infinite"
//                                    image:[self createFilterForButtonAtIndex:10]
//                                   target:nil
//                                   action:nil],
//            nil];
//}
//
//- (UIImage *)createFilterForButtonAtIndex:(NSInteger)index
//{
//    UIImage *buttonImage = self.image; // original image returned as it is
//    
//    if (index > 0 && index < 11) {
//        NSArray *filterNames = @[@"Original", //original image
//                                 @"CILinearToSRGBToneCurve",
//                                 @"CIPhotoEffectChrome",
//                                 @"CIPhotoEffectFade",
//                                 @"CIPhotoEffectInstant",
//                                 @"CIPhotoEffectMono",
//                                 @"CIPhotoEffectNoir",
//                                 @"CIPhotoEffectProcess",
//                                 @"CIPhotoEffectTonal",
//                                 @"CIPhotoEffectTransfer",
//                                 @"CISRGBToneCurveToLinear",
//                                 ];
//        
//        UIImageOrientation originalOrientation = self.image.imageOrientation;
//        CGFloat originalScale = self.image.scale;
//        NSString *filterName = [filterNames objectAtIndex:index];
//        CIImage *ciImage = [[CIImage alloc] initWithImage:self.image];
//        CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
//        [filter setDefaults];
//        CIContext *context = [CIContext contextWithOptions:nil];
//        CIImage *outputImage = [filter outputImage];
//        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
//        buttonImage = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
//        CGImageRelease(cgImage);
//    }
//    
//    return buttonImage;
//}
//
//- (void)setFilter
//{
//    self.imageView.image = self.image;
//    CGFloat pageWidth = self.scrollView.frame.size.width;
//    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
//    
//    if (page > 0 && page < [carouselItemsArr count]) {
//        NSArray *items = @[@"Original", //original image
//                           @"CILinearToSRGBToneCurve",
//                           @"CIPhotoEffectChrome",
//                           @"CIPhotoEffectFade",
//                           @"CIPhotoEffectInstant",
//                           @"CIPhotoEffectMono",
//                           @"CIPhotoEffectNoir",
//                           @"CIPhotoEffectProcess",
//                           @"CIPhotoEffectTonal",
//                           @"CIPhotoEffectTransfer",
//                           @"CISRGBToneCurveToLinear",
//                           ];
//        
//        UIImageOrientation originalOrientation = self.image.imageOrientation;
//        CGFloat originalScale = self.image.scale;
//        NSString *filterName = [items objectAtIndex:page];
//        CIImage *ciImage = [[CIImage alloc] initWithImage:self.image];
//        CIFilter *filter = [CIFilter filterWithName:filterName keysAndValues:kCIInputImageKey, ciImage, nil];
//        [filter setDefaults];
//        CIContext *context = [CIContext contextWithOptions:nil];
//        CIImage *outputImage = [filter outputImage];
//        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
//        self.imageView.image = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
//        CGImageRelease(cgImage);
//    }
//}
//
//#pragma mark - UIScrollViewDelegate
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    for (int index = 0; index < [carouselItemsArr count]; index++) {
//        UIButton *button = [carouselItemsArr objectAtIndex:index];
//        
//        if (scrollView.contentOffset.x > (SIZE * (index + 1)) ||
//            scrollView.contentOffset.x < (SIZE * (index - 1))) {// if offset is before / after the page bounds of current button, skip and move to the next page
//            
//            continue;
//        }
//        
//        // adjust size of buttons to the LEFT of UIScrollView
//        if (scrollView.contentOffset.x > (index * SIZE)) {
//            CGRect frame = button.frame;
//            frame.size.width = SIZE - ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
//            frame.size.height = SIZE - ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
//            button.frame = frame;
//            button.center = CGPointMake(((SIZE * index) + (SIZE/2)), (SIZE/2));
//            
//            continue;
//        }
//        
//        // adjust size of buttons to the RIGHT of UIScrollView
//        if (scrollView.contentOffset.x < (index * SIZE)) {
//            CGRect frame = button.frame;
//            frame.size.width = SIZE + ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
//            frame.size.height = SIZE + ((scrollView.contentOffset.x - (index * SIZE)) * 0.32);
//            button.frame = frame;
//            button.center = CGPointMake(((SIZE * index) + (SIZE/2)), (SIZE/2));
//        }
//    }
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self setFilter];
//}
//
//#pragma mark - Segues
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"SegueToUpload"]) {
//        UploadPhotoViewController *uploadPhotoViewController = segue.destinationViewController;
//        uploadPhotoViewController.image = self.imageView.image;
//    }
//}
//
//@end
