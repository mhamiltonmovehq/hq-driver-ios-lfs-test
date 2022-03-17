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

@interface RestSyncRequest() <TokenResponseProtocol, HubActivationResponseProtocol>
@end

@implementation RestSyncRequest
@synthesize scheme, host, basePath, methodPath;

-(NSString*)executeHttpRequest:(NSString*) httpMethod withQueryParameters:(NSDictionary*) queryParams andBodyData:(NSData*) bodyData andError:(NSError**) error shouldDecode:(BOOL) shouldDecode {
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSDate *now  = [NSDate date];
    if ([SurveyAppDelegate hasInternetConnection] || ([now timeIntervalSince1970] - del.tokenAcquiredTimeIntervalSince1970) > (double)del.session._expires_in) {
        TokenWrapper *tokenWrapper = [[TokenWrapper alloc] init];
        [tokenWrapper verifyTokenWithJwt:del.session._access_token caller:self];
    }
    
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

-(void)verifyTokenResponseCompletedWithResult:(TokenResponseWrapperResult * _Nonnull) result {
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    BOOL resultSuccess  = (BOOL)result.success;
    
    if (resultSuccess == NO) {
        TokenWrapper *tokenWrapper = [[TokenWrapper alloc] init];
        tokenWrapper.caller = self;
        if ([result.errorMessage containsString:@"blacklisted"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [del logoutAndShowActivationError:@"Access to the application has been revoked, please contact support" fromCurrentView:del.currentView];
            });
        }
        else {
            [tokenWrapper refreshTokenWithJwt:del.session._access_token];
        }
    }
}

-(void)refreshTokenResponseCompletedWithResult:(TokenResponseWrapperResult * _Nonnull)result {
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (result.success == NO) {
        if (![result.errorMessage containsString:@"blacklisted"]) {
            HubActivationWrapper *hubWrapper = [[HubActivationWrapper alloc] init];
            [hubWrapper activateWithCaller:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [del logoutAndShowActivationError:@"Access to the application has been revoked, please contact support"  fromCurrentView:del.currentView];
            });
            NSLog(@"refresh token error %@", result.errorMessage);
        }
    }
}

- (void)hubActivationCompletedWithResult:(HubActivationWrapperResult * _Nonnull) result {
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];

    ActivationRecord *rec = [del.surveyDB getActivation];
    
    if (result.success) {
        rec.unlocked = 1;
        rec.lastOpen = rec.lastValidation = [NSDate date];
        rec.fileAssociationId = result.hubResult.carrierId;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [del.surveyDB updateActivation:rec];
        });
    } else {
        rec.unlocked = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            [del logoutAndShowActivationError:result.errorMessage fromCurrentView:del.currentView];
        });
        NSLog(@"Activation error %@", result.errorMessage);
    }
}

@end
