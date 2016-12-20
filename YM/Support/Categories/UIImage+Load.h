#import <UIKit/UIKit.h>

@interface UIImage (Load)

+ (void) loadFromURL: (NSURL*) url callback:(void (^)(UIImage *image))callback;

@end
