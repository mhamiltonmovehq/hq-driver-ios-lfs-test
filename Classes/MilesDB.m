//
//  MilesDB.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MilesDB.h"
#import "SurveyAppDelegate.h"

@implementation MilesDB

#pragma mark General DB Methods

-(id)init
{
    
    if(self = [super init])
    {
        db = NULL;
    }
    
    return self;
}

-(NSString*)fullDBPath
{
    return [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:MILES_DB_NAME];
}


-(void)deleteDB
{    
    [self closeDB];
    
    //check if file exists.  if so, delete it
    NSFileManager *mgr = [NSFileManager defaultManager];
    if([mgr fileExistsAtPath:[self fullDBPath]])
    {
        [mgr removeItemAtPath:[self fullDBPath] error:nil];
    }
}

-(BOOL)openDB
{    
    //check if file exists.  if not, create it.
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:[self fullDBPath]])
        return FALSE;//[self createDatabase];
    
    if(sqlite3_open([[self fullDBPath] UTF8String], &db) != SQLITE_OK)
    {
        sqlite3_close(db);
        db = nil;
        return FALSE;
    }
    
    return TRUE;
}


-(BOOL)createDatabase
{
    
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:MILES_DB_NAME];
    
    // copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MILES_DB_NAME];
    
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    return success;
}

-(BOOL) updateDB: (NSString*)cmd
{
    BOOL success = YES;
    char* err;
    
    if(sqlite3_exec(db, [cmd UTF8String], NULL, NULL, &err) != SQLITE_OK)
    {
        goto error;
    }
    
    goto success;
    
error:
    
    [SurveyAppDelegate showAlert:[NSString stringWithFormat: @"%s", err] withTitle:@"Error updating database"];
    
    success = NO;
    
success:
    
    return success;
}

-(void)closeDB
{
    if(db != nil)
    {
        sqlite3_close(db);
        db = nil;
    }
}

-(BOOL)prepareStatement:(NSString*)cmd withStatement:(sqlite3_stmt**)stmnt
{
    NSInteger retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, stmnt, nil);
    if(retval != SQLITE_OK)
    {
        NSString *error = [[NSString alloc] initWithFormat:@"Unable to prepare SQLite statement.  Error code %ld, statement %@", (long)retval, cmd];
        [SurveyAppDelegate showAlert:error withTitle:@"SQLite error"];
    }
    
    return retval == SQLITE_OK;
}


-(BOOL)tableExists:(NSString*)table
{
    sqlite3_stmt *stmnt;
    BOOL found = FALSE;
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ LIMIT 1", table];
    
    NSInteger retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, &stmnt, nil);
    found = retval == SQLITE_OK;
    sqlite3_finalize(stmnt);
    
    
    return found;
}

-(BOOL)columnExists:(NSString*)column inTable:(NSString*)table
{
    sqlite3_stmt *stmnt;
    BOOL found = FALSE;
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@ LIMIT 1", column, table];
    
    NSInteger retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, &stmnt, nil);
    found = retval == SQLITE_OK;
    sqlite3_finalize(stmnt);    
    
    
    return found;
}

-(double)getDoubleValueFromQuery:(NSString*)cmd
{
    double retval = 0;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = sqlite3_column_double(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)getIntValueFromQuery:(NSString*)cmd
{
    int retval = 0;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}


-(void)dealloc
{
    [self closeDB];
    
}

#pragma mark mileage retrieval functions

-(int)getZipPlace:(NSString*)zip
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT Place FROM ZipMiles WHERE Zip3 like '%%%@%%'",
                     [zip substringToIndex:3]];
    int retval = 0;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;    
}

-(int)getMileageBetweenTwoPoints:(int)place1 withPlaceTwo:(int)place2
{
    int difference = 0;
    
    if(place1 == place2)
        return 10;
    
    if(place1 > place2)
    {
        difference = place1 - place2;
        return [self getMileage:place2 withDifference:difference];
    }
    else
    {
        difference = place2 - place1;
        return [self getMileage:place1 withDifference:difference];
    }
}

-(int)getMileage:(int)place withDifference:(int)difference
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT Miles FROM ZipMiles WHERE Place = %d", place];
    sqlite3_stmt *stmnt;
    NSString *miles = nil;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            miles = [[NSString alloc] initWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)];
        }
    }
    sqlite3_finalize(stmnt);
    
    if(miles == nil)
        return 0;
    
    NSArray *split = [miles componentsSeparatedByString:@","];
    
    
    return [[split objectAtIndex:difference-1] intValue];
}


#pragma mark state/county - deprecated, moved to pricing db

-(NSArray*)getStates
{
    NSString *cmd = @"SELECT Abbr FROM States ORDER BY Abbr ASC";
    
    sqlite3_stmt *stmnt;
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [arr addObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return arr;
}

-(NSArray*)getCounties:(NSString*)state
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT c.County "
                     "FROM States s, Counties c "
                     "WHERE s.Abbr = '%@' AND s.Num = c.State "
                     "ORDER BY c.County ASC", state];
    
    sqlite3_stmt *stmnt;
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [arr addObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return arr;
}

-(int)getServiceArea:(NSString*)state withCounty:(NSString*)county
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT c.ServiceArea "
                     "FROM States s, Counties c "
                     "WHERE s.Abbr = '%@' AND c.County = '%@' AND s.Num = c.State ", state, county];
    
    return [self getIntValueFromQuery:cmd];
}

@end
