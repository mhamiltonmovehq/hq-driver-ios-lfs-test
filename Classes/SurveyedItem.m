//
//  SurveyedItem.m
//  Survey
//
//  Created by Tony Brame on 6/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyedItem.h"
#import "CrateDimensions.h"
#import "SurveyAppDelegate.h"
#import "Item.h"
#import "CustomerUtilities.h"

@implementation SurveyedItem

@synthesize csID;
@synthesize siID;
@synthesize itemID;
@synthesize roomID;
@synthesize shipping;
@synthesize notShipping;
@synthesize packing;
@synthesize unpacking;
@synthesize cube;
@synthesize weight, item, dims, imageID;


-(id)initWithSurveyedItem:(SurveyedItem*)si
{
	
	if(self = [super init])
	{
		csID = si.csID;
		siID = si.siID;
		itemID = si.itemID;
		roomID = si.roomID;
		shipping = si.shipping;
		notShipping = si.notShipping;
		packing = si.packing;
		unpacking = si.unpacking;
		cube = si.cube;
		weight = si.weight;
		
		if(si.item != nil)
			self.item = si.item;
		else
			item = nil;
		
		if(si.dims != nil)
			self.dims = si.dims;
		else
			dims = nil;
	}
	
	return self;
}


-(id)init
{
	
	if(self = [super init])
	{
		item = nil;
		dims  =nil;
	}
	
	return self;
}


-(void)updateCrateCube:(CrateDimensions*)dimensions withMinimum:(double)minimun andInches:(double)inches
{
	
	if(dimensions == nil)
		return;
	
	int len = dimensions.length;
	int width = dimensions.width;
	int height = dimensions.height;
	
	self.cube = ceil(((len + inches) * (width + inches) * (height + inches)) / (12.0 * 12.0 * 12.0));
	
	if(cube < minimun)
		self.cube = minimun;
}

-(void)flushToXML:(XMLWriter*)xml withItems:(NSArray*)items materialHandling:(int)handleType
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	[xml writeStartElement:@"item"];

	//get the right item...
	BOOL found = FALSE;
	Item *temp;
	for(int i = 0; i < [items count]; i++)
	{
		temp = [items objectAtIndex:i];
		if(temp.itemID == itemID)
		{
			found = TRUE;
			self.item = temp;
			break;
		}
	}
	if(!found)
	{
		[xml writeEndElement];
		return;
	}
	
	
	[xml writeElementString:@"article_name" withData:item.name];
	
	[xml writeElementString:@"cube" withData:[[NSNumber numberWithDouble:cube] stringValue]];
	
	[xml writeElementString:@"shipping" withIntData:shipping];
	[xml writeElementString:@"not_shipping" withIntData:notShipping];
	[xml writeElementString:@"weight" withIntData:weight];
	[xml writeElementString:@"pack" withIntData:packing];
	[xml writeElementString:@"unpack" withIntData:unpacking];
	
	if(handleType == FLUSH_MATERIALS_SAME_AS_SHIP)
	{
		[xml writeElementString:@"materials" withIntData:shipping];
	}
	else if (handleType == FLUSH_MATERIALS_SHIP_MINUS_PACK)
	{
		[xml writeElementString:@"materials" withIntData:(shipping-packing)];
	}
	
	[xml writeElementString:@"itemID" withIntData:item.cartonBulkyID];
	
	[xml writeStartElement:@"item_attribs"];
	[xml writeElementString:@"crate" withData:item.isCrate ? @"true" : @"false"];
	[xml writeElementString:@"has_weight" withData:weight > 0 ? @"true" : @"false"];
	[xml writeElementString:@"bulky" withData:item.isBulky ? @"true" : @"false"];
	[xml writeElementString:@"carton" withData:item.isCP || item.isPBO ? @"true" : @"false"];
	[xml writeElementString:@"carton_cp" withData:item.isCP ? @"true" : @"false"];
	[xml writeElementString:@"carton_pbo" withData:item.isPBO ? @"true" : @"false"];
	[xml writeEndElement];
	
	if(item.isCrate)
	{//get dims...
		CrateDimensions *dimensions = [del.surveyDB getCrateDimensions:siID];
		[xml writeStartElement:@"dimensions"];
		
		[xml writeElementString:@"length" withIntData:dimensions.length];
		[xml writeElementString:@"width" withIntData:dimensions.width];
		[xml writeElementString:@"height" withIntData:dimensions.height];
		
		[xml writeEndElement];
	}
	
	NSString *comment = [del.surveyDB getItemComment:siID];
	
	if([comment length] > 0)
	{
		[xml writeStartElement:@"comment"];
		
		[xml writeAttribute:@"id" withData:[NSString stringWithFormat:@"%d", siID]];
		
		[xml writeElementString:@"comment" withData:comment];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
		[xml writeElementString:@"date_time" withData:[formatter stringFromDate:[NSDate date]]];
		
		
		[xml writeEndElement];
	}
		
	int imageSyncID = [del.surveyDB getImageSyncID:del.customerID withPhotoType:IMG_SURVEYED_ITEMS withSubID:siID];
	if(imageSyncID > 0)
		[xml writeElementString:@"image_id" withIntData:imageSyncID];
	
	[xml writeEndElement];
}

-(NSComparisonResult)compareAlphabetically:(SurveyedItem*)otherItem
{
	if(otherItem.item == nil)
		return NSOrderedAscending;
	else if(item == nil)
		return NSOrderedDescending;
	else 
	{
		return [[item name] compare:otherItem.item.name];
	}
}

@end
