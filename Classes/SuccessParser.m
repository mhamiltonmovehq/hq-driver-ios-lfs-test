//
//  SuccessParser.m
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SuccessParser.h"


@implementation SuccessParser

@synthesize errorString, success, currentString, surveyID;

-(id)init
{
    if( self = [super init] )
    {
        currentString = [[NSMutableString alloc] init];
    }
    return self;
}



#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
    if([elementName isEqualToString:@"success"] ||
       [elementName isEqualToString:@"error"] ||
       [elementName isEqualToString:@"survey_id"])
    {
        //all root data
        storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if(storingData && [elementName isEqualToString:@"success"])
    {
        self.success = [currentString isEqualToString:@"true"];
    }
    else if(storingData && [elementName isEqualToString:@"error"])
    {
        self.errorString = currentString;
    }
    else if(storingData && [elementName isEqualToString:@"survey_id"])
    {
        self.surveyID = [currentString intValue];
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
