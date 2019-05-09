//
//  AtlasDrawer.m
//  Survey
//
//  Created by Tony Brame on 3/8/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "PVODrawer.h"
#import "SurveyAppDelegate.h"
#import "PrintCell.h"
#import "CellValue.h"
#import "CustomerUtilities.h"
#import "SyncGlobals.h"
#import "AppFunctionality.h"
#import "PVOPrintController.h"
#import "PVONavigationListItem.h"

@implementation PVODrawer


-(NSDictionary*)availableReports
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:@"ESign Agreement" forKey:[NSNumber numberWithInt:ESIGN_AGREEMENT]];
    [dict setObject:@"Inventory" forKey:[NSNumber numberWithInt:INVENTORY]];
    [dict setObject:@"Delivery Inventory" forKey:[NSNumber numberWithInt:DELIVERY_INVENTORY]];
    [dict setObject:@"Inventory Exceptions Report" forKey:[NSNumber numberWithInt:RIDER_EXCEPTIONS]];
    
    return dict;
}

-(BOOL)getPage:(PagePrintParam*)parms
{
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @autoreleasepool {
        params = parms;
    
        context = params.context;
    
        if (context != NULL)
        {
            CGContextSaveGState(context);
            
            [[UIColor blackColor] set];
            
            CGContextSetShouldAntialias(context, false);
            CGContextSetAllowsAntialiasing(context, false);
            
            UIGraphicsPushContext(context);
            
            // clear full page
            CGContextSetRGBFillColor(context, 1.,1.,1.,1.);
            CGContextFillRect(context, params.contentRect);
        }
    
        //this code used to adjust content for page/margins...
        if (docProgress == 0 && tempDocProgress == 0)
        {
            CGRect tempRect = CGRectInset(params.contentRect, TO_PRINTER(1.), TO_PRINTER(1.));
            tempRect.origin.x += TO_PRINTER(25.);
            tempRect.size.width -= TO_PRINTER(25.);
            params.contentRect = tempRect;
            
            if (width == 0)
                width = params.contentRect.size.width - TO_PRINTER(25.);
        }
    
    
        // needs initialized for header/footer method
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        custID = del.customerID;
        isOrigin = (reportID == INVENTORY);
    
        PVOSignature *checkoffsig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL];
        printDeclineCheckoffWaiver = !isOrigin && checkoffsig != nil;
    
        //setup damage print type
        printDamageCodeOnly = ([del.surveyDB getDriverData].reportPreference > 0);
    
        //setup new page per lot
        PVOInventory *invData = [del.surveyDB getPVOData:del.customerID];
        newPagePerLot = invData.newPagePerLot;
    
        // setup header method
        if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
            headerMethod = @selector(addHeader:);
        else if (reportID == RIDER_EXCEPTIONS)
            headerMethod = @selector(addRiderHeader:);
        else
            headerMethod = nil;
    
        // setup footer method
        if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
            footerMethod = @selector(invFooter:);
        else if (reportID == RIDER_EXCEPTIONS)
            footerMethod = @selector(riderFooter:);
        else
            footerMethod = nil;
    
    
        //prep the page
        [self preparePage];
    
        leftCurrentPageY = currentPageY;
    
        int tempCurrentPageY = currentPageY;
    
    
    
    
        CGAffineTransform transImage = CGAffineTransformMake(1, 0, 0, -1, 0, floor(params.contentRect.size.height));
        if (context != NULL)
            CGContextConcatCTM(context, transImage);
    
        [self printPageHeader];
    
        //finish previous sections... they may still not be done with this page...
        if(![self finishSectionsFromPreviousPage])
            return;
    
        NSArray *loads = nil, *unsortedItems = nil, *unloads = nil;
        NSMutableArray *items = nil;
    
        @try
        {
            if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
            {
                NSString *currentLotNum = @"";
                int progressCounter = -1, currentProgressCounter = 0, missingProgressCounter = 0;
                //NSDictionary *colors = [del.surveyDB getPVOColors];
                countDelivered = 0;
                hasItemsInventoriedAfterSig = FALSE;
                
                invData = [del.surveyDB getPVOData:custID];
                loads = [del.surveyDB getPVOLocationsForCust:custID];
                unloads = [del.surveyDB getPVOUnloads:custID];
                
                BOOL printedPackerInv = NO;
                for (int x=0;x<6;x++) // 0 = MPRO, 1 = SPRO, 2 = High Value Pack Inv., 3 = Pack Inv., 4 = High Value, 5 = everything else
                {
                    if (invData.loadType != MILITARY && x < 2)
                        continue; //skip it, not Military
                    
                    processingMproSproItems = (x <= 1);
                    processingHighValueItems = (x == 2) || (x == 4);
                    processingPackersInvItems = (x > 1 && x < 4);
                    
                    currentProgressCounter = 0;
                    missingProgressCounter = 0;
                    printingMissingItems = FALSE;
                    printingItemsInventoriedAfterSig = FALSE;
                    printingItemsInventoriedAfterSigLOT = FALSE;
                    
                    if (!processingMproSproItems && x % 2 == 0)
                    {
                        currentLotNum = @"";
                        if (currentPageItems != nil)
                        {
                            currentPageItems = nil;
                        }
                        currentPageItems = [[NSMutableArray alloc] init];
                    }
                    
                    for (int i = 0; i < [loads count]; i++)
                    {
                        PVOInventoryLoad *load = [loads objectAtIndex:i];
                        pvoLoadID = load.pvoLoadID;
                        
                        if (!processingMproSproItems &&
                            ((processingPackersInvItems && load.pvoLocationID != 7) || (!processingPackersInvItems && load.pvoLocationID == 7)))
                            continue; //skip it, not packer's inventory
                        
                        sprCheck = FALSE;
                        dvrCheck = FALSE;
                        whsCheck = FALSE;
                        
                        // determine WHS, DVR, SPR checkmarks
                        if (!isOrigin)
                        {
                            int unloadLocationID = 0;
                            for(PVOInventoryUnload *u in unloads)
                                for (NSNumber *loadID in u.loadIDs)
                                    if ([loadID isEqualToNumber:[NSNumber numberWithInt:pvoLoadID]])
                                        unloadLocationID = u.pvoLocationID;
                            
                            switch (unloadLocationID) {
                                case 1:
                                case 2:
                                case 3:
                                case 4:
                                    sprCheck = TRUE;
                                    break;
                                case 5:
                                    dvrCheck = TRUE;
                                    break;
                                case 6:
                                    whsCheck = TRUE;
                                    break;
                            }
                        }
                        items = [[NSMutableArray alloc] init];
                        if (processingMproSproItems)
                            unsortedItems = [del.surveyDB getPVOItemsMproSproForLoad:pvoLoadID isMpro:(x == 0)];
                        else
                            unsortedItems = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                        NSArray *cartonContents;
                        for (PVOItemDetail *currentItem in unsortedItems)
                        {
                            if (!processingMproSproItems) //we pull only the relevant items for these sections
                            {
                                if (currentItem.itemIsMPRO || currentItem.itemIsSPRO)
                                    continue; //skip it, not MPRO/SPRO sections
                                else if (!processingHighValueItems && currentItem.highValueCost > 0)
                                    continue;
                                else if (processingHighValueItems && currentItem.highValueCost <= 0)
                                    continue;
                                else if (!processingHighValueItems)
                                {
                                    if (isOrigin && currentItem.inventoriedAfterSignature)
                                    {
                                        hasItemsInventoriedAfterSig = TRUE;
                                        break; //inv. after customer sign, found end of items (sort places them all on bottom)
                                    }
                                    else if (!isOrigin && !currentItem.itemIsDelivered && !currentItem.itemIsDeleted)
                                        continue; //missing items, do not show in inventory anymore (defect 324)
                                }
                            }
                            
                            [items addObject:currentItem]; //add it, we'll process it
                            
                            //add carton content items if found
                            if (![del.surveyDB pvoItemHasExpandedCartonContentItems:currentItem.pvoItemID])
                                continue; //skip it, not detailed
                            
                            cartonContents = [del.surveyDB getPVOCartonContents:currentItem.pvoItemID withCustomerID:del.customerID];
                            int ccCount = 0;
                            for (PVOCartonContent *cc in cartonContents)
                            {
                                if (![del.surveyDB pvoCartonContentItemIsExpanded:cc.cartonContentID])
                                    continue; //skip it, not detailed
                                PVOItemDetail *ccItem = [del.surveyDB getPVOCartonContentItem:cc.cartonContentID];
                                if (ccItem != nil)
                                {
                                    ccCount++;
                                    ccItem.lotNumber = currentItem.lotNumber;
                                    ccItem.itemNumber = [NSString stringWithFormat:@"%@.%d", currentItem.fullItemNumber, ccCount];
                                    ccItem.itemID = cc.contentID;
                                    //want to show up with parent item
                                    ccItem.inventoriedAfterSignature = currentItem.inventoriedAfterSignature;
                                    ccItem.itemIsDelivered = currentItem.itemIsDelivered;
                                    ccItem.itemIsDeleted = currentItem.itemIsDeleted;
                                    ccItem.voidReason = currentItem.voidReason;
                                    [items addObject:ccItem];
                                }
                            }
                        }
                        [self sortPVOItemDetailArray:items accountForInvAfterSig:isOrigin];
                        
                        for (int k = 0; k < [items count]; k++)
                        {
                            myItem = [items objectAtIndex:k];
                            
                            //if (!myItem.inventoriedAfterSignature || !isOrigin)
                            {
                                if (k == 0 && processingMproSproItems)
                                {
                                    if (x == 0)
                                    {
                                        currentProgressCounter++;
                                        if (![self printSection:@selector(invItemsStartMpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter +
                                                                                                             currentProgressCounter)])
                                            goto endPage;
                                    }
                                    else
                                    {
                                        currentProgressCounter++;
                                        if (![self printSection:@selector(invItemsStartSpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter +
                                                                                                             currentProgressCounter)])
                                            goto endPage;
                                    }
                                }
                                
                                if (myItem.lotNumber != nil && ![currentLotNum isEqualToString:myItem.lotNumber])
                                {
                                    if (newPagePerLot && currentLotNum != nil && currentLotNum.length > 0 && !processingMproSproItems) //defect 1136 mpro and spro same page even if new page per lot is on
                                    {
                                        currentProgressCounter++;
                                        if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                            goto endPage;
                                    }
                                    
                                    if (!processingMproSproItems && (currentLotNum == nil || [currentLotNum isEqualToString:@""]))
                                    {
                                        if (processingPackersInvItems && !printedPackerInv)
                                        {
                                            printedPackerInv = YES;
                                            currentProgressCounter++;
                                            if (![self printSection:@selector(invItemsStartPacker) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter +
                                                                                                                   currentProgressCounter)])
                                                goto endPage;
                                        }
                                        if (processingHighValueItems)
                                        {
                                            currentProgressCounter++;
                                            if (![self printSection:@selector(invItemsStartHighValue) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter +
                                                                                                                      currentProgressCounter)])
                                                goto endPage;
                                        }
                                    }
                                    
                                    currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                                    
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                                
                                if (/*myItem.lotNumber != nil && ![lotNums containsObject:myItem.lotNumber] && */(docProgress - 1) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter))
                                {
                                    [currentPageItems addObject:myItem];
                                }
                                
                                currentProgressCounter++;
                                if (![self printSection:@selector(invItem) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                {
                                    [currentPageItems removeLastObject]; //remove last item, didn't fit
                                    myItem = nil;
                                    goto endPage;
                                }
                                
                                if (myItem.itemIsDeleted)
                                {
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemStrikethrough) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                            }
                        }
                        
                        if (unsortedItems != nil)
                        {
                            unsortedItems = nil;
                        }
                        if (items != nil)
                        {
                            
                            items = nil;
                        }
                    }
                    
                    if(currentProgressCounter >= 0)
                    {
                        if (unsortedItems != nil)
                        {
                            unsortedItems = nil;
                        }
                        if (items != nil)
                        {
                            
                            items = nil;
                        }
                        
                        if (processingMproSproItems)
                        {
                            if (currentProgressCounter > 0)
                            {
                                if (x == 0)
                                {
                                    //re-print the "header"
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsStartMpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                    
                                    //print summary at end on new line
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsEndMpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                                else
                                {
                                    //re-print the "header"
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsStartSpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                    
                                    //print summary at end on new line
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsEndSpro) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                    
                                }
                            }
                        }
                        else
                        {
                            if (processingHighValueItems)
                            {
                                if (currentProgressCounter > 0)
                                {
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsEndHighValue) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                            }
                            else if (processingPackersInvItems)
                            {
                                if (printedPackerInv)
                                {
                                    currentProgressCounter++;
                                    if(![self printSection:@selector(invItemsPackerInitialCounts) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                    
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsEndPacker) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                            }
                            
                            if (!processingHighValueItems && !processingPackersInvItems && (!isOrigin || !hasItemsInventoriedAfterSig))
                            {//only print if it won't print after items inventoried after sig
                                currentProgressCounter++;
                                if (![self printSection:@selector(invItemsEnd) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                    goto endPage;
                            }
                        }
                        
                        if (currentProgressCounter > 0 && [self shouldSectionFinishPage:x withInvData:invData withLoads:loads])
                        {
                            currentProgressCounter++;
                            if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                goto endPage;
                        }
                    }
                    
                    // missing item list
                    if (!processingMproSproItems && !isOrigin && (x % 2) == 1)
                    {
                        if (currentPageItems != nil)
                        {
                            currentPageItems = nil;
                        }
                        currentPageItems = [[NSMutableArray alloc] init];
                        printingMissingItems = TRUE;
                        missingProgressCounter = 0;
                        
                        sprCheck = FALSE;
                        dvrCheck = FALSE;
                        whsCheck = FALSE;
                        
                        for (int i = 0; i < [loads count]; i++)
                        {
                            PVOInventoryLoad *load = [loads objectAtIndex:i];
                            pvoLoadID = load.pvoLoadID;
                            
                            if ((processingPackersInvItems && load.pvoLocationID != 7) || (!processingPackersInvItems && load.pvoLocationID == 7))
                                continue; //skip it, not packer inv
                            
                            unsortedItems = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                            NSArray *cartonContents;
                            for (PVOItemDetail *currentItem in unsortedItems)
                            {//add carton content items if found
                                //skip stuff
                                if (currentItem.itemIsMPRO || currentItem.itemIsSPRO || currentItem.highValueCost > 0)
                                    continue;
                                else if ([currentItem itemIsDelivered] || [currentItem itemIsDeleted])
                                    continue;
                                else if (![del.surveyDB pvoItemHasExpandedCartonContentItems:currentItem.pvoItemID])
                                    continue; //skip it, not detailed
                                
                                cartonContents = [del.surveyDB getPVOCartonContents:currentItem.pvoItemID withCustomerID:del.customerID];
                                int ccCount = 0;
                                for (PVOCartonContent *cc in cartonContents)
                                {
                                    PVOItemDetail *ccItem = [del.surveyDB getPVOCartonContentItem:cc.cartonContentID];
                                    if (ccItem != nil)
                                    {
                                        ccCount++;
                                        ccItem.itemNumber = [NSString stringWithFormat:@"%@.%d", ccItem.fullItemNumber, ccCount];
                                        ccItem.itemID = cc.contentID;
                                        //want to show up with parent item
                                        ccItem.inventoriedAfterSignature = currentItem.inventoriedAfterSignature;
                                        ccItem.itemIsDelivered = currentItem.itemIsDelivered;
                                        ccItem.itemIsDeleted = currentItem.itemIsDeleted;
                                        ccItem.voidReason = currentItem.voidReason;
                                        if (items == nil) items = [[NSMutableArray alloc] init];
                                        [items addObject:ccItem]; //[ccItem retain]];
                                    }
                                }
                            }
                            if (items == nil) items = [[NSMutableArray alloc] init];
                            [items addObjectsFromArray:unsortedItems];
                            [self sortPVOItemDetailArray:items accountForInvAfterSig:NO];
                            for (int k = 0; k < [items count]; k++)
                            {
                                //skip stuff
                                if ([[items objectAtIndex:k] itemIsMPRO] || [[items objectAtIndex:k] itemIsSPRO] || [[items objectAtIndex:k] highValueCost] > 0)
                                    continue;
                                else if ([[items objectAtIndex:k] itemIsDelivered] || [[items objectAtIndex:k] itemIsDeleted])
                                    continue;
                                
                                myItem = [items objectAtIndex:k];
                                
                                if (missingProgressCounter == 0)
                                {
                                    currentProgressCounter++;
                                    if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                        goto endPage;
                                }
                                
                                missingProgressCounter++;
                                if (![self printSection:@selector(invItem) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter + missingProgressCounter)])
                                    goto endPage;
                            }
                        }
                        
                        if (items != nil)
                        {
                            
                            items = nil;
                            unsortedItems = nil;
                        }
                        
                        currentProgressCounter += missingProgressCounter;
                        
                        if (missingProgressCounter > 0)
                        {
                            currentProgressCounter++;
                            if (![self printSection:@selector(invItemsEnd) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                goto endPage;
                            
                            if ([self shouldSectionFinishPage:(x < INVENTORY_SECTION_HIGH_VALUE ? INVENTORY_SECTION_PACK_INV_MISSING : INVENTORY_SECTION_MISSING)
                                                  withInvData:invData withLoads:loads])
                            {
                                if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + currentProgressCounter)])
                                    goto endPage;
                            }
                        }
                    }
                    
                    progressCounter += currentProgressCounter;
                    currentProgressCounter = 0;
                }
                
                if (!isOrigin && !hasItemsInventoriedAfterSig)
                {
                    progressCounter++;
                    if (![self printSection:@selector(printDeliverySummary) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        goto endPage;
                    
                    //end page
                    if (printDeclineCheckoffWaiver && (docProgress) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                    {
                        if ([self declineCheckoff:NO finishAllOnNextPage:NO] > ((params.contentRect.size.height-takeOffBottom)-currentPageY))
                        {
                            progressCounter++;
                            [self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)];
                            
                            //finish decline cehckoff on the next page
                            [self declineCheckoff:NO finishAllOnNextPage:YES];
                            goto endPage;
                        }
                        else
                        {
                            progressCounter++;
                            if (![self printSection:@selector(finishPageWithSpaceForDeclineCheckoff) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                goto endPage;
                            
                            progressCounter++;
                            if (![self printSection:@selector(printDeclineCheckoff) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                goto endPage;
                        }
                    }
                    else
                    {
                        progressCounter++;
                        if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                }
                
                //print pages for items inventoried after sig
                if(isOrigin && hasItemsInventoriedAfterSig)
                {
                    if (myItem != nil && myItem.lotNumber != nil && [myItem.lotNumber length] > 0)
                        currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                    
                    if (currentPageItems != nil)
                    {
                        currentPageItems = nil;
                    }
                    currentPageItems = [[NSMutableArray alloc] init];
                    printingItemsInventoriedAfterSig = TRUE;
                    int itemsInventoriedAfterSigProgressCounter = 0;
                    
                    for (int i = 0; i < [loads count]; i++)
                    {
                        PVOInventoryLoad *load = [loads objectAtIndex:i];
                        pvoLoadID = load.pvoLoadID;
                        
                        unsortedItems = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                        NSArray *cartonContents;
                        for (PVOItemDetail *currentItem in unsortedItems)
                        {//add carton content items if found
                            //skip stuff
                            if (![currentItem inventoriedAfterSignature])
                                continue;
                            else if (![del.surveyDB pvoItemHasExpandedCartonContentItems:currentItem.pvoItemID])
                                continue; //skip it, not detailed
                            
                            cartonContents = [del.surveyDB getPVOCartonContents:currentItem.pvoItemID withCustomerID:del.customerID];
                            int ccCount = 0;
                            for (PVOCartonContent *cc in cartonContents)
                            {
                                PVOItemDetail *ccItem = [del.surveyDB getPVOCartonContentItem:cc.cartonContentID];
                                if (ccItem != nil)
                                {
                                    ccCount++;
                                    ccItem.itemNumber = [NSString stringWithFormat:@"%@.%d", ccItem.fullItemNumber, ccCount];
                                    ccItem.itemID = cc.contentID;
                                    //want to show up with parent item
                                    ccItem.inventoriedAfterSignature = currentItem.inventoriedAfterSignature;
                                    ccItem.itemIsDelivered = currentItem.itemIsDelivered;
                                    ccItem.itemIsDeleted = currentItem.itemIsDeleted;
                                    ccItem.voidReason = currentItem.voidReason;
                                    if (items == nil) items = [[NSMutableArray alloc] init];
                                    [items addObject:ccItem]; //[ccItem retain]];
                                }
                            }
                        }
                        if (items == nil) items = [[NSMutableArray alloc] init];
                        [items addObjectsFromArray:unsortedItems];
                        [self sortPVOItemDetailArray:items accountForInvAfterSig:YES afterSigOnBottom:NO];
                        for (int k = 0; k < [items count]; k++)
                        {
                            if (![[items objectAtIndex:k] inventoriedAfterSignature])
                                break; //found end, stop processing
                            
                            myItem = [items objectAtIndex:k];
                            
                            //if (myItem.inventoriedAfterSignature)
                            {
                                if (myItem.lotNumber != nil && (currentLotNum == nil || ![currentLotNum isEqualToString:myItem.lotNumber]))
                                {
                                    //only force new page if not first item
                                    if (newPagePerLot && currentLotNum != nil && currentLotNum.length > 0 && itemsInventoriedAfterSigProgressCounter > 0)
                                    {
                                        itemsInventoriedAfterSigProgressCounter++;
                                        if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + itemsInventoriedAfterSigProgressCounter)])
                                        {
                                            footerMethod = @selector(invFooterNoCustSignature:);
                                            goto endPage;
                                        }
                                    }
                                    
                                    currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                                    
                                    printingItemsInventoriedAfterSigLOT = TRUE;
                                    progressCounter++;
                                    if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + itemsInventoriedAfterSigProgressCounter)])
                                    {
                                        //only change if this isn't the first line on new page
                                        if (itemsInventoriedAfterSigProgressCounter > 0)
                                            footerMethod = @selector(invFooterNoCustSignature:);
                                        goto endPage;
                                    }
                                }
                                
                                if (itemsInventoriedAfterSigProgressCounter == 0)
                                {
                                    printingItemsInventoriedAfterSigLOT = FALSE;
                                    progressCounter++;
                                    if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                    {
                                        //footerMethod = @selector(invFooterNoCustSignature:);
                                        goto endPage;
                                    }
                                }
                                
                                if (/*myItem.lotNumber != nil && ![lotNums containsObject:myItem.lotNumber] && */(docProgress - 1) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + itemsInventoriedAfterSigProgressCounter))
                                {
                                    [currentPageItems addObject:myItem];
                                }
                                
                                itemsInventoriedAfterSigProgressCounter++;
                                if (![self printSection:@selector(invItem) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + itemsInventoriedAfterSigProgressCounter)])
                                {
                                    [currentPageItems removeLastObject]; //remove last item, didn't fit
                                    myItem = nil;
                                    footerMethod = @selector(invFooterNoCustSignature:);
                                    goto endPage;
                                }
                            }
                        }
                        
                        if (items != nil)
                        {
                            
                            items = nil;
                            unsortedItems = nil;
                        }
                    }
                    
                    /*if (itemsInventoriedAfterSigProgressCounter > 0)
                     {
                     if (![numsFrom containsObject:myItem.fullItemNumber] && docProgress < (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + itemsInventoriedAfterSigProgressCounter))
                     [numsTo addObject:myItem.fullItemNumber];
                     }*/
                    
                    if (items != nil)
                    {
                        
                        items = nil;
                        unsortedItems = nil;
                    }
                    
                    progressCounter += itemsInventoriedAfterSigProgressCounter;
                    
                    progressCounter++;
                    if (![self printSection:@selector(invItemsEnd) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                    {
                        footerMethod = @selector(invFooterNoCustSignature:);
                        goto endPage;
                    }
                    
                    if (!isOrigin)
                    {
                        progressCounter++;
                        if (![self printSection:@selector(printDeliverySummary) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                    
                    if (!isOrigin && printDeclineCheckoffWaiver && (docProgress) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                    {
                        if ([self declineCheckoff:NO finishAllOnNextPage:NO] > ((params.contentRect.size.height-takeOffBottom)-currentPageY))
                        {
                            progressCounter++;
                            [self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)];
                            
                            //finish decline checkoff on the next page
                            [self declineCheckoff:NO finishAllOnNextPage:YES];
                            footerMethod = @selector(invFooterNoCustSignature:);
                            goto endPage;
                        }
                        else
                        {
                            progressCounter++;
                            if (![self printSection:@selector(finishPageWithSpaceForDeclineCheckoff) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            {
                                footerMethod = @selector(invFooterNoCustSignature:);
                                goto endPage;
                            }
                            
                            progressCounter++;
                            if (![self printSection:@selector(printDeclineCheckoff) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            {
                                footerMethod = @selector(invFooterNoCustSignature:);
                                goto endPage;
                            }
                        }
                    }
                    else
                    {
                        progressCounter++;
                        if (![self printSection:@selector(finishPage) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        {
                            footerMethod = @selector(invFooterNoCustSignature:);
                            goto endPage;
                        }
                    }
                    
                    //printingItemsInventoriedAfterSig = FALSE;
                    footerMethod = @selector(invFooterNoCustSignature:);
                }
                
                //wrap up last page
                [self populateCpPboSummaries];
                
                if (docProgress - 1 <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                    footerMethod = @selector(invFooter:);
                
                progressCounter++;
                if (![self printSection:@selector(invPackSummaryStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                    goto endPage;
                
                progressCounter++;
                if (![self printSection:@selector(invPackSummaryHeader) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                    goto endPage;
                
                progressCounter++;
                if (![self printSection:@selector(invPackSummaryDetail) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                    goto endPage;
            }
            else if (reportID == ESIGN_AGREEMENT)
            {
                if (![self printSection:@selector(eSignPage1) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE1])
                    goto endPage;
                
                if (![self printSection:@selector(eSignPage2) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE2])
                    goto endPage;
                
                if (![self printSection:@selector(eSignPage3) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE3])
                    goto endPage;
            }
            else if (reportID == RIDER_EXCEPTIONS)
            {
                int progressCounter = 0;
                
                PVOInventoryLoad *workingLoad = [self getRiderExceptionsWorkingLoad];
                BOOL printNoneLine = YES;
                if (workingLoad != nil)
                {
                    NSArray *items = [del.surveyDB getPVOItemsForLoad:workingLoad.pvoLoadID];
                    NSMutableArray *workItems = [[NSMutableArray alloc] init];
                    if (items != nil && [items count] > 0)
                    {
                        for (PVOItemDetail *item in items)
                        {
                            if ([del.surveyDB hasPVODamage:item.pvoItemID forDamageType:DAMAGE_RIDER])
                                [workItems addObject:item];
                        }
                    }
                    
                    
                    if (workItems != nil && [workItems count] > 0)
                    {
                        printNoneLine = NO;
                        //sort it, then print em
                        [workItems sortUsingComparator:^NSComparisonResult(id a, id b) {
                            if (a == b || (a == nil && b == nil))
                                return NSOrderedSame;
                            else if (a == nil)
                                return NSOrderedDescending;
                            else if (b == nil)
                                return NSOrderedAscending;
                            else
                            {
                                PVOItemDetail *first = nil, *second = nil;
                                if ([a class] == [PVOItemDetail class])
                                    first = (PVOItemDetail*)a;
                                if ([b class] == [PVOItemDetail class])
                                    second = (PVOItemDetail*)b;
                                if (first == second || (first == nil && second == nil))
                                    return NSOrderedSame;
                                else if (first == nil)
                                    return NSOrderedDescending;
                                else if (second == nil)
                                    return NSOrderedAscending;
                                else
                                {
                                    NSString *firstLotNum = (first.lotNumber == nil ? @"" : first.lotNumber),
                                    *secondLotNum = (second.lotNumber == nil ? @"" : second.lotNumber);
                                    if (first.tagColor != second.tagColor)
                                        return [[NSNumber numberWithInt:first.tagColor] compare:[NSNumber numberWithInt:second.tagColor]];
                                    else if (![firstLotNum isEqualToString:secondLotNum])
                                        return [firstLotNum compare:secondLotNum];
                                    else
                                        return [[first fullItemNumber] compare:[second fullItemNumber]];
                                }
                            }
                        }];
                        
                        for (PVOItemDetail *item in workItems)
                        {
                            myItem = item;
                            progressCounter++;
                            if (![self printSection:@selector(riderItem) withProgressID:(RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter)])
                                goto endPage;
                        }
                    }
                }
                
                if (printNoneLine)
                {
                    progressCounter++;
                    if (![self printSection:@selector(riderItemNone) withProgressID:(RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter)])
                        goto endPage;
                }
                
                if (docProgress <= (RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter))
                {
                    //should we finish page and print notes on another page?
                    if (params.contentRect.size.height-takeOffBottom-currentPageY < [self riderNotes:NO])
                    {
                        progressCounter++;
                        if (![self printSection:@selector(riderFinishPage) withProgressID:(RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                }
                
                progressCounter++;
                if (![self printSection:@selector(riderFinishPage) withProgressID:(RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter)])
                    goto endPage;
                
                progressCounter++;
                if (![self printSection:@selector(riderNotesPrint) withProgressID:(RIDER_EXCEPTIONS_PROGRESS_BEGIN + progressCounter)])
                    goto endPage;
            }
        }
        @catch (NSException * e) { }
    
        endOfDoc = TRUE;
        docProgress = 0;
        tempDocProgress = 0;
    
    endPage:
    
        if(tempCurrentPageY != currentPageY)
        {
            [self printPageFooter];
        }
    
    //    if (invData != nil)
    //        [invData release];
    
    //    if (items != nil)
    //
    
        //    if (myItem != nil)
        //        
    
        if (context != NULL)
        {
            UIGraphicsPopContext();
            
            CGContextRestoreGState(context);
            
            CGContextFlush(context);
        }
    }
    //[pool release];
    return TRUE;
}

-(BOOL)shouldSectionFinishPage:(int)section withInvData:(PVOInventory*)invData withLoads:(NSArray*)loads
{
    if (!hasPopulatedInventorySectionCounts)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        mpro = spro = nonMproSpro = packInvHV = packInvNotHV = packInvMissing = allOtherHV = allOtherNotHV = allOtherMissing = 0; //clear 'em
        if (invData.loadType == MILITARY)
        {
            mpro = [del.surveyDB getPVOItemCountMpro:custID];
            spro = [del.surveyDB getPVOItemCountSpro:custID];
            nonMproSpro = [del.surveyDB getPVOItemCountNonMproSpro:custID];
        }
        if (loads != nil && [loads count] > 0)
        {
            for (PVOInventoryLoad *l in loads)
            {
                int count = [del.surveyDB getPVOItemCountForLocation:l.pvoLoadID includeDeleted:YES ignoreItemList:NO];
                if (l.pvoLocationID == 7)
                    packInvNotHV += count;
                else
                    allOtherNotHV += count;
                count = [del.surveyDB getPvoHighValueItemsCountForLoad:l.pvoLoadID];
                if (l.pvoLocationID == 7)
                    packInvHV += count;
                else
                    allOtherHV += count;
                count = [del.surveyDB getPVOItemMissingCountForLocation:l.pvoLoadID];
                if (l.pvoLocationID == 7)
                    packInvMissing += count;
                else
                    allOtherMissing += count;
                if (isOrigin)
                {
                    count = [del.surveyDB getPVOItemAfterInventorySignCountForLocation:l.pvoLoadID];
                    if (l.pvoLocationID == 7)
                        packInvAfterSign += count;
                    else
                        allOtherAfterSign += count;
                }
            }
        }
        //subtract high value items from total count
        if (packInvHV > 0 && packInvNotHV >= packInvHV)
            packInvNotHV -= packInvHV;
        if (allOtherHV > 0 && allOtherNotHV >= allOtherHV)
            allOtherNotHV -= allOtherHV;
        hasPopulatedInventorySectionCounts = YES;
    }
    int checkingSection = section;
    BOOL skipMissing = NO;
    if (section == INVENTORY_SECTION_MPRO)
    {
        return isOrigin && spro == 0 && nonMproSpro == 0;
    }
    else if (section == INVENTORY_SECTION_SPRO)
    {
        return isOrigin && nonMproSpro == 0;
    }
    else if (section == INVENTORY_SECTION_PACK_INV_HIGH_VALUE)
    {
        if (packInvHV > 0 || (!isOrigin && packInvMissing > 0))
            return NO;
        else
            checkingSection = INVENTORY_SECTION_PACK_INV_ALL_OTHER;
    }
    else if (section == INVENTORY_SECTION_HIGH_VALUE)
    {
        if (allOtherNotHV > 0 || (!isOrigin && allOtherMissing > 0))
            return NO;
        else
            checkingSection = INVENTORY_SECTION_ALL_OTHER;
    }
    else if (section == INVENTORY_SECTION_PACK_INV_MISSING)
    {
        checkingSection = INVENTORY_SECTION_PACK_INV_ALL_OTHER;
        skipMissing = YES;
    }
    else if (section == INVENTORY_SECTION_MISSING)
    {
        checkingSection = INVENTORY_SECTION_ALL_OTHER;
        skipMissing = YES;
    }
    
    if (checkingSection == INVENTORY_SECTION_PACK_INV_ALL_OTHER)
    {
        if (!skipMissing && !isOrigin && packInvMissing > 0)
            return NO;
        else
            return (packInvHV + packInvNotHV + packInvMissing > 0) && (isOrigin || (allOtherHV + allOtherNotHV) > 0);
    }
    else if (checkingSection == INVENTORY_SECTION_ALL_OTHER)
    {
        if (!skipMissing && !isOrigin && allOtherMissing > 0)
            return NO;
        else
            return (allOtherHV + allOtherNotHV + allOtherMissing > 0) && (isOrigin /*|| packInvAfterSign + allOtherAfterSign == 0*/);
    }
    return NO;
}

// MARK: E-Sign Agreement
-(int)eSignPage1
{
    currentPageY += TO_PRINTER(35.);
    
    //set up section
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.cellType = CELL_LABEL;
	cell.width = width;
	cell.font = ESIGN_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.padding = 0;
	[section addCell:cell];
	
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Arpin E-Com Agreement\r\n "]] withColName:@"header"];
	
	//place it
	CGPoint pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	int drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Arpin Van Lines, Inc. (AVL) is dedicated to providing you with the highest quality service, "
                               "at affordable rates and in environmentally conscious ways. Utilizing cutting-edge technology, we have developed \"Arpin E-Com\" "
                               "to provide you with better, faster and more efficient moving services through a sustainable, virtually paperless environment. "
                               "Through the use of electronic documents, scanning, emailing, retrieval, and archiving of your shipping documents, "
                               "together we can minimize the use of paper, which makes sense from both an economic and eco-friendly perspective. "
                               "Therefore, we invite you to participate in the Arpin E-Com solution.\r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
    NSString *highValueDesc = [AppFunctionality getHighValueDescription];
    
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"1. Electronic Signature Agreement. By using your finger to sign your name on the "
                               "screen below and then clicking the \"Done\" button, you are signing this Agreement electronically. You "
                               "agree that your electronic signature is and shall be the legal equivalent of your manual signature on "
                               "this Agreement and you hereby consent to be legally bound by the terms and conditions of this Agreement. "
                               "You further agree that your use of a key pad, mouse, your finger, stylus, or other device to sign your "
                               "name and/or to select an item, button, icon or similar action, or to otherwise give AVL instructions, or "
                               "in accessing from or making any transaction with AVL regarding any agreement, acknowledgement, consent "
                               "terms, disclosures or conditions (including, but not limited to, any and all orders for service, survey "
                               "forms, estimates, bills of lading, inventory sheets, %@ inventory forms, home inspection reports, "
                               "statement of charges, and claims forms) shall constitute your signature (hereafter referred to as "
                               "\"E- Signature\"), acceptance and agreement as if actually signed by you in writing. You also agree that "
                               "no certification authority or other third party verification is necessary to validate your E- Signature and "
                               "that the lack of such certification or third party verification will not in any way affect the "
                               "enforceability of your E-Signature or any resulting contract between you and AVL. You also represent that "
                               "you are authorized to enter into this Agreement for all persons who own or are authorized to access any of "
                               "your household goods and that such persons will be bound by the terms and conditions of this Agreement. "
                               "You further agree that each use of your E-Signature in obtaining an AVL service constitutes your agreement "
                               "to be bound by the terms and conditions of the AVL disclosures and agreements as they exist on the date of "
                               "your E-Signature.\r\n ", highValueDesc]]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"2. Consent to Electronic Delivery. You specifically agree to receive and/or "
                               "obtain any and all AVL related \"Electronic Communications\" (defined below) via email, online "
                               "system or the like. The term \"Electronic Communications\" includes, but is not limited to, any and "
                               "all current and future notices, consent forms, information, documents, agreements, and/or disclosures "
                               "(including, but not limited to, any and all orders for service, survey forms, estimates, bills of "
                               "lading, inventory sheets, %@ inventory forms, home inspection reports, statement of charges, "
                               "and claims forms) that various federal and/or state laws or regulations (or contracts in the case of "
                               "corporate accounts) require that AVL provide to you, as well as such other documents, statements, data, "
                               "records and any other communications regarding the services provided by AVL. You acknowledge that, "
                               "for your records, you are able to retain Electronic Communications by printing and/or downloading and "
                               "saving this Agreement and any other agreements and Electronic Communications, documents, or records that "
                               "you agree to using your E-Signature. You accept Electronic Communications provided via email, online "
                               "system or the like as reasonable and proper notice, for the purpose of any and all laws, rules, and "
                               "regulations (and contracts in the case of corporate accounts), and agree that such electronic form "
                               "fully satisfies any requirement that such communications be provided to you in writing or in a form "
                               "that you may keep.\r\n ", [AppFunctionality getHighValueDescription]]]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
    
    return DIDNT_FIT_ON_PAGE;
}

-(int)eSignPage2
{
    currentPageY += TO_PRINTER(50.);
    
    //set up section
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"3. Paper version of Electronic Communications. You may request a "
                                                              "paper version of an Electronic Communication. You acknowledge that AVL reserves the right "
                                                              "to charge you a reasonable fee for the production and mailing of paper versions of Electronic "
                                                              "Communications. To request a paper copy of an Electronic Communication please contact us at "
                                                              "(800) 343-3500, Extension 2577.\r\n "]] withColName:@"body"];
	
	//place it
	CGPoint pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	int drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"4. Revocation of electronic delivery. You have the right to withdraw your consent to "
                               "receive/obtain Electronic Communications from AVL at any time. You acknowledge that AVL reserves the right to "
                               "restrict or terminate your access to Arpin E-Com or any online system relating thereto if you withdraw your "
                               "consent to receive Electronic Communications. If you wish to withdraw your consent, please contact us at (800) "
                               "343-3500, Extension 2280.\r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"5. Valid and current email address, notification and updates. Your current valid "
                               "email address is required in order for you to obtain AVL services and Electronic Communications. You agree to "
                               "keep AVL informed of any changes in your email address. You may modify your email address by emailing your "
                               "new email address to info@arpin.com. AVL may notify you through email when an Electronic Communication or updated "
                               "agreement pertaining to Arpin E- Com is available. It is your responsibility to regularly check for Electronic "
                               "Communications from AVL and to check for updates to this Agreement.\r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"6. Hardware, software and operating system. You are responsible for installation, "
                               "maintenance, and operation of your computer, browser and software. AVL is not responsible for errors or failures "
                               "from any malfunction of your computer, browser or software. AVL is also not responsible for computer viruses "
                               "or related problems associated with use of an online system. The following are the minimum hardware, software "
                               "and operating system requirements necessary to use Arpin E-Com or receive Electronic Communications from AVL:\r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = NINEPOINT_BOLD_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Windows"]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .12;
	cell.font = NINEPOINT_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .78)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObjects:
                              [CellValue cellWithLabel:@"• Intel® 1.3GHz or faster processor"],
                              [CellValue cellWithLabel:@"• Microsoft® Windows® XP Home, Professional, or Tablet PC Edition with "
                               "Service Pack 3 (32 bit), or"],
                              [CellValue cellWithLabel:@"• Service Pack 2 (64 bit); Windows Server® 2003 (with Service Pack 2 "
                               "for 64 bit; Windows Server® 2008 (32\r\n  bit and 64 bit)"],
                              [CellValue cellWithLabel:@"• Windows Server 2008 R2 (32 bit and 64 bit); Windows Vista® Home Basic, "
                               "Home Premium, Business,\r\n  Ultimate, or"],
                              [CellValue cellWithLabel:@"• Enterprise with Service Pack 2 (32 bit and 64 bit); Windows 7 or "
                               "Windows 7 with Service Pack 1 Starter,\r\n  Home Premium, Professional, Ultimate, or Enterprise (32 bit and 64 bit)"],
                              [CellValue cellWithLabel:@"• 256MB of RAM (512MB recommended)"],
                              [CellValue cellWithLabel:@"• 260MB of available hard-disk space"],
                              [CellValue cellWithLabel:@"• 1024x576 screen resolution"],
                              [CellValue cellWithLabel:@"• Microsoft Internet Explorer 7, 8, 9; Firefox 3.6, 4.0 or 6.0; Chrome"],
                              [CellValue cellWithLabel:@"• Video hardware acceleration (optional)"],
                              nil]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = NINEPOINT_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Note: Microsoft Update KB930627 (http://support.microsoft.com/kb/930627) is required for both Windows XP SP2 64 Bit and Windows Server 2003 SP2 64 Bit."]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = NINEPOINT_BOLD_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Mac OS"]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .12;
	cell.font = NINEPOINT_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .78)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .1)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObjects:
                              [CellValue cellWithLabel:@"• Intel processor"],
                              [CellValue cellWithLabel:@"• Mac OS X v.10.5.8 or 10.7"],
                              [CellValue cellWithLabel:@"• 512MB of RAM (1G recommended)"],
                              [CellValue cellWithLabel:@"• 415MB of available hard-disk space"],
                              [CellValue cellWithLabel:@"• 800x600 screen resolution (1024x768 recommended)"],
                              [CellValue cellWithLabel:@"• Apple Safari 4 for Mac OS X 10.5.8 and Mac OS X 10.6.7; Safari 5 for Mac OS X 10.6.7 - 10.6.8"],
                              nil]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    return DIDNT_FIT_ON_PAGE;
}

-(int)eSignPage3
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *eSignSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT];
    
    BOOL eSignSigApplied = FALSE;
    if (eSignSig != nil)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[eSignSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            eSignSigApplied = TRUE;
    }
    
    currentPageY += TO_PRINTER(50.);
    
    //set up section
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"7. Controlling Agreement. This Agreement supplements and modifies other agreements that you "
                               "may have with AVL. To the extent that this Agreement and another agreement contain conflicting provisions, the provisions "
                               "in this Agreement will control (with the exception of provisions in another agreement for an electronic service which "
                               "provisions specify the necessary hardware, software and operating system, in which case such other provision controls). "
                               "All other obligations of the parties remain subject to the terms and conditions of any other agreement.\r\n "]] withColName:@"body"];
	
	//place it
	CGPoint pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	int drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_BOLD_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"To participate in the Arpin E-Com program and obtain Electronic Communications from AVL, "
                               "indicate your consent to the terms and conditions of this Agreement by using your finger to sign the screen below "
                               "and then click on the \"Done\" button.\r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"body" withType:CELL_LABEL withWidth:(width * .8)];
	
	//add values
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"It is recommended that you print a copy of this Agreement for future reference.\r\n \r\n "]]
                 withColName:@"body"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    [self updateCurrentPageY];
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
	
	//set up cell(s)
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"blank1";
	cell.cellType = CELL_LABEL;
    cell.underlineValue = TRUE;
	cell.width = width * .1;
	cell.font = ESIGN_FONT;
    cell.padding = 0;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"CustomerSignature" withType:CELL_TEXT_LABEL withWidth:(width * .59)];
    [section duplicateLastCell:@"Date" withType:CELL_TEXT_LABEL withWidth:(width * .21) withAlign:NSTextAlignmentCenter];
	
	//add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithValue:@" " withLabel:@"Customer Signature: "]] withColName:@"CustomerSignature"];
    
    if (eSignSigApplied)
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithValue:[SurveyAppDelegate formatDate:eSignSig.sigDate]
                                                 withLabel:@" Date: "]]
                     withColName:@"Date"];
    }
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithValue:@" " withLabel:@"Date: "]] withColName:@"Date"];
	
	//place it
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	//print it, check to make sure it fit...
	//if not, store it in the collection of items to continue...
	drawn = [section drawSection:context withPosition:pos andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	
    
    
    // e-sign sig
    if (eSignSigApplied)
    {
        UIImage *img = [eSignSig signatureData];
        CGSize tmpSize = [img size];
        img = [SurveyAppDelegate scaleAndRotateImage:img withOrientation:UIImageOrientationDownMirrored];
        CGRect imgRect = CGRectMake(params.contentRect.origin.x + (width * 0.35),
                                    leftCurrentPageY - TO_PRINTER(26.),
                                    tmpSize.width * 0.155,
                                    tmpSize.height * 0.155);
        [self drawImage:img withCGRect:imgRect];
    }
    
    
    return drawn;
}

//MARK: Inventory Report
-(int)addHeader:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    SurveyLocation *orig = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
    SurveyLocation *dest = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
    
    int padding = TO_PRINTER(1.);
    NSString *vanLineText = @"";
    
    if (print)
    {
        double scale = 1;
        if ([vanLineText length] > 0)
        {
            UIImage *image1 = [UIImage imageNamed:vanLineText];
            CGSize	tmpSize1 = [image1 size];
            image1 = [SurveyAppDelegate scaleAndRotateImage:image1 withOrientation:UIImageOrientationDownMirrored];
            CGRect imageRect1 = CGRectMake(params.contentRect.origin.x + TO_PRINTER(2.),
                                           params.contentRect.origin.y + TO_PRINTER(3.),
                                           tmpSize1.width * scale,
                                           tmpSize1.height * scale);
            
            [self drawImage:image1 withCGRect:imageRect1];
        }
    }
    
    
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.padding = 3;
    cell.underlineValue = FALSE;
    cell.width = width * .22;
    cell.font = PVO_REPORT_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    [section duplicateLastCell:@"website" withType:CELL_LABEL withWidth:(width * .2) withAlign:NSTextAlignmentCenter];
    
    //add values
    vanLineText = @"";
    
    
    if(cust.pricingMode == INTERSTATE)
    {
        //website text goes here
    }
    
    
    NSMutableArray *colVals = [[NSMutableArray alloc] init];
    [colVals addObject:[CellValue cellWithLabel:vanLineText]];
    [section addColumnValues:colVals withColName:@"website"];
    
    
    //place it
    CGPoint pos = params.contentRect.origin;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
    {
        [section drawSection:context
                withPosition:pos
              andRemainingPX:(params.contentRect.size.height-takeOffBottom)];
    }
    
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.padding = 0;
    cell.width = width * .4;
    cell.font = NINEPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"header" withType:CELL_LABEL withWidth:(width * .3) withAlign:NSTextAlignmentCenter];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               @" \r\nRELOCATION SERVICES\r\n"
                               "DESCRIPTIVE INVENTORY\r\n "]]
                 withColName:@"header"];
    
    //place it
    pos = params.contentRect.origin;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    int drawn = 0, tempDrawn = 0;
    if (!print)
        tempDrawn += [section height];
    else
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:(params.contentRect.size.height-takeOffBottom)-tempDrawn];
    
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.padding = 0;
    cell.width = width * .8;
    cell.font = PVO_REPORT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"header" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@" \r\n%@\r\n%@",
                                @"ORDER NUMBER",
                                inf.orderNumber]]]
                 withColName:@"header"];
    
    //place it
    pos = params.contentRect.origin;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    if (drawn > tempDrawn)
        tempDrawn = drawn;
    else
        drawn = tempDrawn;
    
    
    //set up section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"CustomerName";
    cell.cellType = CELL_LABEL;
    cell.width = width * .8;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"PageNo" withType:CELL_LABEL withWidth:(width * .1)];
    [section duplicateLastCell:@"NoPages" withType:CELL_LABEL withWidth:(width * .1)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Customer's Name"]] withColName:@"CustomerName"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Page No."]] withColName:@"PageNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" No. of Pages"]] withColName:@"NoPages"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"CustomerName";
    cell.cellType = CELL_LABEL;
    cell.width = width * .8;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"PageNo" withType:CELL_LABEL withWidth:(width * .1)];
    [section duplicateLastCell:@"NoPages" withType:CELL_LABEL withWidth:(width * .1)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@ %@", cust.firstName, cust.lastName]]]
                 withColName:@"CustomerName"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", [SurveyAppDelegate formatDouble:params.pageNum withPrecision:0]]]]
                 withColName:@"PageNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", [SurveyAppDelegate formatDouble:params.totalPages withPrecision:0]]]]
                 withColName:@"NoPages"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    //set up section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Address";
    cell.cellType = CELL_LABEL;
    cell.width = width * .45;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"GovtBOL" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Origin Address"]] withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" City"]] withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" ST"]] withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" ZIP"]] withColName:@"Zip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Govt Bill of Lading No."]] withColName:@"GovtBOL"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Address";
    cell.cellType = CELL_LABEL;
    cell.width = width * .45;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"GovtBOL" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    NSString *address = [NSString stringWithFormat:@"%@", orig.address1 == nil ? @"" : orig.address1];
    if (orig.address2 != nil && [orig.address2 length] > 0)
        address = [address stringByAppendingFormat:@" %@", orig.address2];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", address]]]
                 withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.city == nil ? @"" : orig.city]]]
                 withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.state == nil ? @"" : orig.state]]]
                 withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.zip == nil ? @"" : orig.zip]]]
                 withColName:@"Zip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", inf.gblNumber == nil ? @"" : inf.gblNumber]]]
                 withColName:@"GovtBOL"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    //set up section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Address";
    cell.cellType = CELL_LABEL;
    cell.width = width * .45;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"VanNo" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Destination Address"]] withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" City"]] withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" ST"]] withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" ZIP"]] withColName:@"Zip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Tractor/Trailer #"]] withColName:@"VanNo"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Address";
    cell.cellType = CELL_LABEL;
    cell.width = width * .45;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"VanNo" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    address = [NSString stringWithFormat:@"%@", dest.address1 == nil ? @"" : dest.address1];
    if (dest.address2 != nil && [dest.address2 length] > 0)
        address = [address stringByAppendingFormat:@" %@", dest.address2];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", address]]]
                 withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.city == nil ? @"" : dest.city]]]
                 withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.state == nil ? @"" : dest.state]]]
                 withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.zip == nil ? @"" : dest.zip]]]
                 withColName:@"Zip"];
    
    NSString *tractor = [NSString stringWithFormat:@"%@", inventory.tractorNumber != nil ? inventory.tractorNumber : @""];
    NSString *trailer = [NSString stringWithFormat:@"%@", inventory.trailerNumber != nil ? inventory.trailerNumber : @""];
    if ([tractor isEqualToString:@""] && driver.tractorNumber != nil && ![driver.tractorNumber isEqualToString:@""])
        tractor = [NSString stringWithFormat:@"%@", driver.tractorNumber];
    if ([trailer isEqualToString:@""] && driver.unitNumber != nil && ![driver.unitNumber isEqualToString:@""])
        trailer = [NSString stringWithFormat:@"%@", driver.unitNumber];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"    %@%@%@",
                                tractor,
                                (![tractor isEqualToString:@""] && ![trailer isEqualToString:@""] ? @" / " : @""),
                                trailer]]]
                 withColName:@"VanNo"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    if (drawn > tempDrawn)
        tempDrawn = drawn;
    else
        drawn = tempDrawn;
    
    
    //set up ADDRESSES section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_ALL;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = SIXPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ItemNo";
    cell.cellType = CELL_LABEL;
    cell.width = width * .04;
    cell.font = PVO_REPORT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"Description" withType:CELL_LABEL withWidth:(width * .288)];
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    [section duplicateLastCell:@"ConditionsAtDest" withType:CELL_LABEL withWidth:(width * .252)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"W\r\nH\r\nS"]] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"D\r\nV\r\nR"]] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"W\r\nH\r\nS"]] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"S\r\nP\r\nR"]] withColName:@"SPR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"ITEM\r\nNO.\r\n "]] withColName:@"ItemNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\nLOCATION - ARTICLES\r\n "]] withColName:@"Description"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"CP, SW,\r\nPBO\r\n "]] withColName:@"CPSWPBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"CONDITIONS AT ORIGIN\r\n \r\n "]] withColName:@"ConditionsAtOrg"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\nCONDITIONS AT DESTINATION\r\n "]] withColName:@"ConditionsAtDest"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += tempDrawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        tempDrawn += [section height];
    else
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:(params.contentRect.size.height-takeOffBottom)-tempDrawn];
    
    
    
    
    if (print)
    {
        //set up ADDRESSES section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"WHS1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .018;
        cell.font = PVO_REPORT_FONT;
        cell.textPosition = NSTextAlignmentCenter;
        cell.borderType = BORDER_RIGHT;
        [section addCell:cell];
        
        
        [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"WHS1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"DVR"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"WHS2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"SPR"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y += drawn;
        
        [section drawSection:context
                withPosition:pos
              andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
        
        
    }
    
    
    //set up ADDRESSES section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = PVO_REPORT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"blank3" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"blank4" withType:CELL_LABEL withWidth:(width * .018)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank5";
    cell.cellType = CELL_LABEL;
    cell.width = width * .04;
    cell.font = PVO_REPORT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"blank6" withType:CELL_LABEL withWidth:(width * .288)];
    [section duplicateLastCell:@"blank7" withType:CELL_LABEL withWidth:(width * .07)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ConditionsAtOrg";
    cell.cellType = CELL_LABEL;
    cell.width = width * .28;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.5)];
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"blank1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"blank2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"blank3"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\n "]] withColName:@"blank4"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n \r\nNOTE: <> indicates good condition except for normal wear"]] withColName:@"ConditionsAtOrg"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-drawn];
    
    
    
    
    if (drawn > tempDrawn)
        tempDrawn = drawn;
    else
        drawn = tempDrawn;
    
    return drawn;
}

-(int)invItemsStart
{
    NSString *descrip = nil, *itemNo = nil;
    UIFont *font = PVO_REPORT_FONT;
    if (printingMissingItems || (printingItemsInventoriedAfterSig && !printingItemsInventoriedAfterSigLOT))
    {
        font = PVO_REPORT_BOLD_FONT;
        itemNo = @"XXX";
        if (printingMissingItems)
        {
            if (processingPackersInvItems)
                descrip = @"--- MISSING PACKER ITEMS ---";
            else
                descrip = @"--- MISSING ITEMS ---";
        }
        else
            descrip = @"Items to follow were inventoried after customer departure.";
    }
    else
    {
        itemNo = @"LOT";
        descrip = [NSString stringWithFormat:@"%@", myItem.lotNumber];
    }
    return [self printInvLineDescrip:descrip withItemNo:itemNo withFont:font];
}

-(int)invItemsStartMpro
{
    return [self printInvLineDescrip:@"** Member Professional Gear (MPRO)" withItemNo:@"" withFont:PVO_REPORT_FONT];
}

-(int)invItemsEndMpro
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = nil;
    @try {
        
        inventory = [del.surveyDB getPVOData:del.customerID];
                // Defect 1073
//            return [self printInvLineDescrip:[NSString stringWithFormat:@" Summary - %d items, Weight: %@",
//                                              [del.surveyDB getPVOItemCountMpro:del.customerID],
//                                              [SurveyAppDelegate formatDouble:inventory.mproWeight withPrecision:0]]
//                                  withItemNo:@"" withFont:UG_PVO_FONT];
            
            return [self printInvLineDescrip:[NSString stringWithFormat:@" Summary - %d items %@", [del.surveyDB getPVOItemCountMpro:del.customerID], isOrigin ? [NSString stringWithFormat:@", Weight: %@", [SurveyAppDelegate formatDouble:inventory.mproWeight withPrecision:0]] : @""]
                                  withItemNo:@"" withFont:PVO_REPORT_FONT];
    }
    @finally {
        //if (inventory != nil) [inventory release];
    }
}

-(int)invItemsStartSpro
{
    return [self printInvLineDescrip:@"** Spouse Professional Gear (SPRO)" withItemNo:@"" withFont:PVO_REPORT_FONT];
}

-(int)invItemsEndSpro
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = nil;
    @try {
            inventory = [del.surveyDB getPVOData:del.customerID];
                // Defect 1073
//            return [self printInvLineDescrip:[NSString stringWithFormat:@" Summary - %d items, Weight: %@",
//                                              [del.surveyDB getPVOItemCountSpro:del.customerID],
//                                              [SurveyAppDelegate formatDouble:inventory.sproWeight withPrecision:0]]
//                                  withItemNo:@"" withFont:UG_PVO_FONT];
            
            return [self printInvLineDescrip:[NSString stringWithFormat:@" Summary - %d items %@", [del.surveyDB getPVOItemCountSpro:del.customerID], isOrigin ? [NSString stringWithFormat:@", Weight: %@", [SurveyAppDelegate formatDouble:inventory.sproWeight withPrecision:0]] : @""]
                                  withItemNo:@"" withFont:PVO_REPORT_FONT];
    }
    @finally {
        //if (inventory != nil) [inventory release];
    }
}

-(int)invItemsStartHighValue
{
    return [self printInvLineDescrip:[NSString stringWithFormat:@"--- %@ INVENTORY ---", [[AppFunctionality getHighValueDescription] uppercaseString]] withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
}

-(int)invItemsEndHighValue
{
    return [self printInvLineDescrip:[NSString stringWithFormat:@"--- END %@ INVENTORY ---", [[AppFunctionality getHighValueDescription]uppercaseString]] withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
}

-(int)invItemsStartPacker
{
    return [self printInvLineDescrip:@"--- PACKER'S INVENTORY ---" withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
}

-(int)invItemsPackerInitialCounts
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *packerInitialCounts = [del.surveyDB getPackersInventoryInitialCounts:custID]; //key = NSString, value = NSNumber
    
    int drawn = 0;
    if (packerInitialCounts != nil && [packerInitialCounts count] > 0)
    {
        NSString *descrip = @"";
        for (NSString *key in [packerInitialCounts keyEnumerator])
        {
            if (key != nil && ![key isEqualToString:@""])
            {
                NSNumber *count = [packerInitialCounts valueForKey:key];
                if ([descrip length] > 0) descrip = [descrip stringByAppendingString:@", "];
                descrip = [descrip stringByAppendingFormat:@"%@-%d", key, [count intValue]];
            }
        }
        if ([descrip length] > 0)
            drawn = [self printInvLineDescrip:[NSString stringWithFormat:@"Packer Item Count: %@", descrip] withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
    }
    
    return drawn;
}

-(int)invItemsEndPacker
{
    return [self printInvLineDescrip:@"--- END PACKER'S INVENTORY ---" withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
}

-(int)printInvLineDescrip:(NSString*)descrip withItemNo:(NSString*)itemNo withFont:(UIFont*)font
{
    int cellItemNoHeight = 0, cellDescriptionHeight = 0;
    
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cellWHS1 = [[PrintCell alloc] initWithRes:resolution];
    cellWHS1.cellName = @"WHS1";
    cellWHS1.cellType = CELL_LABEL;
    cellWHS1.width = width * .018;
    cellWHS1.font = font;
    cellWHS1.textPosition = NSTextAlignmentCenter;
    cellWHS1.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cellWHS1];
    
    PrintCell *cellDVR = [[PrintCell alloc] initWithRes:resolution];
    cellDVR.cellName = @"DVR";
    cellDVR.cellType = CELL_LABEL;
    cellDVR.width = width * .018;
    cellDVR.font = font;
    cellDVR.textPosition = NSTextAlignmentCenter;
    cellDVR.borderType = BORDER_RIGHT;
    [section addCell:cellDVR];
    
    PrintCell *cellWHS2 = [[PrintCell alloc] initWithRes:resolution];
    cellWHS2.cellName = @"WHS2";
    cellWHS2.cellType = CELL_LABEL;
    cellWHS2.width = width * .018;
    cellWHS2.font = font;
    cellWHS2.textPosition = NSTextAlignmentCenter;
    cellWHS2.borderType = BORDER_RIGHT;
    [section addCell:cellWHS2];
    
    PrintCell *cellSPR = [[PrintCell alloc] initWithRes:resolution];
    cellSPR.cellName = @"SPR";
    cellSPR.cellType = CELL_LABEL;
    cellSPR.width = width * .018;
    cellSPR.font = font;
    cellSPR.textPosition = NSTextAlignmentCenter;
    cellSPR.borderType = BORDER_RIGHT;
    [section addCell:cellSPR];
    
    PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
    cellItemNo.cellName = @"ItemNo";
    cellItemNo.cellType = CELL_LABEL;
    cellItemNo.width = width * .04;
    cellItemNo.font = font;
    cellItemNo.textPosition = NSTextAlignmentCenter;
    cellItemNo.borderType = BORDER_RIGHT;
    cellItemNo.wordWrap = TRUE;
    [section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
    cellDescription.cellName = @"Description";
    cellDescription.cellType = CELL_LABEL;
    cellDescription.width = width * .288;
    cellDescription.font = font;
    cellDescription.borderType = BORDER_RIGHT;
    cellDescription.wordWrap = TRUE;
    [section addCell:cellDescription];
    
    PrintCell *cellCPSWPBO = [[PrintCell alloc] initWithRes:resolution];
    cellCPSWPBO.cellName = @"CPSWPBO";
    cellCPSWPBO.cellType = CELL_LABEL;
    cellCPSWPBO.width = width * .07;
    cellCPSWPBO.font = font;
    cellCPSWPBO.textPosition = NSTextAlignmentCenter;
    cellCPSWPBO.borderType = BORDER_RIGHT;
    cellCPSWPBO.wordWrap = TRUE;
    [section addCell:cellCPSWPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
    cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
    cellConditionsAtOrg.cellType = CELL_LABEL;
    cellConditionsAtOrg.width = width * .28;
    cellConditionsAtOrg.font = font;
    cellConditionsAtOrg.borderType = BORDER_RIGHT;
    cellConditionsAtOrg.wordWrap = TRUE;
    [section addCell:cellConditionsAtOrg];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", itemNo]]] withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:(itemNo == nil ? @" " : itemNo)];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", descrip]]] withColName:@"Description"];
    cellDescriptionHeight = [cellDescription heightWithText:(descrip == nil ? @" " : descrip)];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CPSWPBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtOrg"];
    
    // set height overrides for highest cell
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:cellItemNoHeight],
                                              [NSNumber numberWithInt:cellDescriptionHeight],
                                              nil]];
    
    //override all cell heights with highest
    cellWHS1.overrideHeight = true;
    cellWHS1.cellHeight = highHeight;
    cellDVR.overrideHeight = true;
    cellDVR.cellHeight = highHeight;
    cellWHS2.overrideHeight = true;
    cellWHS2.cellHeight = highHeight;
    cellSPR.overrideHeight = true;
    cellSPR.cellHeight = highHeight;
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCPSWPBO.overrideHeight = true;
    cellCPSWPBO.cellHeight = highHeight;
    cellConditionsAtOrg.overrideHeight = true;
    cellConditionsAtOrg.cellHeight = highHeight;
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    int drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    
    return drawn;
}

-(int)invItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *pvoDamages = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
    NSDictionary *pvoDamageLocs = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
    
    int cellItemNoHeight = 0, cellDescriptionHeight = 0, cellCPSWPBOHeight = 0,
    cellConditionsAtOrgHeight = 0, cellConditionsAtDestHeight = 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cellWHS1 = [[PrintCell alloc] initWithRes:resolution];
    cellWHS1.cellName = @"WHS1";
    cellWHS1.cellType = CELL_LABEL;
    cellWHS1.width = width * .018;
    cellWHS1.font = PVO_REPORT_FONT;
    cellWHS1.textPosition = NSTextAlignmentCenter;
    cellWHS1.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cellWHS1];
    
    PrintCell *cellDVR = [[PrintCell alloc] initWithRes:resolution];
    cellDVR.cellName = @"DVR";
    cellDVR.cellType = CELL_LABEL;
    cellDVR.width = width * .018;
    cellDVR.font = PVO_REPORT_FONT;
    cellDVR.textPosition = NSTextAlignmentCenter;
    cellDVR.borderType = BORDER_RIGHT;
    [section addCell:cellDVR];
    
    PrintCell *cellWHS2 = [[PrintCell alloc] initWithRes:resolution];
    cellWHS2.cellName = @"WHS2";
    cellWHS2.cellType = CELL_LABEL;
    cellWHS2.width = width * .018;
    cellWHS2.font = PVO_REPORT_FONT;
    cellWHS2.textPosition = NSTextAlignmentCenter;
    cellWHS2.borderType = BORDER_RIGHT;
    [section addCell:cellWHS2];
    
    PrintCell *cellSPR = [[PrintCell alloc] initWithRes:resolution];
    cellSPR.cellName = @"SPR";
    cellSPR.cellType = CELL_LABEL;
    cellSPR.width = width * .018;
    cellSPR.font = PVO_REPORT_FONT;
    cellSPR.textPosition = NSTextAlignmentCenter;
    cellSPR.borderType = BORDER_RIGHT;
    [section addCell:cellSPR];
    
    PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
    cellItemNo.cellName = @"ItemNo";
    cellItemNo.cellType = CELL_LABEL;
    cellItemNo.width = width * .04;
    if (!(printingMissingItems || processingMproSproItems || processingHighValueItems) && !isOrigin && !myItem.itemIsDelivered)
        cellItemNo.font = PVO_REPORT_BOLD_FONT;
    else
        cellItemNo.font = PVO_REPORT_FONT;
    cellItemNo.textPosition = NSTextAlignmentCenter;
    cellItemNo.borderType = BORDER_RIGHT;
    cellItemNo.wordWrap = TRUE;
    [section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
    cellDescription.cellName = @"Description";
    cellDescription.cellType = CELL_LABEL;
    cellDescription.width = width * .288;
    if (!(printingMissingItems || processingMproSproItems || processingHighValueItems) && !isOrigin && !myItem.itemIsDelivered)
        cellDescription.font = PVO_REPORT_BOLD_FONT;
    else
        cellDescription.font = PVO_REPORT_FONT;
    cellDescription.borderType = BORDER_RIGHT;
    cellDescription.wordWrap = TRUE;
    [section addCell:cellDescription];
    
    PrintCell *cellCPSWPBO = [[PrintCell alloc] initWithRes:resolution];
    cellCPSWPBO.cellName = @"CPSWPBO";
    cellCPSWPBO.cellType = CELL_LABEL;
    cellCPSWPBO.width = width * .07;
    cellCPSWPBO.font = PVO_REPORT_FONT;
    cellCPSWPBO.textPosition = NSTextAlignmentCenter;
    cellCPSWPBO.borderType = BORDER_RIGHT;
    cellCPSWPBO.wordWrap = TRUE;
    [section addCell:cellCPSWPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
    cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
    cellConditionsAtOrg.cellType = CELL_LABEL;
    cellConditionsAtOrg.width = width * .28;
    cellConditionsAtOrg.font = PVO_REPORT_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT;
    cellConditionsAtOrg.wordWrap = TRUE;
    [section addCell:cellConditionsAtOrg];
    
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
    cellConditionsAtDest.cellName = @"ConditionsAtDest";
    cellConditionsAtDest.cellType = CELL_LABEL;
    cellConditionsAtDest.width = width * .25;
    cellConditionsAtDest.font = PVO_REPORT_FONT;
    cellConditionsAtDest.borderType = BORDER_NONE;
    cellConditionsAtDest.wordWrap = TRUE;
    [section addCell:cellConditionsAtDest];
    
    
    //add values
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && whsCheck ? @"X" : @" ")]] withColName:@"WHS1"];
    
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && dvrCheck ? @"X" : @" ")]] withColName:@"DVR"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && sprCheck ? @"X" : @" ")]] withColName:@"SPR"];
    
    if (!printingMissingItems && myItem != nil && myItem.itemIsDelivered)
        countDelivered++;
    
    //item number
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@", myItem.fullItemNumber]]]
                 withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:myItem.fullItemNumber];
    
    Item *item = nil;
    if (myItem.cartonContentID > 0)
    {
        // carton content item
        PVOCartonContent *content = [del.surveyDB getPVOCartonContent:myItem.itemID withCustomerID:del.customerID];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", content.description]]] withColName:@"Description"];
        cellDescriptionHeight = [cellDescription heightWithText:[NSString stringWithFormat:@"    %@", content.description]];
        
    }
    else
    {
        //room - item descrip
        item = [del.surveyDB getItem:myItem.itemID WithCustomer:del.customerID];
        Room *room = [del.surveyDB getRoom:myItem.roomID WithCustomerID:del.customerID];
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@ - %@", room.roomName, item.name]]]
                     withColName:@"Description"];
        cellDescriptionHeight = [cellDescription heightWithText:[NSString stringWithFormat:@"%@ - %@", room.roomName, item.name]];
    }
    
    //symbols
    BOOL shownCP = FALSE, shownPBO = FALSE;
    NSString *cpswpbo = @"";
    
    NSArray *symbols = [del.surveyDB getPVOItemDescriptions:myItem.pvoItemID withCustomerID:del.customerID];
    for (PVOItemDescription *symbol in symbols)
    {
        if ([symbol.descriptionCode length] > 0)
        {
            if (!shownCP) shownCP = [symbol.descriptionCode isEqualToString:@"CP"];
            if (!shownPBO) shownPBO = [symbol.descriptionCode isEqualToString:@"PBO"];
            
            if ([cpswpbo length] > 0)
                cpswpbo = [cpswpbo stringByAppendingString:@", "];
            cpswpbo = [cpswpbo stringByAppendingString:symbol.descriptionCode];
        }
    }
    
    
    if (item != nil && item.isCP && !shownCP)
    {
        if ([cpswpbo length] > 0)
            cpswpbo = [cpswpbo stringByAppendingString:@", "];
        cpswpbo = [cpswpbo stringByAppendingString:@"CP"];
    }
    
    if (item != nil && item.isPBO && !shownPBO)
    {
        if ([cpswpbo length] > 0)
            cpswpbo = [cpswpbo stringByAppendingString:@", "];
        cpswpbo = [cpswpbo stringByAppendingString:@"PBO"];
    }
    
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:([cpswpbo length] > 0 ? cpswpbo : @" ")]]
                 withColName:@"CPSWPBO"];
    cellCPSWPBOHeight = [cellCPSWPBO heightWithText:cpswpbo];
    
    //conditions at origin
    NSString *conditions = @"";
    NSArray *itemDamages;
    
    if ((myItem.cartonContentID > 0 || myItem.itemIsMPRO || myItem.itemIsSPRO) && myItem.highValueCost > 0)
        conditions = [[AppFunctionality getHighValueDescription] uppercaseString];
    
    if(myItem.quantity > 1)
    {
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingFormat:@"; Qty: %d", myItem.quantity];
        else
            conditions = [NSString stringWithFormat:@"Qty: %d", myItem.quantity];
    }
    
    if(myItem.packerInitials != nil && myItem.packerInitials.length > 0)
    {
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingFormat:@"; Packer: %@", myItem.packerInitials];
        else
            conditions = [NSString stringWithFormat:@"Packer: %@", myItem.packerInitials];
    }
    
    if (myItem.hasDimensions)
    {
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingString:@"; Length: "];
        else
            conditions = [NSString stringWithFormat:@"Length: "];
        conditions = [conditions stringByAppendingFormat:@"%d, Width: %d, Height: %d", myItem.length, myItem.width, myItem.height];
    }
    
    /*if(!myItem.itemIsDeleted)
     {*/
    itemDamages = [del.surveyDB getPVOItemDamage:myItem.pvoItemID forDamageType:(int)DAMAGE_LOADING];
    for (PVOConditionEntry *damage in itemDamages)
    {
        if (!damage.isEmpty)
        {
            NSString *loc = @"";
            for (NSString *damageLoc in [damage locationArray])
            {
                if ([loc length] > 0)
                    loc = [loc stringByAppendingString:@"-"];
                
                if (!printDamageCodeOnly)
                {
                    loc = [loc stringByAppendingString:
                           [NSString stringWithFormat:@"%@", [PVOConditionEntry pluralizeLocation:pvoDamageLocs withKey:damageLoc]]];
                }
                else
                {
                    loc = [loc stringByAppendingString:
                           [NSString stringWithFormat:@"%@", damageLoc]];
                }
            }
            
            NSString *cond = @"";
            for (NSString *damageCond in [damage conditionArray])
            {
                if ([cond length] > 0)
                    cond = [cond stringByAppendingString:@"-"];
                
                if (!printDamageCodeOnly)
                {
                    cond = [cond stringByAppendingString:
                            [NSString stringWithFormat:@"%@", [pvoDamages objectForKey:damageCond]]];
                }
                else
                {
                    cond = [cond stringByAppendingString:
                            [NSString stringWithFormat:@"%@", damageCond]];
                }
            }
            
            if ([conditions length] > 0)
                conditions = [conditions stringByAppendingString:@", "];
            if ([loc length] > 0)
            {
                conditions = [conditions stringByAppendingString:loc];
                if ([cond length] > 0)
                    conditions = [conditions stringByAppendingString:@" "];
            }
            if ([cond length] > 0)
                conditions = [conditions stringByAppendingString:cond];
        }
    }
    
    
    if (myItem.cartonContents && myItem.cartonContentID <= 0)
    {
        NSArray *cartonContents = [del.surveyDB getPVOCartonContents:myItem.pvoItemID withCustomerID:del.customerID];
        NSString *ct = @"";
        for (PVOCartonContent *contentID in cartonContents)
        {
            if ([del.surveyDB pvoCartonContentItemIsExpanded:contentID.cartonContentID])
                continue; //skip it, has it's own line
            PVOCartonContent *content = [del.surveyDB getPVOCartonContent:contentID.contentID withCustomerID:del.customerID];
            if ([ct length] > 0)
                ct = [ct stringByAppendingString:@", "];
            ct = [ct stringByAppendingString:[NSString stringWithFormat:@"%@", content.description == nil ? @"" : content.description]];
            
        }
        
        
        if ([ct length] > 0)
        {
            if ([conditions length] > 0)
                conditions = [conditions stringByAppendingString:@"; Contents: "];
            else
                conditions = @"Contents: ";
            
            conditions = [conditions stringByAppendingString:ct];
        }
    }
    
    /*if (myItem.highValueCost > 0)
     {
     if ([conditions length] > 0)
     conditions = [conditions stringByAppendingString:@"; HIGH VALUE"];
     else
     conditions = @"HIGH VALUE";
     }*/
    
    
    NSMutableArray *noteItems = [[NSMutableArray alloc] init];
    
    PVOItemComment *originComment = [del.surveyDB getPVOItemComment:myItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
    if (originComment.comment != nil && [originComment.comment length] > 0)
        [noteItems addObject:originComment.comment];
    if (myItem.year > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Year: %@", [SurveyAppDelegate formatDouble:myItem.year withPrecision:0]]];
    if (myItem.make != nil && [myItem.make length] > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Make: %@", myItem.make]];
    if (myItem.modelNumber != nil && [myItem.modelNumber length] > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Model: %@", myItem.modelNumber]];
    if (myItem.serialNumber != nil && [myItem.serialNumber length] > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Serial #: %@", myItem.serialNumber]];
    if (myItem.odometer > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Odometer: %@", [SurveyAppDelegate formatDouble:myItem.odometer withPrecision:0]]];
    if (myItem.caliberGauge != nil && [myItem.caliberGauge length] > 0)
        [noteItems addObject:[NSString stringWithFormat:@"Caliber/Gauge: %@", myItem.caliberGauge]];
    if ([noteItems count] > 0)
    {
        BOOL first = YES;
        for (NSString *note in [noteItems objectEnumerator])
        {
            if (note != nil && [note length] > 0)
            {
                if (first)
                {
                    if ([conditions length] > 0) conditions = [conditions stringByAppendingString:@"; "];
                    conditions = [conditions stringByAppendingString:@"Notes - "];
                    first = NO;
                }
                else
                    conditions = [conditions stringByAppendingString:@" "];
                conditions = [conditions stringByAppendingFormat:@"%@.", note];
            }
        }
    }
    
    if ([conditions length] == 0)
        conditions = @"<>";
    
    /*}
     else
     {*/
    if(myItem.itemIsDeleted && myItem.voidReason != nil && [myItem.voidReason length] > 0)
    {
        conditions = [NSString stringWithFormat:@"Voided Item Reason: %@%@%@",
                      myItem.voidReason,
                      (conditions != nil && conditions.length > 0 ? @"; " : @""),
                      (conditions == nil ? @"" : conditions)];
    }
    //}
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:conditions]] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:conditions];
    
    // conditions at destination
    conditions = @"";
    
    if (!isOrigin /*&& !myItem.itemIsDeleted*/)
    {
        itemDamages = [del.surveyDB getPVOItemDamage:myItem.pvoItemID forDamageType:(int)DAMAGE_UNLOADING];
        for (PVOConditionEntry *damage in itemDamages)
        {
            if (!damage.isEmpty && myItem.cartonContentID <= 0) //only show if not a carton content item
            {
                NSString *loc = @"";
                for (NSString *damageLoc in [damage locationArray])
                {
                    if ([loc length] > 0)
                        loc = [loc stringByAppendingString:@"-"];
                    
                    if (!printDamageCodeOnly)
                    {
                        loc = [loc stringByAppendingString:
                               [NSString stringWithFormat:@"%@", [PVOConditionEntry pluralizeLocation:pvoDamageLocs withKey:damageLoc]]];
                    }
                    else
                    {
                        loc = [loc stringByAppendingString:
                               [NSString stringWithFormat:@"%@", damageLoc]];
                    }
                }
                
                NSString *cond = @"";
                for (NSString *damageCond in [damage conditionArray])
                {
                    if ([cond length] > 0)
                        cond = [cond stringByAppendingString:@"-"];
                    
                    if (!printDamageCodeOnly)
                    {
                        cond = [cond stringByAppendingString:
                                [NSString stringWithFormat:@"%@", [pvoDamages objectForKey:damageCond]]];
                    }
                    else
                    {
                        cond = [cond stringByAppendingString:
                                [NSString stringWithFormat:@"%@", damageCond]];
                    }
                }
                
                if ([conditions length] > 0)
                    conditions = [conditions stringByAppendingString:@", "];
                if ([loc length] > 0)
                {
                    conditions = [conditions stringByAppendingString:loc];
                    if ([cond length] > 0)
                        conditions = [conditions stringByAppendingString:@" "];
                }
                if ([cond length] > 0)
                    conditions = [conditions stringByAppendingString:cond];
            }
        }
        
        
        if (!myItem.itemIsDeleted && !(printingMissingItems || processingMproSproItems || processingHighValueItems) && !myItem.itemIsDelivered)
        {
            if ([conditions length] > 0)
                conditions = [conditions stringByAppendingString:@"; "];
            conditions = [conditions stringByAppendingString:@"MISSING"];
        }
    }
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:conditions]] withColName:@"ConditionsAtDest"];
    cellConditionsAtDestHeight = [cellConditionsAtDest heightWithText:conditions];
    
    
    // set height overrides for highest cell
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:cellItemNoHeight],
                                              [NSNumber numberWithInt:cellDescriptionHeight],
                                              [NSNumber numberWithInt:cellCPSWPBOHeight],
                                              [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                              [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                              nil]];
    
    //override all cell heights with highest
    cellWHS1.overrideHeight = true;
    cellWHS1.cellHeight = highHeight;
    cellDVR.overrideHeight = true;
    cellDVR.cellHeight = highHeight;
    cellWHS2.overrideHeight = true;
    cellWHS2.cellHeight = highHeight;
    cellSPR.overrideHeight = true;
    cellSPR.cellHeight = highHeight;
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCPSWPBO.overrideHeight = true;
    cellCPSWPBO.cellHeight = highHeight;
    cellConditionsAtOrg.overrideHeight = true;
    cellConditionsAtOrg.cellHeight = highHeight;
    cellConditionsAtDest.overrideHeight = true;
    cellConditionsAtDest.cellHeight = highHeight;
    
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    int drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    
    leftCurrentPageY = currentPageY;
    currentPageY += drawn;

    
    return drawn;
}

-(int)invItemStrikethrough
{
    int drawn = 0;
    // cross out deleted item
    if (myItem.itemIsDeleted)
    {
        PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
        
        //set up cells
        PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"WHS1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .018;
        cell.font = PVO_REPORT_FONT_HALF;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .019)];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"ItemNo";
        cell.cellType = CELL_LABEL;
        cell.width = width * .038;
        cell.font = PVO_REPORT_FONT_HALF;
        cell.textPosition = NSTextAlignmentCenter;
        cell.borderType = BORDER_BOTTOM;
        cell.wordWrap = FALSE;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .001;
        cell.font = PVO_REPORT_FONT_HALF;
        cell.borderType = BORDER_NONE;
        cell.wordWrap = FALSE;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Description";
        cell.cellType = CELL_LABEL;
        cell.width = width * .286;
        cell.font = PVO_REPORT_FONT_HALF;
        cell.borderType = BORDER_BOTTOM;
        cell.wordWrap = TRUE;
        [section addCell:cell];
        
        
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"Description"];
        
        //place it
        CGPoint pos = params.contentRect.origin;
        pos.y = leftCurrentPageY;
        
        //print it, check to make sure it fit...
        //if not, store it in the collection of items to continue...
        [section drawSection:context
                withPosition:pos
              andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
        
        
    }
    
    return drawn;
}

-(int)finishPage
{
    return [self finishPage:NO];
}

-(int)finishPageWithSpaceForDeclineCheckoff
{
    return [self finishPage:YES];
}

-(int)finishPage:(BOOL)leaveSpaceForDeclineCheckoff
{
    int blankHeight = [self blankInvItemRow:FALSE], drawn = 0;
    int bottomPadding = (leaveSpaceForDeclineCheckoff ? [self declineCheckoff:NO finishAllOnNextPage:NO] : 0);
    while ((params.contentRect.size.height-takeOffBottom)-currentPageY > blankHeight + bottomPadding)
        drawn += [self blankInvItemRow:TRUE];
    if (leaveSpaceForDeclineCheckoff)
        return drawn;
    else if (cpSummaryTotal + pboSummaryTotal + crateSummaryTotal > 0) //assume we need to force new page for pack sum. page
        return FORCE_PAGE_BREAK;
    return drawn;
}

-(int)printDeliverySummary
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
    NSString *descrip = [NSString stringWithFormat:@"Summary: Inventory - %d Delivered, %d %@, %d Missing."
                         ,[del.surveyDB getPvoDeliveredItemsCount:del.customerID]
                         ,[del.surveyDB getPvoHighValueItemsCount:del.customerID]
                         ,[[AppFunctionality getHighValueDescription] uppercaseString]
                         ,[del.surveyDB getPvoNotDeliveredItemsCount:del.customerID]];
    return [self printInvLineDescrip:descrip withItemNo:@"XXX" withFont:PVO_REPORT_FONT];
}

-(int)blankInvItemRow
{
    return [self blankInvItemRow:TRUE];
}

-(int)blankInvItemRow:(BOOL)print
{
    int drawn = 0;
    //set up ADDRESSES section...
    PrintSection *section = [self getBlankInvItemRowSection];
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
    {
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
        currentPageY += drawn;
    }
    else
        drawn = [section height];
    
    
    
    return drawn;
}

-(PrintSection*)getBlankInvItemRowSection
{
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DVR";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"ItemNo" withType:CELL_LABEL withWidth:(width * .04)];
    [section duplicateLastCell:@"Description" withType:CELL_LABEL withWidth:(width * .288)];
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ConditionsAtDest";
    cell.cellType = CELL_LABEL;
    cell.width = width * .25;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    //add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"SPR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Description"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"CPSWPBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtOrg"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtDest"];
    
    return section;
}

-(int)invItemsEnd
{
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = PVO_REPORT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ItemNo";
    cell.cellType = CELL_LABEL;
    cell.width = width * .04;
    cell.font = PVO_REPORT_BOLD_FONT;
    cell.borderType = BORDER_RIGHT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Description";
    cell.cellType = CELL_LABEL;
    cell.width = width * .288;
    cell.font = PVO_REPORT_BOLD_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               (printingMissingItems ? (processingPackersInvItems ? @"--- END MISSING PACKER ITEMS ---" : @"--- END MISSING ITEMS ---") : @"--- END OF INVENTORY ---")]]
                 withColName:@"Description"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CPSWPBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtOrg"];
    //[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtDest"];
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    int drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    //    //removed per defect 453.  placed into own section at end.
    //    if(!isOrigin && !printingMissingItems)
    //    {
    //        //set up ADDRESSES section...
    //        section = [[PrintSection alloc] initWithRes:resolution];
    //
    //        //set up cells
    //        cell = [[PrintCell alloc] initWithRes:resolution];
    //        cell.cellName = @"WHS1";
    //        cell.cellType = CELL_LABEL;
    //        cell.width = width * .018;
    //        cell.font = PVO_REPORT_FONT;
    //        cell.textPosition = NSTextAlignmentCenter;
    //        cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    //        [section addCell:cell];
    //        
    //
    //        [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
    //        [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
    //        [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
    //
    //        cell = [[PrintCell alloc] initWithRes:resolution];
    //        cell.cellName = @"ItemNo";
    //        cell.cellType = CELL_LABEL;
    //        cell.width = width * .04;
    //        cell.font = PVO_REPORT_FONT;
    //        cell.borderType = BORDER_RIGHT;
    //        cell.textPosition = NSTextAlignmentCenter;
    //        [section addCell:cell];
    //        
    //
    //        cell = [[PrintCell alloc] initWithRes:resolution];
    //        cell.cellName = @"Description";
    //        cell.cellType = CELL_LABEL;
    //        cell.width = width * .288;
    //        cell.font = PVO_REPORT_FONT;
    //        cell.borderType = BORDER_RIGHT;
    //        [section addCell:cell];
    //        
    //
    //        [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    //        [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    //        //[section duplicateLastCell:@"ConditionsAtDest" withType:CELL_LABEL withWidth:(width * .25)];
    //
    //        //add values
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:
    //                                  [CellValue cellWithLabel:
    //                                   [NSString stringWithFormat:@"Summary: Inventory - %@ delivered",
    //                                    [SurveyAppDelegate formatDouble:countDelivered withPrecision:0]]]]
    //                     withColName:@"Description"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CPSWPBO"];
    //        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtOrg"];
    //        //[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtDest"];
    //
    //        //place it
    //        pos = params.contentRect.origin;
    //        pos.y = currentPageY;
    //
    //        //print it, check to make sure it fit...
    //        //if not, store it in the collection of items to continue...
    //        drawn = [section drawSection:context
    //                        withPosition:pos
    //                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    //        if(drawn == DIDNT_FIT_ON_PAGE)
    //            [self finishSectionOnNextPage:section];
    //
    //        currentPageY += drawn;
    //
    //    }
    
    
    return drawn;
}


-(int)invPackSummaryTotalHeight
{
    return [self invPackSummaryStart:FALSE] + [self invPackSummaryHeader:FALSE] + [self invPackSummaryDetail:FALSE];
}

-(int)invPackSummaryStart { return [self invPackSummaryStart:TRUE]; }
-(int)invPackSummaryStart:(BOOL)print
{
    int drawn = 0;
    if (cpSummaryTotal + pboSummaryTotal + crateSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Title1";
    cell.cellType = CELL_LABEL;
    cell.width = (width / 3.);
    cell.font = PVO_REPORT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    
    if ((cpSummaryTotal > 0 && (pboSummaryTotal > 0 || crateSummaryTotal > 0)) || (pboSummaryTotal > 0 && crateSummaryTotal > 0))
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Title2";
        cell.cellType = CELL_LABEL;
        cell.width = (width / 3.);
        cell.font = PVO_REPORT_FONT;
        cell.textPosition = NSTextAlignmentCenter;
        cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        [section addCell:cell];
        
        
        if (cpSummaryTotal > 0 && pboSummaryTotal > 0 && crateSummaryTotal > 0)
        {
            
            cell = [[PrintCell alloc] initWithRes:resolution];
            cell.cellName = @"Title3";
            cell.cellType = CELL_LABEL;
            cell.width = (width / 3.);
            cell.font = PVO_REPORT_FONT;
            cell.textPosition = NSTextAlignmentCenter;
            cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
            [section addCell:cell];
            
        }
    }
    
    //add values
    NSString *colName = @"Title1";
    if (cpSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packing Summary - Carrier Packed"]]
                     withColName:colName];
        colName = @"Title2";
    }
    if (pboSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packing Summary - Packed By Owner"]]
                     withColName:colName];
        colName = [NSString stringWithFormat:@"Title%d", [[colName substringFromIndex:[colName length]-1] intValue]+1];
    }
    if (crateSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packing Summary - Crate(s)"]]
                     withColName:colName];
    }
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if(print)
    {
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
        currentPageY += drawn;
    }
    else drawn = [section height];
    
    
    
    return drawn;
}

-(int)invPackSummaryHeader { return [self invPackSummaryHeader:TRUE]; }
-(int)invPackSummaryHeader:(BOOL)print
{
    int drawn = 0;
    if (cpSummaryTotal + pboSummaryTotal + crateSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Carton1";
    cell.cellType = CELL_LABEL;
    cell.width = ((width / 3.) * .75) - (width * .006);
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    [section duplicateLastCell:@"Qty1" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    
    if ((cpSummaryTotal > 0 && (pboSummaryTotal > 0 || crateSummaryTotal > 0)) || (pboSummaryTotal > 0 && crateSummaryTotal > 0))
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .009;
        cell.font = PVO_REPORT_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Carton2";
        cell.cellType = CELL_LABEL;
        cell.width = ((width / 3.) * .75) - (width * .006);
        cell.font = PVO_REPORT_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        [section duplicateLastCell:@"Qty2" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
        
        if (cpSummaryTotal > 0 && pboSummaryTotal > 0 && crateSummaryTotal > 0)
        {
            cell = [[PrintCell alloc] initWithRes:resolution];
            cell.cellName = @"blank2";
            cell.cellType = CELL_LABEL;
            cell.width = width * .009;
            cell.font = PVO_REPORT_FONT;
            cell.borderType = BORDER_NONE;
            [section addCell:cell];
            
            
            cell = [[PrintCell alloc] initWithRes:resolution];
            cell.cellName = @"Carton3";
            cell.cellType = CELL_LABEL;
            cell.width = ((width / 3.) * .75) - (width * .006);
            cell.font = PVO_REPORT_FONT;
            cell.borderType = BORDER_NONE;
            [section addCell:cell];
            
            [section duplicateLastCell:@"Qty3" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
        }
    }
    
    //add values
    NSString *colNameCarton = @"Carton1", *colNameQty = @"Qty1";
    if (cpSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Carton"]]
                     withColName:colNameCarton];
        colNameCarton = @"Carton2";
        
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Qty"]]
                     withColName:colNameQty];
        colNameQty = @"Qty2";
    }
    if (pboSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Carton"]]
                     withColName:colNameCarton];
        colNameCarton = [NSString stringWithFormat:@"Carton%d", [[colNameCarton substringFromIndex:[colNameCarton length]-1] intValue]+1];
        
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Qty"]]
                     withColName:colNameQty];
        colNameQty = [NSString stringWithFormat:@"Qty%d", [[colNameQty substringFromIndex:[colNameQty length]-1] intValue]+1];
    }
    if (crateSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Crate"]]
                     withColName:colNameCarton];
        
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Qty"]]
                     withColName:colNameQty];
    }
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if(print)
    {
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
        currentPageY += drawn;
    }
    else drawn = [section height];
    
    
    
    return drawn;
}

-(int)invPackSummaryDetail { return [self invPackSummaryDetail:TRUE]; }
-(int)invPackSummaryDetail:(BOOL)print
{
    int drawn = 0;
    if (cpSummaryTotal + pboSummaryTotal + crateSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Carton1";
    cell.cellType = CELL_LABEL;
    cell.width = ((width / 3.) * .75) - (width * .006);
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_TOP;
    [section addCell:cell];
    
    [section duplicateLastCell:@"Qty1" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    
    if ((cpSummaryTotal > 0 && (pboSummaryTotal > 0 || crateSummaryTotal > 0)) || (pboSummaryTotal > 0 && crateSummaryTotal > 0))
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .009;
        cell.font = PVO_REPORT_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Carton2";
        cell.cellType = CELL_LABEL;
        cell.width = ((width / 3.) * .75) - (width * .006);
        cell.font = PVO_REPORT_FONT;
        cell.borderType = BORDER_TOP;
        [section addCell:cell];
        
        [section duplicateLastCell:@"Qty2" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
        
        if (cpSummaryTotal > 0 && pboSummaryTotal > 0 && crateSummaryTotal > 0)
        {
            cell = [[PrintCell alloc] initWithRes:resolution];
            cell.cellName = @"blank2";
            cell.cellType = CELL_LABEL;
            cell.width = width * .009;
            cell.font = PVO_REPORT_FONT;
            cell.borderType = BORDER_NONE;
            [section addCell:cell];
            
            
            cell = [[PrintCell alloc] initWithRes:resolution];
            cell.cellName = @"Carton3";
            cell.cellType = CELL_LABEL;
            cell.width = ((width / 3.) * .75) - (width * .006);
            cell.font = PVO_REPORT_FONT;
            cell.borderType = BORDER_TOP;
            [section addCell:cell];
            
            [section duplicateLastCell:@"Qty3" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
        }
    }
    
    //add values
    NSString *colNameCarton = @"Carton1", *colNameQty = @"Qty1";
    
    NSMutableArray *colValsName = nil, *colValsQty = nil;
    NSArray *sortedKeys = nil;
    if (cpSummaryTotal > 0)
    {
        sortedKeys = [[cpSummary allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        colValsName = [[NSMutableArray alloc] init];
        colValsQty = [[NSMutableArray alloc] init];
        for (int i=0; i < [sortedKeys count]; i++)
        {
            [colValsName addObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", [sortedKeys objectAtIndex:i]]]];
            [colValsQty addObject:
             [CellValue cellWithLabel:
              [SurveyAppDelegate formatDouble:[[cpSummary objectForKey:[sortedKeys objectAtIndex:i]] intValue] withPrecision:0]]];
        }
        [colValsName addObject:[CellValue cellWithLabel:@"Total:"]];
        [colValsQty addObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDouble:cpSummaryTotal withPrecision:0]]];
        
        [section addColumnValues:colValsName withColName:colNameCarton];
        [section addColumnValues:colValsQty withColName:colNameQty];
        
        colNameCarton = @"Carton2";
        colNameQty = @"Qty2";
    }
    
    if (pboSummaryTotal > 0)
    {
        sortedKeys = [[pboSummary allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        colValsName = [[NSMutableArray alloc] init];
        colValsQty = [[NSMutableArray alloc] init];
        for (int i=0; i < [sortedKeys count]; i++)
        {
            [colValsName addObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", [sortedKeys objectAtIndex:i]]]];
            [colValsQty addObject:
             [CellValue cellWithLabel:
              [SurveyAppDelegate formatDouble:[[pboSummary objectForKey:[sortedKeys objectAtIndex:i]] intValue] withPrecision:0]]];
        }
        [colValsName addObject:[CellValue cellWithLabel:@"Total:"]];
        [colValsQty addObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDouble:pboSummaryTotal withPrecision:0]]];
        
        [section addColumnValues:colValsName withColName:colNameCarton];
        
        [section addColumnValues:colValsQty withColName:colNameQty];
        
        
        colNameCarton = [NSString stringWithFormat:@"Carton%d", [[colNameCarton substringFromIndex:[colNameCarton length]-1] intValue]+1];
        colNameQty = [NSString stringWithFormat:@"Qty%d", [[colNameQty substringFromIndex:[colNameQty length]-1] intValue]+1];
    }
    
    if (crateSummaryTotal > 0)
    {
        sortedKeys = [[crateSummary allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        colValsName = [[NSMutableArray alloc] init];
        colValsQty = [[NSMutableArray alloc] init];
        for (int i=0; i < [sortedKeys count]; i++)
        {
            [colValsName addObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", [sortedKeys objectAtIndex:i]]]];
            [colValsQty addObject:
             [CellValue cellWithLabel:
              [SurveyAppDelegate formatDouble:[[crateSummary objectForKey:[sortedKeys objectAtIndex:i]] intValue] withPrecision:0]]];
        }
        [colValsName addObject:[CellValue cellWithLabel:@"Total:"]];
        [colValsQty addObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDouble:crateSummaryTotal withPrecision:0]]];
        
        [section addColumnValues:colValsName withColName:colNameCarton];
        
        [section addColumnValues:colValsQty withColName:colNameQty];
        
    }
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if(print)
    {
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
        currentPageY += drawn;
    }
    else drawn = [section height];
    
    
    
    return drawn;
}

-(int)printDeclineCheckoff
{
    return [self declineCheckoff:YES finishAllOnNextPage:NO];
}

-(int)printDeclineCheckoffOnNextPage
{
    return [self declineCheckoff:NO finishAllOnNextPage:YES];
}

-(int)declineCheckoff:(BOOL)print finishAllOnNextPage:(BOOL)finishOnNextPage
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *declineSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL];
    int drawn = 0;
    
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_TOP;
    
    //set up Header cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DeclineHeader";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = PVO_REPORT_BOLD_FONT;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"DECLINE CHECKOFF WAIVER"]] withColName:@"DeclineHeader"];
    
    //place it (put footer at the bottom)
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print || finishOnNextPage)
        drawn += [section height];
    else
    {
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        currentPageY += drawn;
    }
    if (finishOnNextPage)
        [self finishSectionOnNextPage:section];
    
    
    
    
    //draw sig
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM;
    section.forcePageBreakAfterSection = finishOnNextPage;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DeclineSig";
    cell.cellType = CELL_LABEL;
    cell.width = width * .4;
    cell.font = PVO_REPORT_FONT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DeclineDate";
    cell.cellType = CELL_LABEL;
    cell.width = width * .6;
    cell.font = PVO_REPORT_FONT;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObjects:[CellValue cellWithLabel:@"I waived the right to check off items during the delivery process."],
                              [CellValue cellWithLabel:@" \r\n \r\nCustomer Signature"],nil]
                 withColName:@"DeclineSig"];
    
    [section addColumnValues:[NSMutableArray arrayWithObjects:[CellValue cellWithLabel:@" "],
                              [CellValue cellWithLabel:[NSString stringWithFormat:@" \r\n \r\nDate        %@", [SurveyAppDelegate formatDate:[NSDate date]]]], nil]
                 withColName:@"DeclineDate"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print || finishOnNextPage)
        drawn += [section height];
    else
    {
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        currentPageY += drawn;
    }
    if (finishOnNextPage)
        [self finishSectionOnNextPage:section];
    
    
    
    
    if ((print || finishOnNextPage) && declineSig != nil)
    {
        UIImage *declineImg = [declineSig signatureData];
        CGSize tmpSize = [declineImg size];
        declineImg = [SurveyAppDelegate scaleAndRotateImage:declineImg withOrientation:UIImageOrientationDownMirrored];
        if(finishOnNextPage)
        {
            [self finishImageOnNextPage:declineImg
                              withRefPoint:CGPointMake((width * 0.15), (0 - (tmpSize.height * 0.14) - TO_PRINTER(10.)))
                               withSize:CGSizeMake(tmpSize.width * 0.14, tmpSize.height * 0.14)];
        }
        else
        {
            CGRect sigRect = CGRectMake(params.contentRect.origin.x + (width * 0.15),
                                        currentPageY - (tmpSize.height * 0.14) - TO_PRINTER(10.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
            [self drawImage:declineImg withCGRect:sigRect];
        }
    }

    return drawn;
}

-(int)invFooter:(BOOL)print
{
    return [self invFooter:print withCustSignatures:TRUE];
}

-(int)invFooterNoCustSignature:(BOOL)print
{
    return [self invFooter:print withCustSignatures:FALSE];
}

-(int)invFooter:(BOOL)print withCustSignatures:(BOOL)showCustSignatures
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    PVOSignature *driverSig = [del.surveyDB getPVOSignature:-1
                                               forImageType:(driver.driverType == PVO_DRIVER_TYPE_PACKER ? PVO_SIGNATURE_TYPE_PACKER : PVO_SIGNATURE_TYPE_DRIVER)];
    PVOSignature *orgCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
    PVOSignature *destCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *custName = [NSString stringWithFormat:@"%@%@%@",
                          cust.firstName != nil ? cust.firstName : @"",
                          cust.firstName != nil && cust.lastName != nil ? @" " : @"",
                          cust.lastName != nil ? cust.lastName : @""];
    
    BOOL driverSigApplied = FALSE;
    BOOL orgCustSigApplied = FALSE;
    BOOL destCustSigApplied = FALSE;
    if (orgCustSig != nil && showCustSignatures)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[orgCustSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            orgCustSigApplied = TRUE;
    }
    if (destCustSig != nil && showCustSignatures)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[destCustSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            destCustSigApplied = TRUE;
    }
    if (driverSig != nil) // && driver.driverType != PVO_DRIVER_TYPE_PACKER)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[driverSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            driverSigApplied = TRUE;
    }
    
    int drawn = 0;
    
    
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_TOP;
    
    //set up Header cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"RemarksLabel";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.1;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Remarks";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.9;
    cell.font = PVO_REPORT_FONT;
    [section addCell:cell];
    
    
    // add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"REMARKS/\r\nCOMMENTS:"]] withColName:@"RemarksLabel"];
    
    NSString *notes = [del.surveyDB getCustomerNote:custID];
    if (notes != nil && [notes length] > 0)
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", notes]]] withColName:@"Remarks"];
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Remarks"];
    
    //place it (put footer at the bottom)
    CGPoint pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_TOP;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"TapeLotLabel";
    cell.cellType = CELL_LABEL;
    cell.width = width * .08;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    cell.wordWrap = NO;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"TapeLot" withType:CELL_LABEL withWidth:(width * .17)];
    [section duplicateLastCell:@"TapeColorLabel" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"TapeColor" withType:CELL_LABEL withWidth:(width * .18)];
    [section duplicateLastCell:@"NumFromLabel" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"NumFrom" withType:CELL_LABEL withWidth:(width * .18)];
    [section duplicateLastCell:@"NumToLabel" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"NumTo" withType:CELL_LABEL withWidth:(width * .18)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Tape Lot No."]] withColName:@"TapeLotLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Tape Color"]] withColName:@"TapeColorLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Nos. From"]] withColName:@"NumFromLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Through"]] withColName:@"NumToLabel"];
    
    // build ALL the arrays
    NSMutableArray *lotNums = [[NSMutableArray alloc] init];
    NSMutableArray *tapeColors = [[NSMutableArray alloc] init];
    NSMutableArray *numsFrom = [[NSMutableArray alloc] init];
    NSMutableArray *numsTo = [[NSMutableArray alloc] init];
    if (currentPageItems != nil && [currentPageItems count] > 0)
    {
        NSDictionary *colors = [del.surveyDB getPVOColors];
        [self sortPVOItemDetailArray:currentPageItems accountForInvAfterSig:YES];
        PVOItemDetail *lastItem = nil;
        for (int i=0;i<currentPageItems.count;i++)
        {
            PVOItemDetail *item = [currentPageItems objectAtIndex:i];
            if (item == nil || item.itemIsDeleted) continue;
            if (!(item.lotNumber == nil || [item.lotNumber isEqualToString:@""]) && [lotNums indexOfObject:item.lotNumber] == NSNotFound)
            {
                [numsFrom addObject:[item fullItemNumber]];
                if (lotNums.count > 0) //find num to
                {
                    for (int j=(i-1);j>0;j--)
                    {
                        PVOItemDetail *prevItem = [currentPageItems objectAtIndex:j];
                        if (prevItem == nil || prevItem.itemIsDeleted) continue;
                        [numsTo addObject:[prevItem fullItemNumber]];
                        break;
                    }
                }
                [lotNums addObject:item.lotNumber];
            }
            if ([tapeColors indexOfObject:[colors objectForKey:[NSNumber numberWithInt:item.tagColor]]] == NSNotFound)
                [tapeColors addObject:[colors objectForKey:[NSNumber numberWithInt:item.tagColor]]];
            lastItem = item;
        }
        if (lastItem != nil)
            [numsTo addObject:[lastItem fullItemNumber]];
    }
    
    
    NSString *temp = @"";
    int count = 0;
    for(NSString *lotNum in lotNums)
    {
        if (++count > 3) break; //only allow three to print
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:lotNum];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"TapeLot"];
    
    temp = @"";
    count = 0;
    for(NSString *tapeColor in tapeColors)
    {
        if (++count > 3) break; //only allow three to print (same as lot number)
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:tapeColor];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"TapeColor"];
    
    temp = @"";
    count = 0;
    for(NSString *numFrom in numsFrom)
    {
        if (++count > 6) break; //only allow 6 to print
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:numFrom];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"NumFrom"];
    
    temp = @"";
    count = 0;
    for(NSString *numTo in numsTo)
    {
        if (++count > 6) break; //only allow 6 to print
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:numTo];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"NumTo"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    drawn += TO_PRINTER(5.);
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Origin";
    cell.cellType = CELL_LABEL;
    cell.width = width * .1;
    cell.font = SEVENPOINT_BOLD_FONT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrgAgentCodeLabel";
    cell.cellType = CELL_LABEL;
    cell.width = width * .08;
    cell.font = PVO_REPORT_FONT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"OrgAgentCode" withType:CELL_LABEL withWidth:(width * .12)];
    [section duplicateLastCell:@"OrgDriverCodeLabel" withType:CELL_LABEL withWidth:(width * .08)];
    [section duplicateLastCell:@"OrgDriverCode" withType:CELL_LABEL withWidth:(width * .122)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Destination";
    cell.cellType = CELL_LABEL;
    cell.width = width * .11;
    cell.font = SEVENPOINT_BOLD_FONT;
    cell.borderType = BORDER_LEFT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DestAgentCodeLabel";
    cell.cellType = CELL_LABEL;
    cell.width = width * .08;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"DestAgentCode" withType:CELL_LABEL withWidth:(width * .12)];
    [section duplicateLastCell:@"DestDriverCodeLabel" withType:CELL_LABEL withWidth:(width * .08)];
    [section duplicateLastCell:@"DestDriverCode" withType:CELL_LABEL withWidth:(width * .114)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"ORIGIN"]] withColName:@"Origin"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Agent Code:"]] withColName:@"OrgAgentCodeLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Driver Code:"]] withColName:@"OrgDriverCodeLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"DESTINATION"]] withColName:@"Destination"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Agent Code:"]] withColName:@"DestAgentCodeLabel"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Driver Code:"]] withColName:@"DestDriverCodeLabel"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@", driver.haulingAgent == nil ? @"" : driver.haulingAgent]]]
                 withColName:@"OrgAgentCode"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@", driver.driverNumber == nil ? @"" : driver.driverNumber]]]
                 withColName:@"OrgDriverCode"];
    
    if (!isOrigin)
    {
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", driver.haulingAgent == nil ? @"" : driver.haulingAgent]]]
                     withColName:@"DestAgentCode"];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", driver.driverNumber == nil ? @"" : driver.driverNumber]]]
                     withColName:@"DestDriverCode"];
    }
    else
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DestAgentCode"];
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DestDriverCode"];
    }
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    int tempDrawn = drawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"OrgCustSig" withType:CELL_LABEL withWidth:(width * 0.39)];
    [section duplicateLastCell:@"OrgCustSigDate" withType:CELL_LABEL withWidth:(width * 0.1)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * 0.01)];
    [section duplicateLastCell:@"DestCustSig" withType:CELL_LABEL withWidth:(width * 0.39)];
    [section duplicateLastCell:@"DestCustSigDate" withType:CELL_LABEL withWidth:(width * 0.1)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n "]] withColName:@"blank1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Customer\r\n "]] withColName:@"OrgCustSig"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Date\r\n "]] withColName:@"OrgCustSigDate"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n "]] withColName:@"blank2"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Customer\r\n "]] withColName:@"DestCustSig"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Date\r\n "]] withColName:@"DestCustSigDate"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    if (print)
    {//print customer name in signature area
        section = [[PrintSection alloc] initWithRes:resolution];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank1";
        cell.cellType = CELL_LABEL;
        cell.width = width * 0.08;
        cell.font = SIXPOINT_FONT;
        [section addCell:cell];
        
        [section duplicateLastCell:@"OrgCustName" withType:CELL_LABEL withWidth:(width * 0.32)];
        [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * 0.18)];
        [section duplicateLastCell:@"DestCustName" withType:CELL_LABEL withWidth:(width * 0.32)];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", custName]]]
                     withColName:@"OrgCustName"];
        
        if (!isOrigin)
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", custName]]]
                         withColName:@"DestCustName"];
        
        //place it (put footer at the bottom)
        pos = params.contentRect.origin;
        pos.y = params.contentRect.size.height-takeOffBottom+tempDrawn;
        
        [section drawSection:context
                withPosition:pos
              andRemainingPX:params.contentRect.size.height-takeOffBottom+tempDrawn];
        
        
    }
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Sig1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .39;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.)];
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Date1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .1;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Sig1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .39;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.)];
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Date2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.1;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"blank1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"blank2"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  Signature"]] withColName:@"Sig1"];
    
    if (orgCustSigApplied && orgCustSig != nil)
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:orgCustSig.sigDate]]]]
                     withColName:@"Date1"];
    }
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date1"];
    
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  Signature"]] withColName:@"Sig2"];
    
    if (!isOrigin)
    {
        if (destCustSigApplied && destCustSig != nil)
        {
            [section addColumnValues:[NSMutableArray arrayWithObject:
                                      [CellValue cellWithLabel:
                                       [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:destCustSig.sigDate]]]]
                         withColName:@"Date2"];
        }
        else
            [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date2"];
    }
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date2"];
    
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    // customer signatures
    if (print && orgCustSigApplied)
    {
        UIImage *custSig = [orgCustSig signatureData];
        CGSize tmpSize = [custSig size];
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + (width * 0.2),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && destCustSigApplied)
    {
        UIImage *custSig = [destCustSig signatureData];
        CGSize tmpSize = [custSig size];
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + (width * 0.7),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    
    tempDrawn = drawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrgDriverSig";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.39;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"OrgDriverSigDate" withType:CELL_LABEL withWidth:(width * 0.1)];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DestDriverSig";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.39;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"DestDriverSigDate" withType:CELL_LABEL withWidth:(width * 0.1)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n "]] withColName:@"blank1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Carrier\r\n "]] withColName:@"OrgDriverSig"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Date\r\n "]] withColName:@"OrgDriverSigDate"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\n "]] withColName:@"blank2"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Carrier\r\n "]] withColName:@"DestDriverSig"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Date\r\n "]] withColName:@"DestDriverSigDate"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    if (print)
    {//print customer name in signature area
        NSString *driverName = [NSString stringWithFormat:@"%@",
                                driver.driverName == nil ? @"" : driver.driverName];
        
        section = [[PrintSection alloc] initWithRes:resolution];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank1";
        cell.cellType = CELL_LABEL;
        cell.width = width * 0.06;
        cell.font = SIXPOINT_FONT;
        [section addCell:cell];
        
        [section duplicateLastCell:@"OrgDriverName" withType:CELL_LABEL withWidth:(width * 0.34)];
        [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * 0.16)];
        [section duplicateLastCell:@"DestDriverName" withType:CELL_LABEL withWidth:(width * 0.34)];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", driverName]]]
                     withColName:@"OrgDriverName"];
        
        if (!isOrigin)
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", driverName]]]
                         withColName:@"DestDriverName"];
        
        //place it (put footer at the bottom)
        pos = params.contentRect.origin;
        pos.y = params.contentRect.size.height-takeOffBottom+tempDrawn;
        
        [section drawSection:context
                withPosition:pos
              andRemainingPX:params.contentRect.size.height-takeOffBottom+tempDrawn];
        
        
    }
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Sig1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .39;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.)];
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Date1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .1;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Sig1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .39;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.)];
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Date2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.1;
    cell.font = PVO_REPORT_FONT;
    cell.borderType = BORDER_LEFT;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"blank1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"blank2"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  Signature"]] withColName:@"Sig1"];
    
    if (driverSigApplied && driverSig != nil)
    {
        if (orgCustSigApplied && orgCustSig != nil)
        {
            [section addColumnValues:[NSMutableArray arrayWithObject:
                                      [CellValue cellWithLabel:
                                       [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:orgCustSig.sigDate]]]]
                         withColName:@"Date1"];
        }
        else
        {
            [section addColumnValues:[NSMutableArray arrayWithObject:
                                      [CellValue cellWithLabel:
                                       [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:driverSig.sigDate]]]]
                         withColName:@"Date1"];
        }
    }
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  Signature"]] withColName:@"Sig2"];
    
    if (!isOrigin)
    {
        if (driverSigApplied && driverSig != nil)
        {
            if (destCustSigApplied && destCustSig != nil)
            {
                [section addColumnValues:[NSMutableArray arrayWithObject:
                                          [CellValue cellWithLabel:
                                           [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:destCustSig.sigDate]]]]
                             withColName:@"Date2"];
            }
            else
            {
                [section addColumnValues:[NSMutableArray arrayWithObject:
                                          [CellValue cellWithLabel:
                                           [NSString stringWithFormat:@" %@", [SurveyAppDelegate formatDate:driverSig.sigDate]]]]
                             withColName:@"Date2"];
            }
        }
        else
            [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date2"];
    }
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Date2"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    
    
    
    // driver signatures
    if (print && driverSigApplied)
    {
        UIImage *drvSig = [driverSig signatureData];
        CGSize tmpSize = [drvSig size];
        drvSig = [SurveyAppDelegate scaleAndRotateImage:drvSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + (width * 0.2),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
        [self drawImage:drvSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && driverSigApplied)
    {
        UIImage *drvSig = [driverSig signatureData];
        CGSize tmpSize = [drvSig size];
        drvSig = [SurveyAppDelegate scaleAndRotateImage:drvSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + (width * 0.7),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
        [self drawImage:drvSig withCGRect:custSigRect];
    }
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Version";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = PVO_REPORT_FIVEPOINT_FONT;
    cell.textPosition = NSTextAlignmentRight;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:[NSString stringWithFormat:@"Mobile Mover %@; Disconnected",
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]]]
                 withColName:@"Version"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    return drawn;
}

//MARK: Rider Exceptions
-(int)addRiderHeader:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    PVOInventoryLoad *workingLoad = [self getRiderExceptionsWorkingLoad];
    
    PrintSection *section;
    PrintCell *cell;
    CGPoint pos;
    int drawn = 0, tempDrawn = 0, vlImageDrawn = 0;
    
    //if (print)
    {
        double scale = 1;
        NSString *vanLineText = @"";
        
        if(cust.pricingMode == 0)
        {
            
        }
        
        if ([vanLineText length] > 0)
        {
            UIImage *image1 = [UIImage imageNamed:vanLineText];
            CGSize	tmpSize1 = [image1 size];
            image1 = [SurveyAppDelegate scaleAndRotateImage:image1 withOrientation:UIImageOrientationDownMirrored];
            CGRect imageRect1 = CGRectMake(params.contentRect.origin.x + TO_PRINTER(2.),
                                           params.contentRect.origin.y + TO_PRINTER(3.),
                                           tmpSize1.width * scale,
                                           tmpSize1.height * scale);
            
            if (print)
                [self drawImage:image1 withCGRect:imageRect1];
            drawn += ceilf(imageRect1.size.height) + TO_PRINTER(3.);
            vlImageDrawn = drawn;
        }
    }
    
    
    tempDrawn = drawn;
    if (cust.pricingMode == 0)
    {
        //set up section
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cell(s)
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"vlInfo";
        cell.cellType = CELL_LABEL;
        cell.textPosition = NSTextAlignmentLeft;
        cell.width = width;
        cell.padding = 0;
        cell.font = TENPOINT_BOLD_FONT;
        [section addCell:cell];
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"vlInfo"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y += drawn;
        
        //print it, check to make sure it fit...
        //if not, store it in the collection of items to continue...
        if (print)
            drawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
        else
            drawn += [section height];
        
        
        //set up section
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cell(s)
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"vlInfo";
        cell.cellType = CELL_LABEL;
        cell.textPosition = NSTextAlignmentLeft;
        cell.width = width;
        cell.padding = 0;
        cell.font = TENPOINT_FONT;
        [section addCell:cell];
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@" "],
                                  [CellValue cellWithLabel:@" "],
                                  [CellValue cellWithLabel:@" "],
                                  nil]
                     withColName:@"vlInfo"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y += drawn;
        
        //print it, check to make sure it fit...
        //if not, store it in the collection of items to continue...
        if (print)
            drawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
        else
            drawn += [section height];
        
        
        //set up section
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cell(s)
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"vlInfo";
        cell.cellType = CELL_LABEL;
        cell.textPosition = NSTextAlignmentLeft;
        cell.width = width;
        cell.padding = 0;
        cell.font = TENPOINT_BOLD_FONT;
        [section addCell:cell];
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]]
                     withColName:@"vlInfo"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y += drawn;
        
        //print it, check to make sure it fit...
        //if not, store it in the collection of items to continue...
        if (print)
            drawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
        else
            drawn += [section height];
        
    }
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Header";
    cell.cellType = CELL_LABEL;
    cell.textPosition = NSTextAlignmentCenter;
    cell.width = width;
    cell.font = THIRTEENPOINT_BOLD_FONT;
    cell.padding = 0;
    [section addCell:cell];
    
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"INVENTORY EXCEPTIONS REPORT"]]
                 withColName:@"Header"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += tempDrawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-tempDrawn];
    else
        tempDrawn += [section height];
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Header";
    cell.cellType = CELL_LABEL;
    cell.textPosition = NSTextAlignmentCenter;
    cell.width = width;
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"For carrier's use only -- (DO NOT GIVE TO CUSTOMER.)"]]
                 withColName:@"Header"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += tempDrawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-tempDrawn];
    else
        tempDrawn += [section height];
    
    
    
    if (tempDrawn > drawn)
        drawn = tempDrawn;
    tempDrawn = vlImageDrawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.width = (width*0.8);
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"checks" withType:CELL_CHECKBOX withWidth:(width*0.2)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObjects:
                              [CellValue cellWithValue:(workingLoad != nil && workingLoad.receivedFromPVOLocationID == WAREHOUSE && workingLoad.pvoLocationID != WAREHOUSE ? @"1" : @"0") withLabel:@"Warehouse to Van"],
                              [CellValue cellWithValue:(workingLoad != nil && workingLoad.receivedFromPVOLocationID == VAN_TO_VAN && workingLoad.pvoLocationID != WAREHOUSE ? @"1" : @"0") withLabel:@"Van to Van"],
                              [CellValue cellWithValue:(workingLoad != nil && workingLoad.receivedFromPVOLocationID == VAN_TO_VAN && workingLoad.pvoLocationID == WAREHOUSE ? @"1" : @"0") withLabel:@"Van to Warehouse"],
                              [CellValue cellWithValue:@"0" withLabel:@"Other: ____________"],
                              nil]
                 withColName:@"checks"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += tempDrawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom-tempDrawn];
    else
        tempDrawn += [section height];
    
    
    if (tempDrawn > drawn)
        drawn = tempDrawn;
    tempDrawn = drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrderNo";
    cell.cellType = CELL_TEXT_LABEL;
    cell.width = (width*0.4);
    cell.font = TENPOINT_FONT;
    cell.padding = 0;
    [section addCell:cell];
    
    [section duplicateLastCell:@"Customer" withType:CELL_TEXT_LABEL withWidth:(width*0.4)];
    
    int pageTextWidth = ([self getTextWidth:@" Page" withFont:TENPOINT_FONT] * 1.05), ofTextWidth = ([self getTextWidth:@" of " withFont:TENPOINT_FONT] * 1.05);
    [section duplicateLastCell:@"page_label" withType:CELL_LABEL withWidth:pageTextWidth];
    [section duplicateLastCell:@"page_no" withType:CELL_LABEL withWidth:(((width*0.2)-pageTextWidth-ofTextWidth)*0.5)];
    cell = (PrintCell*)[[section cells] objectAtIndex:[[section cells] count]-1];
    cell.borderType = BORDER_BOTTOM;
    cell.textPosition = NSTextAlignmentCenter;
    [section duplicateLastCell:@"page_of" withType:CELL_LABEL withWidth:ofTextWidth];
    cell = (PrintCell*)[[section cells] objectAtIndex:[[section cells] count]-1];
    cell.borderType = BORDER_NONE;
    cell.textPosition = NSTextAlignmentLeft;
    [section duplicateLastCell:@"total_pages" withType:CELL_LABEL withWidth:(((width*0.2)-pageTextWidth-ofTextWidth)*0.5)];
    cell = (PrintCell*)[[section cells] objectAtIndex:[[section cells] count]-1];
    cell.borderType = BORDER_BOTTOM;
    cell.textPosition = NSTextAlignmentCenter;
    
    
    //add values
    NSString *temp = inf.orderNumber;
    if (temp == nil) temp = @"";
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithValue:temp withLabel:@"Order No."]]
                 withColName:@"OrderNo"];
    
    temp = [NSString stringWithFormat:@"%@ %@", (cust.firstName == nil ? @"" : cust.firstName), (cust.lastName == nil ? @"" : cust.lastName)];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithValue:temp withLabel:@" Customer:"]] withColName:@"Customer"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Page"]] withColName:@"page_label"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[[NSNumber numberWithInt:params.pageNum] stringValue]]] withColName:@"page_no"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" of "]] withColName:@"page_of"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[[NSNumber numberWithInt:params.pageNum] stringValue]]] withColName:@"total_pages"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
    else
        drawn += [section height];
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"legal";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = [UIFont systemFontOfSize:8.5];
    [section addCell:cell];
    
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"This form is used to record damages or loss exceptions to the origin condition as noted on the Descriptive Inventory.  This form must be completed when a shipment transfers from one van line representative to another, such as van to van transfer, G11, set off, pick up from warehouse (including pick up from permanent storage) and delivery to warehouse.  Both delivering and receiving parties must sign this form."]] withColName:@"legal"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
    else
        drawn += [section height];
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"legal";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = [UIFont boldSystemFontOfSize:8.5];
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"NOTE: If delivering party disagrees with exception(s) "
                                                              "taken, give reason for disagreement in the Remarks section and sign the form."]] withColName:@"legal"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
    else
        drawn += [section height];
    
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_ALL;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ColorTag";
    cell.cellType = CELL_LABEL;
    cell.width = (width*0.18);
    cell.font = NINEPOINT_BOLD_FONT;
    cell.padding = 0;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"Item" withType:CELL_LABEL withWidth:(width*0.25)];
    [section duplicateLastCell:@"Exceptions" withType:CELL_LABEL withWidth:(width*0.57)];
    ((PrintCell*)[[section cells] objectAtIndex:[[section cells] count]-1]).borderType = BORDER_NONE;
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Color/Tag #"]] withColName:@"ColorTag"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Item"]] withColName:@"Item"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Exceptions to Origin Conditions"]] withColName:@"Exceptions"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y += drawn;
    
    //print it, check to make sure it fit...
    //if not, store it in the collection of items to continue...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom-drawn];
    else
        drawn += [section height];
    
    
    return drawn;
}

-(int)riderItem
{
    return [self riderItem:NO shouldPrint:YES];
}

-(int)riderItemNone
{
    return [self riderItem:YES shouldPrint:YES];
}

-(int)riderItem:(BOOL)isNone shouldPrint:(BOOL)print
{
    int drawn = 0;
    
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_LEFT;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ColorTag";
    cell.cellType = CELL_LABEL;
    cell.width = (width*0.18);
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    int minHeight = [cell heightWithText:@" "]; //one line minimum height
    
    [section duplicateLastCell:@"Item" withType:CELL_LABEL withWidth:(width*0.25) withAlign:NSTextAlignmentLeft];
    [section duplicateLastCell:@"Exceptions" withType:CELL_LABEL withWidth:(width*0.57) withAlign:NSTextAlignmentLeft];
    
    //add values
    NSString *colorTag = @"", *itemDescrip = @"", *exceptions = @"";
    if (isNone)
    {
        itemDescrip = @"NONE";
    }
    else if (myItem != nil)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSDictionary *colors = [del.surveyDB getPVOColors];
        if ([colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]] != nil)
            colorTag = [NSString stringWithFormat:@"%@", [colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]];
        
        colorTag = [colorTag stringByAppendingFormat:@"%@%@%@", ([colorTag length] > 0 ? @" " : @""), myItem.lotNumber != nil ? myItem.lotNumber : @"", myItem.itemNumber != nil ? myItem.itemNumber : @""];
        
        Item *item = [del.surveyDB getItem:myItem.itemID WithCustomer:del.customerID];
        if (item.name != nil)
            itemDescrip = [NSString stringWithFormat:@"%@", item.name];
        
        
        NSArray *riderExceptions = [del.surveyDB getPVOItemDamage:myItem.pvoItemID forDamageType:(int)DAMAGE_RIDER];
        if (riderExceptions != nil && [riderExceptions count] > 0)
        {
            NSDictionary *pvoDamages = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
            NSDictionary *pvoDamageLocs = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
            for (PVOConditionEntry *damage in riderExceptions)
            {
                if (!damage.isEmpty)
                {
                    NSString *loc = @"";
                    for (NSString *damageLoc in [damage locationArray])
                    {
                        if ([loc length] > 0)
                            loc = [loc stringByAppendingString:@"-"];
                        
                        if (!printDamageCodeOnly)
                        {
                            loc = [loc stringByAppendingString:
                                   [NSString stringWithFormat:@"%@", [PVOConditionEntry pluralizeLocation:pvoDamageLocs withKey:damageLoc]]];
                        }
                        else
                        {
                            loc = [loc stringByAppendingString:
                                   [NSString stringWithFormat:@"%@", damageLoc]];
                        }
                    }
                    
                    NSString *cond = @"";
                    for (NSString *damageCond in [damage conditionArray])
                    {
                        if ([cond length] > 0)
                            cond = [cond stringByAppendingString:@"-"];
                        
                        if (!printDamageCodeOnly)
                        {
                            cond = [cond stringByAppendingString:
                                    [NSString stringWithFormat:@"%@", [pvoDamages objectForKey:damageCond]]];
                        }
                        else
                        {
                            cond = [cond stringByAppendingString:
                                    [NSString stringWithFormat:@"%@", damageCond]];
                        }
                    }
                    
                    if ([exceptions length] > 0)
                        exceptions = [exceptions stringByAppendingString:@", "];
                    if ([loc length] > 0)
                    {
                        exceptions = [exceptions stringByAppendingString:loc];
                        if ([cond length] > 0)
                            exceptions = [exceptions stringByAppendingString:@" "];
                    }
                    if ([cond length] > 0)
                        exceptions = [exceptions stringByAppendingString:cond];
                }
            }
            
            
        }
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", colorTag]]] withColName:@"ColorTag"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", itemDescrip]]] withColName:@"Item"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"%@", exceptions]]] withColName:@"Exceptions"];
    
    //find highest height, set it
    int highestHeight = minHeight;
    for (PrintCell *cell in [section cells]) //first loop, find highest
    {
        int currentHeight = [cell heightWithText:((CellValue*)[[[section values] objectForKey:cell.cellName] objectAtIndex:0]).label];
        if (currentHeight > highestHeight)
            highestHeight = currentHeight;
    }
    for (PrintCell *cell in [section cells]) //second loop, set highest
    {
        cell.overrideHeight = YES;
        cell.cellHeight = highestHeight;
    }
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    if (print)
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    else
        drawn = [section height];
    
    
    if (print)
        currentPageY += drawn;
    
    return drawn;
}

-(int)riderFinishPage
{
    myItem = nil;
    int drawn = 0, blankHeight = [self riderItem:NO shouldPrint:NO], notesHeight = [self riderNotes:NO];
    if (params.contentRect.size.height-takeOffBottom-currentPageY < notesHeight)
        notesHeight = 0; //notes wont fit, go ahead and finish page w/o it
    while ((params.contentRect.size.height-takeOffBottom)-currentPageY > blankHeight + notesHeight)
        drawn += [self riderItem:NO shouldPrint:YES];
    if (notesHeight == 0)
        return FORCE_PAGE_BREAK;
    else
        return drawn;
}

-(int)riderNotesPrint
{
    return [self riderNotes:YES];
}

-(int)riderNotes:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *notes = [del.surveyDB getReportNotes:del.customerID forType:[del.pricingDB getReportNotesTypeForPVONavItemID:PVO_P_RIDER_EXCEPTIONS]];
    int drawn = 0;
    
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_ALL;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"notes";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = EIGHTPOINT_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    int minHeight = [cell heightWithText:@" \r\n \r\n "]; //needs to be at least 3 lines high
    //
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"Remarks: %@", notes == nil ? @"" : notes]]] withColName:@"notes"];
    
    if ([cell heightWithText:((CellValue*)[[[section values] objectForKey:@"notes"] objectAtIndex:0]).label] < minHeight)
    {
        cell.overrideHeight = YES;
        cell.cellHeight = minHeight;
    }
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    if (print)
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    else
        drawn = [section height];
    
    
    if (print)
        currentPageY += drawn;
    
    return drawn;
}

-(int)riderFooter:(BOOL)print
{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    PVOSignature *custSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_RIDER_EXCEPTIONS];
    PVOSignature *driverSig = [del.surveyDB getPVOSignature:-1
                                               forImageType:(driver.driverType == PVO_DRIVER_TYPE_PACKER ? PVO_SIGNATURE_TYPE_PACKER : PVO_SIGNATURE_TYPE_DRIVER)];
    
    PrintSection *section;
    PrintCell *cell;
    CGPoint pos;
    
    BOOL custSigApplied = FALSE;
    if (custSig != nil)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[custSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            custSigApplied = TRUE;
    }
    BOOL driverSigApplied = FALSE;
    if (driverSig != nil)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[driverSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            driverSigApplied = TRUE;
    }
    
    int drawn = 0, tempDrawn = 0, signatureHeight = 0;
    
    //find height for signatures
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.font = EIGHTPOINT_FONT;
    cell.padding = 0;
    signatureHeight = [cell heightWithText:@" \r\n \r\n "]; //three lines high
    drawn = signatureHeight;
    
    
    
    if (print && custSigApplied)
    {
        UIImage *custSigImg = [custSig signatureData];
        CGSize tmpSize = [custSigImg size];
        double scale = signatureHeight / tmpSize.height;
        double addHeight = 0;
        if (tmpSize.width * scale > (width * 0.5))
        {
            scale = ((width * 0.5) / tmpSize.width);
            addHeight = ((width * 0.5) - (tmpSize.width * scale)); //so it prints on the bottom of the line
        }
        custSigImg = [SurveyAppDelegate scaleAndRotateImage:custSigImg withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x+TO_PRINTER(1.),
                                        params.contentRect.size.height-takeOffBottom+addHeight+TO_PRINTER(1.),
                                        tmpSize.width * scale,
                                        tmpSize.height * scale);
        [self drawImage:custSigImg withCGRect:custSigRect];
    }
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"signature";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.5;
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    tempDrawn = drawn - [cell heightWithText:@" "]; //want to print along side the signatue image
    
    [section duplicateLastCell:@"agency_driver" withType:CELL_LABEL withWidth:(width*0.25)];
    [section duplicateLastCell:@"signature_date" withType:CELL_LABEL withWidth:(width*0.25)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"signature"]; //so a border prints
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"agency_driver"]; //don't have anywehre to pull from right now
    if (custSigApplied)
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDate:custSig.sigDate]]] withColName:@"signature_date"];
    else
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"signature_date"];
    
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+tempDrawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    //don't need to keep this height, since we print it right below the signature
    if (print)
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    else
        tempDrawn += [section height];
    
    
    if (tempDrawn > drawn)
        drawn = tempDrawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"signature1";
    cell.cellType = CELL_LABEL;
    cell.padding = 0;
    cell.width = [self getTextWidth:@"Signature of person" withFont:TENPOINT_FONT] + (cell.padding*2);
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    [section duplicateLastCell:@"signature2" withType:CELL_LABEL withWidth:((width*0.5)-cell.width)];
    
    ((PrintCell*)[[section cells] objectAtIndex:([[section cells] count]-1)]).font = TENPOINT_BOLD_FONT;
    [section duplicateLastCell:@"agency_driver" withType:CELL_LABEL withWidth:(width*0.25)];
    ((PrintCell*)[[section cells] objectAtIndex:([[section cells] count]-1)]).font = TENPOINT_FONT;
    [section duplicateLastCell:@"signature_date" withType:CELL_LABEL withWidth:(width*0.25)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Signature of person"]] withColName:@"signature1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" delivering goods:"]] withColName:@"signature2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Agency/Driver ID:"]] withColName:@"agency_driver"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Date:"]] withColName:@"signature_date"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    else
        drawn += [section height];
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"legal";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" \r\nGoods were received as noted on original inventory except as noted above."]] withColName:@"legal"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    else
        drawn += [section height];
    
    
    
    if (print && driverSigApplied)
    {
        UIImage *driverSigImg = [driverSig signatureData];
        CGSize tmpSize = [driverSigImg size];
        double scale = signatureHeight / tmpSize.height;
        double addHeight = 0;
        if (tmpSize.width * scale > (width * 0.5))
        {
            scale = ((width * 0.5) / tmpSize.width);
            addHeight = ((width * 0.5) - (tmpSize.width * scale)); //so it prints on the bottom of the line
        }
        driverSigImg = [SurveyAppDelegate scaleAndRotateImage:driverSigImg withOrientation:UIImageOrientationDownMirrored];
        CGRect driverSigRect = CGRectMake(params.contentRect.origin.x+TO_PRINTER(1.),
                                          params.contentRect.size.height-takeOffBottom+addHeight+drawn+TO_PRINTER(1.),
                                          tmpSize.width * scale,
                                          tmpSize.height * scale);
        [self drawImage:driverSigImg withCGRect:driverSigRect];
    }
    drawn += signatureHeight;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"signature";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.5;
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    tempDrawn = drawn - [cell heightWithText:@" "]; //want to print along side the signatue image
    
    [section duplicateLastCell:@"agency_driver" withType:CELL_LABEL withWidth:(width*0.25)];
    [section duplicateLastCell:@"signature_date" withType:CELL_LABEL withWidth:(width*0.25)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"signature"]; //so a border prints
    if (driverSigApplied)
    {
        NSString *agencyDriverId = [NSString stringWithFormat:@"%@", driver.haulingAgent != nil ? driver.haulingAgent : @""];
        if (driver.driverNumber != nil && [driver.driverNumber length] > 0)
            agencyDriverId = [agencyDriverId stringByAppendingFormat:@"%@%@", [agencyDriverId length] > 0 ? @" / " : @"", driver.driverNumber];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:agencyDriverId]] withColName:@"agency_driver"];
        if (custSigApplied)
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDate:custSig.sigDate]]] withColName:@"signature_date"];
        else
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[SurveyAppDelegate formatDate:driverSig.sigDate]]] withColName:@"signature_Date"];
    }
    else
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"agency_driver"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"signature_date"];
    }
    
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+tempDrawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    //don't need to keep this height, since we print it right below the signature
    if (print)
        tempDrawn += [section drawSection:context
                             withPosition:pos
                           andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    else
        tempDrawn += [section height];
    
    
    if (tempDrawn > drawn)
        drawn = tempDrawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"signature1";
    cell.cellType = CELL_LABEL;
    cell.padding = 0;
    cell.width = [self getTextWidth:@"Signature of person" withFont:TENPOINT_FONT] + (cell.padding*2);
    cell.font = TENPOINT_FONT;
    [section addCell:cell];
    [section duplicateLastCell:@"signature2" withType:CELL_LABEL withWidth:((width*0.5)-cell.width)];
    
    ((PrintCell*)[[section cells] objectAtIndex:([[section cells] count]-1)]).font = TENPOINT_BOLD_FONT;
    [section duplicateLastCell:@"agency_driver" withType:CELL_LABEL withWidth:(width*0.25)];
    ((PrintCell*)[[section cells] objectAtIndex:([[section cells] count]-1)]).font = TENPOINT_FONT;
    [section duplicateLastCell:@"signature_date" withType:CELL_LABEL withWidth:(width*0.25)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Signature of person"]] withColName:@"signature1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" receiving goods:"]] withColName:@"signature2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Agency/Driver ID:"]] withColName:@"agency_driver"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Date:"]] withColName:@"signature_date"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if (print)
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    else
        drawn += [section height];
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Version";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = PVO_REPORT_FIVEPOINT_FONT;
    cell.textPosition = NSTextAlignmentRight;
    [section addCell:cell];
    
    
    // add values
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:[NSString stringWithFormat:@"Mobile Mover %@; Disconnected",
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]]]
                 withColName:@"Version"];
    
    //place it (put footer at the bottom)
    pos = params.contentRect.origin;
    pos.y = params.contentRect.size.height-takeOffBottom+drawn;
    
    //for printing the footer, give it entire height to print, and put it at the bottom...
    if(!print)
        drawn += [section height];
    else
        drawn += [section drawSection:context
                         withPosition:pos
                       andRemainingPX:params.contentRect.size.height-takeOffBottom+drawn];
    
    return drawn;
}


//MARK: Helpers
-(void)updateCurrentPageY
{
    if(leftCurrentPageY > currentPageY)
        currentPageY = leftCurrentPageY;
    leftCurrentPageY = currentPageY;
}

-(int)findHighestHeight:(NSArray*) heights
{
    int retVal = 0;
    for(NSNumber *i in heights)
    {
        if ([i intValue] > retVal)
            retVal = [i intValue];
    }
    return retVal;
}


-(void)populateCpPboSummaries
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    cpSummary = [[NSMutableDictionary alloc] init];
    pboSummary = [[NSMutableDictionary alloc] init];
    crateSummary = [[NSMutableDictionary alloc] init];
    
    cpSummaryTotal = 0;
    pboSummaryTotal = 0;
    crateSummaryTotal = 0;
    
    NSArray *loads = [del.surveyDB getPVOLocationsForCust:del.customerID], *items = nil;
    NSString *currentKey;
    NSString *currentCrateKey;
    NSNumber *currentCount;
    for (int i = 0; i < [loads count]; i++)
    {
        PVOInventoryLoad *load = [loads objectAtIndex:i];
        items = [del.surveyDB getPVOItemsForLoad:load.pvoLoadID];
        for (int j=0; j < [items count]; j++)
        {
            PVOItemDetail *pvoItem = [items objectAtIndex:j];
            if (!pvoItem.itemIsDeleted)
            {
                Item *item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
                currentKey = [NSString stringWithFormat:@"%@", item.name];
                currentCrateKey = [NSString stringWithFormat:@"%@ %dx%dx%d", item.name, pvoItem.length, pvoItem.width, pvoItem.height];
                if (item.isCP)
                {
                    currentCount = [cpSummary objectForKey:currentKey];
                    cpSummaryTotal += pvoItem.quantity;
                    if (currentCount != nil)
                        [cpSummary setValue:[NSNumber numberWithInt:([currentCount intValue]+pvoItem.quantity)] forKey:currentKey];
                    else
                        [cpSummary setValue:[NSNumber numberWithInt:pvoItem.quantity] forKey:currentKey];
                }
                if (item.isPBO)
                {
                    currentCount = [pboSummary objectForKey:currentKey];
                    pboSummaryTotal += pvoItem.quantity;
                    if (currentCount != nil)
                        [pboSummary setValue:[NSNumber numberWithInt:([currentCount intValue]+pvoItem.quantity)] forKey:currentKey];
                    else
                        [pboSummary setValue:[NSNumber numberWithInt:pvoItem.quantity] forKey:currentKey];
                }
                if (item.isCrate)
                {
                    currentCount = [crateSummary objectForKey:currentCrateKey];
                    crateSummaryTotal += pvoItem.quantity;
                    if (currentCount != nil)
                        [crateSummary setValue:[NSNumber numberWithInt:([currentCount intValue]+pvoItem.quantity)] forKey:currentCrateKey];
                    else
                        [crateSummary setValue:[NSNumber numberWithInt:pvoItem.quantity] forKey:currentCrateKey];
                }
            }
        }
        
    }
}

-(void)sortPVOItemDetailArray:(NSMutableArray *)items accountForInvAfterSig:(BOOL)acctAfterInvSig
{
    return [self sortPVOItemDetailArray:items accountForInvAfterSig:acctAfterInvSig afterSigOnBottom:YES];
}

-(void)sortPVOItemDetailArray:(NSMutableArray *)items accountForInvAfterSig:(BOOL)acctAfterInvSig afterSigOnBottom:(BOOL)afterSigOnBottom
{
    if (items != nil && [items count] > 1)
    {
        [items sortUsingComparator:^NSComparisonResult(id a, id b) {
            if (a == nil && b == nil) {
                return NSOrderedSame;
            } else if (a == nil) {
                return NSOrderedAscending;
            } else if (b == nil) {
                return NSOrderedDescending;
            } else {
                PVOItemDetail *first = nil;
                PVOItemDetail *second = nil;
                if ([a isKindOfClass:[PVOItemDetail class]])
                    first = (PVOItemDetail*)a;
                if ([b isKindOfClass:[PVOItemDetail class]])
                    second = (PVOItemDetail*)b;
                
                if (first == nil && second == nil) {
                    return NSOrderedSame;
                } else if (first == nil) {
                    return NSOrderedAscending;
                } else if (second == nil) {
                    return NSOrderedDescending;
                } else {
                    if (acctAfterInvSig && first.inventoriedAfterSignature != second.inventoriedAfterSignature) {
                        if (first.inventoriedAfterSignature) {
                            return (afterSigOnBottom ? NSOrderedDescending : NSOrderedAscending);
                        } else return (afterSigOnBottom ? NSOrderedAscending : NSOrderedDescending);
                    } else if (first.lotNumber != nil && second.lotNumber != nil) {
                        if (![first.lotNumber isEqualToString:second.lotNumber]) {
                            return [first.lotNumber compare:second.lotNumber];
                        } else {
                            if (first.itemNumber != nil && second.itemNumber != nil) {
                                if ([first.itemNumber rangeOfString:@"."].location != NSNotFound || [second.itemNumber rangeOfString:@"."].location != NSNotFound) {
                                    //compare carton content item numbers
                                    NSArray *firstItemSplit = [first.itemNumber componentsSeparatedByString:@"."];
                                    NSArray *secondItemSplit = [second.itemNumber componentsSeparatedByString:@"."];
                                    for (int i=0;(i<[firstItemSplit count]) && (i<[secondItemSplit count]);i++) {
                                        if (![[firstItemSplit objectAtIndex:i] isEqualToString:[secondItemSplit objectAtIndex:i]])
                                            return [[firstItemSplit objectAtIndex:i] compare:[secondItemSplit objectAtIndex:i]];
                                    }
                                    //want carton content item on bottom
                                    if ([firstItemSplit count] > [secondItemSplit count])
                                        return NSOrderedDescending;
                                    else if ([secondItemSplit count] > [firstItemSplit count])
                                        return NSOrderedAscending;
                                }
                                return [first.itemNumber compare:second.itemNumber];
                            } else if (first.itemNumber != nil) {
                                return NSOrderedDescending;
                            } else if (second.itemNumber != nil) {
                                return NSOrderedAscending;
                            } else return NSOrderedSame;
                        }
                    } else if (first.itemNumber != nil && second.itemNumber != nil) {
                        if ([first.itemNumber rangeOfString:@"."].location != NSNotFound && [second.itemNumber rangeOfString:@"."].location != NSNotFound) {
                            //compare carton content item numbers
                            NSArray *firstItemSplit = [first.itemNumber componentsSeparatedByString:@"."];
                            NSArray *secondItemSplit = [second.itemNumber componentsSeparatedByString:@"."];
                            for (int i=0;(i<[firstItemSplit count]) && (i<[secondItemSplit count]);i++) {
                                if (![[firstItemSplit objectAtIndex:i] isEqualToString:[secondItemSplit objectAtIndex:i]])
                                    return [[firstItemSplit objectAtIndex:i] compare:[secondItemSplit objectAtIndex:i]];
                            }
                        }
                        return [first.itemNumber compare:second.itemNumber];
                    } else if (first.itemNumber != nil) {
                        return NSOrderedDescending;
                    } else if (second.itemNumber != nil) {
                        return NSOrderedAscending;
                    } else return NSOrderedSame;
                }
            }
        }];
    }
}

-(BOOL)hasNonHighValueItems:(NSArray*)items
{
    BOOL hasNonHighValue = FALSE;
    
    if (items != nil || [items count] > 0)
    {
        for (int i=0; i < [items count]; i++)
        {
            hasNonHighValue = ([[items objectAtIndex:i] highValueCost] == 0);
            if (hasNonHighValue) break;
        }
    }
    
    return hasNonHighValue;
}

-(PVOInventoryLoad*)getRiderExceptionsWorkingLoad
{
    PVOInventoryLoad *workingLoad = nil;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (riderExceptionLoadID != 0)
    {
        if (riderExceptionLoadID > 0) //if it's less than zero, means we already tried and didn't find a load to work
            workingLoad = [del.surveyDB getPVOLoad:riderExceptionLoadID];
    }
    else
    {
        NSArray *loads = [del.surveyDB getPVOLocationsForCust:del.customerID];
        if (loads != nil && [loads count] > 0)
        {
            for (PVOInventoryLoad *l in loads)
            {
                if ((l.receivedFromPVOLocationID = WAREHOUSE || l.receivedFromPVOLocationID == VAN_TO_VAN) && l.pvoLocationID != l.receivedFromPVOLocationID)
                    workingLoad = l;
                if (workingLoad != nil)
                    break;
            }
        }
        if (workingLoad != nil)
            riderExceptionLoadID = workingLoad.pvoLoadID;
        else
            riderExceptionLoadID = -1;
    }
    
    return workingLoad;
}

-(int)getTextWidth:(NSString*)text withFont:(UIFont*)font
{
    if (text == nil || font == nil)
        return 0;
    return ceilf([text sizeWithAttributes:@{NSFontAttributeName:font}].width);
}

@end
