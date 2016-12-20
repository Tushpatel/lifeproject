//
//  SignUp5ViewController.m
//  YM
//
//  Created by user on 21/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "SignUp5ViewController.h"
#import "SignUp6ViewController.h"
#import "CountryPicker.h"
#import "ARSPopover.h"
#import "Reachability.h"

#define MAX_COUNTRIES 5

@interface SignUp5ViewController () <CountryPickerDelegate>

- (IBAction)infoPressed:(id)sender;
- (IBAction)removeCountryPressed:(id)sender;
- (IBAction)addCountryPressed:(id)sender;
- (IBAction)signinPressed:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton *removeCountryBtn;
@property (nonatomic, weak) IBOutlet UIButton *addCountryBtn;
@property (nonatomic, weak) IBOutlet UIButton *infoBtn;
@property (nonatomic, weak) IBOutlet UILabel *countryNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *countryName1Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName2Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName3Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName4Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName5Label;

@end

@implementation SignUp5ViewController
{
    NSMutableArray *selectedCountries;
    NSUInteger selectedCountriesCount;
    NSString *pickerCountryName;
    NSString *pickerCountryCode;
}

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
    
    // create an array holding user countries
    selectedCountries  = [[NSMutableArray alloc] init];
    
    // no countries selected yet
    selectedCountriesCount = 0;

    self.countryName1Label.text = @"";
    self.countryName2Label.text = @"";
    self.countryName3Label.text = @"";
    self.countryName4Label.text = @"";
    self.countryName5Label.text = @"";
    
    // there are no countrie to remove yet
    self.removeCountryBtn.userInteractionEnabled = NO;
    
    // initial country
    self.countryNameLabel.text = @"Afganistan";
    pickerCountryName = @"Afganistan";
    pickerCountryCode = @"AF";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title";
    self.navigationItem.title = @"Select Your Background";

    // add navigation bar left button (back)
    UIImage *leftButtonImage =[[UIImage imageNamed:@"navigation-back.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:leftButtonImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
}

- (void)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CountryPickerDelegate

- (void)countryPicker:(__unused CountryPicker *)picker didSelectCountryWithName:(NSString *)name code:(NSString *)code
{
    self.countryNameLabel.text = name;
    
    pickerCountryName = name;
    
    pickerCountryCode = code;
    
    // country selected - allow to add it
    self.addCountryBtn.userInteractionEnabled = YES;
}

#pragma mark - IBActions

- (IBAction)infoPressed:(id)sender
{
    ARSPopover *popoverController = [ARSPopover new];
    popoverController.sourceView = self.infoBtn;
    popoverController.sourceRect = CGRectMake(CGRectGetMidX(self.infoBtn.bounds), CGRectGetMaxY(self.infoBtn.bounds), 0, 0);
    popoverController.contentSize = CGSizeMake(300, 170);
    popoverController.arrowDirection = UIPopoverArrowDirectionUp;
    
    [self presentViewController:popoverController animated:YES completion:^{
        
        [popoverController insertContentIntoPopover:^(ARSPopover *popover, CGSize popoverPresentedSize, CGFloat popoverArrowHeight) {
            CGFloat originX = 4;
            CGFloat originY = 0;
            CGFloat width = popoverPresentedSize.width;
            CGFloat height = popoverPresentedSize.height - popoverArrowHeight;
            CGRect frame = CGRectMake(originX, originY, width, height);
            UILabel *label=[[UILabel alloc]initWithFrame:frame];
            [label setText:@"• Choose your background from the country selector.\n• Press the + (plus) button to add another country.\n• Press the - (minus) button if you need to remove a country.\n• You can select 2-5 countries.\n• Each country must be different.\n• When you have selected your background, press the NEXT button."];
            label.font=[UIFont fontWithName:@"HelveticaNeue" size:14];
            [label setTextAlignment:NSTextAlignmentLeft];
            [label setNumberOfLines:10];
            [popover.view addSubview:label];
        }];
    }];
}

- (IBAction)removeCountryPressed:(id)sender
{
    switch (selectedCountriesCount) {
        case 0:
            break;
            
        case 1:
            [self removeCountryForLabel:self.countryName1Label];
            break;
            
        case 2:
            [self removeCountryForLabel:self.countryName2Label];
            break;
            
        case 3:
            [self removeCountryForLabel:self.countryName3Label];
            break;
            
        case 4:
            [self removeCountryForLabel:self.countryName4Label];
            break;
            
        case 5:
            [self removeCountryForLabel:self.countryName5Label];
            break;
            
        default:
            break;
    }
    
    // hide removeCountryBtn if there are no countries selected
    if(selectedCountriesCount == 0) {
        self.removeCountryBtn.userInteractionEnabled = NO;
    }
    
    // show addCountryBtn if maxSelectedCountriesCount is less than count og corrently selected countries
    if(selectedCountriesCount < MAX_COUNTRIES) {
        self.addCountryBtn.userInteractionEnabled = YES;
    }
}

- (IBAction)addCountryPressed:(id)sender
{
    switch (selectedCountriesCount) {
        case 0:
            [self addCountryForLabel:self.countryName1Label];
            break;
            
        case 1:
            [self addCountryForLabel:self.countryName2Label];
            break;
            
        case 2:
            [self addCountryForLabel:self.countryName3Label];
            break;
            
        case 3:
            [self addCountryForLabel:self.countryName4Label];
            break;
            
        case 4:
            [self addCountryForLabel:self.countryName5Label];
            break;
            
        case 5:
            [self addCountryForLabel:self.countryName5Label];
            break;
            
        default:
            break;
    }
    
    // show removeCountryBtn if there are countries selected
    if(selectedCountriesCount > 0) {
        self.removeCountryBtn.userInteractionEnabled = YES;
    }
    
    // country added - select another country
    self.addCountryBtn.userInteractionEnabled = NO;
}

- (void)addCountryForLabel:(UILabel *)countryLabel
{
    // if it's repeated country - do nothing
    NSString *countryname = pickerCountryCode;
    if([selectedCountries indexOfObject:countryname] != NSNotFound) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Each country must be different."
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"OK action");
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    // if 5 countries selected already - do nothing
    else if(selectedCountriesCount == 5) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Choose a maximum of 5 countries."
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"OK action");
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    else {
        self.countryNameLabel.text = @"";
        countryLabel.text = pickerCountryName;
        selectedCountriesCount++;
        [selectedCountries addObject:pickerCountryCode];
    }
}

- (void)removeCountryForLabel:(UILabel *)countryLabel
{
    countryLabel.text = @"";
    selectedCountriesCount--;
    [selectedCountries removeLastObject];
}

- (IBAction)nextPressed:(id)sender
{
    if(![self isInternetConnection]) return;
    
    // Check that at least 2 countries was selected
    if([selectedCountries count] < 2) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Oops!"
                                              message:@"Choose at least 2 countries."
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"OK action");
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    else {
        //add countries for the user
        self.userData[@"countries"] = selectedCountries;
        
        // go to the next scren
        [self performSegueWithIdentifier:@"SegueToPicture" sender:self];
    }
}

- (IBAction)signinPressed:(id)sender
{
    [self performSegueWithIdentifier:@"SegueTologIn" sender:self];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToPicture"]) {
        SignUp6ViewController *signUp6ViewController = segue.destinationViewController;
        signUp6ViewController.userData = self.userData;
    }
}

@end
