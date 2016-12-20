//
//  AHCarouselView.m
//  Carousel
//
//  Created by Ahmed Omer on 21/03/2013.
//
//

#import "AHCarouselView.h"

//@interface AHCarouselView ()
//
//@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
//
//@end

@implementation AHCarouselView

@synthesize scrollView = _scrollView;

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    BOOL pointInside = [self pointInside:point
                               withEvent:event];
    
    if (pointInside && _scrollView)
    {// if point resides inside this view and UIScrollView object exists
        
        if (CGRectContainsPoint(_scrollView.frame, point))
        {// if point resides inside UIScrollView
            
            return [super hitTest:point withEvent:event]; // do not override
        }
        
        else
        {// if point resides outside UIScrollView
            
            return _scrollView; // override to return UIScrollView
        }
    }
	
	return [super hitTest:point withEvent:event]; // do not override
}

@end
