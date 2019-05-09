//
//  PVOInventoryParser.m
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOTokenParser.h"
#import "SurveyAppDelegate.h"

@implementation PVOTokenParser

@synthesize token;

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
    if([elementName isEqualToString:@"GetUserTokenResult"])
	{
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
    if(storingData && [elementName isEqualToString:@"GetUserTokenResult"])
    {
        self.token = currentString;
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
