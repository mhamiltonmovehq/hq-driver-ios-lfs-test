//
//  PVODynamicReportData.m
//  Survey
//
//  Created by Tony Brame on 1/2/15.
//
//

#import "PVODynamicReportData.h"
#import "SurveyAppDelegate.h"

@implementation PVODynamicReportData


-(void)flushToXML:(XMLWriter*)xml
{
    [xml writeStartElement:@"dynamic_entry"];
    
    [xml writeAttribute:@"report_id" withData:[NSString stringWithFormat:@"%d",self.reportID]];
    [xml writeAttribute:@"section_id" withData:[NSString stringWithFormat:@"%d",self.dataSectionID]];
    [xml writeAttribute:@"entry_id" withData:[NSString stringWithFormat:@"%d",self.dataEntryID]];
    
    if(self.intValue > 0)
        [xml writeElementString:@"int_value" withIntData:self.intValue];
    
    if(self.doubleValue > 0)
        [xml writeElementString:@"double_value" withDoubleData:self.doubleValue];
    
    if(self.dateValue != nil && self.dateValue.timeIntervalSince1970 != 0) 
        [xml writeElementString:@"date_value" withData:[SurveyAppDelegate formatDateAndTime:self.dateValue asGMT:NO]];
    
    if(self.textValue != nil && self.textValue.length > 0)
        [xml writeElementString:@"text_value" withData:self.textValue];
    
    [xml writeEndElement];
}

-(void)dealloc
{
    self.textValue = nil;
    self.dateValue = nil;
}

@end
