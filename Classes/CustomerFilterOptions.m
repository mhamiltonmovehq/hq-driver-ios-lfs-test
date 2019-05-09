//
//  CustomerFilterOptions.m
//  Survey
//
//  Created by Tony Brame on 10/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CustomerFilterOptions.h"


@implementation CustomerFilterOptions

@synthesize sortBy;
@synthesize dateFilter;
@synthesize statusFilter;
@synthesize date;

-(NSString*)currentFilterString
{
	
	NSMutableString *str = [[NSMutableString alloc] initWithString:@"Sorted by "];
	
	switch (sortBy) {
		case SORT_BY_NAME:
			[str appendString:@"Name, "];
			break;
		case SORT_BY_DATE:
			[str appendString:@"Date, "];
			break;
	}
	
	[str appendString:@"showing "];
	
	switch (dateFilter) {
		case SHOW_DATE_SURVEY:
			[str appendString:@"Survey"];
			break;
		case SHOW_DATE_PACK:
			[str appendString:@"Packing"];
			break;
		case SHOW_DATE_LOAD:
			[str appendString:@"Loading"];
			break;
		case SHOW_DATE_DELIVER:
			[str appendString:@"Delivery"];
			break;
		case SHOW_DATE_FOLLOWUP:
			[str appendString:@"Follow Up"];
			break;
		case SHOW_DATE_DECISION:
			[str appendString:@"Decision"];
			break;
	}
	
	[str appendString:@" date, and "];
	
	switch (statusFilter) {
		case SHOW_STATUS_ALL:
			[str appendString:@" All Statuses"];
			break;
		case SHOW_STATUS_ESTIMATE:
			[str appendString:@" Estimate Statuses"];
			break;
		case SHOW_STATUS_BOOKED:
			[str appendString:@" Booked Statuses"];
			break;
		case SHOW_STATUS_LOST:
			[str appendString:@" Lost Statuses"];
			break;
		case SHOW_STATUS_CLOSED:
			[str appendString:@" Closed Statuses"];
			break;
		case SHOW_STATUS_OA:
			[str appendString:@" OA Statuses"];
			break;
	}
	
	
	return str;
}

@end
