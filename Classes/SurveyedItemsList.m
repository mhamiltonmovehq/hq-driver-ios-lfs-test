//
//  SurveyedItemsList.m
//  Survey
//
//  Created by Tony Brame on 6/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyedItemsList.h"
#import "SurveyedItem.h"
#import "SurveyAppDelegate.h"

@implementation SurveyedItemsList

@synthesize list, room;

-(id)init
{
	list = [[NSMutableDictionary alloc] init];
	itemsFilled = FALSE;
	return self;
}

-(int)totalPacking
{
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	int totalPack = 0;
	while (si = [enumerator nextObject]) {
		totalPack += si.packing;
	}
	
	return totalPack;
}

-(int)totalUnpacking
{
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	int totalUnpack = 0;
	while (si = [enumerator nextObject]) {
		totalUnpack += si.unpacking;
	}
	
	return totalUnpack;
}

-(int)totalShipping
{
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	int totalShip = 0;
	while (si = [enumerator nextObject]) {
		totalShip += si.shipping;
	}
	
	return totalShip;
}

-(int)totalNotShipping
{
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	int totalNotShip = 0;
	while (si = [enumerator nextObject]) {
		totalNotShip += si.notShipping;
	}
	
	return totalNotShip;	
}

-(double)totalCube
{
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	double totalCube = 0;
	while (si = [enumerator nextObject]) {
		totalCube += si.cube * si.shipping;
	}
	
	return totalCube;	
	
}

-(double)totalWeight:(double)weightFactor
{
	
	//loop for all cube, and weight
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	double totalCube = 0;
	double totalWeight = 0;
	while (si = [enumerator nextObject]) {
		if(si.weight > 0)
			totalWeight += si.weight * si.shipping;
		else
			totalCube += si.cube * si.shipping;
	}
	
	return (totalCube * weightFactor) + totalWeight;
	
}

-(NSMutableArray*)getBulkies
{
	if(!itemsFilled)
		return nil;
	
//	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSMutableArray *bulkies = [[NSMutableArray alloc] init];
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	while (si = [enumerator nextObject]) {
		if(si.item.isBulky)
		{
			[bulkies addObject:si];
		}		
	}
			
	return bulkies;
}

-(void)fillItems
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSArray *items = [del.surveyDB getAllItems];
	[self fillItems:items];
	
}

-(void)fillItems:(NSArray*)items
{
	SurveyedItem *si;
	Item *item;
	BOOL found = FALSE;
	NSEnumerator *enumerator = [list objectEnumerator];
	while (si = [enumerator nextObject]) {
		
		//get the right item...
		found = FALSE;
		for(int i = 0; i < [items count]; i++)
		{
			item = [items objectAtIndex:i];
			if(item.itemID == si.itemID)
			{
				found = TRUE;
				break;
			}
		}
		if(found)
		{
			si.item = item;
		}
		
	}
	
	itemsFilled = TRUE;
}

-(void)flushToXML:(XMLWriter*)xml materialHandling:(int)handleType
{
	[xml writeStartElement:@"items"];
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	SurveyedItem *si;
	NSArray *items = [del.surveyDB getItemsFromSurveyedItems:self];
	NSEnumerator *enumerator = [list objectEnumerator];
	while (si = [enumerator nextObject])
	{
		[si flushToXML:xml withItems:items materialHandling:handleType];
	}
	
	
	
	[xml writeEndElement];
}

//will return a array of the item ids contained in this surveyed list
/*-(NSMutableArray*)getSurveyedItemIDs
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSEnumerator *enumerator = [list objectEnumerator];
	
	SurveyedItem *si;
	while (si = [enumerator nextObject]) {
		[array addObject:si];
	}
	
	return array;	
}*/

@end
