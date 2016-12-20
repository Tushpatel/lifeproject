//
//  IntralifePhoto.m
//  YM
//
//  Created by user on 30/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "IntralifePhoto.h"

@interface IntralifePhoto ()

@property (nonatomic) FIRDatabaseHandle valueHandle;
@property (nonatomic) BOOL loaded;
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

typedef void (^ffbt_void_ffphoto)(IntralifePhoto* photo);

@implementation IntralifePhoto

+ (IntralifePhoto *)loadFromRoot:(FIRDatabaseReference *)root withPhotoId:(NSString *)photoId block:(ffbt_void_ffphoto)block
{
    ffbt_void_ffphoto userBlock = [block copy];
    FIRDatabaseReference *photoRef = [[root child:@"photos"] child:photoId];
    return [[IntralifePhoto alloc] initWithRef:photoRef andBlock:userBlock];
}

- (id)initWithRef:(FIRDatabaseReference *)ref andBlock:(ffbt_void_ffphoto)block
{
    self = [super init];
    if (self) {
        self.ref = ref;
        // Load the data for this photo from Firebase
        self.valueHandle = [ref observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            id rawKey = snapshot.key;
            id rawVal = snapshot.value;
            if (rawVal == [NSNull null]) {
                block(nil);
            }
            else {
                self.photoId = rawKey;
                NSDictionary *val = rawVal;
                self.authorId = [val objectForKey:@"authorId"];
                self.authorUsername = [val objectForKey:@"authorUsername"];
                self.title = [val objectForKey:@"title"];
                self.report = [val objectForKey:@"report"];
                self.timestamp = [(NSNumber *)[val objectForKey:@"timestamp"] doubleValue];
                self.comments = [val objectForKey:@"comments"];
                self.likes = [val objectForKey:@"likes"];
                block(self); 
            }
        }];
    }
    
    return self;
}

- (void)stopObserving
{
    [self.ref removeObserverWithHandle:self.valueHandle];
}

@end
