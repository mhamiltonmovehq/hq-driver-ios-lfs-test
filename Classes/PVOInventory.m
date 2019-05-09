//
//  Inventory.m
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOInventory.h"
#import "PVOItemDetail.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"


@implementation PVOInventory

@synthesize currentLotNum, inventoryCompleted;
@synthesize currentColor, usingScanner;
@synthesize nextItemNum, custID, currentLocation;

@synthesize loadType, deliveryCompleted, newPagePerLot, weightFactor;
@synthesize noConditionsInventory, tractorNumber, trailerNumber;

@synthesize lockLoadType, mproWeight, sproWeight, consWeight;
@synthesize valuationType;

-(id)init
{
	if((self = [super init]))
	{
        self.currentLotNum = @"";
		self.currentColor = RED;
		self.nextItemNum = 1;
		self.usingScanner = NO;//YES;  //defect 11280
        self.loadType = HOUSEHOLD;
        self.valuationType = 0;
        self.currentLocation = RESIDENCE;
        self.newPagePerLot = YES;
        self.weightFactor = 7.0;
        self.packingType = PVO_PACK_NONE;
        self.packingOT = NO;
        self.lockLoadType = NO;
	}
	return self;
}

-(int)getInventoryMPROWeight
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([AppFunctionality enableMilitaryWeightEntryOnLandingController])
    {
        // if vanline is not arpin, return user defined mpro weight
        return mproWeight;
    }
    else
    {
        // if vanline is arpin, calculate mpro weight based on items in DB
        return [del.surveyDB getPVOItemWeightMpro:custID];
    }
}


-(int)getInventorySPROWeight
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([AppFunctionality enableMilitaryWeightEntryOnLandingController])
    {
        // if vanline is not arpin, return user defined spro weight
        return sproWeight;
    }
    else
    {
        // if vanline is arpin, calculate spro weight based on items in DB
        return [del.surveyDB getPVOItemWeightSpro:custID];
    }
}

-(int)getInventoryConsWeight
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([AppFunctionality enableMilitaryWeightEntryOnLandingController])
    {
        // if vanline is not arpin, return user defined cons weight
        return consWeight;
    }
    else
    {
        // if vanline is arpin, calculate cons weight based on items in DB
        
        return [del.surveyDB getPVOItemWeightCons:custID];
    }
}



-(void)dealloc
{
	self.confirmLotNum = nil;	
}



@end
