//
//  ProcessSync.m
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ProcessSync.h"
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

@implementation ProcessSync

@synthesize updateCallback, updateWindow, completedCallback, errorCallback, downloadCustomItemLists;


-(void)main
{
    BOOL success;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try 
    {
        if(downloadCustomItemLists)
        {
            LoadCustomItemLists *itemLists = [[LoadCustomItemLists alloc] init];
            itemLists.caller = self;
            success = [itemLists runItemListsSync];
            if(!success)
                goto exit;
        }
    
    }
    @catch (NSException * e) {
        
        success = FALSE;
        [self updateProgress:[NSString stringWithFormat:@"Exception on Sync Thread: %@", [e description]]];
        
    }
    
    
    
    

exit:
    
    //
    
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

@end
