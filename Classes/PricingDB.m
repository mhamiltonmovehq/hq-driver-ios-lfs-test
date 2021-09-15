//
//  PricingDB.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PricingDB.h"
#import "SurveyAppDelegate.h"
#import "PVONavigationListItem.h"
#import "PVONavigationCategory.h"
#import "PVOAttachDocItem.h"
#import "PVODynamicReportSection.h"
#import "PVODynamicReportEntry.h"
#import "PVOBulkyEntry.h"
#import "AppFunctionality.h"
#import "XMLDictionary.h"
#import "NSString+Utilities.h"

@implementation PricingDB

@synthesize effectiveDate;
@synthesize runningOnSeparateThread;

#pragma mark General DB Methods

-(id)init
{
    if(self = [super init])
    {
        vanline = 0;
        db = NULL;
        runningOnSeparateThread = FALSE;
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        
        numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setPositiveFormat:@"0.00"];
    }
    
    return self;
}

-(NSString*)fullDBPath
{
    return [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:PRICING_DB_NAME];
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
    //check if file exists
    NSFileManager *mgr = [NSFileManager defaultManager];
    if(![mgr fileExistsAtPath:[self fullDBPath]])
        return FALSE;//[self createDatabase];
    
    if(db != NULL)
        return TRUE;
    
    if(sqlite3_open([[self fullDBPath] UTF8String], &db) != SQLITE_OK)
    {
        sqlite3_close(db);
        db = nil;
        return FALSE;
    }
    
//    //check the version.  if not current, delete.
//    if(![self tableExists:@"Version"] || [self getIntValueFromQuery:@"SELECT Major FROM Version"] != CURRENT_PRICING_VERSION)
//    {
//        [self deleteDB];
//        return FALSE;
//    }
    
    return TRUE;
}

-(BOOL)createDatabase
{
    
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:PRICING_DB_NAME];
    
    // copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:PRICING_DB_NAME];
    
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
    vanline = 0;
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
        [SurveyAppDelegate showAlert:error withTitle:@"SQLite error" withDelegate:nil onSeparateThread:runningOnSeparateThread];
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
    NSString *cmd = [[NSString alloc] initWithFormat:@"SELECT %@ FROM [%@] LIMIT 1", column, table];
    
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
            if (sqlite3_column_type(stmnt, 0) != SQLITE_NULL)
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


#pragma mark Agents

-(NSMutableArray*)getAgentsList:(NSString*)state sortByCode:(BOOL)byCode
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    SurveyAgent *item;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT ID,Name,Address,City,State,Zip,Phone,Fax,Email,Code FROM VanlineAgents "
                     " WHERE State = '%@' ORDER BY %@ ASC", state, byCode ? @"Code": @"Name"];
    
    const char *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item = [[SurveyAgent alloc] init];
            item.itemID = sqlite3_column_int(stmnt, 0);
            temp = (const char*)sqlite3_column_text(stmnt, 1);
            if(temp)
                item.name = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 2);
            if(temp)
                item.address = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 3);
            if(temp)
                item.city = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 4);
            if(temp)
                item.state = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 5);
            if(temp)
                item.zip = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 6);
            if(temp)
                item.phone = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 7);
            temp = (const char*)sqlite3_column_text(stmnt, 8);
            if(temp)
                item.email = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 9);
            if(temp)
                item.code = [NSString stringWithUTF8String:temp];
            [array addObject:item];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(SurveyAgent*)getAgent:(NSString*)code
{
    SurveyAgent *item = [[SurveyAgent alloc] init];
    sqlite3_stmt *stmnt;
    NSString *cmd = [NSString stringWithFormat:@"SELECT ID,Name,Address,City,State,Zip,Phone,Fax,Email,Code FROM VanlineAgents "
                     " WHERE Code = '%@'", code];
    const char *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            item.itemID = sqlite3_column_int(stmnt, 0);
            temp = (const char*)sqlite3_column_text(stmnt, 1);
            if(temp)
                item.name = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 2);
            if(temp)
                item.address = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 3);
            if(temp)
                item.city = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 4);
            if(temp)
                item.state = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 5);
            if(temp)
                item.zip = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 6);
            if(temp)
                item.phone = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 7);
            temp = (const char*)sqlite3_column_text(stmnt, 8);
            if(temp)
                item.email = [NSString stringWithUTF8String:temp];
            temp = (const char*)sqlite3_column_text(stmnt, 9);
            if(temp)
                item.code = [NSString stringWithUTF8String:temp];
        }
    }
    sqlite3_finalize(stmnt);
    return item;
}

-(void)deleteVLAgents
{
    [self updateDB:@"DELETE FROM VanlineAgents"];
}

-(void)insertVLAgents:(NSArray*)agents
{
    SurveyAgent *current;
    for(int i = 0; i < [agents count]; i++)
    {
        current = [agents objectAtIndex:i];
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO VanlineAgents"
                        "(Name,Address,City,State,Zip,Phone,Fax,Email,Code)"
                        "VALUES('%@','%@','%@','%@','%@','%@','%@','%@','%@')",
                        current.name == nil ? @"" : [current.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.address == nil ? @"" : [current.address stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.city == nil ? @"" : [current.city stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.state == nil ? @"" : [current.state stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.zip    == nil ? @"" : [current.zip stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.phone == nil ? @"" : [current.phone stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.email == nil ? @"" : [current.email stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                        current.code == nil ? @"" : [current.code stringByReplacingOccurrencesOfString:@"'" withString:@"''"]]];
    }
}

-(NSMutableArray*)getAgencyStates
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = @"SELECT DISTINCT(State) FROM VanlineAgents "
    " ORDER BY State ASC";
    
    NSString *state;
    const char *temp;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            temp = (const char*)sqlite3_column_text(stmnt, 0);
            if(temp)
            {
                state = [[NSString alloc] initWithUTF8String:(const char*)temp];
                [array addObject:state];
            }
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return array;
    
}

-(BOOL)hasAgencies
{
    return [self getIntValueFromQuery:@"SELECT COUNT(*) FROM VanlineAgents"] > 0;
}


#pragma mark utility funcitons

-(int)vanline
{
    
    BOOL openclose = db == nil;
    if(openclose)
    {
        //this is used to pull the vanline id for survey db upgrades...
        //at this point, if there is no pricing db yet, it will return base
        //which is fine since there wouldnt be anything to upgrade in the 
        //customer db anyway... if this code gets hit in any other circumstance, 
        //this could be a problem.
        if(![self openDB])
            return vanline;
    }
    
    if(vanline != 0)
        return vanline;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = @"SELECT VanLineID FROM DBVersion";
    
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            vanline = sqlite3_column_int(stmnt, 0);
        }
    }
    sqlite3_finalize(stmnt);
    
    //not sure why im setting vanline = 0 in closeDB, but saving temp to ensure it stays.
    int tempvl = vanline;
    
    if(openclose)
        [self closeDB];
    
    vanline = tempvl;
    
    return vanline;
    
}

- (BOOL)requiresUpdate
{
    if (![self columnExists:@"RequiredSignatures" inTable:@"PVOVanlines_Dynamic"])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - PVO

-(BOOL*)hasAutoInventoryItems
{
    int vanlineID = [self vanline];
    NSString *cmd = [NSString stringWithFormat:@"SELECT COUNT(i.NavItemID) "
                     "FROM PVOVanlines v,PVONavItems i "
                     "WHERE v.IncludedPVOItem = i.NavItemID AND v.VanlineID IN(0,%d) "
                     "AND (i.NavItemID = 62 OR i.NavItemID = 63 OR i.NavItemID = 64 OR i.NavItemID = 65 OR i.NavItemID = 79 OR i.NavItemID = 80)",
                     vanlineID];
    
    int autoInventoryNavItems = [self getIntValueFromQuery:cmd];
    

    return autoInventoryNavItems > 0 ? YES : NO;
}

-(NSString*)getRequiredSignaturesForNavItem:(int)pvoNavItem
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT RequiredSignatures FROM PVOVanlines_Dynamic WHERE VanlineID = %d AND IncludedPVOItem = %d", [self vanline], pvoNavItem];
    NSString *retval;
    sqlite3_stmt *stmnt;
    
    if([self prepareStatement:cmd withStatement:&stmnt]) {
        if(sqlite3_step(stmnt) == SQLITE_ROW) {
            retval = ((char*)sqlite3_column_text(stmnt, 0)) ? [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 0)] : @"";
        }
    }
    
    sqlite3_finalize(stmnt);
    return [retval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSDictionary*)getPVOListItems
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    int vanlineID = [self vanline];

    NSString *cmd = [NSString stringWithFormat:@"Select DISTINCT(reportid), navdescription"
           " FROM PVONavItems pni"
           " INNER JOIN  PVOVanlines_Dynamic pvd"
           " ON pni.navitemid = pvd.includedpvoitem"
           " WHERE VanlineID IN (0, %d)"
           " AND Hidden = 0"
           " AND ReportID > 0",
           vanlineID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSMutableArray *array = [retval objectForKey:
                                     [NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
            if(array == nil)
                array = [[NSMutableArray alloc] init];
            
            [retval setObject:array forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 0)]];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVOListItems:(int)driverType withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode
{
    return [self getPVOListItems:driverType withSourcedFromServer:YES withHaulingAgentCode:haulingAgentCode withPricingMode:pricingMode];
    //setting this to yes because the only place its used is DownloadAllHTML and i want all reports to be downloaded
}

-(NSDictionary*)getPVOListItems:(int)driverType withSourcedFromServer:(BOOL)sourcedFromServer withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode
{
    
//#ifdef TARGET_IPHONE_SIMULATOR //sent to prod
    if ([self tableExists:@"PVOVanlines_Dynamic"])
    {//Has the latest pricingDB, use the new method instead of this hodge podge
        return [self getPVOListItemsNew:driverType withSourcedFromServer:sourcedFromServer withHaulingAgentCode:haulingAgentCode withPricingMode:pricingMode];
    }
//#endif
    
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    int vanlineID = [self vanline];
    BOOL hasNavItemOverride = [self tableExists:@"PVONavItemsOverride"];
    BOOL hasHaulingAgentTable = [self tableExists:@"PVOHaulingAgents"];
    
    NSString *reportID = [self columnExists:@"ReportID" inTable:@"PVONavItems"] ? @",i.ReportID" : nil;
    NSString *signatureID = [self columnExists:@"SignatureID" inTable:@"PVONavItems"] ? @",i.SignatureID" : nil;
    NSString *reportNotesTypeID = [self columnExists:@"ReportNotesType" inTable:@"PVONavItems"] ? @",i.ReportNotesType" : nil;
    
    NSString *cmd = @"";
    
//#ifdef TARGET_IPHONE_SIMULATOR //this macro doesn't seem to work anymore
//    sourcedFromServer = YES;
//#endif
    
    if (hasHaulingAgentTable && [haulingAgentCode length] > 0 && pricingMode >= 0)
    {
        
        //auto inventory nav items should be gone if "Standard" inventory type is selected...
        NSString *autoSelection = @"";
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        if (cust.inventoryType == 0)
            autoSelection = [cmd stringByAppendingFormat:@"AND i.NavItemID <> 62 AND i.NavItemID <> 63 AND i.NavItemID <> 64 AND i.NavItemID <> 65 AND i.NavItemID <> 79 AND i.NavItemID <> 80 "];
        else if (cust.inventoryType == 1)
            autoSelection = [cmd stringByAppendingFormat:@"AND (i.NavItemID = 62 OR i.NavItemID = 63 OR i.NavItemID = 64 OR i.NavItemID = 65 OR i.NavItemID = 79 OR i.NavItemID = 80) "];
                
        cmd = [NSString stringWithFormat:@"SELECT i.NavItemID,i.NavDescription,v.ItemCategory,i.ReportID,i.SignatureID,i.ReportNotesType, i.SortKey "
               "FROM PVOVanlines v,PVONavItems i "
               "WHERE v.IncludedPVOItem = i.NavItemID AND v.VanlineID IN(0,%1$d) "
               " AND i.DriverType IN(0,%3$d) "
               " %4$@ "
               " %5$@ "
               " UNION "
               " SELECT i.NavItemID, i.NavDescription, i.ReportNotesType, h.ItemCategory, i.ReportID, i.SignatureID, i.SortKey "
               " FROM PVOHaulingAgents h, PVONavItems i "
               " WHERE h.IncludedPVOItem = i.NavItemID AND h.VanlineID IN(0,%1$d) AND h.HaulingAgentCode = '%2$@'"
               " AND i.DriverType IN (0,%3$d) " ,
               vanlineID,
               haulingAgentCode,
               driverType,
               (sourcedFromServer ? @"" : @" AND i.ReportID <> 26 AND i.NavItemID <> 56 "),
               autoSelection];
        
        
        cmd = [cmd stringByAppendingFormat:@"ORDER BY i.SortKey ASC"];
        
    }
    else
    {
        cmd = [NSString stringWithFormat:@"SELECT i.NavItemID,i.NavDescription,v.ItemCategory%@%@%@ "
                     "FROM PVOVanlines v,PVONavItems i "
                     "WHERE v.IncludedPVOItem = i.NavItemID AND v.VanlineID IN(0,%d) ",
                     reportID == nil ? @"" : reportID,
                     signatureID == nil ? @"" : signatureID,
                     reportNotesTypeID == nil ? @"" : reportNotesTypeID,
                     vanlineID];
        
        //added driver type == -1 for downloading reports at app initiation.
        //at this point, we don't know if it is a driver or packer, and want to be sure we have all possible reports.
        //this could potentially return duplicate records? - accounted for below
        if ([self columnExists:@"DriverType" inTable:@"PVONavItems"] && driverType != -1)
        {
            if (![AppFunctionality disableRiderExceptions])
                cmd = [cmd stringByAppendingFormat:@"AND (i.SignatureID = '16' OR i.DriverType IN(0,%d)) ", driverType];
            else
                cmd = [cmd stringByAppendingFormat:@"AND i.DriverType IN(0,%d) ", driverType];
        }
        
        if (!sourcedFromServer)
        {//remove BOL detail and reports if not downlaoded order
            cmd = [cmd stringByAppendingFormat:@"AND i.ReportID <> 26 AND i.NavItemID <> 56 "];
        }
        
        //auto inventory nav items should be gone if "Standard" inventory type is selected...
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        if (cust.inventoryType == 0)
            cmd = [cmd stringByAppendingFormat:@"AND i.NavItemID <> 62 AND i.NavItemID <> 63 AND i.NavItemID <> 64 AND i.NavItemID <> 65 AND i.NavItemID <> 79 AND i.NavItemID <> 80 "];
        else if (cust.inventoryType == 1)
            cmd = [cmd stringByAppendingFormat:@"AND (i.NavItemID = 62 OR i.NavItemID = 63 OR i.NavItemID = 64 OR i.NavItemID = 65 OR i.NavItemID = 79 OR i.NavItemID = 80) "];
        
        cmd = [cmd stringByAppendingFormat:@"ORDER BY i.%@ ASC", [self columnExists:@"SortKey" inTable:@"PVONavItems"] ? @"SortKey" : @"NavItemID"];
    }
    
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSMutableArray *array = [retval objectForKey:
                                     [NSNumber numberWithInt:sqlite3_column_int(stmnt, 2)]];
            if(array == nil)
                array = [[NSMutableArray alloc] init];
            
            PVONavigationListItem *item = [[PVONavigationListItem alloc] init];
            item.navItemID = sqlite3_column_int(stmnt, 0);
            item.display = [SurveyDB stringFromStatement:stmnt columnID:1];
            item.reportTypeID = reportID == nil ? [PVONavigationListItem reportIDForNavID:item.navItemID] : sqlite3_column_int(stmnt, 3);
            item.signatureIDs = signatureID == nil ? [PVONavigationListItem signatureIDForNavID:item.navItemID] : [SurveyDB stringFromStatement:stmnt columnID:4];
            item.reportNoteType = reportNotesTypeID == nil ? -1 : sqlite3_column_int(stmnt, 5);
            
            //override description if present
            if (item.navItemID > 0 && hasNavItemOverride && [self columnExists:@"NavDescription" inTable:@"PVONavItemsOverride"])
            {
                [self getNavItemOverrideDisplay:item];
            }
            
            // hauling agent nav items
            if (item.navItemID > 0 && hasHaulingAgentTable && [haulingAgentCode length] > 0 && pricingMode >= 0)
            {
                [self getHaulingAgentItemOverride:item withHaulingAgentCode:haulingAgentCode withPricingMode:pricingMode];
            }
            
            //make sure the item doesn't already exist
            BOOL found = NO;
            for (PVONavigationListItem *i in array) {
                if(i.navItemID == item.navItemID)
                {
                    found = YES;
                    break;
                }
            }
            
            if(!found)
            {
                [array addObject:item];
                
                [retval setObject:array forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 2)]];
            }
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSDictionary*)getPVOListItemsNew:(int)driverType withSourcedFromServer:(BOOL)sourcedFromServer withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode
{// I got tired of having to support super old tariffs. If the code hits this it means the user has the latest schema of pricing db and we don't have to cram code in all messy. but it does mean that fixes / updates have to go in both.
    //Theres three tables being unioned on this method. PVOVanlines_Dynamic is used to Add/Remove certain nav items depending on the current pricing mode.
    
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    
    int vanlineID = [self vanline];
    NSString *cmd = @"";
    
//#ifdef TARGET_IPHONE_SIMULATOR
//    //allows me to see all the options when debuging instead of having to download one //this macro doesn't seem to work anymore
//    sourcedFromServer = YES;
//#endif
    
    //auto inventory nav items should be gone if "Standard" inventory type is selected...
    NSString *autoSelection = @"";
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    SurveyCustomer *cust = nil;
    NSString *intraStateQuery = @"";
    int inventoryType = -1;
    int loadType = -1;
    
    if (del.customerID > 0)
    {
        cust = [del.surveyDB getCustomer:del.customerID];
        
        inventoryType = cust.inventoryType;
        
        PVOInventory *data = [del.surveyDB getPVOData:cust.custID];
        loadType = data.loadType;
        
        NSArray *origLocs = [del.surveyDB getCustomerLocations:cust.custID atOrigin:YES];
        SurveyLocation *origin = [origLocs objectAtIndex:0];
        
        NSArray *destLocs = [del.surveyDB getCustomerLocations:cust.custID atOrigin:NO];
        SurveyLocation *dest = [destLocs objectAtIndex:0];
        
        if ([origin.state length] > 0 && [dest.state length] > 0 && [origin.state isEqualToString:dest.state])
        {
            NSString *intraStateToCheck = origin.state;
            intraStateQuery = [NSString stringWithFormat:@" AND (vpm.IntraState IS NULL OR vpm.IntraState = '%@')", intraStateToCheck];
        }
        else
        {
            intraStateQuery = @"AND vpm.IntraState IS NULL";
        }
        
        
        
    }
    
    
#ifndef DEBUG
    if (inventoryType == 0)
        autoSelection = [cmd stringByAppendingFormat:@"AND i.NavItemID <> 62 AND i.NavItemID <> 63 AND i.NavItemID <> 64 AND i.NavItemID <> 65 AND i.NavItemID <> 79 AND i.NavItemID <> 80 "];
    else if (inventoryType)
        autoSelection = [cmd stringByAppendingFormat:@"AND (i.NavItemID = 62 OR i.NavItemID = 63 OR i.NavItemID = 64 OR i.NavItemID = 65 OR i.NavItemID = 79 OR i.NavItemID = 80) "];
#endif
    //part 1 was selecting from pvovanlines, which is no longer needed.  It was removed.
    NSString *part2 = [NSString stringWithFormat:@"SELECT i.NavItemID, i.NavDescription, h.ItemCategory AS Category, i.ReportID, i.SignatureID, i.ReportNotesType, i.SortKey "
                       " FROM PVOHaulingAgents h, PVONavItems i "
                       " WHERE h.IncludedPVOItem = i.NavItemID AND h.VanlineID IN(0,%d) "
                       " AND (h.HaulingAgentCode IS NULL OR h.HaulingAgentCode = '%@') "
                       " AND i.DriverType IN (0,%d) ",
                       vanlineID, haulingAgentCode, driverType];
    
    NSString *part3 = [NSString stringWithFormat:@"SELECT i.NavItemID, i.NavDescription, vpm.ItemCategory AS Category, i.ReportID, i.SignatureID, i.ReportNotesType, i.SortKey "
                       " FROM PVOVanlines_Dynamic vpm, PVONavItems i "
                       " WHERE vpm.IncludedPVOItem = i.NavItemID AND vpm.VanlineID IN(0,%d) "
                       " %@ "
                       " AND COALESCE(vpm.PricingMode,%d) = %d AND COALESCE(vpm.LoadType,%d) = %d %@ "
                       " AND i.DriverType IN (0,%d) ",
                       vanlineID, ([AppFunctionality hideHiddenReports ] ? @" AND vpm.Hidden = 0" : @""), pricingMode, pricingMode,
                       loadType, loadType, intraStateQuery, driverType];
    
    cmd = [NSString stringWithFormat:@"%@ UNION %@ ORDER BY Category, i.SortKey ASC", part2, part3];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            NSMutableArray *array = [retval objectForKey:
                                     [NSNumber numberWithInt:sqlite3_column_int(stmnt, 2)]];
            if(array == nil)
                array = [[NSMutableArray alloc] init];
            
            PVONavigationListItem *item = [[PVONavigationListItem alloc] init];
            item.navItemID = sqlite3_column_int(stmnt, 0);
            item.display = [SurveyDB stringFromStatement:stmnt columnID:1];
            item.itemCategory = sqlite3_column_int(stmnt, 2);
            item.reportTypeID = sqlite3_column_int(stmnt, 3);
            item.signatureIDs = [SurveyDB stringFromStatement:stmnt columnID:4];
            item.reportNoteType = sqlite3_column_int(stmnt, 5);
            
            //override description if present
            if (item.navItemID > 0)
            {
                [self getNavItemOverrideDisplay:item];
            }
            
            // hauling agent nav items
            if (item.navItemID > 0 && [haulingAgentCode length] > 0 && pricingMode >= 0)
            {
                [self getHaulingAgentItemOverride:item withHaulingAgentCode:haulingAgentCode withPricingMode:pricingMode];
            }
            
            //make sure the item doesn't already exist
            BOOL found = NO;
            for (PVONavigationListItem *i in array) {
                if(i.navItemID == item.navItemID)
                {
                    found = YES;
                    break;
                }
            }
            
            //add it to the array if needed
            if(!found && ![self getShouldHideForMinApplicationVersion:item] && ![self getShouldHideForPricingMode:item withPricingMode:pricingMode] &&
               ![self shouldHideForHaulingAgent:item withHaulingAgentCode:haulingAgentCode])
            {
                [array addObject:item];
                
                [retval setObject:array forKey:[NSNumber numberWithInt:sqlite3_column_int(stmnt, 2)]];
            }
            
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)getShouldHideForPricingMode:(PVONavigationListItem*)item withPricingMode:(int)pricingMode
{
    //PVOVanline_PricingMode has a flag to hide items for a vanline if they don't apply to a pricing mode. We do this to hide the base vanline reports on newer versions of the app without effecting users on older versions
    
    sqlite3_stmt *innerStmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT Hidden FROM PVOVanlines_Dynamic WHERE IncludedPVOItem = %d AND VanlineID = %d AND PricingMode = %d", item.navItemID, vanline, pricingMode]
                 withStatement:&innerStmnt])
    {
        if (sqlite3_step(innerStmnt) == SQLITE_ROW && sqlite3_column_type(innerStmnt, 0) != SQLITE_NULL)
        {
            int hidden = sqlite3_column_int(innerStmnt, 0);
            return hidden == 1;
        }
    }
    sqlite3_finalize(innerStmnt);
    
    return FALSE;
}

-(BOOL)shouldHideForHaulingAgent:(PVONavigationListItem*)item withHaulingAgentCode:(NSString*) haulingAgentCode {
    sqlite3_stmt *innerStmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT HaulingAgentCode FROM PVOVanlines_Dynamic WHERE IncludedPVOItem = %d AND VanlineID = %d", item.navItemID, vanline] withStatement:&innerStmnt]) {
    
        while (sqlite3_step(innerStmnt) == SQLITE_ROW) {
            NSString *agent = [SurveyDB stringFromStatement:innerStmnt columnID:0];
            if (agent == nil || [agent isEqualToString:haulingAgentCode]) {
                return NO;
                break;
            }
        }
        return YES;
    }
    return NO;
}

-(BOOL)getShouldHideForMinApplicationVersion:(PVONavigationListItem*)item
{
    //PVOVanline_PricingMode has a flag to hide items for a vanline if they don't apply to a pricing mode. We do this to hide the base vanline reports on newer versions of the app without effecting users on older versions
    
    sqlite3_stmt *innerStmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT MinApplicationVersion FROM PVOVanlines_Dynamic WHERE IncludedPVOItem = %d AND VanlineID = %d AND Hidden = 0", item.navItemID, vanline]
                 withStatement:&innerStmnt])
    {
        if (sqlite3_step(innerStmnt) == SQLITE_ROW && sqlite3_column_type(innerStmnt, 0) != SQLITE_NULL)
        {
            NSString* requiredVersion = [SurveyDB stringFromStatement:innerStmnt columnID:0];
            NSString* actualVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            
            if ([requiredVersion compare:actualVersion options:NSNumericSearch] == NSOrderedDescending) {
                return TRUE;
            }
        }
    }
    sqlite3_finalize(innerStmnt);
    
    return FALSE;
}

-(void)getNavItemOverrideDisplay:(PVONavigationListItem*)item
{
    
    sqlite3_stmt *innerStmnt;
    if ([self prepareStatement:[NSString stringWithFormat:@"SELECT NavDescription FROM PVONavItemsOverride WHERE NavItemID = %d AND VanlineID = %d AND NavItemID > 0 ", item.navItemID, vanline]
                 withStatement:&innerStmnt])
    {
        if (sqlite3_step(innerStmnt) == SQLITE_ROW && sqlite3_column_type(innerStmnt, 0) != SQLITE_NULL)
            item.display = [SurveyDB stringFromStatement:innerStmnt columnID:0];
    }
    sqlite3_finalize(innerStmnt);
    
}

-(void)getHaulingAgentItemOverride:(PVONavigationListItem*)item withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode
{
    sqlite3_stmt *innerStmnt;
    NSString *cmd2 = [NSString stringWithFormat:@"SELECT NavDescription, ReportID, SignatureID FROM PVONavItemsOverride WHERE HaulingAgentOverrideNavItemID = %d AND HaulingAgentCode = '%@' AND PricingMode = %d", item.navItemID, haulingAgentCode, pricingMode];
    if ([self prepareStatement:cmd2
                 withStatement:&innerStmnt])
    {
        if (sqlite3_step(innerStmnt) == SQLITE_ROW)
        {
            if (sqlite3_column_type(innerStmnt, 0) != SQLITE_NULL)
                item.display = [SurveyDB stringFromStatement:innerStmnt columnID:0];
            if (sqlite3_column_type(innerStmnt, 1) != SQLITE_NULL)
                item.reportTypeID = sqlite3_column_int(innerStmnt, 1);
            if (sqlite3_column_type(innerStmnt, 2) != SQLITE_NULL)
                item.signatureIDs = [SurveyDB stringFromStatement:innerStmnt columnID:2];
        }
        
    }
    sqlite3_finalize(innerStmnt);
}

-(NSArray*)getPVOCategoriesFromIDs:(NSArray*)ids
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    NSString *strID = @"";
    for (NSNumber *num in ids) {
        if([strID isEqualToString:@""])
            strID = [strID stringByAppendingFormat:@"%d", [num intValue]];
        else
            strID = [strID stringByAppendingFormat:@",%d", [num intValue]];
    }
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT ID,CategoryName "
                     "FROM PVONavCategories "
                     "WHERE ID IN(%@) "
                     "ORDER BY SortKey ASC", strID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVONavigationCategory *cat = [[PVONavigationCategory alloc] init];
            cat.categoryID = sqlite3_column_int(stmnt, 0);
            cat.description = [SurveyDB stringFromStatement:stmnt columnID:1];
            [retval addObject:cat];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(int)getReportNotesTypeForPVONavItemID:(int)navItemID
{
    int reportNotesType = -1;
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT date  "
                               "FROM PVOVanlines v,PVONavItems i "
                               "WHERE v.IncludedPVOItem = i.NavItemID AND i.NavItemID = %d AND v.VanlineID IN(0,%d) ", navItemID, [self vanline]] withStatement:&stmnt])
    {
        if (sqlite3_step(stmnt) == SQLITE_ROW)
            reportNotesType = sqlite3_column_int(stmnt, 0);
    }
    return reportNotesType;
}

-(NSString*)pvoEsignAlertRequired
{
    NSString *retval = nil;
    
    if(![self tableExists:@"PVOEsign"])
        return nil;
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:[NSString stringWithFormat:@"SELECT EsignText FROM PVOEsign WHERE VanlineID IN(0,%d)", [self vanline]]
                withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)pvoContainsNavItem:(int)itemID
{
    return [self getIntValueFromQuery:
            [NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOVanlines WHERE IncludedPVOItem = %d AND VanlineID IN(0,%d)", itemID, [self vanline]]] > 0;
}

-(NSArray*)getPVOAttachDocItems:(int)navItemID withDriverType:(int)driverType
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT PVOAttachDocumentID,NavItemID,DocDescription,DriverType "
                     "FROM PVOAttachDocuments "
                     "WHERE NavItemID IN (0,%d) AND DriverType IN(0,%d)"
                     "ORDER BY DocDescription COLLATE NOCASE", navItemID, driverType];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            PVOAttachDocItem* item = [[PVOAttachDocItem alloc] init];
            item.attachDocID = sqlite3_column_int(stmnt, 0);
            item.navItemID = sqlite3_column_int(stmnt, 1);
            item.description = [SurveyDB stringFromStatement:stmnt columnID:2];
            item.driverType = sqlite3_column_int(stmnt, 3);
            [retval addObject:item];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
    
}

-(BOOL)pvoNavItemHasReportSections:(int)pvoNavID
{
    if ([self tableExists:@"PVOReportDataSections"] && [self columnExists:@"NavItemID" inTable:@"PVOReportDataSections"])
    {
        NSString *hiddenSelect = @"";
        
        if ([self columnExists:@"Hidden" inTable:@"PVOReportDataSections"])
        {
            hiddenSelect = @" AND Hidden = 0";
        }
        
        return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOReportDataSections "
                                           "WHERE NavItemID = %d %@", pvoNavID, hiddenSelect]] > 0;
        
    }
    return NO;
}

-(NSArray*)getPVOReportSections:(int)pvoNavID
{
    NSMutableArray *retval = nil;
    
    NSString *hiddenSelect = @"";
    
    if ([self columnExists:@"Hidden" inTable:@"PVOReportDataSections"])
    {
        hiddenSelect = @" AND Hidden = 0";
    }
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT NavItemID, ReportID, ReportSectionID, SectionName "
                     "FROM PVOReportDataSections "
                     "WHERE NavItemID = %d%@ "
                     "ORDER BY SortKey ASC", pvoNavID, hiddenSelect];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(retval == nil)
                retval = [[NSMutableArray alloc] init];
            
            PVODynamicReportSection *section = [[PVODynamicReportSection alloc] init];
            section.navItemID = sqlite3_column_int(stmnt, 0);
            section.reportID = sqlite3_column_int(stmnt, 1);
            section.reportSectonID = sqlite3_column_int(stmnt, 2);
            section.sectionName = [SurveyDB stringFromStatement:stmnt columnID:3];
            [retval addObject:section];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSArray*)getPVOReportEntries:(int)pvoReportID forSection:(int)sectionID
{
    NSMutableArray *retval = nil;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT ReportID, DataSectionID, DataEntryID, EntryType, EntryName, DefaultValue, DateTimeGroup "
                     "FROM PVOReportDataEntries "
                     "WHERE ReportID = %d AND DataSectionID = %d "
                     "ORDER BY SortKey ASC", pvoReportID, sectionID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(retval == nil)
                retval = [[NSMutableArray alloc] init];
            
            PVODynamicReportEntry *entry = [[PVODynamicReportEntry alloc] init];
            entry.reportID = sqlite3_column_int(stmnt, 0);
            entry.dataSectionID = sqlite3_column_int(stmnt, 1);
            entry.dataEntryID = sqlite3_column_int(stmnt, 2);
            entry.entryDataType = sqlite3_column_int(stmnt, 3);
            entry.entryName = [SurveyDB stringFromStatement:stmnt columnID:4];
            entry.defaultValue = [SurveyDB stringFromStatement:stmnt columnID:5];
            entry.dateTimeGroup = sqlite3_column_int(stmnt, 6);
            [retval addObject:entry];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}


-(NSString*)getPVOSignatureDescription:(int)signatureID
{
    NSString *retval = @"";
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT Description "
                     "FROM PVOSignatureTypes "
                     "WHERE PVOSignatureID = %d ", signatureID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)pvoNavItemHasConfirmation:(int)pvoNavID
{
    if(![self tableExists:@"PVOConfirmPrompts"])
        return FALSE;
    
    return [self getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM PVOConfirmPrompts "
                                       "WHERE NavItemID = %d ", pvoNavID]] > 0;
}

-(NSArray*)getPVOMultipleChoiceOptions:(int)reportID inSection:(int)sectionID forEntry:(int)entryID
{
    NSMutableArray *retval = nil;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT Choice "
                     "FROM PVOReportDataMultipleChoiceOptions "
                     "WHERE ReportID = %d AND SectionID = %d AND EntryID = %d", reportID, sectionID, entryID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(retval == nil)
                retval = [[NSMutableArray alloc] init];
            
            [retval addObject:[SurveyDB stringFromStatement:stmnt columnID:0]];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(PVOConfirmationDetails*)getPVOConfirmationDetails:(int)pvoNavID
{
    
    PVOConfirmationDetails *retval = nil;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT NavItemID,ConfirmationText,ContinueButton,CancelButton FROM PVOConfirmPrompts "
                     "WHERE NavItemID = %d ", pvoNavID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [[PVOConfirmationDetails alloc] init];
            
            retval.navItemID = sqlite3_column_int(stmnt, 0);
            retval.confirmationText = [SurveyDB stringFromStatement:stmnt columnID:1];
            retval.continueButtonText = [SurveyDB stringFromStatement:stmnt columnID:2];
            retval.cancelButtonText = [SurveyDB stringFromStatement:stmnt columnID:3];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(BOOL)doesVanlineSupportCRM:(int)vanlineID
{
    if (![self tableExists:@"CRMSettings"])
        return FALSE;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT VanlineID FROM CRMSettings WHERE VanlineID = %d", vanlineID];
    int result = [self getIntValueFromQuery:cmd];
    return result > 0;
}

-(NSString*)getCRMInstanceName:(int)vanlineID
{
    if (![self tableExists:@"CRMSettings"])
        return @"";
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT t.SystemDescription FROM CRMSettings s JOIN CRMSystemTypes t ON s.CRMSystemType = t.TypeID WHERE VanlineID = %d", vanlineID];
    NSString *retval = @"";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)getCRMSyncAddress:(int)vanlineID withEnvironment:(int)selectedEnvironment
{
    if (![self tableExists:@"CRMSettings"])
        return @"";
    
    NSString *syncAddressColumn;
    if (selectedEnvironment == 0) {
        syncAddressColumn = @"DevSyncAddress";
    } else if (selectedEnvironment == 1) {
        syncAddressColumn = @"QASyncAddress";
    } else if (selectedEnvironment == 2) {
        syncAddressColumn = @"ProdSyncAddress";
    } else {
        syncAddressColumn = @"UATSyncAddress";
    }
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT %@ FROM CRMSettings s WHERE VanlineID = %d", syncAddressColumn, vanlineID];
    NSString *retval = @"";
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

//bulky inventory
-(NSArray*)getAllWireframeItems
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (![self tableExists:@"PVOBulkyTypes"])
        return array;
    
    Item *item;
    
    sqlite3_stmt *stmnt;
    NSString *cmd = nil;
    
    //get all available wireframe types, inner join the xref to ensure theres entries available for details
    cmd = [NSString stringWithFormat:@"SELECT bt.PVOBulkyTypeID, bt.PVOBulkyDescription FROM PVOBulkyTypes bt "
                                      "INNER JOIN PVOBulkyEntriesXref xref ON bt.PVOBulkyTypeID = xref.PVOBulkyTypeID "
                                      "GROUP BY bt.PVOBulkyTypeID "
                                      "ORDER BY bt.PVOBulkyDescription COLLATE NOCASE ASC"];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {//using the Item as a placeholder to start testing my sql schema
            item = [[Item alloc] init];
            
            item.cartonBulkyID = sqlite3_column_int(stmnt, 0);
            item.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, 1)];
            
            [array addObject:item];
            
        }
    }
    sqlite3_finalize(stmnt);
    return array;
    
}

-(PVOBulkyEntry*)getPVOBulkyDetailEntryByID:(int)dataEntryID
{
    PVOBulkyEntry *entry = [[PVOBulkyEntry alloc] init];
    if (![self tableExists:@"PVOBulkyEntries"])
        return entry;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT be.PVOBulkyEntryID, be.PVOBulkyEntryTypeID, be.PVOBulkyEntryName "
                     "FROM PVOBulkyEntries be "
                     "INNER JOIN PVOBulkyEntriesXref xref on xref.PVOBulkyEntryID = be.PVOBulkyEntryID "
                     "WHERE be.PVOBulkyEntryID = %d " ,
                     dataEntryID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            entry.dataEntryID = sqlite3_column_int(stmnt, 0);
            entry.entryDataType = sqlite3_column_int(stmnt, 1);
            entry.entryName = [SurveyDB stringFromStatement:stmnt columnID:2];
        }
    }
    sqlite3_finalize(stmnt);
    
    return entry;
}

-(NSArray*)getPVOBulkyDetailEntries:(int)pvoBulkyTypeID
{
    NSMutableArray *retval = nil;
    if (![self tableExists:@"PVOBulkyEntries"])
        return retval;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT be.PVOBulkyEntryID, be.PVOBulkyEntryTypeID, be.PVOBulkyEntryName "
                     "FROM PVOBulkyEntries be "
                     "INNER JOIN PVOBulkyEntriesXref xref on xref.PVOBulkyEntryID = be.PVOBulkyEntryID "
                     "WHERE xref.PVOBulkyTypeID = %d "
                     "ORDER BY be.SortKey ASC", pvoBulkyTypeID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(retval == nil)
                retval = [[NSMutableArray alloc] init];
            
            PVOBulkyEntry *entry = [[PVOBulkyEntry alloc] init];
            
            entry.bulkyTypeID = pvoBulkyTypeID;
            entry.dataEntryID = sqlite3_column_int(stmnt, 0);
            entry.entryDataType = sqlite3_column_int(stmnt, 1);
            entry.entryName = [SurveyDB stringFromStatement:stmnt columnID:2];
            
            [retval addObject:entry];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

-(NSString*)getPVOBulkyTypeDescription:(int)pvoBulkyTypeID
{
    NSString *retval = @"";
    if (![self tableExists:@"PVOBulkyTypes"])
        return retval;
    
    sqlite3_stmt *stmnt;
    
    NSString *cmd = nil;
    
    cmd = [NSString stringWithFormat:@"SELECT bt.PVOBulkyDescription FROM PVOBulkyTypes bt WHERE bt.PVOBulkyTypeID = %d", pvoBulkyTypeID];
    
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        if(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
    
}

-(NSDictionary*)getWireframeTypesForPVOBulkyItemType:(int)pvoBulkyItemTypeID
{
    NSMutableDictionary *retval = nil;
    if (![self tableExists:@"PVOWireframeTypes"])
        return retval;
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT wt.PVOWireframeTypeID, wt.PVOWireframeDescription "
                     "FROM PVOWireframeTypes wt "
                     "INNER JOIN PVOBulkyWireframeTypesXref xref on xref.PVOWireframeTypeID = wt.PVOWireframeTypeID "
                     "WHERE xref.PVOBulkyTypeID = %d "
                     "ORDER BY wt.SortKey ASC", pvoBulkyItemTypeID];
    
    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            if(retval == nil)
                retval = [[NSMutableDictionary alloc] init];
            
            int wireframeTypeID = sqlite3_column_int(stmnt, 0);
            NSString *wireframeDescription = [SurveyDB stringFromStatement:stmnt columnID:1];
            
            [retval setObject:wireframeDescription forKey:[NSNumber numberWithInt:wireframeTypeID]];
            
        }
    }
    sqlite3_finalize(stmnt);
    
    return retval;
}

- (NSString *)getRequiredSignaturesForNavItemID:(int)navItemID pricingMode:(int)pricingMode loadType:(int)loadType itemCategory:(int)itemCategory haulingAgentCode:(NSString *)haulingAgentCode
{
    NSString *retval = nil;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    if (![self columnExists:@"RequiredSignatures" inTable:@"PVOVanlines_Dynamic"])
    {
        return retval;
    }
    
    NSString *cmd = [NSString stringWithFormat:@"SELECT RequiredSignatures FROM PVOVanlines_Dynamic "
                       " WHERE RequiredSignatures IS NOT NULL AND IncludedPVOItem = %d AND VanlineID IN(0,%d) "
                       " %@ "
                       " AND COALESCE(PricingMode,%d) = %d AND COALESCE(LoadType,%d) = %d AND COALESCE(ItemCategory,%d) = %d AND COALESCE(HaulingAgentCode,'%@') = '%@' ",
                       navItemID, [del.pricingDB vanline], ([AppFunctionality hideHiddenReports ] ? @" AND Hidden = 0" : @""), pricingMode, pricingMode,
                       loadType, loadType, itemCategory, itemCategory, haulingAgentCode, haulingAgentCode];

    sqlite3_stmt *stmnt;
    if([self prepareStatement:cmd withStatement:&stmnt])
    {
        while(sqlite3_step(stmnt) == SQLITE_ROW)
        {
            retval = [SurveyDB stringFromStatement:stmnt columnID:0];
        }
    }
    
    sqlite3_finalize(stmnt);
    
    return retval;
}
-(int)getReportIDFromNavID:(int)nID
{
    NSString *cmd = [NSString stringWithFormat:@"SELECT ReportID FROM PVONavItems WHERE NavItemID = %d", nID];
    sqlite3_stmt *stmnt;
    int f = -1;
    if([self prepareStatement:cmd withStatement:&stmnt]) {
        if(sqlite3_step(stmnt) == SQLITE_ROW) {
            f = sqlite3_column_int(stmnt, 0);
        }
    }
    
    sqlite3_finalize(stmnt);
    return f;
}

#pragma mark - Creating Pricing DB From service -
-(NSArray *)getItemArrayFromDictionary:(NSDictionary *)dict forKeyPath:(NSString *)keyPath
{
    NSArray *arr = [dict valueForKeyPath:keyPath];
    if ([arr isKindOfClass:[NSDictionary class]])
    {
        arr = @ [ arr ];
    }
    
    return arr;
}

-(void)recreatePVODatabaseTables:(NSString *)xmlString
{
    [self deleteDB];
    [self createDatabase];
    if (!self.openDB) return;
    
    NSDictionary *dict = [NSDictionary dictionaryWithXMLString:xmlString];
    
    NSArray *crmSettings = [self getItemArrayFromDictionary:dict forKeyPath:@"CRMSettings.CRMSetting"];
    if ([crmSettings count] > 0)
    {
        [self recreateCRMSettingsTable:crmSettings];
    }
    
    NSArray *crmSystemTypes = [self getItemArrayFromDictionary:dict forKeyPath:@"CRMSystemTypes.CRMSystemType"];
    if ([crmSystemTypes count] > 0)
    {
        [self recreateCRMSystemTypesTable:crmSystemTypes];
    }
    
    NSArray *attachDocuments = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOAttachDocuments.PVOAttachDocument"];
    if ([attachDocuments count] > 0)
    {
        [self recreatePVOAttachDocumentsTable:attachDocuments];
    }
    
    NSArray *bulkyEntries = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOBulkyEntries.PVOBulkyEntry"];
    if ([bulkyEntries count] > 0)
    {
        [self recreatePVOBulkyEntriesTable:bulkyEntries];
    }
    
    NSArray *bulkyEntriesXrefs = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOBulkyEntriesXrefs.PVOBulkyEntriesXref"];
    if ([bulkyEntriesXrefs count] > 0)
    {
        [self recreatePVOBulkyEntriesXrefTable:bulkyEntriesXrefs];
    }
    
    NSArray *bulkyTypes = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOBulkyTypes.PVOBulkyType"];
    if ([bulkyTypes count] > 0)
    {
        [self recreatePVOBulkyTypesTable:bulkyTypes];
    }
    
    NSArray *bulkyWireframeTypesXrefs = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOBulkyWireframeTypesXrefs.PVOBulkyWireframeTypesXref"];
    if ([bulkyWireframeTypesXrefs count] > 0)
    {
        [self recreatePVOBulkyWireframeTypesXrefTable:bulkyWireframeTypesXrefs];
    }
    
    NSArray *confirmPrompts = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOConfirmPrompts.PVOConfirmPrompt"];
    if ([confirmPrompts count] > 0)
    {
        [self recreatePVOConfirmPromptsTable:confirmPrompts];
    }
    
    NSArray *esigns = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOEsigns.PVOEsign"];
    if ([esigns count] > 0)
    {
        [self recreatePVOEsignTable:esigns];
    }
    
    NSArray *haulingAgents = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOHaulingAgents.PVOHaulingAgent"];
    if ([haulingAgents count] > 0)
    {
        [self recreatePVOHaulingAgentsTable:haulingAgents];
    }
    
    NSArray *navCategories = [self getItemArrayFromDictionary:dict forKeyPath:@"PVONavCategories.PVONavCategory"];
    if ([navCategories count] > 0)
    {
        [self recreatePVONavCategoriesTable:navCategories];
    }
    
    NSArray *navItems = [self getItemArrayFromDictionary:dict forKeyPath:@"PVONavItems.PVONavItem"];
    if ([navItems count] > 0)
    {
        [self recreatePVONavItemsTable:navItems];
    }
    
    NSArray *navItemOverrides = [self getItemArrayFromDictionary:dict forKeyPath:@"PVONavItemOverrides.PVONavItemOverride"];
    if ([navItemOverrides count] > 0)
    {
        [self recreatePVONavItemOverridesTable:navItemOverrides];
    }
    
    NSArray *pricingModes = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOPricingModes.PVOPricingMode"];
    if ([pricingModes count] > 0)
    {
        [self recreatePVOPricingModesTable:pricingModes];
    }
    
    NSArray *reportDataEntries = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOReportDataEntries.PVOReportDataEntry"];
    if ([reportDataEntries count] > 0)
    {
        [self recreatePVOReportDataEntriesTable:reportDataEntries];
    }
    
    NSArray *reportDataMultipleChoiceOptions = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOReportDataMultipleChoiceOptions.PVOReportDataMultipleChoiceOption"];
    if ([reportDataMultipleChoiceOptions count] > 0)
    {
        [self recreatePVOReportDataMultipleChoiceOptionsTable:reportDataMultipleChoiceOptions];
    }
    
    NSArray *reportDataSections = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOReportDataSections.PVOReportDataSection"];
    if ([reportDataSections count] > 0)
    {
        [self recreatePVOReportDataSectionsTable:reportDataSections];
    }
    
    NSArray *reportDataTypes = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOReportDataTypes.PVOReportDataType"];
    if ([reportDataTypes count] > 0)
    {
        [self recreatePVOReportDataTypesTable:reportDataTypes];
    }
    
    NSArray *signatureTypes = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOSignatureTypes.PVOSignatureType"];
    if ([signatureTypes count] > 0)
    {
        [self recreatePVOSignatureTypesTable:signatureTypes];
    }
    
    NSArray *vanlines = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOVanlines.PVOVanline"];
    if ([vanlines count] > 0)
    {
        [self recreatePVOVanlinesTable:vanlines];
    }
    
    NSArray *vanlinesDynamic = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOVanlinesDynamic.PVOVanlineDynamicRecord"];
    if ([vanlines count] > 0)
    {
        [self recreatePVOVanlinesDynamicTable:vanlinesDynamic];
    }
    
    NSArray *wireframeTypes = [self getItemArrayFromDictionary:dict forKeyPath:@"PVOWireframeTypes.PVOWireframeType"];
    if ([wireframeTypes count] > 0)
    {
        [self recreatePVOWireframeTypesTable:wireframeTypes];
    }

    NSArray *scriptedResponses = [self getItemArrayFromDictionary:dict forKeyPath:@"ScriptedResponses.ScriptedResponse"];
    if ([scriptedResponses count] > 0)
    {
        [self recreateScriptedResponsesTable:scriptedResponses];
    }
    
    [self recreateDbVersion];
}

-(void)recreateCRMSettingsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS CRMSettings"];
    [self updateDB:@"CREATE TABLE CRMSettings ( VanlineID integer, DevSyncAddress char(255), QASyncAddress char(255), ProdSyncAddress char(255), CRMSystemType char(255), UATSyncAddress char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSString *devSyncAddress = dict[@"devSyncAddress"];
        NSString *qaSyncAddress = dict[@"qaSyncAddress"];
        NSString *prodSyncAddress = dict[@"prodSyncAddress"];
        NSString *crmSystemType = dict[@"crmSystemType"];
        NSString *uatSyncAddress = dict[@"uatSyncAddress"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO CRMSettings"
                        "(VanlineID, DevSyncAddress, QASyncAddress, ProdSyncAddress, CRMSystemType, UATSyncAddress)"
                        "VALUES(%@, '%@', '%@', '%@', '%@', '%@')", @(vanlineID), DBSAFE(devSyncAddress), DBSAFE(qaSyncAddress), DBSAFE(prodSyncAddress), DBSAFE(crmSystemType), DBSAFE(uatSyncAddress)]];
    }

    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreateCRMSystemTypesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS CRMSystemTypes"];
    [self updateDB:@"CREATE TABLE CRMSystemTypes ( TypeID integer NOT NULL, SystemDescription char(255) NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger typeID = [dict[@"typeID"] integerValue];
        NSString *systemDescription = dict[@"systemDescription"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO CRMSystemTypes"
                        "(TypeID,SystemDescription)"
                        "VALUES(%@, '%@')", @(typeID), DBSAFE(systemDescription)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOAttachDocumentsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOAttachDocuments"];
    [self updateDB:@"CREATE TABLE PVOAttachDocuments ( PVOAttachDocumentID integer NOT NULL, NavItemID integer NOT NULL, DocDescription char(255), DriverType integer NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoAttachDocumentID = [dict[@"pvoAttachDocumentID"] integerValue];
        NSInteger navItemID = [dict[@"navItemID"] integerValue];
        NSString *docDescription = dict[@"docDescription"];
        NSInteger driverType = [dict[@"driverType"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOAttachDocuments"
                        "(PVOAttachDocumentID,NavItemID,DocDescription,DriverType)"
                        "VALUES(%@, %@, '%@', %@)", @(pvoAttachDocumentID), @(navItemID), DBSAFE(docDescription), @(driverType)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOBulkyEntriesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOBulkyEntries"];
    [self updateDB:@"CREATE TABLE PVOBulkyEntries ( PVOBulkyEntryID integer NOT NULL, PVOBulkyEntryTypeID integer NOT NULL, PVOBulkyEntryName char(255) NOT NULL, SortKey integer NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoBulkyEntryID = [dict[@"pvoBulkyEntryID"] integerValue];
        NSInteger pvoBulkyEntryTypeID = [dict[@"pvoBulkyEntryTypeID"] integerValue];
        NSString *pvoBulkyEntryName = dict[@"pvoBulkyEntryName"];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOBulkyEntries"
                        "(PVOBulkyEntryID, PVOBulkyEntryTypeID, PVOBulkyEntryName, SortKey)"
                        "VALUES(%@, %@, '%@', %@)", @(pvoBulkyEntryID), @(pvoBulkyEntryTypeID), DBSAFE(pvoBulkyEntryName), @(sortKey)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOBulkyEntriesXrefTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOBulkyEntriesXref"];
    [self updateDB:@"CREATE TABLE PVOBulkyEntriesXref ( PVOBulkyTypeID integer NOT NULL, PVOBulkyEntryID integer NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoBulkyTypeID = [dict[@"pvoBulkyTypeID"] integerValue];
        NSInteger pvoBulkyEntryID = [dict[@"pvoBulkyEntryID"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOBulkyEntriesXref"
                        "(PVOBulkyTypeID, PVOBulkyEntryID)"
                        "VALUES(%@, %@)", @(pvoBulkyTypeID), @(pvoBulkyEntryID)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOBulkyTypesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOBulkyTypes"];
    [self updateDB:@"CREATE TABLE PVOBulkyTypes ( PVOBulkyTypeID integer NOT NULL, PVOBulkyDescription char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoBulkyTypeID = [dict[@"pvoBulkyTypeID"] integerValue];
        NSString *pvoBulkyDescription = dict[@"pvoBulkyDescription"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOBulkyTypes"
                        "(PVOBulkyTypeID, PVOBulkyDescription)"
                        "VALUES(%@, '%@')", @(pvoBulkyTypeID), DBSAFE(pvoBulkyDescription)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOBulkyWireframeTypesXrefTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOBulkyWireframeTypesXref"];
    [self updateDB:@"CREATE TABLE PVOBulkyWireframeTypesXref ( PVOBulkyTypeID integer NOT NULL, PVOWireframeTypeID integer NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoBulkyTypeID = [dict[@"pvoBulkyTypeID"] integerValue];
        NSInteger pvoWireframeTypeID = [dict[@"pvoWireframeTypeID"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOBulkyWireframeTypesXref"
                        "(PVOBulkyTypeID, PVOWireframeTypeID)"
                        "VALUES(%@, %@)", @(pvoBulkyTypeID), @(pvoWireframeTypeID)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOConfirmPromptsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOConfirmPrompts"];
    [self updateDB:@"CREATE TABLE PVOConfirmPrompts ( NavItemID smallint, ConfirmationText text, ContinueButton char(255), CancelButton char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger navItemID = [dict[@"navItemID"] integerValue];
        NSString *confirmationText = dict[@"confirmationText"];
        NSString *continueButton = dict[@"continueButton"];
        NSString *cancelButton = dict[@"cancelButton"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOConfirmPrompts"
                        "(NavItemID,ConfirmationText,ContinueButton,CancelButton)"
                        "VALUES(%@, '%@', '%@', '%@')", @(navItemID), DBSAFE(confirmationText), DBSAFE(continueButton), DBSAFE(cancelButton)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOEsignTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOEsign"];
    [self updateDB:@"CREATE TABLE PVOEsign ( VanlineID  smallint, EsignText  text )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSString *esignText = dict[@"esignText"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOEsign"
                        "(VanlineID, EsignText)"
                        "VALUES(%@, '%@')", @(vanlineID), DBSAFE(esignText)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOHaulingAgentsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOHaulingAgents"];
    [self updateDB:@"CREATE TABLE PVOHaulingAgents ( VanlineID smallint, HaulingAgentCode char(255), IncludedPVOItem smallint, ItemCategory smallint )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSString *haulingAgentCode = dict[@"haulingAgentCode"];
        NSInteger includedPVOItem = [dict[@"includedPVOItem"] integerValue];
        NSInteger itemCategory = [dict[@"itemCategory"] integerValue];
       
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOHaulingAgents"
                        "(VanlineID,HaulingAgentCode,IncludedPVOItem,ItemCategory)"
                        "VALUES(%@, '%@', %@, %@)", @(vanlineID), DBSAFE(haulingAgentCode), @(includedPVOItem), @(itemCategory)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVONavCategoriesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVONavCategories"];
    [self updateDB:@"CREATE TABLE PVONavCategories ( ID smallint, CategoryName char(255), SortKey smallint )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoNavCategoryID = [dict[@"pvoNavCategoryID"] integerValue];
        NSString *categoryName = dict[@"categoryName"];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVONavCategories"
                        "(ID, CategoryName, SortKey)"
                        "VALUES(%@, '%@', %@)", @(pvoNavCategoryID), DBSAFE(categoryName), @(sortKey)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVONavItemsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVONavItems"];
    [self updateDB:@"CREATE TABLE PVONavItems (NavItemID integer NOT NULL, NavDescription char(255), SortKey integer, ReportID integer, SignatureID char(255), DriverType integer, ReportNotesType integer )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger driverType = [dict[@"driverType"] integerValue];
        NSString *navDescription = dict[@"navDescription"];
        NSInteger navItemID = [dict[@"navItemID"] integerValue];
        NSInteger reportID = [dict[@"reportID"] integerValue];
        NSInteger reportNotesType = [dict[@"reportNotesType"] integerValue];
        NSString *signatureID = dict[@"signatureID"];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVONavItems"
                    "(NavItemID, NavDescription, SortKey, ReportID, SignatureID, DriverType, ReportNotesType)"
                    "VALUES(%@, '%@', %@, %@, '%@', %@, %@)", @(navItemID), DBSAFE(navDescription), @(sortKey), @(reportID), DBSAFE(signatureID), @(driverType), @(reportNotesType)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVONavItemOverridesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVONavItemsOverride"];
    [self updateDB:@"CREATE TABLE PVONavItemsOverride ( NavItemID integer, NavDescription char(255), VanlineID integer, ReportID integer, SignatureID integer, DriverType integer, PricingMode integer, HaulingAgentCode char(255), HaulingAgentOverrideNavItemID integer )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger navItemID = [dict[@"navItemID"] integerValue];
        NSString *navDescription = dict[@"navDescription"];
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSInteger reportID = [dict[@"reportID"] integerValue];
        NSInteger signatureID = [dict[@"signatureID"] integerValue];
        NSInteger driverType = [dict[@"driverType"] integerValue];
        NSInteger pricingMode = [dict[@"pricingMode"] integerValue];
        NSString *haulingAgentCode = dict[@"haulingAgentCode"];
        NSInteger haulingAgentOverrideNavItemID = [dict[@"haulingAgentOverrideNavItemID"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVONavItemsOverride"
                        "(NavItemID,NavDescription,VanlineID,ReportID,SignatureID,DriverType,PricingMode,HaulingAgentCode,HaulingAgentOverrideNavItemID)"
                        "VALUES(%@, '%@', %@, %@, %@, %@, %@, '%@', %@)", @(navItemID), DBSAFE(navDescription), @(vanlineID), @(reportID), @(signatureID), @(driverType), @(pricingMode), DBSAFE(haulingAgentCode), @(haulingAgentOverrideNavItemID)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOPricingModesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOPricingModes"];
    [self updateDB:@"CREATE TABLE PVOPricingModes ( PricingModeID integer PRIMARY KEY NOT NULL, Description text NOT NULL )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pricingModeID = [dict[@"pricingModeID"] integerValue];
        NSString *description = dict[@"description"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOPricingModes"
                        "(PricingModeID,Description)"
                        "VALUES(%@, '%@')", @(pricingModeID), DBSAFE(description)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOReportDataEntriesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOReportDataEntries"];
    [self updateDB:@"CREATE TABLE PVOReportDataEntries ( ID integer NOT NULL, ReportID integer, DataSectionID integer, DataEntryID integer, SortKey integer, EntryType integer, EntryName char(255), DefaultValue char(255), DateTimeGroup integer, Hidden integer )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger ID = [dict[@"ID"] integerValue];
        NSInteger reportID = [dict[@"reportID"] integerValue];
        NSInteger dataSectionID = [dict[@"dataSectionID"] integerValue];
        NSInteger dataEntryID = [dict[@"dataEntryID"] integerValue];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        NSInteger entryType = [dict[@"entryType"] integerValue];
        NSString *entryName = dict[@"entryName"];
        NSString *defaultValue = dict[@"defaultValue"];
        NSInteger dateTimeGroup = [dict[@"dateTimeGroup"] integerValue];
        NSInteger hidden = [dict[@"hidden"] integerValue];
       
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReportDataEntries"
                        "(ID,ReportID,DataSectionID,DataEntryID,SortKey,EntryType,EntryName,DefaultValue,DateTimeGroup,Hidden)"
                        "VALUES(%@, %@, %@, %@, %@, %@, '%@', '%@', %@, %@)", @(ID), @(reportID), @(dataSectionID), @(dataEntryID), @(sortKey), @(entryType), DBSAFE(entryName), DBSAFE(defaultValue), @(dateTimeGroup), @(hidden)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOReportDataMultipleChoiceOptionsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOReportDataMultipleChoiceOptions"];
    [self updateDB:@"CREATE TABLE PVOReportDataMultipleChoiceOptions ( ReportID integer, SectionID integer, EntryID integer, Choice char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger reportID = [dict[@"reportID"] integerValue];
        NSInteger sectionID = [dict[@"sectionID"] integerValue];
        NSInteger entryID = [dict[@"entryID"] integerValue];
        NSString *choice = dict[@"choice"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReportDataMultipleChoiceOptions"
                        "(ReportID,SectionID,EntryID,Choice)"
                        "VALUES(%@, %@, %@, '%@')", @(reportID), @(sectionID), @(entryID), DBSAFE(choice)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOReportDataSectionsTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOReportDataSections"];
    [self updateDB:@"CREATE TABLE PVOReportDataSections ( ID integer PRIMARY KEY NOT NULL, NavItemID integer, ReportID integer, ReportSectionID integer, SectionName char(255), SortKey integer, Hidden integer, SignatureID char(255), SignatureRequirementType integer )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger ID = [dict[@"ID"] integerValue];
        NSInteger navItemID = [dict[@"navItemID"] integerValue];
        NSInteger reportID = [dict[@"reportID"] integerValue];
        NSInteger reportSectionID = [dict[@"reportSectionID"] integerValue];
        NSString *sectionName = dict[@"sectionName"];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        NSInteger hidden = [dict[@"hidden"] integerValue];
        NSString *signatureId = dict[@"signatureID"];
        NSInteger signatureRequirementType = [dict[@"signatureRequirementType"] integerValue];

        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReportDataSections"
                        "(ID,NavItemID,ReportID,ReportSectionID,SectionName,SortKey,Hidden, SignatureID, SignatureRequirementType)"
                        "VALUES(%@, %@, %@, %@, '%@', %@, %@, %@, %@)", @(ID), @(navItemID), @(reportID), @(reportSectionID), DBSAFE(sectionName), @(sortKey), @(hidden), signatureId, @(signatureRequirementType)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOReportDataTypesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOReportDataTypes"];
    [self updateDB:@"CREATE TABLE PVOReportDataTypes ( ID integer NOT NULL, DataTypeID integer, Description char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger ID = [dict[@"ID"] integerValue];
        NSInteger dataTypeID = [dict[@"dataTypeID"] integerValue];
        NSString *description = dict[@"description"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOReportDataTypes"
                        "(ID,DataTypeID,Description)"
                        "VALUES(%@, %@, '%@')", @(ID), @(dataTypeID), DBSAFE(description)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOSignatureTypesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOSignatureTypes"];
    [self updateDB:@"CREATE TABLE PVOSignatureTypes ( PVOSignatureID smallint, Description char(255) )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoSignatureID = [dict[@"pvoSignatureID"] integerValue];
        NSString *description = dict[@"description"];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOSignatureTypes"
                        "(PVOSignatureID, Description)"
                        "VALUES(%@, '%@')", @(pvoSignatureID), DBSAFE(description)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOVanlinesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOVanlines"];
    [self updateDB:@"CREATE TABLE PVOVanlines ( VanlineID smallint, IncludedPVOItem smallint, ItemCategory smallint )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSInteger includedPVOItem = [dict[@"includedPVOItem"] integerValue];
        NSInteger itemCategory = [dict[@"itemCategory"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOVanlines"
                        "(VanlineID, IncludedPVOItem, ItemCategory)"
                        "VALUES(%@, %@, %@)",
                        @(vanlineID), @(includedPVOItem), @(itemCategory)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOVanlinesDynamicTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOVanlines_Dynamic"];
    [self updateDB:@"CREATE TABLE PVOVanlines_Dynamic ( VanlineID smallint, IncludedPVOItem smallint, ItemCategory smallint, PricingMode int, LoadType int, IntraState text, HaulingAgentCode text, MinApplicationVersion text, Hidden int, Brand int, RequiredSignatures text, AdditionalSignatures text )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSInteger includedPVOItem = [dict[@"includedPVOItem"] integerValue];
        NSString *itemCategory = dict[@"itemCategory"];
        NSString *pricingMode = dict[@"pricingMode"];
        NSString *loadType = dict[@"loadType"];
        NSString *intraState = dict[@"intraState"];
        NSString *haulingAgentCode = dict[@"haulingAgentCode"];
        NSString *minApplicationVersion = dict[@"minApplicationVersion"];
        NSInteger hidden = [dict[@"hidden"] integerValue];
        NSInteger brand = [dict[@"brand"] integerValue];
        NSString *requiredSignatures = dict[@"requiredSignatures"];
        NSString *additionalSignatures = dict[@"additionalSignatures"];
        
        if ([itemCategory isEqualToString:@"-1"]) itemCategory = nil;
        if ([pricingMode isEqualToString:@"-1"]) pricingMode = nil;
        if ([loadType isEqualToString:@"-1"]) loadType = nil;
        if ([haulingAgentCode isEqualToString:@"-1"]) haulingAgentCode = nil;
        
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO PVOVanlines_Dynamic"
                         "(VanlineID, IncludedPVOItem, ItemCategory, PricingMode, LoadType, IntraState, "
                         "HaulingAgentCode, MinApplicationVersion, Hidden, Brand, RequiredSignatures, AdditionalSignatures)"
                         "VALUES(%@, %@, %@, %@, %@, %@, %@, '%@', %@, '%@', %@, %@)",
                         @(vanlineID), @(includedPVOItem), itemCategory, pricingMode, loadType,
                         intraState == nil ? @"NULL" : [NSString stringWithFormat:@"'%@'", intraState],
                         haulingAgentCode == nil ? @"NULL" : [NSString stringWithFormat:@"'%@'", haulingAgentCode],
                         DBSAFE(minApplicationVersion), @(hidden), @(brand),
                         requiredSignatures == nil ? @"NULL" : [NSString stringWithFormat:@"'%@'", requiredSignatures],
                         additionalSignatures == nil ? @"NULL" : [NSString stringWithFormat:@"'%@'", additionalSignatures]
                         ];
        
        [self updateDB:cmd];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreatePVOWireframeTypesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS PVOWireframeTypes"];
    [self updateDB:@"CREATE TABLE PVOWireframeTypes (PVOWireframeTypeID integer NOT NULL, PVOWireframeDescription char(255), SortKey integer)"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger pvoWireframeTypeID = [dict[@"pvoWireframeTypeID"] integerValue];
        NSString *pvoWireframeDescription = dict[@"pvoWireframeDescription"];
        NSInteger sortKey = [dict[@"sortKey"] integerValue];
        
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO PVOWireframeTypes"
                        "(PVOWireframeTypeID, PVOWireframeDescription, SortKey)"
                        "VALUES(%@, '%@', %@)", @(pvoWireframeTypeID), DBSAFE(pvoWireframeDescription), @(sortKey)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreateScriptedResponsesTable:(NSArray *)dictArray
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS ScriptedResponses"];
    [self updateDB:@"CREATE TABLE ScriptedResponses ( ID integer NOT NULL, VanlineID integer, ItemName char(255), ItemCube integer, OrderID integer, Question text, Comment text, OptOut integer )"];
    
    for (NSDictionary *dict in dictArray)
    {
        NSInteger scriptedResponseID = [dict[@"scriptedResponseID"] integerValue];
        NSInteger vanlineID = [dict[@"vanlineID"] integerValue];
        NSString *itemName = dict[@"itemName"];
        NSInteger itemCube = [dict[@"itemCube"] integerValue];
        NSInteger orderID = [dict[@"orderID"] integerValue];
        NSString *question = dict[@"question"];
        NSString *comment = dict[@"comment"];
        NSInteger optOut = [dict[@"optOut"] integerValue];
       
        [self updateDB:[NSString stringWithFormat:@"INSERT INTO ScriptedResponses"
                        "(ID,VanlineID,ItemName,ItemCube,OrderID,Question,Comment,OptOut)"
                        "VALUES(%@, %@, '%@', %@, %@, '%@', '%@', %@)", @(scriptedResponseID), @(vanlineID), DBSAFE(itemName), @(itemCube), @(orderID), DBSAFE(question), DBSAFE(comment), @(optOut)]];
    }
    
    [self updateDB:@"END TRANSACTION;"];
}

-(void)recreateDbVersion
{
    [self updateDB:@"BEGIN TRANSACTION;"];
    
    [self updateDB:@"DROP TABLE IF EXISTS DBVersion"];
    [self updateDB:@"CREATE TABLE DBVersion ( VanLineID integer )"];
    
    SurveyAppDelegate *del = SURVEY_APP_DELEGATE;
    
    NSInteger fileAssociationId = [del.surveyDB getActivation].fileAssociationId;
    
    [self updateDB:[NSString stringWithFormat:@"INSERT INTO DBVersion"
                    "(VanLineID)"
                    "VALUES(%@)", @(fileAssociationId)]];
    
    [self updateDB:@"END TRANSACTION;"];
}
@end
