//
//  NSIndexPath+Additions.m
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/19/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import "NSIndexPath+Additions.h"

@implementation NSIndexPath (Additions)

+ (NSArray*)indexPathsForSection:(NSInteger)section fromRow:(NSInteger)startingRow toRow:(NSInteger)endRow
{
    NSMutableArray* indexPaths = [NSMutableArray array];
    
    for (int i = startingRow; i <= endRow; i++)
    {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    
    return indexPaths;
}

@end
