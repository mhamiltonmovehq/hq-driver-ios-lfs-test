//
//  Room.m
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Room.h"


@implementation Room

@synthesize roomID, roomName, CNItemCode;

+(NSMutableDictionary*) getDictionaryFromRoomList: (NSArray*)rooms
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSString *key;
    Room *current;
    unichar currentletter = 0;
    unichar compareletter = 0;
    NSMutableArray *currentRooms = nil;
    
    for(int i = 0; i < [rooms count]; i++)
    {
        current = [rooms objectAtIndex:i];
        compareletter = [current.roomName characterAtIndex:0];
        if(compareletter<=122 && compareletter >= 97)
            compareletter -= 32;
        
        if(currentletter != compareletter)
        {//new room
            if(currentletter != 0)
            {
                key = [[NSString alloc] initWithFormat:@"%c", currentletter];
                [retval setObject:currentRooms forKey:key];
            }
            
            currentletter = compareletter;
            currentRooms = [[NSMutableArray alloc] init];
        }
        [currentRooms addObject:current];
    }
    
    if([currentRooms count] > 0)
    {
        key = [[NSString alloc] initWithFormat:@"%c", currentletter];
        [retval setObject:currentRooms forKey:key];
    }
    
    
    return retval;
}


@end
