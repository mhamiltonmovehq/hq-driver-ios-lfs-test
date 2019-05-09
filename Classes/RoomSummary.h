//
//  RoomSummary.h
//  Survey
//
//  Created by Tony Brame on 6/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Room.h"

@interface RoomSummary : NSObject {
	Room *room;
	int shipping;
	int notShipping;
	double cube;
	double weight;
}

@property (nonatomic) double weight;
@property (nonatomic) int shipping;
@property (nonatomic) int notShipping;
@property (nonatomic) double cube;
@property (nonatomic, retain) Room *room;

+(RoomSummary*)totalRoomSummary:(NSArray*)rooms;

@end
