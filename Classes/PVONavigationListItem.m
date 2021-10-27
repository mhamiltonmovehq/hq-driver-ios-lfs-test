//
//  PVONavigationListItem.m
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVONavigationListItem.h"
#import "SurveyAppDelegate.h"
#import "PVOSignature.h"
#import "PVOPrintController.h"

@implementation PVONavigationListItem

@synthesize navItemID;
@synthesize display;
@synthesize required;
@synthesize reportNoteType;
@synthesize imageDisplayType;

-(id)init
{
    self = [super init];
    if(self)
    {
        //enabled = YES;
    }
    return self;
}

-(BOOL)getReportWasUploaded:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(![self isReportOption]){
        return NO;
    }
    
    return [del.surveyDB getReportWasUploaded:custID forNavItem:navItemID];
}

-(void)setReportWasUploaded:(BOOL)wasUploaded forCustomer:(int)custID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB setReportWasUploaded:wasUploaded forCustomer:custID forNavItem:navItemID];
}

-(BOOL)hasRequiredSignatures
{
    if([self isBulky]){
        return [self hasAllRequiredBulkySignatures];
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *reqSigs = [[del.pricingDB
                         getRequiredSignaturesForNavItem:navItemID]
                        componentsSeparatedByString:@","];
    
    for(int i = 0; i < reqSigs.count; i++){
        int c = _custID == 0 ? del.customerID : _custID;
        if([del.surveyDB getPVOSignature:c forImageType:[reqSigs[i] intValue]] == nil){
            return NO;
        }
    }
    return YES;
}

-(BOOL)isBulky
{
    return (navItemID == PVO_BULKY_INVENTORY_ORIG_REPORT || navItemID == PVO_BULKY_INVENTORY_DEST_REPORT);
}

-(BOOL)hasAllRequiredBulkySignatures
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int c = _custID == 0 ? del.customerID : _custID;
    
    NSArray *bulkies = [del.surveyDB getPVOBulkyInventoryItems:c];
    if([bulkies count] == 0){
        return NO;
    }
    
    NSArray *reqSigs = [[del.pricingDB getRequiredSignaturesForNavItem:navItemID] componentsSeparatedByString:@","];
    int s = [reqSigs[0] intValue];
    
    for(PVOBulkyInventoryItem *b in bulkies)
    {
        PVOSignature *sig = [del.surveyDB getPVOSignature:c
                                             forImageType:s
                                          withReferenceID:b.pvoBulkyItemID];
        if(sig == nil) {
            return NO;
        }
    }
    
    return YES;
}


+(int)reportIDForNavID:(int)navID
{
    switch (navID) {
        case PVO_P_ESIGN_AGREEMENT:
            return ESIGN_AGREEMENT;
            break;
        case PVO_P_ROOM_CONDITIONS:
            return ROOM_CONDITIONS;
            break;
        case PVO_P_EX_PU_INV:
            return EXTRA_PU_INV;
        case PVO_P_INV_CARTON_DETAIL:
            return INVENTORY;
        case PVO_P_HVI_INSTRUCTIONS:
            return LOAD_HVI_INSTRUCTIONS;
        case PVO_P_ORG_HIGH_VALUE:
            return LOAD_HIGH_VALUE;
        case PVO_P_ATLAS_ORG_HIGH_VALUE:
            return LOAD_HVI_AND_CUST_RESPONSIBILITIES;
        case PVO_P_DEL_HIGH_VALUE:
            return DEL_HIGH_VALUE;
        case PVO_P_GYPSY_MOTH:
            return GYPSY_MOTH;
        case PVO_P_EX_DEL:
            return EXTRA_DELIVERY;
        case PVO_P_DEL_EXCP:
            return DELIVERY_INVENTORY;
        case PVO_P_HARDWARE_INVENTORY:
            return HARDWARE_INVENTORY;
        case PVO_P_PRIORITY_INVENTORY:
            return PRIORITY_INVENTORY;
        case PVO_VIEW_BOL:
            return VIEW_BOL;
        case PVO_P_PACK_PER_INVENTORY:
            return PACK_PER_INVENTORY;
        case PVO_P_PACKING_SERVICES:
            return PACKING_SERVICES;
        case PVO_P_ASPOD_ORIGIN:
            return ORIGIN_ASPOD;
        case PVO_P_ASPOD_DESTINATION:
            return DESTINATION_ASPOD;
        case PVO_P_DELIVER_ALL_CONFIRM:
            return DELIVER_ALL_CONFIRM;
    }
    
    return -1;
}

+(NSString*)signatureIDForNavID:(int)navID
{
    switch (navID) {
        case PVO_P_ESIGN_AGREEMENT:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT];
        case PVO_P_ROOM_CONDITIONS:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ROOM_CONDITIONS];
        case PVO_P_INV_CARTON_DETAIL:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ORG_INVENTORY];
        case PVO_P_ORG_HIGH_VALUE:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE];
        case PVO_P_ATLAS_ORG_HIGH_VALUE:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE];
        case PVO_P_DEL_HIGH_VALUE:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_DEST_HIGH_VALUE];
        case PVO_P_DEL_EXCP:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_DEST_INVENTORY];
        case PVO_P_HARDWARE_INVENTORY:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_HARDWARE_INVENTORY];
        case PVO_P_PRIORITY_INVENTORY:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_PRIORITY_INVENTORY];
        case PVO_P_PACKING_SERVICES:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_PACKING_SERVICES];
        case PVO_P_ASPOD_ORIGIN:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_ORIGIN_ASPOD];
        case PVO_P_ASPOD_DESTINATION:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_DESTINATION_ASPOD];
        case PVO_P_DELIVER_ALL_CONFIRM:
            return [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_DELIVER_ALL];
    }
    
    return @"";
}

-(BOOL)isReportOption
{
    return self.reportTypeID != -1;
}

-(int)getPVOChangeDataToCheck
{
    int data = PVO_DATA_LOAD_ITEMS;
    if(self.reportTypeID == LOAD_HIGH_VALUE)
        data = PVO_DATA_LOAD_HIGH_VALE;
    else if(self.reportTypeID == DELIVERY_INVENTORY)
        data = PVO_DATA_DELIVER_ITEMS;
    else if(self.reportTypeID == DEL_HIGH_VALUE)
        data = PVO_DATA_DELIVER_HIGH_VALUE;
    else if(self.reportTypeID == ROOM_CONDITIONS)
        data = PVO_DATA_ROOM_CONDITIONS;
    else if(self.reportTypeID == AUTO_INVENTORY_ORIG)
        data = PVO_DATA_AUTO_INVENTORY_ORIG;
    else if(self.reportTypeID == AUTO_INVENTORY_DEST)
        data = PVO_DATA_AUTO_INVENTORY_DEST;
    else if(self.reportTypeID == AUTO_BOL_ORIG)
        data = PVO_DATA_AUTO_BOL_ORIG;
    else if(self.reportTypeID == AUTO_BOL_DEST)
        data = PVO_DATA_AUTO_BOL_DEST;
    
    return data;
}

-(BOOL)enableUploadFromShipmentMenu
{
    switch (self.reportTypeID) {
        case AUTO_INVENTORY_ORIG:
        case AUTO_INVENTORY_DEST:
        case AUTO_BOL_ORIG:
        case AUTO_BOL_DEST:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

-(BOOL)hasReportNotes
{
    return ([self isReportOption] && reportNoteType > 0);
}

-(BOOL)enabled
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    switch (navItemID)
    {
        case PVO_ERROR_STATE:
            return NO;
        case PVO_P_HARDWARE_INVENTORY:
            return [del.surveyDB pvoHasItemsWithDescription:del.customerID forDescription:@"HW"];
        case PVO_P_PRIORITY_INVENTORY:
            return [del.surveyDB pvoHasItemsWithDescription:del.customerID forDescription:@"PR"];
        case PVO_P_RIDER_EXCEPTIONS:
            {
                BOOL hasWarehouseReceive = NO;
                NSArray *loads = [del.surveyDB getPVOLocationsForCust:del.customerID];
                if (loads != nil)
                {
                    for (PVOInventoryLoad *l in loads)
                    {
                        hasWarehouseReceive = (l != nil && l.receivedFromPVOLocationID == WAREHOUSE && l.pvoLocationID != WAREHOUSE);
                        if (hasWarehouseReceive) break;
                    }
                }
                return hasWarehouseReceive;
            }
    }
    
    return YES;
}

/*-(NSString*)display
{
    switch (cellTag) {
        case PVO_ENTER_TARE_WEIGHT:
            return @"Tare Weight";
        case PVO_CONFIRM_VALUATION:
            return @"Confirm Valuation";
        case PVO_CONFIRM_LOAD_DATE:
            return @"Confirm Load Date";
        case PVO_INVENTORY:
            return @"Inventory";
        case PVO_ORIGIN_SERVICES:
            return @"Origin Services";
        case PVO_GENERAL_COMMENTS:
            return @"General Comments";
        case PVO_PAYMENT_METHOD:
            return @"Confirm Payment Method";
        case PVO_ORG_PROPERTY_DAMAGE:
            return @"Property Damage";
        case PVO_P_EX_PU_INV:
            return @"Print Ex P/U Inventory";
        case PVO_P_INV_CARTON_DETAIL:
            return @"Print Inventory/Carton Detail";
        case PVO_P_COST_DETAIL:
            return @"Print Cost Detail";
        case PVO_P_BOL_TERMS:
            return @"Print BOL Terms & Conditions";
        case PVO_P_GYPSY_MOTH:
            return @"Print Gypsy Moth Form";
        case PVO_ORG_COMPLETE:
            return @"Origin Actions Complete";
        case PVO_GROSS_WEIGHT:
            return @"Gross Weight";
        case PVO_OA_CHARGES:
            return @"OA Charges";
        case PVO_RATE_SHIPMENT:
            return @"Rate Shipment";
        case PVO_SEND_INV_SERVICES:
            return @"Send Inventory & Services";
        case PVO_IN_ROUTE_COMPLETE:
            return @"In Route Actions Complete";
        case PVO_REWEIGH:
            return @"Reweigh";
        case PVO_DEST_SERVICES:
            return @"Destination Services";
        case PVO_RE_RATE:
            return @"Re-Rate Shipment";
        case PVO_CONFIRM_PAYMENT:
            return @"Confirm Payment";
        case PVO_FINAL_DEL_DATE:
            return @"Final Delivery Date";
        case PVO_DELIVER_SHIPMENT:
            return @"Deliver Shipment";
        case PVO_DEST_PROPERTY_DAMAGE:
            return @"Property Damage";
        case PVO_P_EX_DEL:
            return @"Print Extra Delivery";
        case PVO_P_DEL_EXCP:
            return @"Print Del and Exc Reports";
        case PVO_P_BOL:
            return @"Print Bill of Lading";
        case PVO_SEND_DOCS:
            return @"Send Documents to Corporate";
        case PVO_PROCESS_COMPLETE:
            return @"Process Complete";
    }
    
    return @"";
}*/

-(BOOL)completed
{
    BOOL retval = FALSE;
    PVOSignature *sig;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    PVOInventory *data = [del.surveyDB getPVOData:cust.custID];
    DriverData *driverData = [del.surveyDB getDriverData];
    int loadType = data.loadType;

    switch (navItemID)
    {
        /*case PVO_ENTER_TARE_WEIGHT:
            item.completed = tareWeight > 0;
            break;*/
        case PVO_INVENTORY:
        case PVO_P_INV_CARTON_DETAIL:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
            if(navItemID == PVO_INVENTORY)
                retval = data.inventoryCompleted;
            else
                retval = sig != nil;
            break;
        case PVO_P_RIDER_EXCEPTIONS:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_RIDER_EXCEPTIONS];
            retval = sig != nil;
            break;
        /*case PVO_GENERAL_COMMENTS:
            item.completed = [pvoNote length] > 0;
            break;
        case PVO_PAYMENT_METHOD:
            item.completed = confirmPaymentController != nil && confirmPaymentController.paymentMethod != 0;
            break;
        case PVO_ORG_PROPERTY_DAMAGE:
            item.completed = propertyDamageController != nil;
         break;*/
        case PVO_DELIVER_SHIPMENT:
        case PVO_P_DEL_EXCP:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
            if(navItemID == PVO_DELIVER_SHIPMENT)
#ifdef ATLASNET
            retval = data.deliveryCompleted;
#else
            retval = data.deliveryCompleted || sig != nil;
#endif
            else
                retval = sig != nil;
            break;
        case PVO_P_ESIGN_AGREEMENT:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT];
            retval = sig != nil;
            break;
        case PVO_P_ROOM_CONDITIONS:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ROOM_CONDITIONS];
            retval = sig != nil;
            break;
            
        case PVO_P_HARDWARE_INVENTORY:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_HARDWARE_INVENTORY];
            retval = sig != nil;
            break;
            
        case PVO_P_PRIORITY_INVENTORY:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_PRIORITY_INVENTORY];
            retval = sig != nil;
            break;
            
        case PVO_P_ORG_HIGH_VALUE:
        case PVO_P_DEL_HIGH_VALUE:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:navItemID == PVO_P_ORG_HIGH_VALUE ? PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE : PVO_SIGNATURE_TYPE_DEST_HIGH_VALUE];
            retval = sig != nil;
            break;
        case PVO_P_ASPOD_ORIGIN:
        case PVO_P_ASPOD_DESTINATION:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:navItemID == PVO_P_ASPOD_ORIGIN ? PVO_SIGNATURE_TYPE_ORIGIN_ASPOD : PVO_SIGNATURE_TYPE_DESTINATION_ASPOD];
            retval = sig != nil;
            break;
        case PVO_P_PACKING_SERVICES:
            sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_PACKING_SERVICES];
            retval = sig != nil;
            break;
        case PVO_AUTO_INVENTORY_REPORT_ORIG:
            retval = [PVOVehicle verifyAllVehiclesAreSigned:del.customerID withIsOrigin:YES];
            break;
        case PVO_AUTO_INVENTORY_REPORT_DEST:
            retval = [PVOVehicle verifyAllVehiclesAreSigned:del.customerID withIsOrigin:NO];
            break;
        default:
            
            //dynamic reports, or data entry items
            if(self.reportTypeID > 0 || [del.pricingDB pvoNavItemHasReportSections:navItemID])
            {//see if the sig exists for all signatures
                retval = YES;
                
                // see if there is a required signatures field
                NSString *idList = [del.pricingDB getRequiredSignaturesForNavItemID:navItemID pricingMode:cust.pricingMode loadType:loadType itemCategory:_itemCategory haulingAgentCode:driverData.haulingAgent];
                if ([idList length] == 0)
                {
                    idList = self.signatureIDs;
                }
                
                NSArray *idArray = [idList componentsSeparatedByString:@","];
                if ([idArray count] == 0)
                {
                    retval = NO;
                }
                else
                {
                    for (NSString *sigid in idArray) {
                        sig = [del.surveyDB getPVOSignature:del.customerID forImageType:[sigid intValue]];
                        if(sig == nil)
                        {
                            retval = NO;
                            break;
                        }
                        else
                            ;
                    }
                }
            }
            else
                retval = NO;
            
            break;
    }
    
    return retval;
}


-(BOOL)reportOptionSourcedExternally
{
    if(self.reportTypeID == VIEW_BOL)
        return TRUE;
    else
        return FALSE;
}



-(BOOL)hasSignatureType:(int)sigTypeID
{
    for (NSString *sigID in [self.signatureIDs componentsSeparatedByString:@","]) {
        if([sigID intValue] == sigTypeID)
            return YES;
    }
    return NO;
}

//Only going to be used by these two for the foreseeable future. If more reports use this I'll add a flag in the pricing.db
+(BOOL)signatureRequiresTypedFullName:(int)signatureID
{
    switch (signatureID) {
        case PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG:
        case PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}


@end
