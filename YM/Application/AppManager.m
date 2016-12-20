//
//  AppManager.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "AppManager.h"

@interface AppManager ()

@end


@implementation AppManager


#pragma mark - Singleton methods

// GCD and ARC way to get a singleton
+ (AppManager *)sharedAppManager
{
    __strong static AppManager *sharedMyManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

- (id)init
{
    if ((self = [super init])) {
        [self setUserDefaults];
    }
    
    return self;
}

#pragma mark - User defaults

- (void)setUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults boolForKey:@"firstRunCompleted"]) {
        [defaults setBool:YES forKey:@"firstRunCompleted"];
        [defaults synchronize];
    }
}

#pragma mark - plist processing

- (void)saveLoginDataToPlist:(NSDictionary *)loginDetails
{
    //get the plist document path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistFilePath = [documentsDirectory stringByAppendingPathComponent:@"loginDetails.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // if plist doesn’t exist, create an empty plist file
    if (![fileManager fileExistsAtPath: plistFilePath]) {
        NSLog(@"plist does not exist");
        plistFilePath = [documentsDirectory stringByAppendingPathComponent:@"loginDetails.plist"];
        NSLog(@"plist path: %@", plistFilePath);
    }
    
    // save dictionary to plist file
    if([loginDetails writeToFile:plistFilePath atomically:YES]) {
        NSLog(@"Saved new plist");
        
        NSLog(@"................. plistFilePath ................. %@", plistFilePath); ////////////////////////rb
    }
    else {
        NSLog(@"plist could not be saved");
    }
}

// if plist file does not exist (when runing app first time) - null is returned
- (NSDictionary *)getLoginPlistData
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistFilePath = [documentsDirectory stringByAppendingPathComponent:@"loginDetails.plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:plistFilePath];
    
    return dictionary;
}

// Should never be called, but just here for clarity really.
- (void)dealloc
{
    // clean up code goes here
}

@end

