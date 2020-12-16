//
//  SurveyDBUpdater.m
//  Survey
//
//  Created by Lee Zumstein on 1/16/14.
//
//

#import "SurveyDBUpdater.h"
#import "SurveyDB.h"
#import "SurveyAppDelegate.h"
#import "CustomerUtilities.h"

@implementation SurveyDBUpdater

@synthesize db, delegate, success;

+(NSString*)createBackupsSQL
{
    return @"CREATE TABLE Backups (BackupID INTEGER PRIMARY KEY, BackupDate REAL, BackupFolder TEXT)";
}

+(NSString*)createAutoBackupScheduleSQL
{
    return @"CREATE TABLE AutoBackupSchedule (LastBackup REAL, BackupFrequency REAL, NumBackupsToRetain INT, EnableBackup INT)";
}

+(NSString*)createAutoBackupScheduleDefaults
{
    return [NSString stringWithFormat:@"INSERT INTO AutoBackupSchedule(LastBackup, BackupFrequency, NumBackupsToRetain, EnableBackup) VALUES(%f,%d,200,1)",
            [[NSDate date] timeIntervalSince1970], 60 * 60 * 24];
}



-(void)main
{
    self.success = YES;
    
    db.runningOnSeparateThread = YES;
    
    @try
    {
        Item *cItem;
        Room *cRoom;
        NSString *cmd, *strTemp;
        
        if(![db tableExists:@"Versions"])
        {
            //first upgrade
            [db updateDB:@"CREATE TABLE Versions(Major INTEGER, Minor INTEGER)"];
            [db updateDB:@"INSERT INTO Versions VALUES(1,0)"];
            
            cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
                   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
                   "VALUES(%d,%d,'','','','','','','','','','')",
                   DEFAULT_AGENCY_CUST_ID, AGENT_BOOKING];
            [db updateDB:cmd];
            
            cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
                   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
                   "VALUES(%d,%d,'','','','','','','','','','')",
                   DEFAULT_AGENCY_CUST_ID, AGENT_ORIGIN];
            [db updateDB:cmd];
            
            cmd = [[NSString alloc] initWithFormat:@"INSERT INTO CustAgents"
                   "(CustomerID,AgentID,Name,Address,City,State,Zip,Phone,Fax,Email,Code,Contact) "
                   "VALUES(%d,%d,'','','','','','','','','','')",
                   DEFAULT_AGENCY_CUST_ID, AGENT_DESTINATION];
            [db updateDB:cmd];
        }
        
        int maj, min;
        sqlite3_stmt *stmnt;
        cmd = @"SELECT Major,Minor FROM Versions";
        
        if([db prepareStatement:cmd withStatement:&stmnt])
        {
            while(sqlite3_step(stmnt) == SQLITE_ROW)
            {
                maj = sqlite3_column_int(stmnt, 0);
                min = sqlite3_column_int(stmnt, 1);
            }
        }
        
        sqlite3_finalize(stmnt);
        
        if(maj == 1)
        {//MARK: version 2 update
            
            cmd = @"CREATE TABLE Printers(PrinterID INTEGER PRIMARY KEY,"
            "IsDefault INTEGER, Address TEXT, Name TEXT, PrinterKind INTEGER, "
            "IsBonjour INTEGER)";
            [db updateDB:cmd];
            
            cmd = @"CREATE TABLE BonjourSettings(PrinterID INTEGER,"
            "KeyName TEXT, KeyValue TEXT)";
            [db updateDB:cmd];
            
            
            [db updateDB:@"UPDATE Versions SET Major = 2"];
            maj = 2;
        }
        
        if(maj < 3)
        {//MARK: version 3 update
            
            cmd = @"ALTER TABLE InterstatePricing ADD ValueAdd TEXT DEFAULT ''";
            [db updateDB:cmd];
            
            [db updateDB:@"UPDATE Versions SET Major = 3"];
            maj = 3;
            
        }
        
        if(maj < 4)
        {//MARK: version 4 update
            
            cmd = @"CREATE TABLE VanOpChkList (Name TEXT, AgencyCodes TEXT,"
            " Services TEXT, Groups TEXT, Tariff INTEGER, AutoUpdate INTEGER)";
            [db updateDB:cmd];
            
            [db updateDB:@"UPDATE Versions SET Major = 4"];
            maj = 4;
            
        }
        
        if(maj < 5)
        {//MARK: version 5 update
            
            cmd = @"UPDATE Items SET CartonBulkyID = 102 WHERE ItemName LIKE '%TV-Flat%' AND (IsCartonCP = 1 OR IsCartonPBO = 1)";
            [db updateDB:cmd];
            
            [db updateDB:@"UPDATE Versions SET Major = 5"];
            maj = 5;
            
        }
        
        if(maj < 6)
        {//MARK: version 6 update
            
            cmd = @"ALTER TABLE InterstatePricing ADD Arpin50Plus INT DEFAULT 0";
            [db updateDB:cmd];
            
            [db updateDB:@"UPDATE Versions SET Major = 6"];
            maj++;
            
        }
        
        if(maj < 7)
        {//MARK: version 7 update
            
            //add the new rates/services
            [db updateDB:@"ALTER TABLE LocalRatesAcc ADD CWTPack REAL DEFAULT 0"];
            [db updateDB:@"ALTER TABLE LocalRatesAcc ADD CWTUnpack REAL DEFAULT 0"];
            
            [db updateDB:@"ALTER TABLE LocalRatesStorage ADD StoTravelRate REAL DEFAULT 0"];
            [db updateDB:@"ALTER TABLE LocalRatesStorage ADD StoTaxPct REAL DEFAULT 0"];
            
            [db updateDB:@"ALTER TABLE LocalAcc ADD CWTPack INT DEFAULT 0"];
            [db updateDB:@"ALTER TABLE LocalAcc ADD CWTPackWeight INT DEFAULT 0"];
            [db updateDB:@"ALTER TABLE LocalAcc ADD StoTravelTime REAL DEFAULT 0"];
            
            [db updateDB:@"ALTER TABLE LocalPricing ADD PackTravelTime INT DEFAULT 0"];
            [db updateDB:@"ALTER TABLE LocalPricing ADD PackTravelRate REAL DEFAULT 0"];
            
            
            //add the new cartons
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Wd/Speedpack - CP',1,0,0,0,12,500)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Wd/Speedpack - PBO',0,1,0,0,12,500)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Tote Box - CP',1,0,0,0,1.5,501)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Tote Box - PBO',0,1,0,0,1.5,501)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Small Mirror - CP',1,0,0,0,5,502)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Small Mirror - PBO',0,1,0,0,5,502)";
            [db updateDB:cmd];
            
            
            //add the new printer setting for quality...
            
            
            [db updateDB:@"UPDATE Versions SET Major = 7"];
            maj = 7;
            
        }
        
        if(maj < 8)
        {//MARK: version 8 update
            
            //add the new printer setting for quality...
            [db updateDB:@"ALTER TABLE Printers ADD Quality INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 8"];
            maj = 8;
            
        }
        
        if(maj < 9)
        {//MARK: version 9 update
            
            
            [db updateDB:@"CREATE TABLE FreeFVP (CustomerID INTEGER, Applied INTEGER,"
             " AmountApplied REAL, FreeAmount REAL, Rate REAL)"];
            
            //add the new printer setting for quality...
            [db updateDB:@"ALTER TABLE Discounts ADD IsValDiscounted INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 9"];
            maj = 9;
            
        }
        
        if(maj < 10)
        {//MARK: version 10 update
            
            //get rid of item dupes (caused by initial survey db build issue)
            NSArray *items = [db getItemsForV10Upgrade];
            NSMutableArray *ids = [[NSMutableArray alloc] init];
            for(int i = 0; i < [items count]; i++)
            {
                cItem = [items objectAtIndex:i];
                if([db getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM Items WHERE ItemName = '%@'",
                                             [cItem.name stringByReplacingOccurrencesOfString:@"'" withString:@"''"]]] > 1)
                {
                    [ids addObject:[NSNumber numberWithInt:cItem.itemID]];
                }
            }
            
            //loop thru each room to see if it needs removed
            NSArray *rooms = [db getRoomsForV10Upgrade];
            for(int i = 0; i < [rooms count]; i++)
            {
                cRoom = [rooms objectAtIndex:i];
                //search for each item
                for(int j = 0; j < [ids count]; j++)
                {
                    if([db getIntValueFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM MasterItemList WHERE ItemID = %d AND RoomID = %d",
                                                 [[ids objectAtIndex:j] intValue], cRoom.roomID]] > 1)
                    {
                        //delete them all, then re-add only one
                        [db updateDB:[NSString stringWithFormat:@"DELETE FROM MasterItemList WHERE ItemID = %d AND RoomID = %d",
                                      [[ids objectAtIndex:j] intValue], cRoom.roomID]];
                        [db updateDB:[NSString stringWithFormat:@"INSERT INTO MasterItemList(ItemID,RoomID) VALUES(%d,%d)",
                                      [[ids objectAtIndex:j] intValue], cRoom.roomID]];
                    }
                }
            }
            
            
            
            //missing flat wd
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Wardrobe, Flat - CP',1,0,0,0,5,112)";
            [db updateDB:cmd];
            
            cmd = @"INSERT INTO Items(ItemName,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID) "
            "VALUES('Wardrobe, Flat - PBO',0,1,0,0,5,112)";
            [db updateDB:cmd];
            
            
            [db updateDB:@"UPDATE Versions SET Major = 10"];
            maj = 10;
            
        }
        
        
        if(maj < 11)
        {//MARK: version 11 update
            
            [db updateDB:@"CREATE TABLE ReportValues (CustomerID INTEGER, ValueID INTEGER, Option TEXT)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 11"];
            maj = 11;
            
        }
        
        if(maj < 12)
        {//MARK: version 12 update
            
            [db updateDB:@"ALTER TABLE LocalPricing ADD PackSalesTax REAL DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 12"];
            maj++;
            
        }
        
        if(maj < 13)
        {//MARK: version 13 (ipad) update
            
            [db updateDB:@"ALTER TABLE Locations ADD Lat REAL DEFAULT 0"];
            [db updateDB:@"ALTER TABLE Locations ADD Long REAL DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 13"];
            maj++;
        }
        
        if(maj < 14)
        {//MARK: version 14 (bekins) update
            
            [db updateDB:@"ALTER TABLE InterstatePricing ADD IsSmallShipment INT DEFAULT 0"];
            
            [db updateDB:@"CREATE TABLE BekinsAcc (CustomerID INTEGER, LocationID INTEGER, Elevators INTEGER, ElevatorsWeight INTEGER, "
             "Stairs INTEGER, StairsWeight INTEGER, LongCarries INTEGER, LongCarriesWeight INTEGER, PianoElevators INTEGER, "
             "PianoStairsInside INTEGER, PianoStairsOutside INTEGER, AppService INTEGER, AppReservice INTEGER)"];
            
            [db updateDB:@"ALTER TABLE ShipmentInfo ADD Bekins412 INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 14"];
            maj++;
        }
        
        if(maj < 15)
        {//MARK: version 15 (smart items) update
            
            [db updateDB:@"CREATE TABLE SmartItems (SmartItemID INTEGER PRIMARY KEY, ItemID INTEGER, AddNote INT, AddThirdPartyItem INT,"
             " AddMiscItem INT, Note TEXT, ThirdPartyServiceID INT, ThirdPartyLocationID INT, ThirdPartyNote TEXT, MiscItemDescription TEXT,"
             " MiscItemCharge REAL, MiscItemDiscount INT)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 15"];
            maj=15;
            
        }
        
        if(maj < 16)
        {//MARK: version 16 (print color) update
            
            [db updateDB:@"ALTER TABLE Printers ADD Color INT DEFAULT 1"];
            
            [db updateDB:@"UPDATE Versions SET Major = 16"];
            maj = 16;
        }
        
        if(maj < 17)
        {//MARK: version 17 (bekins sync) update
            
            [db updateDB:@"CREATE TABLE BekinsSync (EnableSync INT, UserName TEXT)"];
            
            [db updateDB:@"ALTER TABLE CustomerSync ADD SyncToBekins INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 17"];
        }
        
        if(maj < 30)
        {//MARK: version 30 (PVO) update
            
            [db updateDB:@"CREATE TABLE PVODriverData (VanlineID INT, HaulingAgent TEXT, "
             "SafetyNumber TEXT, DriverName TEXT, DriverNumber TEXT, HaulingAgentEmail TEXT, "
             "DriverEmail TEXT, UnitNumber TEXT, DamageViewPreference INT, EnableRoomConditions INT)"];
            
            [db updateDB:@"ALTER TABLE Dates ADD Inventory REAL"];
            [db updateDB:@"UPDATE Dates SET Inventory = 0"];
            
            [db updateDB:@"CREATE TABLE PVOLoadTypes(LoadTypeID INT, LoadDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (1, 'Commercial')"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (2, 'Household')"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (3, 'Military')"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (4, 'Special Products')"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (5, 'Displays and Exhibits')"];
            [db updateDB:@"INSERT INTO PVOLoadTypes(LoadTypeID, LoadDescription) VALUES (6, 'International')"];
            
            [db updateDB:@"CREATE TABLE PVOColors(ColorID INT, ColorDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (1, 'Red')"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (2, 'Yellow')"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (3, 'Green')"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (4, 'Orange')"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (5, 'Blue')"];
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (6, 'Multi')"];
            
            [db updateDB:@"CREATE TABLE PVOLocations(LocationID INT, LocationDescription TEXT, RequiresLocationSelection INT)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (1, 'Extra Pickup', 1)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (2, 'Overflow', 0)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (3, 'Residence', 1)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (4, 'Self Storage', 0)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (5, 'Van to Van', 0)"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (6, 'Warehouse', 0)"];
            
            
            [db updateDB:@"CREATE TABLE PVOItemLocations(LocationCode INT, LocationDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (1, 'Arm')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (2, 'Bottom')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (3, 'Corner')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (4, 'Front')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (5, 'Left')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (6, 'Leg')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (7, 'Rear')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (8, 'Right')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (9, 'Side')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (10, 'Top')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (11, 'Veneer')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (12, 'Edge')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (13, 'Center')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (14, 'Inside')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (15, 'Seat')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (16, 'Drawer')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (17, 'Door')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (18, 'Shelf')"];
            [db updateDB:@"INSERT INTO PVOItemLocations(LocationCode, LocationDescription) VALUES (19, 'Hardware')"];
            
            [db updateDB:@"CREATE TABLE PVOItemDamage(DamageCode TEXT, DamageDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('BE', 'Bent')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('BR', 'Broken')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('BU', 'Burned')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('CH', 'Chipped')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('D', 'Dented')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('F', 'Faded')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('G', 'Gouged')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('L', 'Loose')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('M', 'Marred')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('MI', 'Mildew')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('MO', 'Motheaten')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('P', 'Peeling')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('R', 'Rubbed')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('RU', 'Rusted')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('SC', 'Scratched')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('SH', 'Short')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('SO', 'Soiled')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('ST', 'Stained')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('S', 'Stretched')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('T', 'Torn')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('W', 'Badly Worn')"];
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('Z', 'Cracked')"];
            
            [db updateDB:@"CREATE TABLE PVORoomFloorTypes (FloorTypeID INT, Description TEXT)"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (1, 'Carpet')"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (2, 'Hardwood')"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (3, 'Laminate Hardwood')"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (4, 'Laminate')"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (5, 'Tile')"];
            [db updateDB:@"INSERT INTO PVORoomFloorTypes(FloorTypeID, Description) VALUES (6, 'Other')"];
            
            
            [db updateDB:@"CREATE TABLE PVOCartonContents(CartonContentID INT, ContentDescription TEXT, "
             "Hidden INT NOT NULL DEFAULT 0)"];
            [self flushCommandsFromFile:@"insert_carton_contents.sql" withProgressHeader:@"Updating Carton Content Items..."];
            
            
            [db updateDB:@"CREATE TABLE PVOInventoryData (CustomerID INT, CurrentLotNumber TEXT, "
             "CurrentTagColor INT, UsingScanner INT, NextItemNumber INT, LoadType INT, "
             "CurrentLocation INT, NoConditions INT, InventoryCompleted INT, DeliveryCompleted INT)"];
            
            
            [db updateDB:@"CREATE TABLE PVOInventoryLoads (PVOLoadID INTEGER PRIMARY KEY, CustomerID INT, "
             "PVOLocationID INT, LocationID INT)"];
            
            //XREF table to associate multiple loads to an unload
            [db updateDB:@"CREATE TABLE PVOInventoryUnloadLoadXref (PVOUnloadID INT, PVOLoadID INT)"];
            
            [db updateDB:@"CREATE TABLE PVOInventoryUnloads (PVOUnloadID INTEGER PRIMARY KEY, CustomerID INT, PVOLocationID INT, LocationID INT)"];
            
            [db updateDB:@"CREATE TABLE PVOInventoryItems (PVOItemID INTEGER PRIMARY KEY, PVOLoadID INT, ItemID INT, RoomID INT, "
             "TagColor INT, CartonContents INT, NoExceptions INT, Quantity INT, "
             "Comments TEXT, LotNumber TEXT, ItemNumber TEXT, ItemIsDeleted INT, ItemIsDelivered INT,"
             "HighValueCost REAL)"];
            
            /*NULL FOR PVOUnloadID if it is load damage...*/
            [db updateDB:@"CREATE TABLE PVOInventoryDamage (PVODamageID INTEGER PRIMARY KEY, PVOItemID INT, "
             "DamageCodes TEXT, LocationCodes TEXT, PVOLoadID INT, PVOUnloadID INT)"];
            
            
            [db updateDB:@"CREATE TABLE PVOInventoryCartonContents (PVOItemID INT, ContentCodes TEXT)"];
            
            [db updateDB:@"CREATE TABLE PVOFavoriteItems (ItemID INT)"];
            
            
            [db updateDB:@"CREATE TABLE PVOSignatures (PVOSignatureID INTEGER PRIMARY KEY, CustomerID INT, "
             "SigTypeID INT, SignatureFileName TEXT, SignatureDate REAL)"];
            
            [db updateDB:@"CREATE TABLE PVOHighValueInitials (PVOHighValueInitialsID INTEGER PRIMARY KEY, PVOItemID INT, "
             "InitialTypeID INT, SignatureFileName TEXT, InitialDate REAL)"];
            
            [db updateDB:@"CREATE TABLE PVORoomConditions (PVORoomConditionID INTEGER PRIMARY KEY, PVOLoadID INT, "
             "RoomID INT, FloorTypeID INT, HasDamage INT, DamageDetail TEXT)"];
            
            
            //add locations id primary key, and LocationType flag...
            [db updateDB:@"CREATE TABLE NewLocations (LocationID INTEGER PRIMARY KEY, "
             "CustomerID INTEGER, LocationType INTEGER, Name TEXT, Address1 TEXT, Address2 TEXT, "
             "City TEXT, State TEXT, Zip TEXT, County TEXT, Country TEXT, IsOrigin INTEGER, "
             "Sequence INTEGER)"];
            
            [db updateDB:@"INSERT INTO NewLocations "
             "(CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,Country"
             ",IsOrigin,Sequence) SELECT "
             "CustomerID,LocationID,Name,Address1,Address2,City,State,Zip,County,Country"
             ",IsOrigin,Sequence "
             "FROM Locations"];
            
            [db updateDB:@"DROP TABLE Locations"];
            [db updateDB:@"ALTER TABLE NewLocations RENAME TO Locations"];
            
            //update location images to use primary key as the sub id...
            cmd = @"SELECT l.CustomerID,l.LocationID,i.SubID FROM Locations l,Images i "
            " WHERE l.CustomerID = i.CustomerID AND PhotoType = 1 AND l.LocationType = i.SubID";
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                while(sqlite3_step(stmnt) == SQLITE_ROW)
                {
                    cmd = [[NSString alloc] initWithFormat:
                           @"UPDATE Images SET SubID = %d "
                           "WHERE CustomerID = %d AND SubID = %d AND PhotoType = 1",
                           sqlite3_column_int(stmnt, 1),
                           sqlite3_column_int(stmnt, 0),
                           sqlite3_column_int(stmnt, 2)];
                    [db updateDB:cmd];
                }
            }
            
            sqlite3_finalize(stmnt);
            
            
            
            [db updateDB:@"CREATE INDEX IDX_PVO_LOAD_ID ON PVOInventoryLoads (PVOLoadID)"];
            [db updateDB:@"CREATE INDEX IDX_PVO_UNLOAD_ID ON PVOInventoryUnloads (PVOUnloadID)"];
            [db updateDB:@"CREATE INDEX IDX_PVO_ITEMS_ID ON PVOInventoryItems (PVOItemID)"];
            [db updateDB:@"CREATE INDEX IDX_PVO_ITEMS_LOAD_ID ON PVOInventoryItems (PVOLoadID)"];
            
            
            
            /*[db updateDB:@"CREATE TABLE NewPhones (PhoneID INTEGER PRIMARY KEY, CustomerID INTEGER, LocationID INTEGER, "
             "TypeID INTEGER, Number TEXT)"];
             
             [db updateDB:@"INSERT INTO NewPhones "
             "(CustomerID, LocationID, TypeID, Number) SELECT "
             "CustomerID, LocationID, TypeID, Number "
             "FROM Locations"];
             
             cmd = @"SELECT CustomerID,LocationID,TypeID,Number FROM Phones";
             if([db prepareStatement:cmd withStatement:&stmnt])
             {
             while(sqlite3_step(stmnt) == SQLITE_ROW)
             {
             cmd = [[NSString alloc] initWithFormat:
             @"UPDATE NewPhones SET LocationID = (SELECT LocationID FROM Locations WHERE CustomerID = %d AND LocationType = %d) "
             "WHERE CustomerID = %d AND LocationID = %d",
             sqlite3_column_int(stmnt, 0),
             sqlite3_column_int(stmnt, 1),
             sqlite3_column_int(stmnt, 0),
             sqlite3_column_int(stmnt, 1)];
             [db updateDB:cmd];
             [cmd release];
             }
             }
             
             [db updateDB:@"DROP TABLE Phones"];
             [db updateDB:@"ALTER TABLE NewPhones RENAME TO Phones"];*/
            
            
            [db updateDB:@"UPDATE Versions SET Major = 30"];
        }
        
        if(maj < 31)
        {//MARK: version 31 (PVO) update
            
            [db updateDB:@"CREATE TABLE PVOInventoryDescriptions (PVODescriptionID INTEGER PRIMARY KEY, PVOItemID INT, "
             "DescriptiveCode TEXT)"];
            
            [db updateDB:@"CREATE TABLE PVODescriptions(DescriptiveCode TEXT, DescriptiveDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('BW', 'Black & White TV')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('DBO', 'Disassembled By Owner')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('C', 'Color TV')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('CP', 'Carrier Packed')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PB', 'Professional Books')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PBO', 'Packed By Owner')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PE', 'Professional Equipment')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PP', 'Professional Papers')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('CD', 'Carrier Disassembled')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('MCU', 'Mechanical Condition Unknown')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('SW', 'Stretch Wrapped')"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('CU', 'Contents & Condition Unknown')"];
            
            
            [db updateDB:@"UPDATE Versions SET Major = 31"];
        }
        
        
        if(maj < 32)
        {//MARK: version 32 (PVO) update
            
            
            [db updateDB:@"ALTER TABLE Items ADD Favorite INT DEFAULT 0"];
            [db updateDB:@"UPDATE Items SET Favorite = 1 WHERE ItemID IN (SELECT ItemID FROM PVOFavoriteItems)"];
            
            [db updateDB:@"DROP TABLE PVOFavoriteItems"];
            
            [db updateDB:@"INSERT INTO PVOColors(ColorID, ColorDescription) VALUES (7, 'White')"];
            
            [db updateDB:@"UPDATE Versions SET Major = 32"];
        }
        
        
        if(maj < 33)
        {//MARK: version 33 (PVO) update
            
            
            [db updateDB:@"ALTER TABLE CustomerSync ADD SyncToPVO INT DEFAULT 0"];
            [db updateDB:@"UPDATE CustomerSync SET SyncToPVO = 0"];
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD DriverPassword TEXT DEFAULT ''"];
            [db updateDB:@"UPDATE PVODriverData SET DriverPassword = ''"];
            
            [db updateDB:@"UPDATE Versions SET Major = 33"];
        }
        
        
        if(maj < 34)
        {//MARK: version 34 (PVO) update
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD DamagesReportViewPreference INT"];
            [db updateDB:@"UPDATE PVODriverData SET DamagesReportViewPreference = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 34"];
        }
        
        
        if(maj < 35)
        {//MARK: version 35 (PVO Claims) update
            
            [db updateDB:@"CREATE TABLE PVOClaims (PVOClaimID INTEGER PRIMARY KEY, CustomerID INT, ClaimDate REAL, "
             "EmployerPaidFor INT, EmployerName TEXT, ShipmentInWarehouse INT, AgencyCode TEXT)"];
            
            [db updateDB:@"CREATE TABLE PVOClaimItems (PVOClaimItemID INTEGER PRIMARY KEY, PVOClaimID INT, PVOItemID INT,"
             "Description TEXT, EstimatedWeight INT, AgeOrDatePurchased TEXT, OriginalCost REAL,"
             "ReplacementCost REAL, EstimatedRepairCost REAL)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 35"];
        }
        
        if(maj < 36)
        {//MARK: version 36 (PVO remove books, listed twice) update
            
            cmd = @"SELECT PVOItemID,ContentCodes FROM PVOInventoryCartonContents";
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                while(sqlite3_step(stmnt) == SQLITE_ROW)
                {
                    strTemp = [SurveyDB stringFromStatement:stmnt columnID:1];
                    if([strTemp rangeOfString:@"8032"].location != NSNotFound)
                    {
                        strTemp = [strTemp stringByReplacingOccurrencesOfString:@"8032" withString:@"8004"];
                        cmd = [NSString stringWithFormat:@"UPDATE PVOInventoryCartonContents SET ContentCodes = '%@' WHERE PVOItemID = %d", strTemp, sqlite3_column_int(stmnt, 0)];
                        [db updateDB:cmd];
                    }
                }
            }
            sqlite3_finalize(stmnt);
            
            [db updateDB:@"DELETE FROM PVOCartonContents WHERE CartonContentID = 8032"];
            
            [db updateDB:@"UPDATE Versions SET Major = 36"];
        }
        
        if(maj < 37)
        {//MARK: version 37 (PVO sync preference) update
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD DriverSyncPreference INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET DriverSyncPreference = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 37"];
        }
        
        if(maj < 38)
        {//MARK: version 38 (PVO carton content bug fix) update
            
            [db updateDB:@"DELETE FROM PVOCartonContents WHERE ContentDescription IS NULL OR ContentDescription = ''"];
            
            [db updateDB:@"UPDATE Versions SET Major = 38"];
        }
        
        if(maj < 39)
        {//MARK: version 39 (PVO carton content bug fix) update
            
            //per email from Brian 8/21/12, tabling these items to a future release.
            //            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('HW', 'Hardware')"];
            //            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('PR', 'Priority')"];
            
            [db updateDB:@"INSERT INTO PVOItemDamage(DamageCode, DamageDescription) VALUES ('CR', 'Crushed')"];
            
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection) VALUES (7, 'Packer''s Inventory', 0)"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD SerialNumber TEXT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD ModelNumber TEXT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD VoidReason TEXT"];
            
            [db updateDB:@"ALTER TABLE ShipmentInfo ADD GBLNumber TEXT"];
            
            /*
             [db updateDB:@"CREATE TABLE PVOInventoryData (CustomerID INT, CurrentLotNumber TEXT, "
             "CurrentTagColor INT, UsingScanner INT, NextItemNumber INT, LoadType INT, "
             "CurrentLocation INT, NoConditions INT, InventoryCompleted INT, DeliveryCompleted INT)"];*/
            
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD TractorNumber TEXT"];
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD TrailerNumber TEXT"];
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD TractorNumber TEXT"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD NewPagePerLot INT"];
            
            [db updateDB:@"CREATE TABLE PVOWeightTicket(CustomerID INT, NetWeight INT, TareWeight INT, GrossWeight INT)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 39"];
        }
        
        if(maj < 40)
        {//MARK: version 40
            
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Cube REAL"];
            
            [db updateDB:@"UPDATE PVOInventoryItems SET Cube = (SELECT Items.Cube FROM Items WHERE Items.ItemID = PVOInventoryItems.ItemID)"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Weight INT"];
            [db updateDB:@"UPDATE PVOInventoryItems SET Weight = 0"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD WeightFactor REAL DEFAULT 7.0"];
            [db updateDB:@"UPDATE PVOInventoryData SET WeightFactor = 7.0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 40"];
        }
        
        
        if(maj < 41)
        {//MARK: version 41
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD QuickInventory INT"];
            [db updateDB:@"UPDATE PVODriverData SET QuickInventory = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 41"];
        }
        
        
        if(maj < 42)
        {//MARK: version 42
            
            [db updateDB:@"CREATE TABLE PVOChangeTracking(CustomerID INT, DataSectionID INT, IsDirty INT)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 42"];
        }
        
        if(maj < 43)
        {//MARK: version 43 (auto backup, may release) updates
            
            cmd = @"CREATE INDEX IF NOT EXISTS IX_MasterItemList_ItemID ON MasterItemList(ItemID)";
            [db updateDB:cmd];
            
            cmd = @"CREATE INDEX IF NOT EXISTS IX_MasterItemList_RoomID ON MasterItemList(RoomID)";
            [db updateDB:cmd];
            
            cmd = @"CREATE INDEX IF NOT EXISTS IX_SurveyedItems_ItemID ON SurveyedItems(ItemId)";
            [db updateDB:cmd];
            
            cmd = @"CREATE INDEX IF NOT EXISTS IX_SurveyedItems_RoomID ON SurveyedItems(RoomId)";
            [db updateDB:cmd];
            
            cmd = @"CREATE INDEX IF NOT EXISTS IX_CubeSheets_CubeSheetID ON CubeSheets(CubeSheetID)";
            [db updateDB:cmd];
            
            cmd = @"CREATE TABLE IF NOT EXISTS AutoBackupSchedule (LastBackup REAL, BackupFrequency REAL, NumBackupsToRetain INT, EnableBackup INT)";
            [db updateDB:cmd];
            
            cmd = [NSString stringWithFormat:@"INSERT INTO AutoBackupSchedule(LastBackup, BackupFrequency, NumBackupsToRetain, EnableBackup) VALUES(%f,%d,25,1)",
                   [[NSDate date] timeIntervalSince1970], 24 * 60 * 60];//once every day, set last backup to now (so it goes an hour before backing up)
            [db updateDB:cmd];
            
            cmd = @"CREATE TABLE IF NOT EXISTS Backups (BackupID INTEGER PRIMARY KEY, BackupDate REAL, BackupFolder TEXT)";
            [db updateDB:cmd];
            
            //get backups and set up existing records...
            NSArray *backups = [CustomerUtilities allBackupFolders];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            for (NSString *folder in backups) {
                if(folder.length == 17)
                    [formatter setDateFormat:@"MM-dd-yyyy hmm a"];
                else
                    [formatter setDateFormat:@"MM-dd-yyyy hhmm a"];
                [db updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate,BackupFolder) VALUES(%f,'%@')",
                              [[formatter dateFromString:folder] timeIntervalSince1970], folder]];
            }
            
            if(![db columnExists:@"ConfirmLotNumber" inTable:@"PVOInventoryData"])
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD ConfirmLotNumber TEXT"];
            
            [db updateDB:@"UPDATE PVOInventoryData SET ConfirmLotNumber = CurrentLotNumber"];
            
            if([db tableExists:@"PVOWeightTicket"])
                [db updateDB:@"DROP TABLE PVOWeightTicket"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOWeightTickets(WeightTicketID INTEGER PRIMARY KEY, CustomerID INT, "
             "GrossWeight INT, TicketDate REAL, Description TEXT, WeightType INT)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOInventoryCartonContentsNew(CartonContentID INTEGER PRIMARY KEY, PVOItemID INT, "
             "ContentCode INT)"];
            
            int records = [db getIntValueFromQuery:@"SELECT COUNT(*) FROM PVOInventoryCartonContents"];
            if(records > 500)
                [self startProgress:@"Updating Contents..."];
            int i = 0;
            cmd = @"SELECT PVOItemID,ContentCodes FROM PVOInventoryCartonContents";
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                while(sqlite3_step(stmnt) == SQLITE_ROW)
                {
                    [self updateProgress:i / (float)records];
                    strTemp = [SurveyDB stringFromStatement:stmnt columnID:1];
                    for (NSString *code in [strTemp componentsSeparatedByString:@","]) {
                        if(code.length > 0)
                        {
                            //insert as a new item.
                            cmd = [[NSString alloc] initWithFormat:@"INSERT INTO PVOInventoryCartonContentsNew(PVOItemID,ContentCode) VALUES(%d,%@)",
                                   sqlite3_column_int(stmnt, 0), code];
                            [db updateDB:cmd];
                            
                        }
                    }
                    i++;
                }
            }
            sqlite3_finalize(stmnt);
            [self endProgress];
            
            [db updateDB:@"DROP TABLE PVOInventoryCartonContents"];
            [db updateDB:@"ALTER TABLE PVOInventoryCartonContentsNew RENAME TO PVOInventoryCartonContents"];
            
            //identify the pvoitems as not associated to a carton content item
            if(![db columnExists:@"CartonContentID" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD CartonContentID INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE PVOInventoryItems SET CartonContentID = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 43"];
        }
        
        if(maj < 44)
        {//MARK: version 44 (auto backup incl images)
            
            if(![db columnExists:@"IncludeImages" inTable:@"AutoBackupSchedule"])
                [db updateDB:@"ALTER TABLE AutoBackupSchedule ADD IncludeImages INT"];
            [db updateDB:@"UPDATE AutoBackupSchedule SET IncludeImages = 1"];
            
            
            [db updateDB:@"UPDATE Versions SET Major = 44"];
        }
        
        if(maj < 45)
        {//MARK: version 45 (AtlasNet 1.0.9 updates)
            
            if(![db columnExists:@"IsCPProvided" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD IsCPProvided INT"];
            [db updateDB:@"UPDATE PVOInventoryItems SET IsCPProvided = 1"];
            
            if(![db columnExists:@"PackingOT" inTable:@"PVOInventoryData"])
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD PackingOT INT"];
            [db updateDB:@"UPDATE PVOInventoryData SET PackingOT = 0"];
            if(![db columnExists:@"PackingType" inTable:@"PVOInventoryData"])
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD PackingType INT"];
            [db updateDB:@"UPDATE PVOInventoryData SET PackingType = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 45"];
        }
        
        if(maj < 46)
        {//MARK: version 46 (lock inventory item feature)
            if (![db columnExists:@"LockedItem" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD LockedItem BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryItems SET LockedItem = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 46"];
        }
        
        if(maj < 47)
        {//MARK: version 47 (aspod table)
            [db updateDB:@"CREATE TABLE IF NOT EXISTS ASPOD ( CustomerID INT, LocationID INT, ShipmentLoadBegin REAL,"
             " ShipmentLoadEnd REAL, ShipmentUnloadBegin REAL, ShipmentUnloadEnd REAL, SingleFamilyDwelling INT, "
             "ExLaborMen INT, ExLaborHours REAL, ExLaborNotes TEXT, OTBeginDate REAL, OTEndDate REAL, OTPacking INT, "
             "WaitTimeMen INT, WaitTimeFreeHours REAL, WaitTimeBegin REAL, WaitTimeEnd REAL, ShuttleAgentProvideLabor TEXT, "
             "ShuttleAgentProvideVan TEXT, ShuttleWeight INT, ShuttleMen INT, ShuttleBegin REAL, ShuttleEnd REAL, "
             "BulkyAutoTruck TEXT, BulkySport TEXT, BulkyMoto TEXT, BulkyTractor TEXT, BulkyPlayhouse TEXT, "
             "BulkyCamper TEXT, BulkySnow TEXT, BulkyTrailer TEXT, BulkyFarm TEXT, BulkyBigScreen TEXT, "
             "BulkyPiano TEXT, BulkyHotTub TEXT, BulkyOther TEXT, WACanoe TEXT, "
             "WABoat TEXT, WATravelCamper TEXT, WABoatTrailer TEXT, WASailboat TEXT, WAOther TEXT, "
             "BFCity TEXT, BFState TEXT, BFZip TEXT, BFCity2 TEXT, BFState2 TEXT, BFZip2 TEXT, MiniStgWeight INT, "
             "MiniStgCity TEXT, MiniStgState TEXT, MiniStgZip TEXT);"];
            
            [db updateDB:@"UPDATE Versions SET Major = 47"];
        }
        
        if(maj < 48)
        {//MARK: version 48
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription) VALUES ('TPD', 'Third Party Disassembled')"];
            
            [db updateDB:@"UPDATE Versions SET Major = 48"];
        }
        
        if(maj < 49)
        {//MARK: version 49 (aspod wait time update)
            if (![db columnExists:@"WaitTimeAuthBy" inTable:@"ASPOD"])
                [db updateDB:@"ALTER TABLE ASPOD ADD WaitTimeAuthBy TEXT"];
            
            [db updateDB:@"UPDATE ASPOD SET WaitTimeAuthBy = '' WHERE WaitTimeAuthBy IS NULL"];
            
            [db updateDB:@"UPDATE Versions SET Major = 49"];
        }
        
        if(![db columnExists:@"ShowTractorTrailerOptions" inTable:@"PVODriverData"])
        {//MARK: version xx (atlasnet optional tractor/trailer) - no versions reqiured, conflicts with doc lib update in trunk
            if (![db columnExists:@"ShowTractorTrailerOptions" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD ShowTractorTrailerOptions INT"];
            [db updateDB:@"UPDATE PVODriverData SET ShowTractorTrailerOptions = 0"];
            
            [db updateDB:@"UPDATE Versions SET Major = 50"];
        }
        
        if(![db tableExists:@"DocumentLibrary"])
        {//MARK: version xx - doc library addition - no versions reqiured, conflicts with doc lib update in trunk
            [db updateDB:@"CREATE TABLE IF NOT EXISTS DocumentLibrary (DocEntryID INTEGER PRIMARY KEY, DocEntryType INT, CustomerID INT, "
             "DocURL TEXT, DocName TEXT, DocPath TEXT, SavedDate REAL, Synchronized INT)"];
            
            [db updateDB:@"UPDATE Versions SET Major = 50"];
        }
        
        
        ////MARK: New stuff for MM 2.0
        
        int ver = 50;
        
        if(maj < ++ver)
        {//MARK: version 51 - (PVO verify inventory) update
            
            [db updateDB:@"CREATE TABLE PVOVerifyInventoryItems(CustomerID INT, SerialNumber TEXT, ArticleName TEXT)"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD VerifyStatus TEXT"];
            
            [db updateDB:@"ALTER TABLE PVOLocations ADD Hidden INT"];
            [db updateDB:@"UPDATE PVOLocations SET Hidden = 0"];
            
            [db updateDB:@"INSERT INTO PVOLocations(LocationID, LocationDescription, RequiresLocationSelection, Hidden) VALUES (8, 'Verify Inventory', 0, 1)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if(maj < ++ver)
        {//MARK: version 52 - (PVO inventory items) update
            
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD InventoriedAfterSignature INT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD HasDimensions INT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Length INT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Width INT"];
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Height INT"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if(maj < ++ver)
        {//MARK: version 53 - (PVO new version alert) update
            
            [db updateDB:@"ALTER TABLE ShipmentInfo ADD SourcedFromServer INT"];
            [db updateDB:@"UPDATE ShipmentInfo SET SourcedFromServer = 0"];
            
            [db updateDB:@"ALTER TABLE ActivationControl ADD NewVersionAlert REAL"];
            [db updateDB:@"UPDATE ActivationControl SET NewVersionAlert = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if(maj < ++ver)
        {//MARK: version 54 - (driver camera save) update
            
            [db updateDB:@"ALTER TABLE PVODriverData ADD SaveToCameraRoll INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET SaveToCameraRoll = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if(maj < ++ver)
        {//MARK: version 55 - packer inventory updates, receivable items
            
            if(![db columnExists:@"DriverType" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD DriverType INT DEFAULT 0"];
            
            [db updateDB:@"UPDATE PVODriverData SET DriverType = 0"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOPackerInitials(Initials TEXT)"];
            
            if(![db columnExists:@"PackerInitials" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD PackerInitials TEXT"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableItems(ReceivableItemID INTEGER PRIMARY KEY, CustomerID INT, ItemID INT, RoomID INT, "
             "Quantity INT, ItemNumber TEXT, LotNumber TEXT, Color INT, Comments TEXT, "
             "ModelNumber TEXT, SerialNumber TEXT, HighValueCost REAL, PackerInitials TEXT NULL, Received BIT NOT NULL DEFAULT 0, "
             "ItemIsDeleted BIT NOT NULL DEFAULT 0, VoidReason TEXT NULL, Delivered BIT NOT NULL DEFAULT 0,"
             "Length INT DEFAULT 0, Width INT DEFAULT 0, Height INT DEFAULT 0, HasDimensions BIT DEFAULT 0, ReceivableCartonContentID INT NULL DEFAULT 0)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableCartonContents(ReceivableCartonContentID INTEGER PRIMARY KEY, ReceivableItemID INT, ContentID INT)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableDescriptions(ReceivableItemID INT, Code TEXT, Description TEXT)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableDamages(ReceivableItemID INT, Damages TEXT, Locations TEXT, IsUnload BIT NOT NULL DEFAULT 0)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableItemsType(CustomerID INT, ReceivedType INT, ReceivedUnloadType INT NOT NULL DEFAULT 0)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if(maj < ++ver)
        {//MARK: version 56 - fix pvo dirty flags for HVI
            [db updateDB:@"DELETE FROM PVOChangeTracking WHERE DataSectionID IN (4,5)"];
            
            [db updateDB:@"INSERT INTO PVOChangeTracking (CustomerID, DataSectionID, IsDirty) SELECT CustomerID, 4, IsDirty FROM PVOChangeTracking WHERE DataSectionID = 1"];
            
            [db updateDB:@"INSERT INTO PVOChangeTracking (CustomerID, DataSectionID, IsDirty) SELECT CustomerID, 5, IsDirty FROM PVOChangeTracking WHERE DataSectionID = 2"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 57 - add add'l fields for service download
            //dates
            if (![db columnExists:@"PackPrefer" inTable:@"Dates"])
            {
                [db updateDB:@"ALTER TABLE Dates ADD PackPrefer DATETIME NULL"];
                [db updateDB:@"UPDATE Dates SET PackPrefer = PackTo"];
            }
            if (![db columnExists:@"LoadPrefer" inTable:@"Dates"])
            {
                [db updateDB:@"ALTER TABLE Dates ADD LoadPrefer DATETIME NULL"];
                [db updateDB:@"UPDATE Dates SET LoadPrefer = LoadTo"];
            }
            if (![db columnExists:@"DeliverPrefer" inTable:@"Dates"])
            {
                [db updateDB:@"ALTER TABLE Dates ADD DeliverPrefer DATETIME NULL"];
                [db updateDB:@"UPDATE Dates SET DeliverPrefer = DeliverTo"];
            }
            //company name
            if (![db columnExists:@"CompanyName" inTable:@"Customer"])
            {
                [db updateDB:@"ALTER TABLE Customer ADD CompanyName TEXT"];
                [db updateDB:@"UPDATE Customer SET CompanyName = ''"];
            }
            //location names for extra Stops
            if (![db columnExists:@"CompanyName" inTable:@"Locations"])
            {
                [db updateDB:@"ALTER TABLE Locations ADD CompanyName TEXT"];
                [db updateDB:@"UPDATE Locations SET CompanyName = ''"];
            }
            if (![db columnExists:@"FirstName" inTable:@"Locations"])
            {
                [db updateDB:@"ALTER TABLE Locations ADD FirstName TEXT"];
                [db updateDB:@"UPDATE Locations SET FirstName = ''"];
            }
            if (![db columnExists:@"LastName" inTable:@"Locations"])
            {
                [db updateDB:@"ALTER TABLE Locations ADD LastName TEXT"];
                [db updateDB:@"UPDATE Locations SET LastName = ''"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 58 - remove all sync flags
            
            [db updateDB:@"UPDATE CustomerSync SET SyncToPVO = 0"]; //clear all sync flags
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 59 - special products
            if (![db columnExists:@"LimitItems" inTable:@"PVOLocations"])
            {
                [db updateDB:@"ALTER TABLE PVOLocations ADD LimitItems INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOLocations SET LimitItems = 0"];
            }
            
            [db updateDB:@"DELETE FROM PVOLocations WHERE LocationID = 9"];
            [db updateDB:@"INSERT INTO PVOLocations(LocationID,LocationDescription,RequiresLocationSelection,Hidden,LimitItems) "
             "VALUES (9,'Commercial',0,1,0)"];
            
            if (![db columnExists:@"PVOLocationID" inTable:@"Rooms"])
            {
                [db updateDB:@"ALTER TABLE Rooms ADD PVOLocationID INT DEFAULT 0"];
                [db updateDB:@"UPDATE Rooms SET PVOLocationID = 0"];
            }
            
            if (![db columnExists:@"PVOLocationID" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD PVOLocationID INT DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET PVOLocationID = 0"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 60 - fix duplicate Master Item List records
            sqlite3_stmt *stmnt;
            NSString *cmd = [NSString stringWithFormat:@"SELECT ItemID,RoomID,COUNT(*) FROM MasterItemList GROUP BY ItemID,RoomID HAVING COUNT(*) > 1"];
            NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
            
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                int itemID, roomID;
                while(sqlite3_step(stmnt) == SQLITE_ROW)
                {
                    itemID = sqlite3_column_int(stmnt, 0);
                    roomID = sqlite3_column_int(stmnt, 1);
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM MasterItemList WHERE ItemID = %d AND RoomID = %d", itemID, roomID]];
                    [updateStatements addObject:[NSString stringWithFormat:@"INSERT INTO MasterItemList(ItemID,RoomID)VALUES(%d,%d)", itemID, roomID]];
                }
            }
            
            for (NSString *upd in updateStatements)
                [db updateDB:upd];
            
            sqlite3_finalize(stmnt);
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        { //MARK: version 61 - hide pvo descriptive symbols, receivable expanded carton contents
            if (![db columnExists:@"Hidden" inTable:@"PVODescriptions"])
            {
                [db updateDB:@"ALTER TABLE PVODescriptions ADD Hidden BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVODescriptions SET Hidden = 0"];
            }
            
            if (![db columnExists:@"PVODriverType" inTable:@"PVODescriptions"])
                [db updateDB:@"ALTER TABLE PVODescriptions ADD PVODriverType INT NOT NULL DEFAULT 0"];
            
            [db updateDB:@"UPDATE PVODescriptions SET PVODriverType = 0 WHERE DescriptiveCode NOT IN('PBO','SW','CU')"];
            [db updateDB:@"UPDATE PVODescriptions SET PVODriverType = 1 WHERE DescriptiveCode IN('PBO','SW','CU')"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 62 - remove orphaned detail Carton Content records
            sqlite3_stmt *stmnt;
            NSString *cmd = [NSString stringWithFormat:@"SELECT DISTINCT(CartonContentID) FROM "
                             "(SELECT CartonContentID,COUNT(CartonContentID) AS idCount FROM PVOInventoryItems WHERE CartonContentID > 0 GROUP BY CartonContentID) "
                             "WHERE idCount > 1 ORDER BY CartonContentID"];
            NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
            
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                int cartonContentID, pvoItemID;
                while(sqlite3_step(stmnt) == SQLITE_ROW)
                {
                    cartonContentID = sqlite3_column_int(stmnt, 0);
                    pvoItemID = [db getIntValueFromQuery:[NSString stringWithFormat:@"SELECT PVOItemID FROM PVOInventoryItems WHERE CartonContentID = %d "
                                                          "ORDER BY PVOItemID DESC LIMIT 1", cartonContentID]]; //keep last record as latest
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM PVOInventoryItems WHERE CartonContentID = %d "
                                                 "AND PVOItemID != %d", cartonContentID, pvoItemID]]; //delete all others
                }
            }
            
            for (NSString *upd in updateStatements)
                [db updateDB:upd];
            
            sqlite3_finalize(stmnt);
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 63 - remove duplicate Carton Content items
            sqlite3_stmt *stmnt;
            NSString *cmd = [NSString stringWithFormat:@"SELECT DISTINCT(TRIM(ContentDescription)) AS descrip, COUNT(*) AS cnt FROM PVOCartonContents"
                             " GROUP BY descrip HAVING COUNT(*) > 1"];
            NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
            
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                NSString *cartonContent, *select;
                while (sqlite3_step(stmnt) == SQLITE_ROW) {
                    cartonContent = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmnt, 0)];
                    //select that gets all duplicate id's
                    select = [NSString stringWithFormat:@"SELECT CartonContentID FROM PVOCartonContents WHERE TRIM(ContentDescription) = %@",
                              [db prepareStringForInsert:cartonContent]];
                    //assign everything to the first duplicate id
                    [updateStatements addObject:[NSString stringWithFormat:@"UPDATE PVOInventoryCartonContents SET ContentCode = (%@ ORDER BY CartonContentID LIMIT 1)"
                                                 " WHERE ContentCode IN(%@)", select, select]];
                    //remove everything except the first id
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM PVOCartonContents WHERE CartonContentID IN("
                                                 "%@ AND CartonContentID != (%@ ORDER BY CartonContentID LIMIT 1))", select, select]];
                }
            }
            
            for (NSString *upd in updateStatements)
                [db updateDB:upd];
            
            sqlite3_finalize(stmnt);
            
            [db updateDB:@"UPDATE PVOCartonContents SET ContentDescription = 'Lamp' WHERE TRIM(ContentDescription) = 'Lam'"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 64 - new Military fields
            if (![db columnExists:@"IsVehicle" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD IsVehicle BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET IsVehicle = 0 WHERE IsVehicle IS NULL"];
            }
            if (![db columnExists:@"IsGun" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD IsGun BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET IsGun = 0 WHERE IsGun IS NULL"];
            }
            if (![db columnExists:@"IsElectronic" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD IsElectronic BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET IsElectronic = 0 WHERE IsElectronic IS NULL"];
            }
            
            if (![db columnExists:@"ItemIsMPRO" inTable:@"PVOInventoryItems"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD ItemIsMPRO BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryItems SET ItemIsMPRO = 0 WHERE ItemIsMPRO IS NULL"];
            }
            if (![db columnExists:@"ItemIsSPRO" inTable:@"PVOInventoryItems"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD ItemIsSPRO BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryItems SET ItemIsSPRO = 0 WHERE ItemIsSPRO IS NULL"];
            }
            if (![db columnExists:@"[Year]" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD [Year] INT NULL"];
            if (![db columnExists:@"Make" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Make TEXT NULL"];
            if (![db columnExists:@"Odometer" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD Odometer INT NULL"];
            if (![db columnExists:@"CaliberOrGauge" inTable:@"PVOInventoryItems"])
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD CaliberOrGauge TEXT NULL"];
            
            if (![db columnExists:@"ItemIsMPRO" inTable:@"PVOReceivableItems"])
            {
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD ItemIsMPRO BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOReceivableItems SET ItemIsMPRO = 0 WHERE ItemIsMPRO IS NULL"];
            }
            if (![db columnExists:@"ItemIsSPRO" inTable:@"PVOReceivableItems"])
            {
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD ItemIsSPRO BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOReceivableItems SET ItemIsSPRO = 0 WHERE ItemIsSPRO IS NULL"];
            }
            if (![db columnExists:@"[Year]" inTable:@"PVOReceivableItems"])
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD [Year] INT NULL"];
            if (![db columnExists:@"Make" inTable:@"PVOReceivableItems"])
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD Make TEXT NULL"];
            if (![db columnExists:@"Odometer" inTable:@"PVOReceivableItems"])
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD Odometer INT NULL"];
            if (![db columnExists:@"CaliberOrGauge" inTable:@"PVOReceivableItems"])
                [db updateDB:@"ALTER TABLE PVOReceivableItems ADD CaliberOrGauge TEXT NULL"];
            
            if (![db columnExists:@"LockLoadType" inTable:@"PVOInventoryData"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD LockLoadType BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryData SET LockLoadType = 0 WHERE LockLoadType IS NULL"];
            }
            
            if (![db columnExists:@"MPROWeight" inTable:@"PVOInventoryData"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD MPROWeight INT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryData SET MPROWeight = 0 WHERE MPROWeight IS NULL"];
            }
            if (![db columnExists:@"SPROWeight" inTable:@"PVOInventoryData"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryData ADD SPROWeight INT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryData SET SPROWeight = 0 WHERE SPROWeight IS NULL"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 65 - add tracking item flag, lock Inventory Item flag
            if (![db columnExists:@"DoneWorking" inTable:@"PVOInventoryItems"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD DoneWorking BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryItems SET DoneWorking = 1"];
            }
            if (![db columnExists:@"LockedItem" inTable:@"PVOInventoryItems"])
            {
                [db updateDB:@"ALTER TABLE PVOInventoryItems ADD LockedItem BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVOInventoryItems SET LockedItem = 0"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 66 - add CC/BCC driver email options
            if (![db columnExists:@"HaulingAgentEmailCC" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD HaulingAgentEmailCC BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET HaulingAgentEmailCC = 0"];
            if (![db columnExists:@"HaulingAgentEmailBCC" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD HaulingAgentEmailBCC BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET HaulingAgentEmailBCC = 0"];
            
            if (![db columnExists:@"DriverEmailCC" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD DriverEmailCC BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET DriverEmailCC = 0"];
            if (![db columnExists:@"DriverEmailBCC" inTable:@"PVODriverData"])
                [db updateDB:@"ALTER TABLE PVODriverData ADD DriverEmailBCC BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVODriverData SET DriverEmailBCC = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 67 - Rider exception changes
            if (![db columnExists:@"DamageType" inTable:@"PVOInventoryDamage"])
                [db updateDB:@"ALTER TABLE PVOInventoryDamage ADD DamageType INT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryDamage SET DamageType = 1 WHERE DamageType IS NULL AND PVOLoadID > 0 AND PVOUnloadID <= 0"]; //loading damage
            [db updateDB:@"UPDATE PVOInventoryDamage SET DamageType = 2 WHERE DamageType IS NULL AND PVOLoadID <= 0 AND PVOUnloadID > 0"]; //unloading damage
            [db updateDB:@"UPDATE PVOInventoryDamage SET DamageType = 1 WHERE DamageType IS NULL"]; //capture any outliers (such as carton content detail items)
            
            if (![db columnExists:@"DamageType" inTable:@"PVOReceivableDamages"])
            {
                [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableDamagesNew(ReceivableItemID INT,Damages TEXT,Locations TEXT,DamageType INT NOT NULL DEFAULT 0)"];
                [db updateDB:@"DELETE FROM PVOReceivableDamagesNew"];
                [db updateDB:@"INSERT INTO PVOReceivableDamagesNew (ReceivableItemID,Damages,Locations,DamageType) SELECT ReceivableItemID,Damages,Locations,"
                 "(CASE WHEN IsUnload IS 1 THEN 2 ELSE 1 END) FROM PVOReceivableDamages"]; //copy stuff over to new table
                
                [db updateDB:@"DROP TABLE PVOReceivableDamages"];
                [db updateDB:@"ALTER TABLE PVOReceivableDamagesNew RENAME TO PVOReceivableDamages"];
            }
            
            if (![db columnExists:@"ReceivedFromPVOLocationID" inTable:@"PVOInventoryLoads"])
                [db updateDB:@"ALTER TABLE PVOInventoryLoads ADD ReceivedFromPVOLocationID INT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryLoads SET ReceivedFromPVOLocationID = 0 WHERE ReceivedFromPVOLocationID IS NULL"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 68 - Report Notes changes
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReportNotes(PVOReportNotesID INTEGER PRIMARY KEY, CustomerID INT NOT NULL, ReportNoteType INT NOT NULL, Notes TEXT)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 69 - Retroactive fixes for defect 1151, dittoed items not saving a damage type
            [db updateDB:@"UPDATE PVOInventoryDamage SET DamageType = 1 WHERE DamageType = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 70 - default rooms, items, master item list
            [self flushCommandsFromFile:@"insert_items.sql" withProgressHeader:@"Updating Items..."]; //flush latest items
            
            //fix items with space in name
            [db updateDB:@"UPDATE Items SET ItemName=TRIM(ItemName) WHERE ItemName IS NOT NULL"];
            
            //remove duplicate items
            sqlite3_stmt *stmnt;
            NSString *cmd = @"SELECT ItemName,COUNT(*) FROM Items GROUP BY ItemName HAVING COUNT(*) > 1";
            NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                NSString *itemName, *select;
                while (sqlite3_step(stmnt) == SQLITE_ROW) {
                    itemName = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmnt, 0)];
                    //select that gets all duplicate id's
                    select = [NSString stringWithFormat:@"SELECT ItemID FROM Items WHERE TRIM(ItemName) = %@",
                              [db prepareStringForInsert:itemName]];
                    //assign everything to the first duplicate id
                    [updateStatements addObject:[NSString stringWithFormat:@"UPDATE SurveyedItems SET ItemID = (%1$@ ORDER BY ItemID LIMIT 1)"
                                                 " WHERE ItemID IN(%1$@)", select]];
                    [updateStatements addObject:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET ItemID = (%1$@ ORDER BY ItemID LIMIT 1)"
                                                 " WHERE ItemID IN(%1$@)", select]];
                    [updateStatements addObject:[NSString stringWithFormat:@"UPDATE PVOReceivableItems SET ItemID = (%1$@ ORDER BY ItemID LIMIT 1)"
                                                 " WHERE ItemID IN(%1$@)", select]];
                    //remove everything except the first id
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM MasterItemList WHERE ItemID IN"
                                                 "(%1$@ AND ItemID != (%1$@ ORDER BY ItemID LIMIT 1))", select]];
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM Items WHERE ItemID IN"
                                                 "(%1$@ AND ItemID != (%1$@ ORDER BY ItemID LIMIT 1))", select]];
                }
            }
            [self flushCommandsFromArray:updateStatements withProgressHeader:@"Updating Items..."];
            sqlite3_finalize(stmnt);
            
            [self flushCommandsFromFile:@"insert_rooms.sql" withProgressHeader:@"Updating Rooms..."]; //flush rooms
            
            //add unique values to MasterItemList table
            BOOL milHasIndex = NO;
            if ([db prepareStatement:@"PRAGMA INDEX_LIST('MasterItemList')" withStatement:&stmnt]) //grab indexes on MasterItemList table
                milHasIndex = (sqlite3_step(stmnt) == SQLITE_ROW);
            sqlite3_finalize(stmnt);
            if (!milHasIndex)
            {
                [db updateDB:@"CREATE TABLE IF NOT EXISTS MasterItemListNew(RoomID INTEGER NOT NULL,ItemID INTEGER NOT NULL,"
                 "UNIQUE(RoomID,ItemID) ON CONFLICT REPLACE)"];
                
                [db updateDB:@"DELETE FROM MasterItemListNew"];
                [db updateDB:@"INSERT OR REPLACE INTO MasterItemListNew(RoomID,ItemID) SELECT RoomID,ItemID FROM MasterItemList"];
                
                [db updateDB:@"DROP TABLE MasterItemList"];
                [db updateDB:@"ALTER TABLE MasterItemListNew RENAME TO MasterItemList"];
            }
            
            //[self flushCommandsFromFile:@"insert_mil.sql" withProgressHeader:@"Updating Master Item List..."]; //flush master item list
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        
        if (maj < ++ver)
        {//MARK: version 71 - prevent Driver Type from Defaulting to 0
            [db updateDB:@"UPDATE PVODriverData SET DriverType = 1 WHERE DriverType = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 72 - hide phone types
            if (![db columnExists:@"IsHidden" inTable:@"PhoneTypes"])
                [db updateDB:@"ALTER TABLE PhoneTypes ADD IsHidden BIT NOT NULL DEFAULT 0"];
            [db updateDB:@"UPDATE PhoneTypes SET IsHidden = 0 WHERE IsHidden IS NULL"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        
        if (maj < ++ver)
        {//MARK: version 73 - fix PVOInventoryCartonContents null CartonContentID values
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOInventoryCartonContentsNew(CartonContentID INTEGER PRIMARY KEY, PVOItemID INT, ContentCode INT)"];
            [db updateDB:@"DELETE FROM PVOInventoryCartonContentsNew"];
            
            //insert the records that aren't duplicates
            [db updateDB:@"INSERT INTO PVOInventoryCartonContentsNew(CartonContentID,PVOItemID,ContentCode) "
             "SELECT DISTINCT CartonContentID,PVOItemID,ContentCode FROM PVOInventoryCartonContents WHERE CartonContentID IS NOT NULL GROUP BY CartonContentID ORDER BY CartonContentID,PVOItemID,ContentCode"];
            
            //insert the records that are duplicates (giving them a new CartonContentID)
            [db updateDB:@"INSERT INTO PVOInventoryCartonContentsNew(PVOItemID,ContentCode) "
             "SELECT PVOItemID,ContentCode FROM PVOInventoryCartonContents cc WHERE "
             "(SELECT COUNT(*) FROM PVOInventoryCartonContents cccount WHERE cccount.CartonContentID = cc.CartonContentID) > 1 "
             " AND (SELECT COUNT(*) FROM PVOInventoryCartonContentsNew ccnew WHERE ccnew.CartonContentID = cc.CartonContentID "
             " AND ccnew.PVOItemID = cc.PVOITemID AND ccnew.ContentCode = cc.ContentCode) = 0"];
            
            //insert the values that have nulls (giving them a CartonContentID)
            [db updateDB:@"INSERT INTO PVOInventoryCartonContentsNew(PVOItemID,ContentCode) "
             "SELECT PVOItemID,ContentCode FROM PVOInventoryCartonContents WHERE CartonContentID IS NULL ORDER BY PVOItemID"];
            
            [db updateDB:@"DROP TABLE PVOInventoryCartonContents"];
            [db updateDB:@"ALTER TABLE PVOInventoryCartonContentsNew RENAME TO PVOInventoryCartonContents"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 74 - add HTML reports table
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS HTMLReports(ReportID INT, ReportTypeID INT, HTMLRevision INT, HTMLBundleLocation TEXT, "
             "HTMLTargetFile TEXT)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: version 75 - add "Use Scanner" option to Driver screen
            if (![db columnExists:@"UseScanner" inTable:@"PVODriverData"])
            {
                [db updateDB:@"ALTER TABLE PVODriverData ADD UseScanner INT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE PVODriverData SET UseScanner = 0 WHERE UseScanner IS NULL"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        
        if (maj < ++ver)
        {//MARK: version 76 - dynamic report options update
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVODynamicReportData (CustomerID INT, ReportID INT, DataSectionID INT,"
             " DataEntryID INT, TextValue TEXT, IntValue INT, DoubleValue REAL, DateTimeValue REAL)"];
            
            //insert all of the aspod data into the new format...
            if([db tableExists:@"ASPOD"])
            {
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 1, 1, NULL, 0, 0, ShipmentLoadBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 1, 2, NULL, 0, 0, ShipmentLoadEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 1, 3, NULL, 0, 0, ShipmentUnloadBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 1, 4, NULL, 0, 0, ShipmentUnloadEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 1, 5, NULL, SingleFamilyDwelling, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 2, 1, NULL, ExLaborMen, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 2, 2, NULL, 0, ExLaborHours, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 2, 3, ExLaborNotes, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 3, 1, NULL, 0, 0, OTBeginDate FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 3, 2, NULL, 0, 0, OTBeginDate FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 3, 3, NULL, 0, 0, OTEndDate FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 3, 4, NULL, 0, 0, OTEndDate FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 3, 5, NULL, OTPacking, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 1, NULL, WaitTimeMen, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 2, NULL, 0, WaitTimeFreeHours, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 3, NULL, 0, 0, WaitTimeBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 4, NULL, 0, 0, WaitTimeBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 5, NULL, 0, 0, WaitTimeEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 6, NULL, 0, 0, WaitTimeEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 4, 7, WaitTimeAuthBy, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 1, ShuttleAgentProvideLabor, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 2, ShuttleAgentProvideVan, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 3, NULL, ShuttleMen, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 4, NULL, ShuttleWeight, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 5, NULL, 0, 0, ShuttleBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 6, NULL, 0, 0, ShuttleBegin FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 7, NULL, 0, 0, ShuttleEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 5, 8, NULL, 0, 0, ShuttleEnd FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 1, BulkyAutoTruck, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 2, BulkySport, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 3, BulkyMoto, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 4, BulkyTractor, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 5, BulkyPlayhouse, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 6, BulkyCamper, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 7, BulkySnow, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 8, BulkyTrailer, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 9, BulkyFarm, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 10, BulkyBigScreen, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 11, BulkyPiano, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 12, BulkyHotTub, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 6, 13, BulkyOther, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 1, WACanoe, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 2, WABoat, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 3, WATravelCamper, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 4, WABoatTrailer, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 5, WASailboat, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 7, 6, WAOther, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 1, BFCity, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 2, BFState, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 3, BFZip, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 4, BFCity2, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 5, BFState2, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 8, 6, BFZip2, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 9, 1, NULL, MiniStgWeight, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 9, 2, MiniStgCity, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 9, 3, MiniStgState, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                [db updateDB:@"INSERT INTO PVODynamicReportData(CustomerID, ReportID, DataSectionID, DataEntryID, TextValue, IntValue, DoubleValue, DateTimeValue) "
                 " SELECT CustomerID, (CASE WHEN LocationID = 1 THEN 22 ELSE 23 END), 9, 4, MiniStgZip, 0, 0, 0 FROM ASPOD WHERE LocationID = 1 OR LocationID = 3"];
                
                //                [db updateDB:@"DROP TABLE ASPOD"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        
        if (maj < ++ver)
        {//MARK: version 77 - Send From Device Report Default
            if (![db columnExists:@"SendFromDevice" inTable:@"ReportDefaults"])
            {
                [db updateDB:@"ALTER TABLE ReportDefaults ADD SendFromDevice BIT NOT NULL DEFAULT 0"];
                [db updateDB:@"UPDATE ReportDefaults SET SendFromDevice = 0 WHERE SendFromDevice IS NULL"];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: report notes for multiple reports
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableReportNotes(PVOReceivableReportNoteID INTEGER PRIMARY KEY, CustomerID INT NOT NULL, "
             "ReportNoteType INT NOT NULL, Notes TEXT NOT NULL)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: getting fastrac from server for atlas bol
            [db updateDB:@"ALTER TABLE ShipmentInfo ADD IsAtlasFastrac INT DEFAULT 0"];
            [db updateDB:@"UPDATE ShipmentInfo SET IsAtlasFastrac = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: version 80 - add a vanline id to document library for filtering global docs (1041 OnTime defect)
            [db updateDB:@"ALTER TABLE DocumentLibrary ADD VanLineID INT DEFAULT -1"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: inventory with images support
            [db updateDB:@"ALTER TABLE HTMLReports ADD HTMLSupportsImages INT DEFAULT 0"];
            [db updateDB:@"UPDATE HTMLReports SET HTMLSupportsImages = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        
        if (maj < ++ver)
        {//MARK: version 82 - update html reports to only have the last path component instead of full location in the html bundle location
            [db updateHTMLReportBundleLocations];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD ItemIsCONS INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryItems SET ItemIsCONS = 0"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD CONSWeight INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryData SET CONSWeight = 0"];
            
            [db updateDB:@"ALTER TABLE PVOReceivableItems ADD ItemIsCONS INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOReceivableItems SET ItemIsCONS = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        if (maj <++ver)
        { //MARK: Add destination room conditions
            [db updateDB:@"CREATE TABLE  IF NOT EXISTS PVODestinationRoomConditions (PVODestinationRoomConditionsID INTEGER PRIMARY KEY, PVOUnloadID INTEGER, "
             "RoomID INTEGER, FloorTypeID INTEGER, HasDamage INTEGER, DamageDetail TEXT);"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: Add the comment tables for adding pvo item comments to delivery
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOInventoryItemComments(PVOCommentID INTEGER PRIMARY KEY, "
             "PVOItemID INT NOT NULL, Comments TEXT, CommentType INT DEFAULT 0)"];
            
            [db updateDB:@"INSERT INTO PVOInventoryItemComments(PVOItemID, Comments) SELECT PVOItemID, Comments FROM PVOInventoryItems WHERE Comments Is Not Null And Comments <> ''"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOReceivableItemComments(PVOCommentID INTEGER PRIMARY KEY, "
             "ReceivableItemID INT NOT NULL, Comments TEXT, CommentType INT DEFAULT 0)"];
            
            [db updateDB:@"INSERT INTO PVOReceivableItemComments(ReceivableItemID, Comments) SELECT ReceivableItemID, Comments FROM PVOReceivableItems WHERE Comments Is Not Null and Comments <> ''"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: Add the weight type to PVOInventoryItems, receivables
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD WeightType INT DEFAULT 0"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"CREATE TABLE PVOValuationTypes(ValuationTypeID INT, ValuationDescription TEXT, VanlineID INT)"];
            [db updateDB:@"INSERT INTO PVOValuationTypes(ValuationTypeID, ValuationDescription,VanlineID) VALUES (0, 'None', 0)"];
            [db updateDB:@"INSERT INTO PVOValuationTypes(ValuationTypeID, ValuationDescription,VanlineID) VALUES (1, 'FVP', 2)"];
            [db updateDB:@"INSERT INTO PVOValuationTypes(ValuationTypeID, ValuationDescription,VanlineID) VALUES (2, 'Released', 2)"];
            
            [db updateDB:@"ALTER TABLE PVOInventoryData ADD ValuationType INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryData SET ValuationType = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver)
        {//MARK: version room alias
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS RoomAlias (CustomerID INT, RoomID INT, Alias TEXT)"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver)
        {//MARK: version room alias
            //this insert script sucks and inserts duplicates and blows out the favorites
            //            [self flushCommandsFromFile:@"insert_mil_2.sql" withProgressHeader:@"Updating Military Items..."];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver)
        {//MARK: version room alias
            int retval = [db getIntValueFromQuery:@"SELECT MAX(CartonContentID) FROM PVOCartonContents"];
            
            [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOCartonContents(CartonContentID, ContentDescription) VALUES(%d,'Mattress')", ++retval]];
            [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOCartonContents(CartonContentID, ContentDescription) VALUES(%d,'Box Spring')", ++retval]];
            [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOCartonContents(CartonContentID, ContentDescription) VALUES(%d,'Box Spring - Split')", ++retval]];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        if (maj < ++ver)
        {//MARK: Added CustomerID to Rooms and Items for Single Use
            [db updateDB:@"ALTER TABLE Rooms ADD CustomerID INT"];
            [db updateDB:@"UPDATE Rooms SET CustomerID = NULL"];
            
            [db updateDB:@"ALTER TABLE Items ADD CustomerID INT"];
            [db updateDB:@"UPDATE Items SET CustomerID = NULL"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: Add the weight type, weight, cube to receivables
            [db updateDB:@"ALTER TABLE PVOReceivableItems ADD WeightType INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOReceivableItems SET WeightType = 0"];
            
            [db updateDB:@"ALTER TABLE PVOReceivableItems ADD Cube REAL"];
            [db updateDB:@"UPDATE PVOReceivableItems SET Cube = (SELECT Items.Cube FROM Items WHERE Items.ItemID = PVOReceivableItems.ItemID)"];
            
            
            [db updateDB:@"ALTER TABLE PVOReceivableItems ADD Weight INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOReceivableItems SET Weight = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {//MARK: Add favorite carton contents
            [db updateDB:@"ALTER TABLE PVOCartonContents ADD Favorite INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOCartonContents SET Favorite = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: version xx - crate dimension identifier
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD DimensionUnitType INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOInventoryItems SET DimensionUnitType = 0"];
            
            [db updateDB:@"ALTER TABLE PVOReceivableItems ADD DimensionUnitType INT DEFAULT 0"];
            [db updateDB:@"UPDATE PVOReceivableItems SET DimensionUnitType = 0"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVODimensionUnitTypes(TypeID INT, TypeDescription TEXT)"];
            [db updateDB:@"INSERT INTO PVODimensionUnitTypes(TypeID, TypeDescription) VALUES (1, 'in.')"];
            [db updateDB:@"INSERT INTO PVODimensionUnitTypes(TypeID, TypeDescription) VALUES (2, 'ft.')"];
            [db updateDB:@"INSERT INTO PVODimensionUnitTypes(TypeID, TypeDescription) VALUES (3, 'cm')"];
            [db updateDB:@"INSERT INTO PVODimensionUnitTypes(TypeID, TypeDescription) VALUES (4, 'm')"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {//MARK: version 81 - auto inventory updates
            if (![db columnExists:@"AutoUnlocked" inTable:@"ActivationControl"])
            {
                [db updateDB:@"ALTER TABLE ActivationControl ADD AutoUnlocked INT DEFAULT 0"];
                [db updateDB:@"UPDATE ActivationControl SET AutoUnlocked = 0"];
            }
            
            if (![db columnExists:@"InventoryType" inTable:@"Customer"])
            {
                [db updateDB:@"ALTER TABLE Customer ADD InventoryType INT DEFAULT 0"];
                [db updateDB:@"UPDATE Customer SET InventoryType = 0"];
            }
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOVehicles(VehicleID INTEGER PRIMARY KEY, CustomerID INT NOT NULL, Type TEXT, Year TEXT, Make TEXT, Model TEXT, Color TEXT, VIN TEXT, License TEXT, LicenseState TEXT, Odometer TEXT, WireframeType INT NOT NULL, DeclaredValue REAL, ServerID INT NOT NULL DEFAULT -1)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOVehicleCheckListItems(CheckListItemID INTEGER PRIMARY KEY, AgencyCode TEXT NOT NULL, Description TEXT)"];
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOVehicleCheckList(VehicleCheckListID INTEGER PRIMARY KEY, CheckListItemID INT NOT NULL, VehicleID INT NOT NULL, IsChecked INT NOT NULL)"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOVehicleDamages(DamageID INTEGER PRIMARY KEY, VehicleID INT, LocationType INT, ImageID INT DEFAULT -1, Comments TEXT, AlphaCodes TEXT, DamageLocationX REAL, DamageLocationY REAL, OriginDamage INT)"];
            
            if (![db columnExists:@"ReferenceID" inTable:@"PVOSignatures"])
            {
                [db updateDB:@"ALTER TABLE PVOSignatures ADD ReferenceID INT DEFAULT -1"];
                [db updateDB:@"UPDATE PVOSignatures SET ReferenceID = -1"];
            }
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOSignatureName(PVOSignatureID INT NOT NULL, Name TEXT NOT NULL)"];
            
            [db updateDB:@"CREATE TABLE PVOVehicleImages (VehicleImageID INTEGER PRIMARY KEY, ImageID INTEGER, VehicleID INTEGER, CustomerID INTEGER)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        if (maj < ++ver)
        {//MARK: test version 81 - add Canada vanline
            //MARK: canada update
            if (![db tableExists:@"CustomItemLists"])
            {
                [db updateDB:@"CREATE TABLE CustomItemLists (ItemListID INTEGER PRIMARY KEY NOT NULL, Description TEXT, ServerItemListID INT DEFAULT 0, IsHidden INT DEFAULT 0, IsDefault INT DEFAULT 0, PricingModeRestriction INT DEFAULT -1)"];
                [db updateDB:@"UPDATE CustomItemLists SET ServerItemListID = 0, IsHidden = 0, IsDefault = 0, PricingModeRestriction = 0"];
                
                [db updateDB:@"INSERT INTO CustomItemLists(Description, ServerItemListID, IsHidden, IsDefault) VALUES('Default', 0, 0, 1)"];
            }
            
            if (![db columnExists:@"CustomItemList" inTable:@"ShipmentInfo"])
            {
                [db updateDB:@"ALTER TABLE ShipmentInfo ADD CustomItemList INT DEFAULT 0"];
                [db updateDB:@"UPDATE ShipmentInfo SET CustomItemList = 0"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"ShipmentInfo"])
            {
                [db updateDB:@"ALTER TABLE ShipmentInfo ADD LanguageCode INT DEFAULT 0"];
                [db updateDB:@"UPDATE ShipmentInfo SET LanguageCode = 0"];
            }
            
            if (![db tableExists:@"Languages"])
            {
                [db updateDB:@"CREATE TABLE Languages (LanguageCode INT DEFAULT 0, Description TEXT)"];
                [db updateDB:@"UPDATE Languages SET LanguageCode = 0"];
                [db updateDB:@"INSERT INTO Languages VALUES(0, 'English')"];
                [db updateDB:@"INSERT INTO Languages VALUES(1, 'French')"];
            }
            
            if (![db tableExists:@"ItemDescription"])
            {
                [db updateDB:@"CREATE TABLE ItemDescription (ItemID INT DEFAULT 0, LanguageCode INT DEFAULT 0, Description TEXT DEFAULT '')"];
                [db updateDB:@"UPDATE ItemDescription SET LanguageCode = 0, ItemID = 0"];
                [db updateDB:@"INSERT INTO ItemDescription (ItemID, LanguageCode, Description) SELECT ItemID,0,ItemName FROM Items"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"Items"])
            {
                //remove ItemName column from Items table
                [db updateDB:@"ALTER TABLE Items ADD ItemListID INT DEFAULT 0"];
                
                [db updateDB:@"CREATE TABLE Items_temp (ItemID INTEGER PRIMARY KEY,ItemName TEXT,IsCartonCP INTEGER DEFAULT 0,IsCartonPBO INTEGER DEFAULT 0,IsCrate INTEGER DEFAULT 0,IsBulky INTEGER DEFAULT 0,Cube REAL DEFAULT 0,CartonBulkyID INTEGER DEFAULT 0, Hidden INTEGER DEFAULT 0, ItemListID INT DEFAULT 0, Favorite INTEGER DEFAULT 0, PVOLocationID INTEGER DEFAULT 0, IsVehicle INTEGER DEFAULT 0, IsGun INTEGER DEFAULT 0, IsElectronic INTEGER DEFAULT 0, CustomerID INT)"];
                [db updateDB:@"INSERT INTO Items_temp SELECT ItemID, ItemName, IsCartonCP, IsCartonPBO, IsCrate, IsBulky, Cube, CartonBulkyID, Hidden, ItemListID, Favorite, PVOLocationID, IsVehicle, IsGun, IsElectronic, CustomerID FROM Items"];
                [db updateDB:@"DROP TABLE Items"];
                
                [db updateDB:@"CREATE TABLE Items (ItemID INTEGER PRIMARY KEY,IsCartonCP INTEGER,IsCartonPBO INTEGER,IsCrate INTEGER,IsBulky INTEGER,Cube REAL,CartonBulkyID INTEGER DEFAULT 0, Hidden INTEGER DEFAULT 0, ItemListID INT DEFAULT 0, IsElectronic INT DEFAULT 0, IsGun INT DEFAULT 0, IsVehicle INT DEFAULT 0, Favorite INT DEFAULT 0, PVOLocationID INT DEFAULT 0, CustomerID INT)"];
                [db updateDB:@"INSERT INTO Items SELECT ItemID,IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID,Hidden,ItemListID, IsElectronic, IsGun, IsVehicle, Favorite, PVOLocationID, CustomerID FROM Items_temp"];
                [db updateDB:@"DROP TABLE Items_temp"];
                
                [db updateDB:@"UPDATE Items SET ItemListID = 0"];
            }
            
            if (![db tableExists:@"RoomDescription"])
            {
                [db updateDB:@"CREATE TABLE RoomDescription (RoomID INT DEFAULT 0, LanguageCode INT DEFAULT 0, Description TEXT DEFAULT '')"];
                [db updateDB:@"UPDATE RoomDescription SET LanguageCode = 0"];
                [db updateDB:@"INSERT INTO RoomDescription (RoomID, LanguageCode, Description) SELECT RoomID,0,RoomName FROM Rooms"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"Rooms"])
            {
                //remove RoomName column from Items table
                [db updateDB:@"ALTER TABLE Rooms ADD ItemListID INT DEFAULT 0"];
                [db updateDB:@"CREATE TABLE Rooms_temp (RoomID INTEGER PRIMARY KEY,RoomName TEXT DEFAULT '', Hidden INT DEFAULT 0, ItemListID INT DEFAULT 0, PVOLocationID INT DEFAULT 0, CustomerID INT)"];
                [db updateDB:@"INSERT INTO Rooms_temp SELECT RoomID, RoomName, Hidden, PVOLocationID, ItemListID, CustomerID FROM Rooms"];
                
                [db updateDB:@"DROP TABLE Rooms"];
                [db updateDB:@"CREATE TABLE Rooms (RoomID INTEGER PRIMARY KEY, Hidden INT DEFAULT 0, ItemListID INT DEFAULT 0, PVOLocationID INT DEFAULT 0, CustomerID INT)"];
                [db updateDB:@"INSERT INTO Rooms SELECT RoomID, Hidden, ItemListID, PVOLocationID, CustomerID FROM Rooms_temp"];
                [db updateDB:@"DROP TABLE Rooms_temp"];
                
            }
            
            if (![db columnExists:@"AtlasCanadaItemCode" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD AtlasCanadaItemCode TEXT DEFAULT NULL"];
                [db updateDB:@"UPDATE Items SET AtlasCanadaItemCode = ''"];
            }
            
            if (![db columnExists:@"Weight" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD Weight INT DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET Weight = 0"];
            }
            
            if (![db columnExists:@"UseWeightDefault" inTable:@"Items"])
            {
                [db updateDB:@"ALTER TABLE Items ADD UseWeightDefault INT DEFAULT 0"];
                [db updateDB:@"UPDATE Items SET UseWeightDefault = 0"];
            }
            
            
            if (![db columnExists:@"LanguageCode" inTable:@"PVOItemDamage"])
            {
                [db updateDB:@"ALTER TABLE Rooms ADD AtlasCanadaRoomCode TEXT DEFAULT NULL"];
                [db updateDB:@"UPDATE Rooms SET AtlasCanadaRoomCode = NULL"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"PVOItemDamage"])
            {
                [db updateDB:@"ALTER TABLE PVOItemDamage ADD LanguageCode INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOItemDamage SET LanguageCode = 0"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"PVOItemDamage"])
            {
                [db updateDB:@"ALTER TABLE PVOItemDamage ADD ItemListID INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOItemDamage SET ItemListID = 0"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"PVOItemLocations"])
            {
                [db updateDB:@"ALTER TABLE PVOItemLocations ADD LanguageCode INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOItemLocations SET LanguageCode = 0"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"PVOItemLocations"])
            {
                [db updateDB:@"ALTER TABLE PVOItemLocations ADD ItemListID INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOItemLocations SET ItemListID = 0"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"PVOCartonContents"])
            {
                [db updateDB:@"ALTER TABLE PVOCartonContents ADD LanguageCode INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOCartonContents SET LanguageCode = 0"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"PVOCartonContents"])
            {
                [db updateDB:@"ALTER TABLE PVOCartonContents ADD ItemListID INT DEFAULT 0"];
                [db updateDB:@"UPDATE PVOCartonContents SET ItemListID = 0"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"Customer"])
            {
                [db updateDB:@"ALTER TABLE Customer ADD ItemListID INT"];
                [db updateDB:@"UPDATE Customer SET ItemListID = 0"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"Customer"])
            {
                [db updateDB:@"ALTER TABLE Customer ADD LanguageCode INT"];
                [db updateDB:@"UPDATE Customer SET LanguageCode = 0"];
            }
            
            if (![db columnExists:@"LanguageCode" inTable:@"PVODescriptions"])
            {
                [db updateDB:@"ALTER TABLE PVODescriptions ADD LanguageCode INT"];
                [db updateDB:@"UPDATE PVODescriptions SET LanguageCode = 0"];
            }
            
            if (![db columnExists:@"ItemListID" inTable:@"PVODescriptions"])
            {
                [db updateDB:@"ALTER TABLE PVODescriptions ADD ItemListID INT"];
                [db updateDB:@"UPDATE PVODescriptions SET ItemListID = 0"];
            }
            
            @try {
                //couldn't find an easy way to check for these, need to keep moving forward to resolve the upgrade issue. if it errors out, it must exist already
                [db updateDB:@"CREATE INDEX IDX_ROOMS_ROOM_ID ON Rooms (RoomID)"];
                
                [db updateDB:@"CREATE INDEX IDX_ITEMS_ITEM_ID ON Items (ItemID)"];
                [db updateDB:@"CREATE INDEX IDX_MIL_ROOM_ID ON MasterItemList (RoomID)"];
                [db updateDB:@"CREATE INDEX IDX_MIL_ITEM_ID ON MasterItemList (ItemID)"];
                [db updateDB:@"CREATE INDEX IDX_ITEM_DESC_ITEM_ID ON ItemDescription (ItemID)"];
            }
            @catch (NSException *e)
            {
                
            }
            
            //insert all items for canadian pricing.
            [self flushCommandsFromFile:@"insert_cn_civ.sql" withProgressHeader:@"Updating CN Civilian Items..."];
            [self flushCommandsFromFile:@"insert_cn_gov.sql" withProgressHeader:@"Updating CN Gov't Items..."];
            
            [self flushCommandsFromFile:@"insert_cn_item_damages.sql" withProgressHeader:@"Updating CN Civilian Damages..."];
            [self flushCommandsFromFile:@"insert_cn_item_locations.sql" withProgressHeader:@"Updating CN Gov't Damages..."];
            [self flushCommandsFromFile:@"insert_cn_carton_contents.sql" withProgressHeader:@"Updating CN Carton Contents Items..."];
            [self flushCommandsFromFile:@"insert_cn_descriptive_symbols.sql" withProgressHeader:@"Updating CN Descriptive Symbols..."];
            
            [db updateDB:@"UPDATE CustomItemLists SET PricingModeRestriction = 2, Description = 'Canada Non-Govt' WHERE ItemListID = 2"];
            [db updateDB:@"UPDATE CustomItemLists SET PricingModeRestriction = 3, Description = 'Canada Govt' WHERE ItemListID = 3"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {// move crm settings to driver table instead of Prefs
            [db updateDB:@"ALTER TABLE PVODriverData ADD CRMUSERNAME TEXT"];
            [db updateDB:@"ALTER TABLE PVODriverData ADD CRMPASSWORD TEXT"];
            [db updateDB:@"ALTER TABLE PVODriverData ADD CRMENVIRONMENT INT DEFAULT 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        if (maj < ++ver)
        {//MARK:
            if (![db columnExists:@"IsPrimary" inTable:@"Phones"]) {
                [db updateDB: @"ALTER TABLE Phones Add IsPrimary int default 0"];
            }
            [db updateDB: @"INSERT INTO PhoneTypes values (0, 'Unknown Phone Type', 1)"];
            [db updateDB: @"UPDATE PHONES Set IsPrimary = 1 WHERE LOCATIONID = -1"];
            [db updateDB: @"UPDATE PHONES Set TypeID = 0 WHERE LocationID = -1"];
            [db updateDB: @"UPDATE Phones SET LocationID = 1 WHERE LocationID = -1"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription, LanguageCode, ItemListID) VALUES ('HW', 'Hardware', 0, 0)"];
            [db updateDB:@"INSERT INTO PVODescriptions(DescriptiveCode, DescriptiveDescription, LanguageCode, ItemListID) VALUES ('PR', 'Priority', 0, 0)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOWireframeDamages(DamageID INTEGER PRIMARY KEY, WireframeItemID INT, LocationType INT, ImageID INT DEFAULT -1, Comments TEXT, AlphaCodes TEXT, DamageLocationX REAL, DamageLocationY REAL, VehicleDamage INT, OriginDamage INT)"];
            [db updateDB:@"DELETE FROM PVOWireframeDamages"];
            
            [db updateDB:@"INSERT INTO PVOWireframeDamages (DamageID, WireframeItemID, LocationType, ImageID, Comments, AlphaCodes, DamageLocationX, DamageLocationY, OriginDamage, VehicleDamage) SELECT DamageID, VehicleID, LocationType, ImageID, Comments, AlphaCodes, DamageLocationX, DamageLocationY, OriginDamage, 1 FROM PVOVehicleDamages"];
            [db updateDB:@"DROP TABLE PVOVehicleDamages"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        if (maj < ++ver)
        {
            //moved to pricing db
            //            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOWireframeTypes(WireframeTypeID INTEGER PRIMARY KEY, Description TEXT NOT NULL)"];
            //            [db updateDB:@"DELETE FROM PVOWireframeTypes"];
            //
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (1, 'Car')"];
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (2, 'Truck')"];
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (3, 'SUV')"];
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (4, 'Photo')"];
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (5, 'Piano')"];
            //            [db updateDB:@"INSERT INTO PVOWireframeTypes (WireframeTypeID, Description) VALUES (6, 'Motorcycle')"];
            
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"ALTER TABLE HTMLReports ADD PageSize INT DEFAULT 0"];
            [db updateDB:@"UPDATE HTMLReports SET PageSize = 0"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOBulkyInventoryItems(PVOBulkyInventoryItemID INTEGER PRIMARY KEY, CustomerID INTEGER, PVOBulkyItemTypeID INTEGER, WireframeTypeID INTEGER)"];
            [db updateDB:@"DELETE FROM PVOBulkyInventoryItems"];
            
            [db updateDB:@"CREATE TABLE IF NOT EXISTS PVOBulkyInventoryItemData(PVOBulkyInventoryItemID INTEGER, DataEntryID INTEGER, TextValue TEXT, IntValue INT, DoubleValue REAL, DateTimeValue REAL)"];
            [db updateDB:@"DELETE FROM PVOBulkyInventoryItemData"];
            
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
            
        }
        
        if (maj < ++ver)
        {
            sqlite3_stmt *stmnt;
            NSString *cmd = [NSString stringWithFormat:@"SELECT DISTINCT(TRIM(d.Description)) AS descrip, COUNT(*) AS cnt FROM Items i INNER JOIN ItemDescription d ON i.ItemID = d.ItemID"
                             " GROUP BY descrip HAVING COUNT(*) > 1"];
            NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
            
            if([db prepareStatement:cmd withStatement:&stmnt])
            {
                NSString *itemDescription, *select;
                while (sqlite3_step(stmnt) == SQLITE_ROW) {
                    itemDescription = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmnt, 0)];
                    //select that gets all duplicate id's
                    select = [NSString stringWithFormat:@"SELECT i.ItemID FROM Items i INNER JOIN ItemDescription d ON i.ItemID = d.ItemID WHERE TRIM(d.Description) = %@",
                              [db prepareStringForInsert:itemDescription]];
                    //assign everything to the first duplicate id
                    [updateStatements addObject:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET ItemID = (%@ ORDER BY i.ItemID LIMIT 1)"
                                                 " WHERE ItemID IN(%@)", select, select]];
                    //remove everything except the first id
                    [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM Items WHERE ItemID IN("
                                                 "%@ AND i.ItemID != (%@ ORDER BY i.ItemID LIMIT 1))", select, select]];
                }
            }
            
            for (NSString *upd in updateStatements)
                [db updateDB:upd];
            
            sqlite3_finalize(stmnt);
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
            // add Sirva activation table
            
            [db createSirvaActivationTable];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
            [db updateDB:@"ALTER TABLE DocumentLibrary ADD OrderReportID INT NOT NULL DEFAULT(0)"];
            [db updateDB:@"ALTER TABLE Customer ADD QpdBrand INT NOT NULL DEFAULT(0)"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
            [db updateDB: @"DROP TABLE IF EXISTS QPDStopLocationXref"];
            [db updateDB: @"CREATE TABLE QPDStopLocationXref (StopId INTEGER,LocationId INTEGER CONSTRAINT "
             "fk_QPDStopLocationXref_LocationId REFERENCES Locations(LocationId) ON DELETE CASCADE)"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
//                        sqlite3_stmt *stmnt;
//                        NSString *cmd = [NSString stringWithFormat:@"SELECT DISTINCT (Description), Count(), itemID, rowid FROM ItemDescription WHERE ItemID IN (Select ItemID from ItemDescription GROUP BY itemID HAVING COUNT(*) > 1) GROUP BY description HAVING COUNT() > 1"];
//                        NSMutableArray *updateStatements = [[NSMutableArray alloc] init];
//            
//                        if([db prepareStatement:cmd withStatement:&stmnt])
//                        {
//                            while (sqlite3_step(stmnt) == SQLITE_ROW) {
//                                int rowID = sqlite3_column_int(stmnt, 3);
//                                [updateStatements addObject:[NSString stringWithFormat:@"DELETE FROM ItemDescription WHERE rowid = %d", rowID]];
//                            }
//                        }
//            
//                        for (NSString *upd in updateStatements)
//                            [db updateDB:upd];
//                        [updateStatements release];
//            
//                        sqlite3_finalize(stmnt);
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            // find the descriptions that are duplicates
            NSMutableArray *duplicateDescriptions = [NSMutableArray array];
            
            sqlite3_stmt *statement1;
            NSString *cmd = @"select description from itemdescription id join items i on i.itemid = id.itemid where cube = 0.0 group by description having count (description) > 1";
            if ([db prepareStatement:cmd withStatement:&statement1])
            {
                while (sqlite3_step(statement1) == SQLITE_ROW)
                {
                    NSString *str = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement1, 0)];
                    [duplicateDescriptions addObject:str];
                }
            }
            
            sqlite3_finalize(statement1);
            
            for (NSString *duplicateDescription in duplicateDescriptions)
            {
                // get the item numbers associated with a description
                NSMutableArray *itemNumbers = [NSMutableArray array];
                sqlite3_stmt *statement2;
                NSString *cmd = [NSString stringWithFormat:@"select itemid from itemdescription where description = %@", [db prepareStringForInsert:duplicateDescription supportsNull:NO]];
                if ([db prepareStatement:cmd withStatement:&statement2])
                {
                    while (sqlite3_step(statement2) == SQLITE_ROW)
                    {
                        int itemID = sqlite3_column_int(statement2, 0);
                        [itemNumbers addObject:@(itemID)];
                    }
                }
                
                sqlite3_finalize(statement2);
                [itemNumbers sortUsingSelector:@selector(compare:)];
                
                if ([itemNumbers count] > 1)
                {
                    NSInteger lowestNumber = -1;
                    for (NSNumber *itemNumber in itemNumbers)
                    {
                        if (lowestNumber == -1)
                        {
                            lowestNumber = [itemNumber integerValue];
                        }
                        else
                        {
                            NSInteger numberToReplace = [itemNumber integerValue];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE SurveyedItems SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE SmartItems SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE PVOReceivableItems SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE PVOInventoryItems SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE MasterItemList SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"UPDATE LocalPacking SET ItemID = %@ where ItemID = %@", @(lowestNumber), @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"DELETE FROM ItemDescription WHERE ItemID = %@", @(numberToReplace)]];
                            [db updateDB:[NSString stringWithFormat:@"DELETE FROM Items WHERE ItemID = %@", @(numberToReplace)]];
                        }
                    }
                }
            }
            
            // now remove the duplicate master item list records
            [db updateDB:@"DELETE FROM MasterItemList WHERE rowid NOT IN ( SELECT MIN(rowid) FROM MasterItemList GROUP BY RoomID, ItemID )"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            // find more duplicate descriptions
            NSMutableArray *duplicateDescriptions = [NSMutableArray array];
            
            sqlite3_stmt *statement1;
            NSString *cmd = @"select itemid from itemdescription where languagecode = 0 group by itemid having count(itemid) > 1";
            if ([db prepareStatement:cmd withStatement:&statement1])
            {
                while (sqlite3_step(statement1) == SQLITE_ROW)
                {
                    [duplicateDescriptions addObject:@(sqlite3_column_int(statement1, 0))];
                }
            }
            
            sqlite3_finalize(statement1);
            
            for (NSNumber *duplicateDescription in duplicateDescriptions)
            {
                NSInteger itemID = [duplicateDescription integerValue];
                [db updateDB:[NSString stringWithFormat:@"delete from itemdescription where itemid = %@ and rowid not in ( select max(rowid) from itemdescription where itemid =%@ )", @(itemID), @(itemID)]];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            // Yet even more duplicates.... the never ending problem.
            NSMutableArray *duplicateDescriptions = [NSMutableArray array];
            NSMutableArray *duplicateCube = [NSMutableArray array];
            NSMutableArray *duplicateLanguageCode = [NSMutableArray array];
            NSMutableArray *duplicateItemListId = [NSMutableArray array];
            NSMutableArray *minItemIds = [NSMutableArray array];
            
            sqlite3_stmt *statement1;
            NSString *initialQuery = @"select count(itemlistid), description, cube, languagecode, itemlistid from itemdescription id join items i on i.itemid = id.itemid group by description, cube, languagecode, itemlistid having count (description) > 1";
            if ([db prepareStatement:initialQuery withStatement:&statement1])
            {
                while (sqlite3_step(statement1) == SQLITE_ROW)
                {
                    [duplicateDescriptions addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement1, 1)]];
                    [duplicateCube addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement1, 2)]];
                    [duplicateLanguageCode addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement1, 3)]];
                    [duplicateItemListId addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement1, 4)]];
                }
            }
            
            sqlite3_finalize(statement1);
            
            for (int i = 0; i < [duplicateDescriptions count]; i++) {
                sqlite3_stmt *statement2;
                NSString *secondQuery = [NSString stringWithFormat: @"select min(i.itemid) from itemdescription id join items i on i.itemid = id.itemid where id.description = '%@' and i.cube = %@ and id.languagecode = %@ and i.itemlistid = %@",
                                         [duplicateDescriptions[i] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                                         duplicateCube[i],
                                         duplicateLanguageCode[i],
                                         duplicateItemListId[i]];
                
                if ([db prepareStatement:secondQuery withStatement:&statement2])
                {
                    while (sqlite3_step(statement2) == SQLITE_ROW)
                    {
                        [minItemIds addObject:[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement2, 0)]];
                        
                    }
                }
                sqlite3_finalize(statement2);
            }
            
            for (int i = 0; i < [minItemIds count]; i++) {
                [db updateDB:[NSString stringWithFormat: @"Update items SET hidden = 1 where itemid in (select i.itemid from itemdescription id join items i on i.itemid = id.itemid where id.description = '%@' and i.cube = %@ and id.languagecode = %@ and i.itemlistid = %@ and i.itemid > %@)",
                              [duplicateDescriptions[i] stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                              duplicateCube[i],
                              duplicateLanguageCode[i],
                              duplicateItemListId[i],
                              minItemIds[i]]];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }

        [db sanityCheck];
        
        if (maj < ++ver)
        {
            if(![db columnExists:@"SecuritySealNumber" inTable:@"PVOInventoryItems"])
                cmd = @"ALTER TABLE PVOInventoryItems ADD SecuritySealNumber TEXT NULL";
            [db updateDB:cmd];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
            [db updateDB:@"CREATE TABLE UploadTracking(CustomerID INT, NavItemID INT, WasUploaded INT)"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        if (maj < ++ver)
        {
            cmd = @"ALTER TABLE PVOReceivableItems ADD SecuritySealNumber TEXT NULL";
            [db updateDB:cmd];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        // do schema checks independ of the version number
        
        if (![db columnExists:@"SecuritySealNumber" inTable:@"PVOInventoryItems"])
        {
            [db updateDB:@"ALTER TABLE PVOInventoryItems ADD SecuritySealNumber TEXT NULL"];
        }
        if (maj < ++ver)
        {
            // Scrub duplicates from the ItemDescription table then add new items for Special Load type
            NSString *cmd = @"DELETE "
            "FROM ItemDescription "
            "WHERE ItemID NOT IN( "
            "SELECT Items.ItemID "
            "FROM Items "
            "INNER JOIN ItemDescription "
            "ON Items.ItemID = ItemDescription.ItemID) ";
            [db updateDB:cmd];
            
            cmd = @"DELETE "
            "FROM MasterItemList "
            "WHERE ItemID NOT IN( "
            "SELECT Items.ItemID "
            "FROM Items "
            "INNER JOIN MasterItemList "
            "ON Items.ItemID = MasterItemList.ItemID) ";
            [db updateDB:cmd];
            
            [db updateDB:@"INSERT INTO CustomItemLists(Description, ServerItemListID, IsHidden, IsDefault, PricingModeRestriction) VALUES('Atlas Special Product Load Type', 0, 0, 0, 4)"];
            
            NSArray *products = @ [@"Carton New Store Fixture-New",
                              @"Carton New Store Fixture-Used",
                              @"Exhibit/Crated, Art-New",
                              @"Exhibit/Crated, Art-Used",
                              @"Exhibit/Crated-New",
                              @"Exhibit/Crated-Used",
                              @"Exh/Half Crate Pad Wrap-New",
                              @"Exh/Half Crate Pad Wrap-Used",
                              @"Exhibit/Pad Wrap Art-New",
                              @"Exhibit/Pad Wrap Art-Used",
                              @"Exhibit/Pad Wrap-New",
                              @"Exhibit/Pad Wrap-Used",
                              @"Medical Equipment",
                              @"Medical Equipment Used",
                              @"Office Equipment-New",
                              @"Office Equipment-Used",
                              @"Office Furniture-New",
                              @"Office Furniture-Used",
                              @"Other Hdware-Special Products",
                              @"Other-Special Products",
                              @"Pad Wrap New Store Fix-New",
                              @"Pad Wrap New Store Fix-Used",
                              @"Skidded Machinery-New",
                              @"Skidded Machinery-Used",
                              @"Store Display-New",
                              @"Store Display-Used",
                              @"Truckload-New",
                              @"Truckload-Used" ];
            
            for (NSString *product in products)
            {
                [db updateDB:@"INSERT INTO Items(IsCartonCP,IsCartonPBO,IsCrate,IsBulky,Cube,CartonBulkyID,Weight,AtlasCanadaItemCode,ItemListID,UseWeightDefault) VALUES(0,0,0,0,0,0,0,'',4,0)"];
                NSInteger lastID = sqlite3_last_insert_rowid([db dbReference]);
                NSString *sql = [NSString stringWithFormat:@"INSERT INTO ItemDescription (ItemID, LanguageCode, Description) VALUES(%@, 0, '%@')", @(lastID), product];
                [db updateDB:sql];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        [db sanityCheck];

        if (maj < ++ver)
        {
            NSArray *locations = @ [@"Bottom", @"Center", @"Edge", @"Front", @"Inside", @"Left", @"Outside", @"Rear", @"Right", @"Side", @"Top", @"Arm", @"Base", @"Control Panel", @"Corner", @"Door", @"Drawer", @"End Cap", @"Foot", @"Frame", @"Glass", @"Grill", @"Handle", @"Hinge", @"Hose", @"Interior", @"Keyboard/Keys", @"Knob", @"Leg", @"Lid", @"Light fixture", @"Other", @"Paint-Finish", @"Panel", @"Piece", @"Plug-(Power)", @"Rail", @"Remote", @"Screen-(Monitor)", @"Seat", @"Shaft", @"Shelf", @"Stand", @"Support", @"Switch", @"Trim", @"Veneer", @"Wall", @"Wheel", @"Window", @"Wood"];
            
            NSArray *locCodes = @ [@"2", @"13", @"12", @"4", @"14", @"5", @"20", @"7", @"8", @"9", @"10", @"1", @"50", @"54", @"3", @"17", @"16", @"75", @"73", @"36", @"60", @"21", @"64", @"62", @"63", @"22", @"65", @"55", @"6", @"71", @"25", @"41", @"61", @"52", @"69", @"58", @"78", @"74", @"57", @"23", @"59", @"18", @"70", @"72", @"56", @"24", @"11", @"29", @"49", @"26", @"68"];
            
            NSArray *conditions = @ [@"Badly Worn", @"Bent", @"Broken", @"Burned", @"Caved", @"Chipped", @"Cracked", @"Crushed", @"Cut", @"Damaged", @"Dented", @"Dusty/Dirty", @"Faded", @"Frayed", @"Gouged", @"Greasy", @"Hole", @"Loose", @"Marred", @"Mechanical Failure", @"Mildew", @"Missing", @"Missing Hardware", @"Motheaten", @"Non-Functional", @"Other", @"Peeling", @"Pitted", @"Ripped", @"Rubbed", @"Rusted", @"Scratched", @"Short", @"Soiled", @"Split", @"Stained", @"Stretched", @"Torn", @"Upholstery", @"Warped", @"Water", @"Worn"];
            
            NSArray *damageCodes = @ [@"W", @"BE", @"BR", @"BU", @"CV", @"CH", @"Z", @"CR", @"CT", @"32", @"D", @"DST", @"F", @"FRA", @"G", @"33", @"31", @"L", @"M", @"34", @"MI", @"MSG", @"MH", @"MO", @"35", @"28", @"PE", @"P", @"30", @"R", @"RU", @"SC", @"SH", @"SO", @"SP", @"ST", @"STR", @"T", @"UPH", @"WA", @"WT", @"WS"];
            
            // Add locations and codes for Atlas Special Products
            for(NSInteger i = 0; i < [locations count]; i++)
            {
                NSString *loc = locations[i];
                NSString *code = locCodes[i];
                
                [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOItemLocations (LocationCode, LocationDescription, LanguageCode, ItemListID) VALUES(%@, '%@', 0, 4)", code, loc]];
            }
            
            // Add damages and codes for Atlas Special Products
            for(NSInteger i = 0; i < [conditions count]; i++)
            {
                NSString *dc = damageCodes[i];
                NSString *cond = conditions[i];
                [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOItemDamage (DamageCode, DamageDescription, LanguageCode, ItemListID) VALUES('%@', '%@', 0, 4)", dc, cond]];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"CREATE TABLE PVOPropertyTypes (FloorTypeID INTEGER PRIMARY KEY, Description TEXT)"];
            NSArray *floors = @ [@"Carpet", @"Ceiling", @"Door", @"Doorway", @"Driveway", @"Fence", @"Floor", @"Gate", @"Lamp Post", @"Light Fixture", @"Mailbox", @"Other-Residence/Property Inside", @"Partition", @"Pillar-Large", @"Pillar-Sm", @"Porch/Deck", @"Railing/Banister", @"Stairs", @"Wall", @"Window", @"Yard"];
            
            for(NSString *floor in floors){
                [db updateDB:[NSString stringWithFormat:@"INSERT INTO PVOPropertyTypes (Description) VALUES('%@')", floor]];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            [db updateDB:@"DROP TABLE CustomItemLists;"];
             
            [db updateDB:@"CREATE TABLE CustomItemLists (ItemListID INTEGER NOT NULL, Description TEXT, ServerItemListID INT DEFAULT 0, IsHidden INT DEFAULT 0, IsDefault INT DEFAULT 0, PricingModeRestriction INT DEFAULT -1);"];
            [db updateDB:@"INSERT INTO `CustomItemLists` VALUES (1,'Default',0,0,1,-1);"];
            [db updateDB:@"INSERT INTO `CustomItemLists` VALUES (2,'Canada Non-Govt',0,0,0,2);"];
            [db updateDB:@"INSERT INTO `CustomItemLists` VALUES (2,'Canada Govt',0,0,0,3);"];
            [db updateDB:@"INSERT INTO `CustomItemLists` VALUES (4,'Atlas Special Product Load Type',0,0,0,4);"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver) {
            [db updateDB:@"CREATE INDEX IDX_RD_LC ON RoomDescription (LanguageCode)"];
            [db updateDB:@"CREATE INDEX IDX_PVO_CC_LC ON PVOCartonContents (LanguageCode)"];
            [db updateDB:@"CREATE INDEX IDX_PVO_D_LC ON PVODescriptions (LanguageCode)"];
      
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        
        }
#if defined(ATLASNET)
        if (maj < ++ver) {
            // Hide all existing crates
            [db updateDB:@"UPDATE Items SET Hidden = 1 WHERE isCrate = 1;"];
            
            // Add new crates
            NSArray *names = [NSArray arrayWithObjects:@"Crate - CP",@"Crate - PBO",@"Crate - 3rd Party",@"Mirror Crate - CP",@"Mirror Crate - PBO",@"Mirror Crate - 3rd Party",@"Marble Crate - CP",@"Marble Crate - PBO",@"Marble Crate - 3rd Party",nil];
            int count = names.count;
            
            for(int i = 0; i < count; i++) {
                // Add an individual crate using one of the names above
                
                // Initialize variables
                Item* newCrate = [[Item alloc] init];
                NSString* newCrateName = names[i];
                
                // Set Item information
                newCrate.name = newCrateName;
                newCrate.cube = 0.0;
                newCrate.isCP = [newCrateName containsString:@" - CP"] ? 1 : 0;
                newCrate.isPBO = [newCrateName containsString:@" - PBO"] ? 1 : 0;
                newCrate.isCrate = 1;
                newCrate.isBulky = 0;
                newCrate.cartonBulkyID = 0;
                newCrate.isVehicle = 0;
                newCrate.isGun = 0;
                newCrate.isElectronic = 0;
                newCrate.CNItemCode = @"";
                
                // Add item (non-customer-specific) to Crates room (RoomID 10)
                [db insertNewItem:newCrate withRoomID:10 withCustomerID:-1 includeCubeInValidation:false withPVOLocationID:0 withLanguageCode:0 withItemListId:0 checkForAdditionalCustomItemLists:false];
                
                [newCrate release];
            }
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
#endif
        
        // OT 7001 - Atlas Completion Dates
        if (maj < ++ver) {
            [db updateDB:@"ALTER TABLE Customer ADD OriginCompletionDate TEXT"];
            [db updateDB:@"UPDATE Customer SET OriginCompletionDate = ''"];
            [db updateDB:@"ALTER TABLE Customer ADD DestinationCompletionDate TEXT"];
            [db updateDB:@"UPDATE Customer SET DestinationCompletionDate = ''"];
            
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }

        if (maj < ++ver) {
            // Update DB for features 2158 and 5982
            [db updateDB:@"ALTER TABLE PVODriverData ADD PackerEmail VARCHAR(100);"];
            [db updateDB:@"ALTER TABLE PVODriverData ADD PackerEmailCC INTEGER(1);"];
            [db updateDB:@"ALTER TABLE PVODriverData ADD PackerEmailBCC INTEGER(1);"];
            [db updateDB:@"ALTER TABLE PVODriverData ADD PackerName VARCHAR(100);"];
     
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if (maj < ++ver)
        {
            if(![db columnExists:@"LastSaveToServerDate" inTable:@"Customer"]) {
                cmd = @"ALTER TABLE Customer ADD LastSaveToServerDate TEXT DEFAULT '';";
                [db updateDB:cmd];
            }
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver) {
            // Update DB for feature 7985
            [db updateDB:@"CREATE TABLE ItemFavoritesByRoom (ItemID INT, RoomID INT);"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver) {
            [db updateDB: @"INSERT INTO PhoneTypes values (5, 'Phone 1', 1);"];
            [db updateDB: @"INSERT INTO PhoneTypes values (6, 'Phone 2', 1);"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        if(maj < ++ver) {
            [db updateDB: @"ALTER TABLE PVOWeightTickets ADD MoveHqId INT DEFAULT 0;"];
            [db updateDB: @"ALTER TABLE PVOWeightTickets ADD ShouldSync SMALLINT DEFAULT 1;"];
            [db updateDB:[NSString stringWithFormat:@"UPDATE Versions SET Major = %d", ver]];
        }
        
        // [db checkDatabaseIntegrity]; // prescott's safety check to use when necessary
        
        [self completed];
    }
    @catch (NSException * e) {
        self.success = NO;
        [self error:[NSString stringWithFormat:@"Exception on Update Thread: %@", [e description]]];
    }
    
    db.runningOnSeparateThread = NO;
}

#pragma mark - End Of Update

-(void)flushCommandsFromFile:(NSString*)filename withProgressHeader:(NSString*)progressHeader
{
    NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    NSError *err = nil;
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:fullPath encoding:NSUnicodeStringEncoding error:&err];
    if (err){
        NSLog(@"error:%@", err.localizedDescription);
    }
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    [self flushCommandsFromArray:lines withProgressHeader:progressHeader];
}

-(void)flushCommandsFromArray:(NSArray*)commands withProgressHeader:(NSString*)progressHeader
{
    if (commands != nil && [commands count] > 0)
    {
        if (progressHeader != nil)
            [self startProgress:progressHeader];
        float totalLines = [commands count];
        
        NSString *cmd;
        for (int i=0; i<totalLines; i++)
        {
            cmd = [commands objectAtIndex:i];
            [db updateDB:cmd];
            if (progressHeader != nil)
                [self updateProgress:i / totalLines];
        }
        if (progressHeader != nil)
            [self endProgress];
    }
}

-(void)error:(NSString*)description
{
    if(delegate != nil && [delegate respondsToSelector:@selector(SurveyDBUpdaterError:)])
        [delegate performSelectorOnMainThread:@selector(SurveyDBUpdaterError:) withObject:description waitUntilDone:NO];
}

-(void)completed
{
    if(delegate != nil && [delegate respondsToSelector:@selector(SurveyDBUpdaterCompleted:)])
        [delegate performSelectorOnMainThread:@selector(SurveyDBUpdaterCompleted:) withObject:self waitUntilDone:NO];
}

-(void)updateProgress:(float)progress
{
    if(delegate != nil && [delegate respondsToSelector:@selector(SurveyDBUpdaterUpdateProgress:)])
        [delegate performSelectorOnMainThread:@selector(SurveyDBUpdaterUpdateProgress:) withObject:[NSNumber numberWithFloat:progress] waitUntilDone:NO];
}

-(void)startProgress:(NSString*)progressLabel
{
    if(delegate != nil && [delegate respondsToSelector:@selector(SurveyDBUpdaterStartProgress:)])
        [delegate performSelectorOnMainThread:@selector(SurveyDBUpdaterStartProgress:) withObject:progressLabel waitUntilDone:NO];
}

-(void)endProgress
{
    if(delegate != nil && [delegate respondsToSelector:@selector(SurveyDBUpdaterEndProgress:)])
        [delegate performSelectorOnMainThread:@selector(SurveyDBUpdaterEndProgress:) withObject:self waitUntilDone:NO];
}

@end
