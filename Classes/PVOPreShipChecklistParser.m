//
//  PVOPreShipChecklistParser.m
//  Survey
//
//  Created by Justin Little on 11/2/2015
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOPreShipChecklistParser.h"
#import "SurveyAppDelegate.h"

@implementation PVOPreShipChecklistParser

@synthesize checkListItems; //, currentItem;

-(id)init
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
        checkListItems = [[NSMutableArray alloc] init];
	}
	return self;
}


#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if([elementName isEqualToString:@"checklist_item"])
	{
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	NSString *temp = [[NSString alloc] initWithString:currentString];
    if(storingData && [elementName isEqualToString:@"checklist_item"])
    {
//        self.currentItem = currentString;
        [checkListItems addObject:temp];
	}
		
	storingData = NO;
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if(storingData)
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
