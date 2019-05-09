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

@implementation ProcessSync

@synthesize updateCallback, updateWindow, completedCallback, errorCallback;

-(void)main
{
	BOOL success;
	req = [[WebSyncRequest alloc] init];
	req.serverAddress = [Prefs address];
	req.port = 80;
	req.functionName = @"ValidateCredentials";
	req.username = [Prefs username];
	
	success = [self validateUserPass];
	if(!success)
		goto exit;	
	if([self isCancelled])
		return;
	[self updateProgress:@"User Credentials Passed..."];
	
	
	
	
	
	
	
	
	

exit:
	
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
	if([updateWindow respondsToSelector:updateCallback])
	{
		[updateWindow performSelectorOnMainThread:updateCallback withObject:updateString waitUntilDone:NO];
	}
}

#pragma mark Sync Processing

-(BOOL)validateUserPass
{
	NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[Prefs username],[Prefs password],nil] 
													 forKeys:[NSArray arrayWithObjects:@"username",@"password",nil]];
	
	NSString *result;
	BOOL success = [req getData:&result withArguments:args needsDecoded:FALSE];
	
	if([result compare:@"Credentials validated"] != NSOrderedSame)
	{
		success = FALSE;
		[self updateProgress:result];
	}
	
	[result release];
	
	return success;
}

-(XMLWriter*)buildIgnoreXML:(NSArray*)ids
{
	XMLWriter *xml = [[XMLWriter alloc] init];
	
	[xml writeStartDocument];
	[xml writeStartElement:@"AtlasSync"];
	
	for(int i = 0; i < [ids count]; i++)
	{
		[xml writeElementString:@"skip_survey" withData:[ids objectAtIndex:i]];
	}
	
	[xml writeEndDocument];
	
	return xml;
}

-(BOOL)downloadSurveys
{
	NSMutableArray *ids = [[NSMutableArray alloc] init];
	XMLWriter *xml = [self buildIgnoreXML:ids];
	
	
	
	[xml release];
	[ids release];
}



@end
