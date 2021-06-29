//
//  SyncGlobals.m
//  Survey
//
//  Created by Tony Brame on 10/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SyncGlobals.h"
#import "SurveyAppDelegate.h"
#import "RoomSummary.h"
#import "SurveyDownloadXMLParser.h"
#import "CustomerUtilities.h"
#import "Base64.h"
#import "AppFunctionality.h"
#import "SignatureViewController.h"
#import "PVODynamicReportData.h"
#import "SurveyImage.h"
#import "PVONavigationListItem.h"
#import "PVOSTGBOL.h"

@implementation SyncGlobals


+(void)insertContactPhone:(SurveyPhone*) phone custId:(int)custId appDelegate:(SurveyAppDelegate *)del {
    if (phone != nil && phone.number != nil && [phone.number length] > 0) {
        phone.custID = custId;
        [del.surveyDB insertPhone:phone];
    }
}

+(BOOL)flushCustomerToDB:(SurveyDownloadXMLParser*)parser appDelegate:(SurveyAppDelegate *)del
{
    //if auto inventory is unlocked on the device let's default the inventory type to both...
    if ([del.surveyDB isAutoInventoryUnlocked]) {
        parser.customer.inventoryType = AUTO;
    }
    
    int custId = [del.surveyDB insertNewCustomer:parser.customer withSync:parser.sync andShipInfo:parser.info];
    [parser updateCustomerID:custId];
    
    del.customerID = custId;
    
    if([parser.note length] > 0)
        [del.surveyDB updateCustomerNote:custId withNote:parser.note];
    
    if (parser.reportNotes != nil && [parser.reportNotes count] > 0)
    {
        [del.surveyDB saveReceivableReportNotes:parser.reportNotes forCustomer:del.customerID];
    }
    
    if (parser.vehicles != nil && [parser.vehicles count] > 0)
    {
        for (int i = 0; i < [parser.vehicles count]; i++)
        {
            PVOVehicle *vehicle = parser.vehicles[i];
            vehicle.customerID = custId;
            [del.surveyDB saveVehicle:vehicle];
        }
    }
    
    [self insertContactPhone:parser.workPhone custId:custId appDelegate:del];
    [self insertContactPhone:parser.mobilePhone custId:custId appDelegate:del];
    [self insertContactPhone:parser.homePhone custId:custId appDelegate:del];
    
    for(int i = 0; i < [parser.locations count]; i++)
    {
        SurveyLocation *location = [parser.locations objectAtIndex:i];
        if(location.locationType == -1) {//this is an ex stop
            //locid and seq generated automatically...
            [del.surveyDB insertLocation:location];
        } else {
            [del.surveyDB updateLocation:location];
        }
        
        for(SurveyPhone *phone in location.phones)
        {
            phone.custID = custId;
            phone.locationTypeId = location.locationType;
            [del.surveyDB insertPhone:phone];
        }
    }
    
    for(int i = 0; i < [parser.agents count]; i++)
    {
        BOOL saved = FALSE;
        SurveyAgent *agt = [parser.agents objectAtIndex:i];
        if (agt != nil && agt.code != nil && [agt.code length] > 0)
        {//per Defect 355, pull details if available
            SurveyAgent *agent = [del.pricingDB getAgent:agt.code];
            if (agent.itemID > 0) {
                if (agt.name != nil && [agt.name length] > 0)
                    agent.name = agt.name; //receive this from download
                agent.itemID = agt.itemID; //customerID
                agent.agencyID = agt.agencyID;
                [del.surveyDB saveAgent:agent];
                saved = TRUE;
            }
        }
        if (!saved)
            [del.surveyDB saveAgent:agt];
    }
    
    [del.surveyDB updateDates:parser.dates];
    
    for (int i = 0; i < [parser.dynamicDataParser.dynamicData count]; i++)
    {
        PVODynamicReportData *data = [parser.dynamicDataParser.dynamicData objectAtIndex:i];
        data.custID = del.customerID;
        [del.surveyDB savePVODynamicReportDataEntry:data];
    }
    
    //cubesheet
    if(parser.csParser.entries != nil && [parser.csParser.entries count] > 0)
    {
        CubeSheet *cs = [del.surveyDB openCubeSheet:custId];
        
        for (SurveyedItem *si in parser.csParser.entries) {
            si.csID = cs.csID;
            
            si.siID = [del.surveyDB insertNewSurveyedItem:si];
            
            if(si.dims != nil && (si.dims.length > 0 || si.dims.width > 0 || si.dims.height > 0))
                [del.surveyDB setCrateDimensions:si.siID withDimensions:si.dims];
        }
        
    }
    
    //ls/sub ls
    if(parser.info.isOA)
    {
        parser.info.status = OA;
    }
    
    [del.surveyDB updateShipInfo:parser.info];
        
    
    return TRUE;
}

+(BOOL)mergeCustomerToDB:(SurveyDownloadXMLParser*)parser appDelegate:(SurveyAppDelegate *)del
{
    SurveyCustomer *existingCust = [del.surveyDB getCustomerByOrderNumber:parser.info.orderNumber];
    
    //this should never hapen, but just in case.
    if(existingCust == nil)
        return FALSE;
    
    int custId = existingCust.custID;
    parser.customer.custID = custId;

    [parser updateCustomerID:custId];
    del.customerID = custId;
    
    [del.surveyDB updateCustomer:parser.customer];
    [del.surveyDB updateShipInfo:parser.info];
    [del.surveyDB updateCustomerSync:parser.sync];
    
    
    if([parser.note length] > 0)
        [del.surveyDB updateCustomerNote:custId withNote:parser.note];
    
    if (parser.reportNotes != nil && [parser.reportNotes count] > 0)
    {
        [del.surveyDB saveReceivableReportNotes:parser.reportNotes forCustomer:del.customerID];
    }
        
    //remove any ex stips...
    for (int i = 0; i < 2; i++) {
        
        NSArray *stops = [del.surveyDB getCustomerLocations:del.customerID atOrigin:i == 0];
        for (SurveyLocation *l in stops) {
            if(l.sequence > 0)
            {
                [del.surveyDB deleteLocation:l];
                [del.surveyDB deletePhones:custId withLocationID:l.locationType];
            }
        }
    }

    [self insertContactPhone:parser.workPhone custId:custId appDelegate:del];
    [self insertContactPhone:parser.mobilePhone custId:custId appDelegate:del];
    [self insertContactPhone:parser.homePhone custId:custId appDelegate:del];
    
    for(int i = 0; i < [parser.locations count]; i++)
    {
        SurveyLocation *location = [parser.locations objectAtIndex:i];
        if(location.locationType == -1) {//this is an ex stop
            //locid and seq generated automatically...
            [del.surveyDB insertLocation:location];
        } else {
            [del.surveyDB updateLocation:location];
            [del.surveyDB deletePhones:custId withLocationID:location.locationType];
        }
        
        for(SurveyPhone *phone in location.phones)
        {
            phone.custID = custId;
            phone.locationTypeId = location.locationType;
            [del.surveyDB insertPhone:phone];
        }
    }
    
    for(int i = 0; i < [parser.agents count]; i++)
    {
        BOOL saved = FALSE;
        SurveyAgent *agt = [parser.agents objectAtIndex:i];
        if (agt != nil && agt.code != nil && [agt.code length] > 0)
        {//per Defect 355, pull details if available
            SurveyAgent *agent = [del.pricingDB getAgent:agt.code];
            if (agent.itemID > 0) {
                if (agt.name != nil && [agt.name length] > 0)
                    agent.name = agt.name; //receive this from download
                agent.itemID = agt.itemID; //customerID
                agent.agencyID = agt.agencyID;
                [del.surveyDB saveAgent:agent];
                saved = TRUE;
            }
        }
        if (!saved)
            [del.surveyDB saveAgent:agt];
    }
    
    [del.surveyDB updateDates:parser.dates];
    
    //delete the cubesheet...
    [del.surveyDB deleteCubeSheet:del.customerID];
    
    //cubesheet
    if(parser.csParser.entries != nil && [parser.csParser.entries count] > 0)
    {
        CubeSheet *cs = [del.surveyDB openCubeSheet:custId];
        
        for (SurveyedItem *si in parser.csParser.entries) {
            si.csID = cs.csID;
            
            si.siID = [del.surveyDB insertNewSurveyedItem:si];
            
            if(si.dims != nil && (si.dims.length > 0 || si.dims.width > 0 || si.dims.height > 0))
                [del.surveyDB setCrateDimensions:si.siID withDimensions:si.dims];
        }
        
    }
    
    //ls/sub ls
    if(parser.info.isOA)
    {
        parser.info.status = OA;
    }
    [del.surveyDB updateShipInfo:parser.info];
    
    
    return TRUE;
}

+(XMLWriter*)buildCustomerXML:(int)custID isAtlas:(BOOL)atlas
{
    return [self buildCustomerXML:custID withNavItemID:-1 isAtlas:atlas];
}

+(XMLWriter*)buildCustomerXML:(int)custID withNavItemID:(int)navItemID isAtlas:(BOOL)atlas
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    XMLWriter *retval = [[XMLWriter alloc] init];
    
    int oldCustID = del.customerID;
    del.customerID = custID;
    
    [retval writeStartDocument];
    
    if(atlas)
        [retval writeStartElement:@"AtlasSync"];
    else
        [retval writeStartElement:@"MMSync"];
    

    [retval writeStartElement:@"survey_upload"];
    
    if (navItemID > 0)
        [retval writeElementString:@"nav_item_id" withIntData:navItemID];
    
    [retval writeElementString:@"customer_type" withData:@"Inventory"];
    
    
    [retval writeElementString:@"survey_version" withData:[NSString stringWithFormat:@"iOS %@", 
                                                           [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    
    //add customer, dates, and sync
    SurveyCustomer *cust = [del.surveyDB getCustomer:custID];
    ShipmentInfo *info = [del.surveyDB getShipInfo:del.customerID];
    
    if (cust.pricingMode == INTERSTATE)
        [retval writeElementString:@"pricing_mode" withData:@"Interstate"];
    else if ([cust isCanadianGovernmentCustomer])
        [retval writeElementString:@"pricing_mode" withData:@"CNGOV"];
    else if ([cust isCanadianNonGovernmentCustomer])
        [retval writeElementString:@"pricing_mode" withData:@"CNCIV"];
    else
        [retval writeElementString:@"pricing_mode" withData:@"Local"];
    
    [retval writeElementString:@"van_line_id" withIntData:[del.pricingDB vanline]];
    
    CubeSheet *cs = [del.surveyDB openCubeSheet:custID];
    [cust flushToXML:retval];
    
    SurveyDates *dates = [del.surveyDB getDates:custID];
    [dates flushToXML:retval];
    
    //write weight factor...
    [retval writeElementString:@"weight_factor" withData:[[NSNumber numberWithDouble:cs.weightFactor] stringValue]];
    
    SurveyCustomerSync *sync = [del.surveyDB getCustomerSync:custID];
    [sync flushToXML:retval sendToQM:TRUE];
    
    //write the info...
    [info flushToXML:retval];
    
    //write the notes
    NSString *notes = [del.surveyDB getCustomerNote:custID];
    if([notes length] > 0)
        [retval writeElementString:@"notes" withData:notes];
    
    //write report notes
    [retval writeStartElement:@"report_notes"];
    NSArray *reportNotes = [del.surveyDB getAllReportNotes:custID];
    for (PVOReportNote *rptNote in reportNotes) {
        if (rptNote != nil)
        {
            [retval writeStartElement:@"report_note"];
            [retval writeAttribute:@"type" withIntData:rptNote.pvoReportNoteTypeID];
            [retval writeAttribute:@"note" withData:rptNote.reportNote];
            [retval writeEndElement];
        }
    }
    [retval writeEndElement];
    
    //prima1e number
    SurveyPhone *primaryPhone = [del.surveyDB getPrimaryPhone:custID];
    if (primaryPhone != nil)
    {
        [retval writeElementString:@"primary_phone" withData:primaryPhone.number];
    }
    
    //add the locations
    BOOL origExStops, destExStops;
    NSArray *locs = [del.surveyDB getCustomerLocations:custID atOrigin:YES];
    NSArray *phones = [del.surveyDB getCustomerPhones:custID withLocationID:ORIGIN_LOCATION_ID];
    SurveyLocation *loc = [locs objectAtIndex:0];
    origExStops = [locs count] > 1;
    [loc flushToXML:retval withPhones:phones];
    
    locs = [del.surveyDB getCustomerLocations:custID atOrigin:NO];
    phones = [del.surveyDB getCustomerPhones:custID withLocationID:DESTINATION_LOCATION_ID];
    loc = [locs objectAtIndex:0];
    destExStops = [locs count] > 1;
    [loc flushToXML:retval withPhones:phones];
    
    if(origExStops || destExStops)
    {
        [retval writeStartElement:@"extra_locations"];
        
        locs = [del.surveyDB getCustomerLocations:custID atOrigin:YES];
        for(int i = 1; i < [locs count]; i++)
        {
            loc = [locs objectAtIndex:i];
            [loc flushToXML:retval withPhones:nil];
        }
        locs = [del.surveyDB getCustomerLocations:custID atOrigin:NO];
        for(int i = 1; i < [locs count]; i++)
        {
            loc = [locs objectAtIndex:i];
            [loc flushToXML:retval withPhones:nil];
        }
        
        [retval writeEndElement];
    }
    
    //add the agents
    SurveyAgent *agent = [del.surveyDB getAgent:custID withAgentID:AGENT_BOOKING];
    [agent flushToXML:retval];
    
    agent = [del.surveyDB getAgent:custID withAgentID:AGENT_ORIGIN];
    [agent flushToXML:retval];
    
    agent = [del.surveyDB getAgent:custID withAgentID:AGENT_DESTINATION];
    [agent flushToXML:retval];
    
    //add the cubesheet...
    [retval writeElementString:@"total_weight" 
                      withData:[NSString stringWithFormat:@"%f",
                                [CustomerUtilities getTotalCustomerWeight]]];
    
    NSArray *rooms = [del.surveyDB getRoomSummaries:cs customerID:custID];
    RoomSummary *summary;
    SurveyedItemsList *siList;
    [retval writeStartElement:@"cube_sheet"];
    [retval writeStartElement:@"rooms"];
    for(int i = 0; i < [rooms count]; i++)
    {
        summary = [rooms objectAtIndex:i];
        siList = [del.surveyDB getRoomSurveyedItems:summary.room withCubesheetID:cs.csID];
        [retval writeStartElement:@"room"];
        
        [retval writeAttribute:@"name" withData:summary.room.roomName];
        
        int imageSyncID = [del.surveyDB getImageSyncID:del.customerID withPhotoType:IMG_ROOMS withSubID:summary.room.roomID];
        if(imageSyncID > 0)
            [retval writeAttribute:@"image_id" withData:[NSString stringWithFormat:@"%d",imageSyncID]];
            
        //could not use an attribute due to incompatilbility
        NSString *alias = [del.surveyDB getRoomAlias:custID withRoomID:summary.room.roomID];
        if(alias != nil)
            [retval writeElementString:@"alias" withData:alias];
        
        [siList flushToXML:retval  materialHandling:FLUSH_NO_MATERIALS];
        
        [retval writeEndElement];
    }
    [retval writeEndElement];
    [retval writeEndElement];
    
    
    
    //Add PVO Items
    //get the tariff specific information
    if(del.viewType == OPTIONS_PVO_VIEW)
    {
        [SyncGlobals getPVOInfo:retval navItemID:navItemID];
    }
    
    for(int i = 0; i < 2; i++)
    {
        NSString *documentsDirectory = [SurveyAppDelegate getDocsDirectory];
        NSString *filePath = @"";
        if(i == 0)
            filePath = [documentsDirectory stringByAppendingPathComponent:CUST_SIG_FILE];
        else
            filePath = [documentsDirectory stringByAppendingPathComponent:AGENT_SIG_FILE];
        
        UIImage *compressedImage = [SyncGlobals removeUnusedImageSpace:[UIImage imageWithContentsOfFile:filePath]];
        
        NSData *sigData = UIImagePNGRepresentation(compressedImage);
        if(sigData != nil && sigData.length > 0)
        {
            if(i == 0)
                [retval writeElementString:@"customer_sig" withData:[Base64 encode64WithData:sigData]];
            else
                [retval writeElementString:@"agent_sig" withData:[Base64 encode64WithData:sigData]];
        }
    }
    
#if defined(ATLASNET)
    NSString *stgBolPath = [PVOSTGBOL fullPathForCustomer:custID];
    NSString *content = [NSString stringWithContentsOfFile:stgBolPath encoding:NSUTF8StringEncoding error:nil];
    if ([content length] > 0)
    {
        [retval writeExistingNode:content];
        //[retval content];
    }
#endif
    
    [retval writeEndDocument];
    
    
    del.customerID = oldCustID;
    
    
    
#if defined(SHOW_CUSTOMER_XML)
    NSLog(@"Customer XML: %@", [NSString stringWithFormat:@"%@", retval.file]);
#endif
    
    return retval;
}

+(void)getPVOInfo:(XMLWriter*)retval navItemID:(int)navItemID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DriverData *driver = [del.surveyDB getDriverData];
    [driver flushToXML:retval];
    
    NSArray *dynamicReportValues = [del.surveyDB getPVODynamicReportData:del.customerID];
    [retval writeStartElement:@"dynamic_report_entries"];
    for (PVODynamicReportData *entry in dynamicReportValues) {
        [entry flushToXML:retval];
    }
    [retval writeEndElement];
    
    //write current claim
    while(true)
    {
        if(del.currentPVOClaimID != 0)
        {
            PVOClaim *claim = nil;
            NSArray *tempArr = [del.surveyDB getPVOClaims:del.customerID];
            for (PVOClaim *c in tempArr) {
                if(c.pvoClaimID == del.currentPVOClaimID)
                    claim = c;
            }
            
            if(claim == nil)
                break;
            
            [retval writeStartElement:@"pvo_claim"];
            
            NSDateFormatter *dFormatter = [[NSDateFormatter alloc] init];
            [dFormatter setDateStyle:NSDateFormatterShortStyle];
            [retval writeAttribute:@"claim_date" withData:[dFormatter stringFromDate:claim.claimDate]];
            
            [retval writeElementString:@"employer_paid" withData:claim.employerPaid ? @"true" : @"false"];
            if(claim.employerPaid)
                [retval writeElementString:@"employer" withData:claim.employer];
            
            [retval writeElementString:@"shipment_in_warehouse" withData:claim.shipmentInWarehouse ? @"true" : @"false"];
            if(claim.shipmentInWarehouse)
                [retval writeElementString:@"agency_code" withData:claim.agencyCode];
            
            tempArr = [del.surveyDB getPVOClaimItems:claim.pvoClaimID];
            for (PVOClaimItem *item in tempArr) {
                [retval writeStartElement:@"pvo_claim_item"];
                
                PVOItemDetail *pid = [del.surveyDB getPVOItem:item.pvoItemID];
                Item *i = [del.surveyDB getItem:pid.itemID];
                
                [retval writeElementString:@"item_number" withData:pid.itemNumber];
                [retval writeElementString:@"item_name" withData:i.name];
                [retval writeElementString:@"damage_description" withData:item.description];
                [retval writeElementString:@"estimated_weight" withIntData:item.estimatedWeight];
                [retval writeElementString:@"age_or_date_purchased" withData:item.ageOrDatePurchased];
                [retval writeElementString:@"original_cost" withData:[SurveyAppDelegate formatDouble:item.originalCost]];
                [retval writeElementString:@"replacement_cost" withData:[SurveyAppDelegate formatDouble:item.replacementCost]];
                [retval writeElementString:@"repair_cost" withData:[SurveyAppDelegate formatDouble:item.estimatedRepairCost]];
                
                [retval writeEndElement];
            }
            
            [retval writeEndElement];
        }
        break;
    }
    
    
    PVOInventory *invData = [del.surveyDB getPVOData:del.customerID];
    
    [retval writeStartElement:@"pvo_driver_inventory"];
    
    [retval writeAttribute:@"load_complete" withData:invData.inventoryCompleted ? @"true" : @"false"];
    [retval writeAttribute:@"unload_complete" withData:invData.deliveryCompleted ? @"true" : @"false"];
    [retval writeAttribute:@"new_page_per_lot" withData:invData.newPagePerLot ? @"true" : @"false"];
    
    [retval writeElementString:@"valuation_type" withData:del.hviValType == 1 ? @"FVP" : @"0.60/lb"];
    
    NSDictionary *loadTypes = [del.surveyDB getPVOLoadTypes];
    [retval writeElementString:@"load_type" withData:[[loadTypes objectForKey:[NSNumber numberWithInt:invData.loadType]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    if(invData.packingType == PVO_PACK_CUSTOM)
        [retval writeElementString:@"packing_type" withData:@"custom"];
    else if(invData.packingType == PVO_PACK_FULL)
        [retval writeElementString:@"packing_type" withData:@"full"];
    
    [retval writeElementString:@"packing_ot" withData:invData.packingOT ? @"true" : @"false"];
    
    if(invData.mproWeight > 0)
        [retval writeElementString:@"mpro_weight" withIntData:invData.mproWeight];
    if(invData.sproWeight > 0)
        [retval writeElementString:@"spro_weight" withIntData:invData.sproWeight];
    if(invData.consWeight > 0 )
        [retval writeElementString:@"cons_weight" withIntData:invData.consWeight];
            
    NSArray *pvoLocations = [del.surveyDB getPVOLocationsForCust:del.customerID];
    NSArray *pvoRooms, *pvoItems;
    
    NSDictionary *pvoLocationTypes = [del.surveyDB getPVOLocations:YES isLoading:YES];
    
    NSData *sigData;
    
    //hmmm....
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDictionary *floorTypes = [del.pricingDB vanline] == ATLAS ? [del.surveyDB getPVOPropertyTypes] : [del.surveyDB getPVORoomFloorTypes];
    
    for (PVOInventoryLoad *currentLoad in pvoLocations) 
    {
        pvoRooms = [del.surveyDB getPVORooms:currentLoad.pvoLoadID withDeletedItems:YES andConditionOnly:[AppFunctionality includeEmptyRoomsInXML] withCustomerID:del.customerID];
        
        [retval writeStartElement:@"location"];
        
        //location type
        [retval writeElementString:@"pvo_location_type" withData:[pvoLocationTypes objectForKey:[NSNumber numberWithInt:currentLoad.pvoLocationID]]];
        
        //receive from type
        if (currentLoad.receivedFromPVOLocationID > 0)
            [retval writeElementString:@"pvo_received_from_type" withData:[pvoLocationTypes objectForKey:[NSNumber numberWithInt:currentLoad.receivedFromPVOLocationID]]];
        
        [retval writeElementString:@"tractor_number" withData:invData.tractorNumber];
        [retval writeElementString:@"trailer_number" withData:invData.trailerNumber];
        
        int unloadType = [del.surveyDB getPVODeliveryType:currentLoad.pvoLoadID];
        if(unloadType != 0) {
            [retval writeElementString:@"pvo_unload_type" withData:[pvoLocationTypes objectForKey:[NSNumber numberWithInt:unloadType]]];
            
            SurveyLocation* location = [del.surveyDB getCustomerLocation:currentLoad.locationID];
            
            if (location != nil)
                [retval writeElementString:@"pvo_unload_sequence" withData:[NSString stringWithFormat:@"%d",location.sequence]];
        }
        
        [retval writeStartElement:@"rooms"];
        for (PVORoomSummary *sum in pvoRooms) 
        {
            if (sum.room == nil || sum.numberOfItems <= 0)
                continue;
            
            [retval writeStartElement:@"inventory_room"];
            [retval writeAttribute:@"name" withData:sum.room.roomName];
            
            PVORoomConditions *rc = [del.surveyDB getPVORoomConditions:currentLoad.pvoLoadID andRoomID:sum.room.roomID];
            if (rc != nil)
            {
                if(rc.hasDamage)
                {
                    [retval writeAttribute:@"has_damage" withData:@"true"];
                    [retval writeAttribute:@"damage_description" withData:rc.damageDetail];
                }
                NSString *ft = [floorTypes objectForKey:[NSNumber numberWithInt:rc.floorTypeID]];
                if(ft != nil)
                    [retval writeAttribute:@"floor_type" withData:ft];
            }
            
            if ([AppFunctionality addImageLocationsToXML])
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                NSArray *locationImages = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_ROOMS withSubID:rc.roomConditionsID loadAllItems:NO];
                
                [retval writeStartElement:@"images"];
                
                for (SurveyImage *surveyImage in locationImages)
                {
                    NSFileManager *mgr = [NSFileManager defaultManager];
                    
                    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
                    if([mgr fileExistsAtPath:[docsDir stringByAppendingString:surveyImage.path]])
                    {
                        [retval writeStartElement:@"image"];
                        [retval writeAttribute:@"location" withData:[NSString stringWithFormat:@"%@", [SurveyAppDelegate getLastTwoPathComponents:surveyImage.path]]];
                        [retval writeAttribute:@"photoType" withIntData:surveyImage.photoType];
                        [retval writeAttribute:@"description" withData:[NSString stringWithFormat:@"%@", sum.room.roomName]];
                        [retval writeEndElement]; //end image
                    }
                    
                }
                [retval writeEndElement]; //end images
            
            }
            
            [retval writeStartElement:@"items"];
            
            pvoItems = [del.surveyDB getPVOItems:currentLoad.pvoLoadID
                                         forRoom:sum.room.roomID];
            if (pvoItems != nil)
                for (PVOItemDetail *pvoItem in pvoItems)
                    [pvoItem flushToXML:retval];
            //end items
            [retval writeEndElement];
            //end inventory_room
            [retval writeEndElement];
        }
        
        //end rooms
        [retval writeEndElement];
        //end location
        [retval writeEndElement];
    }
    
    //add destination room conditions
    [self writeDestRoomConditions:retval];
    
    
    
    //end pvo_driver_inventory
    [retval writeEndElement];
    
    //get all the bulky inventory items
    NSArray *bulkyItems = [del.surveyDB getPVOBulkyInventoryItems:del.customerID];
    if ([bulkyItems count] > 0)
    {
        //start bulky inventory
        [retval writeStartElement:@"pvo_bulky_inventory"];
        
        for (PVOBulkyInventoryItem *bulky in bulkyItems)
        {
            //flush the bulky item to xml, this includes the damages
            [bulky flushToXML:retval];
        }
        
        //end vehicle inventory
        [retval writeEndElement];
    }
    
    //get all the vehicles
    NSArray *vehicles = [del.surveyDB getAllVehicles:del.customerID];
    
    if ([vehicles count] > 0)
    {
        //start Vehicle inventory
        [retval writeStartElement:@"pvo_vehicles"];
        
        for (PVOVehicle *v in vehicles)
        {
            //flush the vehicle to xml, this includes the damages
            [v flushToXML:retval];
        }
        
        //end vehicle inventory
        [retval writeEndElement];
    }
    
    [retval writeStartElement:@"pvo_signatures"];
    
#if defined(ATLASNET)
    NSDate *originBOLDate = nil;
    NSDate *destinationBOLDate = nil;
#endif
    
    NSArray *signatures = [del.surveyDB getPVOSignatures:del.customerID];
    
    for (PVOSignature *mysig in signatures) {
        UIImage *compressedImage = [SyncGlobals removeUnusedImageSpace:[mysig signatureData]];
        sigData = UIImagePNGRepresentation(compressedImage);
        if(sigData != nil && sigData.length > 0)
        {
            [retval writeStartElement:@"signature"];

            switch (mysig.pvoSigTypeID) {
                case PVO_SIGNATURE_TYPE_ORG_INVENTORY:
                    [retval writeAttribute:@"type" withData:@"OriginInventory"];
                    break;
                case PVO_SIGNATURE_TYPE_DEST_INVENTORY:
                    [retval writeAttribute:@"type" withData:@"DestinationInventory"];
                    break;
                case PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT:
                    [retval writeAttribute:@"type" withData:@"ESign"];
                    break;
                case PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE:
                    [retval writeAttribute:@"type" withData:@"OriginHighValue"];
                    break;
                case PVO_SIGNATURE_TYPE_DEST_HIGH_VALUE:
                    [retval writeAttribute:@"type" withData:@"DestinationHighValue"];
                    break;
                case PVO_SIGNATURE_TYPE_CLAIM:
                    [retval writeAttribute:@"type" withData:@"Claim"];
                    break;
                case PVO_SIGNATURE_TYPE_ROOM_CONDITIONS:
                    [retval writeAttribute:@"type" withData:@"RoomConditions"];
                    break;
                case PVO_SIGNATURE_TYPE_DEST_ROOM_CONDITIONS:
                    [retval writeAttribute:@"type" withData:@"DestRoomConditions"];
                    break;
                case PVO_SIGNATURE_TYPE_HARDWARE_INVENTORY:
                    [retval writeAttribute:@"type" withData:@"HardwareInventory"];
                    break;
                case PVO_SIGNATURE_TYPE_PRIORITY_INVENTORY:
                    [retval writeAttribute:@"type" withData:@"PriorityInventory"];
                    break;
                case PVO_SIGNATURE_TYPE_PACKING_SERVICES:
                    [retval writeAttribute:@"type" withData:@"PackingServices"];
                    break;
                case PVO_SIGNATURE_TYPE_ORIGIN_ASPOD:
                    [retval writeAttribute:@"type" withData:@"OriginASPOD"];
                    break;
                case PVO_SIGNATURE_TYPE_DESTINATION_ASPOD:
                    [retval writeAttribute:@"type" withData:@"DestinationASPOD"];
                    break;
                case PVO_SIGNATURE_TYPE_DELIVER_ALL:
#ifdef ATLASNET
                    [retval writeAttribute:@"type" withData:@"DeliverAll"];
#else
                    [retval writeAttribute:@"type" withData:@"DeclineCheckoff"];
#endif
                    break;
                case PVO_SIGNATURE_TYPE_RIDER_EXCEPTIONS:
                    [retval writeAttribute:@"type" withData:@"RiderExceptions"];
                    break;
                default:
                    [retval writeAttribute:@"typeID" withData:[NSString stringWithFormat:@"%d", mysig.pvoSigTypeID]];
                    
#if defined(ATLASNET)
                    if (mysig.pvoSigTypeID == PVO_SIGNATURE_TYPE_BOL_ORIGIN)
                    {
                        originBOLDate = mysig.sigDate;
                    }
                    else if (mysig.pvoSigTypeID == PVO_SIGNATURE_TYPE_BOL_DESTINATION)
                    {
                        destinationBOLDate = mysig.sigDate;
                    }
#endif
                    
                    break;
            }
            [retval writeAttribute:@"referenceID" withIntData:mysig.referenceID]; //only used for vehicles right now, all vehicles will have the same sig type, so the vehicle id is used to match sigs to vehicles

            [retval writeElementString:@"image" withData:[Base64 encode64WithData:sigData]];
            
            [retval writeElementString:@"dateTime" withData:[dateFormatter stringFromDate:mysig.sigDate]];
            
            NSString *printedName = [del.surveyDB getPVOSignaturePrintedName:mysig.pvoSigID];
            if (printedName != nil && ![[printedName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
            {
                [retval writeElementString:@"printed_name" withData:printedName];
            }
            
            [retval writeEndElement];
        }
        //[sigData release];
    }
    
    
    PVOSignature *sig = [del.surveyDB getPVOSignature:-1
                                         forImageType:(driver.driverType == PVO_DRIVER_TYPE_PACKER ? PVO_SIGNATURE_TYPE_PACKER : PVO_SIGNATURE_TYPE_DRIVER)];
    if(sig != nil)
    {
        //if (driver.driverType != PVO_DRIVER_TYPE_PACKER) // don't sync driver sig for packer | removed per defect 620
        {
            UIImage *driverSig = [sig signatureData];
            sigData = UIImagePNGRepresentation([SyncGlobals removeUnusedImageSpace:driverSig]);
            if(sigData != nil && sigData.length > 0)
            {
                [retval writeStartElement:@"signature"];
                [retval writeAttribute:@"type" withData:@"Driver"];
                [retval writeElementString:@"image" withData:[Base64 encode64WithData:sigData]];
                
#if defined(ATLASNET)
                
                NSDate *signatureDate = [NSDate date];
                
                if (navItemID == PVO_BOL_ORIGIN)
                {
                    if (originBOLDate != nil)
                    {
                        signatureDate = originBOLDate;
                    }
                }
                else if (navItemID == PVO_BOL_DEST)
                {
                    if (originBOLDate != nil)
                    {
                        signatureDate = originBOLDate;
                    }
                    else if (destinationBOLDate != nil)
                    {
                        signatureDate = destinationBOLDate;
                    }
                }
                
                [retval writeElementString:@"dateTime" withData:[dateFormatter stringFromDate:signatureDate]];
                
#else
                
                [retval writeElementString:@"dateTime" withData:[dateFormatter stringFromDate:[NSDate date]]];
                
#endif
                
                [retval writeEndElement];
            }
            
            //[sigData release];
        }
    }
    
    
    //end pvo_signatures
    [retval writeEndElement];
    
}

+(void)writeDestRoomConditions:(XMLWriter*)retval
{
    
    /*SET IDENTITY_INSERT tblPVOReportTypes ON
    GO
    
    insert into tblPVOReportTypes (PVOReportTypeID, ReportDescription) values (30, 'Unload Room Conditions')
    GO
    
    SET IDENTITY_INSERT tblPVOReportTypes OFF
    GO
     
     INSERT Into [MoverDocsPVOBeta].[dbo].[tblPVOReports] (ReportIndex, PVOReportTypeID, ReportDll, VanlineID, CustomReportsPassword, ReportNamespace, HTMLSupported, HTMLFileRevision, HTMLBundleLocation, HTMLTargetFile)
     VALUES (0, 30, '', 2, NULL, '', 1, 39, 'https://print.moverdocs.com/ArpinPVOBeta/html/preexisting.zip', 'preexisting.html')
     
     */
    
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDictionary *floorTypes = [del.pricingDB vanline] == ATLAS ? [del.surveyDB getPVOPropertyTypes] : [del.surveyDB getPVORoomFloorTypes];
    
    //get all unloads for customer
    NSArray *unloads = [del.surveyDB getPVOUnloads:del.customerID];
    
    NSDictionary *pvoLocationTypes = [del.surveyDB getPVOLocations:YES isLoading:YES];
    
    if ([unloads count] > 0)
    {
        
        for (PVOInventoryUnload *unload in unloads)
        {
            //start unload
            [retval writeStartElement:@"unload"];
            
            int unloadType = [del.surveyDB getPVODeliveryType:unload.pvoLoadID];
            if(unloadType != 0) {
                [retval writeElementString:@"pvo_unload_type" withData:[pvoLocationTypes objectForKey:[NSNumber numberWithInt:unloadType]]];
            }
            
            SurveyLocation* location = [del.surveyDB getCustomerLocation:unload.locationID];
            
            if (location != nil)
                [retval writeElementString:@"pvo_unload_sequence" withData:[NSString stringWithFormat:@"%d",location.sequence]];

            //get all rooms with destination conditions
            NSArray *pvoRooms = [del.surveyDB getPVODestinationRooms:unload.pvoLoadID];
            [retval writeStartElement:@"rooms"];
            for (PVORoomSummary *sum in pvoRooms)
            {
                if (sum.room == nil || sum.numberOfItems <= 0)
                    continue;
                
                [retval writeStartElement:@"inventory_room"];
                [retval writeAttribute:@"name" withData:sum.room.roomName];
                
                PVORoomConditions *rc = [del.surveyDB getPVODestinationRoomConditions:unload.pvoLoadID andRoomID:sum.room.roomID];
                if (rc != nil)
                {
                    if(rc.hasDamage)
                    {
                        [retval writeAttribute:@"has_damage" withData:@"true"];
                        [retval writeAttribute:@"damage_description" withData:rc.damageDetail];
                    }
                    NSString *ft = [floorTypes objectForKey:[NSNumber numberWithInt:rc.floorTypeID]];
                    if(ft != nil)
                        [retval writeAttribute:@"floor_type" withData:ft];
                }
                
                if ([AppFunctionality addImageLocationsToXML])
                {
                    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                    NSArray *locationImages = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_DESTINATION_ROOMS withSubID:rc.roomConditionsID loadAllItems:NO];
                    
                    [retval writeStartElement:@"images"];
                    
                    for (SurveyImage *surveyImage in locationImages)
                    {
                        NSFileManager *mgr = [NSFileManager defaultManager];
                        
                        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
                        if([mgr fileExistsAtPath:[docsDir stringByAppendingString:surveyImage.path]])
                        {
                            [retval writeStartElement:@"image"];
                            [retval writeAttribute:@"location" withData:[NSString stringWithFormat:@"%@", [SurveyAppDelegate getLastTwoPathComponents:surveyImage.path]]];
                            [retval writeAttribute:@"photoType" withIntData:surveyImage.photoType];
                            [retval writeAttribute:@"description" withData:[NSString stringWithFormat:@"Dest. %@", sum.room.roomName]];
                            [retval writeEndElement]; //end image
                        }
                        
                    }
                    [retval writeEndElement]; //end images                    
                }
                //end inventory_room
                [retval writeEndElement];
                
            }
            //end rooms
            [retval writeEndElement];
            
            //end unload
            [retval writeEndElement];
            
        }
        
    }
    
}


//utility to get RGB at image location adapted from http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
+(UIImage*)removeUnusedImageSpace:(UIImage*)source
{
    if(source == nil)
        return nil;
    
    // First get the image into your data buffer
    CGImageRef imageRef = [source CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *rawData = malloc(height * width * 4);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    //try to not loop if we've already determined that this x or y won't be it...
    //what about the danged ole rest of them.  poop.
    
    int closestX = width/* source.size.width*/, farthestX = 0, closestY = height/*source.size.height*/, farthestY = 0;
    CGRect populatedArea = CGRectMake(-1, -1, -1, -1);
    unsigned char current;
    for(int y = 0; y < height/* source.size.height*/; y++)
    {
        for(int x = 0; x < width /*source.size.width*/; x++)
        {
            int byteIndex = (bytesPerRow * y) + (x * bytesPerPixel);
            //alpha > 0 indicates a value...
            //CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
            
            current = rawData[byteIndex + 3];
            if((current * 1.0) > 0)
            {
                if(closestX > x)
                    closestX = x;
                if(farthestX < x)
                    farthestX = x;
                if(closestY > y)
                    closestY = y;
                if(farthestY < y)
                    farthestY = y;
            }
        }
    }
    
    populatedArea = CGRectMake(closestX, closestY, farthestX - closestX, farthestY - closestY);
    
    free(rawData);
    
    return [UIImage imageWithCGImage:CGImageCreateWithImageInRect(source.CGImage, populatedArea)];
    
}


@end
