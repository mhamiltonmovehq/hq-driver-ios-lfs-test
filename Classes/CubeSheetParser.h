//
//  CubeSheetParser.h
//  Survey
//
//  Created by Tony Brame on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SurveyedItem.h"
#import "Room.h"
#import "CrateDimensions.h"
#import "CubeSheet.h"

@class SurveyAppDelegate;

@interface CubeSheetParser : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentString;
	NSMutableArray *entries;
	BOOL storingData;
    Room *currentRoom;
    SurveyedItem *si;
    Item *item;
    BOOL inRoom;
    
    //key is the room id
    NSMutableDictionary *roomImages;
    
    int currentRoomImageID;
    
    id<NSXMLParserDelegate> parent;
}

@property (nonatomic, retain) Room *currentRoom;
@property (nonatomic, retain) NSMutableArray *entries;
@property (nonatomic, retain) NSMutableString *currentString;
@property (nonatomic, retain) NSMutableDictionary *roomImages;
@property (nonatomic, retain) id<NSXMLParserDelegate> parent;
@property (nonatomic, assign) SurveyAppDelegate *appDelegate;

-(id)initWithAppDelegate:(SurveyAppDelegate *)del;

@end
