//
//  CubeSheetParser.m
//  Survey
//
//  Created by Tony Brame on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CubeSheetParser.h"
#import "SurveyAppDelegate.h"

@implementation CubeSheetParser

@synthesize currentString, entries, currentRoom, parent, roomImages;

-(id)initWithAppDelegate:(SurveyAppDelegate *)del
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
		entries = [[NSMutableArray alloc] init];
        roomImages = [[NSMutableDictionary alloc] init];
        _appDelegate = del;
	}
	return self;
}

-(void)dealloc
{
    _appDelegate = nil;
}


#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if([elementName isEqualToString:@"room"])
	{
        inRoom = YES;
        
        currentRoomImageID = 0;
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"image_id"] != nil)
            currentRoomImageID = [[attributeDict objectForKey:@"image_id"] intValue];
        
    }
    else if([elementName isEqualToString:@"dimensions"])
	{
        si.dims = [[CrateDimensions alloc] init];
    }
    else if([elementName isEqualToString:@"item"])
	{
        item = [[Item alloc] init];
        si = [[SurveyedItem alloc] init];
        
        si.roomID = currentRoom.roomID;
//        si.csID = cs.csID;
    }
	else if((inRoom && [elementName isEqualToString:@"name"]) || 
            [elementName isEqualToString:@"article_name"] ||
            [elementName isEqualToString:@"article_name_french"] ||
			[elementName isEqualToString:@"cube"] ||
			[elementName isEqualToString:@"shipping"] || 
			[elementName isEqualToString:@"not_shipping"] || 
			[elementName isEqualToString:@"weight"] || 
			[elementName isEqualToString:@"pack"] || 
			[elementName isEqualToString:@"unpack"] || 
			[elementName isEqualToString:@"itemID"] || 
			[elementName isEqualToString:@"crate"] || 
			[elementName isEqualToString:@"weight"] || 
			[elementName isEqualToString:@"bulky"] || 
			[elementName isEqualToString:@"carton_cp"] || 
			[elementName isEqualToString:@"carton_pbo"] || 
			[elementName isEqualToString:@"length"] || 
			[elementName isEqualToString:@"width"] || 
			[elementName isEqualToString:@"height"] || 
			[elementName isEqualToString:@"image_id"])
	{
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	NSString *temp = [[NSString alloc] initWithString:currentString];
	
	NSDate *date = [[NSDate alloc] init];
	
	if([elementName isEqualToString:@"cube_sheet"])
	{
        [parser setDelegate:parent];
    }
	else if([elementName isEqualToString:@"room"])
	{
        inRoom = NO;
    }
	else if([elementName isEqualToString:@"item"])
	{
        
        //create the item if necessary...
        si.itemID = [_appDelegate.surveyDB insertNewItem:item withRoomID:-1 withCustomerID:-1 includeCubeInValidation:YES withPVOLocationID:0 appDelegate:_appDelegate];
        
//        si.itemID = [del.surveyDB getItemID:item.name withCube:item.cube];
        
        //there may be > 1 of same item in a room.  Roll up the counts.
        BOOL found = false;
        
        for (SurveyedItem *current in entries) {
            if(current.itemID == si.itemID &&
               current.roomID == si.roomID)
            {
                current.shipping += si.shipping;
                current.packing += si.packing;
                current.unpacking += si.unpacking;
                current.notShipping += si.notShipping;
                found = true;
            }
        }
        
        //write out the item.
        //add to entries
        if(!found)
            [entries addObject:si];
        
    }
    else if(inRoom && [elementName isEqualToString:@"name"])
    {
        Room *r = [_appDelegate.surveyDB insertNewRoom:temp withCustomerID:-1 alwaysReturnRoom:YES];
        self.currentRoom = r;
        
        if(currentRoomImageID > 0)
            [roomImages setObject:[NSNumber numberWithInt:currentRoomImageID] forKey:[NSNumber numberWithInt:currentRoom.roomID]];
        
    }
    else if(storingData && [elementName isEqualToString:@"article_name"]){
        item.name = temp;
    }
    else if(storingData && [elementName isEqualToString:@"article_name_french"]){
        item.nameFrench = temp;
    }
    else if(storingData && [elementName isEqualToString:@"cube"]){
        si.cube = [temp doubleValue];
        item.cube = si.cube;
	}
    else if(storingData && [elementName isEqualToString:@"shipping"]){
        si.shipping = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"not_shipping"]){
        si.notShipping = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"weight"]){
        si.weight = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"pack"]){
        si.packing = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"unpack"]){
        si.unpacking = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"itemID"]){
        item.cartonBulkyID = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"crate"]){
        item.isCrate = [temp isEqualToString:@"true"] ? 1 : 0;
	}
    else if(storingData && [elementName isEqualToString:@"bulky"]){
        item.isBulky = [temp isEqualToString:@"true"] ? 1 : 0;
	}
    else if(storingData && [elementName isEqualToString:@"carton_cp"]){
        item.isCP = [temp isEqualToString:@"true"] ? 1 : 0;
	}
    else if(storingData && [elementName isEqualToString:@"carton_pbo"]){
        item.isPBO = [temp isEqualToString:@"true"] ? 1 : 0;
	}
    else if(storingData && [elementName isEqualToString:@"length"]){
        si.dims.length = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"width"]){
        si.dims.width = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"height"]){
        si.dims.height = [temp intValue];
	}
    else if(storingData && [elementName isEqualToString:@"image_id"]){
        si.imageID = [temp intValue];
	}
	
	storingData = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if(storingData)
		[currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}


@end
