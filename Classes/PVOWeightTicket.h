//
//  PVOWeightTicket.h
//  Survey
//
//  Created by Tony Brame on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

#define PVO_WEIGHT_TICKET_NONE 0
#define PVO_WEIGHT_TICKET_GROSS 1
#define PVO_WEIGHT_TICKET_TARE 2
#define PVO_WEIGHT_TICKET_NET 3

@interface PVOWeightTicket : NSObject

@property (nonatomic) int custID;
@property (nonatomic) int grossWeight;
@property (nonatomic) int weightType;
@property (nonatomic) int weightTicketID;
@property (nonatomic) BOOL newRecord;
@property (nonatomic) int moveHqId;
@property (nonatomic) BOOL shouldSync;

@property (nonatomic, retain) NSDate *ticketDate;
@property (nonatomic, retain) NSString *description;

-(XMLWriter*)xmlFile;

@end
