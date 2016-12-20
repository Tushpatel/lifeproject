//
//  EditProfileViewController.m
//  YM
//
//  Created by user on 11/12/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Intralife.h"
#import "Reachability.h"

#define NAME_TAG  1001
#define URL_TAG   1002
#define BIO_TAG   1003
#define EMAIL_TAG 1004
#define PHONE_TAG 1005

#define MAXLENGTH_NAME  20
#define MAXLENGTH_URL   25
#define MAXLENGTH_BIO   80
#define MAXLENGTH_EMAIL 50
#define MAXLENGTH_PHONE 14

#define MINLENGTH_NAME  2
#define MINLENGTH_URL   4
#define MINLENGTH_BIO   0
#define MINLENGTH_EMAIL 4
#define MINLENGTH_PHONE 10

@interface EditProfileViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTxt;
@property (weak, nonatomic) IBOutlet UITextField *websiteTxt;
@property (weak, nonatomic) IBOutlet UITextField *bioTxt;
@property (weak, nonatomic) IBOutlet UITextField *emailTxt;
@property (weak, nonatomic) IBOutlet UITextField *phoneTxt;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegment;

@property (weak, nonatomic) IBOutlet UIImageView *nameNoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *urlNoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bioNoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *phoneNoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *emailNoImageView;

@property (strong, nonatomic) UIBarButtonItem *uploadBtn;
@property (strong, nonatomic) Intralife *intralife;

@end

@implementation EditProfileViewController

#pragma mark - Internet Connection

- (BOOL)isInternetConnection
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if(internetStatus == NotReachable) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Error"
                                              message:@"Please check your internet connection."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.intralife = [[Intralife alloc] initIntralife];
    
    // Keyboard stuff
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.nameTxt.delegate = self;
    self.websiteTxt.delegate = self;
    self.bioTxt.delegate = self;
    self.emailTxt.delegate = self;
    self.phoneTxt.delegate = self;
    
    self.nameTxt.tag = NAME_TAG;
    self.websiteTxt.tag = URL_TAG;
    self.bioTxt.tag = BIO_TAG;
    self.emailTxt.tag = EMAIL_TAG;
    self.phoneTxt.tag = PHONE_TAG;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title
    self.navigationItem.title = @"Edit";
    
    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    // add navigation bar right button
    UIImage *rightButtonImage = [[UIImage imageNamed:@"navigation-tick.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.uploadBtn = [[UIBarButtonItem alloc] initWithImage:rightButtonImage
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(rightTapped:)];
    self.navigationItem.rightBarButtonItem = self.uploadBtn;
    
    // current user
    NSString *userId = [FIRAuth auth].currentUser.uid;
    IntralifeUser *outsideUser = [IntralifeUser loadFromRoot:self.intralife.root withUserId:userId completionBlock:^(IntralifeUser *user) {
        // name
        self.nameTxt.text = user.name;
        
        // website
        self.websiteTxt.text = user.website;
        
        // bio
        self.bioTxt.text = user.bio;
        
        // email
        self.emailTxt.text = user.email;
        
        //phone (may be empty)
        self.phoneTxt.text = user.phone;
        
        // gender
        if([user.gender isEqualToString:@"Male"]) {
            self.genderSegment.selectedSegmentIndex = 0;
        }
        else if([user.gender isEqualToString:@"Female"]) {
            self.genderSegment.selectedSegmentIndex = 1;
        }
        else {
            self.genderSegment.selectedSegmentIndex = 2;
        }
    }];
    
    self.nameNoImageView.hidden = YES;
    self.urlNoImageView.hidden = YES;
    self.bioNoImageView.hidden = YES;
    self.phoneNoImageView.hidden = YES;
    self.emailNoImageView.hidden = YES;
    
    // done with user - no need to observe anymore
    [outsideUser stopObserving];
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightTapped:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // entered information
    NSString *name  = [self.nameTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *url   = [self.websiteTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *bio   = [self.bioTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *phone = [self.phoneTxt.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    BOOL isEntryError = NO;
    BOOL isWrongName = NO;
    if(![self isValidName:name]) {
        self.nameNoImageView.hidden = NO;
        isWrongName = YES;
        isEntryError = YES;
    }
    if(![self isValidURL:url]) {
        self.urlNoImageView.hidden = NO;
        isEntryError = YES;
    }
    if(![self isValidBio:bio]) {
        self.bioNoImageView.hidden = NO;
        isEntryError = YES;
    }
    if(![self isValidEmail:email]) {
        self.emailNoImageView.hidden = NO;
        isEntryError = YES;
    }
    if(![self isValidPhone:phone]) {
        self.phoneNoImageView.hidden = NO;
        isEntryError = YES;
    }
    
    // wrong name was entered - show popup message and return
    if(isWrongName) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Your name should be 2-20 characters long."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    // some field(s) is wrong - return (red dot(s) will appear)
    if(isEntryError) {
        return;
    }
    
    FIRDatabaseReference *peopleRef = [self.intralife.root child:@"people"];
    NSString *currentUserId = [FIRAuth auth].currentUser.uid;
    FIRDatabaseReference *currentUserRef = [peopleRef child:currentUserId];
    
    // gender
    NSString *gender;
    switch (self.genderSegment.selectedSegmentIndex) {
        case 0:
            gender = @"Male";
            break;
            
        case 1:
            gender = @"Female";
            break;
            
        case 2:
            gender = @"Hidden";
            break;
            
        default:
            break;
    }
    
    // url going to Firebase database
    NSString *databaseUrl = [self createDatabaseUrl:url];
    
    NSDictionary *updatedData = @{
                                  @"name": name,
                                  @"website": databaseUrl,
                                  @"bio": bio,
                                  @"email": email,
                                  @"phone": phone,
                                  @"gender": gender
                                  };
    
    [currentUserRef updateChildValues:updatedData withCompletionBlock:^(NSError *error, FIRDatabaseReference *currentUserRef) {
        if(error) {
            NSLog(@"%@", error.localizedDescription);
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (BOOL)isValidName:(NSString *)name
{
    NSUInteger length = [name length];
    if(length < MINLENGTH_NAME) return NO;
    
    return YES;
}

- (BOOL)isValidURL:(NSString *)url
{
    NSUInteger length = [url length];
    
    // make this field not mendatory
    if(length == 0) return YES;
    
    if(length < MINLENGTH_URL) return NO;
    
    if(![self validUrl:url]) return NO;
    
    return YES;
}

- (BOOL)isValidBio:(NSString *)bio
{
    return YES;
}

- (BOOL)isValidPhone:(NSString *)phone
{
    NSUInteger length = [phone length];
    
    // make this field not mendatory
    if(length == 0) return YES;
    
    if(length < MINLENGTH_PHONE) return NO;
    
    return YES;
}

- (BOOL)isValidEmail:(NSString *)email
{
    NSUInteger length = [email length];
    
    if(length < MINLENGTH_EMAIL) return NO;
    
    if(![self validEmail:email]) return NO;
    
    return YES;
}

- (BOOL)validEmail:(NSString*)emailString
{
    //TODO: test this regex more
    // taken from: stackoverflow.com/questions/11760787/regex-for-email-address
    const char cRegex[] = "^(?!(?:(?:\\x22?\\x5C[\\x00-\\x7E]\\x22?)|(?:\\x22?[^\\x5C\\x22]\\x22?)){255,})(?!(?:(?:\\x22?\\x5C[\\x00-\\x7E]\\x22?)|(?:\\x22?[^\\x5C\\x22]\\x22?)){65,}@)(?:(?:[\\x21\\x23-\\x27\\x2A\\x2B\\x2D\\x2F-\\x39\\x3D\\x3F\\x5E-\\x7E]+)|(?:\\x22(?:[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x21\\x23-\\x5B\\x5D-\\x7F]|(?:\\x5C[\\x00-\\x7F]))*\\x22))(?:\\.(?:(?:[\\x21\\x23-\\x27\\x2A\\x2B\\x2D\\x2F-\\x39\\x3D\\x3F\\x5E-\\x7E]+)|(?:\\x22(?:[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x21\\x23-\\x5B\\x5D-\\x7F]|(?:\\x5C[\\x00-\\x7F]))*\\x22)))*@(?:(?:(?!.*[^.]{64,})(?:(?:(?:xn--)?[a-z0-9]+(?:-+[a-z0-9]+)*\\.){1,126}){1,}(?:(?:[a-z][a-z0-9]*)|(?:(?:xn--)[a-z0-9]+))(?:-+[a-z0-9]+)*)|(?:\\[(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){7})|(?:(?!(?:.*[a-f0-9][:\\]]){7,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?)))|(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){5}:)|(?:(?!(?:.*[a-f0-9]:){5,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3}:)?)))?(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))(?:\\.(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))){3}))\\]))$";
    NSString *emailRegex = [NSString stringWithUTF8String:cRegex];
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    if (![emailTest evaluateWithObject:emailString]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validUrl:(NSString*)url
{
    NSUInteger length = [url length];
    if (length > 0) { // empty strings should return NO
        NSError *error = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (dataDetector && !error) {
            NSRange range = NSMakeRange(0, length);
            NSRange notFoundRange = (NSRange){NSNotFound, 0};
            NSRange linkRange = [dataDetector rangeOfFirstMatchInString:url options:0 range:range];
            if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (NSString *)createDatabaseUrl:(NSString *)webAddress
{
    // filter out prefixes
    NSArray *prefixes = [NSArray arrayWithObjects:@"https:", @"http:", @"www.", @"//", @"/", nil];
    
    for (NSString *prefix in prefixes) {
        if([webAddress hasPrefix:prefix]) {
            webAddress = [webAddress stringByReplacingOccurrencesOfString:prefix
                                                               withString:@""
                                                                  options:NSAnchoredSearch
                                                                    range:NSMakeRange(0, [webAddress length])];
        }
    }
    
    // filter out suffixes
    NSArray *suffixes = [NSArray arrayWithObjects:@"/", nil];
    for (NSString *suffix in suffixes) {
        if([webAddress hasSuffix:suffix]) {
            webAddress = [webAddress stringByReplacingOccurrencesOfString:suffix
                                                               withString:@""
                                                                  options:NSBackwardsSearch
                                                                    range:NSMakeRange(0, [webAddress length])];
        }
    }
    
    return webAddress;
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nameTxt resignFirstResponder];
    [self.websiteTxt resignFirstResponder];
    [self.bioTxt resignFirstResponder];
    [self.emailTxt resignFirstResponder];
    [self.phoneTxt resignFirstResponder];
    
    return YES;
}

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

// max length of text fields
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    switch (textField.tag) {
        case NAME_TAG: // name
        {
            self.nameNoImageView.hidden = YES;
            
            NSUInteger oldLength = [textField.text length];
            NSUInteger replacementLength = [string length];
            NSUInteger rangeLength = range.length;
            NSUInteger newLength = oldLength - rangeLength + replacementLength;
            BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
            
            return newLength <= MAXLENGTH_NAME || returnKey;
        }
            break;
            
        case URL_TAG: // website
        {
            self.urlNoImageView.hidden = YES;
            
            NSUInteger oldLength = [textField.text length];
            NSUInteger replacementLength = [string length];
            NSUInteger rangeLength = range.length;
            NSUInteger newLength = oldLength - rangeLength + replacementLength;
            BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
            
            return newLength <= MAXLENGTH_URL || returnKey;
        }
            break;
            
        case BIO_TAG: // bio
        {
            self.bioNoImageView.hidden = YES;
            
            NSUInteger oldLength = [textField.text length];
            NSUInteger replacementLength = [string length];
            NSUInteger rangeLength = range.length;
            NSUInteger newLength = oldLength - rangeLength + replacementLength;
            BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
            
            return newLength <= MAXLENGTH_BIO || returnKey;
        }
            break;
            
        case EMAIL_TAG: // email
        {
            self.emailNoImageView.hidden = YES;
            
            NSUInteger oldLength = [textField.text length];
            NSUInteger replacementLength = [string length];
            NSUInteger rangeLength = range.length;
            NSUInteger newLength = oldLength - rangeLength + replacementLength;
            BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
            
            return newLength <= MAXLENGTH_EMAIL || returnKey;
        }
            break;
            
        case PHONE_TAG: // phone
        {
            self.phoneNoImageView.hidden = YES;
            
            NSUInteger oldLength = [textField.text length];
            NSUInteger replacementLength = [string length];
            NSUInteger rangeLength = range.length;
            NSUInteger newLength = oldLength - rangeLength + replacementLength;
            BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
            
            return newLength <= MAXLENGTH_PHONE || returnKey;
        }
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
