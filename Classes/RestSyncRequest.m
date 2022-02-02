//
//  RestSyncRequest.m
//  Survey
//
//  Created by Bob Boatwright on 7/13/20.
//

#import <Foundation/Foundation.h>
#import "RestSyncRequest.h"
#import "Base64.h"
#import <HQ_Driver-Swift.h>

@implementation RestSyncRequest
@synthesize scheme, host, basePath, methodPath;

-(NSString*)executeHttpRequest:(NSString*) httpMethod withQueryParameters:(NSDictionary*) queryParams andBodyData:(NSData*) bodyData andError:(NSError**) error shouldDecode:(BOOL) shouldDecode {
    // verify token
    // if expired refresh
    // if unsuccesfeull refresh
    // kick back to creds screen
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];

//    TokenWrapper *tokenWrapper = [[TokenWrapper alloc] init];
//    tokenWrapper.caller = self;
//    
//    
//    
//    if(![tokenWrapper refreshTokenWithJwt:del.session._access_token] == [NonEmpty string]) {
//        if ([tokenWrapper verifyTokenWithJwt:del.session._access_token caller:self]) {
//        
//        }
//    }


    NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", scheme, host, basePath, methodPath];
    NSURL *url = [self url:urlString withQueryParameters:queryParams];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.timeoutInterval = 120.0;

    [request setHTTPMethod:httpMethod];
    [request setURL:url];
    [request setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self getUserAgentHeaderValue] forHTTPHeaderField:@"User-Agent"];
    if (bodyData != nil) {
        [request setHTTPBody:bodyData];
        
        NSLog(@"Request Body: %@", [NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding]]);
    }
    
    NSString *responseString = [self executeRequest:request withError:error shouldDecode:shouldDecode];
    NSLog(@"RequestResponse: %@", responseString);
    
    return responseString;
}

-(NSString*)executeRequest:(NSURLRequest*) request withError:(NSError**) error shouldDecode:(BOOL) shouldDecode {
    NSHTTPURLResponse *urlResponse = nil;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:error];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    
    if ([urlResponse statusCode] == 200) {
        if (shouldDecode) {
            return [[NSString alloc] initWithData:[Base64 decode64:responseString] encoding:NSUTF8StringEncoding];
        }
        return responseString;
    } else {
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:error];
        
        *error = [[NSError alloc] initWithDomain:@"MobileMover" code:[urlResponse statusCode] userInfo:@{@"Error": [jsonDict valueForKey:@"ExceptionMessage"]}];
        return nil;
    }
}

-(NSURL*)url:(NSString*)url withQueryParameters:(NSDictionary<NSString*, NSString*>*) queryDictionary {
    NSMutableArray<NSURLQueryItem*> *queryParams = [NSMutableArray array];
    for (NSString *key in queryDictionary) {
        NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:queryDictionary[key]];
        [queryParams addObject:queryItem];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:url] resolvingAgainstBaseURL:NO];
    if ([queryParams count] > 0) {
        components.queryItems = [queryParams copy];
    }
    
    return components.URL;
}

-(NSString*)getUserAgentHeaderValue {
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *buildNumber = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    return [NSString stringWithFormat:@"%@/%@ build %@ (%@ %@) %@", @"HQ Driver", appVersion, buildNumber, currentDevice.systemName, currentDevice.systemVersion, currentDevice.model];
}
@end
