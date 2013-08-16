//
//  DGPlacesAPIClient.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFHTTPClient.h>

@interface DGPlacesAPIJSONClient : AFHTTPClient

extern NSString* const kPlacesAPIKey;
extern NSString* const kPlacesBaseURLString;

+ (DGPlacesAPIJSONClient *)sharedClient;

- (void)requestPlacesNear:(CLLocation*)location
               withRadius:(NSInteger)radiusInMeters
                pageToken:(NSString*)pageToken
                  success:(void (^)(NSArray* places, NSString* nextPageToken))success
                  failure:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error, id JSON))failure;

@end
