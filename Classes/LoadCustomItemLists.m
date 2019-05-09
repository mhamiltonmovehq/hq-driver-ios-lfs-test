//
//  LoadCustomItemLists.m
//  Survey
//
//  Created by Tony Brame on 3/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoadCustomItemLists.h"
#import "Prefs.h"

#import "CustomItemListParser.h"

@implementation LoadCustomItemLists

@synthesize caller;


-(BOOL)runItemListsSync
{
    BOOL success = FALSE;
    
    req = [[WebSyncRequest alloc] init];
    req.serverAddress = ITEM_LISTS_WCF_ADDRESS;
    req.port = 80;
    req.username = [Prefs username];
    req.type = CUSTOM_ITEM_LISTS;
    
    
    //get item lists for user...
    
    [caller updateProgress:[NSString stringWithFormat:@"Syncing Custom Item Lists for %@...", [Prefs username]]];
    
    success = [self downloadItemLists];
    if(!success)
        goto exit;    
    if([caller isCancelled])
        return NO;
    [caller updateProgress:@"Finished Item Lists Download..."];
    
    
    success = TRUE;
    
exit:
    
    return success;
}

-(BOOL)downloadItemLists
{
    BOOL success = FALSE;
    
    req.functionName = @"GetItemListsForUser";
    NSString *result;
    success = [req getData:&result 
             withArguments:[NSDictionary dictionaryWithObject:req.username forKey:@"username"] 
              needsDecoded:NO];
    
    if(!success)
    {
        [caller updateProgress:result];
//        [result release];
        return success;
    }
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    
    CustomItemListParser *xmlParser = [[CustomItemListParser alloc] init];
    
    parser.delegate = xmlParser;
    [parser parse];
    
//    [result release];
    
    return success;    
}

@end
