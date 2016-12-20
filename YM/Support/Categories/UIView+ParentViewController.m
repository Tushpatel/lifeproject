//
//  UIView+ParentViewController.m
//  YM
//
//  Created by user on 03/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "UIView+ParentViewController.h"

@implementation UIView (ParentViewController)

- (UIViewController *)parentViewController
{
    
    //Go up in responder hierarchy until we reach a ViewController or return nil
    //if we don't find one
    id object = [self nextResponder];
    
    while (![object isKindOfClass:[UIViewController class]] &&
           object != nil) {
        object = [object nextResponder];
    }
    
    return object;
}

@end