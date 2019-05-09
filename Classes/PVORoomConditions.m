//
//  PVORoomConditions.m
//  Survey
//
//  Created by Tony Brame on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVORoomConditions.h"

@implementation PVORoomConditions

@synthesize roomConditionsID;
@synthesize pvoLoadID;
@synthesize roomID;
@synthesize floorTypeID;
@synthesize hasDamage;
@synthesize damageDetail;
@synthesize pvoUnloadID;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


@end
