//
//  AHCarouselItem.h
//  Carousel
//
//  Created by Ahmed Omer on 21/03/2013.
//
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#define SIZE 100.0

@interface AHCarouselItem : UIButton
{
    NSString *_strItemTitle;
}

@property (nonatomic, retain) NSString *itemTitle;

+ (AHCarouselItem*)itemWithTitle:(NSString *)title
                           image:(UIImage*)image
                          target:(id)target
                          action:(SEL)action;

@end
