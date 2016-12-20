//
//  AHCarouselItem.m
//  Carousel
//
//  Created by Ahmed Omer on 21/03/2013.
//
//

#import "AHCarouselItem.h"

@implementation AHCarouselItem

@synthesize itemTitle = _strItemTitle;

+ (AHCarouselItem*)itemWithTitle:(NSString *)title
                           image:(UIImage*)image
                          target:(id)target
                          action:(SEL)action
{
    AHCarouselItem *item = [AHCarouselItem buttonWithType:UIButtonTypeCustom];
    
    item.itemTitle =    title;
    item.frame =        CGRectMake((SIZE * 0), 0, SIZE, SIZE);
    item.center =       CGPointMake(((SIZE * 0) + (SIZE/2)), (SIZE/2));
    
    item.layer.borderColor   =  [[UIColor grayColor] CGColor];
    item.layer.borderWidth   =  1.0;
    item.layer.shadowColor   =  [[UIColor blackColor] CGColor];
    item.layer.shadowOffset  =  CGSizeMake(1.0, 1.0);
    item.layer.shadowOpacity =  0.8;
    
    [item setImage:image forState:UIControlStateNormal];
    
    [item addTarget:target
             action:action
   forControlEvents:UIControlEventTouchUpInside];
    
    return item;
}

@end
