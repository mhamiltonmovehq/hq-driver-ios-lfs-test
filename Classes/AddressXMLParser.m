//
//  AddressXMLParser.m
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AddressXMLParser.h"


@implementation AddressXMLParser

@synthesize nodeName, location, parent, callback;

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
    if([elementName isEqualToString:@"add1"] ||
       [elementName isEqualToString:@"add2"] ||
       [elementName isEqualToString:@"city"] ||
       [elementName isEqualToString:@"state"] ||
       [elementName isEqualToString:@"county"] ||
       [elementName isEqualToString:@"zip"] ||
       [elementName isEqualToString:@"home_phone"] ||
       [elementName isEqualToString:@"work_phone"] ||
       [elementName isEqualToString:@"mobile_phone"] ||
       [elementName isEqualToString:@"other_phone"] ||
       [elementName isEqualToString:@"loc_note"] ||
       [elementName isEqualToString:@"id"] ||
       [elementName isEqualToString:@"name"] ||
       [elementName isEqualToString:@"orig_dest"] ||
       [elementName isEqualToString:@"sequence"] ||
       [elementName isEqualToString:@"first_name"] ||
       [elementName isEqualToString:@"last_name"] ||
       [elementName isEqualToString:@"company_name"])
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
		{
			location.name = @"Origin";
			location.locationType = ORIGIN_LOCATION_ID;
		}
		else if([nodeName rangeOfString:@"dest"].location != NSNotFound)
		{
			location.name = @"Destination";
			location.locationType = DESTINATION_LOCATION_ID;
		}
		else
		{//use the next id...
			location.locationType = -1;
		}
		
		//done, set back to parent
		if([parent respondsToSelector:callback])
		{
			[parent performSelector:callback withObject:location];
		}
		
		[parser setDelegate:parent];
	}
	else if(storingData && [elementName isEqualToString:@"add1"]){
		location.address1 = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"add2"]){
		location.address2 = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"city"]){
		location.city = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"county"]){
		location.county = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"state"]){
		location.state = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"zip"]){
		location.zip = [NSString stringWithString:currentString];
	}
    else if(storingData && [elementName isEqualToString:@"home_phone"])
    {
        SurveyPhone *phone = [[SurveyPhone alloc] init];
        phone.number = [NSString stringWithString:currentString];
        phone.type.name = @"Home";
        [location.phones addObject:phone];
        
	}
    else if(storingData && [elementName isEqualToString:@"work_phone"])
    {
        SurveyPhone *phone = [[SurveyPhone alloc] init];
        phone.number = [NSString stringWithString:currentString];
        phone.type.name = @"Work";
        [location.phones addObject:phone];
        
	}
    else if(storingData && [elementName isEqualToString:@"mobile_phone"])
    {
        SurveyPhone *phone = [[SurveyPhone alloc] init];
        phone.number = [NSString stringWithString:currentString];
        phone.type.name = @"Mobile";
        [location.phones addObject:phone];
        
	}else if(storingData && [elementName isEqualToString:@"other_phone"])
    {
        SurveyPhone *phone = [[SurveyPhone alloc] init];
        phone.number = [NSString stringWithString:currentString];
        phone.type.name = @"Other";
        [location.phones addObject:phone];
        
	}
    else if(storingData && [elementName isEqualToString:@"loc_note"]){
		//no note yet...
	}else if(storingData && [elementName isEqualToString:@"name"]){
		location.name = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"orig_dest"]){
		location.isOrigin = [currentString isEqualToString:@"Origin"];
	}else if(storingData && [elementName isEqualToString:@"sequence"]){
		location.sequence = [currentString intValue];
	}else if(storingData && [elementName isEqualToString:@"first_name"]){
		location.firstName = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"last_name"]){
		location.lastName = [NSString stringWithString:currentString];
	}else if(storingData && [elementName isEqualToString:@"company_name"]){
		location.companyName = [NSString stringWithString:currentString];
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
