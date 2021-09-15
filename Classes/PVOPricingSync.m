//
//  PVOPricingSync.m
//  HQ Driver
//
//  Created by Bob Boatwright on 8/11/21.
//

#import <Foundation/Foundation.h>
#import "PVOPricingSync.h"
#import "RestSyncRequest.h"
#import "PVOSync.h"

@implementation PVOPricingSync

+(NSString*)getPVODatabaseVersion: (NSError**) error
{
    RestSyncRequest* restRequest = [PVOPricingSync getRestSyncRequest];
    restRequest.methodPath = PVO_CONTROL_VERSION;
    
    return [restRequest executeHttpRequest:@"GET" withQueryParameters:nil andBodyData:nil andError:error shouldDecode:NO];
}

+(NSString*)getPVODatabaseData: (NSError**) error
{
    RestSyncRequest* restRequest = [PVOPricingSync getRestSyncRequest];
    restRequest.methodPath = PVO_CONTROL_DATA;
    
    return [restRequest executeHttpRequest:@"GET" withQueryParameters:nil andBodyData:nil andError:error shouldDecode:YES];
}

+(RestSyncRequest*) getRestSyncRequest {
    RestSyncRequest *restRequest = [[RestSyncRequest alloc] init];
    restRequest.scheme = SCHEME;
    restRequest.host = [PVOSync getRestHost];
    restRequest.basePath = AICLOUD_PATH;
    
    return restRequest;
}
@end
