//
//  RestSyncRequest.h
//  Survey
//
//  Created by Bob Boatwright on 7/13/20.
//

#ifndef RestSyncRequest_h
#define RestSyncRequest_h


#endif /* RestSyncRequest_h */

@class RestSyncRequest;
@interface RestSyncRequest : NSObject<NSURLConnectionDataDelegate>{
    
}
@property (nonatomic, retain) NSString *scheme;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *basePath;
@property (nonatomic, retain) NSString *methodPath;

-(NSString*)executeHttpRequest:(NSString*)httpMethod withQueryParameters:(NSDictionary*) queryItems andBodyData:(NSData*) bodyData andError:(NSError**) error shouldDecode:(BOOL) shouldDecode;

@end
