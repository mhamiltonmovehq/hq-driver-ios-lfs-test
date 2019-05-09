//
//  PVOInventoryParser.h
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Room.h"
#import "SurveyedItem.h"
#import "Item.h"
#import "PVOItemDetailExtended.h"
#import "PVOConditionEntry.h"

#define INV_PARSER_NONE 0
#define INV_PARSER_CARTON_CONTENTS 1
#define INV_PARSER_DAMAGE 2
#define INV_PARSER_DESCRIPTIVE 3

@interface PVOInventoryParser : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentString;
	NSMutableArray *entries;
	BOOL storingData;
    Room *currentRoom;
    PVOItemDetailExtended *invitem;
    Item *item;
    BOOL inRoom;
    
    //key is the room id
    NSMutableDictionary *roomImages;
    
    int currentRoomImageID;
    
    id<NSXMLParserDelegate> parent;
    
    int subnode;
    
    PVOConditionEntry *currentCondy;
    
    NSArray *allCartonContents;
    
    BOOL inInventory;
    
    int receivedType;
    int receivedUnloadType;
    int loadType;
    int mproWeight;
    int sproWeight;
    int consWeight;
    int receivedFromType;
    
    BOOL processingDetailedCartonContent;
    PVOItemDetailExtended *cartonContentItem;
    
}

@property (nonatomic, retain) Room *currentRoom;
@property (nonatomic, retain) NSMutableArray *entries;
@property (nonatomic, retain) NSMutableString *currentString;
@property (nonatomic, retain) NSMutableDictionary *roomImages;
@property (nonatomic, retain) id<NSXMLParserDelegate> parent;

@property (nonatomic) int receivedType;
@property (nonatomic) int receivedUnloadType;
@property (nonatomic) int loadType;
@property (nonatomic) int mproWeight;
@property (nonatomic) int sproWeight;
@property (nonatomic) int consWeight;
@property (nonatomic) int receivedFromType;

@end
