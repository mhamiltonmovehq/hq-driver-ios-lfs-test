//
//  CancelledSurveyParser.m
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CancelledSurveyParser.h"


@implementation CancelledSurveyParser

@synthesize ids, currentString;

-(id)init
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
		ids = [[NSMutableArray alloc] init];
	}
	return self;
}


#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if([elementName isEqualToString:@"cancelled_survey"])
	{
		//all root data
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	if(storingData && [elementName isEqualToString:@"cancelled_survey"])
	{
		[ids addObject:currentString];
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
