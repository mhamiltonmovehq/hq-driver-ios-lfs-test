//
//  PVOConditions.m
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOConditions.h"


@implementation PVOConditions

@synthesize code, description;

+(NSDictionary*)getConditionList
{
	return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Bent",@"Broken",@"Burned",@"Chipped",@"Dented",@"Faded",@"Gouged",@"Loose",@"Marred",@"Mildew",@"Motheaten",@"Peeling",@"Rubbed",@"Rusted",@"Scratched",@"Short",@"Soiled",@"Stained",@"Stretched",@"Torn",@"Badly Worn",@"Cracked",nil] 
									   forKeys:[NSArray arrayWithObjects:@"BE",@"BR",@"BU",@"CH",@"D",@"F",@"G",@"L",@"M",@"MI",@"MO",@"P",@"R",@"RU",@"SC",@"SH",@"SO",@"ST",@"S",@"T",@"W",@"Z",nil]];
	
}

+(NSDictionary*)getLocationList
{
	return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Arm",@"Bottom",@"Corner",@"Front",@"Left",@"Leg",@"Rear",@"Right",@"Side",@"Top",@"Veneer",@"Edge",@"Center",@"Inside",@"Seat",@"Drawer",@"Door",@"Shelf",@"Hardware",nil]
									   forKeys:[NSArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",@"18",@"19",nil]];
	
}

@end
