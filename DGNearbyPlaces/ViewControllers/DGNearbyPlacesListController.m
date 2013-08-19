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

#define kEndOfFirstPage 20;
#define kEndOfSecondPage 40;

NSInteger const kDefaultSearchRadius = 500;
NSString* const kControllerTitle = @"Nearby Places";
NSInteger const kNumTableViewSections = 1;
NSInteger const kLastRowOfFirstPage = 19;
NSInteger const kLastRowOfSecondPage = 39;
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
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // When reaching the last row of a 'page' & you haven't loaded the results for the next page yet, load next page results
    // Load page 2
    if (indexPath.row == kLastRowOfFirstPage && [self.nearbyPlaces count] == kNumberOfResultsPerPage)
    {
        //Load the next 20 results
        if (self.nextPageToken)
        {
            [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:self.nextPageToken success:^(NSArray* places, NSString* nextPageToken) {
                [self.nearbyPlaces addObjectsFromArray:places];
                self.nextPageToken = nextPageToken;
                [self.nearbyPlacesTableView reloadData];
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                [self handleError:error];
            }];
        }
    }
    // Load page 3
    if (indexPath.row == kLastRowOfSecondPage && [self.nearbyPlaces count] == 2*kNumberOfResultsPerPage)
    {
        //Load the last 20 results
        if (self.nextPageToken)
        {
            [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:self.nextPageToken success:^(NSArray* places, NSString* nextPageToken) {
                [self.nearbyPlaces addObjectsFromArray:places];
                self.nextPageToken = nextPageToken;
                [self.nearbyPlacesTableView reloadData];
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
    
    self.nearbyPlaces = nil;
    [self.nearbyPlacesTableView reloadData];
    
    // Scroll to top to ensure there's no interference with 2nd & 3rd page loading behavior
    //    [self.nearbyPlacesTableView reloadData];
    //    [self.nearbyPlacesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:nil success:^(NSArray* places, NSString* nextPageToken) {
        self.nearbyPlaces = [NSMutableArray arrayWithArray:places];
        self.nextPageToken = nextPageToken;
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