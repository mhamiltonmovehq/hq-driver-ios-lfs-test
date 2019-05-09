//
//  SurveyedItemsList.h
//  Survey
//
//  Created by Tony Brame on 6/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"
#import "Room.h"

@interface SurveyedItemsList: NSObject {
	NSMutableDictionary *list;
	Room *room;
	BOOL itemsFilled;
}

@property (nonatomic, retain) NSMutableDictionary *list;
@property (nonatomic, retain) Room *room;

-(int)totalShipping;
-(int)totalNotShipping;
-(int)totalPacking;
-(int)totalUnpacking;
-(double)totalCube;
-(double)totalWeight:(double)weightFactor;
-(NSMutableArray*)getBulkies;
-(void)fillItems;
-(void)fillItems:(NSArray*)items;

-(void)flushToXML:(XMLWriter*)xml materialHandling:(int)handleType;

@end
