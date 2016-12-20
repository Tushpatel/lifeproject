//
//  AHCarouselView.h
//  Carousel
//
//  Created by Ahmed Omer on 21/03/2013.
//
//

#import <UIKit/UIKit.h>

@interface AHCarouselView : UIView
{
    UIScrollView *_scrollView;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

@end
