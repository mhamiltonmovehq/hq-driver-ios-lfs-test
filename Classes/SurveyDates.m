//
//  SurveyDates.m
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyDates.h"


@implementation SurveyDates

@synthesize packFrom, packTo, packPrefer, loadFrom, loadTo, loadPrefer, deliverFrom, deliverTo, deliverPrefer, survey, custID, noPack, noLoad, noDeliver, followUp, decision, inventory;

-(void)setToToday
{
    [self setToToday:YES];
}

-(void)setToToday:(BOOL)includePackLoadDelv
{
    if (includePackLoadDelv)
    {
        self.packFrom = [NSDate date];
        self.packTo = [NSDate date];
        self.packPrefer = [NSDate date];
        self.loadFrom = [NSDate date];
        self.loadTo = [NSDate date];
        self.loadPrefer = [NSDate date];
        self.deliverFrom = [NSDate date];
        self.deliverTo = [NSDate date];
        self.deliverPrefer = [NSDate date];
    }
    self.survey = [NSDate date];
    self.decision = [NSDate date];
    self.followUp = [NSDate date];
    self.inventory = [NSDate date];
    
}

-(void)flushToXML:(XMLWriter*)xml
{
    [xml writeStartElement:@"dates"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //[formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    
    if(!noPack)
    {
        if (packFrom != nil)
            [xml writeElementString:@"pack_from" withData:[formatter stringFromDate:packFrom]];
        if (packTo != nil)
            [xml writeElementString:@"pack_to" withData:[formatter stringFromDate:packTo]];
        if (packPrefer != nil)
            [xml writeElementString:@"pack_prefer" withData:[formatter stringFromDate:packPrefer]];
    }
    if(!noLoad)
    {
        if (loadFrom != nil)
            [xml writeElementString:@"load_from" withData:[formatter stringFromDate:loadFrom]];
        if (loadTo != nil)
            [xml writeElementString:@"load_to" withData:[formatter stringFromDate:loadTo]];
        if (loadPrefer != nil)
            [xml writeElementString:@"load_prefer" withData:[formatter stringFromDate:loadPrefer]];
    }
    if(!noDeliver)
    {
        if (deliverFrom != nil)
            [xml writeElementString:@"deliver_from" withData:[formatter stringFromDate:deliverFrom]];
        if (deliverTo != nil)
            [xml writeElementString:@"deliver_to" withData:[formatter stringFromDate:deliverTo]];
        if (deliverPrefer != nil)
            [xml writeElementString:@"deliver_prefer" withData:[formatter stringFromDate:deliverPrefer]];
    }
    
    [xml writeElementString:@"survey" withData:[formatter stringFromDate:survey]];
    [xml writeElementString:@"follow_up" withData:[formatter stringFromDate:followUp]];
    [xml writeElementString:@"decision" withData:[formatter stringFromDate:decision]];
    [xml writeElementString:@"inventory" withData:[formatter stringFromDate:inventory]];
    
    
    [xml writeEndElement];
}


@end
