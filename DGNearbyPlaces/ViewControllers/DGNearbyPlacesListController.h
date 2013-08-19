//
//  DGNearbyPlacesListController.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DGPlacesAPIJSONClient;

@interface DGNearbyPlacesListController : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView* nearbyPlacesTableView;
@property (nonatomic, strong) IBOutlet UIView* actionView;
@property (nonatomic, strong) IBOutlet UITextField* radiusTextField;

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) NSMutableArray* nearbyPlaces;
@property (nonatomic, strong) CLLocation* currentLocation;

@end
