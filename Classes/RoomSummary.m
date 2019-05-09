//
//  RoomSummary.m
//  Survey
//
//  Created by Tony Brame on 6/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RoomSummary.h"


@implementation RoomSummary

@synthesize room, shipping, notShipping, cube, weight;

+(RoomSummary*)totalRoomSummary:(NSArray*)rooms
{
	RoomSummary *retval = [[RoomSummary alloc] init];
	
	retval.room = [[Room alloc] init];
	retval.room.roomName = @"ALL ITEMS SUMMARY";
	
	RoomSummary *current;
	for(int i = 0; i < [rooms count]; i++)
	{
		current = [rooms objectAtIndex:i];
		retval.shipping += current.shipping;
		retval.notShipping += current.notShipping;
		retval.weight += current.weight;
		retval.cube += current.cube;
	}
	
	return retval;
}


@end
