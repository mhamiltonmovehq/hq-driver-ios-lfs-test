//
//  ReportOptionParser.m
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ReportOptionParser.h"

@implementation ReportOptionParser

@synthesize address, entries, option;

-(id)init
{
	if(self = [super init]){
		currentString = [[NSMutableString alloc] init];
	}
	return self;
}

#pragma mark NSXMLParser Parsing Callbacks

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
    if([elementName isEqualToString:@"reports"])
	{
		if([attributeDict objectForKey:@"service_address"] != nil)
			self.address = [attributeDict objectForKey:@"service_address"];
    }
	else if([elementName isEqualToString:@"report"])
	{
		ReportOption *opt = [[ReportOption alloc] init];
		self.option = opt;
	}
	else if([elementName isEqualToString:@"report_name"] ||
			[elementName isEqualToString:@"report_id"] ||
			[elementName isEqualToString:@"html_supported"] ||
			[elementName isEqualToString:@"html_revision"] ||
			[elementName isEqualToString:@"html_location"] ||
            [elementName isEqualToString:@"html_target_file"] ||
            [elementName isEqualToString:@"html_supports_images"] ||
            [elementName isEqualToString:@"page_size"])
	{//all root data
		storingData = YES;
		[currentString setString:@""];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	NSString *temp = [[NSString alloc] initWithString:currentString];
	
	if([elementName isEqualToString:@"report"])
	{
		if(entries == nil)
			entries = [[NSMutableArray alloc] init];
		[entries addObject:option];
	}
	else if(storingData && [elementName isEqualToString:@"report_name"]){
		option.reportName = temp;
	}
	else if(storingData && [elementName isEqualToString:@"report_id"]){
		option.reportID = [temp intValue];
	}
	else if(storingData && [elementName isEqualToString:@"html_supported"]){
		option.htmlSupported = [temp isEqualToString:@"true"];
	}
	else if(storingData && [elementName isEqualToString:@"html_revision"]){
		option.htmlRevision = [temp intValue];
	}
	else if(storingData && [elementName isEqualToString:@"html_location"]){
		option.htmlBundleLocation = temp;
	}
	else if(storingData && [elementName isEqualToString:@"html_target_file"]){
		option.htmlTargetFile = temp;
	}
    else if(storingData && [elementName isEqualToString:@"html_supports_images"]){
        option.htmlSupportsImages = [temp isEqualToString:@"true"];
    }
    else if(storingData && [elementName isEqualToString:@"page_size"]){
        option.pageSize = [temp intValue];
    }
    
	
	
	storingData = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[currentString appendString:string];
}

@end
