//
//  DGPlace.m
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import "DGPlace.h"

@implementation DGPlace

- (NSString*)description
{
    return [NSString stringWithFormat:@"Place, name: %@, image: %@", self.name, self.image];
}

@end
