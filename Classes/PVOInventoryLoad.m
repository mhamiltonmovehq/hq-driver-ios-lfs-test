//
//  PVOInventoryLoad.m
//  Survey
//
//  Created by Tony Brame on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOInventoryLoad.h"

@implementation PVOInventoryLoad

@synthesize pvoLoadID;
@synthesize custID;
@synthesize pvoLocationID;
@synthesize locationID;

@synthesize cube, weight;

@synthesize receivedFromPVOLocationID;;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end
