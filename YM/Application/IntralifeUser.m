//
//  IntralifeUser.m
//  YM
//
//  Created by user on 30/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "IntralifeUser.h"

@interface IntralifeUser ()

@property (nonatomic) FIRDatabaseHandle valueHandle;
@property (nonatomic) BOOL loaded;
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation IntralifeUser

typedef void (^ffbt_void_ffuser)(IntralifeUser* user);

+ (IntralifeUser *)loadFromRoot:(FIRDatabaseReference *)root
                     withUserId:(NSString *)userId
                completionBlock:(ffbt_void_ffuser)block
{
    // Create basic user data from what we already know and pass through
    return [self loadFromRoot:root withUserData:@{@"userId": userId} completionBlock:block];
}

+ (IntralifeUser *)loadFromRoot:(FIRDatabaseReference *)root
                   withUserData:(NSDictionary *)userData
                completionBlock:(ffbt_void_ffuser)block
{
    // Create a new IntralifeUser instance pointed at the given location, with the given initial data, and setup the callback for when it updates
    ffbt_void_ffuser userBlock = [block copy];
    NSString* userId = [userData objectForKey:@"userId"];
    FIRDatabaseReference* peopleRef = [[root child:@"people"] child:userId];
    
    return [[IntralifeUser alloc] initRef:peopleRef initialData:userData andBlock:userBlock];
}

- (id)initRef:(FIRDatabaseReference *)ref
  initialData:(NSDictionary *)userData
     andBlock:(ffbt_void_ffuser)userBlock
{
    self = [super init];
    if (self) {
        self.loaded = NO;
        self.userId = ref.key;
        // Setup any initial data that we already have
        self.bio = [userData objectForKey:@"bio"];
        self.website = [userData objectForKey:@"website"];
        self.phone = [userData objectForKey:@"phone"];
        self.email = [userData objectForKey:@"email"];
        self.gender = [userData objectForKey:@"gender"];
        self.name = [userData objectForKey:@"name"];
        self.countries = [userData objectForKey:@"countries"];
        self.username = [userData objectForKey:@"username"];
        self.ref = ref;
        // Load the actual data from Firebase
        self.valueHandle = [ref observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            id val = snapshot.value;
            if (val == [NSNull null]) {
                // First login
            } else {
                NSString* prop = [val objectForKey:@"bio"];
                if (prop) {
                    self.bio = prop;
                }
                prop = [val objectForKey:@"website"];
                if (prop) {
                    self.website = prop;
                }
                prop = [val objectForKey:@"phone"];
                if (prop) {
                    self.phone = prop;
                }
                prop = [val objectForKey:@"email"];
                if (prop) {
                    self.email = prop;
                }
                prop = [val objectForKey:@"gender"];
                if (prop) {
                    self.gender = prop;
                }
                prop = [val objectForKey:@"name"];
                if (prop) {
                    self.name = prop;
                }
                prop = [val objectForKey:@"username"];
                if (prop) {
                    self.username = prop;
                }
                NSArray *propCountries = [val objectForKey:@"countries"];
                if (prop) {
                    self.countries = propCountries;
                }
            }

            if (self.loaded) {
                // just call the delegate for updates
                [self.delegate userDidUpdate:self];
            }
            else {
                // Trigger the block for the initial load
                userBlock(self);
            }
            self.loaded = YES;
        }];
    }
    
    return self;
}

- (void)stopObserving
{
    [_ref removeObserverWithHandle:_valueHandle];
    _valueHandle = NSNotFound;
}


- (void)updateFromRoot:(FIRDatabaseReference *)root
{
    // We force lowercase for name so that we can check search index keys in the security rules
    // Those values aren't used for display anyways
    FIRDatabaseReference *peopleRef = [[root child:@"people"] child:_userId];
    [peopleRef updateChildValues:@{@"bio": _bio, @"website": _website, @"phone": _phone, @"email": _email, @"gender": _gender, @"name": [_name lowercaseString], @"countries": _countries, @"username": _username}];
}

- (void)setBio:(NSString *)bio
{
    if (!bio) {
        _bio = @"";
    }
    else {
        _bio = bio;
    }
}

- (void)setWebsite:(NSString *)website
{
    if(!website) {
        _website = @"";
    }
    else {
        _website = website;
    }
}

- (void)setPhone:(NSString *)phone
{
    if (!phone) {
        _phone = @"";
    }
    else {
        _phone = phone;
    }
}

- (void)setEmail:(NSString *)email
{
    if (!email) {
        _email = @"";
    }
    else {
        _email = email;
    }
}

- (void)setGender:(NSString *)gender
{
    if (!gender) {
        _gender = @"Hidden";
    }
    else {
        _gender = gender;
    }
}

- (void)setName:(NSString *)name
{
    if(!name) {
        _name = @"";
    }
    else {
        _name = name;
    }
}

- (void)setUsername:(NSString *)username
{
    if (!username) {
        _username = @"";
    }
    else {
        _username = username;
    }
}

- (void)setCountries:(NSArray *)countries
{
    // has to be at least one country
    _countries = countries;
}

// Override so that we can find other objects pointed at the same user
- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]] && [self.userId isEqualToString:[object userId]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"User %@", _userId];
}

@end
