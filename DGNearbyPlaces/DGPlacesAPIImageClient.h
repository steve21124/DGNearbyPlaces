//
//  DGPlacesAPIImageClient.h
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/16/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFHTTPClient.h>
#import "DGPlacesAPIJSONClient.h"

@interface DGPlacesAPIImageClient : AFHTTPClient

+ (DGPlacesAPIImageClient *)sharedClient;

- (void)requestPhotoForPhotoRef:(NSString*)photoRef
                      maxHeight:(NSInteger)maxHeightPx
                       maxWidth:(NSInteger)maxWidthPx
                        success:(void (^)(UIImage* photo))success
                        failure:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error))failure;

@end
