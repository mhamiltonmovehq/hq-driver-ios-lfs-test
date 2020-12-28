//
//  PVOWeightTicket.m
//  Survey
//
//  Created by Tony Brame on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOWeightTicket.h"
#import "WCFParser.h"

@implementation PVOWeightTicket

@synthesize ticketDate, description, moveHqId, shouldSync;

-(id)init {
    self = [super init];
    if (self) {
        moveHqId = 0;
        shouldSync = YES;
    }
    return self;
}

-(XMLWriter*)xmlFile
{
    XMLWriter *retval = [[XMLWriter alloc] init];
    
    [retval writeStartDocument];
    [retval writeStartElement:@"weight_ticket"];
    
    [retval writeElementString:@"gross_weight" withIntData:self.grossWeight];
    [retval writeElementString:@"ticket_date" withData:[WCFParser stringFromDate:self.ticketDate]];
    [retval writeElementString:@"description" withData:self.description];
    [retval writeElementString:@"weight_ticket_id" withIntData:self.moveHqId];
    
    switch (self.weightType) {
        case PVO_WEIGHT_TICKET_GROSS:
            [retval writeElementString:@"weight_type" withData:@"GROSS"];
            break;
        case PVO_WEIGHT_TICKET_TARE:
            [retval writeElementString:@"weight_type" withData:@"TARE"];
            break;
        case PVO_WEIGHT_TICKET_NET:
            [retval writeElementString:@"weight_type" withData:@"NET"];
            break;
    }
    
    [retval writeEndDocument];
    
    return retval;
}
@end
