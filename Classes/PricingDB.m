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
@end
