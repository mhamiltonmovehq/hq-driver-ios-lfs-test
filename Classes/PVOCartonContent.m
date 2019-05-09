//
//  PVOCartonContent.m
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOCartonContent.h"


@implementation PVOCartonContent

@synthesize description, contentID, cartonContentID, pvoItemID;

+(NSMutableDictionary*) getDictionaryFromContentList: (NSArray*)items
{
	NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
	
	NSString *key;
	PVOCartonContent *current;
	unichar currentletter = 0, compareletter;
	
	NSMutableArray *currentItems = nil;
	
	for(int i = 0; i < [items count]; i++)
	{
		current = [items objectAtIndex:i];
		compareletter = [current.description characterAtIndex:0]; 
		
		if(compareletter >= 97)//it is lower case, make it upper.
			compareletter -= 32;
		
		
		if(currentletter != compareletter &&
           ((currentletter <= 48 || currentletter >= 57) ||
            (compareletter <= 48 || compareletter >= 57)))//if they dont equal, and either are not numeric
		{//new letter
			if(currentletter != 0)
			{
				if(currentletter >= 48 && currentletter <= 57)
					key = @"#";
				else
					key = [[NSString alloc] initWithFormat:@"%c", currentletter];
				
				[retval setObject:currentItems forKey:key];
			}
			
			currentletter = [current.description characterAtIndex:0];
			if(currentletter >= 97)//it is lower case, make it upper.
				currentletter -= 32;
			
			currentItems = [[NSMutableArray alloc] init];
		}
		[currentItems addObject:current];
	}
	
	if(currentItems != nil)
	{
		if([currentItems count] > 0)
		{
			key = [[NSString alloc] initWithFormat:@"%c", currentletter];
			[retval setObject:currentItems forKey:key];
		}
		
	}
	
	return retval;
}

@end
