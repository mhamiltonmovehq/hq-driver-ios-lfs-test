//
//  CustomerFilterOptions.h
//  Survey
//
//  Created by Tony Brame on 10/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SORT_BY_NAME 1
#define SORT_BY_DATE 2
#define SORT_BY_ORDER_NUMBER 3

#define SHOW_ORDER_NUMBER 1
#define SHOW_DATE_SURVEY 2
#define SHOW_DATE_PACK 3
#define SHOW_DATE_LOAD 4
#define SHOW_DATE_DELIVER 5
#define SHOW_DATE_FOLLOWUP 6
#define SHOW_DATE_DECISION 7

#define SHOW_STATUS_ALL 1
#define SHOW_STATUS_ESTIMATE 2
#define SHOW_STATUS_BOOKED 3
#define SHOW_STATUS_LOST 4
#define SHOW_STATUS_CLOSED 5
#define SHOW_STATUS_OA 6

@interface CustomerFilterOptions : NSObject {
	int sortBy;
	int dateFilter;
	int statusFilter;
	NSDate* date;
}

@property (nonatomic) int sortBy;
@property (nonatomic) int dateFilter;
@property (nonatomic) int statusFilter;

@property (nonatomic, retain) NSDate* date;

-(NSString*)currentFilterString;

@end
