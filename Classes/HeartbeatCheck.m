//
//  PVOSync.m
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//#import <AdSupport/ASIdentifierManager.h>
#import "HeartbeatCheck.h"
#import "WebSyncRequest.h"
#import "Prefs.h"
#import "XMLWriter.h"
#import "Base64.h"
#import "SurveyDownloadXMLParser.h"
#import "SurveyAppDelegate.h"
#import "CancelledSurveyParser.h"
#import "CustomerListItem.h"
#import "RoomSummary.h"
#import "SuccessParser.h"
#import "SurveyImage.h"
#import "SyncGlobals.h"
#import "LoadCustomItemLists.h"
#import "GetReport.h"
#import "PVOImageParser.h"
#import "PVOInventoryParser.h"
#import "PVOTokenParser.h"
#import "OpenUDID.h"

@implementation HeartbeatCheck

@synthesize updateCallback, updateWindow, completedCallback, errorCallback;

-(id)init
{
    self = [super init];
    if(self)
    {
        req = [[WebSyncRequest alloc] init];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        switch ([del.pricingDB vanline]) {
            default:
                req.serverAddress = @"print.moverdocs.com";
                req.port = 80;
                req.type = HEARTBEAT;
                break;
        }
        
//        if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"add:"].location != NSNotFound)
//        {
//            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"add:"];
//            req.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
//        }
    }
    return self;
}



-(void)main
{
    BOOL success = YES;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try 
    {
        
        success = [self checkActivation];
    
    }
    @catch (NSException * e) {
        
        success = FALSE;
        [self updateProgress:[NSString stringWithFormat:@"Exception on Download Thread: %@", [e description]]];
        
    }

exit:
    
    //[pool drain];
    
    if(success)
        [self completed];
    else
        [self error];

}

-(void)completed
{
    if([updateWindow respondsToSelector:completedCallback])
    {
        [updateWindow performSelectorOnMainThread:completedCallback withObject:nil waitUntilDone:NO];
    }
}

-(void)error
{
    if([updateWindow respondsToSelector:errorCallback])
    {
        [updateWindow performSelectorOnMainThread:errorCallback withObject:nil waitUntilDone:NO];
    }
}

-(void)updateProgress:(NSString*)updateString
{
    if(updateString == nil || [updateString length] == 0)
        return;
    
    if([updateWindow respondsToSelector:updateCallback])
    {
        [updateWindow performSelectorOnMainThread:updateCallback withObject:updateString waitUntilDone:NO];
    }
}

-(BOOL)checkActivation
{
    BOOL success = TRUE;
    NSString *result = nil;
    
    NSDictionary *temp = nil; 
    
    
    req.functionName = @"CheckActivation";
    
    NSString *deviceID = nil;
//    if ([[ASIdentifierManager sharedManager] respondsToSelector:@selector(advertisingIdentifier)])
//        deviceID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
//    else
        deviceID = [OpenUDID value];
    
    temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[Prefs username],
                                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                                [NSString stringWithFormat:@"iOS %@", @"Mobile Mover"],
                                                deviceID, nil]
                                       forKeys:[NSArray arrayWithObjects:@"username", @"softwareVersion", @"appName", @"deviceID", nil]];
    
    success = [req getData:&result withArguments:temp needsDecoded:NO withSSL:NO flushToFile:nil
                 withOrder:[NSArray arrayWithObjects:@"username", @"softwareVersion", @"appName", @"deviceID", nil]];
    
    if(success)
    {
        success = [result rangeOfString:@"true"].location != NSNotFound;
    }
    
//    [result release];
    
    return success;
}

@end
