//
//  AppFunctionality.h
//  Survey
//
//  Created by Lee Zumstein on 10/2/13.
//
//

#import <Foundation/Foundation.h>
#import "SurveyCustomer.h"
#import "PVOInventory.h"
#import "ItemType.h"
#import "PVOItemDetail.h"

enum HV_DETAILS_TYPE {
    HV_DETAILS_FLAG = 0,
    HV_DETAILS_COST = 1
};

enum PVO_RECEIVE_TYPE {
    PVO_RECEIVE_ON_DOWNLOAD = 1 << 0,
    PVO_RECEIVE_SCREEN      = 1 << 1
};

@interface AppFunctionality : NSObject

+(int)supportedNumberOfPVOLoads:(enum PRICING_MODE_TYPE)pricingMode;
+(int)maxNotesLengh:(enum PRICING_MODE_TYPE)pricingMode;
+(BOOL)supportIndividualBlankDates:(enum PRICING_MODE_TYPE)pricingMode;
+(BOOL)disableScanner:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType;
+(BOOL)disableTractorTrailer:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType;
+(BOOL)disablePackersInventory;
+(BOOL)showAgencyCodeOnDownload;
+(BOOL)isSpecialProducts:(enum PRICING_MODE_TYPE)pricingMode withLoadType:(enum PVO_LOAD_TYPES)loadType;
+(BOOL)expandedCartonContents:(enum PRICING_MODE_TYPE)pricingMode;
+(ItemType*)getItemTypes:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType withLoadType:(enum PVO_LOAD_TYPES)loadType;
+(BOOL)lockInventoryLoadTypeOnDownload:(enum PRICING_MODE_TYPE)pricingMode;
+(BOOL)showCrateDimensionsForCartonContent;
+(BOOL)showPackerInitialsForDriver;
+(BOOL)disableRiderExceptions;
+(BOOL)disableSynchronization;
+(BOOL)lockFieldsOnSourcedFromServer;
+(BOOL)isAvailablePricingModeForNewJob:(enum PRICING_MODE_TYPE)pricingMode;
+(NSDictionary*)getPricingModesForNewJob;
+(NSArray*)getDemoOrderNumbers;
+(NSString*)getDemoOrderDisplay;
+(BOOL)isDemoOrder:(NSString*)orderNum;
+(NSString*)getDemoOrderFilePath:(NSString*)orderNum;
+(BOOL)showDittoFunctionOnExceptions:(PVOItemDetail*)pvoItem isQuickScanScreen:(BOOL)quickScan;
+(BOOL)canDeleteInventoryItems;
+(NSString*)deliverAllPVOItemsAlertConfirm;
+(NSString*)deliverAllPVOItemsSignatureLegal;
+(BOOL)allowNoCoditionsInventory:(enum PRICING_MODE_TYPE)pricingMode withLoadType:(enum PVO_LOAD_TYPES)loadType;
+(enum HV_DETAILS_TYPE)getHighValueType;
+(BOOL)grabHighValueInitials;
+(BOOL)promptForValuationTypeOnHighValueReport;
+(NSString*)defaultReportingServiceCustomReportPass;
+(BOOL)disableDocumentsLibrary;
+(enum PVO_RECEIVE_TYPE)getPvoReceiveType;
+(BOOL)disableWeightTickets;
+(BOOL)disableAskOnDamageView;
+(BOOL)disableCSVImport;

+(BOOL)removeSignatureOnNavigateIntoCompletedInv;
+(BOOL)showCubeAndWeight:(PVOInventory*)inventory;
+(BOOL)enableMilitaryWeightEntryOnLandingController;
+(BOOL)showCPProvided;
+(BOOL)showPackOptions;
+(BOOL)allowAnyLoadOnAnyUnload;
+(BOOL)requireSignatureForDeliverAll;
+(BOOL)showCommentsOnExceptions;
+(BOOL)showTractorTrailerAlways;
+(BOOL)showTractorTrailerOptional;
+(BOOL)showTractorTrailerOnBeginInventory:(enum PRICING_MODE_TYPE)pricingMode;
+(BOOL)includeToteItemsInCPPBO;
+(BOOL)showPackDatesSection;
+(BOOL)autoUploadInventoryReportOnSign;
+(BOOL)autoUploadPPIAfterInventory;
+(BOOL)showConfirmLotNumberOnBeginInventory;
+(BOOL)allowWaiveRightsOnDelivery;
+(BOOL)allowReportUploadFromPreview:(enum PRICING_MODE_TYPE)pricingMode;
+(BOOL)includeEmptyRoomsInXML;
+(BOOL)useAirPrintForPrinting;
+(BOOL)allowSendingReportEmailFromDevice;
+(int)webRequestTimeoutInSeconds;

+(BOOL)flagAllItemsAsVehicle;
+(BOOL)flagAllItemsAsGun;
+(BOOL)flagAllItemsAsElectronic;
+(BOOL)useNewActiviationMethod;
+(BOOL)showCodesOnInventoryReport;

+(BOOL)addImageLocationsToXML;

+(NSString*) getHighValueDescription;
+(NSString*)getHighValueInitialsDescriptions;
+(BOOL)enableSaveToServer;
+(BOOL)enableCanadianPricingModes;
+(BOOL)enableLanguageSelection:(int)pricingMode;

+(BOOL)enableValuationType;
+(BOOL)mustCompleteDeliveryForDestReports;
+(BOOL)mustEnterMilitaryItemWeights:(PVOInventory*)data;
+(BOOL)enableDestinationRoomConditions;
+(BOOL)showPrintedNameOnSignatureView:(int)signatureTypeID;
+(BOOL)enablePackDatesSection;
+(BOOL)customerIsAutoInventory;
+(BOOL)enableDocumentUploadWithSaveToServer;
+(BOOL)enableMoveHQSettings;
+(BOOL)enableAddSettingsToBackupEmail;

+(BOOL)enableWireframeExceptionsForItems;
+(BOOL)disableHiddenReports;

+(BOOL)includeSecuritySealRowInItemDetails;
+(BOOL)uploadReportAfterSigning;
+(BOOL)requiresPropertyCondition;

@end
