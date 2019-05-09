//
//  PVOCheckListItem.m
//  Survey
//
//  Created by David Yost on 9/14/15.
//
//

#import "PVOCheckListItem.h"

@implementation PVOCheckListItem

@synthesize vehicleCheckListID, checkListItemID, customerID, vehicleID;
@synthesize description;
@synthesize isChecked;
@synthesize agencyCode;


-(id)init
{
    self = [super init];
    
    if(self)
    {
        vehicleCheckListID = -1;
        checkListItemID = -1;
        customerID = -1;
        vehicleID = -1;
        description = nil;
        isChecked = false;
    }
    
    return self;
}


@end
