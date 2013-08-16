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

@interface DGNearbyPlacesListController ()

@property (nonatomic, assign) NSInteger searchRadius;
@property (nonatomic, copy) NSString* nextPageToken;

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
        self.locationFound = NO;
        self.searchRadius = 500;
    }
    return self;
}

#pragma mark UIViewController lifecycle methods

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Nearby Places";
    
    [self.locationManager startUpdatingLocation];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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
    cell.textLabel.textAlignment=UITextAlignmentCenter;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.image = nearByPlace.image;
        
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Load page 2
    if (indexPath.row == 19 && [self.nearbyPlaces count] == 20)
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
    if (indexPath.row == 39 && [self.nearbyPlaces count] == 40)
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
    if (!self.locationFound)
    {
        self.currentLocation = newLocation;
        
        [[DGPlacesAPIJSONClient sharedClient] requestPlacesNear:self.currentLocation withRadius:self.searchRadius pageToken:nil success:^(NSArray* places, NSString* nextPageToken) {
            self.nearbyPlaces = [NSMutableArray arrayWithArray:places];
            self.nextPageToken = nextPageToken;
            [self.nearbyPlacesTableView reloadData];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [self handleError:error];
        }];
        self.locationFound = YES;
    }
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
    self.locationFound = NO;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Error handling

- (void) handleError:(NSError*)error
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:@"Connection Error"];
    [alert setMessage:[NSString stringWithFormat:@"There was a problem retrieving places data: Details: %@", [error localizedDescription]]];
    [alert setDelegate:self];
    [alert addButtonWithTitle:@"Dismiss"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

@end