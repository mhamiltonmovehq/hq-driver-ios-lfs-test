//
//  AtlasDrawer.m
//  Survey
//
//  Created by Tony Brame on 3/8/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "ArpinPVODrawer.h"
#import "SurveyAppDelegate.h"
#import "PrintCell.h"
#import "CellValue.h"
#import "CustomerUtilities.h"
#import "SyncGlobals.h"
#import "PVOPrintController.h"

@implementation ArpinPVODrawer


-(NSDictionary*)availableReports
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:@"ESign Agreement" forKey:[NSNumber numberWithInt:ESIGN_AGREEMENT]];
    [dict setObject:@"Inventory" forKey:[NSNumber numberWithInt:INVENTORY]];
    [dict setObject:@"Delivery Inventory" forKey:[NSNumber numberWithInt:DELIVERY_INVENTORY]];
    //[dict setObject:@"Load High Value" forKey:[NSNumber numberWithInt:LOAD_HIGH_VALUE]];
    //[dict setObject:@"Delivery High Value" forKey:[NSNumber numberWithInt:DEL_HIGH_VALUE]];
    
    return dict;
}

-(BOOL)getPage:(PagePrintParam*)parms
{
    @autoreleasepool {
    
        params = parms;
        
        context = params.context;
        
    if(context != nil)
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
    
    if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
    {
        if (currentPageY <= [self addHeader:FALSE])
            currentPageY += TO_PRINTER(30.);
    }
    
    
    // needs initialized for header/footer method
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    custID = del.customerID;
    isOrigin = (reportID == INVENTORY);
    
    //setup damage print type
    printDamageCodeOnly = ([del.surveyDB getDriverData].reportPreference > 0);
    
    // setup header method
    if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
        headerMethod = @selector(addHeader:);
    else
        headerMethod = nil;
        
        // setup footer method
    if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
        footerMethod = @selector(invFooter:);
    else
        footerMethod = nil;
        
    
        //prep the page
        [self preparePage];
        
        leftCurrentPageY = currentPageY;
        
        int tempCurrentPageY = currentPageY;
    
    
        
        
        CGAffineTransform transImage = CGAffineTransformMake(1, 0, 0, -1, 0, floor(params.contentRect.size.height));
    if(context != nil)
        CGContextConcatCTM(context, transImage);
    
    [self printPageHeader];
        
        //finish previous sections... they may still not be done with this page...
        if(![self finishSectionsFromPreviousPage])
        return;
    
    NSArray *loads = nil, *items = nil, *sortedItems = nil, *unloads = nil, *sorts = nil;
    
    @try
    {
        if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
        {
            
            NSString *currentLotNum = @"";
            int progressCounter = -1;
            printingMissingItems = FALSE;
            lotNums = [[NSMutableArray alloc] init];
            tapeColors = [[NSMutableArray alloc] init];
            numsFrom = [[NSMutableArray alloc] init];
            numsTo = [[NSMutableArray alloc] init];
            NSDictionary *colors = [del.surveyDB getPVOColors];
            countDelivered = 0;
            
            sorts = [NSArray arrayWithObjects:
                     [[NSSortDescriptor alloc] initWithKey:@"lotNumber" ascending:YES],
                     [[NSSortDescriptor alloc] initWithKey:@"itemNumber" ascending:YES],
                     nil];
            
            BOOL newPagePerLot = [[del.surveyDB getPVOData:del.customerID] newPagePerLot];
            
            loads = [del.surveyDB getPVOLocationsForCust:custID];
            unloads = [del.surveyDB getPVOUnloads:custID];
            
            // Packers Inventory
            printingPackersInventory = TRUE;
            BOOL printedPackerStart = FALSE;
            for (int x=0; x < [loads count]; x++)
            {
                PVOInventoryLoad *load = [loads objectAtIndex:x];
                if (load.pvoLocationID == 7)
                {
                    pvoLoadID = load.pvoLoadID;
                    
                    sprCheck = FALSE;
                    dvrCheck = FALSE;
                    whsCheck = FALSE;
                    
                    items = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                    sortedItems = [items sortedArrayUsingDescriptors:sorts];
                    
                    if([sortedItems count] > 0 && !printedPackerStart)
                    {
                        printedPackerStart = TRUE;
                        progressCounter++;
                        
                        if (![self printSection:@selector(invItemsStart) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                    
                    for (int y = 0; y < [sortedItems count]; y++)
                    {
                        myItem = [sortedItems objectAtIndex:y];
                        
                        if (myItem.lotNumber != nil && ![currentLotNum isEqualToString:myItem.lotNumber])
                        {
                            currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                            
                            progressCounter++;
                            printingPackersInventory = FALSE;
                            if (![self printSection:@selector(invItemsStart) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            {
                                printingPackersInventory = TRUE;
                                goto endPage;
                            }
                            printingPackersInventory = TRUE;
                        }
                        
                        if (myItem.lotNumber != nil && ![lotNums containsObject:myItem.lotNumber] && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + 1))
                        {
                            if (y > 0 && [lotNums count] > 0)
                                [numsTo addObject:[[sortedItems objectAtIndex:(y-1)] fullItemNumber]];
                            if (y == 0 || [lotNums count] == 0 || ![lotNums containsObject:myItem.lotNumber])
                            {
                                [lotNums addObject:myItem.lotNumber];
                                [numsFrom addObject:myItem.fullItemNumber];
                            }
                        }
                        
                        if (![tapeColors containsObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]] && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + 1))
                            [tapeColors addObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]];
                        
                        if ([numsFrom count] == 0 && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + 1))
                            [numsFrom addObject:myItem.fullItemNumber];
                        
                        progressCounter++;
                        if (![self printSection:@selector(invItem) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        {
                            if (y > 0)
                            {
                                PVOItemDetail *item = [sortedItems objectAtIndex:(y - 1)];
                                [numsTo addObject:item.fullItemNumber];
                            }
                            goto endPage;
                        }
                    }
                }
            }
            
            // add end inventory, finish page
            if(progressCounter >= 0)
            {
                if (docProgress < (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + 1))
                    [numsTo addObject:myItem.fullItemNumber];
                
                progressCounter++;
                if (![self printSection:@selector(invItemsEnd) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                    goto endPage;
                
                progressCounter++;
                if (docProgress < (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter))
                {
                    if (![self printSection:@selector(finishPage) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        goto endPage;
                }
            }
            
            
            currentLotNum = @"";
            printingPackersInventory = FALSE;
            int tempProgressCounter = 0;
            for (int x=0; x < [loads count]; x++)
            {
                PVOInventoryLoad *load = [loads objectAtIndex:x];
                if (load.pvoLocationID != 7)
                {
                    pvoLoadID = load.pvoLoadID;
                    
                    sprCheck = FALSE;
                    dvrCheck = FALSE;
                    whsCheck = FALSE;
                    
                    // determine WHS, DVR, SPR checkmarks
                    if (!isOrigin)
                    {
                        int unloadLocationID = [del.surveyDB getPVODeliveryType:pvoLoadID];
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
                    
                    items = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                    sortedItems = [items sortedArrayUsingDescriptors:sorts];
                    for (int y = 0; y < [sortedItems count]; y++)
                    {
                        myItem = [sortedItems objectAtIndex:y];
                        
                        if (myItem.itemIsDelivered)
                            countDelivered += myItem.quantity;
                        
                        if (myItem.lotNumber != nil && ![currentLotNum isEqualToString:myItem.lotNumber])
                        {
                            //force new page
                            if (newPagePerLot && ![currentLotNum isEqualToString:@""])
                            {
                                tempProgressCounter++;
                                if (docProgress < (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter + 1))
                                {
                                    if (![self printSection:@selector(finishPage) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter)])
                                        goto endPage;
                                    
                                    if (y > 0)
                                    {
                                        PVOItemDetail *item = [sortedItems objectAtIndex:(y - 1)];
                                        [numsTo addObject:item.fullItemNumber];
                                    }
                                }
                            }
                            
                            currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                            
                            tempProgressCounter++;
                            if (![self printSection:@selector(invItemsStart) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter)])
                                goto endPage;
                        }
                        
                        if (myItem.lotNumber != nil && ![lotNums containsObject:myItem.lotNumber] && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter + 1))
                        {
                            if (y > 0 && [lotNums count] > 0)
                                [numsTo addObject:[[sortedItems objectAtIndex:(y-1)] fullItemNumber]];
                            if (y == 0 || [lotNums count] == 0 || ![lotNums containsObject:myItem.lotNumber])
                            {
                                [lotNums addObject:myItem.lotNumber];
                                [numsFrom addObject:myItem.fullItemNumber];
                            }
                        }
                        
                        if (![tapeColors containsObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]] && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter + 1))
                            [tapeColors addObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]];
                        
                        if ([numsFrom count] == 0 && docProgress <= (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter + 1))
                            [numsFrom addObject:myItem.fullItemNumber];
                        
                        tempProgressCounter++;
                        if (![self printSection:@selector(invItem) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter)])
                        {
                            if (y > 0)
                            {
                                PVOItemDetail *item = [sortedItems objectAtIndex:(y-1)];
                                [numsTo addObject:item.fullItemNumber];
                            }
                            goto endPage;
                        }
                    }
                }
            }
            
            if (docProgress < (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + tempProgressCounter + 1))
                [numsTo addObject:myItem.fullItemNumber];
            
            bool printedItems = tempProgressCounter > 0;
            progressCounter += tempProgressCounter;
            
            progressCounter++;
            if (![self printSection:@selector(invItemsEnd) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                goto endPage;
            
            
            // missing item list
            int missingProgressCounter = 0;
            if (!isOrigin)
            {
                printingMissingItems = TRUE;
                
                sprCheck = FALSE;
                dvrCheck = FALSE;
                whsCheck = FALSE;
                
                loads = [del.surveyDB getPVOLocationsForCust:custID];
                
                for (int x = 0; x < [loads count]; x++)
                {
                    PVOInventoryLoad *load = [loads objectAtIndex:x];
                    if (load.pvoLocationID != 7)
                    {
                        pvoLoadID = load.pvoLoadID;
                        
                        items = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                        sortedItems = [items sortedArrayUsingDescriptors:sorts];
                        for (int y = 0; y < [sortedItems count]; y++)
                        {
                            myItem = [sortedItems objectAtIndex:y];
                            
                            if (!myItem.itemIsDelivered && !myItem.itemIsDeleted)
                            {
                                if (missingProgressCounter == 0)
                                { 
                                    progressCounter++;
                                    if (![self printSection:@selector(invItemsStart) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                        goto endPage;
                                }
                                
                                missingProgressCounter++;
                                if (![self printSection:@selector(invItem) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + missingProgressCounter)])
                                    goto endPage;
                            }
                        }
                    }
                }
                
                if (missingProgressCounter > 0)
                {
                    missingProgressCounter++;
                    if (![self printSection:@selector(invItemsEnd) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter + missingProgressCounter)])
                        goto endPage;
                }
            }
            progressCounter += missingProgressCounter;
            
            //wrap up last page
            [self populateCpPboSummaries];
            
            if (printedItems || missingProgressCounter > 0)
            {
                progressCounter++;
                if (docProgress < (ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter))
                {
                    if (![self printSection:@selector(finishPage) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        goto endPage;
                }
            }
            
            progressCounter++;
            if (![self printSection:@selector(invPackSummaryStart) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                goto endPage;
            
            progressCounter++;
            if (![self printSection:@selector(invPackSummaryHeader) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                goto endPage;
            
            progressCounter++;
            if (![self printSection:@selector(invPackSummaryDetail) withProgressID:(ARPIN_PVO_PROGRESS_ITEMS_BEGIN + progressCounter)])
                goto endPage;
        }
        
        if (reportID == ESIGN_AGREEMENT)
        {
            if (![self printSection:@selector(eSignPage1) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE1])
                goto endPage;
            
            if (![self printSection:@selector(eSignPage2) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE2])
                goto endPage;
            
            if (![self printSection:@selector(eSignPage3) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE3])
                goto endPage;
        }
        
        /*if (reportID == ARPIN_PVO_HIGH_VALUE_ORIGIN || reportID == ARPIN_PVO_INVENTORY_DESTINATION)
        {
            if (![self printSection:@selector(addHighValueHeader) withProgressID:ARPIN_PVO_HIGH_VALUE_HEADER])
                goto endPage;
            
            if (![self printSection:@selector(highValueItemsHeader) withProgressID:ARPIN_PVO_HIGH_VALUE_ITEMS_HEADER])
                goto endPage;
            
            int progressCounter = -1;
            
            loads = [del.surveyDB getPVOLocations:custID];
            for (int i = 0; i < [loads count]; i++)
            {
                PVOInventoryLoad *load = [loads objectAtIndex:i];
                pvoLoadID = load.pvoLoadID;
                
                rooms = [del.surveyDB getPVORooms:pvoLoadID];
                for (int j = 0; j < [rooms count]; j++)
                {
                    [myRoom release];
                    myRoom = [[rooms objectAtIndex:j] retain];
                    
                    items = [del.surveyDB getPVOItems:pvoLoadID forRoom:myRoom.room.roomID];
                    for (int k = 0; k < [items count]; k++)
                    {
                        
                        myItem = [[items objectAtIndex:k] retain];
                        
                        if (!myItem.itemIsDeleted && myItem.highValueCost > 0)
                        {
                            progressCounter++;
                            if (![self printSection:@selector(highValueItem) withProgressID:(ARPIN_PVO_HIGH_VALUE_ITEMS_BEGIN + progressCounter)])
                                goto endPage;
                        }
                    }
                }
            }
            
            if (items != nil)
                
            
            // fill blank space on last page
            int blankHeight = [self getHighValueItemHeight];
            myItem = nil;
            
            while ((params.contentRect.size.height-takeOffBottom)-currentPageY > blankHeight)
            {
                progressCounter++;
                if (![self printSection:@selector(highValueItem) withProgressID:(ARPIN_PVO_HIGH_VALUE_ITEMS_BEGIN + progressCounter)])
                    goto endPage;
            }

        }*/
    }
    @catch (NSException * e)
    {
        //NSLog([NSString stringWithFormat:@"%@", e.description]);
    }
        
        endOfDoc = TRUE;
    docProgress = 0;
    tempDocProgress = 0;

endPage:
    
        if(tempCurrentPageY != currentPageY)
    {
            [self printPageFooter];
    }
    
    if(context != nil)
    {
        UIGraphicsPopContext();
        
        CGContextRestoreGState(context);
        
        CGContextFlush(context);
    }
    
    }
    
    return TRUE;
}

// MARK: Inventory Report
-(int)addHeader:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    SurveyLocation *orig = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
    SurveyLocation *dest = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
    PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
    
    int padding = TO_PRINTER(1.);
    
    if (print)
    {
        UIImage *image1 = [UIImage imageNamed:@"Arpin.png"];
        CGSize    tmpSize1 = [image1 size];
        image1 = [SurveyAppDelegate scaleAndRotateImage:image1 withOrientation:UIImageOrientationDownMirrored];
        CGRect imageRect1 = CGRectMake(params.contentRect.origin.x + TO_PRINTER(2.), 
                                       params.contentRect.origin.y + TO_PRINTER(3.), 
                                       tmpSize1.width * 0.25, 
                                       tmpSize1.height * 0.25);
        
        [self drawImage:image1 withCGRect:imageRect1];
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
    cell.font = ARPIN_PVO_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    [section duplicateLastCell:@"website" withType:CELL_LABEL withWidth:(width * .2) withAlign:NSTextAlignmentCenter];
    
    //add values
    NSMutableArray *colVals = [[NSMutableArray alloc] init];
    [colVals addObject:[CellValue cellWithLabel:[NSString stringWithFormat:@" \r\n%@\r\n%@", @"Arpin Van Lines", @"www.Arpin.com"]]];
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
    cell.font = ARPIN_PVO_FONT;
    [section addCell:cell];
    [section duplicateLastCell:@"header" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@" \r\n%@\r\n%@",
                                @"REGISTRATION NUMBER",
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
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"GovtBOL" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    NSString *address = [NSString stringWithFormat:@"%@", orig.address1];
    if ([orig.address2 length] > 0)
        address = [NSString stringWithFormat:@"%@ %@", orig.address1, orig.address2];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", address]]]
                 withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.city]]]
                 withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.state]]]
                 withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", orig.zip]]]
                 withColName:@"Zip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", (inf.gblNumber != nil ? inf.gblNumber : @" ")]]]
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
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    cell.padding = padding;
    [section addCell:cell];
    
    [section duplicateLastCell:@"City" withType:CELL_LABEL withWidth:(width * .15)];
    [section duplicateLastCell:@"State" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"Zip" withType:CELL_LABEL withWidth:(width * .131)];
    [section duplicateLastCell:@"VanNo" withType:CELL_LABEL withWidth:(width * .2)];
    
    //add values
    address = [NSString stringWithFormat:@"%@", dest.address1];
    if ([dest.address2 length] > 0)
        address = [NSString stringWithFormat:@"%@ %@", dest.address1, dest.address2];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", address]]]
                 withColName:@"Address"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.city]]]
                 withColName:@"City"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.state]]]
                 withColName:@"State"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", dest.zip]]]
                 withColName:@"Zip"];
    
    NSString *tractorTrailer = [NSString stringWithFormat:@"%@", inv.tractorNumber];
    if (![tractorTrailer isEqualToString:@""] && inv.trailerNumber != nil && ![inv.trailerNumber isEqualToString:@""])
        tractorTrailer = [tractorTrailer stringByAppendingString:@" / "];
    if (inv.trailerNumber != nil && ![inv.trailerNumber isEqualToString:@""])
        tractorTrailer = [tractorTrailer stringByAppendingFormat:@"%@", inv.trailerNumber];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", tractorTrailer]]]
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
    
    
    if (driver.reportPreference == 1)
    {
        //set up section
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"header1";
        cell.cellType = CELL_LABEL;
        cell.width = ((int)((width * .018) * 4)) + ((int)(width * .04)) + ((int)(width * .288));
        cell.font = ARPIN_PVO_BOLD_FONT;
        cell.borderType = BORDER_LEFT | BORDER_RIGHT;
        cell.padding = padding;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        [section duplicateLastCell:@"header2" withType:CELL_LABEL withWidth:((int)(width * .07)) + ((int)(width * .28))];
        [section duplicateLastCell:@"header3" withType:CELL_LABEL withWidth:(width * .252)];
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:@"DESCRIPTIVE INVENTORY"]]
                     withColName:@"header1"];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:@"EXCEPTION SYMBOLS"]]
                     withColName:@"header2"];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:@"LOCATION SYMBOLS"]]
                     withColName:@"header3"];
        
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
        
        
        //set up section
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"header1";
        cell.cellType = CELL_LABEL;
        cell.width = ((int)((width * .018) * 4)) + ((int)(width * .04)) + ((int)(width * .288));
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT | BORDER_RIGHT;
        cell.padding = 0;
        [section addCell:cell];
        [section duplicateLastCell:@"header2" withType:CELL_LABEL withWidth:((int)(width * .07)) + ((int)(width * .28))];
        [section duplicateLastCell:@"header3" withType:CELL_LABEL withWidth:(width * .252)];
        
        //add values
        CellValue *blank = [CellValue cellWithLabel:@" "];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  blank,blank,blank,blank,blank,blank,blank,blank,nil]
                     withColName:@"header1"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  blank,blank,blank,blank,blank,blank,blank,blank,nil]
                     withColName:@"header2"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  blank,blank,blank,blank,blank,blank,blank,blank,nil]
                     withColName:@"header3"];
        
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
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .005;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = 0;
        [section addCell:cell];
        [section duplicateLastCell:@"code1" withType:CELL_LABEL withWidth:(width * .03)];
        [section duplicateLastCell:@"descrip1" withType:CELL_LABEL withWidth:(width * .14)];
        [section duplicateLastCell:@"code2" withType:CELL_LABEL withWidth:(width * .035)];
        [section duplicateLastCell:@"descrip2" withType:CELL_LABEL withWidth:(width * .2)];
        
        [section duplicateLastCell:@"code3" withType:CELL_LABEL withWidth:(width * .03)];
        [section duplicateLastCell:@"descrip3" withType:CELL_LABEL withWidth:(width * (.26 / 3))];
        [section duplicateLastCell:@"code4" withType:CELL_LABEL withWidth:(width * .03)];
        [section duplicateLastCell:@"descrip4" withType:CELL_LABEL withWidth:(width * (.26 / 3))];
        [section duplicateLastCell:@"code5" withType:CELL_LABEL withWidth:(width * .03)];
        [section duplicateLastCell:@"descrip5" withType:CELL_LABEL withWidth:(width * (.26 / 3))];
        
        [section duplicateLastCell:@"num6" withType:CELL_LABEL withWidth:(width * .025) withAlign:NSTextAlignmentRight];
        [section duplicateLastCell:@"descrip6" withType:CELL_LABEL withWidth:((width * (.18 / 3)) - .005) withAlign:NSTextAlignmentLeft];
        [section duplicateLastCell:@"num7" withType:CELL_LABEL withWidth:(width * .025) withAlign:NSTextAlignmentRight];
        [section duplicateLastCell:@"descrip7" withType:CELL_LABEL withWidth:(width * (.18 / 3)) withAlign:NSTextAlignmentLeft];
        [section duplicateLastCell:@"num8" withType:CELL_LABEL withWidth:(width * .025) withAlign:NSTextAlignmentRight];
        [section duplicateLastCell:@"descrip8" withType:CELL_LABEL withWidth:(width * (.18 / 3)) withAlign:NSTextAlignmentLeft];
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"BW"],
                                  [CellValue cellWithLabel:@"C"],
                                  [CellValue cellWithLabel:@"CP"],
                                  [CellValue cellWithLabel:@"PBO"],
                                  [CellValue cellWithLabel:@"CD"],
                                  [CellValue cellWithLabel:@"SW"],
                                  [CellValue cellWithLabel:@"PR"],
                                  nil]
                     withColName:@"code1"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"- Black & White TV"],
                                  [CellValue cellWithLabel:@"- Color TV"],
                                  [CellValue cellWithLabel:@"- Carrier Packed"],
                                  [CellValue cellWithLabel:@"- Packed by Owner"],
                                  [CellValue cellWithLabel:@"- Carrier Disassembled"],
                                  [CellValue cellWithLabel:@"- Stretch Wrapped"],
                                  [CellValue cellWithLabel:@"- Priority"],
                                  nil]
                     withColName:@"descrip1"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"DBO"],
                                  [CellValue cellWithLabel:@"PB"],
                                  [CellValue cellWithLabel:@"PE"],
                                  [CellValue cellWithLabel:@"PP"],
                                  [CellValue cellWithLabel:@"MCU"],
                                  [CellValue cellWithLabel:@"CU"],
                                  [CellValue cellWithLabel:@"HW"],
                                  nil]
                     withColName:@"code2"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"- Disassembled by Owner"],
                                  [CellValue cellWithLabel:@"- Professional Books"],
                                  [CellValue cellWithLabel:@"- Professional Equipment"],
                                  [CellValue cellWithLabel:@"- Professional Papers"],
                                  [CellValue cellWithLabel:@"- Mechanical Condition Unknown"],
                                  [CellValue cellWithLabel:@"- Contents & Condition Unknown"],
                                  [CellValue cellWithLabel:@"- Hardware"],
                                  nil]
                     withColName:@"descrip2"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"BE"],
                                  [CellValue cellWithLabel:@"BR"],
                                  [CellValue cellWithLabel:@"BU"],
                                  [CellValue cellWithLabel:@"CH"],
                                  [CellValue cellWithLabel:@"CR"],
                                  [CellValue cellWithLabel:@"D"],
                                  [CellValue cellWithLabel:@"F"],
                                  [CellValue cellWithLabel:@"G"],
                                  nil]
                     withColName:@"code3"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"- Bent"],
                                  [CellValue cellWithLabel:@"- Broken"],
                                  [CellValue cellWithLabel:@"- Burned"],
                                  [CellValue cellWithLabel:@"- Chipped"],
                                  [CellValue cellWithLabel:@"- Crushed"],
                                  [CellValue cellWithLabel:@"- Dented"],
                                  [CellValue cellWithLabel:@"- Faded"],
                                  [CellValue cellWithLabel:@"- Gouged"],
                                  nil]
                     withColName:@"descrip3"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"L"],
                                  [CellValue cellWithLabel:@"M"],
                                  [CellValue cellWithLabel:@"MI"],
                                  [CellValue cellWithLabel:@"MO"],
                                  [CellValue cellWithLabel:@"P"],
                                  [CellValue cellWithLabel:@"R"],
                                  [CellValue cellWithLabel:@"RU"],
                                  [CellValue cellWithLabel:@"SC"],
                                  nil]
                     withColName:@"code4"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"- Loose"],
                                  [CellValue cellWithLabel:@"- Marred"],
                                  [CellValue cellWithLabel:@"- Mildew"],
                                  [CellValue cellWithLabel:@"- Motheaten"],
                                  [CellValue cellWithLabel:@"- Peeling"],
                                  [CellValue cellWithLabel:@"- Rubbed"],
                                  [CellValue cellWithLabel:@"- Rusted"],
                                  [CellValue cellWithLabel:@"- Scratched"],
                                  nil]
                     withColName:@"descrip4"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"SH"],
                                  [CellValue cellWithLabel:@"SO"],
                                  [CellValue cellWithLabel:@"ST"],
                                  [CellValue cellWithLabel:@"S"],
                                  [CellValue cellWithLabel:@"T"],
                                  [CellValue cellWithLabel:@"W"],
                                  [CellValue cellWithLabel:@"Z"],
                                  nil]
                     withColName:@"code5"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"- Short"],
                                  [CellValue cellWithLabel:@"- Soiled"],
                                  [CellValue cellWithLabel:@"- Stained"],
                                  [CellValue cellWithLabel:@"- Stretched"],
                                  [CellValue cellWithLabel:@"- Torn"],
                                  [CellValue cellWithLabel:@"- Badly Worn"],
                                  [CellValue cellWithLabel:@"- Cracked"],
                                  nil]
                     withColName:@"descrip5"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"1."],
                                  [CellValue cellWithLabel:@"2."],
                                  [CellValue cellWithLabel:@"3."],
                                  [CellValue cellWithLabel:@"4."],
                                  [CellValue cellWithLabel:@"5."],
                                  [CellValue cellWithLabel:@"6."],
                                  [CellValue cellWithLabel:@"7."],
                                  nil]
                     withColName:@"num6"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"Arm"],
                                  [CellValue cellWithLabel:@"Bottom"],
                                  [CellValue cellWithLabel:@"Corner"],
                                  [CellValue cellWithLabel:@"Front"],
                                  [CellValue cellWithLabel:@"Left"],
                                  [CellValue cellWithLabel:@"Leg"],
                                  [CellValue cellWithLabel:@"Rear"],
                                  nil]
                     withColName:@"descrip6"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"8."],
                                  [CellValue cellWithLabel:@"9."],
                                  [CellValue cellWithLabel:@"10."],
                                  [CellValue cellWithLabel:@"11."],
                                  [CellValue cellWithLabel:@"12."],
                                  [CellValue cellWithLabel:@"13."],
                                  [CellValue cellWithLabel:@"14."],
                                  nil]
                     withColName:@"num7"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"Right"],
                                  [CellValue cellWithLabel:@"Side"],
                                  [CellValue cellWithLabel:@"Top"],
                                  [CellValue cellWithLabel:@"Veneer"],
                                  [CellValue cellWithLabel:@"Edge"],
                                  [CellValue cellWithLabel:@"Center"],
                                  [CellValue cellWithLabel:@"Inside"],
                                  nil]
                     withColName:@"descrip7"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"15."],
                                  [CellValue cellWithLabel:@"16."],
                                  [CellValue cellWithLabel:@"17."],
                                  [CellValue cellWithLabel:@"18."],
                                  [CellValue cellWithLabel:@"19."],
                                  nil]
                     withColName:@"num8"];
        
        [section addColumnValues:[NSMutableArray arrayWithObjects:
                                  [CellValue cellWithLabel:@"Seat"],
                                  [CellValue cellWithLabel:@"Drawer"],
                                  [CellValue cellWithLabel:@"Door"],
                                  [CellValue cellWithLabel:@"Shelf"],
                                  [CellValue cellWithLabel:@"Hardware"],
                                  nil]
                     withColName:@"descrip8"];
        
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
        
        
        
        if (drawn > tempDrawn)
            tempDrawn = drawn;
        else
            drawn = tempDrawn;
    }
    
    
    //set up section...
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
    cell.font = ARPIN_PVO_FONT;
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
        cell.font = ARPIN_PVO_FONT;
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
        
        tempDrawn += [section drawSection:context
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
    cell.font = ARPIN_PVO_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"blank3" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"blank4" withType:CELL_LABEL withWidth:(width * .018)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank5";
    cell.cellType = CELL_LABEL;
    cell.width = width * .04;
    cell.font = ARPIN_PVO_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank6" withType:CELL_LABEL withWidth:(width * .288)];
    [section duplicateLastCell:@"blank7" withType:CELL_LABEL withWidth:(width * .08)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ConditionsAtOrg";
    cell.cellType = CELL_LABEL;
    cell.width = width * .27;
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
    
    
    //[inv release];
    
    return drawn;
}

-(int)invItemsStart
{
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    if (printingMissingItems || printingPackersInventory)
        cell.font = ARPIN_PVO_BOLD_FONT;
    else
        cell.font = ARPIN_PVO_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .018)];
    [section duplicateLastCell:@"ItemNo" withType:CELL_LABEL withWidth:(width * .04)];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Description";
    cell.cellType = CELL_LABEL;
    cell.width = width * .288;
    if (printingMissingItems || printingPackersInventory)
        cell.font = ARPIN_PVO_BOLD_FONT;
    else
        cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    //[section duplicateLastCell:@"ConditionsAtDest" withType:CELL_LABEL withWidth:(width * .25)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
    if (printingMissingItems)
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"--- MISSING ITEMS ---"]] withColName:@"Description"];
    }
    else if(printingPackersInventory)
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"--- PACKER INVENTORY ---"]] withColName:@"Description"];
    }
    else
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"LOT"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", myItem.lotNumber]]]
                     withColName:@"Description"];
    }
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
    
    
    return drawn;
}

-(int)invItem
{
    [self updateCurrentPageY];
    
    
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
    cellWHS1.font = ARPIN_PVO_FONT;
    cellWHS1.textPosition = NSTextAlignmentCenter;
    cellWHS1.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cellWHS1];
    
    PrintCell *cellDVR = [[PrintCell alloc] initWithRes:resolution];
    cellDVR.cellName = @"DVR";
    cellDVR.cellType = CELL_LABEL;
    cellDVR.width = width * .018;
    cellDVR.font = ARPIN_PVO_FONT;
    cellDVR.textPosition = NSTextAlignmentCenter;
    cellDVR.borderType = BORDER_RIGHT;
    [section addCell:cellDVR];
    
    PrintCell *cellWHS2 = [[PrintCell alloc] initWithRes:resolution];
    cellWHS2.cellName = @"WHS2";
    cellWHS2.cellType = CELL_LABEL;
    cellWHS2.width = width * .018;
    cellWHS2.font = ARPIN_PVO_FONT;
    cellWHS2.textPosition = NSTextAlignmentCenter;
    cellWHS2.borderType = BORDER_RIGHT;
    [section addCell:cellWHS2];
    
    PrintCell *cellSPR = [[PrintCell alloc] initWithRes:resolution];
    cellSPR.cellName = @"SPR";
    cellSPR.cellType = CELL_LABEL;
    cellSPR.width = width * .018;
    cellSPR.font = ARPIN_PVO_FONT;
    cellSPR.textPosition = NSTextAlignmentCenter;
    cellSPR.borderType = BORDER_RIGHT;
    [section addCell:cellSPR];
    
    PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
    cellItemNo.cellName = @"ItemNo";
    cellItemNo.cellType = CELL_LABEL;
    cellItemNo.width = width * .04;
    if (!printingMissingItems && !printingPackersInventory && !isOrigin && !myItem.itemIsDelivered)
        cellItemNo.font = ARPIN_PVO_BOLD_FONT;
    else
        cellItemNo.font = ARPIN_PVO_FONT;
    cellItemNo.textPosition = NSTextAlignmentCenter;
    cellItemNo.borderType = BORDER_RIGHT;
    cellItemNo.wordWrap = TRUE;
    [section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
    cellDescription.cellName = @"Description";
    cellDescription.cellType = CELL_LABEL;
    cellDescription.width = width * .288;
    if (!printingMissingItems && !printingPackersInventory && !isOrigin && !myItem.itemIsDelivered)
        cellDescription.font = ARPIN_PVO_BOLD_FONT;
    else
        cellDescription.font = ARPIN_PVO_FONT;
    cellDescription.borderType = BORDER_RIGHT;
    cellDescription.wordWrap = TRUE;
    [section addCell:cellDescription];
    
    PrintCell *cellCPSWPBO = [[PrintCell alloc] initWithRes:resolution];
    cellCPSWPBO.cellName = @"CPSWPBO";
    cellCPSWPBO.cellType = CELL_LABEL;
    cellCPSWPBO.width = width * .07;
    cellCPSWPBO.font = ARPIN_PVO_FONT;
    cellCPSWPBO.textPosition = NSTextAlignmentCenter;
    cellCPSWPBO.borderType = BORDER_RIGHT;
    cellCPSWPBO.wordWrap = TRUE;
    [section addCell:cellCPSWPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
    cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
    cellConditionsAtOrg.cellType = CELL_LABEL;
    cellConditionsAtOrg.width = width * .28;
    cellConditionsAtOrg.font = ARPIN_PVO_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT;
    cellConditionsAtOrg.wordWrap = TRUE;
    [section addCell:cellConditionsAtOrg];
    
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
    cellConditionsAtDest.cellName = @"ConditionsAtDest";
    cellConditionsAtDest.cellType = CELL_LABEL;
    cellConditionsAtDest.width = width * .25;
    cellConditionsAtDest.font = ARPIN_PVO_FONT;
    cellConditionsAtDest.borderType = BORDER_NONE;
    cellConditionsAtDest.wordWrap = TRUE;
    [section addCell:cellConditionsAtDest];
    
    
    //add values
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && !myItem.itemIsDeleted && whsCheck ? @"X" : @" ")]] withColName:@"WHS1"];
    
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && !myItem.itemIsDeleted && dvrCheck ? @"X" : @" ")]] withColName:@"DVR"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    
    [section addColumnValues:
     [NSMutableArray arrayWithObject:
      [CellValue cellWithLabel:(myItem != nil && myItem.itemIsDelivered && !myItem.itemIsDeleted && sprCheck ? @"X" : @" ")]] withColName:@"SPR"];
    
    //item number
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@", myItem.fullItemNumber]]]
                 withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:myItem.fullItemNumber];
    
    //room - item descrip
    Item *item = [del.surveyDB getItem:myItem.itemID WithCustomer:del.customerID];
    Room *room = [del.surveyDB getRoom:myItem.roomID WithCustomerID:del.customerID];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@ - %@", room.roomName, item.name]]]
                 withColName:@"Description"];
    cellDescriptionHeight = [cellDescription heightWithText:[NSString stringWithFormat:@"%@ - %@", room.roomName, item.name]];
    
    //symbols
    BOOL shownCP = FALSE, shownPBO = FALSE;
    NSString *cpswpbo = @"";
    
    NSArray *symbols = [del.surveyDB getPVOItemDescriptions:myItem.pvoItemID withCustomerID:del.customerID];
    for (PVOItemDescription *symbol in symbols)
    {
        if ([symbol.descriptionCode length] > 0)
        {
            shownCP = ([symbol.descriptionCode compare:@"CP"] != 0);
            shownPBO = ([symbol.descriptionCode compare:@"PBO"] != 0);
            
            if ([cpswpbo length] > 0)
                cpswpbo = [cpswpbo stringByAppendingString:@", "];
            cpswpbo = [cpswpbo stringByAppendingString:symbol.descriptionCode];
        }
    }
    
    if (item.isCP && !shownCP)
    {
        if ([cpswpbo length] > 0)
            cpswpbo = [cpswpbo stringByAppendingString:@", "];
        cpswpbo = [cpswpbo stringByAppendingString:@"CP"];
    }
    
    if (item.isPBO && !shownPBO)
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
    
    if (!myItem.itemIsDeleted)
    {
        NSArray *itemDamages = [del.surveyDB getPVOItemDamage:myItem.pvoItemID];
        for (PVOConditionEntry *damage in itemDamages)
        {
            if (!damage.isEmpty && damage.pvoLoadID > 0)
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
        
        if (myItem.cartonContents)
        {
            NSArray *cartonContents = [del.surveyDB getPVOCartonContents:myItem.pvoItemID withCustomerID:del.customerID];
            NSString *ct = @"";
            for (PVOCartonContent *contentID in cartonContents)
            {
                PVOCartonContent *content = [del.surveyDB getPVOCartonContent:contentID.contentID withCustomerID:del.customerID];
                if ([content.description length] > 0)
                {
                    if ([ct length] > 0)
                        ct = [ct stringByAppendingString:@", "];
                    ct = [ct stringByAppendingString:content.description];
                }
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
        
        if (myItem.highValueCost > 0)
        {
            if ([conditions length] > 0)
                conditions = [conditions stringByAppendingString:@"; EXTRAORDINARY VALUE"];
            else
                conditions = @"EXTRAORDINARY VALUE";
        }
        
        
        if ((myItem.modelNumber != nil && [myItem.modelNumber length] > 0) ||
            (myItem.serialNumber != nil && [myItem.serialNumber length] > 0))
        {
            if ([conditions length] > 0)
                conditions = [conditions stringByAppendingString:@"; Notes: "];
            else
                conditions = @"Notes: ";
            
//            NSString *notes = [NSString stringWithFormat:@"%@.", (myItem.comments != nil && [myItem.comments length] > 0 ? myItem.comments : @"")];
            NSString *model = [NSString stringWithFormat:@"Model #: %@.", (myItem.modelNumber != nil && [myItem.modelNumber length] > 0 ? myItem.modelNumber : @"")];
            NSString *serial = [NSString stringWithFormat:@"Serial #: %@.", (myItem.serialNumber != nil && [myItem.serialNumber length] > 0 ? myItem.serialNumber : @"")];
            
//            conditions = [conditions stringByAppendingString:myItem.comments];
//            if ([notes length] > 1 && ([model length] > 10 || [serial length] > 11))
//                conditions = [conditions stringByAppendingString:@" "];
            if ([model length] > 10)
                conditions = [conditions stringByAppendingString:model];
            if ([model length] > 10 && [serial length] > 11)
                conditions = [conditions stringByAppendingString:@" "];
            if ([serial length] > 11)
                conditions = [conditions stringByAppendingString:serial];
        }
        
        if ([conditions length] == 0)
            conditions = @"<>";
    }
    else
    {
        if (myItem.voidReason != nil && [myItem.voidReason length] > 0)
            conditions = [NSString stringWithFormat:@"Voided Item Reason: %@", myItem.voidReason];
    }
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:conditions]] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:conditions];
    
    // conditions at destination
    conditions = @"";
    
    if (!isOrigin && !myItem.itemIsDeleted)
    {
        NSArray *itemDamages = [del.surveyDB getPVOItemDamage:myItem.pvoItemID];
        for (PVOConditionEntry *damage in itemDamages)
        {
            if (!damage.isEmpty && !(damage.pvoLoadID > 0))
            {
                NSString *loc = @"";
                for (NSString *damageLoc in [damage locationArray])
                {
                    if ([loc length] > 0)
                        loc = [loc stringByAppendingString:@"-"];
                    
                    if (!printDamageCodeOnly)
                    {
                        loc = [loc stringByAppendingString:
                               [NSString stringWithFormat:@"%@", [pvoDamageLocs objectForKey:damageLoc]]];
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
        
        if (!printingMissingItems && !printingPackersInventory && !myItem.itemIsDelivered)
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
    
    currentPageY += drawn;
    
    
    // cross out deleted item
    if (myItem.itemIsDeleted)
    {
        //set up ADDRESSES section...
        section = [[PrintSection alloc] initWithRes:resolution];
        
        //set up cells
        PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"WHS1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .018;
        cell.font = ARPIN_PVO_FONT_HALF;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        [section duplicateLastCell:@"DVR" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"WHS2" withType:CELL_LABEL withWidth:(width * .018)];
        [section duplicateLastCell:@"SPR" withType:CELL_LABEL withWidth:(width * .019)];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"ItemNo";
        cell.cellType = CELL_LABEL;
        cell.width = width * .038;
        cell.font = ARPIN_PVO_FONT_HALF;
        cell.textPosition = NSTextAlignmentCenter;
        cell.borderType = BORDER_BOTTOM;
        cell.wordWrap = FALSE;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .001;
        cell.font = ARPIN_PVO_FONT_HALF;
        cell.borderType = BORDER_NONE;
        cell.wordWrap = FALSE;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Description";
        cell.cellType = CELL_LABEL;
        cell.width = width * .286;
        cell.font = ARPIN_PVO_FONT_HALF;
        cell.borderType = BORDER_BOTTOM;
        cell.wordWrap = TRUE;
        [section addCell:cell];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"Description"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y = leftCurrentPageY;
        
        //print it, check to make sure it fit... 
        //if not, store it in the collection of items to continue...
        [section drawSection:context
                withPosition:pos
              andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
    }
    
    
    
    
    return drawn;
}

-(int)finishPage
{
    int blankHeight = [self blankInvItemRow:FALSE], drawn = 0;
    while ((params.contentRect.size.height-takeOffBottom)-currentPageY > blankHeight)
        drawn += [self blankInvItemRow:TRUE];
    if (printingPackersInventory || (cpSummaryTotal + pboSummaryTotal > 0))
        return FORCE_PAGE_BREAK;
    else
        return drawn;
}

-(int)blankInvItemRow
{
    return [self blankInvItemRow:TRUE];
}

-(int)blankInvItemRow:(BOOL)print
{
    int drawn = 0;
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DVR";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
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

-(int)invItemsEnd
{
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"WHS1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .018;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_BOLD_FONT;
    cell.borderType = BORDER_RIGHT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Description";
    cell.cellType = CELL_LABEL;
    cell.width = width * .288;
    cell.font = ARPIN_PVO_BOLD_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
    [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
    //[section duplicateLastCell:@"ConditionsAtDest" withType:CELL_LABEL withWidth:(width * .25)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               (printingMissingItems ? @"--- END MISSING ITEMS ---" : [NSString stringWithFormat:@"--- END OF%@INVENTORY ---", (printingPackersInventory ? @" PACKER " : @" ")])]]
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
    
    
    if(!isOrigin && !printingMissingItems && !printingPackersInventory)
    {
        //set up ADDRESSES section...
        section = [[PrintSection alloc] initWithRes:resolution];
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"WHS1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .018;
        cell.font = ARPIN_PVO_FONT;
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
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Description";
        cell.cellType = CELL_LABEL;
        cell.width = width * .288;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_RIGHT;
        [section addCell:cell];
        
        [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .07)];
        [section duplicateLastCell:@"ConditionsAtOrg" withType:CELL_LABEL withWidth:(width * .28)];
        //[section duplicateLastCell:@"ConditionsAtDest" withType:CELL_LABEL withWidth:(width * .25)];
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DVR"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"WHS2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SPR"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"Summary: Inventory - %@ delivered", 
                                    [SurveyAppDelegate formatDouble:countDelivered withPrecision:0]]]]
                     withColName:@"Description"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CPSWPBO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtOrg"];
        //[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtDest"];
        
        //place it
        pos = params.contentRect.origin;
        pos.y = currentPageY;
        
        //print it, check to make sure it fit... 
        //if not, store it in the collection of items to continue...
        drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
        if(drawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:section];
        
        currentPageY += drawn;
    }
    
    
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
    if (cpSummaryTotal + pboSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"FirstTitle";
    cell.cellType = CELL_LABEL;
    cell.width = width / 3.;
    cell.font = ARPIN_PVO_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    if (cpSummaryTotal > 0 && pboSummaryTotal > 0)
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .02;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"SecondTitle";
        cell.cellType = CELL_LABEL;
        cell.width = width / 3.;
        cell.font = ARPIN_PVO_FONT;
        cell.textPosition = NSTextAlignmentCenter;
        cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        [section addCell:cell];
    }
    
    //add values
    if (cpSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packing Summary - Carrier Packed"]]
                     withColName:@"FirstTitle"];
    }
    if (pboSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packing Summary - Packed By Owner"]]
                     withColName:(cpSummaryTotal > 0 ? @"SecondTitle" : @"FirstTitle")];
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
    if (cpSummaryTotal + pboSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"FirstCarton";
    cell.cellType = CELL_LABEL;
    cell.width = (width / 3.) * .75;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_BOTTOM;
    [section addCell:cell];
    [section duplicateLastCell:@"FirstQty" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    
    if (cpSummaryTotal > 0 && pboSummaryTotal > 0)
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .02;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"SecondCarton";
        cell.cellType = CELL_LABEL;
        cell.width = (width / 3.) * .75;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_BOTTOM;
        [section addCell:cell];
        [section duplicateLastCell:@"SecondQty" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    }
    
    //add values
    if (cpSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Carton"]]
                     withColName:@"FirstCarton"];
        
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Qty"]]
                     withColName:@"FirstQty"];
    }
    if (pboSummaryTotal > 0)
    {
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Carton"]]
                     withColName:(cpSummaryTotal > 0 ? @"SecondCarton" : @"FirstCarton")];
        
        [section addColumnValues:
         [NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Qty"]]
                     withColName:(cpSummaryTotal > 0 ? @"SecondQty" : @"FirstQty")];
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
    if (cpSummaryTotal + pboSummaryTotal == 0)
        return 0;
    
    //set up ADDRESSES section...
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    
    //set up cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"FirstCarton";
    cell.cellType = CELL_LABEL;
    cell.width = (width / 3.) * .75;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    [section duplicateLastCell:@"FirstQty" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    
    if (cpSummaryTotal > 0 && pboSummaryTotal > 0)
    {
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank";
        cell.cellType = CELL_LABEL;
        cell.width = width * .02;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"SecondCarton";
        cell.cellType = CELL_LABEL;
        cell.width = (width / 3.) * .75;
        cell.font = ARPIN_PVO_FONT;
        cell.borderType = BORDER_NONE;
        [section addCell:cell];
        [section duplicateLastCell:@"SecondQty" withType:CELL_LABEL withWidth:((width / 3.) * .25)];
    }
    
    //add values
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
        
        [section addColumnValues:colValsName withColName:@"FirstCarton"];
        [section addColumnValues:colValsQty withColName:@"FirstQty"];
    }
    
    if(pboSummaryTotal > 0)
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
        
        [section addColumnValues:colValsName withColName:(cpSummaryTotal > 0 ? @"SecondCarton" : @"FirstCarton")];
        [section addColumnValues:colValsQty withColName:(cpSummaryTotal > 0 ? @"SecondQty" : @"FirstQty")];
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

-(int)invFooter:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyAgent *orgAgent = [del.surveyDB getAgent:custID withAgentID:AGENT_ORIGIN];
    SurveyAgent *destAgent = [del.surveyDB getAgent:custID withAgentID:AGENT_DESTINATION];
    DriverData *driver = [del.surveyDB getDriverData];
    PVOSignature *driverSig = [del.surveyDB getPVOSignature:-1 forImageType:PVO_SIGNATURE_TYPE_DRIVER];
    PVOSignature *orgCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
    PVOSignature *destCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
    PVOInventory *invData = [del.surveyDB getPVOData:del.customerID];
    BOOL draftOrigin = !invData.inventoryCompleted;
    BOOL draftDestination = !invData.deliveryCompleted && !isOrigin;
    //[invData release];
    
    BOOL driverSigApplied = FALSE, orgCustSigApplied = FALSE, destCustSigApplied = FALSE;
    for (PVOSignature *sig in [del.surveyDB getPVOSignatures:custID])
    {
        if (sig != nil)
        {
            UIImage *img = [SyncGlobals removeUnusedImageSpace:[sig signatureData]];
            NSData *imgData = UIImagePNGRepresentation(img);
            if (imgData != nil && imgData.length > 0)
            {
                switch (sig.pvoSigTypeID) {
                    case PVO_SIGNATURE_TYPE_ORG_INVENTORY:
                        orgCustSigApplied = TRUE;
                        break;
                    case PVO_SIGNATURE_TYPE_DEST_INVENTORY:
                        destCustSigApplied = TRUE;
                        break;
                }
            }
        }
    }
    if (driverSig != nil)
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Remarks";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.9;
    cell.font = ARPIN_PVO_FONT;
    [section addCell:cell];
    
    // add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"REMARKS/\r\nEXCEPTIONS:"]] withColName:@"RemarksLabel"];
    
    NSString *notes = [del.surveyDB getCustomerNote:custID];
    if ([notes length] > 0)
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_NONE;
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
    
    NSString *temp = @"";
    for(NSString *lotNum in lotNums)
    {
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:lotNum];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"TapeLot"];
    
    temp = @"";
    for(NSString *tapeColor in tapeColors)
    {
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:tapeColor];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"TapeColor"];
    
    temp = @"";
    for(NSString *numFrom in numsFrom)
    {
        if ([temp length] > 0)
            temp = [temp stringByAppendingString:@", "];
        temp = [temp stringByAppendingString:numFrom];
    }
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:temp]] withColName:@"NumFrom"];
    
    temp = @"";
    for(NSString *numTo in numsTo)
    {
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
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
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
                               [NSString stringWithFormat:@"%@", orgAgent.code]]]
                 withColName:@"OrgAgentCode"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               [NSString stringWithFormat:@"%@", driver.driverNumber]]]
                 withColName:@"OrgDriverCode"];
    
    if (!isOrigin)
    {
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", destAgent.code]]]
                     withColName:@"DestAgentCode"];
        
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", driver.driverNumber]]]
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
    cell.font = ARPIN_PVO_FONT;
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
    
    
    
    int draftSigDrawn = drawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Sig2";
    cell.cellType = CELL_LABEL;
    cell.width = width * .39;
    cell.font = [UIFont systemFontOfSize:TO_PRINTER(5.)];
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Date2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.1;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrgDriverSig";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.39;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"OrgDriverSigDate" withType:CELL_LABEL withWidth:(width * 0.1)];
    
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.01;
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DestDriverSig";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.39;
    cell.font = ARPIN_PVO_FONT;
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
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
    cell.borderType = BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank2";
    cell.cellType = CELL_LABEL;
    cell.width = width * .01;
    cell.font = ARPIN_PVO_FONT;
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
    cell.font = ARPIN_PVO_FONT;
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
    
    
    if (draftOrigin || draftDestination)
    {
        section = [[PrintSection alloc] initWithRes:resolution];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Sig1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .39;
        cell.font = ARPIN_PVO_DRAFT_FONT;
        cell.borderType = BORDER_NONE;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"blank2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .11;
        cell.font = ARPIN_PVO_DRAFT_FONT;
        cell.borderType = BORDER_NONE;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"Sig2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .39;
        cell.font = ARPIN_PVO_DRAFT_FONT;
        cell.borderType = BORDER_NONE;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        if (draftOrigin)
        {
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"DRAFT"]] withColName:@"Sig1"];
        }
        
        if (draftDestination)
        {
            [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"DRAFT"]] withColName:@"Sig2"];
        }
        
        pos = params.contentRect.origin;
        pos.y = params.contentRect.size.height-takeOffBottom+draftSigDrawn;
        if ([cell heightWithText:@" "] > (drawn - draftSigDrawn))
            pos.y += ((drawn - draftSigDrawn) - [cell heightWithText:@" "]) / 2.;
        
        if(!print)
            draftSigDrawn += [section height];
        else
            draftSigDrawn += [section drawSection:context 
                                     withPosition:pos 
                                   andRemainingPX:params.contentRect.size.height-takeOffBottom+draftSigDrawn];
        
    }
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Version";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = ARPIN_PVO_FIVEPOINT_FONT;
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

// MARK: E-Sign Agreement
-(int)eSignPage1
{
    currentPageY += TO_PRINTER(25.);
    
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
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"1. Electronic Signature Agreement. By using your finger to sign your name on the "
                               "screen below and then clicking the \"Done\" button, you are signing this Agreement electronically. You "
                               "agree that your electronic signature is and shall be the legal equivalent of your manual signature on "
                               "this Agreement and you hereby consent to be legally bound by the terms and conditions of this Agreement. "
                               "You further agree that your use of a key pad, mouse, your finger, stylus, or other device to sign your "
                               "name and/or to select an item, button, icon or similar action, or to otherwise give AVL instructions, or "
                               "in accessing from or making any transaction with AVL regarding any agreement, acknowledgement, consent "
                               "terms, disclosures or conditions (including, but not limited to, any and all orders for service, survey "
                               "forms, estimates, bills of lading, inventory sheets, extraordinary value inventory forms, home inspection reports, "
                               "statement of charges, and claims forms) shall constitute your signature (hereafter referred to as "
                               "\"E- Signature\"), acceptance and agreement as if actually signed by you in writing. You also agree that "
                               "no certification authority or other third party verification is necessary to validate your E- Signature and "
                               "that the lack of such certification or third party verification will not in any way affect the "
                               "enforceability of your E-Signature or any resulting contract between you and AVL. You also represent that "
                               "you are authorized to enter into this Agreement for all persons who own or are authorized to access any of "
                               "your household goods and that such persons will be bound by the terms and conditions of this Agreement. "
                               "You further agree that each use of your E-Signature in obtaining an AVL service constitutes your agreement "
                               "to be bound by the terms and conditions of the AVL disclosures and agreements as they exist on the date of "
                               "your E-Signature.\r\n "]]
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
                              [CellValue cellWithLabel:@"2. Consent to Electronic Delivery. You specifically agree to receive and/or "
                               "obtain any and all AVL related \"Electronic Communications\" (defined below) via email, online "
                               "system or the like. The term \"Electronic Communications\" includes, but is not limited to, any and "
                               "all current and future notices, consent forms, information, documents, agreements, and/or disclosures "
                               "(including, but not limited to, any and all orders for service, survey forms, estimates, bills of "
                               "lading, inventory sheets, extraordinary value inventory forms, home inspection reports, statement of charges, "
                               "and claims forms) that various federal and/or state laws or regulations (or contracts in the case of "
                               "corporate accounts) require that AVL provide to you, as well as such other documents, statements, data, "
                               "records and any other communications regarding the services provided by AVL. You acknowledge that, "
                               "for your records, you are able to retain Electronic Communications by printing and/or downloading and "
                               "saving this Agreement and any other agreements and Electronic Communications, documents, or records that "
                               "you agree to using your E-Signature. You accept Electronic Communications provided via email, online "
                               "system or the like as reasonable and proper notice, for the purpose of any and all laws, rules, and "
                               "regulations (and contracts in the case of corporate accounts), and agree that such electronic form "
                               "fully satisfies any requirement that such communications be provided to you in writing or in a form "
                               "that you may keep.\r\n "]] 
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
    currentPageY += TO_PRINTER(35.);
    
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
    
    currentPageY += TO_PRINTER(35.);
    
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

//MARK: High Value
-(int)addHighValueHeader
{
    currentPageY += TO_PRINTER(10.);
    
    
    [self updateCurrentPageY];
    
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    
    
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_TOP;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"header";
    cell.cellType = CELL_LABEL;
    cell.width = width * .55;
    cell.font = HIGH_VALUE_HEADER_FONT;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Declaration\r\nItems of Extraordinary Value & Firearms"]]
                 withColName:@"header"];
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = leftCurrentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    int drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    leftCurrentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.width = width * .65;
    cell.font = EIGHTPOINT_BOLD_FONT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ARPV";
    cell.cellType = CELL_LABEL;
    cell.width = width * .25;
    cell.font = EIGHTPOINT_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               @" \r\n \r\nArpin Van Lines"]]
                 withColName:@"ARPV"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.width = width * .65;
    cell.font = EIGHTPOINT_FONT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Carrier";
    cell.cellType = CELL_LABEL;
    cell.width = width * .25;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               @"CARRIER"]]
                 withColName:@"Carrier"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    [self updateCurrentPageY];
    
    
    currentPageY += TO_PRINTER(5.);
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Shipper";
    cell.cellType = CELL_TEXT_LABEL;
    cell.width = width * .5;
    cell.font = EIGHTPOINT_FONT;
    cell.underlineValue = TRUE;
    [section addCell:cell];
    
    [section duplicateLastCell:@"RegNo" withType:CELL_TEXT_LABEL withWidth:(width * 0.35)];
    [section duplicateLastCell:@"Page1" withType:CELL_TEXT_LABEL withWidth:(width * 0.085) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"Page2" withType:CELL_TEXT_LABEL withWidth:(width * 0.065) withAlign:NSTextAlignmentCenter];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithValue:[NSString stringWithFormat:@"%@ %@", cust.firstName, cust.lastName]
                               withLabel:@"Shipper"]]
                 withColName:@"Shipper"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithValue:[NSString stringWithFormat:@"%@", inf.orderNumber]
                                             withLabel:@"Reg. #"]]
                 withColName:@"RegNo"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithValue:[NSString stringWithFormat:@"%@", [SurveyAppDelegate formatDouble:params.pageNum withPrecision:0]]
                                             withLabel:@"Page"]]
                 withColName:@"Page1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithValue:[NSString stringWithFormat:@"%@", [SurveyAppDelegate formatDouble:params.totalPages withPrecision:0]]
                                             withLabel:@" of"]]
                 withColName:@"Page2"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    currentPageY += TO_PRINTER(5.);
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"text";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = EIGHTPOINT_FONT;
    cell.underlineValue = TRUE;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"We want to make sure your prized possessions receive the best care during your "
                               "relocation with our firm. To help us make sure things go well (and to satisfy an interstate commerce "
                               "commission requirement), would you please declare:"]]
                 withColName:@"text"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.06;
    cell.font = EIGHTPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"letter" withType:CELL_LABEL withWidth:(width * 0.06) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"item" withType:CELL_LABEL withWidth:(width * 0.88) withAlign:NSTextAlignmentLeft];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"[A]\r\n[B]\r\n[C]"]]
                 withColName:@"letter"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Items with a value of $100 per pound or more.\r\n"
                               "A single item or matching sets of items with a value of $2,000 or more.\r\n"
                               "Firearms tendered for transportation must have Make, Model & Serial Number."]]
                 withColName:@"item"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"text";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = EIGHTPOINT_FONT;
    cell.underlineValue = TRUE;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Packable items of an extraordinary value and Firearms must be packed by "
                               "carrier for control, receipt, and liability. (In accordance with Federal Regulations, failure to "
                               "disclose such articles will result in limited carrier liability). Shippers are required to have "
                               "these items un-packed and acknowledge receipt at the time of delivery."]]
                 withColName:@"text"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    
    
    return drawn;
}

-(int)highValueItemsHeader
{
    [self updateCurrentPageY];
    
    
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"header";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = NINEPOINT_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"(DECLARATION PORTION)"]]
                 withColName:@"header"];
    
    //place it
    CGPoint pos = params.contentRect.origin;
    pos.y = leftCurrentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    int drawn = [section drawSection:context
                        withPosition:pos
                      andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    leftCurrentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .07;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * .27) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"blank3" withType:CELL_LABEL withWidth:(width * .28) withAlign:NSTextAlignmentCenter];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"PackCont";
    cell.cellType = CELL_LABEL;
    cell.width = width * .14;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank4";
    cell.cellType = CELL_LABEL;
    cell.width = width * .11;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_NONE;
    [section addCell:cell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DestAck";
    cell.cellType = CELL_LABEL;
    cell.width = width * .13;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packed in\r\nContainer"]] withColName:@"PackCont"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Destination\r\nAcknowledgement"]] withColName:@"DestAck"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    //set up section
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"InvNo";
    cell.cellType = CELL_LABEL;
    cell.width = width * .07;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"ItemDescrip" withType:CELL_LABEL withWidth:(width * .27) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"Condition" withType:CELL_LABEL withWidth:(width * .28) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"PackInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"OrgShipInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"DeclareValue" withType:CELL_LABEL withWidth:(width * .11) withAlign:NSTextAlignmentCenter];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"DestShipInit";
    cell.cellType = CELL_LABEL;
    cell.width = width * .13;
    cell.font = EIGHTPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    [section addCell:cell];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Inv. #\r\n "]] withColName:@"InvNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Item\r\nDescription"]] withColName:@"ItemDescrip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Condition\r\nof Item"]] withColName:@"Condition"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Packer\r\nInitials"]] withColName:@"PackInit"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Shipper\r\nInitials"]] withColName:@"OrgShipInit"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Declared\r\nValue"]] withColName:@"DeclareValue"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Shipper's\r\nInitials"]] withColName:@"DestShipInit"];
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it, check to make sure it fit... 
    //if not, store it in the collection of items to continue...
    drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:section];
    
    currentPageY += drawn;
    
    
    return drawn;
}

-(int)highValueItem
{
    [self updateCurrentPageY];
    
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *pvoDamages = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
    NSDictionary *pvoDamageLocs = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
    
    int drawn = 0, borderDrawn = 0,
    tempCurrentPageY = currentPageY,
    invNoCellHeight = 0, itemDescripCellHeight = 0, conditionCellHeight = 0,
    packInitCellHeight = 0, orgShipInitCellHeight = 0, declareValueCellHeight = 0,
    destShipInitCellHeight = 0;
    double initScale = 0.245;
    CGPoint pos;
    
    
    //set up section
    PrintSection *borderSection = [[PrintSection alloc] initWithRes:resolution];
    borderSection.borderType = BORDER_NONE;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"InvNo";
    cell.cellType = CELL_LABEL;
    cell.width = width * .07;
    cell.font = SEVENPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [borderSection addCell:cell];
    
    [borderSection duplicateLastCell:@"ItemDescrip" withType:CELL_LABEL withWidth:(width * .27) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"Condition" withType:CELL_LABEL withWidth:(width * .28) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"PackInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"OrgShipInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"DeclareValue" withType:CELL_LABEL withWidth:(width * .11) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"DestShipInit" withType:CELL_LABEL withWidth:(width * .13) withAlign:NSTextAlignmentCenter];
    
    //add values
    CellValue *blankTwo = [CellValue cellWithLabel:@" \r\n "];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"InvNo"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"ItemDescrip"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"Condition"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"PackInit"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"OrgShipInit"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"DeclareValue"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"DestShipInit"];
    
    
    //set up section
    PrintSection *hvSection = [[PrintSection alloc] initWithRes:resolution];
    hvSection.borderType = BORDER_NONE;
    
    //set up cell(s)
    PrintCell *invNoCell = [[PrintCell alloc] initWithRes:resolution];
    invNoCell.cellName = @"InvNo";
    invNoCell.cellType = CELL_LABEL;
    invNoCell.width = width * .07;
    invNoCell.font = SEVENPOINT_FONT;
    invNoCell.textPosition = NSTextAlignmentCenter;
    invNoCell.borderType = BORDER_NONE;
    [hvSection addCell:invNoCell];
    
    PrintCell *itemDescripCell = [[PrintCell alloc] initWithRes:resolution];
    itemDescripCell.cellName = @"ItemDescrip";
    itemDescripCell.cellType = CELL_LABEL;
    itemDescripCell.width = width * .27;
    itemDescripCell.font = SEVENPOINT_FONT;
    itemDescripCell.textPosition = NSTextAlignmentCenter;
    itemDescripCell.borderType = BORDER_NONE;
    [hvSection addCell:itemDescripCell];
    
    PrintCell *conditionCell = [[PrintCell alloc] initWithRes:resolution];
    conditionCell.cellName = @"Condition";
    conditionCell.cellType = CELL_LABEL;
    conditionCell.width = width * .28;
    conditionCell.font = SEVENPOINT_FONT;
    conditionCell.textPosition = NSTextAlignmentCenter;
    conditionCell.borderType = BORDER_NONE;
    [hvSection addCell:conditionCell];
    
    PrintCell *packInitCell = [[PrintCell alloc] initWithRes:resolution];
    packInitCell.cellName = @"PackInit";
    packInitCell.cellType = CELL_LABEL;
    packInitCell.width = width * .07;
    packInitCell.font = SEVENPOINT_FONT;
    packInitCell.textPosition = NSTextAlignmentCenter;
    packInitCell.borderType = BORDER_NONE;
    [hvSection addCell:packInitCell];
    
    PrintCell *orgShipInitCell = [[PrintCell alloc] initWithRes:resolution];
    orgShipInitCell.cellName = @"OrgShipInit";
    orgShipInitCell.cellType = CELL_LABEL;
    orgShipInitCell.width = width * .07;
    orgShipInitCell.font = SEVENPOINT_FONT;
    orgShipInitCell.textPosition = NSTextAlignmentCenter;
    orgShipInitCell.borderType = BORDER_NONE;
    [hvSection addCell:orgShipInitCell];
    
    PrintCell *declareValueCell = [[PrintCell alloc] initWithRes:resolution];
    declareValueCell.cellName = @"DeclareValue";
    declareValueCell.cellType = CELL_LABEL;
    declareValueCell.width = width * .11;
    declareValueCell.font = SEVENPOINT_FONT;
    declareValueCell.textPosition = NSTextAlignmentCenter;
    declareValueCell.borderType = BORDER_NONE;
    [hvSection addCell:declareValueCell];
    
    PrintCell *destShipInitCell = [[PrintCell alloc] initWithRes:resolution];
    destShipInitCell.cellName = @"DestShipInit";
    destShipInitCell.cellType = CELL_LABEL;
    destShipInitCell.width = width * .13;
    destShipInitCell.font = SEVENPOINT_FONT;
    destShipInitCell.textPosition = NSTextAlignmentCenter;
    destShipInitCell.borderType = BORDER_NONE;
    [hvSection addCell:destShipInitCell];
    
    //add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
    if (myItem != nil && myItem.highValueCost > 0)
    {
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", myItem.fullItemNumber]]]
                     withColName:@"InvNo"];
        invNoCellHeight = [invNoCell heightWithText:[NSString stringWithFormat:@"%@", myItem.fullItemNumber]];
        
        Item *item = [del.surveyDB getItem:myItem.pvoItemID WithCustomer:del.customerID];
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", item.name]]]
                     withColName:@"ItemDescrip"];
        itemDescripCellHeight = [itemDescripCell heightWithText:[NSString stringWithFormat:@"%@", item.name]];
        
        NSString *condition = @"";
        NSArray *itemDamages = [del.surveyDB getPVOItemDamage:myItem.itemID];
        for (PVOConditionEntry *damage in itemDamages)
        {
            if (!damage.isEmpty && damage.pvoLoadID > 0)
            {
                NSString *loc = @"";
                for (NSString *damageLoc in [damage locationArray])
                {
                    if ([loc length] > 0)
                        loc = [loc stringByAppendingString:@"-"];
                    loc = [loc stringByAppendingString:
                           [NSString stringWithFormat:@"%@", [pvoDamageLocs objectForKey:damageLoc]]];
                }
                
                NSString *cond = @"";
                for (NSString *damageCond in [damage conditionArray])
                {
                    if ([cond length] > 0)
                        cond = [cond stringByAppendingString:@"-"];
                    cond = [cond stringByAppendingString:
                            [NSString stringWithFormat:@"%@", [pvoDamages objectForKey:damageCond]]];
                }
                
                if ([condition length] > 0)
                    condition = [condition stringByAppendingString:@", "];
                if ([loc length] > 0)
                {
                    condition = [condition stringByAppendingString:loc];
                    if ([cond length] > 0)
                        condition = [condition stringByAppendingString:@" "];
                }
                if ([cond length] > 0)
                    condition = [condition stringByAppendingString:cond];
            }
        }
        
        if ([condition length] == 0)
            condition = @" ";
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", condition]]]
                     withColName:@"Condition"];
        conditionCellHeight = [conditionCell heightWithText:[NSString stringWithFormat:@"%@", condition]];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", 
                                    [SurveyAppDelegate formatCurrency:myItem.highValueCost withCommas:(BOOL)(myItem.highValueCost > 1)]]]]
                     withColName:@"DeclareValue"];
        declareValueCellHeight = [declareValueCell heightWithText:[NSString stringWithFormat:@"%@", 
                                                                   [SurveyAppDelegate formatCurrency:myItem.highValueCost withCommas:(BOOL)(myItem.highValueCost > 1)]]];
    }
    else
    {
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"InvNo"];
        invNoCellHeight = [invNoCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemDescrip"];
        itemDescripCellHeight = [itemDescripCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Condition"];
        conditionCellHeight = [conditionCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DeclareValue"];
        declareValueCellHeight = [declareValueCell heightWithText:@" "];
    }
    
    [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"PackInit"];
    packInitCellHeight = [packInitCell heightWithText:@" "];
    
    [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"OrgShipInit"];
    orgShipInitCellHeight = [orgShipInitCell heightWithText:@" "];
    
    [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DestShipInit"];
    destShipInitCellHeight = [destShipInitCell heightWithText:@" "];
    
    
    //calculate highest height
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:invNoCellHeight],
                                              [NSNumber numberWithInt:itemDescripCellHeight],
                                              [NSNumber numberWithInt:conditionCellHeight],
                                              [NSNumber numberWithInt:declareValueCellHeight],
                                              [NSNumber numberWithInt:packInitCellHeight],
                                              [NSNumber numberWithInt:orgShipInitCellHeight],
                                              [NSNumber numberWithInt:destShipInitCellHeight],
                                              nil]];
    
    //override all cell heights with highest
    invNoCell.overrideHeight = TRUE;
    invNoCell.cellHeight = highHeight;
    itemDescripCell.overrideHeight = TRUE;
    itemDescripCell.cellHeight = highHeight;
    conditionCell.overrideHeight = TRUE;
    conditionCell.cellHeight = highHeight;
    declareValueCell.overrideHeight = TRUE;
    declareValueCell.cellHeight = highHeight;
    packInitCell.overrideHeight = TRUE;
    packInitCell.cellHeight = highHeight;
    orgShipInitCell.overrideHeight = TRUE;
    orgShipInitCell.cellHeight = highHeight;
    destShipInitCell.overrideHeight = TRUE;
    destShipInitCell.cellHeight = highHeight;
    
    
    //if hvSection text not greater than two lines, print two line height borderSection
    if (!(highHeight >= [borderSection height]))
    {
        //place it
        pos = params.contentRect.origin;
        pos.y = leftCurrentPageY;
        
        //print it
        borderDrawn = [borderSection drawSection:context
                                    withPosition:pos
                                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
        if(borderDrawn == DIDNT_FIT_ON_PAGE)
            [self finishSectionOnNextPage:borderSection];
        
        leftCurrentPageY += borderDrawn;
        
        
        //center hvSection in borderSection if less than two line
        if (highHeight != borderDrawn)
            currentPageY += (highHeight / 2);
    }
    else
    {
        //set borders in hvSection cells, since borderSection not printed
        invNoCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        itemDescripCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        conditionCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        declareValueCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        packInitCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        orgShipInitCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        destShipInitCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    }
    
    
    
    
    //print initials
    if (myItem != nil && myItem.highValueCost > 0)
    {
        NSArray *hvInitials = [del.surveyDB getAllPVOHighValueInitials:myItem.pvoItemID];
        for (PVOHighValueInitial *hvi in hvInitials)
        {
            if ((hvi.pvoSigTypeID == PVO_HV_INITIAL_TYPE_PACKER || hvi.pvoSigTypeID == PVO_HV_INITIAL_TYPE_CUSTOMER) ||
                (!isOrigin && hvi.pvoSigTypeID == PVO_HV_INITIAL_TYPE_DEST_CUSTOMER))
            {
                NSData *imgData = UIImagePNGRepresentation([SyncGlobals removeUnusedImageSpace:[hvi signatureData]]);
                if (imgData != nil && imgData.length > 0)
                {
                    UIImage *img = [hvi signatureData];
                    CGSize tmpSize = [img size];
                    img = [SurveyAppDelegate scaleAndRotateImage:img withOrientation:UIImageOrientationDownMirrored];
                    
                    //calculate x position
                    int x = params.contentRect.origin.x + invNoCell.width + itemDescripCell.width + conditionCell.width;
                    switch (hvi.pvoSigTypeID) {
                        case PVO_HV_INITIAL_TYPE_PACKER:
                            x += ((packInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                        case PVO_HV_INITIAL_TYPE_CUSTOMER:
                            x += packInitCell.width + ((orgShipInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                        case PVO_HV_INITIAL_TYPE_DEST_CUSTOMER:
                            x += packInitCell.width + orgShipInitCell.width + declareValueCell.width + ((destShipInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                    }
                    
                    CGRect imgRect = CGRectMake(x, tempCurrentPageY+TO_PRINTER(1.), tmpSize.width * initScale, tmpSize.height * initScale);
                    [self drawImage:img withCGRect:imgRect];
                }
            }
        }
    }
    
    
    
    
    //place it
    pos = params.contentRect.origin;
    pos.y = currentPageY;
    
    //print it
    drawn = [hvSection drawSection:context
                      withPosition:pos
                    andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
    if(drawn == DIDNT_FIT_ON_PAGE)
        [self finishSectionOnNextPage:hvSection];
    
    currentPageY += drawn;
    
    
    
    
    [self updateCurrentPageY];
    
    
    if (borderDrawn > drawn)
        return borderDrawn;
    else
        return drawn;
}

-(int)getHighValueItemHeight
{
    //set up section
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cell(s)
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"InvNo";
    cell.cellType = CELL_LABEL;
    cell.width = width * .07;
    cell.font = SEVENPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"ItemDescrip" withType:CELL_LABEL withWidth:(width * .27) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"Condition" withType:CELL_LABEL withWidth:(width * .28) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"PackInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"OrgShipInit" withType:CELL_LABEL withWidth:(width * .07) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"DeclareValue" withType:CELL_LABEL withWidth:(width * .11) withAlign:NSTextAlignmentCenter];
    [section duplicateLastCell:@"DestShipInit" withType:CELL_LABEL withWidth:(width * .13) withAlign:NSTextAlignmentCenter];
    
    //add values
    CellValue *blank = [CellValue cellWithLabel:@" \r\n "];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"InvNo"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemDescrip"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Condition"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DeclareValue"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"PackInit"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"OrgShipInit"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DestShipInit"];
    
    // get height
    int height = [section height];
    
    return height;
}

-(int)highValueFooter:(BOOL)print
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyAgent *orgAgent = [del.surveyDB getAgent:custID withAgentID:AGENT_ORIGIN];
    SurveyAgent *destAgent = [del.surveyDB getAgent:custID withAgentID:AGENT_DESTINATION];
    DriverData *driver = [del.surveyDB getDriverData];
    PVOSignature *driverSig = [del.surveyDB getPVOSignature:-1 forImageType:PVO_SIGNATURE_TYPE_DRIVER];
    PVOSignature *orgCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
    PVOSignature *destCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
    
    BOOL driverSigApplied = FALSE, orgCustSigApplied = FALSE, destCustSigApplied = FALSE;
    for (PVOSignature *sig in [del.surveyDB getPVOSignatures:custID])
    {
        if (sig != nil)
        {
            UIImage *img = [SyncGlobals removeUnusedImageSpace:[sig signatureData]];
            NSData *imgData = UIImagePNGRepresentation(img);
            if (imgData != nil && imgData.length > 0)
            {
                switch (sig.pvoSigTypeID) {
                    case PVO_SIGNATURE_TYPE_ORG_INVENTORY:
                        orgCustSigApplied = TRUE;
                        break;
                    case PVO_SIGNATURE_TYPE_DEST_INVENTORY:
                        destCustSigApplied = TRUE;
                        break;
                }
            }
        }
    }
    if (driverSig != nil)
    {
        UIImage *img = [SyncGlobals removeUnusedImageSpace:[driverSig signatureData]];
        NSData *imgData = UIImagePNGRepresentation(img);
        if (imgData != nil && imgData.length > 0)
            driverSigApplied = TRUE;
    }
    
    int drawn = 0;
    double sigScale = 0.10;
    
    
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"text";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = EIGHTPOINT_FONT;
    [section addCell:cell];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"Owner / authorized representative agrees that any claim for loss or "
                               "damage must be supported by proof of value and understands the settlement for items of extra-ordinary "
                               "value will be based on the information furnished, subject to a maximum amount declared above, or "
                               "the lump sum value declared on the Uniform Household Goods Bill of Lading and Freight Bill, or "
                               "repairs or replacement, whichever results in the lower cost."]]
                 withColName:@"text"];
    
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
    
    
    
    drawn += TO_PRINTER(5.);
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"Important";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.999;
    cell.font = NINEPOINT_BOLD_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"IMPORTANT"]] withColName:@"Important"];
    
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
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_RIGHT;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"blank1";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.015;
    cell.font = EIGHTPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"text" withType:CELL_LABEL withWidth:(width * 0.97)];
    [section duplicateLastCell:@"blank2" withType:CELL_LABEL withWidth:(width * 0.015)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"• If, for any reason, you have not listed items of extraordinary "
                               "value with a value to $100 per pound or more, any liability of the carrier shall be limited "
                               "to no more than $100 per pound per article based on the item’s actual weight, limited to a "
                               "maximum amount declared on the Uniform Household Goods Bill of Lading and Freight Bill.\r\n"
                               "• Single items or matching sets of items with a value to $2,000 or more must be listed on "
                               "this form. Failure to list such items will limit carriers liability to a maximum of $1,000 "
                               "on an unlisted item, or matching sets.\r\n"
                               "• If there are no items being shipped with a value of $100 per pound per article or single "
                               "or matching sets of items with a value of $2,000 or more the word “NONE” shall be entered "
                               "in the declaration portion above.\r\n "]]
                 withColName:@"text"];
    
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
    section.borderType = BORDER_BOTTOM;
    section.borderWidth = TO_PRINTER(3.);
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"text";
    cell.cellType = CELL_LABEL;
    cell.width = width;
    cell.font = EIGHTPOINT_FONT;
    [section addCell:cell];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObjects:
                              [CellValue cellWithLabel:@"The requirement to declare items of extraordinary value was promulgated "
                               "by the Interstate Commerce Commission, and designed to protect customers as well as making the "
                               "carrier aware of the value of the items being relocated."],
                              [CellValue cellWithLabel:@"The driver will be provided the Items of Extraordinary Value / Single "
                               "items or Matching sets of items for inventory and delivery. Any items of extraordinary value "
                               "packed at origin must be unpacked by the driver at the time of delivery in your presence, and "
                               "acknowledgement of receipt signed for below."],
                              nil]
                 withColName:@"text"];
    
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
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"text1";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.45;
    cell.font = SIXPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank" withType:CELL_LABEL withWidth:(width * 0.1)];
    [section duplicateLastCell:@"text2" withType:CELL_LABEL withWidth:(width * 0.45)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"By signature below, shipper agrees this is a true and complete "
                               "list of all items tendered for transportation of an extraordinary value."]]
                 withColName:@"text1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"By the signature below, the shipper acknowledges unpacking "
                               "was performed and all goods were delivered in good condition, except as noted."]]
                 withColName:@"text2"];
    
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
    int tempDrawn = drawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    PrintCell *sigBox1Cell = [[PrintCell alloc] initWithRes:resolution];
    sigBox1Cell.cellName = @"SigBox1";
    sigBox1Cell.cellType = CELL_LABEL;
    sigBox1Cell.width = width * 0.45;
    sigBox1Cell.font = NINEPOINT_FONT;
    sigBox1Cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:sigBox1Cell];
    
    PrintCell *sigBoxBlankCell = [[PrintCell alloc] initWithRes:resolution];
    sigBoxBlankCell.cellName = @"blank";
    sigBoxBlankCell.cellType = CELL_LABEL;
    sigBoxBlankCell.width = width * 0.1;
    sigBoxBlankCell.font = NINEPOINT_FONT;
    sigBoxBlankCell.borderType = BORDER_NONE;
    [section addCell:sigBoxBlankCell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"SigBox2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.45;
    cell.font = NINEPOINT_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@" \r\n "]]
                 withColName:@"SigBox1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@" \r\n "]]
                 withColName:@"SigBox2"];
    
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
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + TO_PRINTER(1.),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * sigScale,
                                        tmpSize.height * sigScale);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && destCustSigApplied)
    {
        UIImage *custSig = [destCustSig signatureData];
        CGSize tmpSize = [custSig size];
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + sigBox1Cell.width + sigBoxBlankCell.width + TO_PRINTER(1.),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * sigScale,
                                        tmpSize.height * sigScale);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrgSigShipper";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.3;
    cell.font = SIXPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank" withType:CELL_LABEL withWidth:(width * 0.25)];
    [section duplicateLastCell:@"DestSigShipper" withType:CELL_LABEL withWidth:(width * 0.3)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"SIGNATURE OF SHIPPER OR REPRESENTATIVE"]]
                 withColName:@"OrgSigShipper"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"SIGNATURE OF SHIPPER OR REPRESENTATIVE"]]
                 withColName:@"DestSigShipper"];
    
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
    
    
    
    tempDrawn = drawn;
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    sigBox1Cell = [[PrintCell alloc] initWithRes:resolution];
    sigBox1Cell.cellName = @"SigBox1";
    sigBox1Cell.cellType = CELL_LABEL;
    sigBox1Cell.width = width * 0.45;
    sigBox1Cell.font = NINEPOINT_FONT;
    sigBox1Cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:sigBox1Cell];
    
    sigBoxBlankCell = [[PrintCell alloc] initWithRes:resolution];
    sigBoxBlankCell.cellName = @"blank";
    sigBoxBlankCell.cellType = CELL_LABEL;
    sigBoxBlankCell.width = width * 0.1;
    sigBoxBlankCell.font = NINEPOINT_FONT;
    sigBoxBlankCell.borderType = BORDER_NONE;
    [section addCell:sigBoxBlankCell];
    
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"SigBox2";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.45;
    cell.font = NINEPOINT_FONT;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
    [section addCell:cell];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@" \r\n "]]
                 withColName:@"SigBox1"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@" \r\n "]]
                 withColName:@"SigBox2"];
    
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
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + TO_PRINTER(1.),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * sigScale,
                                        tmpSize.height * sigScale);
        [self drawImage:drvSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && driverSigApplied)
    {
        UIImage *drvSig = [driverSig signatureData];
        CGSize tmpSize = [drvSig size];
        drvSig = [SurveyAppDelegate scaleAndRotateImage:drvSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + sigBox1Cell.width + sigBoxBlankCell.width + TO_PRINTER(1.),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * sigScale,
                                        tmpSize.height * sigScale);
        [self drawImage:drvSig withCGRect:custSigRect];
    }
    
    
    
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up Header cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"OrgDriver";
    cell.cellType = CELL_LABEL;
    cell.width = width * 0.3;
    cell.font = SIXPOINT_FONT;
    [section addCell:cell];
    
    [section duplicateLastCell:@"blank" withType:CELL_LABEL withWidth:(width * 0.25)];
    [section duplicateLastCell:@"DestDriver" withType:CELL_LABEL withWidth:(width * 0.3)];
    
    // add values
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"SIGNATURE OF CARRIER REPRESENTATIVE"]]
                 withColName:@"OrgDriver"];
    
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"SIGNATURE OF CARRIER REPRESENTATIVE"]]
                 withColName:@"DestDriver"];
    
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
    
    cpSummaryTotal = 0;
    pboSummaryTotal = 0;
    
    NSArray *loads = [del.surveyDB getPVOLocationsForCust:del.customerID], *items = nil;
    NSString *currentKey;
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
            }
        }
    }
}

@end
