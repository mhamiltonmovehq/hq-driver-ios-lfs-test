//
//  SurveyDB.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <sqlite3.h>
#import "SurveyCustomer.h"
#import "SurveyLocation.h"
#import	"SurveyPhone.h"
#import "ShipmentInfo.h"
#import "Room.h"
#import "Item.h"
#import "SurveyedItem.h"
#import "CubeSheet.h"
#import	"SurveyedItemsList.h"
#import "CrateDimensions.h"
#import "SurveyDates.h"
#import "SurveyAgent.h"
#import "SurveyCustomerSync.h"
#import "CommonNote.h"
#import "ActivationRecord.h"
#import "StoredPrinter.h"
#import "CustomerFilterOptions.h"
#import "DriverData.h"
#import "PVOInventory.h"
#import "PVORoomSummary.h"
#import "PVOItemDetail.h"
#import "PVOConditionEntry.h"
#import "PVOCartonContent.h"
#import "PVORoomConditions.h"
#import "PVOSignature.h"
#import "PVOHighValueInitial.h"
#import "PVOInventoryLoad.h"
#import "PVOInventoryUnload.h"
#import "PVOItemDescription.h"
#import "PVOClaim.h"
#import "PVOClaimItem.h"
#import "PVOWeightTicket.h"
#import "BackupRecord.h"
#import "AutoBackupSchedule.h"
#import "DocLibraryEntry.h"
#import "PVOVerifyInventoryItem.h"
#import "ReportDefaults.h"
#import "PVOItemDetailExtended.h"
#import "ItemType.h"
#import "ReportOption.h"
#import "PVOReportNote.h"
#import "PVODynamicReportData.h"
#import "PVOItemComment.h"
#import "PVOVehicle.h"
#import "PVOBulkyData.h"
#import "PVOBulkyInventoryItem.h"

@class AppFunctionality, SurveyAppDelegate, SurveyImage;

#define SURVEY_DB_NAME @"survey.sqlite3"

//images will be stored at "cust (id)/surveyeditems/photo" or locations/photo
#define IMG_SURVEYED_ITEMS 0
#define IMG_LOCATIONS 1
#define IMG_ALL 2
#define IMG_ROOMS 3
#define IMG_PVO_ITEMS 4
#define IMG_PVO_ROOMS 5
#define IMG_PVO_CLAIM_ITEMS 6
#define IMG_PVO_WEIGHT_TICKET 7
#define IMG_PVO_DESTINATION_ROOMS 8
#define IMG_PVO_DESTINATION_ITEMS 9
#define IMG_PVO_VEHICLE_DAMAGES 10
#define IMG_PVO_ITEM_DAMAGES 11

#define IMG_ROOT_DIRECTORY @"Images"
#define IMG_SI_DIRECTORY @"SurveyedItems"
#define IMG_LOCATIONS_DIRECTORY @"Locations"
#define IMG_ROOMS_DIRECTORY @"Rooms"
#define IMG_PVO_ITEMS_DIRECTORY @"PVOItems"
#define IMG_PVO_ROOMS_DIRECTORY @"PVORooms"
#define IMG_PVO_DESTINATION_ROOMS_DIRECTORY @"PVODestinationRooms"
#define IMG_PVO_CLAIM_ITEMS_DIRECTORY @"PVOClaimItems"
#define IMG_PVO_WEIGHT_TICKET_DIRECTORY @"PVOWeightTickets"
#define IMG_PVO_VEHICLES_DIRECTORY @"PVOVehicles"

#define DEFAULT_AGENCY_CUST_ID -1

//used to check dirty flags for different data sections
#define PVO_DATA_LOAD_ITEMS 1
#define PVO_DATA_DELIVER_ITEMS 2
#define PVO_DATA_ROOM_CONDITIONS 3
#define PVO_DATA_LOAD_HIGH_VALE 4
#define PVO_DATA_DELIVER_HIGH_VALUE 5
#define PVO_DATA_AUTO_INVENTORY_ORIG 6
#define PVO_DATA_AUTO_INVENTORY_DEST 7
#define PVO_DATA_AUTO_BOL_ORIG 8
#define PVO_DATA_AUTO_BOL_DEST 9

@interface SurveyDB : NSObject {
	//int custID;
	sqlite3	*db;
    
    BOOL runningOnSeparateThread;
}

@property (nonatomic) BOOL runningOnSeparateThread;

-(id)initDB:(int)vlID;

-(sqlite3*)dbReference;
-(void)openDB:(int)vlID;
-(NSString*)fullDBPath;
-(void)closeDB;
-(BOOL) updateDB: (NSString*)cmd;
-(BOOL)prepareStatement:(NSString*)cmd withStatement:(sqlite3_stmt**)stmnt;
-(BOOL)tableExists:(NSString*)table;
-(BOOL)columnExists:(NSString*)column inTable:(NSString*)table;
-(NSString*)getStringValueFromQuery:(NSString*)cmd;
-(double)getDoubleValueFromQuery:(NSString*)cmd;
-(int)getIntValueFromQuery:(NSString*)cmd;
-(NSString*)prepareStringForInsert:(NSString*)src supportsNull:(BOOL)nullable;
-(NSString*)prepareStringForInsert:(NSString*)src;
+(NSString*)stringFromStatement:(sqlite3_stmt*)stmnt columnID:(int)column;

//maintenance
-(BOOL)createDatabase;
-(void)upgradeDBWithDelegate:(id)delegate forVanline:(int)vlid;
-(void)upgradeDBForVanline:(int)vlid;

- (void)sanityCheck;

- (BOOL)checkDatabaseIntegrity;

//customer functions
-(NSMutableArray*)getCustomerList:(CustomerFilterOptions*)filters;
-(NSMutableArray*)getCustomerListByDate:(NSDate*)surveyDate;
-(SurveyCustomer*)getCustomer:(int) cID;
-(SurveyCustomer*)getCustomerByQMID:(int)qmID;
-(SurveyCustomer*)getCustomerByOrderNumber:(NSString*)orderNumber;
-(SurveyLocation*)getCustomerLocation:(int)locID;
-(SurveyLocation*)getCustomerLocation:(int) cID withType:(int)locID;
-(NSMutableArray*)getCustomerLocations:(int) cID atOrigin:(BOOL)origin;
-(void)copyCustomer:(int)custID;
-(int)getExtraLocationsCount:(int) cID;
-(void)updateCustomer:(SurveyCustomer*) cust;
-(void)updateCustomerPricingMode:(int)custID pricingMode:(enum PRICING_MODE_TYPE)pricingMode;
-(int)getItemListIDForPricingMode:(int)pricingModeID;
-(int)getCustomerItemListID:(int)customerId;
-(void)updateLocation:(SurveyLocation*) loc;
-(int)insertLocation:(SurveyLocation*) loc;
-(void)deleteLocation:(SurveyLocation*) loc;
-(int)insertNewCustomer:(SurveyCustomer*) cust withSync:(SurveyCustomerSync*)sync andShipInfo:(ShipmentInfo*)info;
-(void)deleteCustomerLocalRates:(int) cID;
-(void)deleteCustomer:(int) cID;
-(int)getPhoneTypeIDFromName:(NSString*)name;
-(SurveyDates*)getDates:(int) cID;
-(void)updateDates:(SurveyDates*) dates;
-(NSMutableArray*)getPhoneTypeList;
-(BOOL)addPhone:(SurveyPhone*)phone withTypeString:(NSString*)type;
-(NSMutableArray*)getCustomerPhones:(int) cID withLocationID:(int) locationID;
-(NSString*)getCustomerPhone:(int)cID withLocationID:(int)locationID andPhoneType:(NSString*)type;
-(void)updatePhone:(SurveyPhone*) phone;
-(void)insertPhone:(SurveyPhone*) phone;
-(void)deletePhone:(SurveyPhone*) phone;
-(void)deletePhones:(int)custID withLocationID:(int)locationID;
-(SurveyPhone*)getPrimaryPhone:(int)cID;
-(BOOL)phoneExists:(int)customerID withLocationID:(int)locationID withPhoneType:(int)phoneTypeID;
-(BOOL)insertNewPhoneType:(NSString*)typeName;
-(void)hidePhoneType:(int)phoneTypeID;
-(void)updatePhoneType:(int) newTypeID withOldPhoneTypeID:(int)oldTypeID withCustomerID:(int)customerID andLocationID:(int)locationID;
-(SurveyCustomerSync*)getCustomerSync:(int)custID;
-(void)updateCustomerSync:(SurveyCustomerSync*)sync;
-(void)removeAllCustomerSyncFlags;
-(NSString*)getCustomerNote:(int)custID;
-(void)updateCustomerNote:(int)custID withNote:(NSString*)note;
-(NSDictionary*)getPVOPropertyTypes;

-(ShipmentInfo*)getShipInfo:(int)custID;
-(void)updateShipInfo:(ShipmentInfo*)info;
-(void)updateShipInfo:(int)custID languageCode:(int)languageCode customItemList:(int)customItemList;

//agents
-(SurveyAgent*)getAgent:(int)customerID withAgentID:(int)agentID;
-(void)saveAgent:(SurveyAgent*)agent;

//common notes
-(NSArray*)loadCommonNotes:(int)noteType;
-(void)saveNewCommonNote:(CommonNote*)note;
-(void)deleteCommonNote:(int)recID;

//cubesheet functions
// Get all rooms
-(NSMutableArray*)getAllRoomsList:(int)customerID;
-(NSMutableArray*)getAllRoomsList:(int)customerID withHidden:(BOOL)includeHidden;
-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden;
-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden limitToCustomer:(BOOL)customerItemsOnly;
-(NSMutableArray*)getAllRoomsList:(int)customerID withCheckInclude:(BOOL)includeHidden limitToCustomer:(BOOL)customerItemsOnly withPVOLocationID:(int)pvoLocationID withHidden:(BOOL)includeHidden2;

-(NSMutableArray*)getRoomsForV10Upgrade;
-(Room*)getRoom:(int)roomID;
-(Room*)getRoom:(int)roomID WithCustomerID:(int)custID;
-(Room*)getRoomIgnoringItemListID:(int)roomID;
- (Room *)getRoomByName:(NSString *)name languageCode:(int)languageCode itemListID:(int)itemListID;

-(Item*)getItemByItemName:(NSString*)itemName;
-(Item*)getItemByItemName:(int)custID withItemName:(NSString*)itemName;
-(Item*)getItemByItemName:(int)customerID itemName:(NSString*)itemName languageCode:(int)languageCode itemListID:(int)itemListID;
-(Item*)getVoidTagItem;
-(Item*)getItem:(int)itemID;
-(Item*)getItem:(int)itemID WithCustomer:(int)custID;
-(BOOL)includeItemInRoom:(Item*)item;
-(NSMutableArray*)getTypicalItemsForRoom:(Room*)room withCustomerID:(int)custID;
-(NSMutableArray*)getTypicalItemsForRoom:(Room*)room withPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID;

// Get all items
-(NSMutableArray*)getAllItems;
-(NSMutableArray*)getAllSpecialProductItemsWithCustomerID:(int)customerID;
-(NSMutableArray*)getFavoriteSpecialProductItems;
-(NSArray*)getPVOFavoriteItemsRooms;
-(void)removePVOFavoriteItemRoom:(int)roomID;
-(void)addPVOFavoriteItemRoom:(int)roomID withItems:(NSArray*)items;
-(NSArray*)getPVOFavoriteItemsForRoom:(Room*)room;
-(void)removeAllPVOFavoriteItems;
-(NSDictionary*)getSpecialProductDamageConditions;
-(NSDictionary*)getSpecialProductDamageLocations;
-(NSMutableArray*)getAllItems:(BOOL)checkInclude;
-(NSMutableArray*)getAllItems:(BOOL)checkInclude withCustomerID:(int)customerID;
-(NSMutableArray*)getAllItems:(BOOL)checkInclude withCustomerID:(int)customerID withHidden:(BOOL)hidden ignoreItemListId:(BOOL)ignore;
-(NSMutableArray*)getAllItemsWithPVOLocationID:(int)pvoLocationID;
-(NSMutableArray*)getAllItemsWithPVOLocationID:(int)pvoLocationID WithCustomerID:(int)custID;
-(int)getItemListIDForItem:(Item*)item;
-(NSString*)getItemTypesSelection:(ItemType*)itemTypes isFirst:(BOOL)first withTableAppend:(NSString*)append;
-(NSMutableArray*)getItemsForV10Upgrade;
-(NSMutableArray*)getItemsForV10UpgradeWithCustomerID:(int)custID;
-(NSMutableArray*)getCPItemswithCustomerID:(int)custID;
-(NSMutableArray*)getCPItemsWithPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID;
-(NSMutableArray*)getPBOItemsWithCustomerID:(int)custID;
-(NSMutableArray*)getPBOItemsWithPVOLocationID:(int)pvoLocationID withCustomerID:(int)custID;
-(NSMutableArray*)getItemsFromSurveyedItems:(SurveyedItemsList*)ids;
-(NSMutableArray*)getItemsFromSurveyedItems:(SurveyedItemsList*)items withCustomerID:(int)custID;
-(CubeSheet*)openCubeSheet:(int)customerID;
-(void)deleteCubeSheet:(int)customerID;
-(void)updateCubeSheet:(CubeSheet*)cs;
-(NSMutableArray*)getRoomSummaries:(CubeSheet*)csID customerID:(int)custID;
-(NSMutableArray*)getAllRoomSummaries:(CubeSheet*)cs customerID:(int)custID;
-(NSMutableArray*)getRoomSummaries:(CubeSheet*)cs overrideLimit:(BOOL)noLimit customerID:(int)custID ignoreItemListID:(BOOL)ignoreItemListID;
-(SurveyedItemsList*)getRoomSurveyedItems:(Room*)room withCubesheetID: (int)csID;
-(SurveyedItemsList*)getRoomSurveyedItems:(Room*)room withCubesheetID:(int)csID overrideLimit:(BOOL)noLimit;
-(SurveyedItemsList*)getSurveyedPackingItems:(int)csID;
-(NSMutableArray*)getAllSurveyedItems:(int)custID;
-(void)saveSurveyedItems:(SurveyedItemsList*)surveyedItems;
-(void)updateSurveyedItem:(SurveyedItem*)surveyedItem;
-(int)insertNewSurveyedItem:(SurveyedItem*)surveyedItem;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID withPVOLocationID:(int)pvoLocationID;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID appDelegate:(SurveyAppDelegate *)del;
-(int)insertNewItem:(Item*)item withRoomID:(int)roomID withCustomerID:(int)customerID includeCubeInValidation:(BOOL)includeCube withPVOLocationID:(int)pvoLocationID withLanguageCode:(int)languageCode withItemListId:(int)itemListId checkForAdditionalCustomItemLists:(BOOL)checkForAdditionalCustomItemLists;
-(int)getItemID:(NSString*)itemName;
-(int)getItemID:(NSString *)itemName withCube:(double)cube;
-(CrateDimensions*)getCrateDimensions: (int)surveyedID;
-(NSString*)getItemComment: (int)surveyedID;
-(void)setItemComment: (int)surveyedID withCommentText:(NSString*)comment;
-(void)setCrateDimensions:(int)surveyedID withDimensions:(CrateDimensions*)dims;
-(SurveyedItemsList*)getBulkies:(int)custID;
-(SurveyedItemsList*)getCrates:(int)custID;
-(SurveyedItemsList*)getCPs:(int)custID;
-(SurveyedItemsList*)getPBOs:(int)custID;
-(SurveyedItemsList*)getCartons:(int)custID isCP:(BOOL)cp;
//-(void)updateCartons:(int)custID withItems:(NSArray*)items;
-(int)getItemIDFromCartonID:(int)cartonID isCP:(BOOL)isCP;
-(void)hideItem:(int)itemID;
-(void)unHideItem:(int)itemID;
-(void)hideRoom:(int)roomID;
-(void)unHideRoom:(int)roomID;
-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID;
-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID withPVOLocationID:(int)pvoLocationID;
-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID alwaysReturnRoom:(BOOL)returnRoom;
-(Room*)insertNewRoom:(NSString*)name withCustomerID:(int)custID alwaysReturnRoom:(BOOL)returnRoom withPVOLocationID:(int)pvoLocationID withCustomListID:(int)customListID checkForAdditionalCustomItemLists:(BOOL)checkForAdditionalCustomItemLists;
-(void)updateRoomIDsForSurveyedItems:(int)oldRoomID toNewRoomID:(int)newRoomID;
-(void)updateItemIDsForSurveyedItems:(int)oldItemID toNewItemID:(int)newItemID;

//photo functions
-(NSString*)getPhotoSavePath:(int)customerID withPhotoType:(int)type withSubID:(int)subID;
-(int)addNewImageEntry:(int)customerID withPhotoType:(int)type withSubID:(int)subID withPath:(NSString*)path;
-(NSMutableArray*)getImagesList:(int)customerID withPhotoType:(int)type withSubID:(int)subID loadAllItems:(BOOL)loadAll;
-(NSMutableArray*)getImagesList:(int)customerID withPhotoType:(int)type withSubID:(int)subID loadAllItems:(BOOL)loadAll loadAllForType:(BOOL)allForType;
-(NSMutableArray*)getImagesList:(int)customerID withPhotoTypes:(NSArray*)types withSubID:(int)subID loadAllItems:(BOOL)loadAll loadAllForType:(BOOL)allForType;
-(BOOL*)customerHasImages:(int)customerID;
-(void)deleteImageEntry:(int)imageID;
-(int)getImageSyncID:(int)customerID withPhotoType:(int)type withSubID:(int)subID;
-(NSString*)getImageDescription:(SurveyImage*)imageDetails;

//activation
-(void)updateActivation:(ActivationRecord*)rec; 
-(ActivationRecord*)getActivation;
-(BOOL)isAutoInventoryUnlocked;

//email defaults
-(ReportDefaults*)getReportDefaults;
-(void)saveReportDefaults:(ReportDefaults*)defaults;

//printer info
-(void)addPrinter:(StoredPrinter*)printer;
-(void)setDefaultPrinter:(int)printerID;
-(NSArray*)getAllPrinters;
-(void)removePrinter:(int)printerID;
-(StoredPrinter*)getDefaultPrinter;
-(void)setPrintQuality:(int)quality;
-(void)setPrintColor:(BOOL)color;


//PVO
-(void)saveCRMSettings:(NSString*)username password:(NSString*)password syncEnvironment:(int)selectedEnvironment;
-(NSString*)getDriverNumber;
-(NSString*)getHaulingAgentCode;
-(DriverData*)getDriverData;
-(void)updateDriverData:(DriverData*)data;
-(NSArray*)getDriverDataCCEmails;
-(NSArray*)getDriverDataBCCEmails;
-(NSArray*)getDriverDataPackerCCEmails;
-(NSArray*)getDriverDataPackerBCCEmails;
-(PVOInventory*)getPVOData:(int)custID;
-(void)updatePVOData:(PVOInventory*)data;
-(NSMutableDictionary*)getPVOLoadTypes;
-(NSMutableDictionary*)getPVOLoadTypesForAtlas:(NSArray*)descriptionsToHide;
-(NSDictionary*)getPVOValuationTypes:(int)vanlineID;
-(NSDictionary*)getPVOLocations:(BOOL)includeHidden isLoading:(BOOL)isLoad;
-(NSDictionary*)getPVOLocations:(BOOL)includeHidden isLoading:(BOOL)isLoad isDriverInv:(BOOL)isDriver;
-(BOOL)pvoLocationRequiresLocationSelection:(int)locationID;
-(NSDictionary*)getPVOColors;
-(NSDictionary*)getPVODimensionUnitTypes;
-(NSDictionary*)getPVODamageLocationsWithCustomerID:(int)custID;
-(NSDictionary*)getPVODamageWithCustomerID:(int)custID;
-(int)updatePVOLoad:(PVOInventoryLoad*)data;
-(PVOInventoryLoad*)getPVOLoad:(int)pvoLoadID;
-(PVOInventoryLoad*)getFirstPVOLoad:(int)custID forPVOLocationID:(int)pvoLocationID;
-(BOOL)locationAvailableForPVOLoad:(int)locID;
-(NSArray*)getPVOItems:(int)pvoLoadID forRoom:(int)roomID;
-(int)updatePVOItem:(PVOItemDetail*)data withDataUpdateType:(int)dataType;
-(int)updatePVOItem:(PVOItemDetail*)data;
//-(BOOL)updatePVOComments:(PVOItemDetail*)data comments:(NSString *)commentsText;
-(void)copyPVOItem:(PVOItemDetail*)pvoItem withQuantity:(int)qty includeDetails:(BOOL)withDetail;
-(void)copyPVOItem:(PVOItemDetail*)pvoItem withQuantity:(int)qty andCartonContentID:(int)cartonContentID includeDetails:(BOOL)withDetail;
-(void)deletePVOItem:(int)pvoItemID withCustomerID:(int)custID;
-(void)deletePVOItem:(int)pvoItemID isCartonContent:(BOOL)cartonContent withCustomerID:(int)custID;
-(void)voidPVOItem:(int)pvoItemID;
-(void)voidPVOItem:(int)pvoItemID withReason:(NSString*)reason;
-(void)setWorkingPVOItem:(int)pvoItemID;
-(void)doneWorkingPVOItem:(int)pvoItemID;
-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID;
-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID forDamageType:(int)damageType;
-(NSArray*)getPVOReceivableItemDamage:(int)pvoReceivableItemID forDamageTypes:(NSArray*)damageTypes;
-(void)deletePVOItemsInRoom:(int)pvoLoadID andRoom:(int)roomid;
-(void)switchPVOItemLocations:(int)pvoLoadID toLocation:(int)to;
-(BOOL)pvoItemExists:(PVOItemDetail*)data;
-(PVOItemDetail*)getPVOItem:(int)pvoLoadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber;
-(PVOItemDetail*)getPVOItem:(int)pvoLoadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber includeDeleted:(BOOL)withDeleted;
-(PVOItemDetail*)getPVOItemForUnload:(int)pvoUnloadID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber;
//this is just returning the first item that matches that item number (or item and lot if both provided)...
-(PVOItemDetail*)getPVOItemForCustID:(int)custID forLotNumber:(NSString*)lotNumber withItemNumber:(NSString*)itemNumber;
-(PVOItemDetail*)getPVOItem:(int)pvoItemID;
-(int)getPVODeliveryType:(int)pvoLoadID;
-(NSArray*)getPVOItemsForLoad:(int)loadID;
-(NSArray*)getPVOAllItems:(int)custID;
-(NSArray*)getPVOAllItems:(int)custID lotNumber:(NSString *)lotNum;
-(NSString*)nextPVOItemNumber:(int)custID forLot:(NSString*)lotNum;
-(NSString*)nextPVOItemNumber:(int)custID forLot:(NSString*)lotNum withStartingItem:(int)startingItemNum;
-(NSArray*)getRemainingPVOItems:(int)pvoLoadID forLot:(NSString*)lotNumber;
-(NSArray*)getRemainingPVOItems:(int)pvoUnloadID forLot:(NSString*)lotNumber useLotNumber:(BOOL)useLotNumber;
-(NSString*)getPVOItemDetailSelectString;
-(PVOItemDetail*)getPVOCartonContentItem:(int)cartonContentID;

-(NSArray*)getPVOLocationsForCust:(int)custID;
-(NSArray*)getPVOLocationsForCust:(int)custID withDriverType:(int)driverType;
-(int)getPVOItemCountForLocation:(int)pvoLoadID includeDeleted:(BOOL)includeDeleted ignoreItemList:(BOOL)ignoreItemList;
-(int)getPVOItemMissingCountForLocation:(int)pvoLoadID;
-(int)getPVOItemAfterInventorySignCountForLocation:(int)pvoLoadID;
-(NSArray*)getPVORooms:(int)pvoLoadID withCustomerID:(int)custID;
-(NSArray*)getPVORooms:(int)pvoLoadID withDeletedItems:(BOOL)includeDeleted withCustomerID:(int)custID;
-(NSArray*)getPVORooms:(int)pvoLoadID withDeletedItems:(BOOL)includeDeleted andConditionOnly:(BOOL)includeConditionsOnly withCustomerID:(int)custID;
-(NSArray*)getPVOItemDamage:(int)itemID;
-(NSArray*)getPVOItemDamage:(int)itemID forDamageType:(int)damageType;
-(NSArray*)getPVOItemDamage:(int)itemID forDamageTypes:(NSArray*)damageTypes;
-(void)deletePVODamage:(int)pvoItemID withDamageType:(int)damageType;
-(void)savePVODamage:(PVOConditionEntry*)entry;
-(int)hasPVODamage:(int)pvoItemID forDamageType:(enum PVO_DAMAGE_TYPE)damageType;

// Get Carton Contents
-(NSArray*)getPVOAllCartonContents;
-(NSArray*)getPVOAllCartonContents:(int)custID;
-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID;
-(NSArray*)getPVOCartonContents:(int)pvoItemID withCustomerID:(int)custID;
-(NSArray*)getPVOAllCartonContents:(NSString*)search withCustomerID:(int)custID includeFavorites:(int)favorites withHidden:(BOOL)showHidden;
-(BOOL)pvoItemHasExpandedCartonContentItems:(int)pvoItemID;
-(BOOL)pvoCartonContentItemIsExpanded:(int)cartonContentID;
-(PVOCartonContent*)getPVOCartonContent:(int)contentID withCustomerID:(int)custID;
-(void)updatePVOCartonContents:(int)pvoItem withContents:(NSArray*)contents;
-(int)getPVONextCartonContentID;
-(BOOL)savePVOCartonContent:(PVOCartonContent*)content withCustomerID:(int)custID;
-(void)hidePVOCartonContent:(int)contentsID;
-(void)unhidePVOCartonContent:(int)contentsID;
-(PVOCartonContent*)getPVOItemCartonContent:(int)cartonContentID;
-(int)addPVOCartonContent:(int)contentID forPVOItem:(int)pvoItemID;
-(void)removePVOCartonContent:(int)cartonContentID withCustomerID:(int)custID;

-(NSArray*)getPVOFavoriteItemsWithCustomerID:(int)custID;
-(void)addPVOFavoriteItem:(int)itemID;
-(void)removePVOFavoriteItem:(int)itemID;


-(NSArray*)getPVOLots:(int)pvoUnloadID;

//signatures
-(int)savePVOSignature:(int)custID forImageType:(int)pvoImageType withImage:(UIImage*)image;
-(int)savePVOSignature:(int)custID forImageType:(int)pvoImageType withImage:(UIImage*)image withReferenceID:(int)referenceID;
-(NSString*)getPVOSignaturePrintedName:(int)pvoSignatureID;
-(void)deletePVOSignaturePrintedName:(int)custID forImageType:(int)pvoImageType;
-(void)deletePVOSignaturePrintedName:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID;
-(void)savePVOSignaturePrintedName:(NSString*)printedName withPVOSignatureID:(int)pvoSignatureID;
-(PVOSignature*)getPVOSignature:(int)custID forImageType:(int)pvoImageType;
-(PVOSignature*)getPVOSignature:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID;
-(void)deletePVOSignature:(int)custID forImageType:(int)pvoImageType;
-(void)deletePVOSignature:(int)custID forImageType:(int)pvoImageType withReferenceID:(int)referenceID;
-(NSArray*)getPVOSignatures:(int)custID;

-(PVORoomConditions*)getPVORoomConditions:(int)pvoLoadID andRoomID:(int)roomID;
-(PVORoomConditions*)getPVODestinationRoomConditions:(int)pvoLoadID andRoomID:(int)roomID;
-(int)savePVORoomConditions:(PVORoomConditions*)data;
-(NSDictionary*)getPVORoomFloorTypes;
-(BOOL)roomHasPVOInventoryItems:(int)roomID;
-(PVORoomConditions*)getPVORoomConditions:(int)roomConditionsID;

-(PVORoomConditions*)getPVODestinationRoomConditions:(int)pvoUnloadID andRoomID:(int)roomID;
-(int)savePVODestinationRoomConditions:(PVORoomConditions*)data;
-(PVORoomConditions*)getPVODestinationRoomConditions:(int)roomConditionsID;
-(NSArray*)getPVODestinationRooms:(int)pvoUnloadID;
-(void)deletePVODestinationRoom:(int)pvoUnloadID andRoom:(int)roomid;

-(BOOL)pvoHasItemsWithDescription:(int)custID forDescription:(NSString*)desc;
-(BOOL)pvoHasHighValueItems:(int)custID;
-(void)removeHighValueCostForCustomerItems:(int)custID;
-(int)getPvoHighValueItemsCountForLoad:(int)loadID;
-(int)getPvoHighValueItemsCount:(int)custID;
-(int)getPvoDeliveredItemsCount:(int)custID;
-(int)getPvoNotDeliveredItemsCount:(int)custID;
-(NSDictionary*)getPackersInventoryInitialCounts:(int)custID;
-(void)savePVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType withImage:(UIImage*)image;
-(PVOHighValueInitial*)getPVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType;
-(NSArray*)getAllPVOHighValueInitials:(int)pvoItemID;
-(void)deletePVOHighValueInitial:(int)pvoItemID forInitialType:(int)pvoImageType;

-(int)savePVOUnload:(PVOInventoryUnload*)entry;
-(NSArray*)getPVOUnloads:(int)custID;
-(PVOInventoryUnload*)getPVOUnload:(int)pvoUnloadID;
-(PVOInventoryUnload*)getFirstPVOUnload:(int)custID forPVOLocationID:(int)pvoLocationID;
-(BOOL)pvoLoadAvailableForUnload:(int)pvoLoadID;

-(NSArray*)getAllPVOItemDescriptions:(int)pvoItemID withCustomerID:(int)custID;
-(NSArray*)getPVOItemDescriptions:(int)pvoItemID withCustomerID:(int)custID;
-(NSArray*)getPVOReceivableItemDescriptions:(int)pvoItemID;
-(void)savePVODescriptions:(NSArray*)descriptionEntries forItem:(int)pvoItemID;
-(void)duplicatePVODescriptionsForQuickScan:(int)newItemID forPVOItem:(int)originalItemID;

-(int)savePVOClaimItem:(PVOClaimItem*)data;
-(NSArray*)getPVOClaimItems:(int)pvoClaimID;
-(int)savePVOClaim:(PVOClaim*)data;
-(NSArray*)getPVOClaims:(int)custID;
-(void)deletePVOClaim:(int)pvoClaimID;
-(void)deletePVOClaimItem:(int)pvoClaimItemID;

-(NSArray*)getPVOWeightTickets:(int)custID;
-(int)savePVOWeightTicket:(PVOWeightTicket*)weightTicket;
-(void)deletePVOWeightTicket:(int)weightTicketID forCustomer:(int)custid;

-(void)setPVOItemsInventoriedBeforeSignature:(int)custID;


-(NSArray*)getPVOVerifyInventoryOrders;
-(NSArray*)getPVOVerifyInventoryItems;
-(int)getPVOVerifyInventoryItemCount:(NSArray*)loads;
-(void)pvoDeleteVerifyItem:(PVOVerifyInventoryItem*)item;
-(NSDictionary*)getLanguages;
-(int)getLanguageForCustomer:(int)customerId;
-(void)resetLanguageWithCustomerID:(int)custID code:(int)code;

-(void)pvoSetDataIsDirty:(BOOL)dirty forType:(int)dataType forCustomer:(int)customerID;
-(BOOL)pvoCheckDataIsDirty:(int)dataType forCustomer:(int)customerID;


-(NSMutableArray*)getAllPackersInitials;
-(void)savePackersInitials:(NSString*)initials;
-(void)deletePackersInitials:(NSString*)initials;
-(BOOL)packersInitialsExists:(NSString*)initials;

-(BOOL)hasPVOReceivableItems:(int)custID receivedType:(int)receivedType ignoreReceived:(BOOL)ignoreReceived;
-(NSMutableArray*)getPVOReceivableRooms:(int)custID;
-(NSMutableArray*)getPVOReceivableItems:(int)custID;
-(NSMutableArray*)getPVOReceivableItems:(int)custID ignoreReceived:(BOOL)ignoreReceived forRoom:(int)roomID;
-(NSMutableArray*)getPVOReceivableItems:(int)custID ignoreReceived:(BOOL)ignoreReceived forRoom:(int)roomID isVoided:(int)voided;
-(PVOItemDetailExtended*)getPVOReceivableItem:(int)receivableItemID;
-(void)savePVOReceivableItem:(PVOItemDetailExtended*)item forCustID:(int)custID;
-(void)removePVOReceivableItem:(int)receivableItemID;
-(void)savePVOReceivableItems:(NSArray*)allItems forCustomer:(int)custID;
-(void)savePVOReceivableItems:(NSArray*)allItems forCustomer:(int)custID ignoreIfInventoried:(BOOL)ignoreIfInventoried;
-(BOOL)pvoInventoryItemExists:(int)custID withItemNumber:(NSString*)itemNumber andLotNumber:(NSString*)lotNumber andTagColor:(int)color;
-(BOOL)pvoReceivableItemExists:(int)custID withReceivedType:(int)receivedType andItemNumber:(NSString*)itemNumber andLotNumber:(NSString*)lotNumber andTagColor:(int)color;
-(void)setPVOReceivedItemsType:(int)receiveType forCustomer:(int)custID;
-(int)getPVOReceivedItemsType:(int)custID;

-(NSArray*)getDeliveredPVOItems:(int)pvoUnloadID;

-(int)getPVOLoadCount:(int)custID;

-(int)getPVOReceivedItemsUnloadType:(int)custID;
-(void)setPVOReceivedItemsUnloadType:(int)receiveUnloadType forCustomer:(int)custID;

-(BOOL)pvoLocationLimitItems:(int)pvoLocationID;

-(void)movePVOInventoryItem:(PVOItemDetail *)item toNewRoom:(Room *)room;

-(NSArray*)getPVOFavoriteCartonContents:(NSString*)search;
-(void)addPVOFavoriteCartonContents:(int)contentID;
-(void)removePVOFavoriteCartonContents:(int)contentID;

//-(NSString*)getReportNotes:(int)custID forType:(int)reportNoteType;
-(PVOReportNote*)getReportNotes:(int)custID forType:(int)reportNoteType;
-(void)saveReportNotes:(PVOReportNote*)rptNote forCustomer:(int)custID;
-(NSArray*)getAllReportNotes:(int)custID;
-(void)saveReceivableReportNotes:(NSArray*)reportNotes forCustomer:(int)custID;
-(void)getReceivableReportNotesForCustomer:(int)custID;

//military
-(int)getPVOItemCountMpro:(int)customerID;
-(int)getPVOItemCountSpro:(int)customerID;
-(int)getPVOItemCountCons:(int)customerID;
-(int)getPVOItemCountNonMproSpro:(int)customerID;
-(NSArray*)getPVOItemsMproSproForLoad:(int)loadID isMpro:(BOOL)mpro;
-(BOOL)autoCalculateInventoryMilitaryWeights:(int)custID;
-(int)getPVOItemWeightMpro:(int)custID;
-(int)getPVOItemWeightSpro:(int)custID;
-(int)getPVOItemWeightCons:(int)custID;

//backups
-(void)saveNewBackup:(BackupRecord*)data;
-(void)deleteBackup:(BackupRecord*)data;
-(NSArray*)getAllBackups;
-(AutoBackupSchedule*)getBackupSchedule;
-(void)saveBackupSchedule:(AutoBackupSchedule*)sched;

//documents
-(NSArray*)getGlobalDocs;
-(NSArray*)getGlobalDocs:(int)vanlineID;
-(NSArray*)getCustomerDocs:(int)customerID;
-(void)deleteDocLibraryEntry:(DocLibraryEntry*)data;
-(int)saveDocLibraryEntry:(DocLibraryEntry*)data;
-(int)saveDocLibraryEntry:(DocLibraryEntry*)data withVanline:(int)vanlineID;

//dynamic data
-(void)savePVODynamicReportDataEntry:(PVODynamicReportData*)data;
-(void)savePVODynamicReportData:(NSArray*)dataEntries;
- (NSMutableArray*)getPVODynamicReportData:(int)customerID forReport:(int)reportID sectionID:(int)section;
- (NSMutableArray*)getPVODynamicReportData:(int)customerID;
- (BOOL)pvoDynamicReportDataExists:(int)customerID forReport:(int)reportTypeID;

//html reports
-(BOOL)htmlReportIsCurrent:(ReportOption*)reportOption;
-(BOOL)htmlReportSupportsImages:(int)reportTypeID;
-(BOOL)htmlReportExistsForReportType:(int)reportTypeID;
-(BOOL)htmlReportExists:(ReportOption*)reportOption;
-(void)saveHTMLReport:(ReportOption*)htmlReport;
//- (ReportOption*)getHTMLReportData:(int)reportID;
- (ReportOption*)getHTMLReportDataForReportType:(int)reportTypeID;
-(BOOL)updateHTMLReportBundleLocations;

//pvo item comment
-(NSArray*)getAllPVOItemCommentsForItem:(int)pvoItemID;
-(NSArray*)getAllPVOItemCommentsForItem:(int)pvoItemID isReceivable:(BOOL)isReceivable;
-(PVOItemComment*)getPVOItemComment:(int)pvoItemID withCommentType:(int)commentType;
-(PVOItemComment*)getPVOItemComment:(int)pvoItemID withCommentType:(int)commentType isReceivable:(BOOL)isReceivable;
-(BOOL)savePVOItemComment:(NSString*)comment withPVOItemID:(int)pvoItemID withCommentType:(int)commentType;
-(void)deletePVOItemComment:(int)pvoItemID withCommentType:(int)commentType;
-(void)deletePVOItemPhotos:(int)pvoItemID withPhotoType:(int)photoType;

// alias
-(NSString*)getRoomAlias:(int)customerID withRoomID:(int)roomID;
-(void)saveRoomAlias:(NSString*)alias withCustomerID:(int)csID andRoomID:(int)roomID;

//pvo vehicles
-(PVOVehicle*)getPVOVehicleForID:(int)pvoVehicleID;
-(NSMutableArray*)getAllVehicles:(int)customerID;
-(int)saveVehicle:(PVOVehicle*)vehicle;
-(void)deleteVehicle:(PVOVehicle*)vehicle;

//pvo vehicle images
-(NSMutableArray*)getAllVehicleImages:(int)vehicleID withCustomerID:(int)customerID;
-(void)saveVehicleImage:(int)imageID withVehicleID:(int)vehicleID withCustomerID:(int)customerID;

//pvo vehicle damages
-(NSArray*)getPVOVehicleWireframeTypes:(int)customerID;
-(NSArray*)getVehicleDamages:(int)vehicleID;
-(NSArray*)getVehicleDamages:(int)vehicleID withImageID:(int)imageID;
-(void)savePVOWireframeDamages:(NSArray*)damages forWireframeItemID:(int)wireframeItemID withImageID:(int)imageID withIsVehicle:(BOOL)isVehicle;
//wireframe damages
-(NSArray*)getWireframeDamages:(int)wireframeItemID;
-(NSArray*)getWireframeDamages:(int)wireframeItemID withImageID:(int)imageID;
-(NSArray*)getWireframeDamages:(int)wireframeItemID withImageID:(int)imageID withIsVehicle:(BOOL)isVehicle;

//pvo check list
-(NSArray*)getCheckListItems:(int)customerID withVehicleID:(int)vehicleID withAgencyCode:(NSString*)haulingAgent;
-(void)savePVOVehicleCheckListForAgency:(NSArray*)vehicleCheckListItems withAgencyCode:(NSString*)agencyCode;
-(void)saveVehicleCheckList:(NSArray*)vehicleCheckList;

//bulky inventory
-(NSMutableArray*)getPVOBulkyData:(int)pvoBulkyItemID;
-(void)savePVOBulkyData:(NSArray*)dataEntries withPVOBulkyItemID:(int)pvoBulkyItemID;
-(void)savePVOBulkyDataEntry:(PVOBulkyData*)data;
-(int)getPVOBulkyItemCount:(int)pvoBulkyTypeID forCustomer:(int)customerID;
-(int)savePVOBulkyInventoryItem:(int)customerID withPVOBulkyItem:(PVOBulkyInventoryItem *)pvoBulkyItem;
-(int)insertNewPVOBulkyInventoryItem:(int)customerID withPVOBulkyItem:(PVOBulkyInventoryItem *)pvoBulkyItem;
-(NSArray*)getPVOBulkyInventoryItems:(int)customerID;
-(NSArray*)getPVOBulkyInventoryItems:(int)customerID withPVOBulkyItemType:(int)pvoBulkyItemTypeID;
-(PVOBulkyInventoryItem*)getPVOBulkyInventoryItemByID:(int)pvoBulkyItemID;
-(int)updatePVOBulkyInventoryItem:(PVOBulkyInventoryItem*)bulkyItem;
-(void)deleteAllPVOBulkyInventoryItemsForCustomer:(int)customerID;
-(void)deletePVOBulkyInventoryItem:(int)pvoBulkyItemID;
-(NSArray*)getPVOBulkyWireframeTypesForCustomer:(int)customerID;

- (void)createSirvaActivationTable;

// UploadTracking table methods
-(NSMutableArray*)getAllDirtyReports;
-(NSArray*)getUploadTrackingRecordsForCustomer:(int)cID;
-(NSString*)getCustomerRejectedDeliveryWaiverDate:(int)custID;
-(int)numberOfUploadTrackingRecordsForCustomer:(int)cID;
-(NSMutableArray*)getAllDirtyReportsForCustomer:(int)cID;
-(BOOL)getReportWasUploaded:(int)cID forNavItem:(int)nID;
-(void)setReportWasUploaded:(bool)wasUploaded forCustomer:(int)cID forNavItem:(int)nID;

-(NSMutableArray*)getAllItems:(BOOL)checkInclude withCustomerID:(int)customerID ignoreItemListId:(BOOL)ignore;

// Completion Dates methods
-(void)setCompletionDate:(int)customerID isOrigin:(BOOL)origin;
-(void)removeCompletionDate:(int)customerID isOrigin:(BOOL)origin;

@end


