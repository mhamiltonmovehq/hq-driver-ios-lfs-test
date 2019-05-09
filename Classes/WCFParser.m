//
//  WCFParser.m
//  Survey
//
//  Created by Tony Brame on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WCFParser.h"


@implementation WCFParser


//standard WCF format (2011-04-26T20:57:59.13)
+(NSDate*)dateFromString:(NSString*)datestring
{
    if(datestring == nil || [datestring isEqualToString:@""])
        return nil;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //format, 2011-04-26T20:57:59.13   yyyy-MM-ddTHH:mm:ss.SS
    //i've also seen 2011-04-26T20:57:59 - handle both
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    if([datestring rangeOfString:@"."].location != NSNotFound)
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SS"];
    else
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    //NSRange tLoc = [datestring rangeOfString:@"T"];
    NSDate *date = [dateFormatter dateFromString:datestring];
    /*[dateFormatter setDateFormat:@"HH:mm:ss.SS"];
     NSDate *time = [dateFormatter dateFromString:[datestring substringFromIndex:tLoc.location + 1]];*/
    return date;// [date dateByAddingTimeInterval:[time timeIntervalSince1970]];
}

+(NSString*)stringFromDate:(NSDate*)date
{
    if(date == nil || [date timeIntervalSince1970] == 0)
        return nil;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //format, 2011-04-26T20:57:59.13   yyyy-MM-ddTHH:mm:ss.SS
    //i've also seen 2011-04-26T20:57:59 - handle both
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    return [dateFormatter stringFromDate:date];
}


//issue is that wcf elelemtns have a namespace prefix.
//i.e. node "ItemList" could be in the xml as "a:ItemList"
//this method ensures that regardless of the prefix, this is the correct element

//we can't just check that the string exists,
//because if the element name was "ItemListName", it would return true for element "ItemList"
-(BOOL)thisElement:(NSString*)myElementName isElement:(NSString*)targetElementName
{
	NSRange rangeOfString = [myElementName rangeOfString:[@":" stringByAppendingString:targetElementName]];
	
	if(rangeOfString.location != NSNotFound)
	{
		//ensure what it found is the last characters of the string...
		return rangeOfString.location + rangeOfString.length == [myElementName length];
	}
	
	return FALSE;
}



@end
