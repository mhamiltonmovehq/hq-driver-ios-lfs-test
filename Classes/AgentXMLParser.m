//
//  AddressXMLParser.m
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AgentXMLParser.h"


@implementation AgentXMLParser

@synthesize nodeName, agent, parent, callback;

-(id)init
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
	}
	return self;
}

#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if([elementName isEqualToString:@"code"] || 
			[elementName isEqualToString:@"name"] || 
			[elementName isEqualToString:@"add1"] || 
			[elementName isEqualToString:@"add2"] || 
			[elementName isEqualToString:@"city"] || 
			[elementName isEqualToString:@"state"] || 
			[elementName isEqualToString:@"zip"] || 
			[elementName isEqualToString:@"phone"] || 
			[elementName isEqualToString:@"contact"])
	{
		//all root data
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	if([elementName isEqualToString:nodeName])
	{
		if([nodeName rangeOfString:@"orig"].location != NSNotFound)
			agent.agencyID = AGENT_ORIGIN;
		else if([nodeName rangeOfString:@"dest"].location != NSNotFound)
			agent.agencyID = AGENT_DESTINATION;
		else
			agent.agencyID = AGENT_BOOKING;
		
		//done, set back to parent
		if([parent respondsToSelector:callback])
			[parent performSelector:callback withObject:agent];
		
		[parser setDelegate:parent];
	}
	else if(storingData && [elementName isEqualToString:@"code"]){
		agent.code = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"name"]){
		agent.name = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"add1"]){
		agent.address = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"add2"]){
		agent.address = [agent.address stringByAppendingFormat:@" %@", currentString];
	}else if(storingData && [elementName isEqualToString:@"city"]){
		agent.city = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"state"]){
		agent.state = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"zip"]){
		agent.zip = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"phone"]){
		agent.phone = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"contact"]){
		agent.contact = [NSString stringWithString:currentString];
	}
	
	storingData = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
