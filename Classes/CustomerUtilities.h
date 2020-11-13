//
//  CustomerUtilities.h
//  Survey
//
//  Created by Tony Brame on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoomSummary.h"
#import "StoredPrinter.h"
#import "Item.h"

#define LOCAL_DEFAULT_RATES_ID -25
#define BACKUP_DIR @"Backups"

@class SurveyAppDelegate;

@interface CustomerUtilities : NSObject {

}

+(double)getTotalCustomerWeight;
+(RoomSummary*)getTotalSurveyedSummary;
+(RoomSummary*)getTotalSurveyedSummary:(int)custid;
//+(double)getValuationMinimumFromDB;
//+(double)getValuationMinimum;
//+(double)getLocalValuationMinimum:(int)ded;
+(double)getTotalCustomerCuFt;

//+(void)saveLocalRatesAsDefault;
//+(void)loadLocalDefaultRates;

//+(int)getMileage;

//+(BOOL)tariffAfterDate:(NSString*)date;

+(NSDictionary*)getPricingModes;
+(NSDictionary*)getInventoryTypes;
+(NSMutableDictionary*)getJobStatuses;
+(NSMutableDictionary*)getEstimateTypes;

//backups
+(void)deleteBackup:(NSString*)path;
+(NSString*)backupDatabases:(BOOL)includeImages withSuppress:(BOOL)suppressAlert appDelegate:(SurveyAppDelegate *)del;
+(NSString*)backupDatabases:(BOOL)includeImages withSuppress:(BOOL)suppressAlert success:(BOOL*)success appDelegate:(SurveyAppDelegate *)del;
+(BOOL)restoreBackup:(NSString*)path;
+(void)sendBackupToSupport:(NSString*)path;
+(NSArray*)allBackupFolders;
//+(void)restoreFromAttachment:(NSURL*)url;

//printing
+(NSDictionary*)getPrintSettings:(StoredPrinter*)printer;
+(BOOL)printDisconnectedSupported;

//smart items
//+(void)processSmartItem:(Item*)itemAdded withSmartItems:(NSArray*)smartItems;

//PVO
+(BOOL)roomConditionsEnabled;
+(NSMutableDictionary*)arpinSyncPreferences;
+(BOOL)customerSourcedFromServer;
+(int)customerPricingMode;
+(SurveyPhone*)setupContactPhone:(SurveyPhone*)phone withPhoneTypeId:(NSInteger)typeId;
+(NSMutableString*)formatPhoneString:(NSMutableString *)str;
// date utilities
+(NSDate*)dateFromString:(NSString*)dateString;

@end
