
//
//  SurveyDB.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyDB.h"
#import	"CustomerListItem.h"
#import "SurveyCustomer.h"
#import "SurveyLocation.h"
#import "SurveyPhone.h"
#import	"SurveyAppDelegate.h"
#import "Room.h"
#import "Item.h"
#import "SurveyedItem.h"
#import "CubeSheet.h"
#import	"SurveyedItemsList.h"
#import	"RoomSummary.h"
#import "CrateDimensions.h"
#import "SurveyAgent.h"
#import "SurveyImage.h"
#import "Prefs.h"
#import "CustomerUtilities.h"
#import "SurveyDBUpdater.h"
#import "PVOConditionEntry.h"
#import "AppFunctionality.h"
#import "PVODynamicReportData.h"
#import "PVOReportNote.h"
#import "PVOVehicle.h"
#import "PVOCheckListItem.h"
#import "PVOBulkyData.h"
#import "PVOBulkyInventoryItem.h"
#import "PVONavigationListItem.h"
#import "PVOSTGBOL.h"
#import "PVOSTGBOLParser.h"

@implementation SurveyDB

//@synthesize custID;
@synthesize runningOnSeparateThread;

#pragma mark General DB Methods


-(id)initDB:(int)vlID
{
    
    if((self = [super init]))
    {
        [self openDB:vlID];
    }
    
    return self;
}

-(sqlite3*)dbReference
{
    return db;
}

-(NSString*)fullDBPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    return [docsDir stringByAppendingPathComponent:SURVEY_DB_NAME];
}


-(void)openDB:(int)vlID
{
    //check if file exists.  if not, create it.
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:[self fullDBPath]])
        [self createDatabase];//copy default database to the docs dir
    
    sqlite3_shutdown();
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    sqlite3_initialize();
    if(sqlite3_open_v2([[self fullDBPath] UTF8String], &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK)
    {
        sqlite3_close(db);
        db = nil;
        NSAssert(0, @"Falied to open survey database");
    }
    //	else
    //	{
    //        [self updateDB:@"PRAGMA foreign_keys=ON"];
    //
    //		[self upgradeDB:vlID];
    //	}
}

-(BOOL) updateDB: (NSString*)cmd
{
#if defined(SHOW_SQL_STATEMENTS)
    NSLog(@"SQL updateDB: %@", cmd);
#endif
    
    BOOL success = YES;
    char* err;
    
    if(sqlite3_exec(db, [cmd UTF8String], NULL, NULL, &err) != SQLITE_OK)
    {
        NSLog(@"SQL updateDB error: %s", sqlite3_errmsg(db));
        [SurveyAppDelegate showAlert:[NSString stringWithFormat: @"%s\r\nCMD: %@", err, cmd]
                           withTitle:@"Error updating database" withDelegate:nil onSeparateThread:runningOnSeparateThread];
        success = NO;
    }
    
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

-(void)dealloc
{
    [self closeDB];
}

-(BOOL)prepareStatement:(NSString*)cmd withStatement:(sqlite3_stmt**)stmnt
{
#if defined(SHOW_SQL_STATEMENTS)
    NSLog(@"SQL prepareStatement: %@", cmd);
#endif
    
    int retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, stmnt, nil);
    if(retval != SQLITE_OK)
    {
        NSLog(@"SQL prepareStatement error: %s", sqlite3_errmsg(db));
        NSString *error = [[NSString alloc] initWithFormat:@"Unable to prepare SQLite statement.  Error code %d, statement %@", retval, cmd];
        [SurveyAppDelegate showAlert:error withTitle:@"SQLite error" withDelegate:nil onSeparateThread:runningOnSeparateThread];
    }
    
    return retval == SQLITE_OK;
}

-(BOOL)tableExists:(NSString*)table
{
    sqlite3_stmt *stmnt;
    BOOL found = FALSE;
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ LIMIT 1", table];
    
    int retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, &stmnt, nil);
    found = retval == SQLITE_OK;
    sqlite3_finalize(stmnt);
    
    return found;
}

-(BOOL)columnExists:(NSString*)column inTable:(NSString*)table
{
    sqlite3_stmt *stmnt;
    BOOL found = FALSE;
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@ LIMIT 1", column, table];
    
    int retval = sqlite3_prepare_v2(db, [cmd UTF8String], -1, &stmnt, nil);
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
            if (sqlite3_column_type(stmnt, 0) != SQLITE_NULL)
                retval = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)getStringValueFromQuery:(NSString*)cmd
{
    NSString *retval = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            const char *temp = (const char *)sqlite3_column_text(stmnt, 0);
            
            if(temp != NULL)
                retval = [[NSString alloc] initWithUTF8String:temp];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)prepareStringForInsert:(NSString*)src
{
    return [self prepareStringForInsert:src supportsNull:NO];
}

-(NSString*)prepareStringForInsert:(NSString*)src supportsNull:(BOOL)nullable
{
    if(nullable && (src == nil || [src length] == 0))
        return @"NULL";
    else
    {
        if(src == nil)
            return @"''";
        else
            return [NSString stringWithFormat:@"'%@'", [src stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
}

+(NSString*)stringFromStatement:(sqlite3_stmt*)stmnt columnID:(int)column
{
    const unsigned char* temp = sqlite3_column_text(stmnt, column);
    if(temp != NULL)
        return [NSString stringWithUTF8String:(const char*)temp];
    else
        return nil;
}

-(void)flushCommandsFromFile:(NSString*)filename
{
    NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    //    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:fullPath];
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *cmd in lines) {
        [self updateDB:cmd];
    }
}

-(NSMutableArray*)getItemsForV10Upgrade
{
    @synchronized(self)
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        Item *item;
        
        sqlite3_stmt *stmnt;
        
        NSString *cmd = @"SELECT i.ItemID,i.ItemName,i.IsCartonCP,i.IsCartonPBO,i.IsCrate,i.IsBulky,i.Cube,i.CartonBulkyID"
        " FROM Items i "
        " WHERE Hidden != 1 "
        "ORDER BY i.ItemName COLLATE NOCASE ASC";
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                item = [[Item alloc] init];
                
                item.itemID = sqlite3_column_int(stmnt, 0);
                item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
                item.isCP = sqlite3_column_int(stmnt, 2);
                item.isPBO = sqlite3_column_int(stmnt, 3);
                item.isCrate = sqlite3_column_int(stmnt, 4);
                item.isBulky = sqlite3_column_int(stmnt, 5);
                item.cube = sqlite3_column_double(stmnt, 6);
                item.cartonBulkyID = sqlite3_column_int(stmnt, 7);
                
                [array addObject:item];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return array;
    }
}

-(NSMutableArray*)getRoomsForV10Upgrade
{
    
    @synchronized(self)
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        Room *item;
        
        sqlite3_stmt *stmnt;
        
        NSString *cmd = @"SELECT RoomID,RoomName FROM Rooms WHERE Hidden != 1 ORDER BY RoomName COLLATE NOCASE ASC";
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                item = [[Room alloc] init];
                
                item.roomID = sqlite3_column_int(stmnt, 0);
                item.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
                
                [array addObject:item];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return array;
    }
}

-(void)upgradeDBWithDelegate:(id)delegate forVanline:(int)vlid
{
    SurveyDBUpdater *updater = [[SurveyDBUpdater alloc] init];
    updater.db = self;
    updater.delegate = delegate;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.operationQueue addOperation:updater];
    
}

-(void)upgradeDBForVanline:(int)vlid
{
    int maj, min;
    sqlite3_stmt *stmnt;
    NSString *cmd = @"SELECT Major,Minor FROM Versions";
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            maj = sqlite3_column_int(stmnt, 0);
            min = sqlite3_column_int(stmnt, 1);
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if(vlid == ARPIN)
    {
        //        if(min < 1)
        //        {//MARK: ARPIN version 1 (PVO items list Arpin update) update
        //
        //            [self flushCommandsFromFile:@"update_arpin_item_list.sql"];
        //
        //            [self updateDB:@"UPDATE Versions SET Minor = 1"];
        //        }
        
        if(min < 2)
        {//MARK: ARPIN version 2 add documents to library
            
            NSFileManager *mgr = [NSFileManager defaultManager];
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            DocLibraryEntry *libEntry = nil;
            
            for (int i = 0; i < 23; i++) {
                libEntry = [[DocLibraryEntry alloc] init];
                
                
                
                libEntry.docEntryType = DOC_LIB_TYPE_GLOBAL;
                
                for(int i = 0; true; i++)
                {
                    libEntry.docPath = [NSString stringWithFormat:@"%@/%@", DOC_LIB_FOLDER, [NSString stringWithFormat:DOC_LIB_FILENAME, i]];
                    if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:libEntry.docPath]])
                        break;
                }
                
                if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]])
                    [mgr createDirectoryAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:nil];
                
                switch (i) {
                    case 0:
                        libEntry.docName = @"High Value Inventory";
                        break;
                    case 1:
                        libEntry.docName = @"MIL DD Form 619-1";
                        break;
                    case 2:
                        libEntry.docName = @"MIL DD Form 619";
                        break;
                    case 3:
                        libEntry.docName = @"MIL High Risk/HVI";
                        break;
                    case 4:
                        libEntry.docName = @"MIL Loss/Damage after Delivery";
                        break;
                    case 5:
                        libEntry.docName = @"MIL Loss/Damage at Delivery";
                        break;
                    case 6:
                        libEntry.docName = @"Packing Damage Report";
                        break;
                    case 7:
                        libEntry.docName = @"Parts/Hardware Inventory";
                        break;
                    case 8:
                        libEntry.docName = @"Piano Condition Report";
                        break;
                    case 9:
                        libEntry.docName = @"Priority/Items Of Concern";
                        break;
                    case 10:
                        libEntry.docName = @"Inventory Bingo Sheet";
                        break;
                    case 11:
                        libEntry.docName = @"Accessorial Services Performed";
                        break;
                    case 12:
                        libEntry.docName = @"Pre Existing Conditions";
                        break;
                    case 13:
                        libEntry.docName = @"Gypsy Moth Checklist";
                        break;
                    case 14:
                        libEntry.docName = @"Final Walkthrough Packing Confirmation";
                        break;
                    case 15:
                        libEntry.docName = @"Final Walkthrough Loading Confirmation";
                        break;
                    case 16:
                        libEntry.docName = @"Final Walkthrough Delivery Confirmation";
                        break;
                    case 17:
                        libEntry.docName = @"Motor Vehicle Inventory";
                        break;
                    case 18:
                        libEntry.docName = @"Contract Labor Receipt";
                        break;
                    case 19:
                        libEntry.docName = @"Delivery Report";
                        break;
                    case 20:
                        libEntry.docName = @"Driver Stmnt Services Performed";
                        break;
                    case 21:
                        libEntry.docName = @"Rider To Inventory";
                        break;
                    case 22:
                        libEntry.docName = @"VO Quick Claim Settlement";
                        break;
                }
                NSString *fileName = [[libEntry.docName
                                       stringByReplacingOccurrencesOfString:@" " withString:@""]
                                      stringByReplacingOccurrencesOfString:@"/" withString:@""];
                NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName
                                                                     ofType:@"pdf"];
                [mgr createFileAtPath:[libEntry fullDocPath]
                             contents:[NSData dataWithContentsOfFile:filePath]
                           attributes:nil];
                
                libEntry.url = [NSString stringWithFormat:@"http://www.mobilemover.com/arpinmm/%@.pdf", fileName];
                
                //now save to the database
                libEntry.savedDate = [NSDate date];
                //                [self saveDocLibraryEntry:libEntry withVanline:vlid]; // 1041 OnTime Defect, TODO: activate in 3.0.4
                [self saveDocLibraryEntry:libEntry];
                
            }
            
            
            
            [self updateDB:@"UPDATE Versions SET Minor = 2"];
        }
        
        if(min < 3)
        {//MARK: ARPIN version 3 change urls to mobilemover.com
            
            [self updateDB:@"UPDATE DocumentLibrary SET DocURL = REPLACE(DocURL,'http://www.igcsoftware.com/arpinmm', "
             "'http://www.mobilemover.com/arpinmm') WHERE DocURL LIKE 'http://www.igcsoftware.com/arpinmm%'"];
            
            [self updateDB:@"UPDATE Versions SET Minor = 3"];
        }
        if(min < 4)
        {//MARK: ARPIN version 3 change urls to mobilemover.com
            
            [self updateDB:@"UPDATE DocumentLibrary SET DocName = 'Extraordinary Value Inventory' WHERE DocName LIKE 'High Value Inventory'"];
            
            [self updateDB:@"UPDATE Versions SET Minor = 4"];
        }
        
        if(min < 5)
        {//MARK: ARPIN version 5 add new Mil doc to library
            
            NSFileManager *mgr = [NSFileManager defaultManager];
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            DocLibraryEntry *libEntry = nil;
            
            libEntry = [[DocLibraryEntry alloc] init];
            
            libEntry.docEntryType = DOC_LIB_TYPE_GLOBAL;
            
            for(int i = 0; true; i++)
            {
                libEntry.docPath = [NSString stringWithFormat:@"%@/%@", DOC_LIB_FOLDER, [NSString stringWithFormat:DOC_LIB_FILENAME, i]];
                if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:libEntry.docPath]])
                    break;
            }
            
            if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]])
                [mgr createDirectoryAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
            
            
            libEntry.docName = @"MIL Government Shipping Order"; // 1207 OnTime Defect
            
            NSString *fileName = [[libEntry.docName
                                   stringByReplacingOccurrencesOfString:@" " withString:@""]
                                  stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName
                                                                 ofType:@"pdf"];
            [mgr createFileAtPath:[libEntry fullDocPath]
                         contents:[NSData dataWithContentsOfFile:filePath]
                       attributes:nil];
            
            libEntry.url = [NSString stringWithFormat:@"http://www.mobilemover.com/arpinmm/%@.pdf", fileName];
            
            //now save to the database
            libEntry.savedDate = [NSDate date];
            //                [self saveDocLibraryEntry:libEntry withVanline:vlid]; // 1041 OnTime Defect, TODO: activate in 3.0.4
            [self saveDocLibraryEntry:libEntry];
            
            
            
            
            
            [self updateDB:@"UPDATE Versions SET Minor = 5"];
        }
        
        if(min < 6) {
            // Arpin documents - switch to HTTPS
            [self updateDB:@"UPDATE DocumentLibrary SET DocURL = replace(DocURL, 'http://www.mobilemover.com/arpinmm/', 'https://www.mobilemover.com/arpinmm/');"];
            
            [self updateDB:@"UPDATE Versions SET Minor = 6"];
        }
    }
    
    if(vlid == ATLAS)
    {
        if(min < 1)
        {//MARK: ATLAS version 1 (PVO conditions list Atlas update)
            
            [self updateDB:@"DELETE FROM PVODescriptions WHERE DescriptiveCode = 'BW'"];
            [self updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PBD', 'Particle Board')"];
            [self updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('EU', 'Electrical Condition Unknown')"];
            
            [self updateDB:@"UPDATE Versions SET Minor = 1"];
        }
        
        if(min < 2)
        {//MARK: ATLAS version 2 (Location List Atlas update)
            
            [self updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (8, 'Extra Delivery', 1)"];
            
            [self updateDB:@"UPDATE Versions SET Minor = 2"];
        }
    }
}

#pragma mark Survey specific methods

-(BOOL)createDatabase
{
    
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:SURVEY_DB_NAME];
    
    // copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SURVEY_DB_NAME];
    
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    return success;
}

#define DIVIDER @"=========================================================================================================="

- (void)sanityCheck
{
#ifndef DEBUG
    return;
#endif
    if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"databasesanity"].location == NSNotFound)
    {
        return;
    }

    NSString *cmd;
    NSInteger i;
    NSMutableString *failureString = [NSMutableString string];
    NSString *errorMessage;
    
    cmd = @"select count(*) from (select count(itemlistid), description, cube, languagecode, itemlistid from itemdescription id join items i on i.itemid = id.itemid where i.Hidden = 0 group by description, cube, languagecode, itemlistid having count (description) > 1)";
    i = [self getIntValueFromQuery:cmd];
    if (i > 0)
    {
        errorMessage = @"There are now one or more items in the items table that have matching item list IDs, descriptions, cube values, and language codes.";
        [failureString appendFormat:@"%@\n", DIVIDER];
        [failureString appendFormat:@"Error message: %@\n", errorMessage];
        [failureString appendFormat:@"Query: %@\n", cmd];
        [failureString appendFormat:@"Result: %@\n", @(i)];
        [failureString appendFormat:@"Stack trace: %@\n", [NSThread callStackSymbols]];
        [failureString appendFormat:@"%@\n", DIVIDER];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SurveyAppDelegate showAlert:errorMessage withTitle:@"Item table error"];
        });
    }
    
    if ([failureString length] > 0)
    {
        NSLog(@"%@", failureString);
    }
}

- (BOOL)checkDatabaseIntegrity
{
    NSString *cmd;
    BOOL databaseOK = YES;
    
    if([self tableExists:@"ItemDescription"])
    {
        cmd = @"SELECT Count(*) FROM ItemDescription WHERE ItemID NOT IN (SELECT ItemID from Items)";
        if ([self getIntValueFromQuery:cmd] > 0)
        {
            NSLog(@"Problem");
            databaseOK = NO;
        }
    }
    return databaseOK;
}

#pragma mark - Customer methods

-(NSMutableArray*)getCustomerListByDate:(NSDate*)surveyDate
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    CustomerListItem *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd;
    
    //get a range of seconds for this day, and query against it..
    NSTimeInterval timeseconds = [surveyDate timeIntervalSince1970];
    long seconds = (long)round(timeseconds);
    seconds -= seconds % 86400;
    
    cmd = [NSString stringWithFormat:@"SELECT c.CustomerID,c.LastName,d.Survey FROM Customer c,Dates d "
           " WHERE d.CustomerID = c.CustomerID AND c.Cancelled != 1 AND d.Survey >= %ld AND d.Survey <= %ld",
           seconds, seconds + 86400];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[CustomerListItem alloc] init];
            item.custID = sqlite3_column_int(stmnt, 0);
            item.name = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            item.date = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 2)];
            [array addObject:item];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return array;
}

-(NSMutableArray*)getCustomerList:(CustomerFilterOptions*)filters
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    CustomerListItem *item;
    
    sqlite3_stmt *stmnt;
    
    NSMutableString *cmd;
    
    if(filters == nil)
        cmd  = [NSMutableString stringWithString:@"SELECT c.CustomerID,c.LastName,s.OrderNumber,d.Survey,c.PricingMode FROM Customer c,Dates d,ShipmentInfo s "
                " WHERE d.CustomerID = c.CustomerID AND s.CustomerID = c.CustomerID ORDER BY c.LastName COLLATE NOCASE ASC"];
    else
    {
        
        cmd = [NSMutableString stringWithString:@"SELECT c.CustomerID,c.LastName,s.OrderNumber,"];
        
        //CustomerID,PackFrom,PackTo,LoadFrom,LoadTo,DeliverFrom,DeliverTo,Survey,Decision,FollowUp,NoPack,NoLoad,NoDeliver
        NSString *dateColumn = @"";
        
        switch (filters.dateFilter) {
            case SHOW_DATE_PACK:
                dateColumn = @"d.PackFrom";
                break;
            case SHOW_DATE_LOAD:
                dateColumn = @"d.LoadFrom";
                break;
            case SHOW_DATE_DELIVER:
                dateColumn = @"d.DeliverFrom";
                break;
            case SHOW_DATE_FOLLOWUP:
                dateColumn = @"d.FollowUp";
                break;
            case SHOW_DATE_DECISION:
                dateColumn = @"d.Decision";
                break;
            case SHOW_DATE_SURVEY:
            default:
                dateColumn = @"d.Survey";
                break;
        }
        [cmd appendString:dateColumn];
        
        
        [cmd appendString:@",c.PricingMode FROM Customer c,Dates d,ShipmentInfo s "
         "WHERE d.CustomerID = c.CustomerID AND s.CustomerID = c.CustomerID"];
        
        
        switch (filters.statusFilter) {
            case SHOW_STATUS_ESTIMATE:
                [cmd appendFormat:@" AND s.JobStatus = %d", ESTIMATE];
                break;
            case SHOW_STATUS_BOOKED:
                [cmd appendFormat:@" AND s.JobStatus = %d", BOOKED];
                break;
            case SHOW_STATUS_LOST:
                [cmd appendFormat:@" AND s.JobStatus = %d", LOST];
                break;
            case SHOW_STATUS_CLOSED:
                [cmd appendFormat:@" AND s.JobStatus = %d", CLOSED];
                break;
            case SHOW_STATUS_OA:
                [cmd appendFormat:@" AND s.JobStatus = %d", OA];
                break;
        }
        
        if(filters.date != nil)
        {
            //get a range of seconds for this day, and query against it..
            NSTimeInterval timeseconds = [filters.date timeIntervalSince1970];
            long seconds = (long)round(timeseconds);
            seconds -= seconds % 86400;
            [cmd appendFormat:@" AND %@ >= %ld AND %@ <= %ld", dateColumn, seconds, dateColumn, seconds + 86400];
        }
        
        
        [cmd appendString:@" AND c.Cancelled != 1"];
        
        switch (filters.sortBy) {
            case SORT_BY_NAME:
                [cmd appendString:@" ORDER BY c.LastName COLLATE NOCASE ASC"];
                break;
            case SORT_BY_ORDER_NUMBER:
                [cmd appendString:@" ORDER BY s.OrderNumber COLLATE NOCASE ASC"];
                break;
            case SORT_BY_DATE:
                [cmd appendFormat:@" ORDER BY %@ ASC", dateColumn];
                break;
        }
        
    }
    
    /*if(sortMode == SORT_BY_NAME)
     cmd = @"SELECT c.CustomerID,c.LastName,d.Survey FROM Customer c,Dates d "
     " WHERE d.CustomerID = c.CustomerID AND c.Cancelled != 1 ORDER BY c.LastName ASC";
     else
     cmd = @"SELECT c.CustomerID,c.LastName,d.Survey FROM Customer c,Dates d "
     " WHERE d.CustomerID = c.CustomerID AND c.Cancelled != 1 ORDER BY d.Survey ASC";*/
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[CustomerListItem alloc] init];
            item.custID = sqlite3_column_int(stmnt, 0);
            item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            item.orderNumber = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 2)];
            item.date = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 3)];
            [array addObject:item];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return array;
}

-(SurveyCustomer*)getCustomerByOrderNumber:(NSString*)orderNumber
{
    SurveyCustomer *retval = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd;
    
    if(orderNumber != nil)
    {
        cmd = [[NSString alloc] initWithFormat:@"SELECT CustomerID FROM ShipmentInfo"
               " WHERE OrderNumber = '%@' COLLATE NOCASE", orderNumber];
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            if(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                retval = [self getCustomer:sqlite3_column_int(stmnt, 0)];
            }
        }
        
        sqlite3_finalize(stmnt);
    }
    
    return retval;
}

-(SurveyCustomer*)getCustomerByQMID:(int)qmID
{
    SurveyCustomer *retval = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT CustomerID FROM CustomerSync"
                     " WHERE GeneralSyncID = '%@'", [NSString stringWithFormat:@"%d", qmID]];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [self getCustomer:sqlite3_column_int(stmnt, 0)];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return retval;
    
}

-(void)updateCustomer:(SurveyCustomer*) cust
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Customer SET "
                     "LastName = '%@', "
                     "FirstName = '%@', "
                     "CompanyName = '%@', "
                     "Email = '%@', "
                     "Weight = %d, "
                     "PricingMode = %d, "
                     "Cancelled = %d, "
                     "InventoryType = %d, "
                     "LastSaveToServerDate = '%@' "
                     "WHERE CustomerID = %d",
                     cust.lastName == nil ? @"" : [cust.lastName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.firstName == nil ? @"" : [cust.firstName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.account == nil ? @"" : [cust.account stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.email == nil ? @"" : [cust.email stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.estimatedWeight, cust.pricingMode, cust.cancelled, cust.inventoryType,
                     cust.lastSaveToServerDate == nil ? @"" : [cust.lastSaveToServerDate stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.custID];
    
    [self updateDB:cmd];
    
    
    
}

-(void)updateCustomerPricingMode:(int)custID pricingMode:(enum PRICING_MODE_TYPE)pricingMode
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Customer SET PricingMode = %d WHERE CustomerID = %d", pricingMode, custID];
    [self updateDB:cmd];
    
}

-(int)getItemListIDForPricingMode:(int)pricingModeID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT ItemListID FROM CustomItemLists WHERE PricingModeRestriction = %d", pricingModeID]];
}

-(int)getCustomerItemListID:(int)customerId
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %d", customerId]];
}

-(SurveyCustomerSync*)getCustomerSync:(int)custID
{
    SurveyCustomerSync *sync = [[SurveyCustomerSync alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "CreatedOnDevice,Sync,SyncToQM,GeneralSyncID,AtlasShipmentID,AtlasSurveyID,SyncToPVO "
                     "FROM CustomerSync WHERE CustomerID = %d",
                     custID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            sync.custID = custID;
            sync.createdOnDevice = sqlite3_column_int(stmnt, 0) > 0;
            sync.sync = sqlite3_column_int(stmnt, 1) > 0;
            sync.syncToQM = sqlite3_column_int(stmnt, 2) > 0;
            sync.generalSyncID = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 3)];
            sync.atlasShipID = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 4)];
            sync.atlasSurveyID = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 5)];
            sync.syncToPVO = sqlite3_column_int(stmnt, 6) > 0;
        }
    }
    
    sqlite3_finalize(stmnt);
    
    
    
    return sync;
}

-(void)updateCustomerSync:(SurveyCustomerSync*)sync
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE CustomerSync SET "
                     "CreatedOnDevice = %d, "
                     "Sync = %d, "
                     "SyncToQM = %d, "
                     "SyncToPVO = %d, "
                     "GeneralSyncID = '%@', "
                     "AtlasShipmentID = '%@',"
                     "AtlasSurveyID = '%@' "
                     "WHERE CustomerID = %d",
                     sync.createdOnDevice ? 1 : 0,
                     sync.sync ? 1 : 0,
                     sync.syncToQM ? 1 : 0,
                     sync.syncToPVO ? 1 : 0,
                     sync.generalSyncID == nil ? @"" : [sync.generalSyncID stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     sync.atlasShipID == nil ? @"" : [sync.atlasShipID stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     sync.atlasSurveyID == nil ? @"" : [sync.atlasSurveyID stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     sync.custID];
    
    [self updateDB:cmd];
    
    
}

-(void)removeAllCustomerSyncFlags
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE CustomerSync SET Sync = %d, SyncToQM = %d, SyncToPVO = %d", 0, 0, 0]];
}

-(SurveyCustomer*)getCustomer:(int) cID
{
    SurveyCustomer *cust = [[SurveyCustomer alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT CustomerID,LastName,FirstName,Email"
                     ",Weight,PricingMode,Cancelled,CompanyName,InventoryType,LastSaveToServerDate, OriginCompletionDate, DestinationCompletionDate FROM Customer WHERE CustomerID = %d", cID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            cust.custID = sqlite3_column_int(stmnt, 0);
            cust.lastName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            cust.firstName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 2)];
            cust.email = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 3)];
            cust.estimatedWeight = sqlite3_column_int(stmnt, 4);
            cust.pricingMode = sqlite3_column_int(stmnt, 5);
            cust.cancelled = sqlite3_column_int(stmnt, 6);
            cust.account = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 7)];
            cust.inventoryType = sqlite3_column_int(stmnt, 8);
            cust.lastSaveToServerDate = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 9)];
            cust.originCompletionDate = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 10)];
            cust.destinationCompletionDate = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 11)];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    return cust;
}

-(void)deleteCustomerLocalRates:(int) cID
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesHourly WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalPacking WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesCrates WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesValuation WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesStorage WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesTrans WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesAcc WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesSIT WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalRatesMaterials WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
}

-(void)deleteCustomer:(int) cID
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Customer WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CustomerSync WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Dates WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CustomerNotes WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM ThirdPartyApplied WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Locations WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Phones WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    CubeSheet *cs = [self openCubeSheet:cID];
    
    if(cs != nil)
    {
        //delete the comments and crate dimensions
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM Comments WHERE SurveyedItemID IN("
                        "SELECT SurveyedItemID FROM SurveyedItems WHERE CubesheetID = %d)", cs.csID]];
        
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM CrateDimensions WHERE SurveyedItemID IN("
                        "SELECT SurveyedItemID FROM SurveyedItems WHERE CubesheetID = %d)", cs.csID]];
        
        cmd = [[NSString alloc] initWithFormat:@"DELETE FROM SurveyedItems WHERE CubeSheetID = %d", cs.csID];
        [self updateDB:cmd];
        
        
        cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CubeSheets WHERE CustomerID = %d", cID];
        [self updateDB:cmd];
        
    }
    
    //delete all of the images
    NSMutableArray *images = [self getImagesList:cID withPhotoType:0 withSubID:0 loadAllItems:YES];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *inDocsPath;
    NSString *fullPath;
    NSError *error;
    SurveyImage *img;
    for(int i = 0; i < [images count]; i++)
    {
        img = [images objectAtIndex:i];
        inDocsPath = img.path;
        fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
        
        if([fileManager fileExistsAtPath:fullPath])
            [fileManager removeItemAtPath:fullPath error:&error];
        
    }
    
    //delete all of the Documents
    NSArray *docs = [self getCustomerDocs:cID];
    if (docs != nil)
    {
        for (DocLibraryEntry *doc in docs) {
            [self deleteDocLibraryEntry:doc];
        }
    }
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Images WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CustAgents WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM InterstateAccessorials WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM MiniStorage WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM VehicleWeights WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM ShipmentInfo WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM InterstatePricing WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Discounts WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM MiscItems WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM VanOperatorApplied WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM AKInfo WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM FreeFVP WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM BekinsAcc WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    [self deleteCustomerLocalRates:cID];
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalPricing WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalAcc WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM LocalPricingTotals WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOInventoryData WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    sqlite3_stmt *stmnt;
    //loop through loads to delete all loads for the customer....
    for (PVOInventoryLoad *ld in [self getPVOLocationsForCust:cID]) {
        
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOItemID FROM PVOInventoryItems WHERE PVOLoadID = %d", ld.pvoLoadID]
                    withStatement:&stmnt])
        {
            int pvoItemID;
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                pvoItemID = sqlite3_column_int(stmnt, 0);
                NSString *ccItemSelect = [NSString stringWithFormat:@"SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID IN"
                                          "(SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d)", pvoItemID];
                //carton contents
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVOItemID IN(%@)", ccItemSelect]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDescriptions WHERE PVOItemID IN(%@)", ccItemSelect]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOHighValueInitials WHERE PVOItemID IN(%@)", ccItemSelect]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItemComments WHERE PVOItemID IN (%@)", ccItemSelect]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItems WHERE CartonContentID IN"
                                "(SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d)", pvoItemID]];
                
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryCartonContents WHERE PVOItemID = %d", pvoItemID]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDescriptions WHERE PVOItemID = %d", pvoItemID]];
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItemComments WHERE PVOItemID = %d", pvoItemID]];
                for (PVOHighValueInitial *pvoinitial in [self getAllPVOHighValueInitials:pvoItemID]) {
                    [self deletePVOHighValueInitial:pvoItemID forInitialType:pvoinitial.pvoSigTypeID];
                }
                [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOHighValueInitials WHERE PVOItemID = %d", pvoItemID]];
            }
        }
        sqlite3_finalize(stmnt);
        
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItems WHERE PVOLoadID = %d", ld.pvoLoadID]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVOLoadID = %d", ld.pvoLoadID]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVORoomConditions WHERE PVOLoadID = %d", ld.pvoLoadID]];
    }
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOInventoryLoads WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    //loop through unloads to delete all loads for the customer....
    for (PVOInventoryUnload *unload in [self getPVOUnloads:cID]) {
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVODestinationRoomConditions WHERE PVOUnloadID = %d", unload.pvoLoadID]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d", unload.pvoLoadID]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVOUnloadID = %d", unload.pvoLoadID]];
    }
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOInventoryUnloads WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    
    //delete all of the pvo sigs
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT SignatureFileName FROM PVOSignatures WHERE CustomerID = %d", cID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            NSString *fullPath;
            fullPath = [docsDir stringByAppendingPathComponent:[SurveyDB stringFromStatement:stmnt columnID:0]];
            if([fileManager fileExistsAtPath:fullPath])
                [fileManager removeItemAtPath:fullPath error:nil];
            
        }
        sqlite3_finalize(stmnt);
    }
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOChangeTracking WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOSignatures WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOClaimItems WHERE PVOClaimID IN(SELECT PVOClaimID FROM PVOClaims WHERE CustomerID = %d)", cID];
    [self updateDB:cmd];
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOClaims WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOWeightTickets WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOVerifyInventoryItems WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"DELETE FROM PVOChangeTracking WHERE CustomerID = %d", cID];
    [self updateDB:cmd];
    
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableCartonContents WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDescriptions WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDamages WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItemComments WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItems WHERE CustomerID = %d", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItemsType WHERE CustomerID = %d", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItemsType WHERE CustomerID = %d", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReportNotes WHERE CustomerID = %d", cID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableReportNotes WHERE CustomerID = %d", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVODynamicReportData WHERE CustomerID = %d", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM MasterItemList WHERE ItemID IN"
                    "(SELECT ItemID FROM Items WHERE CustomerID = %d)", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM Items WHERE CustomerID = %d", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM MasterItemList WHERE RoomID IN"
                    "(SELECT RoomID FROM Rooms WHERE CustomerID = %d)", cID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM Rooms WHERE CustomerID = %d", cID]];
    
    [self deleteAllPVOBulkyInventoryItemsForCustomer:cID];
    
    NSMutableArray *vehicles = [self getAllVehicles:cID];
    if (vehicles != nil && [vehicles count] > 0)
    { //TODO: convert to sql delete
        for (int i = 0; i < [vehicles count]; i ++)
        {
            PVOVehicle *vehicle = vehicles[i];
            [self deleteVehicle:vehicle];
        }
    }
    
#if defined(ATLASNET)
    // delete the STG BOL XML data file
    NSString *stgBolPath = [PVOSTGBOL fullPathForCustomer:cID];
    if ([fileManager fileExistsAtPath:stgBolPath])
    {
        [fileManager removeItemAtPath:stgBolPath error:nil];
    }
#endif
}


-(void)copyCustomer:(int)custID
{
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Customer (LastName) VALUES('')"]];
    
    int newCustID = sqlite3_last_insert_rowid(db);
    
    SurveyCustomer *tempCust = [self getCustomer:custID];
    tempCust.custID = newCustID;
    tempCust.lastName = [NSString stringWithFormat:@"%@ (copy)", tempCust.lastName];
    [self updateCustomer:tempCust];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Dates(CustomerID,PackFrom,PackTo,LoadFrom,LoadTo,DeliverFrom,DeliverTo,Survey"
                    ",Decision,FollowUp,NoPack,NoLoad,NoDeliver,Inventory,PackPrefer,LoadPrefer,DeliverPrefer) SELECT "
                    "%d,PackFrom,PackTo,LoadFrom,LoadTo,DeliverFrom,DeliverTo,Survey"
                    ",Decision,FollowUp,NoPack,NoLoad,NoDeliver,Inventory,PackPrefer,LoadPrefer,DeliverPrefer "
                    "FROM Dates WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO ShipmentInfo SELECT "
                    "%d,LeadSource,SubLeadSource,Miles,OrderNumber,JobStatus,EstimateType,Cancelled,IsOA,SourcedFromServer,IsAtlasFastrac "
                    "FROM ShipmentInfo WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO CustomerSync SELECT "
                    "%d,CreatedOnDevice,Sync,SyncToQM,GeneralSyncID,AtlasShipmentID,AtlasSurveyID "
                    "FROM CustomerSync WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Locations(CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,Country"
                    ",IsOrigin,Sequence,CompanyName,FirstName,LastName) SELECT "
                    "%d,LocationType,Name,Address1,Address2,City,State,Zip,County,Country,IsOrigin,Sequence,CompanyName,FirstName,LastName "
                    "FROM Locations WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Phones SELECT "
                    "%d,LocationID,TypeID,Number "
                    "FROM Phones WHERE CustomerID = %d", newCustID, custID]];
    
    CubeSheet *newCS = [self openCubeSheet:newCustID];
    CubeSheet *oldCS = [self openCubeSheet:custID];
    newCS.weightFactor = oldCS.weightFactor;
    [self updateCubeSheet:newCS];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO SurveyedItems("
                    "CubeSheetID,ItemID,RoomID,Shipping,NotShipping,Packing,"
                    "Unpacking,Cube,Weight) SELECT "
                    "%d,ItemID,RoomID,Shipping,NotShipping,Packing,"
                    "Unpacking,Cube,Weight "
                    "FROM SurveyedItems WHERE CubeSheetID = %d", newCS.csID, oldCS.csID]];
    
    //copy comments and crate dims too
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "cd.SurveyedItemID,cd.Length,cd.Width,cd.Height,si.RoomID,si.ItemID "
                     " FROM CrateDimensions cd, SurveyedItems si WHERE "
                     " si.SurveyedItemID = cd.SurveyedItemID AND"
                     " si.CubeSheetID = %d", oldCS.csID];/*get the existing customer's crate dims*/
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO CrateDimensions(SurveyedItemID,Length,Width,Height)"
                            "VALUES("
                            "(SELECT SurveyedItemID FROM SurveyedItems WHERE RoomID = %d AND ItemID = %d AND CubeSheetID = %d),"
                            "%d,%d,%d)",
                            sqlite3_column_int(stmnt, 4),
                            sqlite3_column_int(stmnt, 5),
                            newCS.csID,
                            sqlite3_column_int(stmnt, 1),
                            sqlite3_column_int(stmnt, 2),
                            sqlite3_column_int(stmnt, 3)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    
    cmd = [[NSString alloc] initWithFormat: @"SELECT "
           "c.Comment,si.RoomID,si.ItemID "
           " FROM Comments c, SurveyedItems si WHERE "
           " si.SurveyedItemID = c.SurveyedItemID AND"
           " si.CubeSheetID = %d", oldCS.csID];/*get the existing customer's crate dims*/
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO Comments(SurveyedItemID,Comment)"
                            "VALUES("
                            "(SELECT SurveyedItemID FROM SurveyedItems WHERE RoomID = %d AND ItemID = %d AND CubeSheetID = %d),"
                            "'%@')",
                            sqlite3_column_int(stmnt, 1),
                            sqlite3_column_int(stmnt, 2),
                            newCS.csID,
                            [[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)]
                             stringByReplacingOccurrencesOfString:@"'" withString:@"''"]]];
        }
    }
    sqlite3_finalize(stmnt);
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Images(CustomerID,SubID,PhotoType,Path) SELECT "
                    "%d,SubID,PhotoType,Path "
                    "FROM Images WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO CustAgents SELECT "
                    "%d,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact "
                    "FROM CustAgents WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO InterstateAccessorials SELECT "
                    "%d,LocationID,Shuttle,ShuttleWeight,OTLoad,OTPack,ExLabor"
                    ",ExLaborOT,WaitTime,WaitTimeOT,SITDays,SITWeight,SITMiles,SITZip,SITIn,"
                    "SITPuDel,SITFS,SITIRR,FullPack,SITCartageOverrideApplied,SITCartageOverride,DayCertain "
                    "FROM InterstateAccessorials WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO ThirdPartyApplied"
                    "(CustomerID,LocationID,Quantity,Rate,ThirdPartyID,CompanyServiceID,Category,Description,Note) SELECT "
                    "%d,LocationID,Quantity,Rate,ThirdPartyID,CompanyServiceID,Category,Description,Note "
                    "FROM ThirdPartyApplied WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO MiniStorage"
                    "(CustomerID,LocationID,Weight) SELECT "
                    "%d,LocationID,Weight "
                    "FROM MiniStorage WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO VehicleWeights"
                    "(CustomerID,Weight,Name) SELECT "
                    "%d,Weight,Name "
                    "FROM VehicleWeights WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO CustomerNotes"
                    "(CustomerID,Note) SELECT "
                    "%d,Note "
                    "FROM CustomerNotes WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO InterstatePricing"
                    "(CustomerID,EffDate,ValuationDeductible,ValuationAmount,FuelSurcharge,"
                    "IRR,Peak,BookerAdjustment,PricePacking,DiscProgID,GPPPackCustom,ValueAdd) SELECT "
                    "%d,EffDate,ValuationDeductible,ValuationAmount,FuelSurcharge,"
                    "IRR,Peak,BookerAdjustment,PricePacking,DiscProgID,GPPPackCustom,ValueAdd "
                    "FROM InterstatePricing WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Discounts"
                    "(CustomerID,Positive,BottomLine,SIT,Linehaul,Pack,Accessorial,DayCertain,Crates,IsValDiscounted) SELECT "
                    "%d,Positive,BottomLine,SIT,Linehaul,Pack,Accessorial,DayCertain,Crates,IsValDiscounted "
                    "FROM Discounts WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO ServiceCharges"
                    "(CustomerID,LocationID,ServiceID,Applied,AppliedWt) SELECT "
                    "%d,LocationID,ServiceID,Applied,AppliedWt "
                    "FROM ServiceCharges WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO SpecialService"
                    "(CustomerID,ExclusiveUse,ExclusiveUseCuFt"
                    ",ExclusiveUseMinWt,SpaceRes,SpaceResCuFt,SpaceResMinWt,ExpService,ExpServiceCuFt"
                    ",ExpServiceMinWt) SELECT "
                    "%d,ExclusiveUse,ExclusiveUseCuFt"
                    ",ExclusiveUseMinWt,SpaceRes,SpaceResCuFt,SpaceResMinWt,ExpService,ExpServiceCuFt"
                    ",ExpServiceMinWt "
                    "FROM SpecialService WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO MiscItems"
                    "(CustomerID,Description,Charge,Discounted) SELECT "
                    "%d,Description,Charge,Discounted "
                    "FROM MiscItems WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO VanOperatorApplied"
                    "(CustomerID,[Group],SeqServ,Applied,"
                    "[Type],[Date],Quantity,Location) SELECT "
                    "%d,[Group],SeqServ,Applied,"
                    "[Type],[Date],Quantity,Location "
                    "FROM VanOperatorApplied WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO AKInfo"
                    "(CustomerID,AKIsOrigin,AKCity,IsLand,USPort,AKPort,USMiles,AKMiles) SELECT "
                    "%d,AKIsOrigin,AKCity,IsLand,USPort,AKPort,USMiles,AKMiles "
                    "FROM AKInfo WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO FreeFVP"
                    "(CustomerID,Applied,AmountApplied,FreeAmount,Rate) SELECT "
                    "%d,Applied,AmountApplied,FreeAmount,Rate "
                    "FROM FreeFVP WHERE CustomerID = %d", newCustID, custID]];
    
    
    
    /*************
     **   LOCAL
     **************/
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesHourly"
                    "(CustomerID,HourlyRateType,_1men1van,_2men1van,_3men1van"
                    ",_4men1van,AddlMover,AddlVan) SELECT "
                    "%d,HourlyRateType,_1men1van,_2men1van,_3men1van"
                    ",_4men1van,AddlMover,AddlVan "
                    "FROM LocalRatesHourly WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalPacking"
                    "(CustomerID,ItemID,Container,Unit,PackReg,UnpackReg,PackRegOT,UnpackRegOT"
                    ",PackPeak,UnpackPeak,PackPeakOT,UnpackPeakOT) SELECT "
                    "%d,ItemID,Container,Unit,PackReg,UnpackReg,PackRegOT,UnpackRegOT"
                    ",PackPeak,UnpackPeak,PackPeakOT,UnpackPeakOT "
                    "FROM LocalPacking WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesCrates"
                    "(CustomerID,RegCrate,RegOTCrate,PeakCrate,PeakOTCrate) SELECT "
                    "%d,RegCrate,RegOTCrate,PeakCrate,PeakOTCrate "
                    "FROM LocalRatesCrates WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesValuation"
                    "(CustomerID,ReleasedVal,DeclaredVal,Declared100,MaxValLb"
                    ",Max0,Max250,Max500) SELECT "
                    "%d,ReleasedVal,DeclaredVal,Declared100,MaxValLb"
                    ",Max0,Max250,Max500 "
                    "FROM LocalRatesValuation WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesStorage"
                    "(CustomerID,MonthlyCWT,MonthlyCuFt,DailyCWT,DailyCuFt,"
                    "ValPercentPerCharge,ValPercentPerVal,CartageCWT,CartageCuFt,CartageManHr,HandlingCWT,HandlingCuFt"
                    ",HandlingManHr,VaultMonth,StoTravelRate,StoTaxPct) SELECT "
                    "%d,MonthlyCWT,MonthlyCuFt,DailyCWT,DailyCuFt,"
                    "ValPercentPerCharge,ValPercentPerVal,CartageCWT,CartageCuFt,CartageManHr,HandlingCWT,HandlingCuFt"
                    ",HandlingManHr,VaultMonth,StoTravelRate,StoTaxPct "
                    "FROM LocalRatesStorage WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesTrans"
                    "(CustomerID,RateCWT,OTRateCWT,RateCuFt,OTRateCuFt,LbManHr,MinWt"
                    ",MinCuFt,MinHrs) SELECT "
                    "%d,RateCWT,OTRateCWT,RateCuFt,OTRateCuFt,LbManHr,MinWt"
                    ",MinCuFt,MinHrs "
                    "FROM LocalRatesTrans WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesAcc"
                    "(CustomerID,StairsHr,StairsCWT,StairsCuFt,StairsPiece,ElevatorHr,"
                    "ElevatorCWT,ElevatorCuFt,ElevatorPiece,LongHr,LongCWT,LongCuFt,LongPiece,ShuttleHr,ShuttleManHr,"
                    "ShuttleVanHr,OTShuttleHr,OTShuttleManHr,OTShuttleVanHr,ShuttleCWT,OTShuttleCWT,ShuttleCuFt,"
                    "OTShuttleCuFt,ExLaborHr,ExLaborManHr,ExLaborVanHr,OTExLaborHr,OTExLaborManHr,OTExLaborVanHr,"
                    "ExLaborCWT,OTExLaborCWT,ExLaborCuFt,OTExLaborCuFt,ApplianceService,ApplianceUnservice,"
                    "ExPuDel,Diversions,CWTPack,CWTUnpack) SELECT "
                    "%d,StairsHr,StairsCWT,StairsCuFt,StairsPiece,ElevatorHr,"
                    "ElevatorCWT,ElevatorCuFt,ElevatorPiece,LongHr,LongCWT,LongCuFt,LongPiece,ShuttleHr,ShuttleManHr,"
                    "ShuttleVanHr,OTShuttleHr,OTShuttleManHr,OTShuttleVanHr,ShuttleCWT,OTShuttleCWT,ShuttleCuFt,"
                    "OTShuttleCuFt,ExLaborHr,ExLaborManHr,ExLaborVanHr,OTExLaborHr,OTExLaborManHr,OTExLaborVanHr,"
                    "ExLaborCWT,OTExLaborCWT,ExLaborCuFt,OTExLaborCuFt,ApplianceService,ApplianceUnservice,"
                    "ExPuDel,Diversions,CWTPack,CWTUnpack "
                    "FROM LocalRatesAcc WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesSIT"
                    "(CustomerID,FirstDay,AddlDay,FirstDayCWT,AddlDayCWT,CWTDay,CuFtDay,"
                    "SITCartageCWT,SITCartageCuFt,SITCartageManHr,SITCartageVanHr,SITOTCartageCWT,SITOTCartageCuFt,"
                    "SITOTCartageManHr,SITOTCartageVanHr,SITHandlingCWT,SITHandlingCuFt,SITHandlingManHr,SITHandlingVanHr,"
                    "SITOTHandlingCWT,SITOTHandlingCuFt,SITOTHandlingManHr,SITOTHandlingVanHr,SITValPercentPerCharge,"
                    "SITValPercentPerValuation) SELECT "
                    "%d,FirstDay,AddlDay,FirstDayCWT,AddlDayCWT,CWTDay,CuFtDay,"
                    "SITCartageCWT,SITCartageCuFt,SITCartageManHr,SITCartageVanHr,SITOTCartageCWT,SITOTCartageCuFt,"
                    "SITOTCartageManHr,SITOTCartageVanHr,SITHandlingCWT,SITHandlingCuFt,SITHandlingManHr,SITHandlingVanHr,"
                    "SITOTHandlingCWT,SITOTHandlingCuFt,SITOTHandlingManHr,SITOTHandlingVanHr,SITValPercentPerCharge,"
                    "SITValPercentPerValuation "
                    "FROM LocalRatesSIT WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalRatesMaterials"
                    "(CustomerID,BubbleWrapQty,BubbleWrapRate,PaperQty,PaperRate,TapeQty,"
                    "TapeRate,PadsQty,PadsRate) SELECT "
                    "%d,BubbleWrapQty,BubbleWrapRate,PaperQty,PaperRate,TapeQty,"
                    "TapeRate,PadsQty,PadsRate "
                    "FROM LocalRatesMaterials WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalPricing"
                    "(CustomerID,PackingRateType,CratingRateType,TravelTime,HourlyRateType,"
                    "HourlyPackRateType,NumMovers,NumMoveVans,MoveHours,NumPackers,NumPackVans,PackHours,CwtWeight,CwtOT,"
                    "CuftWeight,CuftOT,FsPercentage,Discount,DedAmt,FlatCharge,FSFlat,IRRPercentage,IRRFlat,CWTOverride,"
                    "CuFtOverride,BasePlusWeight,BasePlusMiles,BasePlusBaseWeight,BasePlusRate,BasePlusExcessRate,"
                    "BreakPointWeight,BreakPointMiles,BreakPointCalcWeight,BreakPointRate,WeightMilesWeight,WeightMilesMiles,"
                    "WeightMilesRate,OrigATCRate,DestATCRate,LocalTransType,ValuationOverride,ValDeductible,DiscProgID,"
                    "PackTravelTime,PackTravelRate,PackSalesTax) SELECT "
                    "%d,PackingRateType,CratingRateType,TravelTime,HourlyRateType,"
                    "HourlyPackRateType,NumMovers,NumMoveVans,MoveHours,NumPackers,NumPackVans,PackHours,CwtWeight,CwtOT,"
                    "CuftWeight,CuftOT,FsPercentage,Discount,DedAmt,FlatCharge,FSFlat,IRRPercentage,IRRFlat,CWTOverride,"
                    "CuFtOverride,BasePlusWeight,BasePlusMiles,BasePlusBaseWeight,BasePlusRate,BasePlusExcessRate,"
                    "BreakPointWeight,BreakPointMiles,BreakPointCalcWeight,BreakPointRate,WeightMilesWeight,WeightMilesMiles,"
                    "WeightMilesRate,OrigATCRate,DestATCRate,LocalTransType,ValuationOverride,ValDeductible,DiscProgID,"
                    "PackTravelTime,PackTravelRate,PackSalesTax "
                    "FROM LocalPricing WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalAcc"
                    "(CustomerID,LocationID,stairsCount,stairsHours,stairsWeight,stairsCuFt"
                    ",stairsPieces,elevatorsCount,elevatorsHours,elevatorsWeight,elevatorsCuFt,elevatorsPieces,longCount,"
                    "longHours,longWeight,longCuFt,longPieces,miscAppServiced,miscAppUnserviced,miscDiversions,shuttleOT,"
                    "shuttleMen,shuttleVans,shuttleHours,shuttleWeight,shuttleCuFt,exLaborOT,exLaborMen,exLaborVans,"
                    "exLaborHours,exLaborWeight,exLaborCuFt,sitDays,sitWeight,sitCuFt,sitCartageOT,sitCartageMen,"
                    "sitCartageHours,sitCartageVans,sitCartageWeight,sitCartageCuFt,sitHandlingOT,sitHandlingMen,"
                    "sitHandlingHours,sitHandlingVans,sitHandlingWeight,sitHandlingCuFt,storageMonths,storageDays,"
                    "storageWeight,storageCuFt,storageCartageWeight,storageCartageCuFt,storageCartageMen,"
                    "storageCartageHours,storageHandlingWeight,storageHandlingCuFt,storageHandlingMen,storageHandlingHours,"
                    "storageVaults,stairsOverride,elevatorsOverride,longOverride,shuttleOverride,exLaborOverride,"
                    "storageOverride,stoCartageOverride,stoHandlingOverride,stoValOverride,sitValOverride,sitMonths,"
                    "CWTPack,CWTPackWeight,StoTravelTime) SELECT "
                    "%d,LocationID,stairsCount,stairsHours,stairsWeight,stairsCuFt"
                    ",stairsPieces,elevatorsCount,elevatorsHours,elevatorsWeight,elevatorsCuFt,elevatorsPieces,longCount,"
                    "longHours,longWeight,longCuFt,longPieces,miscAppServiced,miscAppUnserviced,miscDiversions,shuttleOT,"
                    "shuttleMen,shuttleVans,shuttleHours,shuttleWeight,shuttleCuFt,exLaborOT,exLaborMen,exLaborVans,"
                    "exLaborHours,exLaborWeight,exLaborCuFt,sitDays,sitWeight,sitCuFt,sitCartageOT,sitCartageMen,"
                    "sitCartageHours,sitCartageVans,sitCartageWeight,sitCartageCuFt,sitHandlingOT,sitHandlingMen,"
                    "sitHandlingHours,sitHandlingVans,sitHandlingWeight,sitHandlingCuFt,storageMonths,storageDays,"
                    "storageWeight,storageCuFt,storageCartageWeight,storageCartageCuFt,storageCartageMen,"
                    "storageCartageHours,storageHandlingWeight,storageHandlingCuFt,storageHandlingMen,storageHandlingHours,"
                    "storageVaults,stairsOverride,elevatorsOverride,longOverride,shuttleOverride,exLaborOverride,"
                    "storageOverride,stoCartageOverride,stoHandlingOverride,stoValOverride,sitValOverride,sitMonths,"
                    "CWTPack,CWTPackWeight,StoTravelTime "
                    "FROM LocalAcc WHERE CustomerID = %d", newCustID, custID]];
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO LocalPricingTotals"
                    "(CustomerID,origAcc,origStairs,origLongs,origElevator,origExLabor,"
                    "origAppService,origExPuDel,origDiversion,destAcc,destStairs,destLongs,destElevator,destExLabor,"
                    "destAppService,destExPuDel,destDiversion,origShuttle,destShuttle,bulky,bulkyWtAdd,bulkyCharges,"
                    "storage,storageCharge,stoCartage,stoHandling,stoVal,storageTotal,origSIT,origSITCharge,"
                    "origSITCartageHandling,origSITVal,origSITTotal,destSIT,destSITCharge,destSITCartageHandling,"
                    "destSITVal,destSITTotal) SELECT "
                    "%d,origAcc,origStairs,origLongs,origElevator,origExLabor,"
                    "origAppService,origExPuDel,origDiversion,destAcc,destStairs,destLongs,destElevator,destExLabor,"
                    "destAppService,destExPuDel,destDiversion,origShuttle,destShuttle,bulky,bulkyWtAdd,bulkyCharges,"
                    "storage,storageCharge,stoCartage,stoHandling,stoVal,storageTotal,origSIT,origSITCharge,"
                    "origSITCartageHandling,origSITVal,origSITTotal,destSIT,destSITCharge,destSITCartageHandling,"
                    "destSITVal,destSITTotal "
                    "FROM LocalPricingTotals WHERE CustomerID = %d", newCustID, custID]];
    
}

-(SurveyDates*)getDates:(int) cID
{
    SurveyDates *dates = [[SurveyDates alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "CustomerID,PackFrom,PackTo,PackPrefer,LoadFrom,LoadTo,"
                     "LoadPrefer,DeliverFrom,DeliverTo,DeliverPrefer,Survey,"
                     "Decision,FollowUp,NoPack,NoLoad,NoDeliver,Inventory"
                     " FROM Dates WHERE CustomerID = %d", cID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            dates.custID = cID;
            if (sqlite3_column_type(stmnt, 1) != SQLITE_NULL)
                dates.packFrom = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 1)];
            if (sqlite3_column_type(stmnt, 2) != SQLITE_NULL)
                dates.packTo = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 2)];
            if (sqlite3_column_type(stmnt, 3) != SQLITE_NULL)
                dates.packPrefer = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 3)];
            if (sqlite3_column_type(stmnt, 4) != SQLITE_NULL)
                dates.loadFrom = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 4)];
            if (sqlite3_column_type(stmnt, 5) != SQLITE_NULL)
                dates.loadTo = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 5)];
            if (sqlite3_column_type(stmnt, 6) != SQLITE_NULL)
                dates.loadPrefer = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 6)];
            if (sqlite3_column_type(stmnt, 7) != SQLITE_NULL)
                dates.deliverFrom = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 7)];
            if (sqlite3_column_type(stmnt, 8) != SQLITE_NULL)
                dates.deliverTo = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 8)];
            if (sqlite3_column_type(stmnt, 9) != SQLITE_NULL)
                dates.deliverPrefer = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 9)];
            dates.survey = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 10)];
            dates.decision = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 11)];
            dates.followUp = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 12)];
            dates.noPack = sqlite3_column_int(stmnt, 13) > 0;
            dates.noLoad = sqlite3_column_int(stmnt, 14) > 0;
            dates.noDeliver = sqlite3_column_int(stmnt, 15) > 0;
            dates.inventory = sqlite3_column_double(stmnt, 16) == 0 ? nil : [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 16)];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return dates;
}

-(void)updateDates:(SurveyDates*) dates
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Dates SET "
                     "PackFrom = %@,PackTo = %@,LoadFrom = %@,LoadTo = %@,DeliverFrom = %@,DeliverTo = %@,Survey = %f,Decision = %f,FollowUp = %f,"
                     "NoPack = %d,NoLoad = %d,NoDeliver = %d,Inventory = %f,PackPrefer = %@,LoadPrefer = %@,DeliverPrefer = %@"
                     " WHERE CustomerID = %d",
                     (dates.packFrom == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.packFrom timeIntervalSince1970]]),
                     (dates.packTo == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.packTo timeIntervalSince1970]]),
                     (dates.loadFrom == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.loadFrom timeIntervalSince1970]]),
                     (dates.loadTo == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.loadTo timeIntervalSince1970]]),
                     (dates.deliverFrom == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.deliverFrom timeIntervalSince1970]]),
                     (dates.deliverTo == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.deliverTo timeIntervalSince1970]]),
                     [dates.survey timeIntervalSince1970],
                     [dates.decision timeIntervalSince1970],
                     [dates.followUp timeIntervalSince1970],
                     dates.noPack ? 1 : 0,
                     dates.noLoad ? 1 : 0,
                     dates.noDeliver ? 1 : 0,
                     [dates.inventory timeIntervalSince1970],
                     (dates.packPrefer == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.packPrefer timeIntervalSince1970]]),
                     (dates.loadPrefer == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.loadPrefer timeIntervalSince1970]]),
                     (dates.deliverPrefer == nil ? @"null" : [NSString stringWithFormat:@"%f", [dates.deliverPrefer timeIntervalSince1970]]),
                     dates.custID];
    
    [self updateDB:cmd];
    
    
}

-(int)insertNewCustomer:(SurveyCustomer*) cust withSync:(SurveyCustomerSync*)sync andShipInfo:(ShipmentInfo*)info
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Customer(LastName,FirstName,CompanyName,Email,"
                     "Weight,PricingMode,Cancelled, InventoryType, OriginCompletionDate, DestinationCompletionDate) VALUES('%@','%@','%@','%@',%d,%d,0, %d, '', '');",
                     cust.lastName == nil ? @"" : [cust.lastName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.firstName == nil ? @"" : [cust.firstName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.account == nil ? @"" : [cust.account stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.email == nil ? @"" : [cust.email stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     cust.estimatedWeight, cust.pricingMode, cust.inventoryType];
    
    [self updateDB:cmd];
    
    
    
    cust.custID = sqlite3_last_insert_rowid(db);
    
    if(cust.custID == 0)
        NSAssert(0, @"Unable to create new customer due to invalid returned id");
    
    //insert sync fields
    sync.custID = cust.custID;
    cmd = [[NSString alloc] initWithFormat: @"INSERT INTO CustomerSync "
           "(CustomerID,CreatedOnDevice,Sync,SyncToQM,GeneralSyncID,AtlasShipmentID,AtlasSurveyID)"
           " VALUES(%d,0,0,0,'','','')",
           cust.custID];
    [self updateDB:cmd];
    
    //now update
    [self updateCustomerSync:sync];
    
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustomerNotes"
           "(CustomerID,Note)"
           " VALUES(%d,'')",
           cust.custID];
    [self updateDB:cmd];
    
    
    //insert dates
    NSDate *now = [NSDate date];
    NSTimeInterval seconds = [now timeIntervalSince1970];
    BOOL nullPackLoadDeliver = [AppFunctionality supportIndividualBlankDates:cust.pricingMode];
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Dates "
           "(CustomerID,"
           "PackFrom,PackTo,PackPrefer,LoadFrom,LoadTo,LoadPrefer,DeliverFrom,DeliverTo,DeliverPrefer,"
           "Survey,Decision,FollowUp,NoPack,NoLoad,NoDeliver,Inventory) "
           "VALUES(%d,"
           "%@" //pack/load/deliver dates
           "%f,%f,%f,0,0,0,%f)",
           cust.custID,
           (nullPackLoadDeliver ? @"null,null,null,null,null,null,null,null,null," :
            [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,",
             seconds, seconds, seconds, seconds, seconds, seconds, seconds, seconds, seconds]),
           seconds, seconds, seconds, seconds];
    [self updateDB:cmd];
    
    
    //insert info
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO ShipmentInfo"
           "(CustomerID,LeadSource,SubLeadSource,Miles,OrderNumber,JobStatus,EstimateType,Cancelled,IsOA,GBLNumber,SourcedFromServer,IsAtlasFastrac,LanguageCode,CustomItemList)"
           " VALUES(%d,%@,%@,%d,%@,%d,%d,%d,%d,%@,%d,%d,%d,%d)",
           cust.custID,
           [self prepareStringForInsert:info.leadSource],
           [self prepareStringForInsert:info.subLeadSource],
           info.miles,
           [self prepareStringForInsert:info.orderNumber],
           info.status, info.type, info.cancelled ? 1 : 0, info.isOA ? 1 : 0,
           [self prepareStringForInsert:info.gblNumber],
           info.sourcedFromServer ? 1 : 0,
           info.isAtlasFastrac ? 1 : 0,
           info.language,
           info.itemListID];
    [self updateDB:cmd];
    
    
    //insert pricing
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO InterstatePricing"
           "(CustomerID,EffDate,ValuationDeductible,ValuationAmount,FuelSurcharge,"
           "IRR,Peak,BookerAdjustment,PricePacking,GPPPackCustom,ValueAdd)"
           " VALUES(%d,%f,0,0,0,4,0,0.001,1,0,'')",
           cust.custID, seconds];
    [self updateDB:cmd];
    
    
    //insert discounts
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Discounts"
           "(CustomerID,Positive,BottomLine,SIT,Linehaul,Pack,Accessorial,IsValDiscounted)"
           " VALUES(%d,0,0,0,0,0,0,0)",
           cust.custID];
    [self updateDB:cmd];
    
    
    //insert origin
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Locations"
           "(CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,CompanyName,FirstName,LastName)"
           " VALUES(%d,%d,'Origin','','','','','','',1,0,'','','')",
           cust.custID, ORIGIN_LOCATION_ID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO InterstateAccessorials"
           "(CustomerID,LocationID,Shuttle,ShuttleWeight,OTLoad,OTPack,ExLabor"
           ",ExLaborOT,WaitTime,WaitTimeOT,SITDays,SITWeight,SITMiles,SITZip,SITIn,"
           "SITPuDel,SITFS,SITIRR,FullPack,SITCartageOverrideApplied,SITCartageOverride,DayCertain)"
           " VALUES(%d,1,0,0,0,0,0,0,0,0,0,0,0,'',%f,%f,0,0,0,0,0,0)",
           cust.custID, seconds, seconds];
    [self updateDB:cmd];
    
    
    //insert destination
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Locations"
           "(CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,CompanyName,FirstName,LastName)"
           " VALUES(%d,%d,'Destination','','','','','','',0,0,'','','')",
           cust.custID, DESTINATION_LOCATION_ID];
    [self updateDB:cmd];
    
    
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO InterstateAccessorials"
           "(CustomerID,LocationID,Shuttle,ShuttleWeight,OTLoad,OTPack,ExLabor"
           ",ExLaborOT,WaitTime,WaitTimeOT,SITDays,SITWeight,SITMiles,SITZip,SITIn,"
           "SITPuDel,SITFS,SITIRR,FullPack,SITCartageOverrideApplied,SITCartageOverride,DayCertain)"
           " VALUES(%d,2,0,0,0,0,0,0,0,0,0,0,0,'',%f,%f,0,0,0,0,0,0)",
           cust.custID, seconds, seconds];
    [self updateDB:cmd];
    
    
    
    //insert the default agents...
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO CustAgents SELECT "
                    "%d,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact "
                    "FROM CustAgents WHERE CustomerID = %d", cust.custID, DEFAULT_AGENCY_CUST_ID]];
    /*
     
     cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
		   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
		   "VALUES(%d,%d,'','','','','','','','','','')",
		   cust.custID, AGENT_BOOKING];
     [self updateDB:cmd];
     
     
     cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
		   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
		   "VALUES(%d,%d,'','','','','','','','','','')",
		   cust.custID, AGENT_ORIGIN];
     [self updateDB:cmd];
     
     
     cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
		   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
		   "VALUES(%d,%d,'','','','','','','','','','')",
		   cust.custID, AGENT_DESTINATION];
     [self updateDB:cmd];
     */
    
    
    /*PVO Testing for Inventory*/
    //    NSLog(@"GET RID OF THIS!!!");
    //
    //    //PVOVerifyInventoryItems(CustomerID INT, SerialNumber TEXT, ArticleName
    //
    //    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVerifyInventoryItems"
    //                    "(CustomerID, SerialNumber, ArticleName) VALUES(%d,'1122334455','This new Item')", cust.custID]];
    //    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVerifyInventoryItems"
    //                    "(CustomerID, SerialNumber, ArticleName) VALUES(%d,'2233445566','1.5 - CP')", cust.custID]];
    
    return cust.custID;
}

-(void)insertPhone:(SurveyPhone*) phone {
    NSString *cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Phones(CustomerID,LocationID,TypeID,Number,isPrimary) VALUES(%ld,%ld,%ld,'%@',%d);",
                     phone.custID,
                     phone.locationTypeId,
                     phone.type == nil ? 0 : phone.type.phoneTypeID,
                     phone.number == nil ? @"" : [phone.number stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     phone.isPrimary];
    
    [self updateDB:cmd];
    
    
    
}

-(void)updatePhone:(SurveyPhone*) phone {
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Phones SET Number = '%@', isPrimary = %d WHERE CustomerID = %ld AND LocationID = %ld AND TypeID = %ld;",
                     phone.number == nil ? @"" : [phone.number stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     phone.isPrimary,
                     phone.custID,
                     phone.locationTypeId,
                     phone.type == nil ? 0 : phone.type.phoneTypeID];
    
    [self updateDB:cmd];
    
    
    
}

-(void)deletePhone:(SurveyPhone*) phone
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Phones WHERE CustomerID = %ld AND LocationID = %ld AND TypeID = %ld;",
                     phone.custID, phone.locationTypeId, phone.type.phoneTypeID];
    
    [self updateDB:cmd];
    
    
    
}

-(void)deletePhones:(int)custID withLocationID:(int)locationID
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Phones WHERE CustomerID = %d AND LocationID = %d", custID, locationID];
    [self updateDB:cmd];
    
}

-(void)updatePhoneType:(int) newTypeID withOldPhoneTypeID:(int) oldTypeID withCustomerID:(int)customerID andLocationID:(int)locationID
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Phones SET TypeID = %d WHERE CustomerID = %d AND LocationID = %d AND TypeID = %d;",
                     newTypeID, customerID, locationID, oldTypeID];
    
    [self updateDB:cmd];
    
    
    
    
}

-(NSString*)getCustomerNote:(int)custID
{
    NSString *notes;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "Note "
                     "FROM CustomerNotes WHERE CustomerID = %d",
                     custID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            notes = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    
    
    return notes;
}

-(void)updateCustomerNote:(int)custID withNote:(NSString*)note
{
    NSString *cmd = [[NSString alloc] initWithFormat: @"UPDATE CustomerNotes SET "
                     "Note = '%@' "
                     "WHERE CustomerID = %d",
                     note == nil ? @"" : [note stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     custID];
    
    [self updateDB:cmd];
    
    
    
}

-(void)updateLocation:(SurveyLocation*) loc
{
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE Locations SET "
                     "Name = '%@', "
                     "CompanyName = '%@', "
                     "FirstName = '%@', "
                     "LastName = '%@', "
                     "Address1 = '%@', "
                     "Address2 = '%@', "
                     "City = '%@', "
                     "State = '%@', "
                     "Zip = '%@', "
                     "County = '%@', "
                     "IsOrigin = %d, "
                     "Sequence = %d "
                     "WHERE CustomerID = %ld AND LocationType = %ld",
                     loc.name == nil ? @"" : [loc.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.companyName == nil ? @"" : [loc.companyName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.firstName == nil ? @"" : [loc.firstName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.lastName == nil ? @"" : [loc.lastName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.address1 == nil ? @"" : [loc.address1 stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.address2 == nil ? @"" : [loc.address2 stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.city == nil ? @"" : [loc.city stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.state == nil ? @"" : [loc.state stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.zip == nil ? @"" : [loc.zip stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.county == nil ? @"" : [loc.county stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     loc.isOrigin ? 1 : 0, loc.sequence,
                     loc.custID, loc.locationType];
    
    [self updateDB:cmd];
    
    
    
}

-(void)deleteLocation:(SurveyLocation*) loc
{
    //remove the image entries first
    //    [[[del.surveyDB getImagesList:custID withPhotoType:IMG_LOCATIONS
    //                        withSubID:[[locations objectAtIndex:[indexPath section]] locationType] loadAllItems:NO]
    
    NSMutableArray *locImages = [self getImagesList:loc.custID withPhotoType:IMG_LOCATIONS withSubID:loc.locationType loadAllItems:NO];
    if (locImages != nil && [locImages count] > 0)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docsDir, *inDocsPath, *fullPath;
        NSError *error;
        for (SurveyImage *img in locImages)
        {
            [self deleteImageEntry:img.imageID];
            docsDir = [SurveyAppDelegate getDocsDirectory];
            inDocsPath = img.path;
            fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
            if([fileManager fileExistsAtPath:fullPath])
                [fileManager removeItemAtPath:fullPath error:&error];
        }
    }
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Locations "
                     "WHERE CustomerID = %ld AND LocationID = %d",
                     loc.custID, loc.locationID];
    
    [self updateDB:cmd];
    
    
}

-(SurveyLocation*)getCustomerLocation:(int) cID withType:(int)locID
{
    SurveyLocation *retval = [[SurveyLocation alloc] init];
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,LocationID,CompanyName,FirstName,LastName"
                     " FROM Locations WHERE CustomerID = %d AND LocationType = %d"
                     , cID, locID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[SurveyLocation alloc] initWithStatement:stmnt];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(SurveyLocation*)getCustomerLocation:(int)locID
{
    SurveyLocation *retval = [[SurveyLocation alloc] init];
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,LocationID,CompanyName,FirstName,LastName"
                     " FROM Locations WHERE LocationID = %d"
                     , locID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            
            retval = [[SurveyLocation alloc] initWithStatement:stmnt];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return retval;
}

-(NSMutableArray*)getCustomerLocations:(int) cID atOrigin:(BOOL)origin
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,LocationID,CompanyName,FirstName,LastName"
                     " FROM Locations WHERE CustomerID = %d AND IsOrigin = %d"
                     " ORDER BY Sequence ASC", cID, origin ? 1 : 0];
    SurveyLocation *loc;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            loc = [[SurveyLocation alloc] initWithStatement:stmnt];
            [retval addObject:loc];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return retval;
}

-(int)getExtraLocationsCount:(int) cID
{
    int retval = 0;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT "
                     "COUNT(*)"
                     " FROM Locations WHERE CustomerID = %d AND LocationType > %d", cID, DESTINATION_LOCATION_ID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return retval;
}

-(int)insertLocation:(SurveyLocation*) loc
{
    //get the next sequence and location ID first.
    sqlite3_stmt *stmnt;
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT MAX(Sequence) FROM Locations WHERE "
                     "CustomerID = %ld AND IsOrigin = %d", loc.custID, loc.isOrigin ? 1 : 0];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            loc.sequence = sqlite3_column_int(stmnt, 0) + 1;
        }
    }
    sqlite3_finalize(stmnt);
    
    
    cmd = [[NSString alloc] initWithFormat: @"SELECT MAX(LocationID) FROM Locations WHERE "
           "CustomerID = %ld", loc.custID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            loc.locationType = sqlite3_column_int(stmnt, 0) + 1;
        }
    }
    sqlite3_finalize(stmnt);
    
    
    //now insert the new location
    cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Locations"
           "(CustomerID,LocationType,Name,CompanyName,FirstName,LastName,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence)"
           " VALUES(%ld,%ld,'%@','%@','%@','%@','%@','%@','%@','%@','%@','%@',%d,%d)",
           loc.custID, loc.locationType,
           loc.name == nil ? @"" : [loc.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.companyName == nil ? @"" : [loc.companyName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.firstName == nil ? @"" : [loc.firstName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.lastName == nil ? @"" : [loc.lastName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.address1 == nil ? @"" : [loc.address1 stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.address2 == nil ? @"" : [loc.address2 stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.city == nil ? @"" : [loc.city stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.state == nil ? @"" : [loc.state stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.zip == nil ? @"" : [loc.zip stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.county == nil ? @"" : [loc.county stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
           loc.isOrigin ? 1 : 0, loc.sequence];
    [self updateDB:cmd];
    
    
    return sqlite3_last_insert_rowid(db);
}

-(int)getPhoneTypeIDFromName:(NSString*)name
{
    int retval = -1;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT PhoneTypeID FROM PhoneTypes WHERE Name = '%@'", name];
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


-(NSString*)getPhoneTypeNameFromId:(int)phoneTypeId {
    NSString *retval = nil;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT Name FROM PhoneTypes WHERE PhoneTypeID = '%d'", phoneTypeId];
    if([self prepareStatement:cmd withStatement:&stmnt]) {
        if(sqlite3_step(stmnt) == SQLITE_ROW) {
            retval = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSMutableArray*)getPhoneTypeList
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    PhoneType *item;
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT PhoneTypeID,Name FROM PhoneTypes WHERE COALESCE(IsHidden,0) = 0 ORDER BY Name COLLATE NOCASE ASC" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[PhoneType alloc] init];
            item.phoneTypeID = sqlite3_column_int(stmnt, 0);
            item.name = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            [array addObject:item];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
}

-(NSString*)getCustomerPhone:(int)cID withLocationID:(int)locationID andPhoneType:(NSString*)type {
    NSArray *phones = [self getCustomerPhones:cID withLocationID:locationID];
    NSString *retval = nil;
    
    for(SurveyPhone *current in phones) {
        if([current.type.name isEqualToString:type]) {
            retval = [[NSString alloc] initWithString:current.number];
        }
    }
    
    return retval;
}

-(NSMutableArray*)getCustomerPhones:(int) cID withLocationID:(int)locID {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    SurveyPhone *item;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT p.CustomerID,p.LocationID,t.PhoneTypeID,t.Name,p.Number, p.IsPrimary FROM Phones p,PhoneTypes t WHERE p.CustomerID = %d AND p.LocationID = %d AND p.TypeID = t.PhoneTypeID AND IsPrimary = 0", cID, locID];
    
    if([self prepareStatement:cmd withStatement:&stmnt]) {
        while(sqlite3_step(stmnt) == SQLITE_ROW) {
            item = [[SurveyPhone alloc] init];
            item.type = [[PhoneType alloc] init];
            
            item.custID = sqlite3_column_int(stmnt, 0);
            item.locationTypeId = sqlite3_column_int(stmnt, 1);
            item.type.phoneTypeID = sqlite3_column_int(stmnt, 2);
            int isPrimary = sqlite3_column_int(stmnt, 5);
            if (isPrimary == 1)
                item.type.name = @"Primary";
            else
                item.type.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 3)];
            item.number = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 4)];
            item.isPrimary = isPrimary;
            
            [array addObject:item];
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
}

-(SurveyPhone*)getPrimaryPhone:(int)cID
{
    SurveyPhone *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = nil;
    
    cmd = [[NSString alloc] initWithFormat: @"SELECT p.CustomerID,p.LocationID,t.PhoneTypeID,t.Name,p.Number,p.IsPrimary FROM Phones p,PhoneTypes t WHERE p.CustomerID = %d AND p.isPrimary = 1 AND p.TypeID = t.PhoneTypeID", cID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyPhone alloc] init];
            item.type = [[PhoneType alloc] init];
            
            item.custID = sqlite3_column_int(stmnt, 0);
            item.locationTypeId = sqlite3_column_int(stmnt, 1);
            item.type.phoneTypeID = sqlite3_column_int(stmnt, 2);
            //item.type.name = @"Primary";  // This makes it show as 'Primary' in the editphonecontroller if primary is unchecked... don't like it.
            item.type.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 3)];
            item.number = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 4)];
            item.isPrimary = 1;
            
            return item;
        }
    }
    
    
    sqlite3_finalize(stmnt);
    
    
    
    return nil;
}

-(BOOL)phoneExists:(int)customerID withLocationID:(int)locationID withPhoneType:(int)phoneTypeID
{
    BOOL retval = NO;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat: @"SELECT COUNT(*) FROM Phones WHERE CustomerID = %d AND LocationID = %d AND TypeID = %d", customerID, locationID, phoneTypeID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(sqlite3_column_int(stmnt, 0) > 0)
                retval = YES;
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    
    
    return retval;
}

-(BOOL)insertNewPhoneType:(NSString*)typeName
{
    if (typeName == nil || [typeName length] == 0 ||
        [[typeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
        return NO;
    int typeID = [self getPhoneTypeIDFromName:[typeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    if(typeID > 0)
        [self updateDB:[NSString stringWithFormat:@"UPDATE PhoneTypes SET IsHidden = 0 WHERE PhoneTypeID = %d", typeID]];
    else
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PhoneTypes(Name,IsHidden) VALUES('%@',0)",
                        [typeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
    return YES;
}

-(void)hidePhoneType:(int)phoneTypeID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PhoneTypes SET IsHidden = 1 WHERE PhoneTypeID = %d", phoneTypeID]];
}


#pragma mark agents


-(SurveyAgent*)getAgent:(int)customerID withAgentID:(int)agentID
{
    SurveyAgent *item = [[SurveyAgent alloc] init];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT CustomerID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact FROM CustAgents "
                     "WHERE CustomerID = %d AND AgentID = %d", customerID, agentID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item.itemID = sqlite3_column_int(stmnt, 0);
            item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            item.address = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 2)];
            item.city = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 3)];
            item.state = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 4)];
            item.zip = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 5)];
            item.phone = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 6)];
            item.email = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 8)];
            item.code = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 9)];
            item.contact = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 10)];
            item.agencyID = agentID;
        }
    }
    
    return item;
}

-(void)saveAgent:(SurveyAgent*)agent
{
    NSString *cmd = [NSString stringWithFormat:@"UPDATE CustAgents SET "
                     "Name = '%@', Address = '%@', City = '%@', State = '%@', Zip = '%@', "
                     "Phone = '%@', Fax = '%@', Email = '%@', Code = '%@', Contact = '%@' "
                     " WHERE CustomerID = %d AND AgentID = %d",
                     agent.name == nil ? @"" : [agent.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.address == nil ? @"" : [agent.address stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.city == nil ? @"" : [agent.city stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.state == nil ? @"" : [agent.state stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.zip == nil ? @"" : [agent.zip stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.phone == nil ? @"" : [agent.phone stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     @"", // Former Fax (Removed with TEG-617)
                     agent.email == nil ? @"" : [agent.email stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.code == nil ? @"" : [agent.code stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.contact == nil ? @"" : [agent.contact stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     agent.itemID, agent.agencyID];
    
    [self updateDB:cmd];
    
}

#pragma mark Common Notes
-(NSArray*)loadCommonNotes:(int)noteType
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    CommonNote *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT CommonNoteID,CommonNoteType,Note "
                     "FROM CommonNotes WHERE CommonNoteType = %d ORDER BY Note COLLATE NOCASE ASC", noteType];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[CommonNote alloc] init];
            
            item.recID = sqlite3_column_int(stmnt, 0);
            item.type = sqlite3_column_int(stmnt, 1);
            item.note = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 2)];
            
            [array addObject:item];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return array;
    
}

-(void)saveNewCommonNote:(CommonNote*)note
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CommonNotes"
                     "(CommonNoteType,Note) "
                     "VALUES(%d,'%@')",
                     note.type,
                     note.note == nil ? @"" : [note.note stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    
    [self updateDB:cmd];
    
}

-(void)deleteCommonNote:(int)recID
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CommonNotes"
                     " WHERE CommonNoteID = %d",
                     recID];
    
    [self updateDB:cmd];
    
}

#pragma mark Shipment Info

-(ShipmentInfo*)getShipInfo:(int)custID
{
    ShipmentInfo *info = [[ShipmentInfo alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT CustomerID,LeadSource,SubLeadSource,Miles,OrderNumber,JobStatus,EstimateType,Cancelled,IsOA,GBLNumber,SourcedFromServer,IsAtlasFastrac,LanguageCode,CustomItemList"
                     " FROM ShipmentInfo"
                     " WHERE CustomerID = %d", custID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            info.customerID = sqlite3_column_int(stmnt, 0);
            info.leadSource = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)];
            info.subLeadSource = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
            info.miles = sqlite3_column_int(stmnt, 3);
            info.orderNumber = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 4)];
            info.status = sqlite3_column_int(stmnt, 5);
            info.type = sqlite3_column_int(stmnt, 6);
            info.cancelled = sqlite3_column_int(stmnt, 7) > 0;
            info.isOA = sqlite3_column_int(stmnt, 8) > 0;
            info.gblNumber = [SurveyDB stringFromStatement:stmnt columnID:9];
            info.sourcedFromServer = sqlite3_column_int(stmnt, 10) > 0;
            info.isAtlasFastrac = sqlite3_column_int(stmnt, 11) > 0;
            info.language = sqlite3_column_int(stmnt, 12);
            info.itemListID = sqlite3_column_int(stmnt, 13);
        }
    }
    sqlite3_finalize(stmnt);
    
    return info;
}

-(void)updateShipInfo:(ShipmentInfo*)info
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE ShipmentInfo SET "
                     "LeadSource = '%@', "
                     "SubLeadSource = '%@', "
                     "Miles = %d, "
                     "OrderNumber = '%@', "
                     "JobStatus = %d, "
                     "EstimateType = %d,"
                     "Cancelled = %d,"
                     "IsOA = %d,"
                     "GBLNumber = %@,"
                     "SourcedFromServer = %d, "
                     "IsAtlasFastrac = %d, "
                     "LanguageCode = %d, "
                     "CustomItemList = %d"
                     " WHERE CustomerID = %d",
                     info.leadSource == nil ? @"" : [info.leadSource stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     info.subLeadSource == nil ? @"" : [info.subLeadSource stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     info.miles,
                     info.orderNumber == nil ? @"" : [info.orderNumber stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     info.status, info.type, info.cancelled ? 1 : 0, info.isOA ? 1 : 0,
                     [self prepareStringForInsert:info.gblNumber supportsNull:YES],
                     info.sourcedFromServer ? 1 : 0,
                     info.isAtlasFastrac ? 1 : 0,
                     info.language,
                     info.itemListID,
                     info.customerID];
    
    
    [self updateDB:cmd];
    
    
}

-(void)updateShipInfo:(int)custID languageCode:(int)languageCode customItemList:(int)customItemList
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE ShipmentInfo SET LanguageCode = %d, CustomItemList = %d WHERE CustomerID = %d", languageCode, customItemList, custID];
    [self updateDB:cmd];
    
}

-(NSDictionary*)getLanguages
{
    @synchronized(self)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        sqlite3_stmt *stmnt;
        if([self prepareStatement:@"SELECT LanguageCode,Description FROM Languages"
                    withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                [dict setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                         forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
            }
        }
        sqlite3_finalize(stmnt);
        
        return dict;
    }
}

-(int)getLanguageForCustomer:(int)customerId
{
    NSString *query = [NSString stringWithFormat:@"SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d", customerId];
    return [self getIntValueFromQuery:query];
}

-(void)resetLanguageWithCustomerID:(int)custID code:(int)code
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE ShipmentInfo SET LanguageCode = %d WHERE CustomerID = %d", code, custID]];
}

#pragma mark Cubesheet Methods

-(NSMutableArray*)getAllRoomsList:(int)customerID
{
    return [self getAllRoomsList:customerID withCheckInclude:NO];
}

-(NSMutableArray*)getAllRoomsList:(int)customerID withHidden:(BOOL)includeHidden
{
    return [self getAllRoomsList:customerID withCheckInclude:NO limitToCustomer:NO withPVOLocationID:-1 withHidden:includeHidden];
}

-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden
{
    return [self getAllRoomsList:customerID withCheckInclude:includeHidden limitToCustomer:NO withPVOLocationID:-1 withHidden:NO];
}

-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden limitToCustomer:(BOOL)customerItemsOnly
{
    return [self getAllRoomsList:customerID withCheckInclude:includeHidden limitToCustomer:customerItemsOnly withPVOLocationID:-1 withHidden:NO];
}

-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden limitToCustomer:(BOOL)customerItemsOnly withPVOLocationID:(int)pvoLocationID withHidden:(BOOL)includeHidden2
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Room *item;
    
    
    sqlite3_stmt *stmnt;
    
    
    BOOL limitByPVOLocation = [self pvoLocationLimitItems:pvoLocationID];
    
    NSString *customerQuery = [NSString stringWithFormat:@"AND (r.CustomerID IS NULL OR r.CustomerID = %d)", customerID];
    
    if (customerItemsOnly)
        customerQuery = [NSString stringWithFormat:@"AND r.CustomerID = %d", customerID];
    
    NSString *itemListClause = @"";
    if (customerID > 0){
        if([AppFunctionality requiresPropertyCondition]){
            itemListClause =  @" d.LanguageCode = 0 AND r.ItemListID = 0 "; // need to remove the logic around this if/when adding special products specific rooms
        } else {
            itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND r.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", customerID];
        }
    }else{
        itemListClause = @" d.LanguageCode = 0 AND r.ItemListID = 0 ";
    }
    NSString* cmd;
    if(!includeHidden2) {
        // If showing hidden items, this branch will be used (modified from original)
        cmd = [NSString stringWithFormat:@"SELECT r.RoomID, d.Description, r.Hidden FROM Rooms r, RoomDescription d WHERE d.Description != '' "
                     "%1$@ %2$@ "
                     " AND %3$@ "
                     "AND d.RoomID = r.RoomID "
                     "ORDER BY d.Description COLLATE NOCASE ASC",
                     (limitByPVOLocation ? [NSString stringWithFormat:@"AND PVOLocationID = %d", pvoLocationID] : @"AND Hidden != 1"),
                     customerQuery,
                     itemListClause];
    } else {
        // If not showing hidden items, this branch will be used (not modified from original)
        cmd = [NSString stringWithFormat:@"SELECT r.RoomID, d.Description, r.Hidden FROM Rooms r, RoomDescription d WHERE d.Description != '' "
                         "%1$@ %2$@ "
                         " AND %3$@ "
                         "AND d.RoomID = r.RoomID "
                         "ORDER BY d.Description COLLATE NOCASE ASC",
                         (limitByPVOLocation ? [NSString stringWithFormat:@"AND PVOLocationID = %d", pvoLocationID] : @""),
                         customerQuery,
                         itemListClause];
    }
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Room alloc] init];
            item.roomID = sqlite3_column_int(stmnt, 0);
            item.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            if(includeHidden2) {
                // Include isHidden if showing hidden items
                item.isHidden = sqlite3_column_int(stmnt, 2);
            }
            //item.isHidden = sqlite3_column_int(stmnt, 2) > 0;
            
            [array addObject:item];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    return array;
}



//-(Room*)getRoom:(int)roomID
//{
//    Room *retval = nil;
//
//    sqlite3_stmt *stmnt;
//
//    NSString *cmd = [NSString stringWithFormat:@"SELECT RoomID,RoomName FROM Rooms WHERE RoomID = %d", roomID];
//    if([self prepareStatement:cmd withStatement:&stmnt])
//    {
//        while(sqlite3_step(stmnt) == SQLITE_ROW)
//        {
//            retval = [[Room alloc] init];
//
//            retval.roomID = sqlite3_column_int(stmnt, 0);
//            retval.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
//
//        }
//    }
//    sqlite3_finalize(stmnt);
//
//    return retval;
//}

-(Room*)getRoom:(int)roomID
{
    return [self getRoom:roomID WithCustomerID:-1];
}

-(Room*)getRoom:(int)roomID WithCustomerID:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    BOOL isSpecialProducts = inventory.loadType == SPECIAL_PRODUCTS; // need to remove the logic around this if/when adding special products specific rooms
    
    NSString *itemListClause = @"";
    
    if (custID > 0) {
        NSString *customClause = isSpecialProducts ? @"0" : [NSString stringWithFormat:@"(SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d)", custID];
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND r.ItemListID = %2$@", custID, customClause];
    } else {
        itemListClause = @" d.LanguageCode = 0 AND r.ItemListID = 0 ";
    }
    Room *retval = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT r.RoomID,d.Description FROM Rooms r, RoomDescription d WHERE r.RoomID = %d AND d.RoomID = r.RoomID AND %@ ", roomID, itemListClause];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[Room alloc] init];
            
            retval.roomID = sqlite3_column_int(stmnt, 0);
            retval.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(Room*)getRoomIgnoringItemListID:(int)roomID
{
    NSString *itemListClause = @" 1 = 1 ";
    
    Room *retval = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT r.RoomID,d.Description FROM Rooms r, RoomDescription d WHERE r.RoomID = %d AND d.RoomID = r.RoomID AND %@ ", roomID, itemListClause];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[Room alloc] init];
            
            retval.roomID = sqlite3_column_int(stmnt, 0);
            retval.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

- (Room *)getRoomByName:(NSString *)name languageCode:(int)languageCode itemListID:(int)itemListID
{
    NSString *itemListClause = [NSString stringWithFormat:@" d.LanguageCode = %d AND r.ItemListID = %d ", languageCode, itemListID];

    Room *retval = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT r.RoomID,d.Description FROM Rooms r, RoomDescription d WHERE d.Description = '%@' AND d.RoomID = r.RoomID AND %@ ", name, itemListClause];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[Room alloc] init];
            
            retval.roomID = sqlite3_column_int(stmnt, 0);
            retval.roomName = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(Item*)getItem:(int)itemID
{
    return [self getItem:itemID WithCustomer:-1];
}

-(Item*)getItem:(int)itemID WithCustomer:(int)custID
{
    Item *item = nil;
    
    sqlite3_stmt *stmnt;
    
    //handle having a customer ID < 0
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND i.ItemID = %d",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     itemID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
        }
    }
    sqlite3_finalize(stmnt);
    
    if (item == nil)
        item = [[Item alloc] init];
    
    if ([AppFunctionality flagAllItemsAsVehicle])
        item.isVehicle = YES;
    else if ([AppFunctionality flagAllItemsAsGun])
        item.isGun = YES;
    else if ([AppFunctionality flagAllItemsAsElectronic])
        item.isElectronic = YES;
    
    return item;
    
}



-(Item*)getItemByItemName:(NSString*)itemName
{
    [self getItemByItemName:-1 withItemName:itemName];
}

-(Item*)getItemByItemName:(int)custID withItemName:(NSString*)itemName
{//only reason this exists now is to get the NO ITEM item, instead of looping through everything several times
    //TODO: NEED TO CONVERT THIS TO USE ITEMDESCRIPTION TABLE
    Item *item = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND d.Description = %@ AND i.Hidden = 0",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     [self prepareStringForInsert:itemName]];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if (item == nil)
                item = [[Item alloc] initWithStatement:stmnt];
        }
    }
    sqlite3_finalize(stmnt);
    
    if ([AppFunctionality flagAllItemsAsVehicle])
        item.isVehicle = YES;
    else if ([AppFunctionality flagAllItemsAsGun])
        item.isGun = YES;
    else if ([AppFunctionality flagAllItemsAsElectronic])
        item.isElectronic = YES;
    
    return item;
    
}

-(Item*)getItemByItemName:(int)customerID itemName:(NSString*)itemName languageCode:(int)languageCode itemListID:(int)itemListID
{
    Item *item = nil;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND d.Description = %@ AND i.Hidden = 0",
                     [Item getItemSelectString:customerID itemListID:itemListID languageCode:languageCode withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d" withRoomID:-1],
                     [self prepareStringForInsert:itemName]];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if (item == nil)
                item = [[Item alloc] initWithStatement:stmnt];
        }
    }
    sqlite3_finalize(stmnt);
    
    if ([AppFunctionality flagAllItemsAsVehicle])
        item.isVehicle = YES;
    else if ([AppFunctionality flagAllItemsAsGun])
        item.isGun = YES;
    else if ([AppFunctionality flagAllItemsAsElectronic])
        item.isElectronic = YES;
    
    return item;
    
}

-(Item*)getVoidTagItem
{
    Item *item = nil;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT i.ItemID FROM Items i INNER JOIN ItemDescription d ON i.ItemID = d.ItemID WHERE d.Description = %@", [self prepareStringForInsert:PVO_VOID_NO_ITEM_NAME]];;
    int itemID = [self getIntValueFromQuery:cmd];
    
    if (itemID <= 0)
    {
        item = [[Item alloc] init];
        item.name = PVO_VOID_NO_ITEM_NAME;
        itemID = [self insertNewItem:item withRoomID:-1 withCustomerID:-1]; //do not attach to a customer
        
    }
    
    item = [self getItem:itemID];
    
    return item;
}

-(BOOL)includeItemInRoom:(Item*)item
{
    return TRUE;
}

-(NSMutableArray*)getAllSpecialProductItemsWithCustomerID:(int)customerID
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    Item *item;
    
    ShipmentInfo* shipInfo = [self getShipInfo:customerID];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT Items.ItemID,ItemDescription.Description,Items.IsCartonCP,Items.IsCartonPBO,Items.IsCrate,Items.IsBulky,Items.Cube,Items.CartonBulkyID,Items.IsVehicle,Items.IsGun,Items.IsElectronic "
    "FROM Items "
    "INNER JOIN ItemDescription "
    "ON Items.ItemID = ItemDescription.ItemID "
    "WHERE Items.ItemListID = 4 "
    "AND ItemDescription.LanguageCode = %d"
    " AND (Items.CustomerID IS NULL OR Items.CustomerID = %d) AND Items.Hidden = 0", shipInfo.language, customerID];
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            [items addObject:item];
        }
    }
    
    return items;
}

-(NSMutableArray*)getFavoriteSpecialProductItems
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    Item *item;
    
    NSString *cmd = @"SELECT Items.ItemID,ItemDescription.Description,Items.IsCartonCP,Items.IsCartonPBO,Items.IsCrate,Items.IsBulky,Items.Cube,Items.CartonBulkyID,Items.IsVehicle,Items.IsGun,Items.IsElectronic "
    "FROM Items "
    "INNER JOIN ItemDescription "
    "ON Items.ItemID = ItemDescription.ItemID "
    "WHERE Items.ItemListID = 4 AND Favorite = 1";
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            [items addObject:item];
        }
    }
    
    return items;
}

-(NSDictionary*)getSpecialProductDamageConditions
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSString *itemListClause = @" LanguageCode = 0 AND ItemListID = 4 ";
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DamageCode, DamageDescription FROM PVOItemDamage WHERE %@", itemListClause]  withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getSpecialProductDamageLocations
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSString *itemListClause = @" LanguageCode = 0 AND ItemListID = 4 ";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT LocationCode, LocationDescription FROM PVOItemLocations WHERE %@", itemListClause] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}


-(NSMutableArray*)getAllItemsWithPVOLocationID:(int)pvoLocationID WithCustomerID:(int)custID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    BOOL limitByPVOLocation = [self pvoLocationLimitItems:pvoLocationID];
    ItemType *itemTypes = [AppFunctionality getItemTypes:[self getCustomer:custID].pricingMode
                                          withDriverType:[self getDriverData].driverType
                                            withLoadType:[self getPVOData:custID].loadType];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND d.Description != '' AND d.Description IS NOT NULL "
                     "%@ %@ %@"
                     "ORDER BY d.Description COLLATE NOCASE ASC",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     (limitByPVOLocation ? [NSString stringWithFormat:@"AND i.PVOLocationID = %d", pvoLocationID] : @"AND i.Hidden != 1"),
                     [self getItemTypesSelection:itemTypes isFirst:NO withTableAppend:@"i"],
                     [NSString stringWithFormat:@" AND (i.CustomerID IS NULL OR i.CustomerID = %d)", custID]];
    
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            [array addObject:item];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
}

-(int)getItemListIDForItem:(Item*)item {
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT ItemListID FROM Items WHERE ItemID = %d",item.itemID]];
}

-(NSString*)getItemTypesSelection:(ItemType*)itemTypes isFirst:(BOOL)first withTableAppend:(NSString*)append
{
    NSString *select = @"";
    if (itemTypes != nil)
    {
        for (int x=0; x<2; x++)
        {
            // x = 0 hidden, x = 1 allow
            NSArray *hideAllow = (x == 0 ? itemTypes.hiddenItems : itemTypes.allowedItems);
            if (hideAllow != nil) {
                int count = 0;
                NSString *clause, *value;
                for (NSNumber *itemType in [hideAllow objectEnumerator])
                {
                    clause = [NSString stringWithFormat:@" %@%@", (first ? @"WHERE" : (x == 1 && count > 0 ? @"OR" : @"AND")), (count == 0 ? @" (" : @" ")];
                    if (append != nil && ![append isEqualToString:@""])
                        clause = [clause stringByAppendingFormat:@"%@.", append];
                    value = [NSString stringWithFormat:@" = %d", x];
                    switch ([itemType intValue]) {
                        case ITEM_TYPE_CP:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsCartonCP", value];
                            break;
                        case ITEM_TYPE_PBO:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsCartonPBO", value];
                            break;
                        case ITEM_TYPE_CRATE:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsCrate", value];
                            break;
                        case ITEM_TYPE_BULKY:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsBulky", value];
                            break;
                        case ITEM_TYPE_VEHICLE:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsVehicle", value];
                            break;
                        case ITEM_TYPE_GUN:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsGun", value];
                            break;
                        case ITEM_TYPE_ELECTRONIC:
                            count++;
                            select = [select stringByAppendingFormat:@"%@%@%@", clause, @"IsElectronic", value];
                            break;
                    }
                    if (first) first = (count == 0);
                }
                if (count > 0) select = [select stringByAppendingString:@")"];
            }
        }
    }
    return select;
}

-(NSMutableArray*)getAllItems
{
    return [self getAllItems:TRUE];
}
-(NSMutableArray*)getAllItems:(BOOL)checkInclude
{
    return [self getAllItems:checkInclude withCustomerID:-1];
}

-(NSMutableArray*)getAllItems:(BOOL)checkInclude withCustomerID:(int)customerID
{
    return [self getAllItems:checkInclude withCustomerID:customerID withHidden:false ignoreItemListId:FALSE];
}

-(NSMutableArray*)getAllItems:(BOOL)checkInclude withCustomerID:(int)customerID withHidden:(BOOL)hidden ignoreItemListId:(BOOL)ignore
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = nil;
    
    if(checkInclude) {
        if(hidden == true) {
        cmd = [NSString stringWithFormat:@"SELECT %@ "
                   " AND d.Description != '' AND d.Description IS NOT NULL "
                   "ORDER BY d.Description COLLATE NOCASE ASC",
                   [Item getItemSelectString:customerID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d" ignoreItemListId:ignore]];
        } else {
            cmd = [NSString stringWithFormat:@"SELECT %@ "
               " AND Hidden != 1 "
               " AND d.Description != '' AND d.Description IS NOT NULL "
               "ORDER BY d.Description COLLATE NOCASE ASC",
                   [Item getItemSelectString:customerID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d" ignoreItemListId:ignore]];
        }
    } else {
        //fix it down here too aaron
        cmd = [NSString stringWithFormat:@"SELECT %@ "
               "ORDER BY d.Description COLLATE NOCASE ASC",
               [Item getItemSelectString:customerID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d" ignoreItemListId:ignore]];
    }
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] init];
            
            if(hidden == true) {
                // If showing hidden items, this branch will be used (modified from original)
            item.itemID = sqlite3_column_int(stmnt, 0);
            item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            item.isCP = sqlite3_column_int(stmnt, 2);
            item.isPBO = sqlite3_column_int(stmnt, 3);
            item.isCrate = sqlite3_column_int(stmnt, 4);
            item.isBulky = sqlite3_column_int(stmnt, 5);
            item.cube = sqlite3_column_double(stmnt, 6);
            item.cartonBulkyID = sqlite3_column_int(stmnt, 7);
                item.isVehicle = sqlite3_column_int(stmnt, 8);
                item.isGun = sqlite3_column_int(stmnt, 9);
                item.isElectronic = sqlite3_column_int(stmnt, 10);
                // Notice that the hidden property is set here
                item.isHidden = sqlite3_column_int(stmnt, 11);
                if (sqlite3_column_type(stmnt,12) != SQLITE_NULL)
                    item.CNItemCode = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 12)];
            } else {
                // If not showing hidden items, this branch will be used (not modified from original)
                item.itemID = sqlite3_column_int(stmnt, 0);
                item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
                item.isCP = sqlite3_column_int(stmnt, 2);
                item.isPBO = sqlite3_column_int(stmnt, 3);
                item.isCrate = sqlite3_column_int(stmnt, 4);
                item.isBulky = sqlite3_column_int(stmnt, 5);
                item.cube = sqlite3_column_double(stmnt, 6);
                item.cartonBulkyID = sqlite3_column_int(stmnt, 7);
            if (sqlite3_column_type(stmnt, 8) != SQLITE_NULL)
                item.isVehicle = sqlite3_column_int(stmnt, 8) > 0;
            if (sqlite3_column_type(stmnt, 9) != SQLITE_NULL)
                item.isGun = sqlite3_column_int(stmnt, 9) > 0;
            if (sqlite3_column_type(stmnt,10) != SQLITE_NULL)
                item.isElectronic = sqlite3_column_int(stmnt, 10) > 0;
            if (sqlite3_column_type(stmnt,11) != SQLITE_NULL)
                item.CNItemCode = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 11)];
            }
            
            if(!checkInclude || [self includeItemInRoom:item])
                [array addObject:item];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(NSMutableArray*)getCPItemswithCustomerID:(int)custID
{
    return [self getCPItemsWithPVOLocationID:-1 withCustomerID:custID];
}

-(NSMutableArray*)getCPItemsWithPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    BOOL limitByPVOLocation = [self pvoLocationLimitItems:pvoLocationID];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     "AND (i.IsCartonCP = 1 %@) "
                     // "%@ "
                     "ORDER BY d.Description COLLATE NOCASE ASC",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     //                     ([AppFunctionality includeToteItemsInCPPBO] ? @" OR i.ItemName LIKE 'Tote%'" : @""),
                     (limitByPVOLocation ? [NSString stringWithFormat:@"AND i.PVOLocationID  = %d", pvoLocationID] : @"AND i.Hidden != 1")];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            if(limitByPVOLocation || [self includeItemInRoom:item])
                [array addObject:item];
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(NSMutableArray*)getPBOItemsWithCustomerID:(int)custID
{
    return [self getPBOItemsWithPVOLocationID:-1 withCustomerID:custID];
}

-(NSMutableArray*)getPBOItemsWithPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    BOOL limitByPVOLocation = [self pvoLocationLimitItems:pvoLocationID];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND (i.IsCartonPBO = 1 %@) "
                     //"%@ "
                     " ORDER BY d.Description COLLATE NOCASE ASC",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     //([AppFunctionality includeToteItemsInCPPBO] ? @"OR i.ItemName LIKE 'Tote%'" : @""),
                     (limitByPVOLocation ? [NSString stringWithFormat:@"AND i.PVOLocationID  = %d", pvoLocationID] : @"AND i.Hidden != 1")];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            if(limitByPVOLocation || [self includeItemInRoom:item])
                [array addObject:item];
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(NSMutableArray*)getTypicalItemsForRoom:(Room*)room withCustomerID:(int)custID
{
    return [self getTypicalItemsForRoom:room withPVOLocationID:-1 withCustomerID:custID];
}

-(NSMutableArray*)getTypicalItemsForRoom:(Room*)room withPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    BOOL limitByPVOLocation = [self pvoLocationLimitItems:pvoLocationID];
    ItemType *itemTypes = [AppFunctionality getItemTypes:[self getCustomer:custID].pricingMode
                                          withDriverType:[self getDriverData].driverType
                                            withLoadType:[self getPVOData:custID].loadType];
    
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     "%@ %@" //"AND i.Hidden != 1 "
                     "ORDER BY d.Description COLLATE NOCASE ASC",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d" withRoomID:room.roomID],
                     (limitByPVOLocation ? [NSString stringWithFormat:@"AND i.PVOLocationID = %d", pvoLocationID] : @"AND i.Hidden != 1"),
                     [self getItemTypesSelection:itemTypes isFirst:NO withTableAppend:@"i"]];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            if(limitByPVOLocation || [self includeItemInRoom:item])
                [array addObject:item];
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    //
    
    return array;
    
}


-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID
{
    return [self insertNewRoom:name withCustomerID:custID withPVOLocationID:0];
}

-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID withPVOLocationID:(int)pvoLocationID
{
    return [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:NO withPVOLocationID:pvoLocationID withCustomListID:-1 checkForAdditionalCustomItemLists:YES];
}

-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID alwaysReturnRoom:(BOOL)returnRoom
{
    return [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:0 withCustomListID:-1 checkForAdditionalCustomItemLists:YES];
}

- (void)insertRoomRecord:(BOOL)limitItemsPVOLocID pvoLocationID:(int)pvoLocationID customItemList:(int)customItemList custID:(int)custID withRoomID:(int)roomID
{
    //If we have an STG type selected change the customItemList to 0 so that when we query for rooms the room is viewable.
    if (customItemList == SPECIAL_PRODUCTS) {
        customItemList = 0;
    }
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Rooms (Hidden%@, ItemListID, CustomerID, RoomID) VALUES(0 %@,%@,%@,%d)",
                     (limitItemsPVOLocID ? @",PVOLocationID" : @""),
                     (limitItemsPVOLocID ? [NSString stringWithFormat:@",%d", pvoLocationID] : @""),
                     @(customItemList),
                     (custID <= 0 ? @"NULL" : [NSString stringWithFormat:@"%d", custID]),
                     roomID];
    [self updateDB:cmd];
    //return sqlite3_last_insert_rowid(db);
}

- (int)insertRoomDescriptionRecord:(int)roomID languageCode:(NSInteger)languageCode name:(NSString *)name
{
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO RoomDescription (RoomID, LanguageCode, Description) VALUES(%d,%@,'%@')", roomID, @(languageCode), [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    [self updateDB:cmd];
    return sqlite3_last_insert_rowid(db);
}

-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID alwaysReturnRoom:(BOOL)returnRoom withPVOLocationID:(int)pvoLocationID withCustomListID:(int)customListID checkForAdditionalCustomItemLists:(BOOL)checkForAdditionalCustomItemLists
{
    NSInteger languageCode, customItemList;
    if (custID > 0)
    {
        NSString *query1 = [NSString stringWithFormat:@"SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d", custID];
        languageCode = [self getIntValueFromQuery:query1];
        if (customListID == -1)
        {
            NSString *query2 = [NSString stringWithFormat:@"SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %d", custID];
            customItemList = [self getIntValueFromQuery:query2];
        }
        else
        {
            customItemList = customListID;
        }
    }
    else
    {
        languageCode = 0;
        customItemList = 0;
    }
    
    NSString *itemListClause = @"";
    
    if (custID > 0)
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND r.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
    else
        itemListClause = @" d.LanguageCode = 0 AND r.ItemListID = 0 ";
    
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat: @"SELECT r.RoomID,r.Hidden "
                     "FROM Rooms r, RoomDescription d"
                     " WHERE d.RoomID = r.RoomID "
                     " AND (CustomerID IS NULL OR CustomerID = %d)"
                     "AND %@ "
                     "AND d.Description = '%@'",
                     custID,
                     itemListClause,
                     [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    BOOL limitItemsPVOLocID = [self pvoLocationLimitItems:pvoLocationID];
    Room *room = nil;
    
    // So essentially "cmd" at this point will pull out an already existing room meeting the criteria of the roomID, customerID, languageCode, itemListID, customItemList, and description values being the same. If it finds a matching room, it will unhide it and make it fully usable then exit this fuction, or will move on below otherwise.
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int roomID = sqlite3_column_int(stmnt, 0);
            //if(sqlite3_column_int(stmnt, 1) == 1)
            {
                //unhide it...
                [self updateDB:[NSString stringWithFormat:@"UPDATE Rooms SET Hidden = 0%@ WHERE RoomID = %d",
                                (limitItemsPVOLocID ? [NSString stringWithFormat:@", PVOLocationID = %d", pvoLocationID] : @""),
                                roomID]];
                room = [[Room alloc] init];
                room.roomID = roomID;
                room.roomName = name;
            }
            /*else if(returnRoom)
             {
             room = [[Room alloc] init];
             room.roomID = sqlite3_column_int(stmnt, 0);
             room.roomName = name;
             }*/
            sqlite3_finalize(stmnt);
            
            // found a matching room, check for an entry for the other language
            NSInteger otherLanguageCode = (languageCode == 0 ? 1 : 0);
            NSString *query1 = [NSString stringWithFormat:@"SELECT count(*) FROM RoomDescription WHERE RoomID = %d AND LanguageCode = %@", roomID, @(otherLanguageCode)];
            NSInteger ctr = [self getIntValueFromQuery:query1];
            if (ctr == 0)
            {
                [self insertRoomDescriptionRecord:roomID languageCode:otherLanguageCode name:name];
            }
            
            if (checkForAdditionalCustomItemLists)
            {
                // make sure the other custom item list IDs are represented
                if (customItemList == 0)
                {
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:2 checkForAdditionalCustomItemLists:NO];
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:3 checkForAdditionalCustomItemLists:NO];
                }
                else if (customItemList == 2)
                {
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:0 checkForAdditionalCustomItemLists:NO];
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:3 checkForAdditionalCustomItemLists:NO];
                }
                else if (customItemList == 3)
                {
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:0 checkForAdditionalCustomItemLists:NO];
                    [self insertNewRoom:name withCustomerID:custID alwaysReturnRoom:returnRoom withPVOLocationID:pvoLocationID withCustomListID:2 checkForAdditionalCustomItemLists:NO];
                }
            }
            
            return room;
        }
    }
    //didnt exist
    sqlite3_finalize(stmnt);
    
    // Moving on... now we know the driver is trying to add a truly new room that does not exist. If this room had already existed, the code would have returned already, as you can see a few lines above this. Now the process of actually creating the room begins.
    
    // Generate new room number using MAX(maxRooms, maxRoomDescription) + 1
    int maxRooms = [self getIntValueFromQuery:@"SELECT MAX(RoomID) FROM Rooms"];
    int maxRoomDescription = [self getIntValueFromQuery:@"SELECT MAX(RoomID) FROM RoomDescription"];
    int roomID = -1;
    if(maxRooms >= maxRoomDescription) {
        // Use the rooms number
        roomID = maxRooms + 1;
    } else {
        // Use the room description number
        roomID = maxRoomDescription + 1;
    }
    
    // Added the "withRoomID" parameter here - this is the only line this function is called from so that is OK.
    [self insertRoomRecord:limitItemsPVOLocID pvoLocationID:pvoLocationID customItemList:customItemList custID:custID withRoomID:roomID];
    
    room = [[Room alloc] init];
    room.roomID = roomID; //sqlite3_last_insert_rowid(db);
    room.roomName = name;
    
    // write the description for the selected language
    cmd = [NSString stringWithFormat:@"INSERT INTO RoomDescription(RoomID,LanguageCode,Description) VALUES(%d,%@,'%@')",
           room.roomID, @(languageCode), [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    [self updateDB:cmd];
    
    NSInteger otherLanguageCode = (languageCode == 0 ? 1 : 0);
    cmd = [NSString stringWithFormat:@"INSERT INTO RoomDescription(RoomID,LanguageCode,Description) VALUES(%d,%@,'%@')", room.roomID, @(otherLanguageCode), [name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    [self updateDB:cmd];
    
    if (checkForAdditionalCustomItemLists)
    {
        // make sure the other custom item list IDs are represented
        NSArray *itemListIDs;
        if (customItemList == 0)
        {
            itemListIDs = @[ @(2), @(3) ];
        }
        else if (customItemList == 2)
        {
            itemListIDs = @[ @(0), @(3) ];
        }
        else if (customItemList == 3)
        {
            itemListIDs = @[ @(0), @(2) ];
        }else {
            itemListIDs = [[NSArray alloc] init];
        }
        
        if ([itemListIDs count] > 0) {
            for (NSNumber *itemListID in itemListIDs)
            {
                // Generate new room number using MAX(maxRooms, maxRoomDescription) + 1
                maxRooms = [self getIntValueFromQuery:@"SELECT MAX(RoomID) FROM Rooms"];
                maxRoomDescription = [self getIntValueFromQuery:@"SELECT MAX(RoomID) FROM RoomDescription"];
                roomID = -1;
                if(maxRooms >= maxRoomDescription) {
                    // Use the rooms number
                    roomID = maxRooms + 1;
                } else {
                    // Use the room description number
                    roomID = maxRoomDescription + 1;
                }
                
                int cID = [itemListID intValue];
                [self insertRoomRecord:limitItemsPVOLocID pvoLocationID:pvoLocationID customItemList:cID custID:custID withRoomID:roomID];
                for (int langCode = 0; langCode <= 1; langCode++)
                {
                    [self insertRoomDescriptionRecord:roomID languageCode:langCode name:name];
                }
            }
        }
    }

    return room;
}

-(void)updateRoomIDsForSurveyedItems:(int)oldRoomID toNewRoomID:(int)newRoomID
{
    if (oldRoomID == newRoomID)
    {
        return;
    }
    
    NSArray *tables = @ [ @"SurveyedItems", @"PVOInventoryItems", @"PVORoomConditions", @"PVOReceivableItems", @"PVODestinationRoomConditions" ];
    for (NSString *tableName in tables)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE %@ SET RoomID = %d WHERE RoomID = %d", tableName, newRoomID, oldRoomID]];
    }
}

-(void)updateItemIDsForSurveyedItems:(int)oldItemID toNewItemID:(int)newItemID
{
    if (oldItemID == newItemID)
    {
        return;
    }
    
    NSArray *tables = @ [ @"SurveyedItems", @"PVOInventoryItems", @"PVOReceivableItems" ];
    for (NSString *tableName in tables)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE %@ SET ItemID = %d WHERE ItemID = %d", tableName, newItemID, oldItemID]];
    }
}

-(NSMutableArray*)getItemsFromSurveyedItems:(SurveyedItemsList*)items
{
    return [self getItemsFromSurveyedItems:items withCustomerID:-1];
}


-(NSMutableArray*)getItemsFromSurveyedItems:(SurveyedItemsList*)items withCustomerID:(int)custID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    if([items.list count] == 0)
        return array;
    
    NSString *itemListClause = @"";
    
    if (custID > 0){
        if([AppFunctionality requiresPropertyCondition]){
            itemListClause =  @" d.LanguageCode = 0 AND i.ItemListID = 0 "; // need to remove the logic around this if/when adding special products specific rooms
        } else {
            itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
        }
    } else {
        itemListClause = @" d.LanguageCode = 0 AND i.ItemListID = 0 ";
    }
    
    NSMutableString *cmd = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"SELECT %@ "
                                                                    " AND i.ItemID IN(",
                                                                    [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"]]];
    
    NSEnumerator *enumerator = [items.list objectEnumerator];
    
    SurveyedItem *si;
    while ((si = [enumerator nextObject])) {
        [cmd appendFormat:@"%d,", si.itemID];
    }
    
    [cmd replaceCharactersInRange:NSMakeRange([cmd length]-1, 1) withString:@""];
    [cmd appendString:@") ORDER BY d.Description COLLATE NOCASE ASC"];
    
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            si = [items.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
            
            if(si.shipping > 0 || si.notShipping > 0)
            {
                [array addObject:item];
            }
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return array;
    
}

-(CrateDimensions*)getCrateDimensions: (int)surveyedID
{
    CrateDimensions *retval = [[CrateDimensions alloc] init];
    
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat: @"SELECT Length,Width,Height FROM CrateDimensions WHERE SurveyedItemID = %d", surveyedID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.length = sqlite3_column_int(stmnt, 0);
            retval.width = sqlite3_column_int(stmnt, 1);
            retval.height = sqlite3_column_int(stmnt, 2);
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)getItemComment: (int)surveyedID
{
    NSString *retval = [[NSString alloc] initWithString:@""];
    
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat: @"SELECT Comment FROM Comments WHERE SurveyedItemID = %d", surveyedID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            
            retval = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}
-(void)setItemComment: (int)surveyedID withCommentText:(NSString*)comment
{
    NSString *cmd;
    
    if([comment length] == 0)
        cmd = [[NSString alloc] initWithFormat:@"DELETE FROM Comments WHERE SurveyedItemID = %d", surveyedID];
    else
    {
        sqlite3_stmt *stmnt;
        NSString *sel = [[NSString alloc] initWithFormat: @"SELECT Comment FROM Comments WHERE SurveyedItemID = %d", surveyedID];
        
        if([self prepareStatement:sel withStatement:&stmnt])
        {
            if(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                cmd = [[NSString alloc] initWithFormat:@"UPDATE Comments SET Comment = '%@' WHERE SurveyedItemID = %d",
                       [comment stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                       surveyedID];
            }
            else
            {
                cmd = [[NSString alloc] initWithFormat:@"INSERT INTO Comments(SurveyedItemID,Comment) VALUES(%d,'%@')", surveyedID,
                       [comment stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            }
        }
        
        sqlite3_finalize(stmnt);
        
        
        
    }
    
    [self updateDB:cmd];
    
    
    
}

-(void)setCrateDimensions:(int)surveyedID withDimensions:(CrateDimensions*)dims
{
    NSString *cmd;
    //"Length,Width,Height FROM CrateDimensions WHERE SurveyedItemID"
    if(dims == nil)
        cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CrateDimensions WHERE SurveyedItemID = %d", surveyedID];
    else
    {
        sqlite3_stmt *stmnt;
        NSString *sel = [[NSString alloc] initWithFormat: @"SELECT Length FROM CrateDimensions WHERE SurveyedItemID = %d", surveyedID];
        
        if([self prepareStatement:sel withStatement:&stmnt])
        {
            if(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                cmd = [[NSString alloc] initWithFormat:@"UPDATE CrateDimensions SET "
                       "Length = %d,"
                       "Width = %d,"
                       "Height = %d WHERE SurveyedItemID = %d", dims.length, dims.width, dims.height, surveyedID];
            }
            else
            {
                cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CrateDimensions(SurveyedItemID,Length,Width,Height) VALUES(%d,%d,%d,%d)",
                       surveyedID, dims.length, dims.width, dims.height];
            }
        }
        
        sqlite3_finalize(stmnt);
        
        
    }
    
    [self updateDB:cmd];
    
    
    
}

-(SurveyedItemsList*)getRoomSurveyedItems:(Room*)room withCubesheetID:(int)csID
{
    return [self getRoomSurveyedItems:room withCubesheetID:csID overrideLimit:YES];
}

-(SurveyedItemsList*)getRoomSurveyedItems:(Room*)room withCubesheetID:(int)csID overrideLimit:(BOOL)noLimit
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ItemType *itemTypes = [AppFunctionality getItemTypes:[self getCustomer:del.customerID].pricingMode
                                          withDriverType:[self getDriverData].driverType
                                            withLoadType:[self getPVOData:del.customerID].loadType];
    
    SurveyedItemsList *array = [[SurveyedItemsList alloc] init];
    SurveyedItem *item;
    
    array.room = room;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT si.SurveyedItemID,si.CubeSheetID,si.ItemID,si.RoomID,si.Shipping,si.NotShipping,"
                     "si.Packing,si.Unpacking,si.Cube,si.Weight"
                     " FROM SurveyedItems si, Items i"
                     " WHERE si.ItemID = i.ItemID"
                     " AND si.RoomID = %d AND si.CubeSheetID = %d"
                     "%@",
                     room.roomID, csID,
                     (noLimit ? @"" : [self getItemTypesSelection:itemTypes isFirst:NO withTableAppend:@"i"])];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyedItem alloc] init];
            
            item.siID = sqlite3_column_int(stmnt, 0);
            item.csID = sqlite3_column_int(stmnt, 1);
            item.itemID = sqlite3_column_int(stmnt, 2);
            item.roomID = sqlite3_column_int(stmnt, 3);
            item.shipping = sqlite3_column_int(stmnt, 4);
            item.notShipping = sqlite3_column_int(stmnt, 5);
            item.packing = sqlite3_column_int(stmnt, 6);
            item.unpacking = sqlite3_column_int(stmnt, 7);
            item.cube = sqlite3_column_double(stmnt, 8);
            item.weight = sqlite3_column_int(stmnt, 9);
            
            [array.list setObject:item forKey:[NSString stringWithFormat:@"%d", item.itemID]];
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(SurveyedItemsList*)getSurveyedPackingItems:(int)csID
{
    SurveyedItemsList *array = [[SurveyedItemsList alloc] init];
    SurveyedItem *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT si.SurveyedItemID,si.CubeSheetID,si.ItemID,"
                     "si.RoomID,si.Shipping,si.NotShipping,si.Packing,si.Unpacking,si.Cube,si.Weight"
                     " FROM SurveyedItems si,Items i WHERE "
                     " si.ItemID = i.ItemID"
                     " AND si.Packing > 0"
                     " AND si.CubeSheetID = %d", csID];
    
    SurveyedItem *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyedItem alloc] init];
            
            item.siID = sqlite3_column_int(stmnt, 0);
            item.csID = sqlite3_column_int(stmnt, 1);
            item.itemID = sqlite3_column_int(stmnt, 2);
            item.roomID = sqlite3_column_int(stmnt, 3);
            
            //check to see if it exsits, then add to... (cube and weight dissapears but that shouldnt matter...)
            temp = [array.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
            if(temp != NULL)
            {
                
                item = temp;
            }
            
            item.shipping = sqlite3_column_int(stmnt, 4); // this used to be += no idea why.
            item.notShipping = sqlite3_column_int(stmnt, 5);// this used to be += no idea why.
            item.packing = sqlite3_column_int(stmnt, 6);// this used to be += no idea why.
            item.unpacking = sqlite3_column_int(stmnt, 7);// this used to be += no idea why.
            item.cube = sqlite3_column_double(stmnt, 8);
            item.weight = sqlite3_column_int(stmnt, 9);
            
            [array.list setObject:item forKey:[NSString stringWithFormat:@"%d", item.itemID]];
            
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if([array.list count] > 0)
    {
        [array fillItems];
    }
    
    
    return array;
    
}


-(SurveyedItemsList*)getBulkies:(int)custID
{
    SurveyedItemsList *array = [[SurveyedItemsList alloc] init];
    SurveyedItem *item;
    CubeSheet *cs = [self openCubeSheet:custID];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT si.SurveyedItemID,si.CubeSheetID,si.ItemID,"
                     "si.RoomID,si.Shipping,si.NotShipping,si.Packing,si.Unpacking,si.Cube,si.Weight"
                     " FROM SurveyedItems si,Items i WHERE "
                     " si.ItemID = i.ItemID"
                     " AND i.IsBulky = 1"
                     " AND si.CubeSheetID = %d", cs.csID];
    SurveyedItem *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyedItem alloc] init];
            
            item.siID = sqlite3_column_int(stmnt, 0);
            item.csID = sqlite3_column_int(stmnt, 1);
            item.itemID = sqlite3_column_int(stmnt, 2);
            item.roomID = sqlite3_column_int(stmnt, 3);
            
            //check to see if it exsits, then add to... (cube and weight dissapears but that shouldnt matter...)
            temp = [array.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
            if(temp != NULL)
            {
                
                item = temp;
            }
            
            item.shipping += sqlite3_column_int(stmnt, 4);
            item.notShipping += sqlite3_column_int(stmnt, 5);
            item.packing += sqlite3_column_int(stmnt, 6);
            item.unpacking += sqlite3_column_int(stmnt, 7);
            item.cube = sqlite3_column_double(stmnt, 8);
            item.weight = sqlite3_column_int(stmnt, 9);
            
            [array.list setObject:item forKey:[NSString stringWithFormat:@"%d", item.itemID]];
            
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if([array.list count] > 0)
    {
        [array fillItems];
    }
    
    return array;
    
}
-(SurveyedItemsList*)getCrates:(int)custID
{
    SurveyedItemsList *array = [[SurveyedItemsList alloc] init];
    SurveyedItem *item;
    CubeSheet *cs = [self openCubeSheet:custID];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT si.SurveyedItemID,si.CubeSheetID,si.ItemID,"
                     "si.RoomID,si.Shipping,si.NotShipping,si.Packing,si.Unpacking,si.Cube,si.Weight"
                     " FROM SurveyedItems si,Items i WHERE "
                     " si.ItemID = i.ItemID"
                     " AND i.IsCrate = 1"
                     " AND si.CubeSheetID = %d", cs.csID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyedItem alloc] init];
            
            item.siID = sqlite3_column_int(stmnt, 0);
            item.csID = sqlite3_column_int(stmnt, 1);
            item.itemID = sqlite3_column_int(stmnt, 2);
            item.roomID = sqlite3_column_int(stmnt, 3);
            item.shipping = sqlite3_column_int(stmnt, 4);
            item.notShipping = sqlite3_column_int(stmnt, 5);
            item.packing = sqlite3_column_int(stmnt, 6);
            item.unpacking = sqlite3_column_int(stmnt, 7);
            item.cube = sqlite3_column_double(stmnt, 8);
            item.weight = sqlite3_column_int(stmnt, 9);
            
            item.dims = [self getCrateDimensions:item.siID];
            
            //do these separately (base on surveyed item id instead of item id)
            [array.list setObject:item forKey:[NSString stringWithFormat:@"%d", item.siID]];
            
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if([array.list count] > 0)
    {
        [array fillItems];
    }
    
    
    
    
    return array;
    
}


-(SurveyedItemsList*)getCPs:(int)custID
{
    return [self getCartons:custID isCP:YES];
}

-(SurveyedItemsList*)getPBOs:(int)custID
{
    return [self getCartons:custID isCP:NO];
}

-(SurveyedItemsList*)getCartons:(int)custID isCP:(BOOL)cp
{
    SurveyedItemsList *array = [[SurveyedItemsList alloc] init];
    SurveyedItem *item;
    CubeSheet *cs = [self openCubeSheet:custID];
    
    NSString *itemListClause = @"";
    
    if (custID > 0)
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
    else
        itemListClause = @" d.LanguageCode = 0 AND i.ItemListID = 0 ";
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT si.SurveyedItemID,si.CubeSheetID,si.ItemID,"
                     "si.RoomID,si.Shipping,si.NotShipping,si.Packing,si.Unpacking,si.Cube,si.Weight"
                     " FROM SurveyedItems si,Items i, ItemDescription d WHERE "
                     " si.ItemID = i.ItemID"
                     " AND %@"
                     " AND si.CubeSheetID = %d"
                     " AND d.ItemID = i.ItemID "
                     " AND %@ "
                     " ORDER BY d.Description COLLATE NOCASE ASC",
                     cp ? @"i.IsCartonCP = 1" : @"i.IsCartonPBO = 1",
                     cs.csID,
                     itemListClause];
    SurveyedItem *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyedItem alloc] init];
            
            item.siID = sqlite3_column_int(stmnt, 0);
            item.csID = sqlite3_column_int(stmnt, 1);
            item.itemID = sqlite3_column_int(stmnt, 2);
            item.roomID = sqlite3_column_int(stmnt, 3);
            
            //check to see if it exsits, then add to... (cube and weight dissapears but that shouldnt matter...)
            temp = [array.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
            if(temp != NULL)
            {
                
                item = temp;
            }
            
            item.shipping = item.shipping + sqlite3_column_int(stmnt, 4);
            item.notShipping = item.notShipping + sqlite3_column_int(stmnt, 5);
            item.packing = item.packing + sqlite3_column_int(stmnt, 6);
            item.unpacking = item.unpacking + sqlite3_column_int(stmnt, 7);
            item.cube = item.cube + sqlite3_column_double(stmnt, 8);
            item.weight = item.weight + sqlite3_column_int(stmnt, 9);
            
            [array.list setObject:item forKey:[NSString stringWithFormat:@"%d", item.itemID]];
            
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if([array.list count] > 0)
    {
        [array fillItems];
    }
    
    
    return array;
    
}

-(NSMutableArray*)getAllSurveyedItems:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    CubeSheet *cs = [self openCubeSheet:custID];
    NSArray *summaries = [self getAllRoomSummaries:cs customerID:custID];
    SurveyedItemsList *current;
    RoomSummary *currentRm;
    NSArray *items = [self getAllItems];
    for(int i = 0; i < [summaries count]; i++)
    {
        currentRm = [summaries objectAtIndex:i];
        current = [self getRoomSurveyedItems:currentRm.room withCubesheetID:cs.csID];
        [current fillItems:items];
        [retval addObject:current];
    }
    
    return retval;
}

-(NSMutableArray*)getRoomSummaries:(CubeSheet*)cs customerID:(int)custID
{
    return [self getRoomSummaries:cs overrideLimit:YES customerID:custID ignoreItemListID:NO];
}

-(NSMutableArray*)getAllRoomSummaries:(CubeSheet*)cs customerID:(int)custID
{
    return [self getRoomSummaries:cs overrideLimit:YES customerID:custID ignoreItemListID:YES];
}

-(NSMutableArray*)getRoomSummaries:(CubeSheet*)cs overrideLimit:(BOOL)noLimit customerID:(int)custID ignoreItemListID:(BOOL)ignoreItemListID
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    RoomSummary *item;
    SurveyedItemsList *siList;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd;
    if (ignoreItemListID)
    {
        cmd = [[NSString alloc] initWithFormat:@"SELECT DISTINCT(r.RoomID),d.Description FROM Rooms r, SurveyedItems si, RoomDescription d"
               " WHERE si.RoomID = r.RoomID "
               " AND r.RoomID = d.RoomID "
               " AND si.CubeSheetID = %d "
               " AND d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d) "
               " ORDER BY d.Description COLLATE NOCASE ASC", cs.csID, custID];
    }
    else
    {
        cmd = [[NSString alloc] initWithFormat:@"SELECT DISTINCT(r.RoomID),d.Description FROM Rooms r, SurveyedItems si, RoomDescription d"
                     " WHERE si.RoomID = r.RoomID "
                     " AND r.RoomID = d.RoomID "
                     " AND si.CubeSheetID = %d "
                     " AND r.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %d) "
                     " AND d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d) "
                     " ORDER BY d.Description COLLATE NOCASE ASC", cs.csID, custID, custID];
    }
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[RoomSummary alloc] init];
            
            Room * tempr = [[Room alloc] init];
            item.room = tempr;
            item.room.roomID = sqlite3_column_int(stmnt, 0);
            item.room.roomName = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            
            siList = [self getRoomSurveyedItems:item.room withCubesheetID:cs.csID overrideLimit:noLimit];
            
            if([siList totalShipping] == 0 && [siList totalNotShipping] == 0)
            {
                continue;
            }
            
            item.shipping = [siList totalShipping];
            item.notShipping = [siList totalNotShipping];
            item.cube = [siList totalCube];
            item.weight = [siList totalWeight:cs.weightFactor];
            
            [array addObject:item];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return array;
    
}

-(void)saveSurveyedItems:(SurveyedItemsList*)surveyedItems
{
    NSEnumerator *enumerator = [surveyedItems.list objectEnumerator];
    
    SurveyedItem *si;
    
    while ((si = [enumerator nextObject])) {
        if(si.siID == -1)
        {//create new
            [self insertNewSurveyedItem:si];
        }
        else
        {//update
            [self updateSurveyedItem:si];
        }
    }
    
    return;
}

-(void)updateSurveyedItem:(SurveyedItem*)surveyedItem
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE SurveyedItems SET "
                     "Shipping = %d, "
                     "NotShipping = %d, "
                     "Packing = %d, "
                     "Unpacking = %d, "
                     "Cube = %f, "
                     "Weight = %d "
                     "WHERE SurveyedItemID = %d",
                     surveyedItem.shipping,
                     surveyedItem.notShipping,
                     surveyedItem.packing,
                     surveyedItem.unpacking,
                     surveyedItem.cube,
                     surveyedItem.weight,
                     surveyedItem.siID];
    
    
    [self updateDB:cmd];
    
    
}


-(int)getItemIDFromCartonID:(int)cartonID isCP:(BOOL)isCP
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT ItemID FROM Items WHERE CartonBulkyID = %d AND %@",
                     cartonID, isCP ? @"IsCartonCP = 1" : @"IsCartonPBO = 1"];
    int retval = -1;
    
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

-(int)insertNewSurveyedItem:(SurveyedItem*)surveyedItem
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"INSERT INTO SurveyedItems"
                     "(CubeSheetID, ItemID, RoomID, Shipping, NotShipping, Packing, Unpacking, Cube, Weight)"
                     " VALUES(%d,%d,%d,%d,%d,%d,%d,%f,%d)",
                     surveyedItem.csID,
                     surveyedItem.itemID,
                     surveyedItem.roomID,
                     surveyedItem.shipping,
                     surveyedItem.notShipping,
                     surveyedItem.packing,
                     surveyedItem.unpacking,
                     surveyedItem.cube,
                     surveyedItem.weight];
    
    [self updateDB:cmd];
    
    
    
    return sqlite3_last_insert_rowid(db);
}

-(int)getItemID:(NSString *)itemName withCube:(double)cube
{
    return [self getItemID:itemName withCube:cube withCustomerID:-1];
}

-(int)getItemID:(NSString *)itemName withCube:(double)cube withCustomerID:(int)customerID
{
    NSString *itemListClause = @"";
    
    if (customerID > 0)
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", customerID];
    else
        itemListClause = @" d.LanguageCode = 0 AND i.ItemListID = 0 ";
    
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT i.ItemID FROM Items i, ItemDescription d WHERE d.Description = '%@' AND i.ItemID = d.ItemID AND i.Cube = %f AND %@",
                                       [itemName stringByReplacingOccurrencesOfString:@"'" withString:@"''"], cube, itemListClause]];
}

-(int)getNextNewItemID
{
    // Generate new room number using MAX(maxItems, maxItemDescription) + 1
    int maxItems = [self getIntValueFromQuery:@"SELECT MAX(ItemID) FROM Items"];
    int maxItemDescription = [self getIntValueFromQuery:@"SELECT MAX(ItemID) FROM ItemDescription"];
    int itemID = -1;
    if(maxItems >= maxItemDescription) {
        // Use the rooms number
        itemID = maxItems + 1;
    } else {
        // Use the room description number
        itemID = maxItemDescription + 1;
    }
    
    //int retval = [self getIntValueFromQuery:@"SELECT MAX(ItemID) FROM ItemDescription"];
    return itemID;
}

-(int)insertNewItem:(Item*)item withRoomID:(int)roomID
{
    return [self insertNewItem:item withRoomID:roomID withCustomerID:-1 withPVOLocationID:0];
}

-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID
{
    return [self insertNewItem:item withRoomID:roomID withCustomerID:customerID withPVOLocationID:0];
}

-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID withPVOLocationID:(int)pvoLocationID
{
    return [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:YES withPVOLocationID:pvoLocationID];
}

-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    //BOOL isSpecialProducts = inventory.loadType == SPECIAL_PRODUCTS; // need to remove this if/when making special products specific rooms.
    
    return [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID appDelegate:del];
}

-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID appDelegate:(SurveyAppDelegate *)del
{
    int languageCode = [del.surveyDB getLanguageForCustomer:customerID];
    int itemListId = [del.surveyDB getCustomerItemListID:customerID];
    
    return [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:itemListId checkForAdditionalCustomItemLists:YES];
}


-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID withLanguageCode:(int)languageCode withItemListId:(int)itemListId checkForAdditionalCustomItemLists:(BOOL)checkForAdditionalCustomItemLists
{
//    if(customerID == 0){
//        //if new customer, we need to grab loadtype from pvoinventorydata
//        SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
//        PVOInventory *p = [del.surveyDB getPVOData:customerID];
//        itemListId = p.loadType;
//    }
    
    NSString *itemListClause = [NSString stringWithFormat:@" d.LanguageCode = %d AND i.ItemListID = %d ", languageCode, itemListId];
    
    if(item == nil || [item.name length] == 0)
        return -1;

    
    BOOL limitItemsPVOLocID = [self pvoLocationLimitItems:pvoLocationID];
    
    
    sqlite3_stmt *stmnt;
    NSString *cmd = nil;
    
    NSString *customerIDClause = @"";
    if (customerID > 0)
    {
        customerIDClause = [NSString stringWithFormat:@"AND (CustomerID = %d OR CustomerID IS NULL) ", customerID];
    }
    
    cmd = [NSString stringWithFormat:@"SELECT i.ItemID FROM Items i, ItemDescription d WHERE d.Description = '%@' AND i.ItemID = d.ItemID %@ AND %@",
           [item.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"], customerIDClause, itemListClause];
    
    if (includeCube)
    {
        cmd = [cmd stringByAppendingString:[NSString stringWithFormat:@" AND i.Cube = %f ", item.cube]];
    }
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if (sqlite3_step(stmnt) == SQLITE_ROW)
        {//item already exists
            
            item.itemID = sqlite3_column_int(stmnt, 0);
            sqlite3_finalize(stmnt);
            
            cmd = [NSString stringWithFormat:@"UPDATE Items SET Hidden = 0%1$@ WHERE ItemID = (SELECT ItemID FROM ItemDescription WHERE Description = '%2$@' AND LanguageCode = %3$d) AND ItemListID = %4$d ",
                   (limitItemsPVOLocID ? [NSString stringWithFormat:@", PVOLocationID = %d", pvoLocationID] : @""),
                   [item.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                   languageCode,
                   itemListId];
            
            if (includeCube)
            {
                cmd = [cmd stringByAppendingString:[NSString stringWithFormat:@" AND Cube = %f ", item.cube]];
            }
            
            [self updateDB:cmd];
            
            [self sanityCheck];
            
            // found a matching item, check for an entry for the other language
            NSInteger otherLanguageCode = (languageCode == 0 ? 1 : 0);
            NSString *query1 = [NSString stringWithFormat:@"SELECT count(*) FROM ItemDescription WHERE ItemID = %@ AND LanguageCode = %@", @(item.itemID), @(otherLanguageCode)];
            NSInteger ctr = [self getIntValueFromQuery:query1];
            if (ctr == 0)
            {
                query1 = [NSString stringWithFormat:@"INSERT INTO ItemDescription"
                          "(ItemID,LanguageCode,Description)"
                          " VALUES(%@,%@,'%@')",
                          @(item.itemID), @(otherLanguageCode), [item.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
                [self updateDB:query1];
            }

            // make sure that the other custom list IDs are represented
            if (checkForAdditionalCustomItemLists)
            {
                if (itemListId == 0)
                {
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:2 checkForAdditionalCustomItemLists:NO];
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:3 checkForAdditionalCustomItemLists:NO];
                }
                else if (itemListId == 2)
                {
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:0 checkForAdditionalCustomItemLists:NO];
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:3 checkForAdditionalCustomItemLists:NO];
                }
                else if (itemListId == 3)
                {
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:0 checkForAdditionalCustomItemLists:NO];
                    [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:2 checkForAdditionalCustomItemLists:NO];
                }
            }
            
            return item.itemID;
        }
    }
    
    //didn't exist
    sqlite3_finalize(stmnt);
    
    int newItemID = [self getNextNewItemID];
    item.itemID = newItemID;
    
    cmd = [NSString stringWithFormat:@"INSERT INTO Items"
           "(ItemID,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,IsVehicle,IsGun,IsElectronic,%@ItemListID,Favorite%@)"
           " VALUES(%d,%d,%d,%d,%d,%f,%d,%d,%d%@,%d,%d%@)",
           (limitItemsPVOLocID ? @",PVOLocationID" : @""),
           (customerID > 0 ? @",CustomerID" : @""),
           newItemID,
           item.isCP, item.isPBO, item.isCrate, item.isBulky, item.cube, item.isVehicle, item.isGun, item.isElectronic,
           (limitItemsPVOLocID ? [NSString stringWithFormat:@",%d", pvoLocationID] : @""), itemListId, 0,
           (customerID > 0 ? [NSString stringWithFormat:@",%d", customerID] : @"")]; //customerID is expected to be null if not assigned to a customer
    
    [self updateDB:cmd];
    
    cmd = [NSString stringWithFormat:@"INSERT INTO ItemDescription"
           "(ItemID,LanguageCode,Description)"
           " VALUES(%d,%d,'%@')",
           newItemID, languageCode, [item.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    
    [self updateDB:cmd];
    
    // write the other language with the same text
    NSInteger otherLanguageCode = (languageCode == 0 ? 1 : 0);
    NSString *theItemName = item.name;
    if (otherLanguageCode == 1 && [item.nameFrench length] > 0)
    {
        theItemName = item.nameFrench;
    }
    
    cmd = [NSString stringWithFormat:@"INSERT INTO ItemDescription"
           "(ItemID,LanguageCode,Description)"
           " VALUES(%d,%@,'%@')",
           newItemID, @(otherLanguageCode), [theItemName stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    
    [self updateDB:cmd];
    
    if(roomID != -1)
    {
        cmd = [NSString stringWithFormat:@"INSERT INTO MasterItemList VALUES(%d,%d)", roomID, newItemID];
        [self updateDB:cmd];
    }
    
    // make sure that the other custom list IDs are represented
    if (checkForAdditionalCustomItemLists)
    {
        if (itemListId == 0)
        {
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:2 checkForAdditionalCustomItemLists:NO];
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:3 checkForAdditionalCustomItemLists:NO];
        }
        else if (itemListId == 2)
        {
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:0 checkForAdditionalCustomItemLists:NO];
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:3 checkForAdditionalCustomItemLists:NO];
        }
        else if (itemListId == 3)
        {
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:0 checkForAdditionalCustomItemLists:NO];
            [self insertNewItem:item withRoomID:roomID withCustomerID:customerID includeCubeInValidation:includeCube withPVOLocationID:pvoLocationID withLanguageCode:languageCode withItemListId:2 checkForAdditionalCustomItemLists:NO];
        }
    }
    
    [self sanityCheck];
    
    return newItemID;
}

-(void)deleteCubeSheet:(int)customerID
{
    CubeSheet *cs = [self openCubeSheet:customerID];
    
    if(cs != nil)
    {
        //delete the comments and crate dimensions
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM Comments WHERE SurveyedItemID IN("
                        "SELECT SurveyedItemID FROM SurveyedItems WHERE CubesheetID = %d)", cs.csID]];
        
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM CrateDimensions WHERE SurveyedItemID IN("
                        "SELECT SurveyedItemID FROM SurveyedItems WHERE CubesheetID = %d)", cs.csID]];
        
        NSString *cmd = [[NSString alloc] initWithFormat:@"DELETE FROM SurveyedItems WHERE CubeSheetID = %d", cs.csID];
        [self updateDB:cmd];
        
        
        cmd = [[NSString alloc] initWithFormat:@"DELETE FROM CubeSheets WHERE CustomerID = %d", customerID];
        [self updateDB:cmd];
        
    }
    
    
}

-(CubeSheet*)openCubeSheet:(int)customerID
{
    CubeSheet *cs;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT CubeSheetID,CustomerID,WeightFactor FROM CubeSheets WHERE CustomerID = %d", customerID];
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        cs = [[CubeSheet alloc] init];
        cs.custID = customerID;
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            cs.csID = sqlite3_column_int(stmnt, 0);
            cs.weightFactor = sqlite3_column_double(stmnt, 2);
        }
        else
        {
            
            cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CubeSheets(CustomerID,WeightFactor) VALUES(%d,7.00)", customerID];
            [self updateDB:cmd];
            cs.weightFactor = 7.0;
            cs.csID = sqlite3_last_insert_rowid(db);
        }
    }
    sqlite3_finalize(stmnt);
    
    
    
    return cs;
    
}

-(void)updateCubeSheet:(CubeSheet*)cs
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE CubeSheets SET WeightFactor = %f WHERE CubeSheetID = %d", cs.weightFactor, cs.csID]];
}

-(void)hideItem:(int)itemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Items SET Hidden = 1, PVOLocationID = 0 WHERE ItemID = %d", itemID]];
}

-(void)unHideItem:(int)itemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Items SET Hidden = 0, PVOLocationID = 0 WHERE ItemID = %d", itemID]];
}

-(void)hideRoom:(int)roomID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Rooms SET Hidden = 1, PVOLocationID = 0 WHERE RoomID = %d", roomID]];
}

-(void)unHideRoom:(int)roomID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Rooms SET Hidden = 0, PVOLocationID = 0 WHERE RoomID = %d", roomID]];
}


#pragma mark Photo Storage methods

-(NSString*)getPhotoSavePath:(int)customerID withPhotoType:(int)type withSubID:(int)subID
{
    
    sqlite3_stmt *stmnt;
    NSString *cmd;
    
    SurveyCustomer *cust = [self getCustomer:customerID];
    PVOInventory *p = [self getPVOData:customerID];

    cmd = [[NSString alloc] initWithFormat:@"SELECT COUNT(*) FROM Images "
           " WHERE"
           " CustomerID = %d AND "
           " SubID = %d AND "
           " PhotoType = %d", customerID, subID, type];
   
    int count = 0;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            count = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    
    NSString *filename;
    if(type == IMG_SURVEYED_ITEMS)
    {
        //get the item and room name
        cmd = [[NSString alloc] initWithFormat:@"SELECT d.Description, rd.Description FROM Items i,Rooms r,SurveyedItems si, ItemDescription d, RoomDescription rd"
               " WHERE"
               " si.SurveyedItemID = %d AND "
               " si.RoomID = r.RoomID AND "
               " si.ItemID = i.ItemID AND "
               " d.ItemID = i.ItemID AND "
               " i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %d) AND "
               " rd.RoomID = r.RoomID AND "
               " d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d) ", subID, customerID, customerID];

        
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            if(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                filename = [[NSString alloc] initWithFormat:@"%@ - %@[%d].jpeg",
                            [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)],
                            [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)],
                            count];
            }
        }
        sqlite3_finalize(stmnt);
        
        
    }
    else if(type == IMG_ROOMS)
    {
        //get the room name
        Room *rm = [self getRoom:subID];
        filename = [[NSString alloc] initWithFormat:@"%@[%d].jpeg", rm.roomName, count];
    }
    else if(type == IMG_LOCATIONS)
    {
        filename = [[NSString alloc] initWithFormat:@"%@[%d].jpeg",
                    (subID == ORIGIN_LOCATION_ID ? @"Origin" :
                     (subID == DESTINATION_LOCATION_ID ? @"Destination" :
                      [NSString stringWithFormat:@"ExtraStop[%d]", subID])), //need to insert unique key for ex stops
                    count];
    }
    else
    {
        NSDate *date = [NSDate date];
        filename = [[NSString alloc] initWithFormat:@"(%d)[%lli].jpeg", subID, [@(floor([date timeIntervalSince1970] * 1000)) longLongValue]];
    }
    
    
    NSString *directory = [[NSString alloc] initWithFormat:@"/%@/%@ (%d)/%@/",
                           IMG_ROOT_DIRECTORY, cust.lastName, customerID,
                           type == IMG_SURVEYED_ITEMS ? IMG_SI_DIRECTORY :
                           type == IMG_LOCATIONS ? IMG_LOCATIONS_DIRECTORY :
                           type == IMG_PVO_ITEMS ? IMG_PVO_ITEMS_DIRECTORY :
                           type == IMG_PVO_DESTINATION_ITEMS ? IMG_PVO_ITEMS_DIRECTORY :
                           type == IMG_PVO_ROOMS ? IMG_PVO_ROOMS_DIRECTORY :
                           type == IMG_PVO_DESTINATION_ROOMS ? IMG_PVO_DESTINATION_ROOMS_DIRECTORY :
                           type == IMG_PVO_CLAIM_ITEMS ? IMG_PVO_CLAIM_ITEMS_DIRECTORY :
                           type == IMG_PVO_WEIGHT_TICKET ? IMG_PVO_WEIGHT_TICKET_DIRECTORY :
                           type == IMG_PVO_VEHICLE_DAMAGES ? IMG_PVO_VEHICLES_DIRECTORY :
                           IMG_ROOMS_DIRECTORY];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullDirectory = [documentsDirectory stringByAppendingPathComponent:directory];
    NSError *error;
    BOOL isDir = YES;
    if(![fileManager fileExistsAtPath:fullDirectory isDirectory:&isDir])
    {
        if(![fileManager createDirectoryAtPath:fullDirectory withIntermediateDirectories:YES attributes:nil error:&error])
            [SurveyAppDelegate showAlert:[error localizedDescription] withTitle:@"Error creating Directory"];
    }
    
    NSString *retval = [[NSString alloc] initWithString:
                        [directory stringByAppendingPathComponent:
                         [filename stringByReplacingOccurrencesOfString:@"/" withString:@" "]]];//rid file name of slashes
    
    return retval;
    
}

-(int)addNewImageEntry:(int)customerID withPhotoType:(int)type withSubID:(int)subID withPath:(NSString*)path
{
    
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Images(CustomerID,SubID,PhotoType,Path) VALUES(%d,%d,%d,'%@')",
                     customerID, subID, type, [path stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    [self updateDB:cmd];
    
    int imageId = sqlite3_last_insert_rowid(db);
    return imageId;
}

-(void)deleteImageEntry:(int)imageID
{
    
    NSString *cmd = [NSString stringWithFormat:@"DELETE FROM Images WHERE ImageID = %d", imageID];
    [self updateDB:cmd];
    
}

//will select the min image id for the item to be uploaded (need one id, one item)
-(int)getImageSyncID:(int)customerID withPhotoType:(int)type withSubID:(int)subID
{
    NSString *cmd;
    sqlite3_stmt *stmnt;
    int imageID = 0;
    cmd = [[NSString alloc] initWithFormat:@"SELECT MIN(ImageID) FROM Images "
           " WHERE"
           " CustomerID = %d AND "
           " SubID = %d AND "
           " PhotoType = %d", customerID, subID, type];
    
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            imageID = sqlite3_column_int(stmnt, 0);
        }
    }
    
    
    
    return imageID;
}

-(NSString*)getImageDescription:(SurveyImage*)imageDetails
{
    
    NSString *retval = @"";
    
    switch (imageDetails.photoType) {
        case IMG_SURVEYED_ITEMS:
            retval = [NSString stringWithFormat:@"Survey - %@, %@",
                      [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT rd.Description "
                                                     "FROM SurveyedItems si, RoomDescription rd "
                                                     "JOIN Rooms r ON r.RoomID = si.RoomID "
                                                     "WHERE si.SurveyedItemID = %d "
                                                     "AND rd.RoomID = r.RoomID ",
                                                     imageDetails.subID]],
                      [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT d.Description "
                                                     "FROM SurveyedItems si, ItemDescription d "
                                                     "JOIN Items i ON si.ItemID = i.ItemID "
                                                     "WHERE si.SurveyedItemID = %d "
                                                     "AND rd.RoomID = r.RoomID ",
                                                     imageDetails.subID]]];
            break;
        case IMG_LOCATIONS:
            if (imageDetails.subID == 1) {
                retval = @"Origin";
            } else if (imageDetails.subID == 2) {
                retval = @"Destination";
            } else {
                retval = [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT "
                                                        "CASE WHEN l.LocationType = 1 THEN 'Origin' "
                                                        "WHEN l.LocationType = 2 THEN 'Destination' "
                                                        "WHEN l.IsOrigin = 1 THEN 'Origin Extra Stop' "
                                                        "WHEN l.IsOrigin = 0 THEN 'Destination Extra Stop' END "
                                                        "FROM Locations l WHERE LocationID = %d", imageDetails.subID]];
            }
            break;
        case IMG_PVO_ITEMS:
            retval = [NSString stringWithFormat:@"%@, %@",
                      [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT rd.Description "
                                                     "FROM PVOInventoryItems pi, RoomDescription rd "
                                                     "JOIN Rooms r ON r.RoomID = pi.RoomID "
                                                     "WHERE pi.PVOItemID = %d "
                                                     "AND rd.RoomID = r.RoomID", imageDetails.subID]],
                      [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT d.Description "
                                                     "FROM PVOInventoryItems pi, ItemDescription d "
                                                     "JOIN Items i ON pi.ItemID = i.ItemID "
                                                     "WHERE pi.PVOItemID = %d "
                                                     "AND d.ItemID = i.ItemID",
                                                     imageDetails.subID]]];
            
            // OT 21178 - this part was missing
            if ([retval isEqualToString:@"(null), (null)"])
            {
                // try to grab the carton contents
                retval = [NSString stringWithFormat:@"%@",
                          [self getStringValueFromQuery:[NSString stringWithFormat:@"select ContentDescription from PVOCartonContents where CartonContentID = (select ContentCode from PVOInventoryCartonContents where CartonContentID = (select CartonContentID from PVOInventoryItems where PVOItemID = %d))", imageDetails.subID]]];
                if ([retval isEqualToString:@"(null)"])
                {
                    retval = @"";
                }
            }
            
            break;
        case IMG_PVO_ROOMS:
            retval = [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT rd.Description "
                                                    "FROM PVORoomConditions rc, RoomDescription rd "
                                                    "JOIN Rooms r ON r.RoomID = rc.RoomID "
                                                    "WHERE rc.PVORoomConditionID = %d "
                                                    "AND rd.RoomID = r.RoomID", imageDetails.subID]];
            break;
        case IMG_ROOMS:
            retval = [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT rd.Description "
                                                    "FROM Rooms r, RoomDescription rd "
                                                    "WHERE r.RoomID = %d "
                                                    "AND rd.RoomID = r.RoomID", imageDetails.subID]];
            break;
        case IMG_PVO_CLAIM_ITEMS:
            retval = [NSString stringWithFormat:@"Claims - %@", [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT d.Description "
                                                                                               "FROM PVOClaimItems ci, ItemDescription d "
                                                                                               "JOIN PVOInventoryItems pi ON ci.PVOItemID = pi.ItemID "
                                                                                               "JOIN Items i ON pi.ItemID = i.ItemID "
                                                                                               "WHERE ci.PVOClaimItemID = %d "
                                                                                               "AND i.ItemID = d.ItemID", imageDetails.subID]]];
            break;
        case IMG_PVO_WEIGHT_TICKET:
            retval = @"Weight Ticket";
            break;
        case IMG_PVO_VEHICLE_DAMAGES:
            retval = @"Vehicle Damages";
            break;
        case IMG_PVO_DESTINATION_ROOMS:
            retval = [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT r.RoomName "
                                                    "FROM PVODestinationRoomConditions rc "
                                                    "JOIN Rooms r ON r.RoomID = rc.RoomID "
                                                    "WHERE rc.PVODestinationRoomConditionsID = %d", imageDetails.subID]];
            break;
        default:
            break;
    }
    
    if (retval == nil)
        retval = @""; //prevent null values, but should never happen
    
    return retval;
}


-(NSMutableArray*)getImagesList:(int)customerID withPhotoType:(int)type withSubID:(int)subID loadAllItems:(BOOL)loadAll
{
    return [self getImagesList:customerID withPhotoTypes:[NSArray arrayWithObject:[NSNumber numberWithInt:type]] withSubID:subID loadAllItems:loadAll loadAllForType:FALSE];
}

-(NSMutableArray*)getImagesList:(int)customerID withPhotoType:(int)type withSubID:(int)subID loadAllItems:(BOOL)loadAll loadAllForType:(BOOL)allForType
{
    return [self getImagesList:customerID withPhotoTypes:[NSArray arrayWithObject:[NSNumber numberWithInt:type]] withSubID:subID loadAllItems:loadAll loadAllForType:allForType];
}

-(NSMutableArray*)getImagesList:(int)customerID withPhotoTypes:(NSArray*)types withSubID:(int)subID loadAllItems:(BOOL)loadAll loadAllForType:(BOOL)allForType
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSString *cmd;
    sqlite3_stmt *stmnt;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *p = [del.surveyDB getPVOData:del.customerID];

    NSString* itemListClause = [NSString stringWithFormat:@"(SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d)", customerID];
    if (types.count > 0) {
        NSNumber* type = types.firstObject;
        if(p.loadType == SPECIAL_PRODUCTS){
            if (type.integerValue == 5) {
                itemListClause =  @"0"; // Rooms have an ItemListID of 0
            }else {
                itemListClause =  @"4"; // STG Items have an ItemListID of 4
            }
        }
    }else if(p.loadType == SPECIAL_PRODUCTS){
            itemListClause =  @"4"; // STG Items have an ItemListID of 4
    }
   
    // OT 21178 - added the OR clause regarding carton contents, this was missing
    NSString *itemListSelect = [NSString stringWithFormat:@"((PHOTOTYPE = 4 AND SubID IN "
                                "(SELECT PVOItemID FROM PVOInventoryItems ii "
                                "JOIN Items i ON ii.ItemID = i.ItemID WHERE i.ItemListID = %1$@)) "
                                "OR (PHOTOTYPE = 5 AND SubID IN ("
                                    "SELECT PVORoomConditionID FROM PVORoomConditions rc JOIN Rooms r ON rc.RoomID = r.RoomID WHERE r.ItemListID = %1$@ AND PVOLoadID IN (SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %2$d))) "
                                "OR (PHOTOTYPE = 4 AND SubID IN (select PVOItemID from PVOInventoryItems where CartonContentID in (select CartonContentID from PVOInventoryCartonContents where PVOItemID in (select PVOItemID from PVOInventoryItems where PVOLoadID in (select PVOLoadID from PVOInventoryLoads where customerID = %2$d)))))"
                                "OR (PHOTOTYPE <> 4 AND PHOTOTYPE <> 5)) ", itemListClause, customerID];

    if(loadAll)
        cmd = [[NSString alloc] initWithFormat:@"SELECT ImageID,CustomerId,SubID,PhotoType,Path FROM Images "
               " WHERE"
               " %1$@ "
               " AND CustomerID = %2$d ORDER BY PhotoType ASC,SubID ASC",
               itemListSelect,
               customerID];
    else if(allForType)
        cmd = [[NSString alloc] initWithFormat:@"SELECT ImageID,CustomerId,SubID,PhotoType,Path FROM Images "
               " WHERE"
               " %1$@"
               " AND CustomerID = %2$d AND "
               " PhotoType IN(%3$@) ORDER BY SubID ASC",
               itemListSelect,
               customerID,
               [types componentsJoinedByString:@","]];
    else
        cmd = [[NSString alloc] initWithFormat:@"SELECT ImageID,CustomerId,SubID,PhotoType,Path FROM Images "
               " WHERE"
               " %1$@"
               " AND CustomerID = %2$d AND "
               " SubID = %3$d AND "
               " PhotoType IN(%4$@)",
               itemListSelect,
               customerID,
               subID,
               [types componentsJoinedByString:@","]];
    
    SurveyImage *image;
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            image = [[SurveyImage alloc] init];
            image.imageID = sqlite3_column_int(stmnt, 0);
            image.custID = sqlite3_column_int(stmnt, 1);
            image.subID = sqlite3_column_int(stmnt, 2);
            image.photoType = sqlite3_column_int(stmnt, 3);
            image.path = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 4)];
            [array addObject:image];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    return array;
}

-(BOOL*)customerHasImages:(int)customerID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT Count(*) FROM Images WHERE CustomerID = %d", customerID];
    
    return [self getIntValueFromQuery:cmd] > 0;
}

#pragma mark Activation

-(void)updateActivation:(ActivationRecord*)rec
{
    BOOL autoUnlockedColumnExists = [self columnExists:@"AutoUnlocked" inTable:@"ActivationControl"];
    BOOL newVerAvailable = [self columnExists:@"NewVersionAlert" inTable:@"ActivationControl"];
    
    [self updateDB:[NSString stringWithFormat:@"UPDATE ActivationControl SET "
                    "TrialBeginDate = %f,"
                    "LastValidationDate = %f,"
                    "LastOpenDate = %f,"
                    "Unlocked = %d,"
                    "FileCompanyPtr = %d,"
                    "PricingDBVersion = %d,"
                    "MilesDBVersion = %d,"
                    "MilesDLFolder = '%@',"
                    "TariffDLFolder = '%@'"
                    "%@"
                    "%@",
                    [rec.trialBegin timeIntervalSince1970],
                    [rec.lastValidation timeIntervalSince1970],
                    [rec.lastOpen timeIntervalSince1970],
                    rec.unlocked ? 1 : 0,
                    rec.fileCompany,
                    rec.pricingDBVersion,
                    0, //not needed
                    rec.milesDLFolder == nil ? @"" : [rec.milesDLFolder stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                    rec.tariffDLFolder == nil ? @"" : [rec.tariffDLFolder stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                    (autoUnlockedColumnExists ? [NSString stringWithFormat:@",AutoUnlocked = %d", rec.autoUnlocked ? 1 : 0] : @""),
                    (newVerAvailable ? [NSString stringWithFormat:@",NewVersionAlert = %f", [rec.alertNewVersionDate timeIntervalSince1970]] : @"")]];
}

-(ActivationRecord*)getActivation
{
    ActivationRecord *retval = [[ActivationRecord alloc] init];
    
    sqlite3_stmt *stmnt;
    NSString *cmd;
    
    BOOL autoUnlockedColumnExists = [self columnExists:@"AutoUnlocked" inTable:@"ActivationControl"];
    BOOL newVerAvailable = [self columnExists:@"NewVersionAlert" inTable:@"ActivationControl"];
    
    cmd = [NSString stringWithFormat:@"SELECT TrialBeginDate,LastValidationDate,LastOpenDate,Unlocked,FileCompanyPtr"
           ",PricingDBVersion,MilesDBVersion,MilesDLFolder,TariffDLFolder%@%@"
           " FROM ActivationControl",
           autoUnlockedColumnExists ? @",AutoUnlocked" : @"",
           newVerAvailable ? @",NewVersionAlert" : @""];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.trialBegin = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 0)];
            retval.lastValidation = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 1)];
            retval.lastOpen = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 2)];
            retval.unlocked = sqlite3_column_int(stmnt, 3) > 0;
            retval.fileCompany = sqlite3_column_int(stmnt, 4);
            retval.pricingDBVersion = sqlite3_column_int(stmnt, 5);
            retval.milesDBVersion = 0; //sqlite3_column_int(stmnt, 6);
            retval.milesDLFolder = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 7)];
            retval.tariffDLFolder = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 8)];
            if (sqlite3_column_count(stmnt) > 9)
                retval.autoUnlocked = sqlite3_column_int(stmnt, 9) > 0;
            if (sqlite3_column_count(stmnt) > 10)
                retval.alertNewVersionDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 10)];
        }
        else
        {
            retval.unlocked = 0;
            retval.trialBegin = [NSDate date];
            retval.lastValidation = retval.trialBegin;
            retval.lastOpen = retval.trialBegin;
            retval.fileCompany = 0;
            retval.pricingDBVersion = 0;
            retval.milesDBVersion = 0;
            retval.milesDLFolder = @"";
            retval.tariffDLFolder = @"";
            retval.autoUnlocked = 0;
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO ActivationControl VALUES(%f,%f,%f,%d,%d,%d,%d,'','',0%@)",
                            [retval.trialBegin timeIntervalSince1970],
                            [retval.lastValidation timeIntervalSince1970],
                            [retval.lastOpen timeIntervalSince1970],
                            retval.unlocked ? 1 : 0,
                            retval.fileCompany,
                            retval.pricingDBVersion,
                            0, //retval.milesDBVersion,
                            autoUnlockedColumnExists ? [NSString stringWithFormat:@",%d", retval.autoUnlocked ? 1 : 0] : @""]];
        }
        
    }
    
    sqlite3_finalize(stmnt);
    return retval;
    
}

-(BOOL)isAutoInventoryUnlocked
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB hasAutoInventoryItems];
    
    //ActivationRecord *record = [self getActivation];
    //return record.autoUnlocked;
}

#pragma mark - SIRVA activation

- (void)createSirvaActivationTable
{
    [self updateDB:@"CREATE TABLE IF NOT EXISTS SirvaActivationControl (Success INT, UserName TEXT, ErrorMessage TEXT, AppMode TEXT, "
     "InterstateAccess INT, MMAccess INT, QPDAccess INT, UserType TEXT)"];
}

#pragma mark email defaults

-(ReportDefaults*)getReportDefaults
{
    ReportDefaults *retval = [[ReportDefaults alloc] init];
    
    NSString *cmd = @"SELECT AgentEmail,AgentName,Subject,Body,SendFromDevice FROM ReportDefaults";
    
    retval.newRec = TRUE;
    retval.body = @"Attached is the documentation for your Inventory.";
    retval.subject = @"Inventory Documentation";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.newRec = FALSE;
            retval.agentEmail = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)];
            retval.agentName = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)];
            retval.subject = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
            retval.body = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 3)];
            retval.sendFromDevice = sqlite3_column_int(stmnt, 4) > 0;
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)saveReportDefaults:(ReportDefaults*)defaults
{
    if(defaults.newRec)
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO ReportDefaults(AgentEmail,AgentName,Subject,Body,SendFromDevice)"
                        " VALUES('%@','%@','%@','%@',%d)",
                        defaults.agentEmail == nil ? @"" : [defaults.agentEmail stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.agentName == nil ? @"" : [defaults.agentName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.subject == nil ? @"" : [defaults.subject stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.body == nil ? @"" : [defaults.body stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.sendFromDevice ? 1 : 0]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE ReportDefaults SET "
                        "AgentEmail = '%@',"
                        "AgentName = '%@',"
                        "Subject = '%@',"
                        "Body = '%@',"
                        "SendFromDevice = %d",
                        defaults.agentEmail == nil ? @"" : [defaults.agentEmail stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.agentName == nil ? @"" : [defaults.agentName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.subject == nil ? @"" : [defaults.subject stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.body == nil ? @"" : [defaults.body stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        defaults.sendFromDevice ? 1 : 0]];
    }
    
}

#pragma mark printer info

-(void)addPrinter:(StoredPrinter*)printer
{
    //check to see if it has to be default... (if there are no others)
    BOOL defaultFound = FALSE;
    NSArray *printers = [self getAllPrinters];
    for (int i = 0; i < [printers count]; i++) {
        if([[printers objectAtIndex:i] isDefault])
        {
            defaultFound = TRUE;
            break;
        }
    }
    
    //clear existing default if it exists
    if(printer.isDefault)
    {
        [self updateDB:@"UPDATE Printers SET IsDefault = 0"];
    }
    
    
    //save the printer
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Printers"
                     "(IsDefault,Address,Name,PrinterKind,IsBonjour,Quality,Color) "
                     "VALUES(%d,'%@','%@',%d,%d,0,%d)",
                     printer.isDefault || !defaultFound ? 1 : 0,
                     printer.address == nil ? @"" : [printer.address stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     printer.name == nil ? @"" : [printer.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                     printer.printerKind, printer.isBonjour ? 1 : 0, printer.color ? 1 : 0];
    
    [self updateDB:cmd];
    
    int printerID = sqlite3_last_insert_rowid(db);
    
    //if it is bonjour, save that data
    if(printer.isBonjour)
    {
        NSArray *allKeys = [printer.bonjourSettings allKeys];
        for(int i = 0; i < [allKeys count]; i++)
        {
            cmd = [NSString stringWithFormat:@"INSERT INTO BonjourSettings(PrinterID,KeyName,KeyValue)"
                   " VALUES(%d,'%@','%@')",
                   printerID, [allKeys objectAtIndex:i],
                   [printer.bonjourSettings objectForKey:[allKeys objectAtIndex:i]]];
            [self updateDB:cmd];
        }
    }
    
}

-(void)setDefaultPrinter:(int)printerID
{
    //clear any previous.
    [self updateDB:@"UPDATE Printers SET IsDefault = 0"];
    [self updateDB:[NSString stringWithFormat:@"UPDATE Printers SET IsDefault = 1 WHERE PrinterID = %d",
                    printerID]];
}

-(NSArray*)getAllPrinters
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    NSString *cmd = @"SELECT "
    "PrinterID,IsDefault,Address,Name,PrinterKind,IsBonjour,Quality,Color "
    "FROM Printers ";
    
    StoredPrinter *printer;
    
    sqlite3_stmt *stmnt, *newStmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            printer = [[StoredPrinter alloc] init];
            printer.printerID = sqlite3_column_int(stmnt, 0);
            printer.isDefault = sqlite3_column_int(stmnt, 1) > 0;
            printer.address = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
            printer.name = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 3)];
            printer.printerKind = sqlite3_column_int(stmnt, 4);
            printer.isBonjour = sqlite3_column_int(stmnt, 5) > 0;
            printer.quality = sqlite3_column_int(stmnt, 6);
            printer.color = sqlite3_column_int(stmnt, 7) > 0;
            
            if(printer.isBonjour)
            {
                cmd = [NSString stringWithFormat:@"SELECT KeyName,KeyValue FROM BonjourSettings"
                       " WHERE PrinterID = %d", printer.printerID];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                if([self prepareStatement:cmd withStatement:&newStmnt])
                {
                    while(sqlite3_step(newStmnt) == SQLITE_ROW)
                    {
                        NSString *key = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(newStmnt, 0)];
                        NSString *val = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(newStmnt, 1)];
                        [dict setObject: val
                                 forKey:key];
                    }
                }
                sqlite3_finalize(newStmnt);
                printer.bonjourSettings = dict;
            }
            
            [retval addObject:printer];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)removePrinter:(int)printerID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM Printers WHERE PrinterID = %d", printerID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM BonjourSettings WHERE PrinterID = %d", printerID]];
}

-(StoredPrinter*)getDefaultPrinter
{
    NSArray *printers = [self getAllPrinters];
    StoredPrinter *myPrinter = nil;
    for(int i = 0; i < [printers count]; i++)
    {
        if([[printers objectAtIndex:i] isDefault])
        {
            myPrinter = [printers objectAtIndex:i];
            break;
        }
    }
    
    return myPrinter == nil ? myPrinter : myPrinter;
}

-(void)setPrintQuality:(int)quality
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Printers SET Quality = %d", quality]];
}

-(void)setPrintColor:(BOOL)color
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Printers SET Color = %d", color ? 1 : 0]];
}


#pragma mark PVO

-(void)saveCRMSettings:(NSString*)username password:(NSString*)password syncEnvironment:(int)selectedEnvironment
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVODriverData SET CRMUsername = %@, CRMPassword = %@, CRMEnvironment = %d",
                    [self prepareStringForInsert:username],
                    [self prepareStringForInsert:password],
                    selectedEnvironment]];
}

-(NSString*)getDriverNumber
{
    NSString *cmd = @"SELECT DriverNumber FROM PVODriverData";
    NSString *retval = [self getStringValueFromQuery:cmd];
    return retval;
}

-(NSString*)getHaulingAgentCode
{
    NSString *cmd = @"SELECT HaulingAgent FROM PVODriverData";
    NSString *retval = [self getStringValueFromQuery:cmd];
    return retval;
}

-(DriverData*)getDriverData
{
    DriverData *retval = [[DriverData alloc] init];
    retval.driverType = PVO_DRIVER_TYPE_DRIVER;
    
    BOOL crmSettingsExist = [self columnExists:@"CRMUsername" inTable:@"PVODriverData"]; //can assume the other two also exist
    NSString *cmd = [NSString stringWithFormat:@"SELECT VanlineID,HaulingAgent,SafetyNumber,DriverName,DriverNumber,HaulingAgentEmail"
                     ",DriverEmail,UnitNumber,DamageViewPreference,EnableRoomConditions,DriverPassword"
                     ",DamagesReportViewPreference,DriverSyncPreference,TractorNumber,QuickInventory,ShowTractorTrailerOptions"
                     ",SaveToCameraRoll,DriverType,HaulingAgentEmailCC,HaulingAgentEmailBCC,DriverEmailCC,DriverEmailBCC,UseScanner,PackerEmail,PackerEmailCC,PackerEmailBCC,PackerName%@ "
                     "FROM PVODriverData",
                     (crmSettingsExist ? @",CRMUsername,CRMPassword,CRMEnvironment " : @"")];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int i = 0;
            retval.vanlineID = sqlite3_column_int(stmnt, i) > 0;
            retval.haulingAgent = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.safetyNumber = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.driverName = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.driverNumber = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.haulingAgentEmail = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.driverEmail = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.unitNumber = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.buttonPreference = sqlite3_column_int(stmnt, ++i);
            retval.enableRoomConditions = sqlite3_column_int(stmnt, ++i) > 0;
            retval.driverPassword = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.reportPreference = sqlite3_column_int(stmnt, ++i);
            retval.syncPreference = sqlite3_column_int(stmnt, ++i);
            retval.tractorNumber = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.quickInventory = sqlite3_column_int(stmnt, ++i) > 0;
            retval.showTractorTrailerOptions = sqlite3_column_int(stmnt, ++i) > 0;
            retval.saveToCameraRoll = sqlite3_column_int(stmnt, ++i) > 0;
            retval.driverType = sqlite3_column_int(stmnt, ++i);
            retval.haulingAgentEmailCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.haulingAgentEmailBCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.driverEmailCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.driverEmailBCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.useScanner = (sqlite3_column_int(stmnt, ++i) > 0);
            
            // Packer info
            retval.packerEmail = [SurveyDB stringFromStatement:stmnt columnID:++i];
            retval.packerEmailCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.packerEmailBCC = (sqlite3_column_int(stmnt, ++i) > 0);
            retval.packerName = [SurveyDB stringFromStatement:stmnt columnID:++i];
            
            if (crmSettingsExist)
            {
                retval.crmUsername = [SurveyDB stringFromStatement:stmnt columnID:++i];
                retval.crmPassword = [SurveyDB stringFromStatement:stmnt columnID:++i];
                retval.crmEnvironment = (sqlite3_column_int(stmnt, ++i));
            }
            
            if ([AppFunctionality disablePackersInventory])
                retval.driverType = PVO_DRIVER_TYPE_DRIVER;
        }
    }
    sqlite3_finalize(stmnt);
    
    if (retval.driverType == PVO_DRIVER_TYPE_PACKER)
    {
        // If switching to packer, remove driver info
        //remove extraneous data not needed (defect 545)
        //        retval.haulingAgent = nil;
        retval.safetyNumber = nil;
        retval.driverName = nil;
        //        retval.driverNumber = nil;
        retval.haulingAgentEmail = nil;
        retval.driverEmail = nil;
        retval.unitNumber = nil;
        //        retval.driverPassword = nil;
        retval.tractorNumber = nil;
        retval.haulingAgentEmailCC = NO;
        retval.haulingAgentEmailBCC = NO;
        retval.driverEmailCC = NO;
        retval.driverEmailBCC = NO;
        
        //also remove driver # and password per jeff 1/10/18 feature 2158
        retval.driverNumber = nil;
        retval.driverPassword = nil;
        
        // Remove driver signature
        [self deletePVOSignature:-1 forImageType:PVO_SIGNATURE_TYPE_DRIVER];
    } else if(retval.driverType == PVO_DRIVER_TYPE_DRIVER) {
        // If switching to driver, remove packer info
        retval.packerName = nil;
        retval.packerEmail = nil;
        retval.packerEmailCC = NO;
        retval.packerEmailBCC = NO;
        
        // Remove packer signature
        [self deletePVOSignature:-1 forImageType:PVO_SIGNATURE_TYPE_PACKER];
    }
    
    return retval;
}

-(void)updateDriverData:(DriverData*)data
{
    if([self getIntValueFromQuery:@"SELECT COUNT(*) FROM PVODriverData"] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVODriverData SET VanlineID = %d,HaulingAgent = %@,"
                        "SafetyNumber = %@,DriverName = %@,DriverNumber = %@,HaulingAgentEmail = %@,"
                        "DriverEmail = %@,UnitNumber = %@,DamageViewPreference = %d,EnableRoomConditions = %d,"
                        "DriverPassword = %@, DamagesReportViewPreference = %d, DriverSyncPreference = %d, TractorNumber = %@,"
                        "QuickInventory = %d, ShowTractorTrailerOptions = %d, SaveToCameraRoll = %d, DriverType = %d, "
                        "HaulingAgentEmailCC = %d, HaulingAgentEmailBCC = %d, DriverEmailCC = %d,DriverEmailBCC = %d, UseScanner = %d, PackerEmail = %@, PackerEmailCC = %d, PackerEmailBCC = %d, PackerName = %@",
                        data.vanlineID,
                        [self prepareStringForInsert:data.haulingAgent],
                        [self prepareStringForInsert:data.safetyNumber],
                        [self prepareStringForInsert:data.driverName],
                        [self prepareStringForInsert:data.driverNumber],
                        [self prepareStringForInsert:data.haulingAgentEmail],
                        [self prepareStringForInsert:data.driverEmail],
                        [self prepareStringForInsert:data.unitNumber],
                        data.buttonPreference, data.enableRoomConditions ? 1 : 0,
                        [self prepareStringForInsert:data.driverPassword],
                        data.reportPreference,
                        data.syncPreference,
                        [self prepareStringForInsert:data.tractorNumber],
                        data.quickInventory ? 1 : 0,
                        data.showTractorTrailerOptions ? 1 : 0,
                        data.saveToCameraRoll ? 1 : 0,
                        data.driverType,
                        data.haulingAgentEmailCC ? 1 : 0,
                        data.haulingAgentEmailBCC ? 1 : 0,
                        data.driverEmailCC ? 1 : 0,
                        data.driverEmailBCC ? 1 : 0,
                        data.useScanner ? 1 : 0,
                        [self prepareStringForInsert:data.packerEmail],
                        data.packerEmailCC ? 1 : 0,
                        data.packerEmailBCC ? 1 : 0,
                        [self prepareStringForInsert:data.packerName]]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVODriverData(VanlineID,HaulingAgent,SafetyNumber,DriverName,DriverNumber,HaulingAgentEmail,DriverEmail,UnitNumber,DamageViewPreference,EnableRoomConditions,DriverPassword,DamagesReportViewPreference,DriverSyncPreference,TractorNumber,QuickInventory,ShowTractorTrailerOptions,SaveToCameraRoll,DriverType,HaulingAgentEmailCC,HaulingAgentEmailBCC,DriverEmailCC,DriverEmailBCC,UseScanner,PackerEmail,PackerEmailCC,PackerEmailBCC,PackerName,CRMEnvironment) "
                        "VALUES(%d,%@,%@,%@,%@,%@,%@,%@,%d,%d,%@,%d,%d,%@,%d,%d,%d,%d,%d,%d,%d,%d,%d,%@,%d,%d,%@,%d)",
                        data.vanlineID,
                        [self prepareStringForInsert:data.haulingAgent],
                        [self prepareStringForInsert:data.safetyNumber],
                        [self prepareStringForInsert:data.driverName],
                        [self prepareStringForInsert:data.driverNumber],
                        [self prepareStringForInsert:data.haulingAgentEmail],
                        [self prepareStringForInsert:data.driverEmail],
                        [self prepareStringForInsert:data.unitNumber],
                        data.buttonPreference, data.enableRoomConditions ? 1 : 0,
                        [self prepareStringForInsert:data.driverPassword],
                        data.reportPreference,
                        data.syncPreference,
                        [self prepareStringForInsert:data.tractorNumber],
                        data.quickInventory ? 1 : 0,
                        data.showTractorTrailerOptions ? 1 : 0,
                        data.saveToCameraRoll ? 1 : 0,
                        data.driverType,
                        data.haulingAgentEmailCC ? 1 : 0,
                        data.haulingAgentEmailBCC ? 1 : 0,
                        data.driverEmailCC ? 1 : 0,
                        data.driverEmailBCC ? 1 : 0,
                        data.useScanner ? 1 : 0,
                        data.packerEmail,
                        data.packerEmailCC ? 1 : 0,
                        data.packerEmailBCC ? 1 : 0,
                        data.packerName,
                        PVO_DRIVER_CRM_ENVIRONMENT_PROD]];
    }
}

-(NSArray*)getDriverDataCCEmails
{
    DriverData *driver = nil;
    @try {
        NSMutableArray *ccEmails = [NSMutableArray array];
        driver = [self getDriverData];
        if (driver != nil && driver.haulingAgentEmailCC && driver.haulingAgentEmail != nil && ![driver.haulingAgentEmail isEqualToString:@""])
            [ccEmails addObject:driver.haulingAgentEmail];
        if (driver != nil && driver.driverEmailCC && driver.driverEmail != nil && ![driver.driverEmail isEqualToString:@""])
            [ccEmails addObject:driver.driverEmail];
        if ([ccEmails count] == 0)
            return nil;
        else
            return ccEmails;
    }
    @finally {

    }
}

-(NSArray*)getDriverDataBCCEmails
{
    DriverData *driver = nil;
    @try {
        NSMutableArray *ccEmails = [NSMutableArray array];
        driver = [self getDriverData];
        if (driver != nil && driver.haulingAgentEmailBCC && driver.haulingAgentEmail != nil && ![driver.haulingAgentEmail isEqualToString:@""])
            [ccEmails addObject:driver.haulingAgentEmail];
        if (driver != nil && driver.driverEmailBCC && driver.driverEmail != nil && ![driver.driverEmail isEqualToString:@""])
            [ccEmails addObject:driver.driverEmail];
        if ([ccEmails count] == 0)
            return nil;
        else
            return ccEmails;
    }
    @finally {

    }
}

-(NSArray*)getDriverDataPackerCCEmails
{
    DriverData *driver = nil;
    @try {
        NSMutableArray *ccEmails = [NSMutableArray array];
        driver = [self getDriverData];
        if (driver != nil && driver.packerEmailCC && driver.packerEmail != nil && ![driver.packerEmail isEqualToString:@""])
            [ccEmails addObject:driver.packerEmail];
        if ([ccEmails count] == 0)
            return nil;
        else
            return ccEmails;
    }
    @finally {

    }
}

-(NSArray*)getDriverDataPackerBCCEmails
{
    DriverData *driver = nil;
    @try {
        NSMutableArray *ccEmails = [NSMutableArray array];
        driver = [self getDriverData];
        if (driver != nil && driver.packerEmailBCC && driver.packerEmail != nil && ![driver.packerEmail isEqualToString:@""])
            [ccEmails addObject:driver.packerEmail];
        if ([ccEmails count] == 0)
            return nil;
        else
            return ccEmails;
    }
    @finally {

    }
}

-(PVOInventory*)getPVOData:(int)custID
{
    
    PVOInventory *retval = [[PVOInventory alloc] init];
    retval.custID = custID;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT CustomerID, CurrentLotNumber, CurrentTagColor, UsingScanner, NextItemNumber,"
                               " LoadType, NoConditions, InventoryCompleted, DeliveryCompleted, TractorNumber, TrailerNumber, NewPagePerLot,"
                               " WeightFactor, ConfirmLotNumber, PackingOT, PackingType, LockLoadType, MPROWeight, SPROWeight, CONSWeight, ValuationType "
                               "FROM PVOInventoryData WHERE CustomerID = %d", custID] withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.custID = sqlite3_column_int(stmnt, 0);
            retval.currentLotNum = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)];
            retval.currentColor = sqlite3_column_int(stmnt, 2);
            retval.usingScanner = sqlite3_column_int(stmnt, 3) > 0;
            retval.nextItemNum = sqlite3_column_int(stmnt, 4);
            retval.loadType = sqlite3_column_int(stmnt, 5);
            retval.noConditionsInventory = sqlite3_column_int(stmnt, 6) > 0;
            retval.inventoryCompleted = sqlite3_column_int(stmnt, 7) > 0;
            retval.deliveryCompleted = sqlite3_column_int(stmnt, 8) > 0;
            retval.tractorNumber = [SurveyDB stringFromStatement:stmnt columnID:9];
            retval.trailerNumber = [SurveyDB stringFromStatement:stmnt columnID:10];
            retval.newPagePerLot = sqlite3_column_int(stmnt, 11) > 0;
            retval.weightFactor = sqlite3_column_double(stmnt, 12);
            retval.confirmLotNum = [SurveyDB stringFromStatement:stmnt columnID:13];
            retval.packingOT = sqlite3_column_int(stmnt, 14) > 0;
            retval.packingType = sqlite3_column_int(stmnt, 15);
            retval.lockLoadType = sqlite3_column_int(stmnt, 16) > 0;
            retval.mproWeight = sqlite3_column_int(stmnt, 17);
            retval.sproWeight = sqlite3_column_int(stmnt, 18);
            retval.consWeight = sqlite3_column_int(stmnt, 19);
            retval.valuationType = sqlite3_column_int(stmnt, 20);
        }
        else
        {
            //default to driver values...
            DriverData *driver = [self getDriverData];
            if ([AppFunctionality showTractorTrailerAlways] || ![AppFunctionality showTractorTrailerOptional] || driver.showTractorTrailerOptions)
            {
                retval.tractorNumber = driver.tractorNumber;
                retval.trailerNumber = driver.unitNumber;
            }
            retval.usingScanner = driver.useScanner;
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)updatePVOData:(PVOInventory*)data
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryData WHERE CustomerID = %d",data.custID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryData SET CustomerID = %d,CurrentLotNumber = '%@',CurrentTagColor = %d,"
                        "UsingScanner = %d,NextItemNumber = %d,LoadType = %d,NoConditions = %d,InventoryCompleted = %d,DeliveryCompleted = %d,"
                        "TractorNumber = %@,TrailerNumber = %@, NewPagePerLot = %d,WeightFactor = %f,ConfirmLotNumber = %@,"
                        "PackingOT = %d,PackingType = %d, LockLoadType = %d, MPROWeight = %d, SPROWeight = %d, CONSWeight = %d, ValuationType = %d WHERE CustomerID = %d",
                        data.custID,
                        data.currentLotNum == nil ? @"" : [data.currentLotNum stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        data.currentColor, data.usingScanner ? 1 : 0, data.nextItemNum, data.loadType,
                        data.noConditionsInventory ? 1 : 0,
                        data.inventoryCompleted ? 1 : 0,
                        data.deliveryCompleted ? 1 : 0,
                        [self prepareStringForInsert:data.tractorNumber],
                        [self prepareStringForInsert:data.trailerNumber],
                        data.newPagePerLot ? 1 : 0,
                        data.weightFactor,
                        [self prepareStringForInsert:data.confirmLotNum],
                        data.packingOT ? 1 : 0, data.packingType,
                        data.lockLoadType ? 1 : 0,
                        data.mproWeight,
                        data.sproWeight,
                        data.consWeight,
                        data.valuationType,
                        data.custID]] ;
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryData(CustomerID,CurrentLotNumber,CurrentTagColor,"
                        "UsingScanner,NextItemNumber,LoadType,NoConditions,InventoryCompleted,DeliveryCompleted,TractorNumber,TrailerNumber,NewPagePerLot"
                        ",WeightFactor,ConfirmLotNumber,PackingOT,PackingType,LockLoadType,MPROWeight,SPROWeight,CONSWeight,ValuationType) "
                        "VALUES(%d,'%@',%d,%d,%d,%d,%d,%d,%d,%@,%@,%d,%f,%@,%d,%d,%d,%d,%d,%d,%d)",
                        data.custID,
                        data.currentLotNum == nil ? @"" : [data.currentLotNum stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        data.currentColor, data.usingScanner ? 1 : 0, data.nextItemNum, data.loadType,
                        data.noConditionsInventory ? 1 : 0,
                        data.inventoryCompleted ? 1 : 0,
                        data.deliveryCompleted ? 1 : 0,
                        [self prepareStringForInsert:data.tractorNumber],
                        [self prepareStringForInsert:data.trailerNumber],
                        data.newPagePerLot ? 1 : 0,
                        data.weightFactor,
                        [self prepareStringForInsert:data.confirmLotNum],
                        data.packingOT ? 1 : 0, data.packingType,
                        data.lockLoadType ? 1 : 0,
                        data.mproWeight,
                        data.sproWeight,
                        data.consWeight,
                        data.valuationType]];
    }
}

-(NSMutableDictionary*)getPVOLoadTypes
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT LoadTypeID, LoadDescription FROM PVOLoadTypes" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //pobject, desc, key, id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSMutableDictionary*)getPVOLoadTypesForAtlas:(NSArray*)descriptionsToHide
{
    sqlite3_stmt *stmnt;
	NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT LoadTypeID, LoadDescription FROM PVOLoadTypes WHERE 0 = 0"];
    if ([descriptionsToHide count] > 0) {
        for (int i = 0; i < [descriptionsToHide count]; i++) {
            [sql appendString:@" AND LoadDescription NOT LIKE '%"];
            [sql appendString:[descriptionsToHide objectAtIndex: i]];
            [sql appendString:@"%'"];
        }
    }
    
    if([self prepareStatement:sql withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //pobject, desc, key, id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVOValuationTypes:(int)vanlineID
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT ValuationTypeID, ValuationDescription FROM PVOValuationTypes WHERE VanlineID IN (%d)", vanlineID]; //0 = NONE and is not assigned to a vanline ID, not an option for users
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //pobject, desc, key, id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVOLocations:(BOOL)includeHidden isLoading:(BOOL)isLoad
{
    return [self getPVOLocations:includeHidden isLoading:isLoad isDriverInv:FALSE];
}

-(NSDictionary*)getPVOLocations:(BOOL)includeHidden isLoading:(BOOL)isLoad isDriverInv:(BOOL)isDriver
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    bool isAtlas = [del.pricingDB vanline] == ATLAS;

    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT LocationID, LocationDescription FROM PVOLocations %@%@",
                       (includeHidden ? @"" : isAtlas ? @"WHERE Hidden = 0 OR LocationDescription LIKE '%Commercial%'" : @"WHERE Hidden = 0"), (/*[AppFunctionality disablePackersInventory] ? [NSString stringWithFormat:@" %@ LocationID != 7", (includeHidden ? @"WHERE" : @"AND")] :*/ @"")];
    sqlite3_stmt *stmnt;
    if([self prepareStatement:query withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if ((!isLoad || isDriver) && sqlite3_column_int(stmnt, 0) == PACKER_INVENTORY) //only show packer's inventory if Load //Dont show packer's inventory for drivers
                continue;
            //object = desc, key = id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)pvoLocationRequiresLocationSelection:(int)locationID
{
    BOOL temp = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT RequiresLocationSelection "
                                       "FROM PVOLocations WHERE LocationID = %d", locationID]] > 0;
    return temp;
}

-(NSDictionary*)getPVOColors
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT ColorID, ColorDescription FROM PVOColors" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //pobject, desc, key, id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVODimensionUnitTypes
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT TypeID, TypeDescription FROM PVODimensionUnitTypes" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //pobject, desc, key, id
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVODamageLocationsWithCustomerID:(int)custID
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSString *itemListClause = @"";
    
    if (custID > 0)
        itemListClause = [NSString stringWithFormat:@" LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
    else
        itemListClause = @" LanguageCode = 0 AND ItemListID = 0 ";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT LocationCode, LocationDescription FROM PVOItemLocations WHERE %@", itemListClause] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVODamageWithCustomerID:(int)custID
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    NSString *itemListClause = @"";
    
    if (custID > 0)
        itemListClause = [NSString stringWithFormat:@" LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
    else
        itemListClause = @" LanguageCode = 0 AND ItemListID = 0 ";
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DamageCode, DamageDescription FROM PVOItemDamage WHERE %@", itemListClause]  withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)locationAvailableForPVOLoad:(int)locID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryLoads WHERE LocationID = %d", locID]] == 0;
}

-(int)updatePVOLoad:(PVOInventoryLoad*)data
{
    int retva = data.pvoLoadID;
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryLoads WHERE PVOLoadID = %d", data.pvoLoadID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryLoads SET CustomerID = %d,"
                        "PVOLocationID = %d,LocationID = %d, ReceivedFromPVOLocationID = %d"
                        " WHERE PVOLoadID = %d",
                        data.custID, data.pvoLocationID, data.locationID, data.receivedFromPVOLocationID, data.pvoLoadID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryLoads(CustomerID,"
                        "PVOLocationID,LocationID,ReceivedFromPVOLocationID) VALUES(%d,%d,%d,%d)",
                        data.custID, data.pvoLocationID, data.locationID, data.receivedFromPVOLocationID]];
        retva = sqlite3_last_insert_rowid(db);
        
        [self getReceivableReportNotesForCustomer:data.custID];
    }
    
    return retva;
}

-(NSArray*)getPVOLocationsForCust:(int)custID
{
    return [self getPVOLocationsForCust:custID withDriverType:-1];
}

-(NSArray*)getPVOLocationsForCust:(int)custID withDriverType:(int)driverType
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    PVOInventoryLoad *current;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT PVOLoadID,CustomerID,"
                     "PVOLocationID,LocationID,ReceivedFromPVOLocationID FROM PVOInventoryLoads WHERE CustomerID = %d", custID];
    
    //not sure why we'd hide this for drivers
    //    if (driverType >= 0 && driverType != PVO_DRIVER_TYPE_PACKER)
    //        cmd = [cmd stringByAppendingFormat:@" AND PVOLocationID != %d", PACKER_INVENTORY];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            //check to make sure there are items...  this was causing locationsto not be selectable twice...
            //            if([self getPVOItemCountForLocation:sqlite3_column_int(stmnt, 0)] > 0)
            //            {
            current = [[PVOInventoryLoad alloc] init];
            
            current.pvoLoadID = sqlite3_column_int(stmnt, 0);
            current.custID = sqlite3_column_int(stmnt, 1);
            current.pvoLocationID = sqlite3_column_int(stmnt, 2);
            current.locationID = sqlite3_column_int(stmnt, 3);
            current.receivedFromPVOLocationID = sqlite3_column_int(stmnt, 4);
            
            /*need a weight factor...*/
            current.weight = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT SUM("
                                                         "CASE WHEN Weight > 0 THEN Weight * Quantity "
                                                         "WHEN Weight =0 THEN Cube * (SELECT WeightFactor FROM PVOInventoryData "
                                                         "WHERE CustomerID = %d) * Quantity "
                                                         "END) "
                                                         "FROM PVOInventoryItems WHERE PVOLoadID = %d"
                                                         " AND ItemIsDeleted = 0", custID, current.pvoLoadID]];
            
            current.cube = [self getDoubleValueFromQuery:[NSString stringWithFormat:@"SELECT SUM(Cube * Quantity) FROM PVOInventoryItems WHERE PVOLoadID = %d"
                                                          " AND ItemIsDeleted = 0", current.pvoLoadID]];
            
            [retval addObject:current];
            
            
            //            }
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOInventoryLoad*)getPVOLoad:(int)pvoLoadID
{
    PVOInventoryLoad *retval = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOLoadID,CustomerID,"
                               "PVOLocationID,LocationID,ReceivedFromPVOLocationID FROM PVOInventoryLoads WHERE PVOLoadID = %d", pvoLoadID]
                withStatement:&stmnt])
    {
        if (sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[PVOInventoryLoad alloc] init];
            retval.pvoLoadID = sqlite3_column_int(stmnt, 0);
            retval.custID = sqlite3_column_int(stmnt, 1);
            retval.pvoLocationID = sqlite3_column_int(stmnt, 2);
            retval.locationID = sqlite3_column_int(stmnt, 3);
            retval.receivedFromPVOLocationID = sqlite3_column_int(stmnt, 4);
        }
    }
    sqlite3_finalize(stmnt);
    return retval;
}

-(PVOInventoryLoad*)getFirstPVOLoad:(int)custID forPVOLocationID:(int)pvoLocationID
{
    int pvoLoadID = -1;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOLoadID FROM PVOInventoryLoads "
                               "WHERE CustomerID = %d AND PVOLocationID = %d ORDER BY PVOLoadID LIMIT 1", custID, pvoLocationID]
                withStatement:&stmnt])
    {
        if (sqlite3_step(stmnt) == SQLITE_ROW)
            pvoLoadID = sqlite3_column_int(stmnt, 0);
    }
    sqlite3_finalize(stmnt);
    
    if (pvoLoadID > 0)
        return [self getPVOLoad:pvoLoadID];
    return nil;
}

-(int)getPVOLoadCount:(int)custID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryLoads WHERE CustomerID = %d", custID]];
}

-(int)getPVOItemCountForLocation:(int)pvoLoadID includeDeleted:(BOOL)includeDeleted ignoreItemList:(BOOL)ignoreItemList
{
    NSString *itemListClause;
    if (ignoreItemList)
    {
        itemListClause = @" 1 = 1 ";
    }
    else
    {
        if (pvoLoadID > 0)
        {
            itemListClause = [NSString stringWithFormat:@" i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = (SELECT CustomerID FROM PVOInventoryLoads WHERE PVOLoadID = %1$d)) ", pvoLoadID];
        }
        else
        {
            itemListClause = @" i.ItemListID = 0 ";
        }
    }
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems ii INNER JOIN Items i ON ii.ItemID = i.ItemID "
                     "WHERE ii.PVOLoadID = %d %@ AND %@",
                     pvoLoadID,
                     includeDeleted ? @"" : @" AND ItemIsDeleted = 0",
                     itemListClause];
    
    return [self getIntValueFromQuery:cmd];
}

-(int)getPVOItemMissingCountForLocation:(int)pvoLoadID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOLoadID = %d "
                     "AND ItemIsDelivered = 0 AND (ItemIsMPRO = 0 AND ItemIsSPRO = 0 AND ItemIsCONS = 0 AND HighValueCost <= 0)",
                     pvoLoadID];
    return [self getIntValueFromQuery:cmd];
}

-(int)getPVOItemAfterInventorySignCountForLocation:(int)pvoLoadID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOLoadID = %d "
                     "AND InventoriedAfterSignature = 1 AND (ItemIsMPRO = 0 AND ItemIsSPRO = 0 AND ItemIsCONS = 0 AND HighValueCost <= 0)", //exclude high value from after sign
                     pvoLoadID];
    return [self getIntValueFromQuery:cmd];
}

-(void)switchPVOItemLocations:(int)pvoLoadID toLocation:(int)to
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryLoads "
                    "SET LocationID = %d WHERE PVOLoadID = %d",
                    to, pvoLoadID]];
}

-(NSArray*)getPVORooms:(int)pvoLoadID withCustomerID:(int)custID
{
    return [self getPVORooms:pvoLoadID withDeletedItems:NO withCustomerID:custID];
}

-(NSArray*)getPVORooms:(int)pvoLoadID withDeletedItems:(BOOL)includeDeleted withCustomerID:(int)custID
{
    return [self getPVORooms:pvoLoadID withDeletedItems:includeDeleted andConditionOnly:NO withCustomerID:custID];
}

-(NSArray*)getPVORooms:(int)pvoLoadID withDeletedItems:(BOOL)includeDeleted andConditionOnly:(BOOL)includeConditionsOnly withCustomerID:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    BOOL isSpecialProducts = inventory.loadType == SPECIAL_PRODUCTS;// need to remove the logic around this if/when adding special products specific rooms
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVORoomSummary *current = nil;
    sqlite3_stmt *stmnt;
    NSString *specialProd = isSpecialProducts ? @"0" : [NSString stringWithFormat:@"(SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %d)", custID];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT(i.RoomID) FROM PVOInventoryItems i, RoomDescription d "
                       "LEFT OUTER JOIN Rooms r ON r.RoomID = i.RoomID "
                       "LEFT OUTER JOIN RoomDescription rd on r.RoomID = rd.RoomID "
                       "WHERE i.PVOLoadID = %1$d %2$@ "
                       "AND rd.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %3$d) AND r.ItemListID = %4$@ "
                       "ORDER BY d.Description COLLATE NOCASE",
                       pvoLoadID,
                       (includeDeleted ? @"" : @"AND ItemIsDeleted = 0"),
                       custID,
                       specialProd
                       ]; // using this until we add special product specific rooms.
    if([self prepareStatement:query withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVORoomSummary alloc] init];
            current.room = [self getRoom:sqlite3_column_int(stmnt, 0) WithCustomerID:custID];
            current.numberOfItems = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOLoadID = %d"
                                                                " AND RoomID = %d AND ItemIsDeleted = 0", pvoLoadID, current.room.roomID]];
            
            /*need a weight factor...*/
            current.weight = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT SUM("
                                                         "CASE WHEN Weight > 0 THEN Weight * Quantity "
                                                         "WHEN Weight =0 THEN Cube * (SELECT pid.WeightFactor FROM PVOInventoryData pid "
                                                         "JOIN PVOInventoryLoads l ON l.CustomerID = pid.CustomerID WHERE l.PVOLoadID = %d) * Quantity END) "
                                                         "FROM PVOInventoryItems WHERE PVOLoadID = %d"
                                                         " AND RoomID = %d AND ItemIsDeleted = 0", pvoLoadID, pvoLoadID, current.room.roomID]];
            
            current.cube = [self getDoubleValueFromQuery:[NSString stringWithFormat:@"SELECT SUM(Cube * Quantity) FROM PVOInventoryItems WHERE PVOLoadID = %d"
                                                          " AND RoomID = %d AND ItemIsDeleted = 0", pvoLoadID, current.room.roomID]];
            
            if (![current.room.roomName isEqualToString:@""] && current.room.roomName != nil)
                [retval addObject:current];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    if (includeConditionsOnly)
    {
        if ([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(rc.RoomID) FROM PVORoomConditions rc"
                                    " WHERE rc.PVOLoadID = %d AND rc.RoomID NOT IN "
                                    " (SELECT DISTINCT(i.RoomID) FROM PVOInventoryItems i WHERE i.PVOLoadID = rc.PVOLoadID)", pvoLoadID]
                     withStatement:&stmnt])
        {
            while (sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[PVORoomSummary alloc] init];
                current.room = [self getRoom:sqlite3_column_int(stmnt, 0)];
                current.numberOfItems = 0;
                current.weight = 0;
                current.cube = 0;
                
                [retval addObject:current];
                
            }
        }
    }
    
    return retval;
}

-(NSArray*)getPVODestinationRooms:(int)pvoUnloadID
{
    sqlite3_stmt *stmnt;
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVORoomSummary* current = nil;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(d.RoomID), d.PVOUnloadID FROM PVODestinationRoomConditions d LEFT OUTER JOIN Rooms r ON r.RoomID = d.RoomID WHERE d.PVOUnloadID = %d", pvoUnloadID] withStatement:&stmnt]) {
        
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVORoomSummary alloc] init];
            current.room = [self getRoom:sqlite3_column_int(stmnt, 0)];
            current.numberOfItems = 0;
            current.weight = 0;
            current.cube = 0;
            
            [retval addObject:current];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOItemDetail*)getPVOCartonContentItem:(int)cartonContentID
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE CartonContentID = %d",
                               [self getPVOItemDetailSelectString],
                               cartonContentID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            current.cartonContentID = cartonContentID;
        }
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

-(NSArray*)getPVOItems:(int)pvoLoadID forRoom:(int)roomID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID = %d AND RoomID = %d "
                     "ORDER BY LotNumber, ItemNumber", [self getPVOItemDetailSelectString],
                     pvoLoadID, roomID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOItemsForLoad:(int)loadID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID = %d "
                               "ORDER BY CAST(ItemNumber AS INT)",
                               [self getPVOItemDetailSelectString],
                               loadID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOItemsMproSproForLoad:(int)loadID isMpro:(BOOL)mpro
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID = %d "
                               "%@ "
                               "ORDER BY CAST(ItemNumber AS INT)",
                               [self getPVOItemDetailSelectString],
                               loadID,
                               mpro ? @"AND ItemIsMPRO = 1" : @"AND ItemIsSPRO = 1"]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOAllItems:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)",
                               [self getPVOItemDetailSelectString],
                               custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOAllItems:(int)custID lotNumber:(NSString *)lotNum
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE LotNumber = %@ AND PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)",
                               [self getPVOItemDetailSelectString],
                               [self prepareStringForInsert:lotNum],
                               custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)setPVOItemsInventoriedBeforeSignature:(int)custID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET InventoriedAfterSignature = 0 "
                    "WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", custID]];
}

-(int)updatePVOItem:(PVOItemDetail*)data
{
    return [self updatePVOItem:data withDataUpdateType:PVO_DATA_LOAD_ITEMS];
}

//returns -1 if item already existed
//method used to help track the dirty flags for different data processes (i.e. updating a delivery only field or a load)
-(int)updatePVOItem:(PVOItemDetail*)data withDataUpdateType:(int)dataType
{
    if(data.cartonContentID <= 0 && [self pvoItemExists:data])
        return -1;
    
    if (data.cartonContentID < 0) data.cartonContentID = 0;
    
    [self pvoSetDataIsDirty:YES forType:dataType forCustomer:[self getIntValueFromQuery:
                                                              [NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads "
                                                               "WHERE PVOLoadID = %d", data.pvoLoadID]]];
    
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOItemID = %d AND CartonContentID = %d",
                                   data.pvoItemID, data.cartonContentID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET PVOLoadID = %d, ItemID = %d, RoomID = %d, "
                        "TagColor = %d, CartonContents = %d, NoExceptions = %d, Quantity = %d, "
                        "LotNumber = %@, ItemNumber = %@, ItemIsDeleted = %d, ItemIsDelivered = %d, "
                        "HighValueCost = %f,SerialNumber = %@,ModelNumber = %@,VoidReason = %@,VerifyStatus = %@, "
                        "HasDimensions = %d,Length = %d,Width = %d,Height = %d,DimensionUnitType = %d, InventoriedAfterSignature = %d, PackerInitials = %@, "
                        "IsCPProvided = %d, WeightType = %d, Weight = %d, Cube = %f, "
                        "ItemIsMPRO = %d, ItemIsSPRO = %d, ItemIsCONS = %d, [Year] = %d, Make = %@, Odometer = %d, CaliberOrGauge = %@, DoneWorking = %d, "
                        "LockedItem = %d, SecuritySealNumber = %@"
                        " WHERE PVOItemID = %d AND CartonContentID = %d",
                        data.pvoLoadID, data.itemID, data.roomID, data.tagColor,
                        data.cartonContents ? 1 : 0, data.noExceptions ? 1 : 0, data.quantity,
                        [self prepareStringForInsert:data.lotNumber supportsNull:YES],
                        [self prepareStringForInsert:[data fullItemNumber] supportsNull:YES],
                        data.itemIsDeleted ? 1 : 0,
                        data.itemIsDelivered ? 1 : 0,
                        data.highValueCost,
                        [self prepareStringForInsert:data.serialNumber supportsNull:YES],
                        [self prepareStringForInsert:data.modelNumber supportsNull:YES],
                        [self prepareStringForInsert:data.voidReason supportsNull:YES],
                        [self prepareStringForInsert:data.verifyStatus supportsNull:YES],
                        data.hasDimensions ? 1 : 0, data.length, data.width, data.height, data.dimensionUnitType,
                        data.inventoriedAfterSignature ? 1 : 0,
                        [self prepareStringForInsert:data.packerInitials supportsNull:YES],
                        data.isCPProvided ? 1 : 0,
                        data.weightType,
                        data.weight,
                        data.cube,
                        data.itemIsMPRO ? 1 : 0,
                        data.itemIsSPRO ? 1 : 0,
                        data.itemIsCONS ? 1 : 0,
                        data.year,
                        [self prepareStringForInsert:data.make supportsNull:YES],
                        data.odometer,
                        [self prepareStringForInsert:data.caliberGauge supportsNull:YES],
                        data.doneWorking ? 1 : 0,
                        data.lockedItem ? 1 : 0,
                        [self prepareStringForInsert:data.securitySealNumber supportsNull:YES],
                        data.pvoItemID,
                        data.cartonContentID]];
        return data.pvoItemID;
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryItems(PVOLoadID, ItemID, RoomID, "
                        "TagColor, CartonContents, NoExceptions, Quantity, "
                        "LotNumber, ItemNumber, ItemIsDeleted, ItemIsDelivered,HighValueCost,SerialNumber,"
                        "ModelNumber,VoidReason,VerifyStatus,HasDimensions,Length,Width,Height,DimensionUnitType,InventoriedAfterSignature,PackerInitials,IsCPProvided,"
                        "WeightType,Weight,Cube,CartonContentID,ItemIsMPRO,ItemIsSPRO,ItemIsCONS,[Year],Make,Odometer,CaliberOrGauge,DoneWorking,LockedItem,SecuritySealNumber) "
                        "VALUES(%d,%d,%d,%d,%d,%d,%d,%@,%@,%d,%d,%f,%@,%@,%@,%@,%d,%d,%d,%d,%d,%d,%@,%d,%d,%d,%f,%d,%d,%d,%d,%d,%@,%d,%@,%d,%d,%@)",
                        data.pvoLoadID, data.itemID, data.roomID, data.tagColor,
                        data.cartonContents ? 1 : 0, data.noExceptions ? 1 : 0, data.quantity,
                        [self prepareStringForInsert:data.lotNumber supportsNull:YES],
                        [self prepareStringForInsert:[data fullItemNumber] supportsNull:YES],
                        data.itemIsDeleted ? 1 : 0,
                        data.itemIsDelivered ? 1 : 0,
                        data.highValueCost,
                        [self prepareStringForInsert:data.serialNumber supportsNull:YES],
                        [self prepareStringForInsert:data.modelNumber supportsNull:YES],
                        [self prepareStringForInsert:data.voidReason supportsNull:YES],
                        [self prepareStringForInsert:data.verifyStatus supportsNull:YES],
                        data.hasDimensions ? 1 : 0, data.length, data.width, data.height,data.dimensionUnitType,
                        data.inventoriedAfterSignature ? 1 : 0,
                        [self prepareStringForInsert:data.packerInitials supportsNull:YES],
                        data.isCPProvided ? 1 : 0,
                        data.weightType,
                        data.weight,
                        data.cube,
                        data.cartonContentID,
                        data.itemIsMPRO ? 1 : 0,
                        data.itemIsSPRO ? 1 : 0,
                        data.itemIsCONS ? 1 : 0,
                        data.year,
                        [self prepareStringForInsert:data.make supportsNull:YES],
                        data.odometer,
                        [self prepareStringForInsert:data.caliberGauge supportsNull:YES],
                        data.doneWorking ? 1 : 0,
                        data.lockedItem ? 1 : 0,
                        [self prepareStringForInsert:data.securitySealNumber supportsNull:YES]]];

        return sqlite3_last_insert_rowid(db);
    }
}

//-(BOOL)updatePVOComments:(PVOItemDetail*)data comments:(NSString *)commentsText
//{
//    if([self pvoItemExists:data])
//        return NO;
//
//    [self pvoSetDataIsDirty:YES forType:PVO_DATA_LOAD_ITEMS forCustomer:[self getIntValueFromQuery:
//                                                                         [NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads "
//                                                                          "WHERE PVOLoadID = %d", data.pvoLoadID]]];
//
//    BOOL b = NO;
//
//	if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOItemID = %d", data.pvoItemID]] > 0)
//	{
//		[self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET Comments = %@"
//                        " WHERE PVOItemID = %d",
//                        [self prepareStringForInsert:data.comments supportsNull:YES],
//                        data.pvoItemID]];
//        b = YES;
//	}
//
//    return b;
//}

-(NSArray*)getRemainingPVOItems:(int)pvoUnloadID forLot:(NSString*)lotNumber
{
    return [self getRemainingPVOItems:pvoUnloadID forLot:lotNumber useLotNumber:TRUE];
}

-(NSArray*)getRemainingPVOItems:(int)pvoUnloadID forLot:(NSString*)lotNumber useLotNumber:(BOOL)useLotNumber
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    
    NSMutableString *cmd = [[NSMutableString alloc] init];
    
    [cmd appendString:[NSString stringWithFormat:@"SELECT %1$@ "
                       " JOIN Items i ON ii.ItemID = i.ItemID "
                       //" JOIN ItemDescription d ON i.ItemID = d.ItemID"
                       " WHERE PVOLoadID IN (SELECT PVOLoadID FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %2$d) "
                       //"AND"
                       //" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = (SELECT CustomerID FROM PVOInventoryUnloads WHERE PVOUnloadID = %2$d)) "
                       //"AND "
                       //" i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = (SELECT CustomerID FROM PVOInventoryUnloads WHERE PVOUnloadID = %2$d)) "
                       ,
                       [self getPVOItemDetailSelectString:@"ii"],
                       pvoUnloadID]];
    
    
    //Add lot if not using scanner, else it will show all items for the load
    if (useLotNumber)
        [cmd appendString:[NSString stringWithFormat:@"AND LotNumber = %@ ", [self prepareStringForInsert:lotNumber]]];
    
    //finish the select statement
    [cmd appendString:@"AND ItemIsDelivered = 0 AND ItemIsDeleted = 0 ORDER BY ItemNumber ASC"];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)getPVOItemDetailSelectString
{
    return [self getPVOItemDetailSelectString:@""];
}
-(NSString*)getPVOItemDetailSelectString:(NSString*)prefix
{
    NSString *cmd = [NSString stringWithFormat:@"%1$@PVOItemID, %1$@PVOLoadID, %1$@ItemID, %1$@RoomID, "
            "%1$@TagColor, %1$@CartonContents, %1$@NoExceptions, %1$@Quantity, "
            "%1$@LotNumber, %1$@ItemNumber, %1$@ItemIsDeleted, %1$@ItemIsDelivered, %1$@HighValueCost,"
            "%1$@SerialNumber, %1$@ModelNumber, %1$@VoidReason, %1$@VerifyStatus, %1$@HasDimensions, %1$@Length, %1$@Width, %1$@Height, %1$@DimensionUnitType,"
            "%1$@InventoriedAfterSignature, %1$@PackerInitials, %1$@IsCPProvided,"
            "%1$@WeightType, %1$@Weight, %1$@Cube, %1$@CartonContentID, %1$@ItemIsMPRO, %1$@ItemIsSPRO, %1$@ItemIsCONS,"
            "%1$@[Year], %1$@Make, %1$@Odometer, %1$@CaliberOrGauge, %1$@DoneWorking, %1$@LockedItem, %1$@SecuritySealNumber"
            " FROM PVOInventoryItems %2$@",
            ([prefix length] > 0 ? [NSString stringWithFormat:@"%@.", prefix] : @""),
            ([prefix length] > 0 ? prefix : @"")];
    
    return cmd;
    
}

-(PVOItemDetail*)getPVOItem:(int)pvoLoadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber
{
    return [self getPVOItem:pvoLoadID forLotNumber:lotNumber withItemNumber:itemNumber includeDeleted:FALSE];
}

-(PVOItemDetail*)getPVOItem:(int)pvoLoadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber includeDeleted:(BOOL)withDeleted
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID = %d AND LotNumber = %@ AND ItemNumber = %@ %@",
                               [self getPVOItemDetailSelectString],
                               pvoLoadID, [self prepareStringForInsert:lotNumber],
                               [self prepareStringForInsert:[PVOItemDetail paddedItemNumber:itemNumber]],
                               (withDeleted ? @"" : @"AND ItemIsDeleted = 0")]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

//this is just returning the first item that matches that item number (or item and lot if both provided)...
-(PVOItemDetail*)getPVOItemForCustID:(int)custID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = nil;
    if(lotNumber == nil || [lotNumber length] == 0)
        cmd = [NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) "
               "AND ItemNumber = %@ AND ItemIsDeleted = 0",
               [self getPVOItemDetailSelectString],
               custID,
               [self prepareStringForInsert:[PVOItemDetail paddedItemNumber:itemNumber]]];
    else
        cmd = [NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) "
               "AND LotNumber = %@ AND ItemNumber = %@ AND ItemIsDeleted = 0",
               [self getPVOItemDetailSelectString],
               custID, [self prepareStringForInsert:lotNumber],
               [self prepareStringForInsert:[PVOItemDetail paddedItemNumber:itemNumber]]];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

-(PVOItemDetail*)getPVOItem:(int)pvoItemID
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOItemID = %d",
                               [self getPVOItemDetailSelectString],
                               pvoItemID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

-(int)getPVODeliveryType:(int)pvoLoadID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT ul.PVOLocationID FROM PVOInventoryUnloads ul "
                                       "JOIN PVOInventoryUnloadLoadXref xref ON xref.PVOUnloadID = ul.PVOUnloadID "
                                       "AND xref.PVOLoadID = %d", pvoLoadID]];
}

-(PVOItemDetail*)getPVOItemForUnload:(int)pvoUnloadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN (SELECT PVOLoadID FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d) "
                               "AND LotNumber = %@ AND ItemNumber = %@ AND ItemIsDeleted = 0",
                               [self getPVOItemDetailSelectString],
                               pvoUnloadID,
                               [self prepareStringForInsert:lotNumber],
                               [self prepareStringForInsert:[PVOItemDetail paddedItemNumber:itemNumber]]]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

-(void)copyPVOItem:(PVOItemDetail*)pvoItem withQuantity:(int)qty includeDetails:(BOOL)withDetail
{
    [self copyPVOItem:pvoItem withQuantity:qty andCartonContentID:-1 includeDetails:withDetail];
}

-(void)copyPVOItem:(PVOItemDetail*)pvoItem withQuantity:(int)qty andCartonContentID:(int)cartonContentID includeDetails:(BOOL)withDetail
{
    for(int i = 0; i < qty; i++)
    {
        //make an identical copy of the PVO item (minus high value initials, and images)
        
        //get customer id
        int custid = -1;
        if (pvoItem.pvoLoadID > 0) //grab it off item
            custid = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads WHERE PVOLoadID = %d", pvoItem.pvoLoadID]];
        else if (cartonContentID > 0) //grab it off parent item of Carton Content
            custid = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads WHERE PVOLoadID = ("
                                                 "SELECT PVOLoadID FROM PVOInventoryItems WHERE PVOItemID = ("
                                                 "SELECT PVOItemID FROM PVOInventoryCartonContents WHERE CartonContentID = %d))", cartonContentID]];
        if (custid <= 0) return; //error figuring out CustomerID
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryItems"
                        "(PVOLoadID, ItemID, RoomID, "
                        "TagColor, CartonContents, NoExceptions, Quantity, "
                        "LotNumber, ItemNumber, ItemIsDeleted, ItemIsDelivered,"
                        "HighValueCost,SerialNumber,ModelNumber,VoidReason,VerifyStatus,HasDimensions,"
                        "Length,Width,Height,DimensionUnitType,InventoriedAfterSignature,PackerInitials,IsCPProvided,"
                        "WeightType,Weight,Cube,CartonContentID,ItemIsMPRO,ItemIsSPRO,ItemIsCONS,"
                        "[Year],Make,Odometer,CaliberOrGauge,DoneWorking,LockedItem,SecuritySealNumber) SELECT "
                        "PVOLoadID, ItemID, RoomID, "
                        "TagColor, CartonContents, NoExceptions, Quantity, "
                        "LotNumber, %@, ItemIsDeleted, ItemIsDelivered,HighValueCost"
                        ",SerialNumber,ModelNumber,VoidReason,VerifyStatus,HasDimensions,Length,Width,"
                        "Height,DimensionUnitType,InventoriedAfterSignature,PackerInitials,IsCPProvided,"
                        "WeightType,Weight,Cube,%@,ItemIsMPRO,ItemIsSPRO,ItemIsCONS,"
                        "[Year],Make,Odometer,CaliberOrGauge,1,0,SecuritySealNumber "
                        "FROM PVOInventoryItems WHERE PVOItemID = %d",
                        (pvoItem.cartonContentID <= 0 && cartonContentID <= 0 ? [self prepareStringForInsert:[self nextPVOItemNumber:custid forLot:pvoItem.lotNumber]] : @"ItemNumber"),
                        (cartonContentID > 0 ? [NSString stringWithFormat:@"%d", cartonContentID] : @"CartonContentID"),
                        pvoItem.pvoItemID]];
        
        int newID = sqlite3_last_insert_rowid(db);
        
        if (withDetail)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryDamage"
                            "(PVOItemID, DamageCodes, LocationCodes, "
                            "PVOLoadID, PVOUnloadID, DamageType) SELECT "
                            "%d, DamageCodes, LocationCodes, "
                            "PVOLoadID, PVOUnloadID, DamageType "
                            "FROM PVOInventoryDamage WHERE PVOItemID = %d",
                            newID, pvoItem.pvoItemID]];
            
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryItemComments(PVOItemID, Comments, CommentType) SELECT "
                            "%d, Comments, CommentType FROM PVOInventoryItemComments WHERE PVOItemID = %d",
                            newID, pvoItem.pvoItemID]];
        }
        
        //        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryCartonContents"
        //                        "(PVOItemID, ContentCode) SELECT "
        //                        "%d, ContentCode "
        //                        "FROM PVOInventoryCartonContents WHERE PVOItemID = %d",
        //                        newID, pvoItem.pvoItemID]];
        
        if (pvoItem.cartonContentID <= 0 && cartonContentID <= 0)
        { //carton content details
            NSMutableArray *ccIDs = [NSMutableArray array];
            NSString *cmd = [NSString stringWithFormat:@"SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d", pvoItem.pvoItemID];
            sqlite3_stmt *stmnt;
            if ([self prepareStatement:cmd withStatement:&stmnt])
            {
                while (sqlite3_step(stmnt) == SQLITE_ROW && sqlite3_column_type(stmnt, 0) != SQLITE_NULL)
                    [ccIDs addObject:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
            }
            sqlite3_finalize(stmnt);
            if ([ccIDs count] > 0)
            {
                for (NSNumber *ccID in [ccIDs objectEnumerator])
                {
                    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryCartonContents"
                                    "(PVOItemID, ContentCode) SELECT "
                                    "%d, ContentCode "
                                    "FROM PVOInventoryCartonContents WHERE PVOItemID = %d AND CartonContentID = %d",
                                    newID, pvoItem.pvoItemID, [ccID intValue]]];
                    int newCartonContentID = sqlite3_last_insert_rowid(db);
                    PVOItemDetail *ccItem = [self getPVOCartonContentItem:[ccID intValue]]; //grab detailed record, if exists
                    if (ccItem != nil)
                        [self copyPVOItem:ccItem withQuantity:1 andCartonContentID:newCartonContentID includeDetails:withDetail]; //copy the carton content details
                }
            }
        }
        
        if (withDetail)
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryDescriptions"
                            "(PVOItemID, DescriptiveCode) SELECT "
                            "%d, DescriptiveCode "
                            "FROM PVOInventoryDescriptions WHERE PVOItemID = %d",
                            newID, pvoItem.pvoItemID]];
        }
    }
}

//checks tag to see if item already exists
-(BOOL)pvoItemExists:(PVOItemDetail*)data
{
    int anid = [self getIntValueFromQuery:
                [NSString stringWithFormat:
                 @"SELECT PVOItemID FROM PVOInventoryItems "
                 "WHERE PVOLoadID = %d AND LotNumber = %@ AND ItemNumber = %@ AND COALESCE(CartonContentID,0) <= 0 AND PVOItemID != %d"/* AND ItemIsDeleted = 0"*/, //removed per defect 38
                 data.pvoLoadID,
                 [self prepareStringForInsert:data.lotNumber],
                 [self prepareStringForInsert:[data fullItemNumber]],
                 (data.pvoItemID < 0 ? 0 : data.pvoItemID)]];
    
    if(anid != 0 && anid != data.pvoItemID)
        return TRUE;
    else
        return FALSE;
}

-(NSString*)nextPVOItemNumber:(int)custID forLot:(NSString*)lotNum
{
    sqlite3_stmt *stmnt;
    int nextNumber = -1;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ItemNumber FROM PVOInventoryItems "
                               "WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) "
                               "AND LotNumber = %@ ORDER BY ItemNumber COLLATE NOCASE DESC",
                               custID, [self prepareStringForInsert:lotNum]]
                withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            nextNumber = [[SurveyDB stringFromStatement:stmnt columnID:0] intValue] + 1;
        }
    }
    sqlite3_finalize(stmnt);
    
    if(nextNumber == -1)
    {
        PVOInventory *inv = [self getPVOData:custID];
        nextNumber = inv.nextItemNum;
    }
    
    return [PVOItemDetail paddedItemNumber:[NSString stringWithFormat:@"%d", nextNumber]];
}

-(NSString*)nextPVOItemNumber:(int)custID forLot:(NSString*)lotNum withStartingItem:(int)startingItemNum
{
    sqlite3_stmt *stmnt;
    NSMutableSet *numSet = [NSMutableSet set];
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ItemNumber FROM PVOInventoryItems "
                               "WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) "
                               "AND LotNumber = %@ ORDER BY ItemNumber COLLATE NOCASE DESC",
                               custID, [self prepareStringForInsert:lotNum]]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSNumber *num = @([[SurveyDB stringFromStatement:stmnt columnID:0] intValue]);
            [numSet addObject:num];
        }
    }
    sqlite3_finalize(stmnt);
    
    NSNumber *nextNum = @(startingItemNum);
    while ([numSet containsObject:nextNum]) {
        nextNum = @([nextNum integerValue] + 1);
    }
    
    return [PVOItemDetail paddedItemNumber:[NSString stringWithFormat:@"%@", nextNum]];
}

-(void)deletePVODestinationRoom:(int)pvoUnloadID andRoom:(int)roomid
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVODestinationRoomConditions "
                    "WHERE PVOUnloadID = %d AND RoomID = %d", pvoUnloadID, roomid]];
}

-(void)deletePVOItemsInRoom:(int)pvoLoadID andRoom:(int)roomid
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems "
                    "SET ItemIsDeleted = 1 "
                    "WHERE PVOLoadID = %d AND RoomID = %d",
                    pvoLoadID, roomid]];
}

-(void)deletePVOItem:(int)pvoItemID withCustomerID:(int)custID
{
    [self deletePVOItem:pvoItemID isCartonContent:NO withCustomerID:custID];
}

-(void)deletePVOItem:(int)pvoItemID isCartonContent:(BOOL)cartonContent withCustomerID:(int)custID
{
    //remove detailed carton content items first
    if (!cartonContent)
    {
        NSArray *ccItems = [self getPVOCartonContents:pvoItemID withCustomerID:custID];
        if (ccItems != nil && [ccItems count] > 0)
        {
            PVOItemDetail *ccItem;
            for (PVOCartonContent *cc in ccItems)
            {
                ccItem = [self getPVOCartonContentItem:cc.cartonContentID];
                if (ccItem != nil)
                    [self deletePVOItem:ccItem.pvoItemID isCartonContent:YES withCustomerID:custID];
            }
        }
    }
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItems WHERE PVOItemID = %d", pvoItemID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVOItemID = %d", pvoItemID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryCartonContents WHERE PVOItemID = %d", pvoItemID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDescriptions WHERE PVOItemID = %d", pvoItemID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItemComments WHERE PVOItemID = %d", pvoItemID]];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *photos = [self getImagesList:del.customerID withPhotoType:IMG_PVO_ITEMS withSubID:pvoItemID loadAllItems:NO];
    
    for (SurveyImage *img in photos) {
        [self deleteImageEntry:img.imageID];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        NSString *inDocsPath = img.path;
        NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
        NSError *error;
        if([fileManager fileExistsAtPath:fullPath])
            [fileManager removeItemAtPath:fullPath error:&error];
    }
}

-(void)voidPVOItem:(int)pvoItemID
{
    [self voidPVOItem:pvoItemID withReason:@""];
}

-(void)voidPVOItem:(int)pvoItemID withReason:(NSString*)reason
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET ItemIsDeleted = 1, VoidReason = %@ WHERE PVOItemID = %d",
                    (reason == nil ? @"" : [self prepareStringForInsert:reason]), pvoItemID]];
}

-(void)setWorkingPVOItem:(int)pvoItemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET DoneWorking = 0 WHERE PVOItemID = %d", pvoItemID]];
}

-(void)doneWorkingPVOItem:(int)pvoItemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET DoneWorking = 1 WHERE PVOItemID = %d", pvoItemID]];
}

-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID
{
    return [self getPVOReceivableItemDamage:pvoReceivableItemID forDamageTypes:nil];
}
-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID forDamageType:(int)damageType
{
    return [self getPVOReceivableItemDamage:pvoReceivableItemID forDamageTypes:[NSArray arrayWithObject:[NSNumber numberWithInt:damageType]]];
}
-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID forDamageTypes:(NSArray*)damageTypes
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOConditionEntry *current = nil;
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat:@"SELECT ReceivableItemID,Damages,Locations,DamageType "
                     "FROM PVOReceivableDamages "
                     "WHERE ReceivableItemID = %d", pvoReceivableItemID];
    if (damageTypes != nil && [damageTypes count] > 0)
    {
        cmd = [cmd stringByAppendingString:@" AND DamageType IN("];
        BOOL first = YES;
        for (NSNumber *dmgType in damageTypes) {
            if (!first) cmd = [cmd stringByAppendingString:@","];
            cmd = [cmd stringByAppendingFormat:@"%d", [dmgType intValue]];
            first = NO;
        }
        cmd = [cmd stringByAppendingString:@")"];
    }
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOConditionEntry alloc] init];
            current.pvoItemID = sqlite3_column_int(stmnt, 0);
            current.conditions = [SurveyDB stringFromStatement:stmnt columnID:1];
            current.locations = [SurveyDB stringFromStatement:stmnt columnID:2];
            //            current.pvoLoadID = sqlite3_column_int(stmnt, 3);
            //            current.pvoUnloadID = sqlite3_column_int(stmnt, 4);
            current.damageType = sqlite3_column_int(stmnt, 3);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOItemDamage:(int)itemID
{
    return [self getPVOItemDamage:itemID forDamageTypes:nil];
}

-(NSArray*)getPVOItemDamage:(int)itemID forDamageType:(int)damageType
{
    return [self getPVOItemDamage:itemID forDamageTypes:[NSArray arrayWithObject:[NSNumber numberWithInt:damageType]]];
}

-(NSArray*)getPVOItemDamage:(int)itemID forDamageTypes:(NSArray*)damageTypes
{
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOConditionEntry *current = nil;
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat:@"SELECT PVODamageID,PVOItemID,DamageCodes,LocationCodes,PVOLoadID,PVOUnloadID,DamageType "
                     "FROM PVOInventoryDamage "
                     "WHERE PVOItemID = %d", itemID];
    if (damageTypes != nil && [damageTypes count] > 0)
    {
        cmd = [cmd stringByAppendingString:@" AND DamageType IN("];
        BOOL first = YES;
        for (NSNumber *dmgType in damageTypes) {
            if (!first) cmd = [cmd stringByAppendingString:@","];
            cmd = [cmd stringByAppendingFormat:@"%d", [dmgType intValue]];
            first = NO;
        }
        cmd = [cmd stringByAppendingString:@")"];
    }
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOConditionEntry alloc] init];
            current.pvoDamageID = sqlite3_column_int(stmnt, 0);
            current.pvoItemID = sqlite3_column_int(stmnt, 1);
            current.conditions = [SurveyDB stringFromStatement:stmnt columnID:2];
            current.locations = [SurveyDB stringFromStatement:stmnt columnID:3];
            current.pvoLoadID = sqlite3_column_int(stmnt, 4);
            current.pvoUnloadID = sqlite3_column_int(stmnt, 5);
            current.damageType = sqlite3_column_int(stmnt, 6);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)deletePVODamage:(int)pvoItemID withDamageType:(int)damageType
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVOItemID = %d AND DamageType = %d", pvoItemID, damageType]];
    
}

-(void)savePVODamage:(PVOConditionEntry*)entry
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDamage WHERE PVODamageID = %d", entry.pvoDamageID]] > 0)
    {
        //if empty, delete record.
        if([entry isEmpty])
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDamage WHERE PVODamageID = %d",
                            entry.pvoDamageID]];
        else
            [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryDamage SET PVOItemID = %d,DamageCodes = %@,LocationCodes = %@,PVOLoadID = %d,PVOUnloadID = %d, DamageType = %d"
                            " WHERE PVODamageID = %d",
                            entry.pvoItemID,
                            [self prepareStringForInsert:entry.conditions],
                            [self prepareStringForInsert:entry.locations],
                            entry.pvoLoadID, entry.pvoUnloadID, (int)entry.damageType, entry.pvoDamageID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryDamage(PVOItemID,DamageCodes,LocationCodes,PVOLoadID,PVOUnloadID,DamageType) "
                        "VALUES(%d,%@,%@,%d,%d,%d)",
                        entry.pvoItemID,
                        [self prepareStringForInsert:entry.conditions],
                        [self prepareStringForInsert:entry.locations],
                        entry.pvoLoadID, entry.pvoUnloadID, (int)entry.damageType]];
    }
}

-(int)hasPVODamage:(int)pvoItemID forDamageType:(enum PVO_DAMAGE_TYPE)damageType
{
    return ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDamage WHERE PVOItemID = %d "
                                        "AND DamageType = %d AND LENGTH(COALESCE(DamageCodes,'')) > 0 AND LENGTH(COALESCE(LocationCodes,'')) > 0", pvoItemID, (int)damageType]] > 0);
}


-(NSArray*)getPVOFavoriteCartonContents:(NSString*)search
{
    return [self getPVOFavoriteCartonContents:search withCustomerID:-1];
}

-(NSArray*)getPVOFavoriteCartonContents:(NSString*)search withCustomerID:(int)custID
{
    return [self getPVOAllCartonContents:search withCustomerID:custID includeFavorites:1];
}

-(NSArray*)getPVOAllCartonContents
{
    return [self getPVOAllCartonContents:nil withCustomerID:-1];
}

-(NSArray*)getPVOAllCartonContents:(int)custID
{
    return [self getPVOAllCartonContents:nil withCustomerID:custID];
}

-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID
{
    return [self getPVOAllCartonContents:search withCustomerID:custID includeFavorites:-1];
}

-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID withHidden:(BOOL)showHidden
{
    return [self getPVOAllCartonContents:search withCustomerID:custID includeFavorites:-1 withHidden:showHidden];
}


-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID includeFavorites:(int)favorites
{
    return [self getPVOAllCartonContents:search withCustomerID:custID includeFavorites:-1 withHidden:NO];
}

-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID includeFavorites:(int)favorites withHidden:(BOOL)showHidden
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOCartonContent *current = nil;
    sqlite3_stmt *stmnt;
    
    NSMutableString *cmd;
    
    NSString *itemListClause = @"";
    if (custID > 0){
        if([AppFunctionality requiresPropertyCondition]){
            itemListClause =  @" LanguageCode = 0 AND ItemListID = 0 "; // need to remove the logic around this if/when adding special products specific rooms
        } else {
            itemListClause = [NSString stringWithFormat:@" LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
        }
    } else {
        itemListClause = @" LanguageCode = 0 AND ItemListID = 0 ";
    }
    
    if(!showHidden) {
        // If not showing hidden items, this branch will be used (not modified from original)
    cmd = [NSMutableString stringWithFormat:@"SELECT CartonContentID,ContentDescription FROM PVOCartonContents WHERE Hidden = 0 AND %@", itemListClause];
    } else {
        // If showing hidden items, this branch will be used (modified from original)
        cmd = [NSMutableString stringWithFormat:@"SELECT CartonContentID,ContentDescription,Hidden FROM PVOCartonContents WHERE %@", itemListClause];
    }
    
    
    if (favorites >= 0)
        [cmd appendFormat:@" AND Favorite = %d", favorites];
    if ([search length] > 0)
        [cmd appendFormat:@" AND ContentDescription LIKE '%%%@%%'", search];
    
    [cmd appendString:@" ORDER BY ContentDescription COLLATE NOCASE"];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOCartonContent alloc] init];
            
            current.contentID = sqlite3_column_int(stmnt, 0);
            current.description = [SurveyDB stringFromStatement:stmnt columnID:1];
            
            if(showHidden) {
                // If showing hidden items, get that information
                current.isHidden = sqlite3_column_int(stmnt, 2);
            }
            
            //shouldn't get here, but this bug existed where blank contents were allowed...
            if(current.description == nil || [current.description isEqualToString:@""])
            {
                
                continue;
            }
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}



-(PVOCartonContent*)getPVOCartonContent:(int)contentID withCustomerID:(int)custID
{
    NSString *itemListClause = @"";
    if (custID > 0){
        if([AppFunctionality requiresPropertyCondition]){
            itemListClause =  @" LanguageCode = 0 AND ItemListID = 0 "; // need to remove the logic around this if/when adding special products specific rooms
        } else {
            itemListClause = [NSString stringWithFormat:@" LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
        }
    } else {
        itemListClause = @" LanguageCode = 0 AND ItemListID = 0 ";
    }
    
    PVOCartonContent *current = [[PVOCartonContent alloc] init];
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT CartonContentID,ContentDescription FROM PVOCartonContents WHERE CartonContentID = %d AND %@" , contentID, itemListClause]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current.contentID = sqlite3_column_int(stmnt, 0);
            current.description = [SurveyDB stringFromStatement:stmnt columnID:1];
        }
    }
    sqlite3_finalize(stmnt);
    
    return current;
}


//get an individual carton content record stored for an item by id.
-(PVOCartonContent*)getPVOItemCartonContent:(int)cartonContentID
{
    PVOCartonContent *current = [[PVOCartonContent alloc] init];
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ContentCode,CartonContentID,PVOItemID FROM PVOInventoryCartonContents "
                               "WHERE CartonContentID = %d" , cartonContentID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current.contentID =sqlite3_column_int(stmnt, 0);
            current.cartonContentID = sqlite3_column_int(stmnt, 1);
            current.pvoItemID = sqlite3_column_int(stmnt, 2);
        }
    }
    sqlite3_finalize(stmnt);
    
    return current;
}


-(NSArray*)getPVOCartonContents:(int)pvoItemID withCustomerID:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    
    NSString *itemListClause = @"";
    
    //if (custID > 0)
    //    itemListClause = [NSString stringWithFormat:@" c.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND c.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
   // else
    //    itemListClause = @" c.LanguageCode = 0 AND c.ItemListID = 0 ";
    if (custID > 0){
        if([AppFunctionality requiresPropertyCondition]){
            itemListClause =  @" c.LanguageCode = 0 AND c.ItemListID = 0 "; // need to remove the logic around this if/when adding special products specific rooms
        } else {
            itemListClause = [NSString stringWithFormat:@" c.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND c.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
        }
    } else {
        itemListClause = @" c.LanguageCode = 0 AND c.ItemListID = 0 ";
    }
    
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ic.ContentCode,ic.CartonContentID FROM PVOInventoryCartonContents ic "
                               " INNER JOIN PVOCartonContents c ON c.CartonContentID = ic.ContentCode "
                               "WHERE ic.PVOItemID = %d AND %@ ORDER BY c.ContentDescription", pvoItemID, itemListClause]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVOCartonContent *content = [[PVOCartonContent alloc] init];
            content.contentID = sqlite3_column_int(stmnt, 0);
            content.cartonContentID = sqlite3_column_int(stmnt, 1);
            content.pvoItemID = pvoItemID;
            [retval addObject:content];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)pvoItemHasExpandedCartonContentItems:(int)pvoItemID
{
    int detailCount = [self getIntValueFromQuery:
                       [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE "
                        "CartonContentID IN (SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d) AND ("
                        "(COALESCE(Quantity,1) > 1) OR "
                        "(COALESCE(HighValueCost,0.0) > 0.00) OR "
                        "(COALESCE(Weight,0) > 0) OR "
                        "(COALESCE(Cube,0.00) > 0.00) OR "
                        "(LENGTH(TRIM(COALESCE(SerialNumber,''))) > 0) OR "
                        "(LENGTH(TRIM(COALESCE(ModelNumber,''))) > 0) OR "
                        "(HasDimensions > 0))"
                        ,pvoItemID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDamage WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID IN (SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d)) AND ("
                     "(LENGTH(TRIM(COALESCE(DamageCodes,''))) > 0) OR "
                     "(LENGTH(TRIM(COALESCE(LocationCodes,''))) > 0))"
                     , pvoItemID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDescriptions WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID IN (SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d))"
                     , pvoItemID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItemComments WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID IN (SELECT CartonContentID FROM PVOInventoryCartonContents WHERE PVOItemID = %d)) "
                     "AND (LENGTH(TRIM(COALESCE(Comments, ''))) > 0)",
                     pvoItemID]];
    return (detailCount > 0);
}

-(BOOL)pvoCartonContentItemIsExpanded:(int)cartonContentID
{
    int detailCount = [self getIntValueFromQuery:
                       [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE CartonContentID = %d AND ("
                        "(COALESCE(Quantity,1) > 1) OR "
                        "(COALESCE(HighValueCost,0.0) > 0.00) OR "
                        "(COALESCE(Weight,0) > 0) OR "
                        "(COALESCE(Cube,0.00) > 0.00) OR "
                        "(LENGTH(TRIM(COALESCE(SerialNumber,''))) > 0) OR "
                        "(LENGTH(TRIM(COALESCE(ModelNumber,''))) > 0) OR "
                        "(HasDimensions > 0))"
                        ,cartonContentID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDamage WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID = %d) AND ("
                     "(LENGTH(TRIM(COALESCE(DamageCodes,''))) > 0) OR "
                     "(LENGTH(TRIM(COALESCE(LocationCodes,''))) > 0))"
                     , cartonContentID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryDescriptions WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID = %d)"
                     , cartonContentID]];
    detailCount += [self getIntValueFromQuery:
                    [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItemComments WHERE "
                     "PVOItemID IN (SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID = %d) AND (LENGTH(TRIM(COALESCE(Comments, ''))) > 0)"
                     , cartonContentID]];
    return (detailCount > 0);
}

-(int)addPVOCartonContent:(int)contentID forPVOItem:(int)pvoItemID
{//insert new
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryCartonContents(ContentCode, PVOItemID) VALUES(%d,%d)",
                    contentID, pvoItemID]];
    return sqlite3_last_insert_rowid(db);
}

-(void)removePVOCartonContent:(int)cartonContentID withCustomerID:(int)custID
{//remove the content (by id)
    [self deletePVOItem:[self getPVOCartonContentItem:cartonContentID].pvoItemID withCustomerID:custID];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryCartonContents WHERE CartonContentID = %d",
                    cartonContentID]];
    
}

-(void)updatePVOCartonContents:(int)pvoItem withContents:(NSArray*)contents
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryCartonContents WHERE PVOItemID = %d", pvoItem]];
    for (NSNumber *num in contents) {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryCartonContents(PVOItemID, ContentCode)"
                        " VALUES(%d, '%@')", pvoItem, [num stringValue]]];
    }
}

-(int)getPVONextCartonContentID
{
    int retval = [self getIntValueFromQuery:@"SELECT MAX(CartonContentID) FROM PVOCartonContents"];
    if(retval < 9000)
        return 9000;
    else
        return retval + 1;
}

-(BOOL)savePVOCartonContent:(PVOCartonContent*)content withCustomerID:(int)custID
{
    NSString *itemListClause = @"";
    
    if (custID > 0)
        itemListClause = [NSString stringWithFormat:@" (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d), (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
    else
        itemListClause = @"0,0";
    
    int count = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOCartonContents WHERE CartonContentID = %d", content.contentID]];
    if(count != 0 || content.contentID < 9000)// || content.contentID > 9999)
        return FALSE;
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOCartonContents(CartonContentID,ContentDescription, Hidden,ItemListID, LanguageCode) VALUES(%d,'%@',0,%@)",
                    content.contentID, [content.description stringByReplacingOccurrencesOfString:@"'" withString:@"''"], itemListClause]];
    
    return TRUE;
}

-(void)hidePVOCartonContent:(int)contentsID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOCartonContents SET Hidden = 1 WHERE CartonContentID = %d", contentsID]];
}

-(void)unhidePVOCartonContent:(int)contentsID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOCartonContents SET Hidden = 0 WHERE CartonContentID = %d", contentsID]];
}

-(NSArray*)getPVOFavoriteItemsWithCustomerID:(int)custID
{
    ItemType *itemTypes = [AppFunctionality getItemTypes:[self getCustomer:custID].pricingMode
                                          withDriverType:[self getDriverData].driverType
                                            withLoadType:[self getPVOData:custID].loadType];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Item *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ "
                     " AND i.Favorite = 1 "
                     " AND i.Hidden != 1 "
                     " %@"
                     " ORDER BY d.Description COLLATE NOCASE ASC",
                     [Item getItemSelectString:custID withItemTablePrefix:@"i" withDescriptionTablePrefix:@"d"],
                     [self getItemTypesSelection:itemTypes isFirst:NO withTableAppend:@"i"]];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[Item alloc] initWithStatement:stmnt];
            
            if([self includeItemInRoom:item])
                [array addObject:item];
            
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    
    return array;
    
}

-(void)addPVOFavoriteItem:(int)itemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Items SET Favorite = 1 WHERE ItemID = %d", itemID]];
}

-(void)removePVOFavoriteItem:(int)itemID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE Items SET Favorite = 0 WHERE ItemID = %d", itemID]];
}

-(void)removeAllPVOFavoriteItems {
    [self updateDB:@"UPDATE Items SET Favorite = 0 WHERE TRUE"];
}

-(NSArray*)getPVOLots:(int)pvoUnloadID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(LotNumber) FROM PVOInventoryItems "
                               "WHERE PVOLoadID IN (SELECT PVOLoadID FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d)", pvoUnloadID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSString *temp = [SurveyDB stringFromStatement:stmnt columnID:0];
            
            if(temp != nil)
                [retval addObject:temp];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVOSignature:(int)custID forImageType:(int)pvoImageType withImage:(UIImage*)image
{
    return [self savePVOSignature:custID forImageType:pvoImageType withImage:image withReferenceID:-1];
}

-(int)savePVOSignature:(int)custID forImageType:(int)pvoImageType withImage:(UIImage*)image withReferenceID:(int)referenceID
{
    int retval = -1;
    
    //delete the printed name if one exists BEFORE deleting the signautre
    [self deletePVOSignaturePrintedName:custID forImageType:pvoImageType withReferenceID:referenceID];
    
    [self deletePVOSignature:custID forImageType:pvoImageType withReferenceID:referenceID];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullDirectory = [documentsDirectory stringByAppendingPathComponent:IMG_PVO_DIRECTORY];
    
    BOOL isDir = YES;
    NSError *error;
    if(![fileManager fileExistsAtPath:fullDirectory isDirectory:&isDir])
        [fileManager createDirectoryAtPath:fullDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString *fullPath = [fullDirectory stringByAppendingFormat:@"/%@[%d].png", IMG_PVO_FILE_NAME, 0];
    isDir = NO;
    int i = 1;
    while([fileManager fileExistsAtPath:fullPath]) {
        fullPath = [fullDirectory stringByAppendingFormat:@"/%@[%d].png", IMG_PVO_FILE_NAME, i];
        i++;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    if ([fileManager createFileAtPath:fullPath contents:data attributes:nil])
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOSignatures(CustomerID,SigTypeID,SignatureFileName,SignatureDate,ReferenceID)"
                        " VALUES(%d,%d,%@,%f,%d)", custID, pvoImageType,
                        [self prepareStringForInsert:
                         [fullPath stringByReplacingOccurrencesOfString:documentsDirectory withString:@""]],
                        [[NSDate date] timeIntervalSince1970],referenceID]];
        
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
}

-(void)deletePVOSignaturePrintedName:(int)custID forImageType:(int)pvoImageType
{
    [self deletePVOSignaturePrintedName:custID forImageType:pvoImageType withReferenceID:-1];
}

-(void)deletePVOSignaturePrintedName:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID
{
    //if a ref id is provided (currently only used for auto inventory) use it, otherwise let's leave it out of the statement all together
    NSString *refIDClause = nil;
    if (referenceID != -1)
        refIDClause = [NSString stringWithFormat:@" AND ReferenceID = %d",referenceID];
    else
        refIDClause = @"";
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOSignatureName WHERE PVOSignatureID = (SELECT PVOSignatureID FROM PVOSignatures WHERE CustomerID = %d AND SigTypeID = %d%@)",custID,pvoImageType,refIDClause]];
}

-(void)savePVOSignaturePrintedName:(NSString*)printedName withPVOSignatureID:(int)pvoSignatureID
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOSignatureName WHERE PVOSignatureID = %d", pvoSignatureID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOSignatureName SET Name = %@ WHERE PVOSignatureID = %d", [self prepareStringForInsert:printedName supportsNull:NO], pvoSignatureID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOSignatureName(PVOSignatureID,Name) VALUES(%d,%@)", pvoSignatureID, [self prepareStringForInsert:printedName supportsNull:NO]]];
    }
}

-(NSString*)getPVOSignaturePrintedName:(int)pvoSignatureID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT Name FROM PVOSignatureName WHERE PVOSignatureID = %d", pvoSignatureID];
    NSString *retval = [self getStringValueFromQuery:cmd];
    
    return retval;
}

-(PVOSignature*)getPVOSignature:(int)custID forImageType:(int)pvoImageType
{
    return [self getPVOSignature:custID forImageType:pvoImageType withReferenceID:-1];
}

-(PVOSignature*)getPVOSignature:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID
{
    PVOSignature *retval = nil;
    
    //if a ref id is provided (currently only used for auto inventory) use it, otherwise let's leave it out of the statement all together
    NSString *refIDClause = nil;
    if (referenceID != -1)
        refIDClause = [NSString stringWithFormat:@" AND ReferenceID = %d",referenceID];
    else
        refIDClause = @"";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOSignatureID,CustomerID,SigTypeID,SignatureFileName,SignatureDate,ReferenceID FROM PVOSignatures "
                               "WHERE CustomerID = %d AND SigTypeID = %d%@", custID,pvoImageType,refIDClause] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[PVOSignature alloc] init];
            
            retval.pvoSigID = sqlite3_column_int(stmnt, 0);
            retval.custID = sqlite3_column_int(stmnt, 1);
            retval.pvoSigTypeID = sqlite3_column_int(stmnt, 2);
            retval.fileName = [SurveyDB stringFromStatement:stmnt columnID:3];
            retval.sigDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 4)];
            retval.referenceID = sqlite3_column_int(stmnt, 5);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOSignatures:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOSignature *current = nil;
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOSignatureID,CustomerID,SigTypeID,SignatureFileName,SignatureDate,ReferenceID FROM PVOSignatures "
                               "WHERE CustomerID = %d", custID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOSignature alloc] init];
            
            current.pvoSigID = sqlite3_column_int(stmnt, 0);
            current.custID = sqlite3_column_int(stmnt, 1);
            current.pvoSigTypeID = sqlite3_column_int(stmnt, 2);
            current.fileName = [SurveyDB stringFromStatement:stmnt columnID:3];
            current.sigDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 4)];
            current.referenceID = sqlite3_column_int(stmnt, 5);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)deletePVOSignature:(int)custID forImageType:(int)pvoImageType
{
    [self deletePVOSignature:custID forImageType:pvoImageType withReferenceID:-1];
}

-(void)deletePVOSignature:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID
{
    //if a ref id is provided (currently only used for auto inventory) use it, otherwise let's leave it out of the statement all together
    NSString *refIDClause = nil;
    if (referenceID != -1)
        refIDClause = [NSString stringWithFormat:@" AND ReferenceID = %d",referenceID];
    else
        refIDClause = @"";
    
    PVOSignature *sig = [self getPVOSignature:custID forImageType:pvoImageType withReferenceID:referenceID];
    
    if(sig != nil)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if([fileManager fileExistsAtPath:[sig fullFilePath] isDirectory:&isDir])
            [fileManager removeItemAtPath:[sig fullFilePath] error:nil];
        
        
    }
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOSignatures WHERE CustomerID = %d AND SigTypeID = %d%@",custID,pvoImageType,refIDClause]];
}

-(PVORoomConditions*)getPVORoomConditions:(int)pvoLoadID andRoomID:(int)roomID
{
    
    PVORoomConditions *retval = [[PVORoomConditions alloc] init];
    retval.pvoLoadID = pvoLoadID;
    retval.roomID = roomID;
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVORoomConditionID, PVOLoadID, "
                               "RoomID, FloorTypeID, HasDamage, DamageDetail FROM PVORoomConditions"
                               " WHERE PVOLoadID = %d AND RoomID = %d", pvoLoadID, roomID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.roomConditionsID = sqlite3_column_int(stmnt, 0);
            retval.pvoLoadID = sqlite3_column_int(stmnt, 1);
            retval.roomID = sqlite3_column_int(stmnt, 2);
            retval.floorTypeID = sqlite3_column_int(stmnt, 3);
            retval.hasDamage = sqlite3_column_int(stmnt, 4) > 0;
            retval.damageDetail = [SurveyDB stringFromStatement:stmnt columnID:5];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVORoomConditions*)getPVORoomConditions:(int)roomConditionsID
{
    
    PVORoomConditions *retval = [[PVORoomConditions alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVORoomConditionID, PVOLoadID, "
                               "RoomID, FloorTypeID, HasDamage, DamageDetail FROM PVORoomConditions"
                               " WHERE PVORoomConditionID = %d", roomConditionsID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.roomConditionsID = sqlite3_column_int(stmnt, 0);
            retval.pvoLoadID = sqlite3_column_int(stmnt, 1);
            retval.roomID = sqlite3_column_int(stmnt, 2);
            retval.floorTypeID = sqlite3_column_int(stmnt, 3);
            retval.hasDamage = sqlite3_column_int(stmnt, 4) > 0;
            retval.damageDetail = [SurveyDB stringFromStatement:stmnt columnID:5];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVORoomConditions:(PVORoomConditions*)data
{
    int retval = data.roomConditionsID;
    
    [self pvoSetDataIsDirty:YES forType:PVO_DATA_ROOM_CONDITIONS forCustomer:[self getIntValueFromQuery:
                                                                              [NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads "
                                                                               "WHERE PVOLoadID = %d", data.pvoLoadID]]];
    
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVORoomConditions WHERE PVORoomConditionID = %d", data.roomConditionsID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVORoomConditions SET PVOLoadID = %d, "
                        "RoomID = %d, FloorTypeID = %d, HasDamage = %d, DamageDetail = %@"
                        " WHERE PVORoomConditionID = %d",
                        data.pvoLoadID, data.roomID, data.floorTypeID,
                        data.hasDamage ? 1 : 0, [self prepareStringForInsert:data.damageDetail],
                        data.roomConditionsID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVORoomConditions(PVOLoadID, "
                        "RoomID, FloorTypeID, HasDamage, DamageDetail) "
                        "VALUES(%d,%d,%d,%d,%@)",
                        data.pvoLoadID, data.roomID, data.floorTypeID,
                        data.hasDamage ? 1 : 0, [self prepareStringForInsert:data.damageDetail]]];
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
}

-(NSDictionary*)getPVORoomFloorTypes
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT FloorTypeID, Description FROM PVORoomFloorTypes" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVOPropertyTypes
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT FloorTypeID, Description FROM PVOPropertyTypes" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval setObject:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)]
                       forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVORoomConditions*)getPVODestinationRoomConditions:(int)pvoUnloadID andRoomID:(int)roomID
{
    
    PVORoomConditions *retval = [[PVORoomConditions alloc] init];
    retval.pvoUnloadID = pvoUnloadID;
    retval.roomID = roomID;
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVODestinationRoomConditionsID, PVOUnloadID, "
                               "RoomID, FloorTypeID, HasDamage, DamageDetail FROM PVODestinationRoomConditions"
                               " WHERE PVOUnloadID = %d AND RoomID = %d", pvoUnloadID, roomID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.roomConditionsID = sqlite3_column_int(stmnt, 0);
            retval.pvoUnloadID = sqlite3_column_int(stmnt, 1);
            retval.roomID = sqlite3_column_int(stmnt, 2);
            retval.floorTypeID = sqlite3_column_int(stmnt, 3);
            retval.hasDamage = sqlite3_column_int(stmnt, 4) > 0;
            retval.damageDetail = [SurveyDB stringFromStatement:stmnt columnID:5];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVORoomConditions*)getPVODestinationRoomConditions:(int)destinationRoomConditionsID
{
    
    PVORoomConditions *retval = [[PVORoomConditions alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVODestinationRoomConditionsID, PVOUnloadID, "
                               "RoomID, FloorTypeID, HasDamage, DamageDetail FROM PVODestinationRoomConditions"
                               " WHERE PVODestinationRoomConditionsID = %d", destinationRoomConditionsID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.roomConditionsID = sqlite3_column_int(stmnt, 0);
            retval.pvoUnloadID = sqlite3_column_int(stmnt, 1);
            retval.roomID = sqlite3_column_int(stmnt, 2);
            retval.floorTypeID = sqlite3_column_int(stmnt, 3);
            retval.hasDamage = sqlite3_column_int(stmnt, 4) > 0;
            retval.damageDetail = [SurveyDB stringFromStatement:stmnt columnID:5];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVODestinationRoomConditions:(PVORoomConditions*)data
{
    int retval = data.roomConditionsID;
    /*
     [self pvoSetDataIsDirty:YES forType:PVO_DATA_ROOM_CONDITIONS forCustomer:[self getIntValueFromQuery:
     [NSString stringWithFormat:@"SELECT CustomerID FROM PVOInventoryLoads "
     "WHERE PVOUnloadID = %d", data.pvoLoadID]]];
     */
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVODestinationRoomConditions WHERE PVODestinationRoomConditionsID = %d", data.roomConditionsID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVODestinationRoomConditions SET PVOUnloadID = %d, "
                        "RoomID = %d, FloorTypeID = %d, HasDamage = %d, DamageDetail = %@"
                        " WHERE PVODestinationRoomConditionsID = %d",
                        data.pvoUnloadID, data.roomID, data.floorTypeID,
                        data.hasDamage ? 1 : 0, [self prepareStringForInsert:data.damageDetail],
                        data.roomConditionsID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVODestinationRoomConditions(PVOUnloadID, "
                        "RoomID, FloorTypeID, HasDamage, DamageDetail) "
                        "VALUES(%d,%d,%d,%d,%@)",
                        data.pvoUnloadID, data.roomID, data.floorTypeID,
                        data.hasDamage ? 1 : 0, [self prepareStringForInsert:data.damageDetail]]];
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
}

-(BOOL)roomHasPVOInventoryItems:(int)roomID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE RoomID = %d", roomID]];
}

-(BOOL)pvoHasHighValueItems:(int)custID
{
    return [self getPvoHighValueItemsCount:custID] > 0;
}

-(void)removeHighValueCostForCustomerItems:(int)custID
{
    NSString *cmd = [NSString stringWithFormat:@"UPDATE PVOInventoryItems SET HighValueCost = 0 WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", custID];
    [self updateDB:cmd];
}

-(BOOL)pvoHasItemsWithDescription:(int)custID forDescription:(NSString*)desc
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:
             @"SELECT COUNT(*) FROM "
             "PVOInventoryItems i, PVOInventoryLoads ld, PVOInventoryDescriptions pid "
             "WHERE i.PVOLoadID = ld.PVOLoadID "
             "AND pid.PVOItemID = i.PVOItemID "
             "AND ld.CustomerID = %d "
             "AND pid.DescriptiveCode = %@ "
             "AND i.ItemIsDeleted = 0",
             custID, [self prepareStringForInsert:desc]]] > 0;
}

-(int)getPvoHighValueItemsCountForLoad:(int)loadID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM "
                     "PVOInventoryItems i "
                     "WHERE i.PVOLoadID = %d "
                     "AND i.HighValueCost > 0 "
                     "AND i.ItemIsDeleted = 0", loadID];
    return [self getIntValueFromQuery:cmd];
}

-(int)getPvoHighValueItemsCount:(int)custID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM "
                     "PVOInventoryItems i, PVOInventoryLoads ld "
                     "WHERE i.PVOLoadID = ld.PVOLoadID "
                     "AND ld.CustomerID = %d "
                     "AND i.HighValueCost > 0 "
                     "AND i.ItemIsDeleted = 0", custID];
    return [self getIntValueFromQuery:cmd];
}

-(int)getPvoDeliveredItemsCount:(int)custID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM "
                     "PVOInventoryItems i, PVOInventoryLoads ld "
                     "WHERE i.PVOLoadID = ld.PVOLoadID "
                     "AND ld.CustomerID = %d "
                     "AND i.ItemIsDelivered = 1 "
                     "AND i.ItemIsDeleted = 0", custID];
    return [self getIntValueFromQuery:cmd];
}

-(int)getPvoNotDeliveredItemsCount:(int)custID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:
             @"SELECT COUNT(*) FROM "
             "PVOInventoryItems i, PVOInventoryLoads ld "
             "WHERE i.PVOLoadID = ld.PVOLoadID "
             "AND ld.CustomerID = %d "
             "AND i.ItemIsDelivered = 0 "
             "AND i.ItemIsDeleted = 0",
             custID]];
}

-(NSDictionary*)getPackersInventoryInitialCounts:(int)custID
{
    NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT a.Initials, SUM(a.Quantity) FROM "
                     "(SELECT I.PackerInitials AS Initials, I.Quantity AS Quantity FROM PVOInventoryItems I "
                     "INNER JOIN PVOInventoryLoads L ON L.PVOLoadID = I.PVOLoadID "
                     "WHERE L.CustomerID = %d AND L.PVOLocationID = %d "
                     "AND I.ItemIsDeleted = 0 AND I.CartonContentID = 0) AS a "
                     "WHERE a.Initials IS NOT NULL AND LENGTH(a.Initials) > 0 "
                     "GROUP BY a.Initials ORDER BY a.Initials", custID, (int)PACKER_INVENTORY];
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if (sqlite3_column_type(stmnt, 0) != SQLITE_NULL)
                [items setObject:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 1)]
                          forKey:[[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmnt, 0)] uppercaseString]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return items;
}

-(void)savePVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType withImage:(UIImage*)image
{
    [self deletePVOHighValueInitial:pvoItemID forInitialType:pvoImageType];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullDirectory = [documentsDirectory stringByAppendingPathComponent:IMG_PVO_DIRECTORY];
    
    BOOL isDir = YES;
    NSError *error;
    if(![fileManager fileExistsAtPath:fullDirectory isDirectory:&isDir])
        [fileManager createDirectoryAtPath:fullDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString *fullPath = [fullDirectory stringByAppendingFormat:@"/%@[%d].png", IMG_PVO_FILE_NAME, 0];
    isDir = NO;
    int i = 1;
    while([fileManager fileExistsAtPath:fullPath]) {
        fullPath = [fullDirectory stringByAppendingFormat:@"/%@[%d].png", IMG_PVO_FILE_NAME, i];
        i++;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    if ([fileManager createFileAtPath:fullPath contents:data attributes:nil])
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOHighValueInitials(PVOItemID,InitialTypeID,SignatureFileName,InitialDate)"
                        " VALUES(%d,%d,%@,%f)", pvoItemID, pvoImageType,
                        [self prepareStringForInsert:
                         [fullPath stringByReplacingOccurrencesOfString:documentsDirectory withString:@""]],
                        [[NSDate date] timeIntervalSince1970]]];
    }
}

-(PVOHighValueInitial*)getPVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType
{
    PVOHighValueInitial *retval = nil;
    
    NSArray *allInitials = [self getAllPVOHighValueInitials:pvoItemID];
    for (PVOHighValueInitial *pvoinit in allInitials) {
        if(pvoinit.pvoSigTypeID == pvoImageType)
            retval = pvoinit;
    }
    
    return retval;
}

-(NSArray*)getAllPVOHighValueInitials:(int)pvoItemID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    PVOHighValueInitial *current;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOHighValueInitialsID,PVOItemID,InitialTypeID,SignatureFileName,InitialDate FROM PVOHighValueInitials "
                               "WHERE PVOItemID = %d", pvoItemID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOHighValueInitial alloc] init];
            
            current.pvoSigID = sqlite3_column_int(stmnt, 0);
            current.pvoItemID = sqlite3_column_int(stmnt, 1);
            current.pvoSigTypeID = sqlite3_column_int(stmnt, 2);
            current.fileName = [SurveyDB stringFromStatement:stmnt columnID:3];
            current.sigDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 4)];
            
            [retval addObject:current];
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)deletePVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType
{
    PVOHighValueInitial *sig = [self getPVOHighValueInitial:pvoItemID forInitialType:pvoImageType];
    
    if(sig != nil)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if([fileManager fileExistsAtPath:[sig fullFilePath] isDirectory:&isDir])
            [fileManager removeItemAtPath:[sig fullFilePath] error:nil];
        
        
    }
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOHighValueInitials WHERE PVOItemID = %d AND InitialTypeID = %d",
                    pvoItemID, pvoImageType]];
}


-(NSArray*)getPVOUnloads:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOInventoryUnload *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOUnloadID,CustomerID,PVOLocationID,LocationID "
                               "FROM PVOInventoryUnloads "
                               "WHERE CustomerID = %d", custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOInventoryUnload alloc] init];
            current.pvoLoadID = sqlite3_column_int(stmnt, 0);
            current.custID = sqlite3_column_int(stmnt, 1);
            current.pvoLocationID = sqlite3_column_int(stmnt, 2);
            current.locationID = sqlite3_column_int(stmnt, 3);
            
            current.loadIDs = [NSMutableArray array];
            sqlite3_stmt *newstmnt;
            if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOLoadID "
                                       "FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d", current.pvoLoadID]
                        withStatement:&newstmnt])
            {
                while(sqlite3_step(newstmnt) == SQLITE_ROW)
                    [current.loadIDs addObject:[NSNumber numberWithInt:sqlite3_column_int(newstmnt, 0)]];
            }
            sqlite3_finalize(newstmnt);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOInventoryUnload*)getPVOUnload:(int)pvoUnloadID
{
    PVOInventoryUnload *retval = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOUnloadID,CustomerID,PVOLocationID,LocationID "
                               "FROM PVOInventoryUnloads "
                               "WHERE PVOUnloadID = %d", pvoUnloadID]
                withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[PVOInventoryUnload alloc] init];
            retval.pvoLoadID = sqlite3_column_int(stmnt, 0);
            retval.custID = sqlite3_column_int(stmnt, 1);
            retval.pvoLocationID = sqlite3_column_int(stmnt, 2);
            retval.locationID = sqlite3_column_int(stmnt, 3);
            
            retval.loadIDs = [NSMutableArray array];
            sqlite3_stmt *newstmnt;
            if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOLoadID "
                                       "FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d", retval.pvoLoadID]
                        withStatement:&newstmnt])
            {
                while(sqlite3_step(newstmnt) == SQLITE_ROW)
                    [retval.loadIDs addObject:[NSNumber numberWithInt:sqlite3_column_int(newstmnt, 0)]];
            }
            sqlite3_finalize(newstmnt);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOInventoryUnload*)getFirstPVOUnload:(int)custID forPVOLocationID:(int)pvoLocationID
{
    int pvoUnloadID = -1;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOUnloadID FROM PVOInventoryUnloads "
                               "WHERE CustomerID = %d AND PVOLocationID = %d ORDER BY PVOLoadID LIMIT 1", custID, pvoLocationID]
                withStatement:&stmnt])
    {
        if (sqlite3_step(stmnt) == SQLITE_ROW)
            pvoUnloadID = sqlite3_column_int(stmnt, 0);
    }
    sqlite3_finalize(stmnt);
    
    if (pvoUnloadID > 0)
        return [self getPVOUnload:pvoUnloadID];
    return nil;
}

-(int)savePVOUnload:(PVOInventoryUnload*)entry
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryUnloads WHERE PVOUnloadID = %d", entry.pvoLoadID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryUnloads WHERE PVOUnloadID = %d", entry.pvoLoadID]];
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d", entry.pvoLoadID]];
    }
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryUnloads(CustomerID, PVOLocationID, LocationID) VALUES(%d,%d,%d)",
                    entry.custID, entry.pvoLocationID, entry.locationID]];
    
    int unloadID = sqlite3_last_insert_rowid(db);
    
    for (NSNumber *loadID in entry.loadIDs) {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryUnloadLoadXref(PVOUnloadID, PVOLoadID) VALUES(%d,%d)",
                        unloadID, [loadID intValue]]];
    }
    
    [self getReceivableReportNotesForCustomer:entry.custID];
    
    return unloadID;
}


-(BOOL)pvoLoadAvailableForUnload:(int)pvoLoadID
{
    if ([AppFunctionality allowAnyLoadOnAnyUnload])
        return YES;
    else
        return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryUnloadLoadXref WHERE PVOLoadID = %d", pvoLoadID]] == 0;
}

-(NSArray*)getAllPVOItemDescriptions:(int)pvoItemID withCustomerID:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    BOOL isSpecialProducts = inventory.loadType == SPECIAL_PRODUCTS;// need to remove the logic around this if/when adding special products specific rooms
    
    NSString *itemListClause = @"";
    
    if (custID > 0) {
        NSString *customClause = isSpecialProducts ? @"0" : [NSString stringWithFormat:@"(SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d)", custID];
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND d.ItemListID = %2$@", custID, customClause];
    } else {
        itemListClause = @" d.LanguageCode = 0 AND d.ItemListID = 0 ";
    }

    
    int pvoDriverType = [self getDriverData].driverType;
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDescription *current = nil;
    sqlite3_stmt *stmnt;
    
    NSString *cmd =[NSString stringWithFormat:@"SELECT d.DescriptiveCode, d.DescriptiveDescription "
                    "FROM PVODescriptions d "
                    "LEFT JOIN PVOInventoryDescriptions id ON id.DescriptiveCode = d.DescriptiveCode AND id.PVOItemID = %d "
                    "WHERE (id.PVODescriptionID IS NOT NULL OR d.Hidden != 1) " //hides hidden, unless already selected
                    " AND (id.PVODescriptionID IS NOT NULL OR d.PVODriverType = 0 OR d.PVODriverType = %d ) AND %@ " //hides based on driver type
                    "ORDER BY d.DescriptiveCode ASC", pvoItemID, pvoDriverType, itemListClause];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDescription alloc] init];
            current.descriptionCode = [SurveyDB stringFromStatement:stmnt columnID:0];
            current.description = [SurveyDB stringFromStatement:stmnt columnID:1];
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

/*
 [self updateDB:@"CREATE TABLE PVOInventoryDescriptions (PVODescriptionID INTEGER PRIMARY KEY, PVOItemID INT, "
 "DescriptiveCode TEXT)"];
 
 [self updateDB:@"CREATE TABLE PVODescriptions(DescriptiveCode TEXT, DescriptiveDescription TEXT)"];*/

-(NSArray*)getPVOReceivableItemDescriptions:(int)pvoItemID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDescription *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT id.ReceivableItemID, d.DescriptiveCode, d.DescriptiveDescription "
                               "FROM PVOReceivableDescriptions id, PVODescriptions d "
                               "WHERE id.Code = d.DescriptiveCode COLLATE NOCASE "
                               "AND id.ReceivableItemID = %d "
                               "ORDER BY id.Code ASC", pvoItemID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDescription alloc] init];
            
            current.pvoItemID = sqlite3_column_int(stmnt, 1);
            
            current.descriptionCode = [SurveyDB stringFromStatement:stmnt columnID:2];
            current.description = [SurveyDB stringFromStatement:stmnt columnID:3];
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOItemDescriptions:(int)pvoItemID withCustomerID:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    BOOL isSpecialProducts = inventory.loadType == SPECIAL_PRODUCTS;// need to remove the logic around this if/when adding special products specific rooms
    
    NSString *itemListClause = @"";
    
    if (custID > 0) {
        NSString *customClause = isSpecialProducts ? @"0" : [NSString stringWithFormat:@"(SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d)", custID];
        itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND d.ItemListID = %2$@", custID, customClause];
    } else {
        itemListClause = @" d.LanguageCode = 0 AND d.ItemListID = 0 ";
    }
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDescription *current = nil;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT id.PVODescriptionID, id.PVOItemID, d.DescriptiveCode, d.DescriptiveDescription "
                     "FROM PVOInventoryDescriptions id, PVODescriptions d "
                     "WHERE id.DescriptiveCode = d.DescriptiveCode COLLATE NOCASE "
                     "AND id.PVOItemID = %d "
                     "AND %@"
                     " ORDER BY id.DescriptiveCode ASC", pvoItemID, itemListClause];
    
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDescription alloc] init];
            
            current.pvoItemDescriptionID = sqlite3_column_int(stmnt, 0);
            current.pvoItemID = sqlite3_column_int(stmnt, 1);
            
            current.descriptionCode = [SurveyDB stringFromStatement:stmnt columnID:2];
            current.description = [SurveyDB stringFromStatement:stmnt columnID:3];
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)savePVODescriptions:(NSArray*)descriptionEntries forItem:(int)pvoItemID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryDescriptions WHERE PVOItemID = %d", pvoItemID]];
    
    for (PVOItemDescription *pid in descriptionEntries) {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryDescriptions(PVOItemID, DescriptiveCode) VALUES (%d,%@)",
                        pvoItemID, [self prepareStringForInsert: pid.descriptionCode]]];
    }
}

-(void)duplicatePVODescriptionsForQuickScan:(int)newItemID forPVOItem:(int)originalItemID
{
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryDescriptions(PVOItemID, DescriptiveCode) SELECT %d, DescriptiveCode FROM PVOInventoryDescriptions WHERE PVOItemID = %d", newItemID, originalItemID]];
}


-(NSArray*)getPVOClaims:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOClaim *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOClaimID, CustomerID, ClaimDate, "
                               "EmployerPaidFor, EmployerName, ShipmentInWarehouse, AgencyCode "
                               "FROM PVOClaims "
                               "WHERE CustomerID = %d "
                               "ORDER BY ClaimDate ASC", custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOClaim alloc] init];
            
            current.pvoClaimID = sqlite3_column_int(stmnt, 0);
            current.customerID = sqlite3_column_int(stmnt, 1);
            current.claimDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 2)];
            current.employerPaid = sqlite3_column_int(stmnt, 3) > 0;
            current.employer = [SurveyDB stringFromStatement:stmnt columnID:4];
            current.shipmentInWarehouse = sqlite3_column_int(stmnt, 5) > 0;
            current.agencyCode = [SurveyDB stringFromStatement:stmnt columnID:6];
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVOClaim:(PVOClaim*)data
{
    int retval = data.pvoClaimID;
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOClaims WHERE PVOClaimID = %d", data.pvoClaimID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOClaims SET CustomerID = %d, ClaimDate = %f, "
                        "EmployerPaidFor = %d, EmployerName = %@, ShipmentInWarehouse = %d, AgencyCode = %@"
                        " WHERE PVOClaimID = %d",
                        data.customerID, [data.claimDate timeIntervalSince1970],
                        data.employerPaid ? 1 : 0, [self prepareStringForInsert:data.employer],
                        data.shipmentInWarehouse ? 1 : 0, [self prepareStringForInsert:data.agencyCode],
                        data.pvoClaimID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOClaims(CustomerID, ClaimDate, "
                        "EmployerPaidFor, EmployerName, ShipmentInWarehouse, AgencyCode) "
                        "VALUES(%d,%f,%d,%@,%d,%@)",
                        data.customerID, [data.claimDate timeIntervalSince1970],
                        data.employerPaid ? 1 : 0, [self prepareStringForInsert:data.employer],
                        data.shipmentInWarehouse ? 1 : 0, [self prepareStringForInsert:data.agencyCode]]];
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
    
}

-(void)deletePVOClaim:(int)pvoClaimID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOClaims WHERE PVOClaimID = %d", pvoClaimID]];
}

-(void)deletePVOClaimItem:(int)pvoClaimItemID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOClaimItems WHERE PVOClaimItemID = %d", pvoClaimItemID]];
}

-(NSArray*)getPVOClaimItems:(int)pvoClaimID
{
    /*
     [self updateDB:@"CREATE TABLE PVOClaimItems (PVOClaimItemID INTEGER PRIMARY KEY, PVOClaimID INT, PVOItemID INT,"
     "Description TEXT, EstimatedWeight INT, AgeOrDatePurchased TEXT, OriginalCost REAL,"
     "ReplacementCost REAL, EstimatedRepairCost REAL)"];*/
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOClaimItem *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOClaimID, PVOItemID,"
                               "Description, EstimatedWeight, AgeOrDatePurchased, OriginalCost,"
                               "ReplacementCost, EstimatedRepairCost, PVOClaimItemID "
                               "FROM PVOClaimItems "
                               "WHERE PVOClaimID = %d ", pvoClaimID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOClaimItem alloc] init];
            
            current.pvoClaimID = sqlite3_column_int(stmnt, 0);
            current.pvoItemID = sqlite3_column_int(stmnt, 1);
            current.description = [SurveyDB stringFromStatement:stmnt columnID:2];
            current.estimatedWeight = sqlite3_column_int(stmnt, 3);
            current.ageOrDatePurchased = [SurveyDB stringFromStatement:stmnt columnID:4];
            current.originalCost = sqlite3_column_double(stmnt, 5);
            current.replacementCost = sqlite3_column_double(stmnt, 6);
            current.estimatedRepairCost = sqlite3_column_double(stmnt, 7);
            current.pvoClaimItemID = sqlite3_column_int(stmnt, 8);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVOClaimItem:(PVOClaimItem*)data
{
    int retval = data.pvoClaimItemID;
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOClaimItems WHERE PVOClaimItemID = %d", data.pvoClaimItemID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOClaimItems SET PVOClaimID = %d, PVOItemID = %d,"
                        "Description = %@, EstimatedWeight = %d, AgeOrDatePurchased = %@, OriginalCost = %f,"
                        "ReplacementCost = %f, EstimatedRepairCost = %f"
                        " WHERE PVOClaimItemID = %d",
                        data.pvoClaimID, data.pvoItemID,
                        [self prepareStringForInsert:data.description],
                        data.estimatedWeight, [self prepareStringForInsert:data.ageOrDatePurchased],
                        data.originalCost, data.replacementCost, data.estimatedRepairCost,
                        data.pvoClaimItemID]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOClaimItems(PVOClaimID, PVOItemID,"
                        "Description, EstimatedWeight, AgeOrDatePurchased, OriginalCost,"
                        "ReplacementCost, EstimatedRepairCost) "
                        "VALUES(%d,%d,%@,%d,%@,%f,%f,%f)",
                        data.pvoClaimID, data.pvoItemID,
                        [self prepareStringForInsert:data.description],
                        data.estimatedWeight, [self prepareStringForInsert:data.ageOrDatePurchased],
                        data.originalCost, data.replacementCost, data.estimatedRepairCost]];
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
    
}

-(NSArray*)getPVOWeightTickets:(int)custID
{
    /*CREATE TABLE PVOWeightTickets(WeightTicketID INTEGER PRIMARY KEY, CustomerID INT, "
     "GrossWeight INT, TicketDate REAL, Description TEXT, WeightType INT)*/
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    
    if([self prepareStatement:[NSString stringWithFormat:
                               @"SELECT WeightTicketID, GrossWeight, TicketDate, Description, WeightType "
                               "FROM PVOWeightTickets "
                               "WHERE CustomerID = %d ", custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVOWeightTicket *current = [[PVOWeightTicket alloc] init];
            
            current.custID = custID;
            current.weightTicketID = sqlite3_column_int(stmnt, 0);
            current.grossWeight = sqlite3_column_int(stmnt, 1);
            current.ticketDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmnt, 2)];
            current.description = [SurveyDB stringFromStatement:stmnt columnID:3];
            current.weightType = sqlite3_column_int(stmnt, 4);
            
            [retval addObject:current];
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)savePVOWeightTicket:(PVOWeightTicket*)weightTicket
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOWeightTickets WHERE WeightTicketID = %d", weightTicket.weightTicketID]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOWeightTickets SET GrossWeight = %d, TicketDate = %f, Description = %@, WeightType = %d"
                        " WHERE WeightTicketID = %d",
                        weightTicket.grossWeight, [weightTicket.ticketDate timeIntervalSince1970],
                        [self prepareStringForInsert:weightTicket.description], weightTicket.weightType,
                        weightTicket.weightTicketID]];
        return weightTicket.weightTicketID;
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOWeightTickets(CustomerID, GrossWeight, TicketDate, Description, WeightType) "
                        "VALUES(%d,%d,%f,%@,%d)",
                        weightTicket.custID, weightTicket.grossWeight, [weightTicket.ticketDate timeIntervalSince1970],
                        [self prepareStringForInsert:weightTicket.description], weightTicket.weightType]];
        return sqlite3_last_insert_rowid(db);
    }
}

-(void)deletePVOWeightTicket:(int)weightTicketID forCustomer:(int)custid
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOWeightTickets WHERE WeightTicketID = %d", weightTicketID]];
    
    //delete the image if it exists?
    
    NSMutableArray *arr = [self getImagesList:custid withPhotoType:IMG_PVO_WEIGHT_TICKET
                                    withSubID:weightTicketID loadAllItems:NO];
    
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];


    for (SurveyImage *image in arr)
    {
        // I am sad that I need to destroy this loop.  I want it to live forever in its infinite stupidity. ...so I'm going to leave the code here.  The below commented-out code was a part of this loop for 3-6 years.
        // Code courtesy of Justin Little and Tony Brame.
        
        // image = nil; // hack to get rid of the variable unused warning without messing with this loop (assuming that the loop works).
        // SurveyImage *image = [arr objectAtIndex:0];
        // NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        // NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = image.path;
        NSString *fullPath = [docsDir stringByAppendingPathComponent:filePath];
        
        if([fileManager fileExistsAtPath:fullPath])
            [fileManager removeItemAtPath:fullPath error:nil];
        
        
        [self deleteImageEntry:image.imageID];
    }
    
}

-(NSArray*)getPVOVerifyInventoryOrders
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    
    PVOVerifyInventoryItem *current = nil;
    
    if([self prepareStatement:@"SELECT CustomerID,OrderNumber FROM ShipmentInfo WHERE CustomerID IN(SELECT DISTINCT(CustomerID) FROM PVOVerifyInventoryItems)"
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOVerifyInventoryItem alloc] init];
            current.custID = sqlite3_column_int(stmnt, 0);
            current.orderNumber = [SurveyDB stringFromStatement:stmnt columnID:1];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)getPVOVerifyInventoryItemCount:(NSArray*)loads
{
    NSMutableString *cmd = [NSMutableString stringWithString:@"SELECT COUNT(*) FROM PVOVerifyInventoryItems WHERE CustomerID IN("];
    
    for (PVOVerifyInventoryItem *item in loads) {
        [cmd appendFormat:@"%d,", item.custID];
    }
    [cmd replaceCharactersInRange:NSMakeRange(cmd.length-1, 1) withString:@")"];
    
    return [self getIntValueFromQuery:cmd];
}

-(NSArray*)getPVOVerifyInventoryItems
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    
    PVOVerifyInventoryItem *current = nil;
    
    if([self prepareStatement:@"SELECT CustomerID,SerialNumber,ArticleName FROM PVOVerifyInventoryItems"
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOVerifyInventoryItem alloc] init];
            current.custID = sqlite3_column_int(stmnt, 0);
            current.serialNumber = [SurveyDB stringFromStatement:stmnt columnID:1];
            current.articleDescription = [SurveyDB stringFromStatement:stmnt columnID:2];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)pvoDeleteVerifyItem:(PVOVerifyInventoryItem*)item
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOVerifyInventoryItems WHERE CustomerID = %d AND SerialNumber = %@",
                    item.custID, [self prepareStringForInsert:item.serialNumber]]];
}

-(void)pvoSetDataIsDirty:(BOOL)dirty forType:(int)dataType forCustomer:(int)customerID
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOChangeTracking "
                                   "WHERE CustomerID = %d AND DataSectionID = %d", customerID, dataType]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOChangeTracking SET IsDirty = %d "
                        "WHERE CustomerID = %d AND DataSectionID = %d", dirty ? 1 : 0, customerID, dataType]];
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOChangeTracking(CustomerID, DataSectionID, IsDirty) "
                        "VALUES(%d,%d,%d)", customerID, dataType, dirty ? 1 : 0]];
    }
    
}

-(BOOL)pvoCheckDataIsDirty:(int)dataType forCustomer:(int)customerID
{
    //default to YES
    BOOL isDirty = YES;
    sqlite3_stmt *stmnt;
    
    //[self updateDB:@"CREATE TABLE PVOChangeTracking(CustomerID INT, DataSectionID INT, IsDirty INT)"];
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT IsDirty FROM PVOChangeTracking "
                               "WHERE CustomerID = %d AND DataSectionID = %d", customerID, dataType] withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            isDirty = sqlite3_column_int(stmnt, 0) > 0;
        }
    }
    sqlite3_finalize(stmnt);
    
    return isDirty;
}

//CREATE TABLE IF NOT EXISTS PVOPackerInitials(Initials TEXT)
-(NSMutableArray*)getAllPackersInitials
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:@"SELECT DISTINCT UPPER(TRIM(Initials)) FROM PVOPackerInitials WHERE Initials IS NOT NULL ORDER BY Initials" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            [retval addObject:[SurveyDB stringFromStatement:stmnt columnID:0]];
        }
    }
    sqlite3_finalize(stmnt);
    
    
    return retval;
}

-(void)savePackersInitials:(NSString*)initials
{
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOPackerInitials(Initials) VALUES(%@)", [self prepareStringForInsert:initials]]];
}

-(void)deletePackersInitials:(NSString*)initials
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOPackerInitials WHERE UPPER(TRIM(COALESCE(Initials,''))) = UPPER(TRIM(%@))", [self prepareStringForInsert:initials]]];
}

-(BOOL)packersInitialsExists:(NSString*)initials
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOPackerInitials WHERE Initials = %@", [self prepareStringForInsert:initials]]] > 0;
}

-(void)savePVOReceivableItems:(NSArray*)allItems forCustomer:(int)custID
{
    [self savePVOReceivableItems:allItems forCustomer:custID ignoreIfInventoried:FALSE];
}

-(void)savePVOReceivableItems:(NSArray*)allItems forCustomer:(int)custID ignoreIfInventoried:(BOOL)ignoreIfInventoried
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableCartonContents WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", custID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDescriptions WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", custID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDamages WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", custID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItemComments WHERE ReceivableItemID IN(SELECT ReceivableItemID FROM PVOReceivableItems WHERE CustomerID = %d)", custID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItems WHERE CustomerID = %d", custID]];
    
    for (PVOItemDetailExtended *item in allItems) {
        if (item.itemNumber == nil || item.lotNumber == nil)
            continue; //skip it, no valid barcode
        [self savePVOReceivableItem:item forCustID:custID];
        
        if (ignoreIfInventoried && [self pvoInventoryItemExists:custID withItemNumber:item.itemNumber andLotNumber:item.lotNumber andTagColor:item.tagColor])
            [self removePVOReceivableItem:item.pvoItemID]; //not being removed, hide it from being received
    }
}

-(BOOL)pvoInventoryItemExists:(int)custID withItemNumber:(NSString*)itemNumber andLotNumber:(NSString*)lotNumber andTagColor:(int)color
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE PVOLoadID IN"
                     "(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %1$d) "
                     "AND ItemNumber = '%2$@' "
                     "AND LotNumber IS NOT NULL "
                     "AND (LotNumber = '%3$@' OR SUBSTR((LotNumber || '00000000'),1,7) LIKE '%3$@') " //handles padded zero's at end
                     "AND TagColor = %4$d "
                     "AND (CartonContentID IS NULL OR CartonContentID <= 0)", //skip counting carton content items
                     custID, itemNumber, lotNumber, color];
    return ([self getIntValueFromQuery:cmd] > 0);
}

-(BOOL)pvoReceivableItemExists:(int)custID withReceivedType:(int)receivedType andItemNumber:(NSString*)itemNumber andLotNumber:(NSString*)lotNumber andTagColor:(int)color
{
    if ([self getPVOReceivedItemsType:custID] == receivedType)
        return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItems WHERE CustomerID = %1$d "
                                           "AND ItemNumber = '%2$@' "
                                           "AND LotNumber IS NOT NULL "
                                           "AND (LotNumber = '%3$@' OR SUBSTR((LotNumber || '00000000'),1,7) LIKE '%3$@') " //handles padded zero's at end
                                           "AND Color = %4$d "
                                           "AND (ReceivableCartonContentID IS NULL OR ReceivableCartonContentID <= 0)", //skip counting carton content items
                                           custID, itemNumber, lotNumber, color]];
    return NO;
}

-(void)removePVOReceivableItem:(int)receivableItemID
{
    //no longer deleted, per defect 291
    /*[self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableCartonContents WHERE ReceivableItemID = %d", receivableItemID]];
     [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDescriptions WHERE ReceivableItemID = %d", receivableItemID]];
     [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableDamages WHERE ReceivableItemID = %d", receivableItemID]];
     [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableItems WHERE ReceivableItemID = %d", receivableItemID]];*/
    
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOReceivableItems SET Received = 1 WHERE ReceivableItemID = %d", receivableItemID]];
}

-(void)savePVOReceivableItem:(PVOItemDetailExtended*)item forCustID:(int)custID
{
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableItems(CustomerID, ItemID, RoomID,"
                    " Quantity, ItemNumber, LotNumber, Color, ModelNumber, SerialNumber, HighValueCost,"
                    " PackerInitials, Received, ItemIsDeleted, VoidReason, Delivered, Length, Width, Height,"
                    " HasDimensions, ReceivableCartonContentID, ItemIsMPRO,ItemIsSPRO,ItemIsCONS,[Year],Make,Odometer,CaliberOrGauge,WeightType,Weight,Cube,SecuritySealNumber)"
                    " VALUES (%d,%d,%d,%d,%@,%@,%d,%@,%@,%f,%@,%d,%d,%@,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%@,%d,%@,%d,%d,%f,%@)",
                    custID, item.itemID, item.roomID, item.quantity,
                    [self prepareStringForInsert:item.itemNumber],
                    [self prepareStringForInsert:item.lotNumber],
                    item.tagColor,
                    [self prepareStringForInsert:item.modelNumber],
                    [self prepareStringForInsert:item.serialNumber],
                    item.highValueCost,
                    [self prepareStringForInsert:item.packerInitials],
                    0,
                    (item.itemIsDeleted ? 1 : 0),
                    [self prepareStringForInsert:item.voidReason supportsNull:YES],
                    (item.itemIsDelivered ? 1 : 0),
                    item.length, item.width, item.height,
                    (item.hasDimensions ? 1 : 0),
                    item.cartonContentID,
                    (item.itemIsMPRO ? 1 : 0),
                    (item.itemIsSPRO ? 1 : 0),
                    (item.itemIsCONS ? 1 : 0),
                    item.year,
                    [self prepareStringForInsert:item.make supportsNull:YES],
                    item.odometer,
                    [self prepareStringForInsert:item.caliberGauge supportsNull:YES],
                    item.weightType,
                    item.weight,
                    item.cube,
                    [self prepareStringForInsert:item.securitySealNumber supportsNull:YES]]];
    
    item.pvoItemID = sqlite3_last_insert_rowid(db);
    
    //write carton contents.
    if(item.cartonContentID <= 0 && item.cartonContentsDetail != nil && item.cartonContentsDetail.count > 0)
    {
        //old logic.  shouldn't process anymore.
        //        for (NSNumber *contentID in item.cartonContentsDetail) {
        //            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableCartonContents(ReceivableItemID, ContentID) VALUES(%d,%d)",
        //                            item.pvoItemID, [contentID intValue]]];
        //        }
        for (PVOItemDetailExtended *cartonContent in item.cartonContentsDetail) {
            //new logic, detailed carton contents
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableCartonContents(ReceivableItemID, ContentID) VALUES(%d,%d)",
                            item.pvoItemID, cartonContent.cartonContentID]];
            cartonContent.cartonContentID = sqlite3_last_insert_rowid(db);
            [self savePVOReceivableItem:cartonContent forCustID:custID]; //save detail
        }
    }
    
    //write descriptive symbols
    if(item.descriptiveSymbols != nil && item.descriptiveSymbols.count > 0)
    {
        for (PVOItemDescription *desc in item.descriptiveSymbols) {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableDescriptions(ReceivableItemID, Code, Description) VALUES(%d,%@,%@)",
                            item.pvoItemID,
                            [self prepareStringForInsert:desc.descriptionCode],
                            [self prepareStringForInsert:desc.description]]];
        }
    }
    
    //write damages
    if(item.damageDetails != nil && item.damageDetails.count > 0)
    {
        for (PVOConditionEntry *condy in item.damageDetails) {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableDamages(ReceivableItemID, Damages, Locations, DamageType) VALUES(%d,%@,%@,%d)",
                            item.pvoItemID,
                            [self prepareStringForInsert:condy.conditions],
                            [self prepareStringForInsert:condy.locations],
                            (int)condy.damageType]];
        }
    }
    
    //write comments
    if(item.itemCommentDetails != nil && item.itemCommentDetails.count > 0)
    {
        for (PVOItemComment *comment in item.itemCommentDetails) {
            if ([comment.comment length] > 0)
                [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableItemComments(ReceivableItemID, Comments, CommentType) VALUES(%d,%@,%d)",
                                item.pvoItemID,
                                [self prepareStringForInsert:comment.comment],
                                comment.commentType]];
        }
    }
}

-(BOOL)hasPVOReceivableItems:(int)custID receivedType:(int)receivedType ignoreReceived:(BOOL)ignoreReceived
{
    if ([self getPVOReceivedItemsType:custID] == receivedType)
        return ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItems WHERE CustomerID = %d"
                                            " AND COALESCE(ReceivableCartonContentID,0) = 0 %@",
                                            custID, (ignoreReceived ? @"" : @"AND Received = 0")]] > 0);
    else
        return FALSE;
}

-(NSMutableArray*)getPVOReceivableRooms:(int)custID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVORoomSummary *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(i.RoomID) FROM PVOReceivableItems i "
                               "LEFT OUTER JOIN Rooms r ON r.RoomID = i.RoomID "
                               "WHERE i.CustomerID = %d "
                               "AND COALESCE(ReceivableCartonContentID,0) = 0 "
                               "ORDER BY r.RoomName COLLATE NOCASE", custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVORoomSummary alloc] init];
            current.room = [self getRoom:sqlite3_column_int(stmnt, 0)];
            current.numberOfItems = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItems WHERE CustomerID = %d"
                                                                " AND COALESCE(ReceivableCartonContentID,0) = 0"
                                                                " AND RoomID = %d", custID, current.room.roomID]];
            
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSMutableArray*)getPVOReceivableItems:(int)custID
{
    return [self getPVOReceivableItems:custID ignoreReceived:FALSE forRoom:-1 isVoided:-1];
}

-(NSMutableArray*)getPVOReceivableItems:(int)custID ignoreReceived:(BOOL)ignoreReceived forRoom:(int)roomID
{
    return [self getPVOReceivableItems:custID ignoreReceived:ignoreReceived forRoom:roomID isVoided:-1];
}

-(NSMutableArray*)getPVOReceivableItems:(int)custID ignoreReceived:(BOOL)ignoreReceived forRoom:(int)roomID isVoided:(int)voided
{
    NSMutableArray *itemIDs = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReceivableItemID "
                               "FROM PVOReceivableItems WHERE CustomerID = %d "
                               "AND COALESCE(ReceivableCartonContentID,0) = 0 " //exclude detailed carton contents
                               "%@ %@ %@ "
                               "ORDER BY LotNumber, ItemNumber",
                               custID,
                               (ignoreReceived ? @"" : @"AND Received = 0"),
                               (roomID > 0 ? [NSString stringWithFormat:@"AND RoomID = %d", roomID] : @""),
                               (voided >= 0 ? [NSString stringWithFormat:@"AND ItemIsDeleted = %d", voided] : @"")]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            [itemIDs addObject:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
    }
    sqlite3_finalize(stmnt);
    
    NSMutableArray *retval = [[NSMutableArray alloc] initWithCapacity:[itemIDs count]];
    for (NSNumber *itemID in itemIDs) {
        [retval addObject:[self getPVOReceivableItem:[itemID intValue]]];
        
    }
    return retval;
}

-(PVOItemDetailExtended*)getPVOReceivableItem:(int)receivableItemID
{
    sqlite3_stmt *stmnt;
    
    PVOItemDetailExtended *item;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReceivableItemID, ItemID, RoomID, "
                               "Quantity, ItemNumber, LotNumber, Color, "
                               "ModelNumber, SerialNumber, HighValueCost, PackerInitials, Received, "
                               "ItemIsDeleted, VoidReason, Delivered, Length, Width, Height, HasDimensions, "
                               "COALESCE(ReceivableCartonContentID,0), ItemIsMPRO, ItemIsSPRO, ItemIsCONS,[Year],Make, "
                               "Odometer, CaliberOrGauge, Weight, WeightType, Cube,SecuritySealNumber "
                               "FROM PVOReceivableItems WHERE ReceivableItemID = %d ", receivableItemID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int idx = 0;
            item = [[PVOItemDetailExtended alloc] init];
            item.pvoItemID = sqlite3_column_int(stmnt, idx);
            item.itemID = sqlite3_column_int(stmnt, ++idx);
            item.roomID = sqlite3_column_int(stmnt, ++idx);
            item.quantity = sqlite3_column_int(stmnt, ++idx);
            item.itemNumber = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.lotNumber = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.tagColor = sqlite3_column_int(stmnt, ++idx);
            item.modelNumber = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.serialNumber = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.highValueCost = sqlite3_column_double(stmnt, ++idx);
            item.packerInitials = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.received = (sqlite3_column_int(stmnt,++idx) > 0);
            item.itemIsDeleted = (sqlite3_column_int(stmnt, ++idx) > 0);
            item.voidReason = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.itemIsDelivered = (sqlite3_column_int(stmnt, ++idx) > 0);
            item.length = sqlite3_column_int(stmnt, ++idx);
            item.width = sqlite3_column_int(stmnt, ++idx);
            item.height = sqlite3_column_int(stmnt, ++idx);
            item.hasDimensions = (sqlite3_column_int(stmnt, ++idx) > 0);
            item.cartonContentID = sqlite3_column_int(stmnt, ++idx);
            item.itemIsMPRO = (sqlite3_column_int(stmnt, ++idx) > 0);
            item.itemIsSPRO = (sqlite3_column_int(stmnt, ++idx) > 0);
            item.itemIsCONS = (sqlite3_column_int(stmnt, ++idx) > 0);
            if (sqlite3_column_type(stmnt, ++idx) != SQLITE_NULL)
                item.year = sqlite3_column_int(stmnt, idx);
            item.make = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            if (sqlite3_column_int(stmnt, ++idx) != SQLITE_NULL)
                item.odometer = sqlite3_column_int(stmnt, idx);
            item.caliberGauge = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.weight = sqlite3_column_int(stmnt, ++idx);
            item.weightType = sqlite3_column_int(stmnt, ++idx);
            item.cube = sqlite3_column_double(stmnt, ++idx);
            item.securitySealNumber = [SurveyDB stringFromStatement:stmnt columnID:++idx];
            item.doneWorking = YES; //always flag it as done
        }
    }
    sqlite3_finalize(stmnt);
    
    //populate the remaining items
    item.descriptiveSymbols = [NSMutableArray array];
    item.damageDetails = [NSMutableArray array];
    item.itemCommentDetails = [NSMutableArray array];
    
    //get contents
    if (item.cartonContentID == 0)
    {
        item.cartonContentsDetail = [NSMutableArray array];
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReceivableCartonContentID, ContentID FROM PVOReceivableCartonContents WHERE ReceivableItemID = %d",
                                   item.pvoItemID] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                int receivableItemID = [self getIntValueFromQuery:
                                        [NSString stringWithFormat:@"SELECT ReceivableItemID FROM PVOReceivableItems WHERE ReceivableCartonContentID = %d",
                                         sqlite3_column_int(stmnt, 0)]];
                if (receivableItemID > 0)
                {
                    PVOItemDetailExtended *ccItem = [self getPVOReceivableItem:receivableItemID];
                    ccItem.cartonContentID = sqlite3_column_int(stmnt, 1);
                    [item.cartonContentsDetail addObject:ccItem];
                }
                else
                {
                    [item.cartonContentsDetail addObject:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 1)]];
                }
            }
        }
        sqlite3_finalize(stmnt);
        
        item.cartonContents = (item.cartonContentsDetail != nil && [item.cartonContentsDetail count] > 0);
    }
    
    //descriptive
    PVOItemDescription *desc;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT Code, Description FROM PVOReceivableDescriptions WHERE ReceivableItemID = %d", item.pvoItemID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            desc = [[PVOItemDescription alloc] init];
            desc.descriptionCode = [SurveyDB stringFromStatement:stmnt columnID:0];
            desc.description = [SurveyDB stringFromStatement:stmnt columnID:1];
            [item.descriptiveSymbols addObject:desc];
        }
    }
    sqlite3_finalize(stmnt);
    
    //damages
    PVOConditionEntry *condy;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT Damages, Locations, DamageType FROM PVOReceivableDamages WHERE ReceivableItemID = %d", item.pvoItemID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            condy = [[PVOConditionEntry alloc] init];
            condy.conditions = [SurveyDB stringFromStatement:stmnt columnID:0];
            condy.locations = [SurveyDB stringFromStatement:stmnt columnID:1];
            condy.damageType = sqlite3_column_int(stmnt, 2);
            [item.damageDetails addObject:condy];
        }
    }
    sqlite3_finalize(stmnt);
    
    //comments
    PVOItemComment *comment;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT Comments, CommentType FROM PVOReceivableItemComments WHERE ReceivableItemID = %d", item.pvoItemID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            comment = [[PVOItemComment alloc] init];
            comment.comment = [SurveyDB stringFromStatement:stmnt columnID:0];
            comment.commentType = sqlite3_column_int(stmnt, 1);
            [item.itemCommentDetails addObject:comment];
        }
    }
    sqlite3_finalize(stmnt);
    
    return item;
}

//[self updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableItemsType(CustomerID INT, ReceivedType INT)"];
-(int)getPVOReceivedItemsType:(int)custID
{
    if ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]] > 0)
        return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT ReceivedType FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]];
    else
        return 0;
}

-(void)setPVOReceivedItemsType:(int)receiveType forCustomer:(int)custID
{
    if ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]] > 0)
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOReceivableItemsType SET ReceivedType = %d WHERE CustomerID = %d",
                        receiveType, custID]];
    else
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableItemsType(CustomerID, ReceivedType, ReceivedUnloadType) VALUES(%d,%d,%d)",
                        custID, receiveType, 0]];
}

-(int)getPVOReceivedItemsUnloadType:(int)custID
{
    if ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]] > 0)
        return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT ReceivedUnloadType FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]];
    else
        return 0;
}

-(void)setPVOReceivedItemsUnloadType:(int)receiveUnloadType forCustomer:(int)custID
{
    if ([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReceivableItemsType WHERE CustomerID = %d", custID]] > 0)
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOReceivableItemsType SET ReceivedUnloadType = %d WHERE CustomerID = %d",
                        receiveUnloadType, custID]];
    else
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableItemsType(CustomerID, ReceivedType, ReceivedUnloadType) VALUES(%d,%d,%d)",
                        custID, 0, receiveUnloadType]];
}

-(NSArray*)getDeliveredPVOItems:(int)pvoUnloadID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN (SELECT PVOLoadID FROM PVOInventoryUnloadLoadXref WHERE PVOUnloadID = %d) "
                               "AND ItemIsDelivered = 1 AND ItemIsDeleted = 0 ORDER BY LotNumber ASC, ItemNumber ASC",
                               [self getPVOItemDetailSelectString],
                               pvoUnloadID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            [retval addObject:current];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)pvoLocationLimitItems:(int)pvoLocationID
{
    return ([self getIntValueFromQuery:
             [NSString stringWithFormat:@"SELECT LimitItems FROM PVOLocations WHERE LocationID = %d", pvoLocationID]] > 0);
}

-(PVOReportNote*)getReportNotes:(int)custID forType:(int)reportNoteType
{
    PVOReportNote *current = nil;
    sqlite3_stmt *stmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOReportNotesID,ReportNoteType,Notes FROM PVOReportNotes WHERE CustomerID = %d AND ReportNoteType = %d LIMIT 1", custID, reportNoteType]
                 withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
            current = [[PVOReportNote alloc] initWithStatement:stmnt];
    }
    sqlite3_finalize(stmnt);
    
    return current;
}

-(void)saveReportNotes:(PVOReportNote*)rptNote forCustomer:(int)custID
{
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReportNotes WHERE CustomerID = %d AND ReportNoteType = %d", custID, rptNote.pvoReportNoteTypeID]] > 0)
    {//update
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOReportNotes SET Notes = %@ WHERE CustomerID = %d AND ReportNoteType = %d",
                        [self prepareStringForInsert:rptNote.reportNote supportsNull:NO], custID, rptNote.pvoReportNoteTypeID]];
    }
    else
    {//insert new
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReportNotes(CustomerID,ReportNoteType,Notes)VALUES(%d,%d,%@)",
                        custID, rptNote.pvoReportNoteTypeID, [self prepareStringForInsert:rptNote.reportNote supportsNull:NO]]];
    }
    
}

-(NSArray*)getAllReportNotes:(int)custID
{
    NSMutableArray *reportNotes = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT PVOReportNotesID,ReportNoteType,Notes FROM PVOReportNotes WHERE CustomerID = %d ORDER BY ReportNoteType", custID]
                 withStatement:&stmnt])
    {
        while (sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVOReportNote *note = [[PVOReportNote alloc] initWithStatement:stmnt];
            
            if (note.reportNote != nil)
                [reportNotes addObject:note];
        }
    }
    sqlite3_finalize(stmnt);
    
    return reportNotes;
}

-(void)saveReceivableReportNotes:(NSArray*)reportNotes forCustomer:(int)custID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOReceivableReportNotes WHERE CustomerID = %d", custID]];
    
    for (PVOReportNote* rptNote in reportNotes)
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReceivableReportNotes(CustomerID,ReportNoteType,Notes)VALUES(%d,%d,%@)",
                        custID, rptNote.pvoReportNoteTypeID,[self prepareStringForInsert:rptNote.reportNote supportsNull:YES]]];
    }
}

-(void)getReceivableReportNotesForCustomer:(int)custID
{
    NSMutableString *cmd = [NSMutableString stringWithFormat:@"INSERT INTO PVOReportNotes(CustomerID,ReportNoteType,Notes)"
                            "SELECT a.CustomerID,a.ReportNoteType,a.Notes FROM PVOReceivableReportNotes a WHERE a.CustomerID = %d",
                            custID];
    
    
    [self updateDB:cmd];
}

#pragma mark - Military methods

-(int)getPVOItemCountMpro:(int)customerID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE ItemIsMPRO = 1 AND PVOLoadID IN"
             "(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", customerID]];
}

-(int)getPVOItemCountSpro:(int)customerID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE ItemIsSPRO = 1 AND PVOLoadID IN"
             "(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", customerID]];
}

-(int)getPVOItemCountCons:(int)customerID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE ItemIsCONS = 1 AND PVOLoadID IN"
             "(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", customerID]];
}

-(int)getPVOItemCountNonMproSpro:(int)customerID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItems WHERE ItemIsMPRO = 0 AND ItemIsSPRO = 0 AND ItemIsCONS = 0 AND PVOLoadID IN"
             "(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d)", customerID]];
}

-(BOOL)autoCalculateInventoryMilitaryWeights:(int)custID
{
    PVOInventory *data = [self getPVOData:custID];
    data.mproWeight = [self getPVOItemWeightMpro:custID];
    data.sproWeight = [self getPVOItemWeightSpro:custID];
    data.consWeight = [self getPVOItemWeightCons:custID];
    
    [self updatePVOData:data];
    
    return true;
}

-(int)getPVOItemWeightMpro:(int)custID
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    int total = 0;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) AND ItemIsMPRO = 1 AND ItemIsDeleted = 0",
                               [self getPVOItemDetailSelectString],
                               custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            total += current.weight * current.quantity;
        }
    }
    sqlite3_finalize(stmnt);
    
    return total;
}

-(int)getPVOItemWeightSpro:(int)custID
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    int total = 0;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) AND ItemIsSPRO = 1 AND ItemIsDeleted = 0",
                               [self getPVOItemDetailSelectString],
                               custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            total += current.weight * current.quantity;
        }
    }
    sqlite3_finalize(stmnt);
    
    return total;
}

-(int)getPVOItemWeightCons:(int)custID
{
    PVOItemDetail *current = nil;
    sqlite3_stmt *stmnt;
    int total = 0;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT %@ WHERE PVOLoadID IN(SELECT PVOLoadID FROM PVOInventoryLoads WHERE CustomerID = %d) AND ItemIsCons = 1 AND ItemIsDeleted = 0",
                               [self getPVOItemDetailSelectString],
                               custID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOItemDetail alloc] initWithStatement:stmnt];
            total += current.weight * current.quantity;
        }
    }
    sqlite3_finalize(stmnt);
    
    return total;
}

#pragma mark - auto backup


-(void)saveNewBackup:(BackupRecord*)data
{
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate, BackupFolder) "
                    "VALUES(%f,'%@')", [data.backupDate timeIntervalSince1970], data.backupFolder]];
}

-(void)deleteBackup:(BackupRecord*)data
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM Backups WHERE BackupID = %d", data.backupID]];
    
    //delete folder...
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
    
    NSError *err;
    
    NSString *fullDir = [backupDir stringByAppendingPathComponent:data.backupFolder];
    [mgr removeItemAtPath:fullDir error:&err];
}

-(NSArray*)getAllBackups
{
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT BackupID, BackupDate, BackupFolder FROM Backups ORDER BY BackupDate DESC" withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            BackupRecord *item = [[BackupRecord alloc] init];
            item.backupID = sqlite3_column_int(stmnt, 0);
            item.backupDate = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 1)];
            item.backupFolder = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
            [retval addObject:item];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(AutoBackupSchedule*)getBackupSchedule
{
    AutoBackupSchedule *retval = [[AutoBackupSchedule alloc] init];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:@"SELECT LastBackup, BackupFrequency, NumBackupsToRetain,EnableBackup,IncludeImages FROM AutoBackupSchedule" withStatement:&stmnt])
    {//LastBackup, BackupFrequency, NumBackupsToRetain
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval.lastBackup = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 0)];
            retval.backupFrequency = sqlite3_column_double(stmnt, 1);
            retval.numBackupsToRetain = sqlite3_column_int(stmnt, 2);
            retval.enableBackup = sqlite3_column_int(stmnt, 3) > 0;
            retval.includeImages = sqlite3_column_int(stmnt, 4) > 0;
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)saveBackupSchedule:(AutoBackupSchedule*)sched
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE AutoBackupSchedule SET LastBackup = %f, BackupFrequency = %f, NumBackupsToRetain = %d, EnableBackup = %d, IncludeImages = %d ",
                    [sched.lastBackup timeIntervalSince1970], sched.backupFrequency, sched.numBackupsToRetain,
                    sched.enableBackup ? 1 : 0, sched.includeImages ? 1 : 0]];
}

#pragma mark - Doc Library entries

-(NSArray*)getGlobalDocs:(int)vanlineID
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        
        DocLibraryEntry *current;
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT DocEntryID, DocEntryType, CustomerID, "
                                   "DocURL, DocName, DocPath, SavedDate, Synchronized "
                                   "FROM DocumentLibrary WHERE DocEntryType = %d AND VanlineID IN (-1, %d) ORDER BY DocName ASC", DOC_LIB_TYPE_GLOBAL, vanlineID] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[DocLibraryEntry alloc] init];
                
                current.docEntryID = sqlite3_column_int(stmnt, 0);
                current.docEntryType = sqlite3_column_int(stmnt, 1);
                current.customerID = sqlite3_column_int(stmnt, 2);
                current.url = [SurveyDB stringFromStatement:stmnt columnID:3];
                current.docName = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 4)];
                current.docPath = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 5)];
                current.savedDate = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 6)];
                current.synchronized = sqlite3_column_int(stmnt, 7) > 0;
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(NSArray*)getGlobalDocs
{
    [self getGlobalDocs:-1];
}

- (NSArray*)getCustomerDocs:(int)customerID
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        
        DocLibraryEntry *current;
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT DocEntryID, DocEntryType, CustomerID, "
                                   "DocURL, DocName, DocPath, SavedDate, Synchronized "
                                   "FROM DocumentLibrary WHERE DocEntryType = %d AND CustomerID = %d ORDER BY DocEntryID DESC",
                                   DOC_LIB_TYPE_CUST, customerID] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[DocLibraryEntry alloc] init];
                
                current.docEntryID = sqlite3_column_int(stmnt, 0);
                current.docEntryType = sqlite3_column_int(stmnt, 1);
                current.customerID = sqlite3_column_int(stmnt, 2);
                current.url = [SurveyDB stringFromStatement:stmnt columnID:3];
                current.docName = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 4)];
                current.docPath = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 5)];
                current.savedDate = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 6)];
                current.synchronized = sqlite3_column_int(stmnt, 7) > 0;
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(void)deleteDocLibraryEntry:(DocLibraryEntry*)data
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM DocumentLibrary WHERE DocEntryID = %d", data.docEntryID]];
    
    //delete the file...
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSError *err;
    [mgr removeItemAtPath:[data fullDocPath] error:&err];
    
}

-(int)saveDocLibraryEntry:(DocLibraryEntry*)data withVanline:(int)vanlineID
{
    int retval = -1;
    
    if([self getIntValueFromQuery:
        [NSString stringWithFormat:@"SELECT COUNT(*) FROM DocumentLibrary WHERE DocEntryID = %d", data.docEntryID]] > 0)
    {//update
        [self updateDB:[NSString stringWithFormat:@"UPDATE DocumentLibrary SET DocEntryType = %d, CustomerID = %d, "
                        "DocURL = %@, DocName = '%@', DocPath = '%@', SavedDate = %f, Synchronized = %d, VanlineID = %d WHERE DocEntryID = %d",
                        data.docEntryType, data.customerID,
                        [self prepareStringForInsert:data.url supportsNull:YES],
                        [data.docName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [data.docPath stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [data.savedDate timeIntervalSince1970],
                        data.synchronized ? 1 : 0,
                        vanlineID,
                        data.docEntryID]];
        retval = data.docEntryID;
    }
    else
    {//insert
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO DocumentLibrary(DocEntryType, CustomerID, "
                        "DocURL, DocName, DocPath, SavedDate, Synchronized, VanlineID) VALUES(%d,%d,%@,'%@','%@',%f,%d,%d)",
                        data.docEntryType, data.customerID,
                        [self prepareStringForInsert:data.url supportsNull:YES],
                        [data.docName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [data.docPath stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [data.savedDate timeIntervalSince1970],
                        data.synchronized ? 1 : 0,
                        vanlineID]];
        retval = sqlite3_last_insert_rowid(db);
    }
    
    return retval;
}

-(int)saveDocLibraryEntry:(DocLibraryEntry*)data
{
    [self saveDocLibraryEntry:data withVanline:-1];
}

/*
 -(int)saveDocLibraryEntry:(DocLibraryEntry*)data
 {
 int retval = -1;
 
 if([self getIntValueFromQuery:
 [NSString stringWithFormat:@"SELECT COUNT(*) FROM DocumentLibrary WHERE DocEntryID = %d", data.docEntryID]] > 0)
 {//update
 [self updateDB:[NSString stringWithFormat:@"UPDATE DocumentLibrary SET DocEntryType = %d, CustomerID = %d, "
 "DocURL = %@, DocName = '%@', DocPath = '%@', SavedDate = %f, Synchronized = %d WHERE DocEntryID = %d",
 data.docEntryType, data.customerID,
 [self prepareStringForInsert:data.url supportsNull:YES],
 [data.docName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
 [data.docPath stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
 [data.savedDate timeIntervalSince1970],
 data.synchronized ? 1 : 0,
 data.docEntryID]];
 retval = data.docEntryID;
 }
 else
 {//insert
 [self updateDB:[NSString stringWithFormat:@"INSERT INTO DocumentLibrary(DocEntryType, CustomerID, "
 "DocURL, DocName, DocPath, SavedDate, Synchronized) VALUES(%d,%d,%@,'%@','%@',%f,%d)",
 data.docEntryType, data.customerID,
 [self prepareStringForInsert:data.url supportsNull:YES],
 [data.docName stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
 [data.docPath stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
 [data.savedDate timeIntervalSince1970],
 data.synchronized ? 1 : 0]];
 retval = sqlite3_last_insert_rowid(db);
 }
 
 return retval;
 }
 */

#pragma mark - html reports

-(BOOL)htmlReportIsCurrent:(ReportOption*)reportOption
{
    int localRevision = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT HTMLRevision FROM HTMLReports WHERE ReportTypeID = %d", reportOption.reportTypeID]];
    
    return localRevision == reportOption.htmlRevision;
}

-(BOOL)htmlReportSupportsImages:(int)reportTypeID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT HTMLSupportsImages FROM HTMLReports WHERE ReportTypeID = %d", reportTypeID]] > 0;
}

-(BOOL)htmlReportExistsForReportType:(int)reportTypeID
{
    ReportOption *option = [self getHTMLReportDataForReportType:reportTypeID];
    if (option == nil) return NO;
    
    return [self htmlReportExists:option];
}

-(BOOL)htmlReportExists:(ReportOption*)reportOption
{
    if (reportOption == nil) return NO;
    
    //if the downloader is checking if the file exists, it'll pass in the entire download url in the report.option.htmlBUndlelocaiton
    NSString *htmlBundleLocation = [reportOption.htmlBundleLocation lastPathComponent];
    
    //htmlBundleLocation is now only the zip name, build the location and append the string
    NSString *reportBundlePath = [SurveyAppDelegate getDocsDirectory];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:HTML_FILES_LOCATION];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", reportOption.reportTypeID]];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:htmlBundleLocation];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    if([mgr fileExistsAtPath:reportBundlePath])
        return YES;
    
    return NO;
}


-(void)saveHTMLReport:(ReportOption*)htmlReport
{
    /*HTMLReports(ReportID INT, HTMLRevision INT, HTMLBundleLocation TEXT, "
     "HTMLTargetFile TEXT)*/
    /*
     At this point the full URL of the html bundle on the server is stored in the HTMLBundleLocation property for the download, then it will be shortened down to just the zip bundle name
     */
    
    //only table the zip bundle name, the full location is built dynamically
    htmlReport.htmlBundleLocation = [htmlReport.htmlBundleLocation lastPathComponent];
    
    if([self getIntValueFromQuery:
        [NSString stringWithFormat:@"SELECT COUNT(*) FROM HTMLReports WHERE ReportTypeID = %d", htmlReport.reportTypeID]] > 0)
    {//update
        [self updateDB:[NSString stringWithFormat:@"UPDATE HTMLReports SET ReportID = %d, HTMLRevision = %d, HTMLBundleLocation = '%@', "
                        "HTMLTargetFile = '%@', ReportTypeID = %d, HTMLSupportsImages = %d, PageSize = %d WHERE ReportTypeID = %d",
                        htmlReport.reportID,
                        htmlReport.htmlRevision,
                        [htmlReport.htmlBundleLocation stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [htmlReport.htmlTargetFile stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        htmlReport.reportTypeID,
                        htmlReport.htmlSupportsImages ? 1 : 0,
                        htmlReport.pageSize,
                        htmlReport.reportTypeID]];
    }
    else
    {//insert
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO HTMLReports(ReportID, HTMLRevision, HTMLBundleLocation, "
                        "HTMLTargetFile, ReportTypeID, HTMLSupportsImages, PageSize) VALUES(%d,%d,'%@','%@',%d,%d,%d)",
                        htmlReport.reportID,
                        htmlReport.htmlRevision,
                        [htmlReport.htmlBundleLocation stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        [htmlReport.htmlTargetFile stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        htmlReport.reportTypeID,
                        htmlReport.htmlSupportsImages ? 1 : 0,
                        htmlReport.pageSize]];
    }
}

//- (ReportOption*)getHTMLReportData:(int)reportID
//{
//    @synchronized(self)
//    {
//        ReportOption *retval = nil;
//
//        sqlite3_stmt *stmnt;
//        if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReportID, HTMLRevision, HTMLBundleLocation, "
//                                   "HTMLTargetFile, ReportTypeID, HTMLSupportsImages "
//                                   "FROM HTMLReports WHERE ReportID = %d",
//                                   reportID] withStatement:&stmnt])
//        {
//            while(sqlite3_step(stmnt) == SQLITE_ROW)
//            {
//                retval = [[ReportOption alloc] init];
//
//                retval.htmlSupported = YES;
//
//                retval.reportID = sqlite3_column_int(stmnt, 0);
//                retval.htmlRevision = sqlite3_column_int(stmnt, 1);
//                retval.htmlBundleLocation = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
//                retval.htmlTargetFile = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 3)];
//                retval.reportTypeID = sqlite3_column_int(stmnt, 4);
//                retval.htmlSupportsImages = sqlite3_column_int(stmnt, 5) > 0;
//
//            }
//        }
//        sqlite3_finalize(stmnt);
//
//        return retval;
//    }
//}

- (ReportOption*)getHTMLReportDataForReportType:(int)reportTypeID
{
    @synchronized(self)
    {
        ReportOption *retval = nil;
        
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReportID, HTMLRevision, HTMLBundleLocation, "
                                   "HTMLTargetFile, ReportTypeID, HTMLSupportsImages, PageSize "
                                   "FROM HTMLReports WHERE ReportTypeID = %d",
                                   reportTypeID] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                retval = [[ReportOption alloc] init];
                
                retval.htmlSupported = YES;
                
                retval.reportID = sqlite3_column_int(stmnt, 0);
                retval.htmlRevision = sqlite3_column_int(stmnt, 1);
                retval.htmlBundleLocation = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 2)];
                retval.htmlTargetFile = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 3)];
                retval.reportTypeID = sqlite3_column_int(stmnt, 4);
                retval.htmlSupportsImages = sqlite3_column_int(stmnt, 5) > 0;
                retval.pageSize = sqlite3_column_int(stmnt, 6);
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(BOOL)updateHTMLReportBundleLocations
{
    //we only want the zip file name in the bundle location because the location changes every time the app is launched, we were previously holding the entire absolutely path, which caused issues when the app is launched
    @synchronized(self)
    {
        ReportOption *retval = nil;
        
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT ReportID, HTMLBundleLocation FROM HTMLReports"] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                retval = [[ReportOption alloc] init];
                
                retval.reportID = sqlite3_column_int(stmnt, 0);
                retval.htmlBundleLocation = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmnt, 1)];
                
                [self updateDB:[NSString stringWithFormat:@"UPDATE HTMLReports SET HTMLBundleLocation = %@ WHERE ReportID = %d", [self prepareStringForInsert:[retval.htmlBundleLocation lastPathComponent]], retval.reportID]];
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return YES;
    }
    
}

#pragma mark - PVO Data Entries

- (BOOL)pvoDynamicReportDataExists:(int)customerID forReport:(int)reportTypeID
{
    return [self getIntValueFromQuery:[NSString stringWithFormat:
                                       @"SELECT COUNT(*) FROM PVODynamicReportData WHERE CustomerID = %d AND ReportID = %d", customerID, reportTypeID]] > 0;
}

- (NSMutableArray*)getPVODynamicReportData:(int)customerID
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        
        PVODynamicReportData *current;
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT CustomerID, ReportID, DataEntryID,"
                                   " DataSectionID, TextValue, IntValue, DoubleValue, DateTimeValue "
                                   "FROM PVODynamicReportData WHERE CustomerID = %d ORDER BY ReportID ASC",
                                   customerID] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[PVODynamicReportData alloc] init];
                
                current.custID = sqlite3_column_int(stmnt, 0);
                current.reportID = sqlite3_column_int(stmnt, 1);
                current.dataEntryID = sqlite3_column_int(stmnt, 2);
                current.dataSectionID = sqlite3_column_int(stmnt, 3);
                current.textValue = [SurveyDB stringFromStatement:stmnt columnID:4];
                current.intValue = sqlite3_column_int(stmnt, 5);
                current.doubleValue = sqlite3_column_double(stmnt, 6);
                current.dateValue = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 7)];
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

- (NSMutableArray*)getPVODynamicReportData:(int)customerID forReport:(int)reportID sectionID:(int)section
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        
        /*CREATE TABLE IF NOT EXISTS PVODynamicReportData (CustomerID INT, ReportID INT, DataEntryID INT,"
         " DataSectionID INT, TextValue TEXT, IntValue INT, DoubleValue REAL, DateTimeValue REAL)*/
        
        PVODynamicReportData *current;
        sqlite3_stmt *stmnt;
        if([self prepareStatement:[NSString stringWithFormat:@"SELECT CustomerID, ReportID, DataEntryID,"
                                   " DataSectionID, TextValue, IntValue, DoubleValue, DateTimeValue "
                                   "FROM PVODynamicReportData WHERE CustomerID = %d AND ReportID = %d AND DataSectionID = %d",
                                   customerID, reportID, section] withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[PVODynamicReportData alloc] init];
                
                current.custID = sqlite3_column_int(stmnt, 0);
                current.reportID = sqlite3_column_int(stmnt, 1);
                current.dataEntryID = sqlite3_column_int(stmnt, 2);
                current.dataSectionID = sqlite3_column_int(stmnt, 3);
                current.textValue = [SurveyDB stringFromStatement:stmnt columnID:4];
                current.intValue = sqlite3_column_int(stmnt, 5);
                current.doubleValue = sqlite3_column_double(stmnt, 6);
                current.dateValue = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 7)];
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(void)savePVODynamicReportData:(NSArray*)dataEntries
{
    @synchronized(self)
    {
        for (PVODynamicReportData *data in dataEntries) {
            [self savePVODynamicReportDataEntry:data];
        }
    }
}

-(void)savePVODynamicReportDataEntry:(PVODynamicReportData*)data
{
    if([self getIntValueFromQuery:
        [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVODynamicReportData WHERE CustomerID = %d AND ReportID = %d AND "
         "DataSectionID = %d AND DataEntryID = %d", data.custID, data.reportID, data.dataSectionID, data.dataEntryID]] > 0)
    {//update
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVODynamicReportData SET TextValue = %@, IntValue = %d, "
                        "DoubleValue = %f, DateTimeValue = %f WHERE CustomerID = %d AND ReportID = %d AND "
                        "DataSectionID = %d AND DataEntryID = %d",
                        [self prepareStringForInsert:data.textValue supportsNull:YES],
                        data.intValue, data.doubleValue,
                        data.dateValue == nil ? 0 : data.dateValue.timeIntervalSince1970,
                        data.custID, data.reportID, data.dataSectionID, data.dataEntryID]];
    }
    else
    {//insert
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataEntryID,"
                        " DataSectionID, TextValue, IntValue, DoubleValue, DateTimeValue) VALUES(%d,%d,%d,%d,%@,%d,%f,%f)",
                        data.custID, data.reportID, data.dataEntryID, data.dataSectionID,
                        [self prepareStringForInsert:data.textValue supportsNull:YES],
                        data.intValue, data.doubleValue,
                        data.dateValue == nil ? 0 : data.dateValue.timeIntervalSince1970]];
    }
}

-(void)movePVOInventoryItem:(PVOItemDetail *)item toNewRoom:(Room *)room
{
    NSString *cmd = [[NSString alloc] initWithFormat:@"UPDATE PVOInventoryItems SET RoomID = %d WHERE ItemID = %d AND PVOItemID = %d AND RoomID = %d",
                     room.roomID,
                     item.itemID,
                     item.pvoItemID,
                     item.roomID];
    
    [self updateDB:cmd];
    
}

-(void)addPVOFavoriteCartonContents:(int)contentID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOCartonContents SET Favorite = 1 WHERE CartonContentID = %d", contentID]];
}

-(void)removePVOFavoriteCartonContents:(int)contentID
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOCartonContents SET Favorite = 0 WHERE CartonContentID = %d", contentID]];
}


-(NSArray*)getAllPVOItemCommentsForItem:(int)pvoItemID
{
    return [self getAllPVOItemCommentsForItem: pvoItemID isReceivable:FALSE];
}

-(NSArray*)getAllPVOItemCommentsForItem:(int)pvoItemID isReceivable:(BOOL)isReceivable
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmnt;
    
    NSMutableString *cmd;
    
    if (!isReceivable)
        cmd = [NSMutableString stringWithFormat:@"SELECT Comments, CommentType FROM PVOInventoryItemComments WHERE PVOItemId = %d", pvoItemID];
    else
        cmd = [NSMutableString stringWithFormat:@"SELECT Comments, CommentType FROM PVOReceivableItemComments WHERE ReceivableItemID = %d", pvoItemID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVOItemComment *current = [[PVOItemComment alloc] init];
            current.comment = [SurveyDB stringFromStatement:stmnt columnID:0];
            current.commentType = sqlite3_column_int(stmnt, 1);
            if ([current.comment length] > 0)
                [retval addObject:current];
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOItemComment*)getPVOItemComment:(int)pvoItemID withCommentType:(int)commentType
{
    return [self getPVOItemComment:pvoItemID withCommentType:commentType isReceivable:FALSE];
}

-(PVOItemComment*)getPVOItemComment:(int)pvoItemID withCommentType:(int)commentType isReceivable:(BOOL)isReceivable
{
    PVOItemComment *current = [[PVOItemComment alloc] init];
    sqlite3_stmt *stmnt;
    NSString *cmd;
    
    if (!isReceivable)
        cmd = [NSString stringWithFormat:@"SELECT Comments, CommentType FROM PVOInventoryItemComments WHERE PVOItemId = %d AND CommentType = %d",
               pvoItemID, commentType];
    else
        cmd = [NSString stringWithFormat:@"SELECT Comments, CommentType FROM PVOReceivableItemComments WHERE ReceivableItemID = %d AND CommentType = %d",
               pvoItemID, commentType];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current.comment = [SurveyDB stringFromStatement:stmnt columnID:0];
            current.commentType = sqlite3_column_int(stmnt, 1);
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return current;
}

-(BOOL)savePVOItemComment:(NSString*)comment withPVOItemID:(int)pvoItemID withCommentType:(int)commentType
{
    if (pvoItemID <= 0)
        return NO;
    
    if ([comment length] == 0)
    {
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItemComments WHERE PVOItemId = %d AND CommentType = %d", pvoItemID, commentType]];
        return;
    }
    
    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOInventoryItemComments WHERE PVOItemId = %d AND CommentType = %d", pvoItemID, commentType]] > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItemComments SET Comments = '%@' WHERE PVOItemId = %d AND CommentType = %d", [comment stringByReplacingOccurrencesOfString:@"'" withString:@"''"], pvoItemID, commentType]];
        return YES;
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOInventoryItemComments(PVOItemID,Comments,CommentType) "
                        "VALUES(%d,'%@',%d)",
                        pvoItemID, [comment stringByReplacingOccurrencesOfString:@"'" withString:@"''"], commentType]];
        return sqlite3_last_insert_rowid(db) > 0;
    }
}

-(void)deletePVOItemComment:(int)pvoItemID withCommentType:(int)commentType
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItemComments WHERE PVOItemId = %d AND CommentType = %d", pvoItemID, commentType]];
}

-(void)deletePVOItemPhotos:(int)pvoItemID withPhotoType:(int)photoType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *photos = [self getImagesList:del.customerID withPhotoType:photoType withSubID:pvoItemID loadAllItems:NO];
    
    for (SurveyImage *img in photos)
    {
        [self deleteImageEntry:img.imageID];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        NSString *inDocsPath = img.path;
        NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
        NSError *error;
        if([fileManager fileExistsAtPath:fullPath])
            [fileManager removeItemAtPath:fullPath error:&error];
    }
}

#pragma mark - Room Alias
-(NSString*)getRoomAlias:(int)customerID withRoomID:(int)roomID
{
    //CREATE TABLE IF NOT EXISTS RoomAlias (CubesheetID INT, RoomID INT, Alias TEXT)
    return [self getStringValueFromQuery:[NSString stringWithFormat:@"SELECT Alias FROM RoomAlias WHERE CustomerID = %d AND RoomID = %d", customerID, roomID]];
}

-(void)saveRoomAlias:(NSString*)alias withCustomerID:(int)customerID andRoomID:(int)roomID
{
    //CREATE TABLE IF NOT EXISTS RoomAlias (CubesheetID INT, RoomID INT, Alias TEXT)
    if(alias == nil || alias.length == 0)
        [self updateDB:[NSString stringWithFormat:@"DELETE FROM RoomAlias WHERE CustomerID = %d AND RoomID = %d", customerID, roomID]];
    else
    {
        if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM RoomAlias WHERE CustomerID = %d AND RoomID = %d", customerID, roomID]] > 0)
        {
            [self updateDB:[NSString stringWithFormat:@"UPDATE RoomAlias SET Alias = %@ WHERE CustomerID = %d AND RoomID = %d",
                            [self prepareStringForInsert:alias],
                            customerID, roomID]];
        }
        else
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO RoomAlias(Alias, CustomerID, RoomID) VALUES(%@, %d, %d)",
                            [self prepareStringForInsert:alias],
                            customerID, roomID]];
        }
    }
}
#pragma mark - PVO Vehicles

-(PVOVehicle*)getPVOVehicleForID:(int)pvoVehicleID
{
    PVOVehicle *retval = nil;
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT VehicleID,CustomerID,Type,Year,Make,Model,Color,VIN,License,LicenseState,Odometer,WireframeType,DeclaredValue,ServerID FROM PVOVehicles WHERE VehicleID = %d", pvoVehicleID];
    
    if([self prepareStatement:cmd
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[PVOVehicle alloc] init];
            retval.vehicleID = sqlite3_column_int(stmnt, 0);
            retval.customerID = sqlite3_column_int(stmnt, 1);
            retval.type = [SurveyDB stringFromStatement:stmnt columnID:2];
            retval.year = [SurveyDB stringFromStatement:stmnt columnID:3];
            retval.make = [SurveyDB stringFromStatement:stmnt columnID:4];
            retval.model = [SurveyDB stringFromStatement:stmnt columnID:5];
            retval.color = [SurveyDB stringFromStatement:stmnt columnID:6];
            retval.vin = [SurveyDB stringFromStatement:stmnt columnID:7];
            retval.license = [SurveyDB stringFromStatement:stmnt columnID:8];
            retval.licenseState = [SurveyDB stringFromStatement:stmnt columnID:9];
            retval.odometer = [SurveyDB stringFromStatement:stmnt columnID:10];
            retval.wireframeType = sqlite3_column_int(stmnt, 11);
            retval.declaredValue = sqlite3_column_double(stmnt, 12);
            retval.serverID = sqlite3_column_int(stmnt, 13);
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSMutableArray*)getAllVehicles:(int)customerID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    PVOVehicle *current;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT VehicleID,CustomerID,Type,Year,Make,Model,Color,VIN,License,LicenseState,Odometer,WireframeType,DeclaredValue,ServerID FROM PVOVehicles WHERE CustomerID = %d", customerID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOVehicle alloc] init];
            
            current.vehicleID = sqlite3_column_int(stmnt, 0);
            current.customerID = sqlite3_column_int(stmnt, 1);
            current.type = [SurveyDB stringFromStatement:stmnt columnID:2];
            current.year = [SurveyDB stringFromStatement:stmnt columnID:3];
            current.make = [SurveyDB stringFromStatement:stmnt columnID:4];
            current.model = [SurveyDB stringFromStatement:stmnt columnID:5];
            current.color = [SurveyDB stringFromStatement:stmnt columnID:6];
            current.vin = [SurveyDB stringFromStatement:stmnt columnID:7];
            current.license = [SurveyDB stringFromStatement:stmnt columnID:8];
            current.licenseState = [SurveyDB stringFromStatement:stmnt columnID:9];
            current.odometer = [SurveyDB stringFromStatement:stmnt columnID:10];
            current.wireframeType = sqlite3_column_int(stmnt, 11);
            current.declaredValue = sqlite3_column_double(stmnt, 12);
            current.serverID = sqlite3_column_int(stmnt, 13);
            
            [retval addObject:current];
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)saveVehicle:(PVOVehicle*)vehicle
{
    if(vehicle.vehicleID > 0)
    {
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOVehicles SET Type = %@,Year = %@,Make = %@,Model = %@,Color = %@,VIN = %@,License = %@,LicenseState = %@,Odometer = %@,WireframeType = %d,DeclaredValue = %f,ServerID = %d WHERE VehicleID = %d",
                        [self prepareStringForInsert:vehicle.type],
                        [self prepareStringForInsert:vehicle.year],
                        [self prepareStringForInsert:vehicle.make],
                        [self prepareStringForInsert:vehicle.model],
                        [self prepareStringForInsert:vehicle.color],
                        [self prepareStringForInsert:vehicle.vin],
                        [self prepareStringForInsert:vehicle.license],
                        [self prepareStringForInsert:vehicle.licenseState],
                        [self prepareStringForInsert:vehicle.odometer],
                        vehicle.wireframeType,
                        vehicle.declaredValue,
                        vehicle.serverID,
                        vehicle.vehicleID]];
        
        return vehicle.vehicleID;
    }
    else
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVehicles(CustomerID,Type,Year,Make,Model,Color,VIN,License,LicenseState,Odometer,WireframeType,DeclaredValue,ServerID) VALUES(%d,%@,%@,%@,%@,%@,%@,%@,%@,%@,%d,%f,%d)",
                        vehicle.customerID,
                        [self prepareStringForInsert:vehicle.type],
                        [self prepareStringForInsert:vehicle.year],
                        [self prepareStringForInsert:vehicle.make],
                        [self prepareStringForInsert:vehicle.model],
                        [self prepareStringForInsert:vehicle.color],
                        [self prepareStringForInsert:vehicle.vin],
                        [self prepareStringForInsert:vehicle.license],
                        [self prepareStringForInsert:vehicle.licenseState],
                        [self prepareStringForInsert:vehicle.odometer],
                        vehicle.wireframeType,
                        vehicle.declaredValue,
                        vehicle.serverID]];
        
        return sqlite3_last_insert_rowid(db);
    }
}

-(void)deleteVehicle:(PVOVehicle*)vehicle
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOVehicles WHERE VehicleID = %d", vehicle.vehicleID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOVehicleImages WHERE VehicleID = %d", vehicle.vehicleID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOWireframeDamages WHERE WireframeItemID = %d AND VehicleDamage = 1", vehicle.vehicleID]];
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOSignatures WHERE CustomerID = %d AND ReferenceID = %d", vehicle.customerID, vehicle.vehicleID]];
    
}

//CREATE TABLE PVOVehicleImages (VehicleImageID INTEGER PRIMARY KEY, ImageID INTEGER, VehicleID INTEGER, CustomerID INTEGER)
#pragma mark - PVO Vehicle Images

-(NSMutableArray*)getAllVehicleImages:(int)vehicleID withCustomerID:(int)customerID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT ImageID FROM PVOVehicleImages WHERE VehicleID = %d AND CustomerID = %d",vehicleID, customerID] withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int imageID = sqlite3_column_int(stmnt, 0);
            [retval addObject:[NSNumber numberWithInt:imageID]];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)saveVehicleImage:(int)imageID withVehicleID:(int)vehicleID withCustomerID:(int)customerID
{
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVehicleImages(ImageID,VehicleID,CustomerID) VALUES(%d,%d,%d)", imageID, vehicleID, customerID]];
}

#pragma mark - PVO Vehicle Damages

-(NSArray*)getPVOVehicleWireframeTypes:(int)customerID
{//used to get a list of all wireframe types used for copying the images to the workingHTML folder
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(WireFrameType) FROM PVOVehicles v "
                               "WHERE v.CustomerID = %d ", customerID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int wireFrameType = sqlite3_column_int(stmnt, 0);
            [retval addObject:[NSNumber numberWithInt:wireFrameType]];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getVehicleDamages:(int)vehicleID
{
    return [self getVehicleDamages:vehicleID withImageID:-1];
}

-(NSArray*)getVehicleDamages:(int)vehicleID withImageID:(int)imageID
{
    return [self getWireframeDamages:vehicleID withImageID:imageID withIsVehicle:YES];
}

-(NSArray*)getWireframeDamages:(int)wireframeItemID
{
    return [self getWireframeDamages:wireframeItemID withImageID:-1];
}

-(NSArray*)getWireframeDamages:(int)wireframeItemID withImageID:(int)imageID
{
    return [self getWireframeDamages:wireframeItemID withImageID:imageID withIsVehicle:NO];
}

-(NSArray*)getWireframeDamages:(int)wireframeItemID withImageID:(int)imageID withIsVehicle:(BOOL)isVehicle
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    PVOWireframeDamage *current;
    
    NSString *imageIDClause = (imageID == -1 ? @"" : [NSString stringWithFormat:@" AND ImageID = %d",imageID]);
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT DamageID, WireframeItemID, LocationType, ImageID, Comments, AlphaCodes, DamageLocationX, DamageLocationY, OriginDamage, VehicleDamage FROM PVOWireframeDamages WHERE VehicleDamage = %d AND WireframeItemID = %d%@",
                     (isVehicle ? 1 : 0),
                     wireframeItemID,
                     imageIDClause];
    
    if([self prepareStatement:cmd
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            current = [[PVOWireframeDamage alloc] init];
            
            current.damageID = sqlite3_column_int(stmnt, 0);
            current.vehicleID = sqlite3_column_int(stmnt, 1);
            current.locationType = sqlite3_column_int(stmnt, 2);
            current.imageID = sqlite3_column_int(stmnt, 3);
            current.comments = [SurveyDB stringFromStatement:stmnt columnID:4];
            current.damageAlphaCodes = [SurveyDB stringFromStatement:stmnt columnID:5];
            
            CGPoint loc;
            loc.x = sqlite3_column_double(stmnt, 6);
            loc.y = sqlite3_column_double(stmnt, 7);
            current.damageLocation = loc;
            
            current.isOriginDamage = sqlite3_column_int(stmnt, 8) > 0;
            current.isAutoInventory = sqlite3_column_int(stmnt, 9) > 0;
            
            [retval addObject:current];
            
            
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)savePVOWireframeDamages:(NSArray*)damages forWireframeItemID:(int)wireframeItemID withImageID:(int)imageID withIsVehicle:(BOOL)isVehicle
{
    NSArray *current = [self getWireframeDamages:wireframeItemID withImageID:imageID];
    BOOL found = FALSE;
    for (PVOWireframeDamage *old in current)
    {
        for (PVOWireframeDamage *new in damages)
        {
            if(old.damageID == new.damageID)
            {
                found = TRUE;
                break;
            }
        }
        
        if(!found)
            [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOWireframeDamages WHERE DamageID = %d AND VehicleDamage = 1", old.damageID]];
    }
    
    //save all of the new ones..
    for (PVOWireframeDamage *new in damages)
    {
        if(new.damageID > 0)
        {
            [self updateDB:[NSString stringWithFormat:@"UPDATE PVOWireframeDamages SET WireframeItemID = %d, LocationType = %d, ImageID = %d, Comments = %@, AlphaCodes = %@, DamageLocationX = %f, DamageLocationY = %f, OriginDamage = %d"
                            " WHERE DamageID = %d AND VehicleDamage = %d",
                            wireframeItemID,
                            new.locationType,
                            new.imageID,
                            [self prepareStringForInsert:new.comments],
                            [self prepareStringForInsert:new.damageAlphaCodes],
                            new.damageLocation.x,
                            new.damageLocation.y,
                            new.isOriginDamage ? 1 : 0,
                            new.damageID,
                            (isVehicle ? 1 : 0)]];
        }
        else
        {
            new.imageID = imageID;
            
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOWireframeDamages(WireframeItemID, LocationType, ImageID, Comments, AlphaCodes, DamageLocationX, DamageLocationY, OriginDamage, VehicleDamage) "
                            "VALUES(%d,%d,%d,%@,%@,%f,%f,%d,%d)",
                            wireframeItemID,
                            new.locationType,
                            new.imageID,
                            [self prepareStringForInsert:new.comments],
                            [self prepareStringForInsert:new.damageAlphaCodes],
                            new.damageLocation.x,
                            new.damageLocation.y,
                            (new.isOriginDamage ? 1 : 0),
                            (isVehicle ? 1 : 0)]];
        }
    }
}

#pragma mark - PVO Check List Items

-(NSArray*)getCheckListItems:(int)customerID withVehicleID:(int)vehicleID withAgencyCode:(NSString*)haulingAgent
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    PVOCheckListItem *current;
    
    //disabled, we're just grabbing all the items per hauling agent code, and having the user check them all each time
    //    if([self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOVehicleCheckList WHERE VehicleID = %d", vehicleID]] > 0)
    //    {
    //        //first let's check to see if any check list items have been saved for this vehicle...
    //        [self prepareStatement:[NSString stringWithFormat:@"SELECT vcl.VehicleCheckListID, vcl.CheckListItemID, vcl.VehicleID, vcl.IsChecked, vcli.Description FROM PVOVehicleCheckList vcl JOIN PVOVehicleCheckListItems vcli on vcl.CheckListItemID = vcli.CheckListItemID WHERE vcl.VehicleID = %d", vehicleID] withStatement:&stmnt];
    //
    //        while(sqlite3_step(stmnt) == SQLITE_ROW)
    //        {
    //            current = [[PVOCheckListItem alloc] init];
    //
    //            current.vehicleCheckListID = sqlite3_column_int(stmnt, 0);
    //            current.checkListItemID = sqlite3_column_int(stmnt, 1);
    //            current.vehicleID = sqlite3_column_int(stmnt, 2);
    //            current.isChecked = sqlite3_column_int(stmnt, 3) > 0 ? YES : NO;
    //            current.description = [SurveyDB stringFromStatement:stmnt columnID:4];
    //            current.customerID = customerID;
    //
    //            [retval addObject:current];
    //
    //
    //        }
    //    }
    //    else
    //    {
    //if no check list items have been saved for this vehicle ID let's go ahead and populate the list from the customer record...
    [self prepareStatement:[NSString stringWithFormat:@"SELECT CheckListItemID, Description FROM PVOVehicleCheckListItems WHERE AgencyCode = '%@'", haulingAgent] withStatement:&stmnt];
    
    while(sqlite3_step(stmnt) == SQLITE_ROW)
    {
        current = [[PVOCheckListItem alloc] init];
        
        current.checkListItemID = sqlite3_column_int(stmnt, 0);
        current.description = [SurveyDB stringFromStatement:stmnt columnID:1];
        current.vehicleID = vehicleID;
        current.customerID = customerID;
        
        [retval addObject:current];
        
        
    }
    //    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(void)savePVOVehicleCheckListForAgency:(NSArray*)vehicleCheckListItems withAgencyCode:(NSString*)agencyCode
{
    //not updating or comparing, just delete the old ones and save the new ones
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOVehicleCheckListItems WHERE AgencyCode = '%@' ", agencyCode]];
    
    for (NSString *item in vehicleCheckListItems)
    {
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVehicleCheckListItems(AgencyCode, Description) "
                        "VALUES(%@,%@)",
                        [self prepareStringForInsert:agencyCode],
                        [self prepareStringForInsert:item]]];
    }
}

-(void)saveVehicleCheckList:(NSArray*)vehicleCheckList
{
    for (PVOCheckListItem *item in vehicleCheckList)
    {
        if(item.vehicleCheckListID > 0)
        {
            [self updateDB:[NSString stringWithFormat:@"UPDATE PVOVehicleCheckList SET CheckListItemID = %d, VehicleID = %d, IsChecked = %d WHERE VehicleCheckListID = %d",
                            item.checkListItemID,
                            item.vehicleID,
                            item.isChecked ? 1 : 0,
                            item.vehicleCheckListID]];
        }
        else
        {
            [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVehicleCheckList(CheckListItemID, VehicleID, IsChecked) "
                            "VALUES(%d,%d,%d)",
                            item.checkListItemID,
                            item.vehicleID,
                            item.isChecked ? 1 : 0]];
        }
    }
}

//bulky inventory

-(NSMutableArray*)getPVOBulkyData:(int)pvoBulkyItemID
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        if (pvoBulkyItemID <= 0)
            return retval;
        
        //    [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOBulkyInventoryItemData(PVOBulkyInventoryItemID INTEGER, DataEntryID INTEGER, TextValue TEXT, IntValue INT, DoubleValue REAL, DateTimeValue REAL)"];
        
        PVOBulkyData *current;
        sqlite3_stmt *stmnt;
        
        NSString *cmd = [NSString stringWithFormat:@"SELECT PVOBulkyInventoryItemID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue "
                         "FROM PVOBulkyInventoryItemData WHERE PVOBulkyInventoryItemID = %d",
                         pvoBulkyItemID];
        
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[PVOBulkyData alloc] init];
                
                current.pvoBulkyItemID = sqlite3_column_int(stmnt, 0);
                current.dataEntryID = sqlite3_column_int(stmnt, 1);
                current.textValue = [SurveyDB stringFromStatement:stmnt columnID:2];
                current.intValue = sqlite3_column_int(stmnt, 3);
                current.doubleValue = sqlite3_column_double(stmnt, 4);
                current.dateValue = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(stmnt, 5)];
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(void)savePVOBulkyData:(NSArray*)dataEntries withPVOBulkyItemID:(int)pvoBulkyItemID
{
    @synchronized(self)
    {
        for (PVOBulkyData *data in dataEntries) {
            data.pvoBulkyItemID = pvoBulkyItemID;
            [self savePVOBulkyDataEntry:data];
        }
    }
}

-(void)savePVOBulkyDataEntry:(PVOBulkyData*)data
{
    if([self getIntValueFromQuery:
        [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOBulkyInventoryItemData WHERE PVOBulkyInventoryItemID = %d AND DataEntryID = %d", data.pvoBulkyItemID, data.dataEntryID]] > 0)
    {//update
        [self updateDB:[NSString stringWithFormat:@"UPDATE PVOBulkyInventoryItemData SET TextValue = %1$@, IntValue = %2$d, DoubleValue = %3$f, DateTimeValue = %4$f "
                        "WHERE PVOBulkyInventoryItemID = %5$d AND DataEntryID = %6$d",
                        [self prepareStringForInsert:data.textValue supportsNull:YES],
                        data.intValue,
                        data.doubleValue,
                        data.dateValue == nil ? 0 : data.dateValue.timeIntervalSince1970,
                        data.pvoBulkyItemID,
                        data.dataEntryID]];
    }
    else
    {//insert
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOBulkyInventoryItemData(PVOBulkyInventoryItemID, DataEntryID,"
                        " TextValue, IntValue, DoubleValue, DateTimeValue) VALUES(%d,%d,%@,%d,%f,%f)",
                        data.pvoBulkyItemID,
                        data.dataEntryID,
                        [self prepareStringForInsert:data.textValue supportsNull:YES],
                        data.intValue,
                        data.doubleValue,
                        data.dateValue == nil ? 0 : data.dateValue.timeIntervalSince1970]];
    }
}

-(NSArray*)getPVOBulkyInventoryItems:(int)customerID
{
    return [self getPVOBulkyInventoryItems:customerID withPVOBulkyItemType:-1];
}

-(NSArray*)getPVOBulkyInventoryItems:(int)customerID withPVOBulkyItemType:(int)pvoBulkyItemTypeID
{
    @synchronized(self)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] init];
        
        PVOBulkyInventoryItem *current;
        sqlite3_stmt *stmnt;
        
        //         [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOBulkyInventoryItems(PVOBulkyInventoryItemID INTEGER PRIMARY KEY, CustomerID INTEGER, PVOBulkyItemTypeID INTEGER, WireframeTypeID INTEGER)"];
        
        NSString *cmd = [NSString stringWithFormat:@"SELECT PVOBulkyInventoryItemID, CustomerID, PVOBulkyItemTypeID, WireframeTypeID FROM PVOBulkyInventoryItems WHERE CustomerID = %d",
                         customerID];
        
        if (pvoBulkyItemTypeID > 0)
        {
            cmd = [cmd stringByAppendingString:[NSString stringWithFormat:@" AND PVOBulkyItemTypeID = %d",
                                                pvoBulkyItemTypeID]];
        }
        
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                current = [[PVOBulkyInventoryItem alloc] initWithStatement:stmnt];
                
                [retval addObject:current];
                
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(PVOBulkyInventoryItem*)getPVOBulkyInventoryItemByID:(int)pvoBulkyItemID
{
    @synchronized(self)
    {
        PVOBulkyInventoryItem *retval = [[PVOBulkyInventoryItem alloc] init];
        if (pvoBulkyItemID <= 0)
            return retval;
        
        sqlite3_stmt *stmnt;
        NSString *cmd = [NSString stringWithFormat:@"SELECT PVOBulkyInventoryItemID, CustomerID, PVOBulkyItemTypeID, WireframeTypeID FROM PVOBulkyInventoryItems WHERE PVOBulkyInventoryItemID = %d",
                         pvoBulkyItemID];
        
        if([self prepareStatement:cmd withStatement:&stmnt])
        {
            if(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                retval = [[PVOBulkyInventoryItem alloc] initWithStatement:stmnt];
                
            }
        }
        sqlite3_finalize(stmnt);
        
        return retval;
    }
}

-(int)getPVOBulkyItemCount:(int)pvoBulkyTypeID forCustomer:(int)customerID
{
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT Count(*) FROM PVOBulkyInventoryItems WHERE CustomerID = %d AND PVOBulkyItemTypeID = %d", customerID, pvoBulkyTypeID];
    int retval = [self getIntValueFromQuery:cmd];
    
    return retval;
}

-(int)savePVOBulkyInventoryItem:(int)customerID withPVOBulkyItem:(PVOBulkyInventoryItem *)pvoBulkyItem
{
    if (pvoBulkyItem.pvoBulkyItemID > 0)
    {
        return [self updatePVOBulkyInventoryItem:pvoBulkyItem];
    } else {
        return [self insertNewPVOBulkyInventoryItem:customerID withPVOBulkyItem:pvoBulkyItem];
    }
}

-(int)insertNewPVOBulkyInventoryItem:(int)customerID withPVOBulkyItem:(PVOBulkyInventoryItem*)pvoBulkyItem
{
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PVOBulkyInventoryItems (CustomerID, PVOBulkyItemTypeID) VALUES (%1$d, %2$d)", customerID, pvoBulkyItem.pvoBulkyItemTypeID];
    [self updateDB:cmd];
    
    int itemID = sqlite3_last_insert_rowid(db);
    return itemID;
}

-(int)updatePVOBulkyInventoryItem:(PVOBulkyInventoryItem*)bulkyItem
{
    [self updateDB:[NSString stringWithFormat:@"UPDATE PVOBulkyInventoryItems SET WireframeTypeID = %d WHERE PVOBulkyInventoryItemID = %d",
                    bulkyItem.wireframeTypeID,
                    bulkyItem.pvoBulkyItemID]];
    
    return bulkyItem.pvoBulkyItemID;
    
}

-(void)deleteAllPVOBulkyInventoryItemsForCustomer:(int)customerID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOBulkyInventoryItemData WHERE PVOBulkyInventoryItemID IN (SELECT PVOBulkyInventoryItemID FROM PVOBulkyInventoryItems WHERE CustomerID = %d)",
                    customerID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOWireframeDamages WHERE VehicleDamage = 0 AND WireframeItemID IN (SELECT PVOBulkyInventoryItemID FROM PVOBulkyInventoryItems WHERE CustomerID = %d)",
                    customerID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOBulkyInventoryItems WHERE CustomerID = %d",
                    customerID]];
}

-(void)deletePVOBulkyInventoryItem:(int)pvoBulkyItemID
{
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOBulkyInventoryItemData WHERE PVOBulkyInventoryItemID = %d",
                    pvoBulkyItemID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOWireframeDamages WHERE VehicleDamage = 0 AND WireframeItemID IN(SELECT PVOBulkyInventoryItemID FROM PVOBulkyInventoryItems WHERE PVOBulkyInventoryItemID = %d",
                    pvoBulkyItemID]];
    
    [self updateDB:[NSString stringWithFormat:@"DELETE FROM PVOBulkyInventoryItems WHERE PVOBulkyInventoryItemID = %d",
                    pvoBulkyItemID]];
    
}

-(NSArray*)getPVOBulkyWireframeTypesForCustomer:(int)customerID
{//used to get a list of all wireframe types used for copying the images to the workingHTML folder
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT DISTINCT(WireFrameTypeID) FROM PVOBulkyInventoryItems b "
                               "WHERE b.CustomerID = %d AND WireframeTypeID IS NOT NULL", customerID]
                withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int wireFrameType = sqlite3_column_int(stmnt, 0);
            [retval addObject:[NSNumber numberWithInt:wireFrameType]];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}

#pragma mark - Dirty Report methods
-(int)numberOfUploadTrackingRecordsForCustomer:(int)cID
{
    if([[self getCustomer:cID] pricingMode] == LOCAL){
        return 0;
    }
    int c = [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM UploadTracking WHERE CustomerID = %d", cID]];
    return c;
}

-(NSMutableArray*)getAllDirtyReports
{
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSArray *c = [self getCustomerList:nil];
    
    for(CustomerListItem *a in c){
        [r addObjectsFromArray:[self getAllDirtyReportsForCustomer:a.custID]];
    }
    
    return r;
}

-(NSMutableArray*)getAllDirtyReportsForCustomer:(int)cID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    if([[self getCustomer:cID] pricingMode] == LOCAL){
        return retval;
    }
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:
                     @"SELECT NavItemID FROM UploadTracking WHERE "
                     "WasUploaded = 0 AND CustomerID = %d", cID];
    
    if([self prepareStatement:cmd withStatement:&stmnt]){
        while(sqlite3_step(stmnt) == SQLITE_ROW){
            PVONavigationListItem *p = [[PVONavigationListItem alloc] init];
            p.navItemID = sqlite3_column_int(stmnt, 0);
            p.custID = cID;
            if(p.hasRequiredSignatures){
                [retval addObject:@(p.navItemID)];
            }
        }
    }
    
    sqlite3_finalize(stmnt);
    return retval;
}

-(NSArray*)getUploadTrackingRecordsForCustomer:(int)cID
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    if([[self getCustomer:cID] pricingMode] == LOCAL){
        return retval;
    }
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:
                     @"SELECT NavItemID FROM UploadTracking WHERE "
                     "CustomerID = %d", cID];
    
    if([self prepareStatement:cmd withStatement:&stmnt]){
        while(sqlite3_step(stmnt) == SQLITE_ROW){
            [retval addObject:@(sqlite3_column_int(stmnt, 0))];
        }
    }
    
    sqlite3_finalize(stmnt);
    return retval;
}

-(BOOL)getReportWasUploaded:(int)cID forNavItem:(int)nID
{
    sqlite3_stmt *stmnt;
    bool f = false;
    
    if([[self getCustomer:cID] pricingMode] == LOCAL){
        return f;
    }
    
    NSString *cmd = [NSString stringWithFormat:
                     @"SELECT WasUploaded FROM UploadTracking "
                     "WHERE CustomerID = %d AND NavItemID = %d"
                     , cID, nID];
    
    if([self prepareStatement:cmd withStatement:&stmnt]) {
        if(sqlite3_step(stmnt) == SQLITE_ROW) {
            f = sqlite3_column_int(stmnt, 0) == 1;
        }
    }
    
    sqlite3_finalize(stmnt);
    return f;
}

-(void)setReportWasUploaded:(bool)wasUploaded forCustomer:(int)cID forNavItem:(int)nID
{
    if([[self getCustomer:cID] pricingMode] == LOCAL){
        return;
    }
    
    NSString *cmd;
    NSString *e = [NSString stringWithFormat:
                   @"SELECT COUNT(*) From UploadTracking "
                   "WHERE CustomerID = %d AND NavItemID = %d"
                   , cID, nID];
    
    bool recordExists = [self getIntValueFromQuery:e] > 0;
    
    if(recordExists){
        cmd = [NSString stringWithFormat:
               @"UPDATE UploadTracking SET WasUploaded = %d "
               "WHERE CustomerID = %d AND NavItemID = %d"
               ,wasUploaded ? 1 : 0, cID, nID];
    } else {
        cmd = [NSString stringWithFormat:
               @"Insert INTO UploadTracking "
               "(CustomerID, NavItemID, WasUploaded) "
               "VALUES (%d, %d, %d)",
               cID, nID, wasUploaded ? 1 : 0];
    }
    
    [self updateDB:cmd];
}

#pragma mark - Item Favorites By Room methods
// For OT 7985

// Returns an array of Room objects for which item favorites by room have been added for
-(NSArray*)getPVOFavoriteItemsRooms {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    Room *room;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = @"SELECT DISTINCT ifbr.RoomID, rd.Description FROM ItemFavoritesByRoom AS ifbr JOIN RoomDescription AS rd WHERE ifbr.RoomID = rd.RoomID ORDER BY rd.Description ASC";
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int roomID = sqlite3_column_int(stmnt, 0);
            
            room = [self getRoom:roomID];
            [array addObject:room];
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
}

// Returns an array of Item objects that are favorites for the given room
-(NSArray*)getPVOFavoriteItemsForRoom:(Room*)room {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    Item* item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT ItemID FROM ItemFavoritesByRoom WHERE RoomID = %d",room.roomID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            int itemID = sqlite3_column_int(stmnt, 0);
            
            item = [self getItem:itemID];
            [array addObject:item];
        }
    }
    sqlite3_finalize(stmnt);
    
    return array;
}

// Adds specified items to favorites by room for the specified room
-(void)addPVOFavoriteItemRoom:(int)roomID withItems:(NSArray*)items {
    [self removePVOFavoriteItemRoom:roomID];
    
    for(int i = 0; i < [items count]; i++) {
        Item *item = [items objectAtIndex:i];
        
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO ItemFavoritesByRoom (ItemID, RoomID) VALUES (%d,%d)",item.itemID,roomID];
        
        [self updateDB:cmd];
    }
}

// Deletes all records containing item favorites by room for the specified room
-(void)removePVOFavoriteItemRoom:(int)roomID {
    NSString *cmd = [NSString stringWithFormat:@"DELETE FROM ItemFavoritesByRoom WHERE RoomID = %d",roomID];
    
    [self updateDB:cmd];
}

#pragma mark - Completion Date methods
-(void)setCompletionDate:(int)customerID isOrigin:(BOOL)origin {
    NSString* locationColumnName = origin ? @"OriginCompletionDate" : @"DestinationCompletionDate";
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [formatter stringFromDate:currentDate];
    
    [self updateDB:[NSString stringWithFormat:@"UPDATE Customer SET %@ = '%@' WHERE CustomerID = %d",locationColumnName,dateString,customerID]];
}

-(void)removeCompletionDate:(int)customerID isOrigin:(BOOL)origin {
    NSString* locationColumnName = origin ? @"OriginCompletionDate" : @"DestinationCompletionDate";
    [self updateDB:[NSString stringWithFormat:@"UPDATE Customer SET %@ = '' WHERE CustomerID = %d",locationColumnName,customerID]];
}

@end
