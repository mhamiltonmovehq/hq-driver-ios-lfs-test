//
//  RoomSurveyedItems.h
//  Survey
//
//  Created by Tony Brame on 6/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"Room.h"
#import	"SurveyedItemsList.h"

@interface RoomSurveyedItems : NSObject {
	Room *room;
	SurveyedItemsList *surveyedItems;
}

@property (nonatomic, retain) SurveyedItemsList *surveyedItems;
@property (nonatomic, retain) Room *room;

@end
