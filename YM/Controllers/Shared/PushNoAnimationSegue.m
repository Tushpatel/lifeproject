//
//  PushNoAnimationSegue.m
//  YM
//
//  Created by user on 22/03/2016.
//  Copyright © 2016 Your Mixed. All rights reserved.
//

#import "PushNoAnimationSegue.h"

@implementation PushNoAnimationSegue

- (void)perform
{
    UIViewController *dest = (UIViewController *) self.destinationViewController;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = dest;
}

@end
