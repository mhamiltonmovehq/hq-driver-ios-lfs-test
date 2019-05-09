//
//  DynamicReportDataXMLParser.m
//  Survey
//
//  Created by Justin on 7/14/15.
//
//

#import "SurveyAppDelegate.h"
#import "DynamicReportDataXMLParser.h"

@implementation DynamicReportDataXMLParser

@synthesize parent, callback, dynamicData, rptData;

-(void)dealloc
{
    [currentString release];
    [dateFormatter release];
    [dynamicData release];
    if (rptData != nil)
        [rptData release];
    
    [super dealloc];
}

-(id)init
{
    if(self = [super init])
    {
        currentString = [[NSMutableString alloc] init];
        dynamicData = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark NSXMLParser Parsing Callbacks
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if([elementName isEqualToString:@"dynamic_entry"])
    {
        [rptData release];
        rptData = [[PVODynamicReportData alloc] init];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"report_id"] != nil)
            rptData.reportID = [[attributeDict objectForKey:@"report_id"] intValue];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"section_id"] != nil)
            rptData.dataSectionID = [[attributeDict objectForKey:@"section_id"] intValue];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"entry_id"] != nil)
            rptData.dataEntryID = [[attributeDict objectForKey:@"entry_id"] intValue];
        
    }
    else if([elementName isEqualToString:@"int_value"] ||
       [elementName isEqualToString:@"double_value"] ||
       [elementName isEqualToString:@"date_value"] ||
       [elementName isEqualToString:@"text_value"])
    {
        //all root data
        storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if(storingData && [elementName isEqualToString:@"int_value"]){
        rptData.intValue = [currentString intValue];
    }else if(storingData && [elementName isEqualToString:@"double_value"]){
        rptData.doubleValue = [currentString doubleValue];
    }else if(storingData && [elementName isEqualToString:@"date_value"]){
        NSString *temp = [[NSString alloc] initWithString:currentString];
        NSDate *date = [[NSDate alloc] init];
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        rptData.dateValue = [date retain];
        [date release];
        [temp release];
    }else if(storingData && [elementName isEqualToString:@"text_value"]){
        rptData.textValue = [NSString stringWithString:currentString];
    }else if ([elementName isEqualToString:@"dynamic_entry"]){
        [dynamicData addObject:rptData];
    }
    
    storingData = NO;
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
