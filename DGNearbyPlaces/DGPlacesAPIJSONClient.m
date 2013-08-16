//
//  DGPlacesAPIClient.m
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/15/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import "DGPlacesAPIJSONClient.h"
#import <AFJSONRequestOperation.h>
#import <AFImageRequestOperation.h>
#import "DGPlace.h"
#import "DGPlacesAPIImageClient.h"

NSString* const kPlacesAPIKey = @"AIzaSyAgkxr8L20pp3DP24DH8kZQdE1BVjKkrPs";
NSString* const kPlacesBaseURLString = @"https://maps.googleapis.com/maps/api/place/";

@implementation DGPlacesAPIJSONClient

- (id) initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        self.parameterEncoding = AFJSONParameterEncoding;
    }
    return self;
}

+ (DGPlacesAPIJSONClient *)sharedClient
{
    static DGPlacesAPIJSONClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kPlacesBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)requestPlacesNear:(CLLocation*)location
               withRadius:(NSInteger)radiusInMeters
                pageToken:(NSString*)pageToken
                  success:(void (^)(NSArray* places, NSString* nextPageToken))success
                  failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure;
{
    NSString* path = [NSString stringWithFormat:@"nearbysearch/json?key=%@&location=%f,%f&radius=%d&sensor=true", kPlacesAPIKey, location.coordinate.latitude, location.coordinate.longitude, radiusInMeters];
    
    if (pageToken)
    {
        path = [path stringByAppendingFormat:@"&pagetoken=%@", pageToken];
    }
    
    NSURLRequest* request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse*response, id JSON) {
        NSMutableArray* places = [NSMutableArray array];
        
        NSString* status = [JSON valueForKeyPath:@"status"];
        
        if (status && [status isEqualToString:@"OVER_QUERY_LIMIT"])
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Exceeded Google Places API Limit for today." forKey:NSLocalizedDescriptionKey];
            
            if (failure)
            {
                return failure(request,response,[NSError errorWithDomain:@"dg" code:100 userInfo:errorDetail],JSON);
            }
        }
        
        NSString* nextPageToken = [JSON valueForKeyPath:@"next_page_token"];
        
        for (NSDictionary* result in [JSON valueForKeyPath:@"results"])
        {
            NSString* name = [result valueForKeyPath:@"name"];
            if (name)
            {
                DGPlace* place = [[DGPlace alloc] init];
                place.name = name;
                // set default image
                place.image = [UIImage imageNamed:@"geocode-71"];
                
                NSArray* photos = [result valueForKeyPath:@"photos"];
                
                if (photos)
                {
                    NSDictionary* photo = [photos objectAtIndex:0];
                    NSString* photoReference = [photo valueForKeyPath:@"photo_reference"];
                    
                    [[DGPlacesAPIImageClient sharedClient] requestPhotoForPhotoRef:photoReference maxHeight:100 maxWidth:100 success:^(UIImage *photo) {
                        place.image = photo;
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        if (failure)
                        {
                            failure(request,response,error,JSON);
                        }
                    }];
                }
                [places addObject:place];
            }
        }
        
        if (success)
        {
            success(places,nextPageToken);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failure: %@", [error localizedDescription]);
        if (failure)
        {
            failure(request,response,error,JSON);
        }
    }];
    
    [operation start];
}

@end
