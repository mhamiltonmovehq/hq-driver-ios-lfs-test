//
//  PVOBulkyData.m
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import "PVOBulkyData.h"
#import "PVOBulkyEntry.h"
#import "SurveyAppDelegate.h"

@implementation PVOBulkyData

-(void)flushToXML:(XMLWriter*)xml
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOBulkyEntry *entry = [del.pricingDB getPVOBulkyDetailEntryByID:self.dataEntryID];
    [xml writeStartElement:@"bulky_entry"];
    
    [xml writeAttribute:@"entry_id" withData:[NSString stringWithFormat:@"%d",self.dataEntryID]];
    [xml writeAttribute:@"entry_name" withData:[NSString stringWithFormat:@"%@",entry.entryName]];
    
    if(self.intValue > 0)
        [xml writeElementString:@"int_value" withIntData:self.intValue];
    else if(self.doubleValue > 0)
        [xml writeElementString:@"double_value" withDoubleData:self.doubleValue];
    else if(self.dateValue != nil && self.dateValue.timeIntervalSince1970 != 0)
        [xml writeElementString:@"date_value" withData:[SurveyAppDelegate formatDateAndTime:self.dateValue asGMT:NO]];
    else if(self.textValue != nil && self.textValue.length > 0)
        [xml writeElementString:@"text_value" withData:self.textValue];
        
    [xml writeEndElement];
}

-(void)dealloc
{
    self.textValue = nil;
    self.dateValue = nil;
}

@end
