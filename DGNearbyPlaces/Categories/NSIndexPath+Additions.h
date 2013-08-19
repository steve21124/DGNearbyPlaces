//
//  NSIndexPath+Additions.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/19/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath (Additions)

+ (NSArray*)indexPathsForSection:(NSInteger)section fromRow:(NSInteger)startingRow toRow:(NSInteger)endRow;

@end
