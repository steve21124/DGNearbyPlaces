//
//  DGNearbyPlacesListController.m
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import "DGNearbyPlacesListController.h"
#import "DGPlacesAPIJSONClient.h"
#import <AFNetworking.h>
#import "DGPlace.h"
#import "NSIndexPath+Additions.h"

NSInteger const kDefaultSearchRadius = 500;
NSString* const kControllerTitle = @"Nearby Places";
NSInteger const kNumTableViewSections = 1;
NSInteger const kLastRowOfFirstPage = 19;
NSInteger const kLastRowOfSecondPage = 39;
NSInteger const kLastRowOfThirdPage = 59;
NSInteger const kNumberOfResultsPerPage = 20;
NSString* const kConnectionErrorTitle = @"Connection Error";
NSString* const kConnectionErrorFormat = @"There was a problem retrieving places data: Details: %@";
NSString* const kConnectionErrorButtonTitle = @"Dismiss";
NSInteger const kPhotoSizeMaxWidth = 100;
NSInteger const kPhotoSizeMaxHeight = 100;

@interface DGNearbyPlacesListController ()

@property (nonatomic, assign) NSInteger searchRadius;
@property (nonatomic, copy) NSString* nextPageToken;
@property (nonatomic, assign) BOOL locationFound;
@property (nonatomic, assign) BOOL firstPageLoaded;
@property (nonatomic, assign) BOOL secondPageLoaded;
@property (nonatomic, assign) BOOL thirdPageLoaded;

@end

@implementation DGNearbyPlacesListController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        self.searchRadius = kDefaultSearchRadius;
        self.locationFound = NO;
    }
    return self;
}

#pragma mark UIViewController lifecycle methods

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = kControllerTitle;
    
    [self.locationManager startUpdatingLocation];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumTableViewSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.nearbyPlaces count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    DGPlace* nearByPlace = [self.nearbyPlaces objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont fontWithName:@"System Bold" size:15.0];
    cell.textLabel.text = nearByPlace.name;
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.image = nearByPlace.image;
    
    if (!nearByPlace.imageLoaded)
    {
        // Async call for photo
        [[DGPlacesAPIJSONClient sharedClient] requestPhotoForPhotoRef:nearByPlace.photoRef maxHeight:100 maxWidth:100 success:^(UIImage *photo) {
            nearByPlace.image = photo;
            cell.imageView.image = photo;
            nearByPlace.imageLoaded = YES;
            [cell setNeedsDisplay];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            // We can handle this a few different ways based on the requirements. We could have an image for the failed image download state, or set it
            // so that this will only show one alert for the first time a photo connection error is encountered. We definitely don't want to spam the user
            // with errors for each failed photo download though. For now, let's consider the lack of any image other than the placeholder loading as a sign
            // that the photo couldn't be downloaded.
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // When reaching the last row of a 'page' & you haven't loaded the results for the next page yet, load next page results
    // Load page 2
    if (indexPath.row == kLastRowOfFirstPage && self.firstPageLoaded && !self.secondPageLoaded)
    {
        //Load the next 20 results
        if (self.nextPageToken)
        {
            [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:self.nextPageToken success:^(NSArray* places, NSString* nextPageToken) {
                [self.nearbyPlaces addObjectsFromArray:places];
                self.nextPageToken = nextPageToken;
                self.secondPageLoaded = YES;
                [self.nearbyPlacesTableView beginUpdates];
                [self.nearbyPlacesTableView insertRowsAtIndexPaths:[NSIndexPath indexPathsForSection:0 fromRow:kLastRowOfFirstPage+1 toRow:kLastRowOfSecondPage] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.nearbyPlacesTableView endUpdates];
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                [self handleError:error];
            }];
        }
    }
    // Load page 3
    if (indexPath.row == kLastRowOfSecondPage && self.secondPageLoaded && !self.thirdPageLoaded)
    {
        //Load the last 20 results
        if (self.nextPageToken)
        {
            [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:self.nextPageToken success:^(NSArray* places, NSString* nextPageToken) {
                [self.nearbyPlaces addObjectsFromArray:places];
                self.nextPageToken = nextPageToken;
                self.thirdPageLoaded = YES;
                [self.nearbyPlacesTableView beginUpdates];
                [self.nearbyPlacesTableView insertRowsAtIndexPaths:[NSIndexPath indexPathsForSection:0 fromRow:kLastRowOfSecondPage+1 toRow:kLastRowOfThirdPage] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.nearbyPlacesTableView endUpdates];
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                [self handleError:error];
            }];
        }
    }
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.currentLocation = newLocation;
    
    if (!self.locationFound)
    {
        // location found for the first time now, do initial places request
        [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:nil success:^(NSArray* places, NSString* nextPageToken) {
            self.nearbyPlaces = [NSMutableArray arrayWithArray:places];
            self.nextPageToken = nextPageToken;
            self.firstPageLoaded = YES;
            [self.nearbyPlacesTableView reloadData];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [self handleError:error];
        }];
    }
    
    self.locationFound = YES;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self handleError:error];
}

#pragma mark - UITextFieldDelegate methods
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.searchRadius = [textField.text intValue];
}

// Used to ensure touches outside textfield dismiss keyboard
- (void)hideKeyboard
{
    [self.radiusTextField resignFirstResponder];
}

#pragma mark - IBAction methods
- (IBAction)searchNearby:(id)sender
{
    [self.radiusTextField resignFirstResponder];
    
    self.firstPageLoaded = NO;
    self.secondPageLoaded = NO;
    self.thirdPageLoaded = NO;
    self.nearbyPlaces = nil;
    [self.nearbyPlacesTableView reloadData];
    
    [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:nil success:^(NSArray* places, NSString* nextPageToken) {
        self.nearbyPlaces = [NSMutableArray arrayWithArray:places];
        self.nextPageToken = nextPageToken;
        self.firstPageLoaded = YES;
        [self.nearbyPlacesTableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [self handleError:error];
    }];
}

#pragma mark - Error handling

- (void) handleError:(NSError*)error
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:kConnectionErrorTitle];
    [alert setMessage:[NSString stringWithFormat:kConnectionErrorFormat, [error localizedDescription]]];
    [alert setDelegate:self];
    [alert addButtonWithTitle:kConnectionErrorButtonTitle];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

@end