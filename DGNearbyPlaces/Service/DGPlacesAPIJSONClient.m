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

//Note: Ideally in production this key would be served by one of our own servers rather than stored in the app binary.
NSString* const kPlacesAPIKey = @"AIzaSyAPWQ0TpfcQrjiUIcoD2tMgM1Mh7HKhwpc"; 
NSString* const kPlacesBaseURLString = @"https://maps.googleapis.com/maps/api/place/";
NSString* const kRequestPlacesNearPathFormat = @"nearbysearch/json?key=%@&location=%f,%f&radius=%d&sensor=true";
NSString* const kRequestPhotoForPhotoRefPathFormat = @"photo?maxwidth=%d&maxheight=%d&photoreference=%@&sensor=true&key=%@";
//Note: In API docs this is incorrectly referenced as 'page_token'
NSString* const kPageTokenPathFormat = @"&pagetoken=%@";
NSString* const kStatusKey = @"status";
NSString* const kStatusOverQueryLimit = @"OVER_QUERY_LIMIT";
NSString* const kStatusOverQueryLimitErrorDesc = @"Exceeded Google Places API Limit for today.";
NSString* const kStatusOverQueryLimitErrorDomain = @"dg";
NSInteger const kStatusOverQueryLimitErrorCode = 100;
NSString* const kNextPageTokenKey = @"next_page_token";
NSString* const kResultsKey = @"results";
NSString* const kPlaceNameKey = @"name";
NSString* const kDefaultPlacePhotoImgName = @"default_place_photo";
NSString* const kPhotosKey = @"photos";
NSString* const kPhotoReferenceKey = @"photo_reference";

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
    NSString* path = [NSString stringWithFormat:kRequestPlacesNearPathFormat, kPlacesAPIKey, location.coordinate.latitude, location.coordinate.longitude, radiusInMeters];
    
    if (pageToken)
    {
        path = [path stringByAppendingFormat:kPageTokenPathFormat, pageToken];
    }
    
    NSURLRequest* request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse*response, id JSON) {
        NSMutableArray* places = [NSMutableArray array];
        
        NSString* status = [JSON valueForKeyPath:kStatusKey];
        
        if (status && [status isEqualToString:kStatusOverQueryLimit])
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:kStatusOverQueryLimitErrorDesc forKey:NSLocalizedDescriptionKey];
            
            if (failure)
            {
                return failure(request,response,[NSError errorWithDomain:kStatusOverQueryLimitErrorDomain code:kStatusOverQueryLimitErrorCode userInfo:errorDetail],JSON);
            }
        }
        
        NSString* nextPageToken = [JSON valueForKeyPath:kNextPageTokenKey];
        
        for (NSDictionary* result in [JSON valueForKeyPath:kResultsKey])
        {
            NSString* name = [result valueForKeyPath:kPlaceNameKey];
            if (name)
            {
                DGPlace* place = [[DGPlace alloc] init];
                place.name = name;
                // set default image
                place.image = [UIImage imageNamed:kDefaultPlacePhotoImgName];
                
                NSArray* photos = [result valueForKeyPath:kPhotosKey];
                
                if (photos)
                {
                    NSDictionary* photo = [photos objectAtIndex:0];
                    NSString* photoReference = [photo valueForKeyPath:kPhotoReferenceKey];
                    place.photoRef = photoReference;
                    place.imageLoaded = NO;
                }
                else
                {
                    place.imageLoaded = YES; // if this place has no photos, then it will show the default image, which is already loaded
                }
                [places addObject:place];
            }
        }
        
        if (success)
        {
            success(places,nextPageToken);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure)
        {
            failure(request,response,error,JSON);
        }
    }];
    
    [operation start];
    
}

- (void)requestPhotoForPhotoRef:(NSString*)photoRef
                      maxHeight:(NSInteger)maxHeightPx
                       maxWidth:(NSInteger)maxWidthPx
                        success:(void (^)(UIImage* photo))success
                        failure:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error))failure
{
    NSString* path = [NSString stringWithFormat:kRequestPhotoForPhotoRefPathFormat, maxWidthPx, maxHeightPx, photoRef, kPlacesAPIKey];
    
    NSURLRequest* request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (success)
        {
            return success(image);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        if (failure)
        {
            return failure(request, response, error);
        }
    }];
    
    [operation start];
}

@end
