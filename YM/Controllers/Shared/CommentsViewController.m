//
//  CommentsViewController.m
//  YM
//
//  Created by user on 03/11/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "CommentsViewController.h"
#import "Intralife.h"
#import "AppManager.h"
#import "Reachability.h"

#pragma mark - OldCommentCell

@interface OldCommentCell ()

@property (weak, nonatomic) IBOutlet UILabel *oldCommentLabel;
@property (weak, nonatomic) IBOutlet UILabel *oldCommentUsernameLabel;

@end

@implementation OldCommentCell

@end

@interface CommentsViewController () <IntralifeDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *commentsTable;
@property (weak, nonatomic) IBOutlet UITextField *myComment;

@property (strong, nonatomic) Intralife *intralife;
@property (strong, nonatomic) IntralifeUser *user;
@property (strong, nonatomic) NSMutableArray *photos;
@property (nonatomic) BOOL photosLoaded;

@end

@implementation CommentsViewController
{
    NSMutableArray *commentsText;
    NSMutableArray *commentsUsername;
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

    self.commentsTable.rowHeight = UITableViewAutomaticDimension;
    self.commentsTable.estimatedRowHeight = 44.0;
    
    self.intralife = [[Intralife alloc] initIntralife];
    self.intralife.delegate = self;
    
    self.photos = [[NSMutableArray alloc] init];
    
    // keyboard stuff
    self.myComment.delegate = self;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.photosLoaded = NO;
    
    if(self.userAndFollowingPhotos) { // used only for the first tab
        [self.intralife observeUserAndFollowingPhotos];
    }
    else {
        [self.intralife observePhotosForUserWithId:self.commentPhotoData.authorId];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // set navigation controller title";
    self.navigationItem.title = @"Comments";
    
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
    
    [self.intralife cleanup];
}

#pragma mark - <IntralifeDelegate>

- (void)photo:(IntralifePhoto *)photo wasAddedToTimeline:(NSString *)timeline
{
    [self.photos addObject:photo];

    // see if photo added is photo which we want to comment and if it is, reload commentsTable
    if([photo.photoId isEqualToString:self.commentPhotoData.photoId]) {
        NSArray *commentsData = [photo.comments allValues];
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        NSArray *commentsDataSorted = [commentsData sortedArrayUsingDescriptors:@[timestampDescriptor]];
        commentsText = [[NSMutableArray alloc] init];
        commentsUsername = [[NSMutableArray alloc] init];
        for(int i = 0; i < [commentsDataSorted count]; i++) {
            NSDictionary *commentData = [commentsDataSorted objectAtIndex:i];
            NSString *commentText = [commentData valueForKey:@"text"];
            [commentsText addObject:commentText];
            NSString *commentUsername = [commentData valueForKey:@"username"];
            [commentsUsername addObject:commentUsername];
        }

        [self.commentsTable reloadData];
    }
}

- (void)photo:(IntralifePhoto *)photo wasRemovedFromTimeline:(NSString *)timeline
{
    // some other photo was deleted
    if(![photo.photoId isEqualToString:self.commentPhotoData.photoId]) return;
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Oops!"
                                          message:@"This photo was deleted."
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   [self.navigationController popViewControllerAnimated:NO];
                               }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)photo:(IntralifePhoto *)photo wasUpdatedInTimeline:(NSString *)timeline
{
    // see if photo updated is photo which we want to comment and if it is, reload commentsTable
    if([photo.photoId isEqualToString:self.commentPhotoData.photoId]) {
        NSArray *commentsData = [photo.comments allValues];
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        NSArray *commentsDataSorted = [commentsData sortedArrayUsingDescriptors:@[timestampDescriptor]];
        commentsText = [[NSMutableArray alloc] init];
        commentsUsername = [[NSMutableArray alloc] init];
        for(int i = 0; i < [commentsDataSorted count]; i++) {
            NSDictionary *commentData = [commentsDataSorted objectAtIndex:i];
            NSString *commentText = [commentData valueForKey:@"text"];
            [commentsText addObject:commentText];
            NSString *commentUsername = [commentData valueForKey:@"username"];
            [commentsUsername addObject:commentUsername];
        }

        [self.commentsTable reloadData];
    }
}

- (void)photo:(NSDictionary *)photo wasOverflowedFromTimeline:(NSString *)timeline
{
    
}

- (void)timelineDidLoad:(NSString *)feedId
{
    self.photosLoaded = YES;
}

- (void)userDidUpdate:(IntralifeUser *)user
{
    
}

#pragma mark - <UITextFieldDelegate>

- (void)didTapAnywhere:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

- (double)currentTimestamp
{
    // Incorporate the timestamp from Firebase to get a good estimate of the time
    return ([[NSDate date] timeIntervalSince1970] * 1000.0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(![self isInternetConnection]) {
        [self.myComment resignFirstResponder];
        return YES;
    }

    if (self.myComment.text.length == 0) {
        return YES;
    }
    
    [self.myComment resignFirstResponder];
    
    // update Firebase
    NSString *photoId = self.commentPhotoData.photoId;
    FIRDatabaseReference *commentsRef = [[[self.intralife.root child:@"photos"] child:photoId] child:@"comments"];
    FIRDatabaseReference *commentRef = [commentsRef childByAutoId];
    NSString *text = self.myComment.text;
    NSString *username = [AppManager sharedAppManager].loggedInUser.username;
    NSNumber* ts = [NSNumber numberWithDouble:[self currentTimestamp]];
    NSDictionary *commentData = @{
                                  @"text": text,
                                  @"username": username,
                                  @"timestamp": ts
                                  };
    [commentRef updateChildValues:commentData withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        if (error) {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:@"Error occured while posting."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self.navigationController popViewControllerAnimated:NO];
                                       }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            NSLog(@"Comment data saved successfully.");
            
            [self.navigationController popViewControllerAnimated:YES];
            
            [self.intralife cleanup];
        }
    }];
    
    // empty text field
    [self.myComment setText:@""];
    
    return YES;
}

#pragma mark - <UITableViewDatasource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [commentsText count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CommentCellIdentifier = @"OldCommentCell";
    OldCommentCell *oldCommentCell = (OldCommentCell *)[tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier];
    oldCommentCell.oldCommentLabel.text = [commentsText objectAtIndex:indexPath.row];
    oldCommentCell.oldCommentUsernameLabel.text = [commentsUsername objectAtIndex:indexPath.row];
    
    return oldCommentCell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

@end
