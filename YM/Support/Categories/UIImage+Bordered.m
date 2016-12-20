#import "UIImage+Bordered.h"

@implementation UIImage (Bordered)

- (UIImage *)imageBorderedWithColor:(UIColor *)color borderWidth:(CGFloat)width
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawAtPoint:CGPointZero];
    [color setStroke];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    path.lineWidth = width;
    [path stroke];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end