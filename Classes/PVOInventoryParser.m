//
//  PVOInventoryParser.m
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOInventoryParser.h"
#import "SurveyAppDelegate.h"

@implementation PVOInventoryParser

@synthesize currentString, entries, currentRoom, parent, roomImages;
@synthesize receivedType, receivedUnloadType;
@synthesize loadType, mproWeight, sproWeight, consWeight;
@synthesize receivedFromType;

-(id)init
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
		entries = [[NSMutableArray alloc] init];
        roomImages = [[NSMutableDictionary alloc] init];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        allCartonContents = [del.surveyDB getPVOAllCartonContents];
        
        self.loadType = HOUSEHOLD; //default value
        self.mproWeight = 0;
        self.sproWeight = 0;
        self.consWeight = 0;
        self.receivedFromType = 0;
	}
	return self;
}

#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
    if([elementName isEqualToString:@"pvo_driver_inventory"])
    {
        inInventory = YES;
    }
    else if(!inInventory)
        return;
    else if([elementName isEqualToString:@"inventory_room"])
	{
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        currentRoomImageID = 0;
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"image_id"] != nil)
            currentRoomImageID = [[attributeDict objectForKey:@"image_id"] intValue];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"name"] != nil)
        {
            Room *r = [del.surveyDB insertNewRoom:[attributeDict objectForKey:@"name"] withCustomerID:-1 alwaysReturnRoom:YES];
            self.currentRoom = r;
            
        }
        
        if(currentRoomImageID > 0)
            [roomImages setObject:[NSNumber numberWithInt:currentRoomImageID] forKey:[NSNumber numberWithInt:currentRoom.roomID]];
        
    }
    else if([elementName isEqualToString:@"carton_contents"] && !processingDetailedCartonContent)
	{
        invitem.cartonContents = YES;
        processingDetailedCartonContent = YES;
        invitem.cartonContentsDetail = [NSMutableArray array];
    }
    else if([elementName isEqualToString:@"descriptive_symbols"])
	{
        subnode = INV_PARSER_DESCRIPTIVE;
        if (processingDetailedCartonContent)
            cartonContentItem.descriptiveSymbols = [NSMutableArray array];
        else
            invitem.descriptiveSymbols = [NSMutableArray array];
    }
    else if(subnode == INV_PARSER_DESCRIPTIVE && [elementName isEqualToString:@"symbol"])
	{
        PVOItemDescription *newDesc = [[PVOItemDescription alloc] init];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"code"] != nil)
            newDesc.descriptionCode = [attributeDict objectForKey:@"code"];
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"description"] != nil)
            newDesc.description = [attributeDict objectForKey:@"description"];
        
        if (processingDetailedCartonContent)
            [cartonContentItem.descriptiveSymbols addObject:newDesc];
        else
            [invitem.descriptiveSymbols addObject:newDesc];
        
    }
    else if([elementName isEqualToString:@"inventory_damage"])
	{
        subnode = INV_PARSER_DAMAGE;
        currentCondy = [[PVOConditionEntry alloc] init];
    }
    else if(subnode == INV_PARSER_DAMAGE && [elementName isEqualToString:@"damage"])
	{
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"code"] != nil)
            [currentCondy addCondition:[attributeDict objectForKey:@"code"]];
    }
    else if(subnode == INV_PARSER_DAMAGE && [elementName isEqualToString:@"location"])
	{
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"code"] != nil)
            [currentCondy addLocation:[attributeDict objectForKey:@"code"]];
    }
    else if([elementName isEqualToString:@"item"] || [elementName isEqualToString:@"carton_content"])
	{
        BOOL isCartonContent = [elementName isEqualToString:@"carton_content"];
        if (isCartonContent)
        {
            subnode = INV_PARSER_CARTON_CONTENTS;
            cartonContentItem = [[PVOItemDetailExtended alloc] init];
            cartonContentItem.damageDetails = [NSMutableArray array];
            cartonContentItem.descriptiveSymbols = [NSMutableArray array];
            cartonContentItem.itemCommentDetails = [NSMutableArray array];
        }
        else
        {
            
            item = [[Item alloc] init];
            invitem = [[PVOItemDetailExtended alloc] init];
            
            invitem.damageDetails = [NSMutableArray array];
            invitem.descriptiveSymbols = [NSMutableArray array];
            invitem.cartonContentsDetail = [NSMutableArray array];
            invitem.itemCommentDetails = [NSMutableArray array];
            
            invitem.roomID = currentRoom.roomID;
            
            if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_cp"] != nil)
                item.isCP = [[attributeDict objectForKey:@"is_cp"] isEqualToString:@"true"];
            
            if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_pbo"] != nil)
                item.isPBO = [[attributeDict objectForKey:@"is_pbo"] isEqualToString:@"true"];
        }
        
        PVOItemDetailExtended *i = (isCartonContent ? cartonContentItem : invitem);
        
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_deleted"] != nil)
            i.itemIsDeleted = [[attributeDict objectForKey:@"is_deleted"] isEqualToString:@"true"];
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_delivered"] != nil)
            i.itemIsDelivered = [[attributeDict objectForKey:@"is_delivered"] isEqualToString:@"true"];
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_mpro"] != nil)
            i.itemIsMPRO = [[attributeDict objectForKey:@"is_mpro"] isEqualToString:@"true"];
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_spro"] != nil)
            i.itemIsSPRO = [[attributeDict objectForKey:@"is_spro"] isEqualToString:@"true"];
        if([attributeDict count] > 0 && [attributeDict objectForKey:@"is_cons"] != nil)
            i.itemIsCONS = [[attributeDict objectForKey:@"is_cons"] isEqualToString:@"true"];
    }
    else if ([elementName isEqualToString:@"comment"])
    {
        if (attributeDict != nil && [attributeDict count] > 0 && [attributeDict objectForKey:@"type"] != nil && [attributeDict objectForKey:@"note"] != nil) {
            PVOItemComment *comment = [[PVOItemComment alloc] init];
            NSString *type = [attributeDict objectForKey:@"type"];
            if ([type isEqualToString:@"Loading"]) {
                comment.commentType = COMMENT_TYPE_LOADING;
            } else if ([type isEqualToString:@"Unloading"]) {
                comment.commentType = COMMENT_TYPE_UNLOADING;
            } else {
                comment.commentType = [type intValue];
            }
            comment.comment = [NSString stringWithString:[attributeDict objectForKey:@"note"]];
            
            if (processingDetailedCartonContent)
                [cartonContentItem.itemCommentDetails addObject:comment];
            else
                [invitem.itemCommentDetails addObject:comment];
            
        }
    }
	else if([elementName isEqualToString:@"load_type"] ||
            [elementName isEqualToString:@"mpro_weight"] ||
            [elementName isEqualToString:@"spro_weight"] ||
            [elementName isEqualToString:@"cons_weight"] ||
            [elementName isEqualToString:@"cube"] ||
            [elementName isEqualToString:@"weight"] ||
            [elementName isEqualToString:@"weight_type"] ||
            [elementName isEqualToString:@"article_name"] ||
            [elementName isEqualToString:@"quantity"] ||
            [elementName isEqualToString:@"barcode"] || 
			[elementName isEqualToString:@"tag_color"] || 
//			[elementName isEqualToString:@"notes"] ||
			[elementName isEqualToString:@"cost"] ||
            [elementName isEqualToString:@"year"] ||
            [elementName isEqualToString:@"make"] ||
			[elementName isEqualToString:@"model_number"] ||
			[elementName isEqualToString:@"serial_number"] ||
            [elementName isEqualToString:@"security_seal_number"] ||
            [elementName isEqualToString:@"odometer"] ||
            [elementName isEqualToString:@"caliber_gauge"] ||
            (subnode == INV_PARSER_CARTON_CONTENTS && [elementName isEqualToString:@"description"]) ||
			[elementName isEqualToString:@"pvo_location_type"] ||
            [elementName isEqualToString:@"pvo_received_from_type"] ||
            [elementName isEqualToString:@"pvo_unload_type"] ||
            [elementName isEqualToString:@"packer_initials"] ||
            [elementName isEqualToString:@"void_reason"] ||
            (subnode == INV_PARSER_DAMAGE && [elementName isEqualToString:@"process_type"]) ||
            [elementName isEqualToString:@"length"] ||
            [elementName isEqualToString:@"width"] ||
            [elementName isEqualToString:@"height"] ||
            [elementName isEqualToString:@"has_dimensions"] ||
            [elementName isEqualToString:@"dimension_unit_type"])
	{
		storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	NSString *temp = [[NSString alloc] initWithString:currentString];
		
    //only process in inventory
    if(!inInventory)
        return;
    
	if([elementName isEqualToString:@"item"])
	{
        //create the item if necessary...
        int languageCode = [del.surveyDB getLanguageForCustomer:del.customerID];
        int itemListId = [del.surveyDB getCustomerItemListID:del.customerID];
        invitem.itemID = [del.surveyDB insertNewItem:item withRoomID:currentRoom.roomID withCustomerID:del.customerID includeCubeInValidation:NO withPVOLocationID:0 withLanguageCode:languageCode withItemListId:itemListId checkForAdditionalCustomItemLists:NO];
        
        //write out the item.
        //add to entries
        [entries addObject:invitem];
    }
    else if([elementName isEqualToString:@"carton_contents"]){
        processingDetailedCartonContent = NO;
        subnode = INV_PARSER_NONE;
        invitem.cartonContents = [invitem.cartonContentsDetail count] > 0;
	}
    else if (processingDetailedCartonContent && [elementName isEqualToString:@"carton_content"]) {
        subnode = INV_PARSER_NONE;
        if (cartonContentItem.cartonContentID > 0)
            [invitem.cartonContentsDetail addObject:cartonContentItem];
    }
    else if (storingData && [elementName isEqualToString:@"load_type"]){
        if (temp == nil || [temp isEqualToString:@""] || [temp isEqualToString:@"Household"])
            self.loadType = HOUSEHOLD;
        else if ([temp isEqualToString:@"Commercial"])
            self.loadType = COMMERCIAL;
        else if ([temp isEqualToString:@"Military"])
            self.loadType = MILITARY;
        else if ([temp isEqualToString:@"SpecialProducts"]){
            self.loadType = SPECIAL_PRODUCTS;
            PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
            inventory.custID = del.customerID;
            inventory.loadType = SPECIAL_PRODUCTS;
            [del.surveyDB updatePVOData:inventory];
            
            ShipmentInfo *s = [del.surveyDB getShipInfo:del.customerID];
            s.itemListID = SPECIAL_PRODUCTS;
            [del.surveyDB updateShipInfo:s];
        }
        else if ([temp isEqualToString:@"DisplaysAndExhibits"])
            self.loadType = DISPLAYS_EXHIBITS;
        else if ([temp isEqualToString:@"International"])
            self.loadType = INTERNATIONAL;
        else
            self.loadType = HOUSEHOLD; //not a supported type yet
        
        
    }
    else if (storingData && [elementName isEqualToString:@"mpro_weight"]){
        if(temp != nil && ![temp isEqualToString:@""])
            self.mproWeight = [temp intValue];
    }
    else if (storingData && [elementName isEqualToString:@"spro_weight"]){
        if(temp != nil && ![temp isEqualToString:@""])
            self.sproWeight = [temp intValue];
    }
    else if (storingData && [elementName isEqualToString:@"cons_weight"]){
        if(temp != nil && ![temp isEqualToString:@""])
            self.consWeight = [temp intValue];
    }
    else if(storingData && [elementName isEqualToString:@"article_name"]){
        if (!processingDetailedCartonContent)
            item.name = temp;
	}
    else if(storingData && [elementName isEqualToString:@"quantity"]){
        if (temp != nil && ![temp isEqualToString:@""])
        {
            if (processingDetailedCartonContent)
                cartonContentItem.quantity = [temp intValue];
            else
                invitem.quantity = [temp intValue];
        }
	}
    else if(storingData && [elementName isEqualToString:@"pvo_location_type"]){
        if([temp isEqualToString:@"PackersInventory"])
            self.receivedType = PACKER_INVENTORY;
        else if([temp isEqualToString:@"Warehouse"])
            self.receivedType = WAREHOUSE;
        else
            self.receivedType = RESIDENCE;
	}
    else if(storingData && [elementName isEqualToString:@"pvo_received_from_type"]){
        if([temp isEqualToString:@"PackersInventory"])
            self.receivedFromType = PACKER_INVENTORY;
        else if([temp isEqualToString:@"Warehouse"])
            self.receivedFromType = WAREHOUSE;
        else if ([temp isEqualToString:@"Residence"])
            self.receivedFromType = RESIDENCE;
        else
            self.receivedFromType = 0;
    }
    else if (storingData && [elementName isEqualToString:@"pvo_unload_type"])
    {
        if (temp == nil || [temp isEqualToString:@""])
            self.receivedUnloadType = 0;
        else if([temp isEqualToString:@"ExtraPickup"])
            self.receivedUnloadType = EXTRA_PICKUP;
        else if ([temp isEqualToString:@"Overflow"])
            self.receivedUnloadType = OVERFLOW_LOC;
        else if ([temp isEqualToString:@"SelfStorage"])
            self.receivedUnloadType = SELF_STORAGE;
        else if ([temp isEqualToString:@"VanToVan"])
            self.receivedUnloadType = VAN_TO_VAN;
        else if ([temp isEqualToString:@"Warehouse"])
            self.receivedUnloadType = WAREHOUSE;
        else
            self.receivedUnloadType = RESIDENCE; //default
    }
    else if (storingData && [elementName isEqualToString:@"packer_initials"]){
        if (processingDetailedCartonContent)
            cartonContentItem.packerInitials = temp;
        else
            invitem.packerInitials = temp;
    }
    else if (storingData && [elementName isEqualToString:@"year"]){
        if (temp != nil && ![temp isEqualToString:@""])
        {
            if (processingDetailedCartonContent)
                cartonContentItem.year = [temp intValue];
            else
                invitem.year = [temp intValue];
        }
    }
    else if (storingData && [elementName isEqualToString:@"make"]){
        if (processingDetailedCartonContent)
            cartonContentItem.make = temp;
        else
            invitem.make = temp;
    }
    else if(storingData && [elementName isEqualToString:@"model_number"]){
        if (processingDetailedCartonContent)
            cartonContentItem.modelNumber = temp;
        else
            invitem.modelNumber = temp;
	}
    else if(storingData && [elementName isEqualToString:@"serial_number"]){
        if (processingDetailedCartonContent)
            cartonContentItem.serialNumber = temp;
        else
            invitem.serialNumber = temp; //[temp intValue];
	}
    else if (storingData && [elementName isEqualToString:@"security_seal_number"]){
        if (processingDetailedCartonContent)
            cartonContentItem.securitySealNumber = temp;
        else
            invitem.securitySealNumber = temp; //[temp intValue];
    }

    else if(storingData && [elementName isEqualToString:@"odometer"]){
        if(temp != nil && ![temp isEqualToString:@""])
        {
            if(processingDetailedCartonContent)
                cartonContentItem.odometer = [temp intValue];
            else
                invitem.odometer = [temp intValue];
        }
    }
    else if (storingData && [elementName isEqualToString:@"caliber_gauge"]){
        if(processingDetailedCartonContent)
            cartonContentItem.caliberGauge = temp;
        else
            invitem.caliberGauge = temp;
    }
    else if (storingData && [elementName isEqualToString:@"void_reason"]) {
        if (processingDetailedCartonContent)
            cartonContentItem.voidReason = temp;
        else
            invitem.voidReason = temp;
    }
    else if(storingData && [elementName isEqualToString:@"barcode"]){
        if (temp != nil && temp.length > 3)
        {
            PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
            i.lotNumber = [temp substringToIndex:[temp length]-3];
            i.itemNumber = [temp substringFromIndex:[temp length]-3];
        }
	}
    else if(storingData && [elementName isEqualToString:@"tag_color"]){
        PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
        if(temp == nil)
            i.tagColor = MULTI;
        else if([temp isEqualToString:@"Red"])
            i.tagColor = RED;
        else if([temp isEqualToString:@"Yellow"])
            i.tagColor = YELLOW;
        else if([temp isEqualToString:@"Green"])
            i.tagColor = GREEN;
        else if([temp isEqualToString:@"Orange"])
            i.tagColor = ORANGE;
        else if([temp isEqualToString:@"Blue"])
            i.tagColor = BLUE;
        else
            i.tagColor = MULTI;
	}
//    else if(storingData && [elementName isEqualToString:@"notes"]){
//        if (processingDetailedCartonContent)
//            cartonContentItem.comments = temp;
//        else
//            invitem.comments = temp;
//	}
    else if (storingData && subnode == INV_PARSER_DAMAGE && [elementName isEqualToString:@"process_type"])
    {
        if (processingDetailedCartonContent)
            currentCondy.damageType = DAMAGE_LOADING;
        else
        {
            if (temp == nil || [temp isEqualToString:@""] || [temp isEqualToString:@"Loading"])
                currentCondy.damageType = DAMAGE_LOADING;
            else if ([temp isEqualToString:@"Unloading"])
                currentCondy.damageType = DAMAGE_UNLOADING;
            else if ([temp isEqualToString:@"Rider"])
                currentCondy.damageType = DAMAGE_RIDER;
        }
    }
    else if(subnode == INV_PARSER_DAMAGE && [elementName isEqualToString:@"inventory_damage"]){
        if (processingDetailedCartonContent)
            [cartonContentItem.damageDetails addObject:currentCondy];
        else
            [invitem.damageDetails addObject:currentCondy];
        
        subnode = INV_PARSER_NONE;
	}
    else if(storingData && [elementName isEqualToString:@"descriptive_symbols"]){
        subnode = INV_PARSER_NONE;
	}
    else if(subnode == INV_PARSER_CARTON_CONTENTS && [elementName isEqualToString:@"description"]){
        
        BOOL found = false;
        for (PVOCartonContent *content in allCartonContents) {
            if([content.description isEqualToString:temp])
            {
                cartonContentItem.cartonContentID = content.contentID;
                found = true;
                break;
            }
        }
        
        if(!found)
        {
            //for performance leaving this broken out - alternative is to make this all a db function, so for each hit here, trip to db would be required
            PVOCartonContent *content = [[PVOCartonContent alloc] init];
            content.contentID = [del.surveyDB getPVONextCartonContentID];
            content.description = temp;
            [del.surveyDB savePVOCartonContent:content withCustomerID:-1];
            allCartonContents = [del.surveyDB getPVOAllCartonContents];
            
            //loop again
            for (PVOCartonContent *content in allCartonContents) {
                if([content.description isEqualToString:temp])
                    cartonContentItem.cartonContentID = content.contentID;
            }
        }
	}
    else if(storingData && [elementName isEqualToString:@"cost"]){
        PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
        if (temp != nil && ![temp isEqualToString:@""])
            i.highValueCost = [temp doubleValue];
	}
    else if (storingData && [elementName isEqualToString:@"length"]){
        if (temp != nil)
        {
            PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
            i.length = [temp intValue];
            //i.hasDimensions = (invitem.hasDimensions || invitem.length > 0);
        }
    }
    else if (storingData && [elementName isEqualToString:@"width"]){
        if (temp != nil)
        {
            PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
            i.width = [temp intValue];
            //i.hasDimensions = (invitem.hasDimensions || invitem.width > 0);
        }
    }
    else if (storingData && [elementName isEqualToString:@"height"]){
        if (temp != nil)
        {
            PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
            i.height = [temp intValue];
            //i.hasDimensions = (invitem.hasDimensions || invitem.height > 0);
        }
    }
    else if (storingData && [elementName isEqualToString:@"dimension_unit_type"]){
        if (temp != nil)
        {
            PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
            i.dimensionUnitType = [temp intValue];
        }
    }
    else if (storingData && [elementName isEqualToString:@"has_dimensions"]){
        PVOItemDetailExtended *i = (processingDetailedCartonContent ? cartonContentItem : invitem);
        i.hasDimensions = (i.hasDimensions || (temp != nil && [temp isEqualToString:@"true"]));
    }
    else if (storingData && [elementName isEqualToString:@"cube"]) {
        if (temp != nil)
        {
            invitem.cube = [temp doubleValue];
        }
    }
    else if (storingData && [elementName isEqualToString:@"weight"]) {
        if (temp != nil)
        {
            invitem.weight = [temp intValue];
        }
    }
    else if (storingData && [elementName isEqualToString:@"weight_type"]) {
        if (temp != nil)
        {
            invitem.weightType = [temp intValue];
        }
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
//    NSLog([NSString stringWithFormat:@"%@", parseError.localizedDescription]);
    NSLog(@"%@", parseError.localizedDescription);
}


@end
