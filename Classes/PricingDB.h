//
//  PricingDB.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <sqlite3.h>
#import "SurveyAgent.h"
#import "PVOConfirmationDetails.h"
#import "PVOBulkyEntry.h"

#define PRICING_DB_NAME @"Pricing.sqlite3"
#define PVO_CONTROL_DB_NAME @"PVO_Control.sqlite3"

#define CURRENT_PRICING_VERSION 12
#define MCCOLLISTERS 183

enum VANLINES {
    ALLIED = 1,
    ARPIN,
    ATLAS,
    BASE,
    BEKINS,
    GLOBAL,
    MAYFLOWER,
    NATIONAL,
    NORTH_AMERICAN,
    RED_BALL,
    UNITED,
    WHEATON,
    STEVENS,
    UNIGROUP,
    CARLYLE,
    SIRVAQM,
    GRAEBEL,
    SIRVA,
    SKIPPED19,
    UNITED_CANADA
};


enum UG_PACK_TYPES {
    UG_CONTAINER = 0,
    UG_PACK,
    UG_PACK_OT,
    UG_UNPACK,
    UG_UNPACK_OT
};

enum PACK_TYPES {
    CONTAINER,
    PACK,
    PACK_OT,
    UNPACK,
    UNPACK_OT,
    CRATE_PACK,
    CRATE_UNPACK
};

@class AppFunctionality;

@interface PricingDB : NSObject {
    sqlite3    *db;
    int vanline;
    NSDateFormatter *formatter;
    //0.00 formatter for doubles
    NSNumberFormatter *numFormatter;
    BOOL runningOnSeparateThread;    
    NSDate *effectiveDate;
}

@property (nonatomic) BOOL runningOnSeparateThread;
@property (nonatomic, strong) NSDate *effectiveDate;

-(void)deleteDB;
-(BOOL)openDB;
-(NSString*)fullDBPath;
-(void)closeDB;
-(BOOL) updateDB: (NSString*)cmd;
-(BOOL)prepareStatement:(NSString*)cmd withStatement:(sqlite3_stmt**)stmnt;
-(BOOL)tableExists:(NSString*)table;
-(BOOL)columnExists:(NSString*)column inTable:(NSString*)table;
-(double)getDoubleValueFromQuery:(NSString*)cmd;
-(int)getIntValueFromQuery:(NSString*)cmd;

//utility functions
-(int)vanline;
- (BOOL)requiresUpdate;

//agents
-(NSMutableArray*)getAgentsList:(NSString*)state sortByCode:(BOOL)byCode;
-(SurveyAgent*)getAgent:(NSString*)code;
-(void)deleteVLAgents;
-(void)insertVLAgents:(NSArray*)agents;
-(NSMutableArray*)getAgencyStates;
-(BOOL)hasAgencies;

//PVO
-(BOOL*)hasAutoInventoryItems;
//dictionary with category id keys
-(NSDictionary*)getPVOListItems;
-(NSDictionary*)getPVOListItems:(int)driverType withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode;
-(NSDictionary*)getPVOListItems:(int)driverType withSourcedFromServer:(BOOL)sourcedFromServer withHaulingAgentCode:(NSString *)haulingAgentCode withPricingMode:(int)pricingMode;
//-(NSArray*)getPVOListItemsArray:(int)driverType;
-(NSArray*)getPVOCategoriesFromIDs:(NSArray*)ids;
-(int)getReportNotesTypeForPVONavItemID:(int)navItemID;
-(NSString*)pvoEsignAlertRequired;
-(BOOL)pvoContainsNavItem:(int)itemID;
-(NSArray*)getPVOAttachDocItems:(int)navItemID withDriverType:(int)driverType;
-(int)getReportIDFromNavID:(int)nID;
-(NSString*)getRequiredSignaturesForNavItem:(int)pvoNavItem;
-(BOOL)pvoNavItemHasReportSections:(int)pvoNavID;
-(NSArray*)getPVOReportSections:(int)pvoNavID;
-(NSArray*)getPVOReportEntries:(int)pvoReportID forSection:(int)sectionID;
-(NSString*)getPVOSignatureDescription:(int)signatureID;
-(BOOL)pvoNavItemHasConfirmation:(int)pvoNavID;
-(PVOConfirmationDetails*)getPVOConfirmationDetails:(int)pvoNavID;
-(NSArray*)getPVOMultipleChoiceOptions:(int)reportID inSection:(int)sectionID forEntry:(int)entryID;

//crm settings
-(BOOL)doesVanlineSupportCRM:(int)vanlineID;
-(NSString*)getCRMInstanceName:(int)vanlineID;
-(NSString*)getCRMSyncAddress:(int)vanlineID withEnvironment:(int)selectedEnvironment;

//bulky inventory
-(PVOBulkyEntry*)getPVOBulkyDetailEntryByID:(int)dataEntryID;
-(NSArray*)getPVOBulkyDetailEntries:(int)pvoBulkyTypeID;
-(NSArray*)getAllWireframeItems;
-(NSString*)getPVOBulkyTypeDescription:(int)pvoBulkyTypeID;
-(NSDictionary*)getWireframeTypesForPVOBulkyItemType:(int)pvoBulkyItemTypeID;

- (NSString *)getRequiredSignaturesForNavItemID:(int)navItemID pricingMode:(int)pricingMode loadType:(int)loadType itemCategory:(int)itemCategory haulingAgentCode:(NSString *)haulingAgentCode;
-(void)recreatePVODatabaseTables:(NSString *)xmlString;
@end
