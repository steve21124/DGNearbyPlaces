//
//  DGPlace.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DGPlace : NSObject

@property (nonatomic, copy) NSString* name;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, copy) NSString* photoRef;
@property (nonatomic, assign) BOOL imageLoaded;

@end
