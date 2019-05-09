//
//  MilesDB.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <sqlite3.h>

#define MILES_DB_NAME @"Miles.sqlite3"

@interface MilesDB : NSObject {
	sqlite3	*db;
}

-(BOOL)openDB;
-(void)deleteDB;
-(NSString*)fullDBPath;
-(void)closeDB;
-(BOOL) updateDB: (NSString*)cmd;
-(BOOL)prepareStatement:(NSString*)cmd withStatement:(sqlite3_stmt**)stmnt;
-(BOOL)tableExists:(NSString*)table;
-(BOOL)columnExists:(NSString*)column inTable:(NSString*)table;
-(double)getDoubleValueFromQuery:(NSString*)cmd;
-(int)getIntValueFromQuery:(NSString*)cmd;

//mileage functions
-(int)getZipPlace:(NSString*)zip;
-(int)getMileageBetweenTwoPoints:(int)place1 withPlaceTwo:(int)place2;
-(int)getMileage:(int)place withDifference:(int)difference;

//state/county
-(NSArray*)getStates;
-(NSArray*)getCounties:(NSString*)state;
-(int)getServiceArea:(NSString*)state withCounty:(NSString*)county;

@end