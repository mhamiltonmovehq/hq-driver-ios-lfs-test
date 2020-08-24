//
//
//  AppFunctionality.m
//  Survey
//
//  Created by Lee Zumstein on 10/2/13.
//
//

#import "AppFunctionality.h"
#import "DriverData.h"
#import "Prefs.h"
#import "ItemType.h"
#import "CustomerUtilities.h"
#import "SurveyAppDelegate.h"
#import "PVOPrintController.h"

@implementation AppFunctionality

+(int)supportedNumberOfPVOLoads:(enum PRICING_MODE_TYPE)pricingMode
{
    if (pricingMode == INTERSTATE)
        return 1;
    else
        return -1;
}

+(int)maxNotesLengh:(enum PRICING_MODE_TYPE)pricingMode
{
        return -1;
}

+(BOOL)supportIndividualBlankDates:(enum PRICING_MODE_TYPE)pricingMode
{
        return NO;
}

+(BOOL)disableScanner:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType
{
    //always allow per defect 541
    return NO;
}

+(BOOL)disableTractorTrailer:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType
{
    if (pricingMode == INTERSTATE)
    {
        switch (driverType) {
            case PVO_DRIVER_TYPE_PACKER:
                return YES;
            default:
                return NO;
        }
    }
    else
    {
        return NO;
    }
}

+(BOOL)disablePackersInventory
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanline = [del.pricingDB vanline];
    switch (vanline) {
        case 155:
        case ARPIN:
        case GRAEBEL:
        case ALLIED:
        case NORTH_AMERICAN:
        case SIRVA:
            return NO;
        default:
            return ([Prefs betaPassword] == nil || [[Prefs betaPassword] rangeOfString:@"packer"].location == NSNotFound); //disable if beta password not present
    }
}

+(BOOL)showAgencyCodeOnDownload
{
    if ([self disablePackersInventory])
        return NO;
    else
        return YES;
    
//  no vanline specific logic needed right now, if packers inventory is enabled, go ahead and show this on the sync controller
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if ([del.pricingDB vanline] == 155 || [del.pricingDB vanline] == ARPIN) //ENABLED for demo and arpin
//        return YES;
    
//    return ([Prefs betaPassword] == nil || [[Prefs betaPassword] rangeOfString:@"packer"].location == NSNotFound);
}

+(BOOL)isSpecialProducts:(enum PRICING_MODE_TYPE)pricingMode withLoadType:(enum PVO_LOAD_TYPES)loadType
{
    //right now not dependent on pricing mode
    return (loadType == COMMERCIAL || loadType == SPECIAL_PRODUCTS || loadType == DISPLAYS_EXHIBITS);
}

+(BOOL)expandedCartonContents:(enum PRICING_MODE_TYPE)pricingMode
{
    return YES;
}

+(ItemType*)getItemTypes:(enum PRICING_MODE_TYPE)pricingMode withDriverType:(int)driverType withLoadType:(enum PVO_LOAD_TYPES)loadType
{
    ItemType *itemTypes = [[ItemType alloc] init];
    if (pricingMode == 0 && driverType == PVO_DRIVER_TYPE_PACKER) {
        //hide everything except CP/Crate
        [itemTypes addAllowedItemTypes:[NSSet setWithObjects:[NSNumber numberWithInt:ITEM_TYPE_CP], [NSNumber numberWithInt:ITEM_TYPE_CRATE], nil]];
    } else if (loadType == MILITARY) {
        //hide PBO's, allow everything else
        [itemTypes addHiddenItemType:ITEM_TYPE_PBO];
    }
    return itemTypes;
}

+(BOOL)lockInventoryLoadTypeOnDownload:(enum PRICING_MODE_TYPE)pricingMode
{
    // this should not lock for anyone until all of our systems talk correctly.  Per Jeff B. on 6/2/17.
    return NO;
//    
//#if defined(DEBUG) || defined(ATLASNET)
//    return NO;
//#else
//    
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if ([del.pricingDB vanline] == ARPIN) //never lock for arpin
//        return NO;
//    else
//        return (pricingMode == 0); //lock on Interstate download
//#endif
        }

+(BOOL)showCrateDimensionsForCartonContent
{
    return NO;
}

+(BOOL)showPackerInitialsForDriver
{
    if ([self disablePackersInventory])
        return NO; //packer's inventory is disabled
    else
        return YES; //always show
}

+(BOOL)disableRiderExceptions
{
    if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"rider"].location != NSNotFound)
        return NO; //enabled by beta password
    return YES; //hiding this feature for the 1.8.1 release
}

+(BOOL)disableSynchronization
{
    return NO;
}

+(BOOL)lockFieldsOnSourcedFromServer
{
#ifdef ATLASNET
    return NO;
#endif
    return YES;
}

+(BOOL)isAvailablePricingModeForNewJob:(enum PRICING_MODE_TYPE)pricingMode
{
    return YES; //allow all of em
}

+(NSDictionary*)getPricingModesForNewJob
{
    NSMutableDictionary *pricingModes = [[CustomerUtilities getPricingModes] mutableCopy];
    
    NSMutableArray *remove = [[NSMutableArray alloc] init];
    for (NSNumber *key in [pricingModes keyEnumerator]) {
        if (![AppFunctionality isAvailablePricingModeForNewJob:[key intValue]])
            [remove addObject:key];
    }
    if (remove != nil && [remove count] > 0) {
        [pricingModes removeObjectsForKeys:remove];
    }
    
    return pricingModes;
}

+(NSArray*)getDemoOrderNumbers
{
#ifdef ATLASNET
    return nil;
#else
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if ([del.pricingDB vanline] == 155 /*Demo Van Lines*/) //enabled for everyone per OT Defect 13010
    NSMutableArray *demoOrderNumbers = [[NSMutableArray alloc] initWithObjects:@"DEMO1", @"DEMO2", @"DEMOSURVEY1", @"DEMOSURVEY2", @"DEMOMILITARY1", @"DEMOMILITARY2", nil];
    if (![AppFunctionality disablePackersInventory]) {
        [demoOrderNumbers addObject:@"DEMOPACK1"];
        [demoOrderNumbers addObject:@"DEMOPACK2"];
    }
    
    return demoOrderNumbers;
//        return [[NSMutableArray alloc] initWithObjects:@"DEMO1", [AppFunctionality disablePackersInventory] ? nil : @"DEMOPACK1", nil];

#endif
}

+(NSString*)getDemoOrderDisplay
{
#ifdef ATLASNET
    return nil;
#else
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if ([del.pricingDB vanline] == 155 /*Demo Van Lines*/) {
    
        NSString *demo1 = @"DEMO1";
        NSString *demoPack1 = @"DEMOPACK1";
        NSString *demo2 = @"DEMO2 (no inventory)";
        NSString *demoPack2 = @"DEMOPACK2 (no inventory)";
        NSString *surveyDemo1 = @"DEMOSURVEY1";
        NSString *surveyDemo2 = @"DEMOSURVEY2 (no inventory)";
        NSString *militaryDemo1 = @"DEMOMILITARY1";
        NSString *militaryDemo2 = @"DEMOMILITARY2 (no inventory)";
    
        if ([AppFunctionality disablePackersInventory])
            return [NSString stringWithFormat:@"Driver:\r\n%@\r\n%@\r\n%@\r\n%@\r\n%@\r\n%@",
                    demo1, demo2, surveyDemo1, surveyDemo2, militaryDemo1, militaryDemo2];
        else
            return [NSString stringWithFormat:
                    @"Packer:\r\n%@\r\n%@\r\n\r\nDriver:\r\n%@\r\n%@\r\n%@\r\n%@\r\n\r\n%@\r\n%@\r\n%@\r\n%@",
                    demoPack1, demoPack2, demo1, demoPack1, surveyDemo1, militaryDemo1, demo2, demoPack2, surveyDemo2, militaryDemo2];
//    }
//    return nil;
#endif
}

+(BOOL)isDemoOrder:(NSString*)orderNum
{
    NSArray *demoOrders = [AppFunctionality getDemoOrderNumbers];
    if (demoOrders != nil && [demoOrders count] > 0)
    {
        for (NSString *ord in [demoOrders objectEnumerator]) {
            if (ord != nil && orderNum != nil && [[ord lowercaseString] isEqualToString:[orderNum lowercaseString]])
                return YES;
        }
    }
    return NO;
}

+(NSString*)getDemoOrderFilePath:(NSString*)orderNum
{
    if ([AppFunctionality isDemoOrder:orderNum])
        return [[NSBundle mainBundle] pathForResource:[orderNum lowercaseString] ofType:@"xml"];
    return nil;
}

+(BOOL)showDittoFunctionOnExceptions:(PVOItemDetail*)pvoItem isQuickScanScreen:(BOOL)quickScan
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    Item *item = [del.surveyDB getItem:pvoItem.itemID];
    
    return pvoItem.cartonContentID <= 0 && !quickScan;
//    
    
//#ifdef ATLASNET
//    return !quickScan;
//#else
//    if (item == nil || quickScan)
//        return NO;
//    else
//        return (item.isCP || item.isPBO);
//#endif
}

+(BOOL)canDeleteInventoryItems
{
    return YES;
}

+(NSString*)deliverAllPVOItemsAlertConfirm
{
    return @"By tapping Continue and signing the screen, I waive the right to check off items during the delivery process.";
}

+(NSString*)deliverAllPVOItemsSignatureLegal
{
    return @"By signing this screen, I waived the right to check off items during the delivery process.";
}

+(BOOL)allowNoCoditionsInventory:(enum PRICING_MODE_TYPE)pricingMode withLoadType:(enum PVO_LOAD_TYPES)loadType;
{
//    if ([AppFunctionality isSpecialProducts:pricingMode withLoadType:loadType]) //had functionality to allow this on special products
//        return YES;
    return YES;
}

+(enum HV_DETAILS_TYPE)getHighValueType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ARPIN)
        return HV_DETAILS_FLAG;
    else
        return HV_DETAILS_COST;
}

+(BOOL)grabHighValueInitials
{
    return [AppFunctionality getHighValueType] == HV_DETAILS_COST;
}

+(BOOL)promptForValuationTypeOnHighValueReport
{
    return NO;
}

+(NSString*)defaultReportingServiceCustomReportPass
{
#if defined(DEBUG) || defined(RELEASE)
#ifdef ATLASNET
    return nil;
#else
    return nil;
#endif
#else
    return nil;
#endif
}

+(BOOL)disableDocumentsLibrary
{
    return NO;
}

+(enum PVO_RECEIVE_TYPE)getPvoReceiveType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanline = [del.pricingDB vanline];

    if (vanline == ARPIN)
        return PVO_RECEIVE_ON_DOWNLOAD | PVO_RECEIVE_SCREEN;
    
    return PVO_RECEIVE_ON_DOWNLOAD;
}

+(BOOL)disableWeightTickets
{
#ifdef ATLASNET
    return YES;
#else
    return NO;
#endif
}

+(BOOL)disableAskOnDamageView
{
    return NO;
}


+(BOOL)removeSignatureOnNavigateIntoCompletedInv
{
#ifdef ATLASNET
    return YES;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanline = [del.pricingDB vanline];
    return vanline == ARPIN || vanline == SIRVA;
#endif
}

+(BOOL)showCubeAndWeight:(PVOInventory*)inventory 
{    
#ifdef ATLASNET
    return YES;
#endif
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanlineID = [del.pricingDB vanline];
    if (vanlineID == 155) //demo
        return YES;
    else if (vanlineID == ARPIN && inventory != nil && inventory.loadType == MILITARY)
        return YES;
    else
        return NO;    
    
}

+(BOOL)showCPProvided
{
#ifdef ATLASNET
    return YES;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == 155 /* Demo Van Lines*/) return YES;
    return NO;
#endif
}

+(BOOL)showPackOptions
{
#ifdef ATLASNET
    return YES;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == 155 /* Demo Van Lines*/) return YES;
    return NO;
#endif
}

+(BOOL)allowAnyLoadOnAnyUnload
{
#ifdef ATLASNET
    return YES;
#else
    return NO;
#endif
}

+(BOOL)requireSignatureForDeliverAll
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] != ARPIN;
}

+(BOOL)showCommentsOnExceptions
{
    return YES;
}

+(BOOL)showTractorTrailerAlways
{
#ifdef ATLASNET
    return NO;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == 155 /* Demo Van Lines*/) return NO;
    return YES;
#endif
}

+(BOOL)showTractorTrailerOptional
{
#ifdef ATLASNET
    return YES;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == 155 /* Demo Van Lines*/) return YES;
    return NO;
#endif
}

+(BOOL)showTractorTrailerOnBeginInventory:(enum PRICING_MODE_TYPE)pricingMode;
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ARPIN)
        return NO;
    
    DriverData *driver = nil;
    @try {
        driver = [del.surveyDB getDriverData];
        if ([AppFunctionality disableTractorTrailer:pricingMode withDriverType:driver.driverType])
            return NO;
        else if ([AppFunctionality showTractorTrailerAlways])
            return YES;
        else if ([AppFunctionality showTractorTrailerOptional])
            return driver.showTractorTrailerOptions;
        else
            return NO;
    }
    @finally {

    }
}

+(BOOL)includeToteItemsInCPPBO
{
    //go ahead and flag this as true for all installs, wasn't limited in previous version
    return YES;
}

+(BOOL)autoUploadInventoryReportOnSign
{
    //couldn't find this anywhere in the previous version of the application, go ahead and flag it as no
    return NO;
}

+(BOOL)autoUploadPPIAfterInventory
{
#ifdef ATLASNET
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (del.customerID <= 0)
        return NO;
    
    BOOL retval = NO;
    if ([SurveyCustomer isCanadianCustomer])
        retval = NO;
    else
        retval = YES;
    
    return retval;
#else
    return NO;
#endif
}

+(BOOL)showConfirmLotNumberOnBeginInventory
{
#ifdef ATLASNET
    return NO;
#endif
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] == ARPIN;
}

+(BOOL)allowWaiveRightsOnDelivery
{
#ifdef ATLASNET
    return YES;
#endif
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] != ARPIN;
}

+(BOOL)allowReportUploadFromPreview:(enum PRICING_MODE_TYPE)pricingMode
{
#ifdef ATLASNET
    return YES;
#endif
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ARPIN)
        return (pricingMode != INTERSTATE);
    return YES;
}

+(BOOL)includeEmptyRoomsInXML
{
    return YES;
}

+(BOOL)useAirPrintForPrinting
{
#ifdef ATLASNET
    return YES;
#endif
    return NO;
}

// Method that enables the ability to select "Send From Device" when trying to email a Report.
// This would bypass having to send the PDF up to MoverDocs, and would use the builtin Email client to send.
+(BOOL)allowSendingReportEmailFromDevice
{
    return NO; //per discussion with Tony, don't want to enable this just yet
}

+(int)webRequestTimeoutInSeconds
{
#ifdef TARGET_IPHONE_SIMULATOR
    return 60 * 4;
#endif
    
#ifdef ATLASNET
    return 60 * 3;  // 3 minute timeout value
#else
    return 60;      // 1 minute timeout value
#endif
}

+(BOOL)flagAllItemsAsVehicle
{
    return ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"allitems:vehicle"].location != NSNotFound);
}

+(BOOL)flagAllItemsAsGun
{
    return ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"allitems:gun"].location != NSNotFound);
}

+(BOOL)flagAllItemsAsElectronic
{
    return ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"allitems:electronic"].location != NSNotFound);
}

+(BOOL)disableCSVImport
{
#ifdef ATLASNET
    return NO;
#else
    return NO;
#endif
}

+(BOOL)useNewActiviationMethod
{
#ifdef ATLASNET
    return YES;
#else
    return NO;
#endif
}

+(BOOL)showCodesOnInventoryReport
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return ([del.pricingDB vanline] != ATLAS);
    
}

+(BOOL)addImageLocationsToXML
{
#ifdef ATLASNET
    return NO;
#else
    return YES;
#endif
}

+(NSString*) getHighValueDescription
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *value = ([del.pricingDB vanline] == ARPIN) ?  @"Extraordinary Value" : @"High Value";
    
    return value;
}

+(NSString*)getHighValueInitialsDescriptions
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *value = ([del.pricingDB vanline] == ARPIN) ?  @"EV" : @"HVI";
    
    return value;
}

+(BOOL)enableValuationType
{
#ifdef ATLASNET
    return NO;
#else
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] == ARPIN;
#endif
}
    
+(BOOL)enableSaveToServer
{
#ifdef ATLASNET
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (del.customerID <= 0)
        return NO;
    
//    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
//    if ([SurveyCustomer isCanadianCustomer])
//    {
//        
//        return NO;
//    }
    
    return YES;
#else
    return YES;
#endif
}

+(BOOL)showPrintedNameOnSignatureView:(int)signatureTypeID
{
    return signatureTypeID == PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG ||
    signatureTypeID == PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST ||
    signatureTypeID == PVO_SIGNATURE_TYPE_AUTO_INVENTORY ||
    signatureTypeID == PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG ||
    signatureTypeID == PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST;
    
}
+(BOOL)enablePackDatesSection
{
    return ![self customerIsAutoInventory];
}
+(BOOL)mustCompleteDeliveryForDestReports
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanlineID = [del.pricingDB vanline];
    switch (vanlineID) {
        case ATLAS:
        case UNITED_CANADA:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

+(BOOL)mustEnterMilitaryItemWeights:(PVOInventory*)data
{
    if (data.loadType == MILITARY)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        return [del.pricingDB vanline] == ARPIN;
    }
    
    return NO;
}

+(BOOL)customerIsAutoInventory
{
#ifdef ATLASNET
    return NO;
#endif
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.surveyDB getCustomer:del.customerID].inventoryType == AUTO;
}

+(BOOL)enableDestinationRoomConditions
{
//    SurveyAppDelegate *del = v[[UIApplication sharedApplication] delegate];
//
//    int vanlineID = [del.pricingDB vanline];
//    switch (vanlineID) {
//        case ARPIN:
//        case GRAEBEL:
//            return YES;
//            break;
//            
//        default:
//            return NO;
//    }
#ifdef ATLASNET
    return YES;
#else
    return YES;
#endif
}

+(BOOL)enableDocumentUploadWithSaveToServer
{
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] == ARPIN;
}

+(BOOL)enableCanadianPricingModes
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanlineID = [del.pricingDB vanline];
    switch (vanlineID) {
        case ATLAS:
        case UNITED_CANADA:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

+(BOOL)enableLanguageSelection:(int)pricingMode
{
    switch (pricingMode) {
        case CNCIV:
        case CNGOV:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

+(BOOL)enableMoveHQSettings
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get this out of the pricing db?
    return [del.pricingDB doesVanlineSupportCRM:[del.pricingDB vanline]];
}

+(BOOL)enableAddSettingsToBackupEmail
{
#if defined(DEBUG) || defined(RELEASE)
    return YES;
#endif
    return NO;
}

+(BOOL)enableWireframeExceptionsForItems
{
    return NO; //([Prefs betaPassword] == nil || [[Prefs betaPassword] rangeOfString:@"wireframe"].location == NSNotFound); //disable if beta password not present
}

+(BOOL)disableHiddenReports
{
#if DEBUG
    return NO;
#else
    return ([Prefs betaPassword] == nil || [[Prefs betaPassword] rangeOfString:@"allreports"].location == NSNotFound); //disable if beta password not present
#endif
}

+(BOOL)includeSecuritySealRowInItemDetails
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [del.pricingDB vanline] == ARPIN;
}

+(BOOL)uploadReportAfterSigning
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return ([del.pricingDB vanline] == ARPIN || [del.pricingDB vanline] == SIRVA) &&
            [SurveyAppDelegate hasInternetConnection] &&
            [[del.surveyDB getCustomer:del.customerID] pricingMode] != LOCAL;
}

+(BOOL)requiresPropertyCondition
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ATLAS) {
        PVOInventory *p = [del.surveyDB getPVOData:del.customerID];
        return p.loadType == SPECIAL_PRODUCTS;
    }
    return false;
}

@end
