//
//  ThirdTabViewController.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "ThirdTabViewController.h"
#import "CountryPicker.h"
#import "ARSPopover.h"
#import "Intralife.h"
#import "MatchingProfilesViewController.h"

#define MAX_COUNTRIES 5

@interface ThirdTabViewController () <CountryPickerDelegate>

- (IBAction)infoPressed:(id)sender;
- (IBAction)removeCountryPressed:(id)sender;
- (IBAction)addCountryPressed:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton *removeCountryBtn;
@property (nonatomic, weak) IBOutlet UIButton *addCountryBtn;
@property (nonatomic, weak) IBOutlet UIButton *infoBtn;
@property (nonatomic, weak) IBOutlet UILabel *countryNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *countryName1Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName2Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName3Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName4Label;
@property (nonatomic, weak) IBOutlet UILabel *countryName5Label;

@property (nonatomic, strong) Intralife *intralife;

@end

@implementation ThirdTabViewController
{
    NSMutableArray *selectedCountries;
    NSUInteger selectedCountriesCount;
    NSString *pickerCountryName;
    NSString *pickerCountryCode;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.intralife = [[Intralife alloc] initIntralife];
    
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
    
    self.navigationController.navigationBar.hidden = NO;
    
    // set navigation controller title
    self.navigationItem.title = @"Search By Background";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    
    // save current tab in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"previousTab"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
            [label setText:@"• Choose your background from the country selector.\n• Press the + (plus) button to add another country.\n• Press the - (minus) button if you need to remove a country.\n• You can select 2-5 countries.\n• Each country must be different.\n• When you have selected your background, press the SEARCH button."];
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

- (IBAction)searchPressed:(id)sender
{
    // Check that at least 2 countries was selected
    if([selectedCountries count] < 2) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Error"
                                              message:@"Please select at least two different countries."
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
        // go to next screen
        [self performSegueWithIdentifier:@"SegueToMatchingProfiles" sender:self];
    }
}

- (void)addCountryForLabel:(UILabel *)countryLabel
{
    // if it's repeated country - do nothing
    NSString *countryname = pickerCountryCode;
    if([selectedCountries indexOfObject:countryname] != NSNotFound) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Error"
                                              message:@"All countries should be different."
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
                                              alertControllerWithTitle:@"Error"
                                              message:@"You can select no more than 5 countries."
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToMatchingProfiles"]) {
        MatchingProfilesViewController *matchingProfilesViewController = segue.destinationViewController;
        matchingProfilesViewController.selectedCountries = selectedCountries;
    }
}

@end
