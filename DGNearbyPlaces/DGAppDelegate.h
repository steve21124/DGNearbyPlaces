//
//  DGAppDelegate.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DGNearbyPlacesListController;

@interface DGAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DGNearbyPlacesListController *nearbyPlacesController;

@property (strong, nonatomic) UINavigationController* navController;

@end
