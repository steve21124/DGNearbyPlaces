//
//  DGPlacesAPIImageClient.m
//  DGNearbyPlaces
//
//  Created by Donald Gaxho on 8/16/13.
//  Copyright (c) 2013 dg. All rights reserved.
//

#import "DGPlacesAPIImageClient.h"
#import <AFImageRequestOperation.h>

@implementation DGPlacesAPIImageClient

- (id) initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        [self registerHTTPOperationClass:[AFImageRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"image/jpg,image/png,image/gif"];
        self.parameterEncoding = AFJSONParameterEncoding;
    }
    return self;
}

+ (DGPlacesAPIImageClient *)sharedClient
{
    static DGPlacesAPIImageClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kPlacesBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)requestPhotoForPhotoRef:(NSString*)photoRef
                      maxHeight:(NSInteger)maxHeightPx
                       maxWidth:(NSInteger)maxWidthPx
                        success:(void (^)(UIImage* photo))success
                        failure:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"photo?maxwidth=%d&maxheight=%d&photoreference=%@&sensor=true&key=%@", maxWidthPx, maxHeightPx, photoRef, kPlacesAPIKey];
    
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
