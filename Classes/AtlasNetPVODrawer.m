//
//  AtlasNetPVODrawer
//  Survey
//
//  Created by Tony Brame on 3/8/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "AtlasNetPVODrawer.h"
#import "SurveyAppDelegate.h"
#import "PrintCell.h"
#import "CellValue.h"
#import "CustomerUtilities.h"
#import "SyncGlobals.h"
#import "PVOPrintController.h"
#import "AppFunctionality.h"

@implementation AtlasNetPVODrawer

-(NSDictionary*)availableReports
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:@"Inventory" forKey:[NSNumber numberWithInt:INVENTORY]];
    [dict setObject:@"Delivery Inventory" forKey:[NSNumber numberWithInt:DELIVERY_INVENTORY]];
    //[dict setObject:@"Load High Value" forKey:[NSNumber numberWithInt:LOAD_HIGH_VALUE]];
    [dict setObject:[NSString stringWithFormat:@"Load %@", [AppFunctionality getHighValueDescription]] forKey:[NSNumber numberWithInt:LOAD_HVI_AND_CUST_RESPONSIBILITIES]];
    [dict setObject:[NSString stringWithFormat:@"Delivery %@", [AppFunctionality getHighValueDescription]] forKey:[NSNumber numberWithInt:DEL_HIGH_VALUE]];
	
	return dict;
}

-(BOOL)getPage:(PagePrintParam*)parms
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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
        NSArray *loads = nil, *items = nil, *unloads = nil;
        BOOL docIsFinished = YES;
        
        @try
        {
            if (reportID == INVENTORY || reportID == DELIVERY_INVENTORY)
            {
                NSString *currentLotNum = @"";
                int /*numLotNumPrinted = 0,*/ progressCounter = -1;/*, numDeletedItems = 0;*/
                printingMissingItems = FALSE;
                lotNums = [[NSMutableArray alloc] init];
                tapeColors = [[NSMutableArray alloc] init];
                numsFrom = [[NSMutableArray alloc] init];
                numsTo = [[NSMutableArray alloc] init];
                NSDictionary *colors = [del.surveyDB getPVOColors];
                countDelivered = 0;
                
                loads = [del.surveyDB getPVOLocationsForCust:custID];
                unloads = [del.surveyDB getPVOUnloads:custID];
                for (int i = 0; i < [loads count]; i++)
                {
                    PVOInventoryLoad *load = [loads objectAtIndex:i];
                    pvoLoadID = load.pvoLoadID;
                    
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
                    
                    //                removed room loop to get all items for a load
                    //                rooms = [del.surveyDB getPVORooms:pvoLoadID];
                    //                for (int j = 0; j < [rooms count]; j++)
                    //                {
                    //                    [myRoom release];
                    //                    myRoom = [[rooms objectAtIndex:j] retain];
                    //
                    items = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                    for (int k = 0; k < [items count]; k++)
                    {
                        myItem = [items objectAtIndex:k];
                        
                        if (!myItem.itemIsDeleted)
                        {
                            if (![currentLotNum isEqualToString:myItem.lotNumber])
                            {
                                currentLotNum = [NSString stringWithFormat:@"%@", myItem.lotNumber];
                                //numLotNumPrinted++;
                                
                                //progressCounter = (i + j + k + (numLotNumPrinted-1)) - numDeletedItems;
                                progressCounter++;
                                if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                    goto endPage;
                            }
                            
                            if (![lotNums containsObject:myItem.lotNumber] && (docProgress - 1) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                            {
                                if (k > 0 && [lotNums count] > 0)
                                {
                                    int l = k - 1;
                                    PVOItemDetail *item = [items objectAtIndex:l];
                                    while (l > 0 && item.itemIsDeleted)
                                    {
                                        l--;
                                        item = [items objectAtIndex:l];
                                    }
                                    [numsTo addObject:item.fullItemNumber];
                                }
                                [lotNums addObject:myItem.lotNumber];
                                [numsFrom addObject:myItem.fullItemNumber];
                            }
                            
                            if (![tapeColors containsObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]] && (docProgress - 1) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                                [tapeColors addObject:[colors objectForKey:[NSNumber numberWithInt:myItem.tagColor]]];
                            
                            if ([numsFrom count] == 0 && (docProgress - 1) <= (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                                [numsFrom addObject:myItem.fullItemNumber];
                            
                            //progressCounter = (i + j + k + numLotNumPrinted) - numDeletedItems;
                            progressCounter++;
                            if (![self printSection:@selector(invItem) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            {
                                if (k > 0)
                                {
                                    int l = k - 1;
                                    PVOItemDetail *item = [items objectAtIndex:(l)];
                                    while (l > 0 && item.itemIsDeleted)
                                    {
                                        l--;
                                        item = [items objectAtIndex:l];
                                    }
                                    [numsTo addObject:item.fullItemNumber];
                                }
                                goto endPage;
                            }
                        }
                        /*else
                         numDeletedItems++;*/
                    }
                    //} removed room loop to get all items for a load
                }
                
                if(progressCounter >= 0)
                {
                    if (![numsFrom containsObject:myItem.fullItemNumber] && docProgress < (PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter))
                        [numsTo addObject:myItem.fullItemNumber];
                    
                    if (items != nil)
                        
                    
                    progressCounter++;
                    if (![self printSection:@selector(invItemsEnd) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        goto endPage;
                }
                
                
                // missing item list
                if (!isOrigin)
                {
                    printingMissingItems = TRUE;
                    int missingProgressCounter = 0;
                    
                    sprCheck = FALSE;
                    dvrCheck = FALSE;
                    whsCheck = FALSE;
                    
                    loads = [del.surveyDB getPVOLocationsForCust:custID];
                    
                    for (int i = 0; i < [loads count]; i++)
                    {
                        PVOInventoryLoad *load = [loads objectAtIndex:i];
                        pvoLoadID = load.pvoLoadID;
                        
                        //                    NSArray *rooms = [del.surveyDB getPVORooms:pvoLoadID];
                        //                    for (int j = 0; j < [rooms count]; j++)
                        //                    {
                        //                        [myRoom release];
                        //                        myRoom = [[rooms objectAtIndex:j] retain];
                        //
                        NSArray *items = [del.surveyDB getPVOItemsForLoad:pvoLoadID];
                        for (int k = 0; k < [items count]; k++)
                        {
                            myItem = [items objectAtIndex:k];
                            
                            if (!myItem.itemIsDeleted)
                            {
                                if (!myItem.itemIsDelivered)
                                {
                                    if (missingProgressCounter == 0)
                                    {
                                        progressCounter++;
                                        if (![self printSection:@selector(invItemsStart) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                                            goto endPage;
                                    }
                                    
                                    missingProgressCounter++;
                                    if (![self printSection:@selector(invItem) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter + missingProgressCounter)])
                                        goto endPage;
                                }
                            }
                        }
                        //}
                    }
                    
                 
                 
                    progressCounter += missingProgressCounter;
                    
                    if (missingProgressCounter > 0)
                    {
                        progressCounter++;
                        if (![self printSection:@selector(invItemsEnd) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                }
                
                // fill blank space on last page
                int blankHeight = [self getBlankInvItemRowHeight];
                
                while ((params.contentRect.size.height-takeOffBottom)-currentPageY > blankHeight)
                {
                    progressCounter++;
                    if (![self printSection:@selector(blankInvItemRow) withProgressID:(PVO_REPORTS_PROGRESS_ITEMS_BEGIN + progressCounter)])
                        goto endPage;
                }
            }
            
    //        if (reportID == ESIGN_AGREEMENT)
    //        {
    //            if (![self printSection:@selector(eSignPage1) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE1])
    //                goto endPage;
    //
    //            if (![self printSection:@selector(eSignPage2) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE2])
    //                goto endPage;
    //
    //            if (![self printSection:@selector(eSignPage3) withProgressID:APRIN_PVO_ESIGN_PROGRESS_PAGE3])
    //                goto endPage;
    //        }
            
    #define HIGH_VALUE_ITEMS_PER_PAGE   14
            
            if (reportID == LOAD_HVI_AND_CUST_RESPONSIBILITIES || reportID == DEL_HIGH_VALUE)
            {
                if (reportID == LOAD_HVI_AND_CUST_RESPONSIBILITIES)
                {
                    _isDeliveryHighValueDisconnectedReport = NO;
                }
                else
                {
                    _isDeliveryHighValueDisconnectedReport = YES;
                }
                
                highValueRecordCounter = (params.pageNum - 1) * HIGH_VALUE_ITEMS_PER_PAGE;

                if (params.pageNum > 1)
                {
                    // check to see if there are any more items
                    if (highValueRecordCounter >= [_highValueItems count])
                    {
                        [self printSection:@selector(highValueChecklist) withProgressID:PVO_HIGH_VALUE_ITEMS_HEADER];
                        
                        endOfDoc = YES;
                        goto endPage;
                    }
                }
                
                if (![self printSection:@selector(addHighValueHeader) withProgressID:PVO_HIGH_VALUE_HEADER])
                    goto endPage;
                
                if (![self printSection:@selector(highValueItemsHeader) withProgressID:PVO_HIGH_VALUE_ITEMS_HEADER])
                    goto endPage;
                
                int progressCounter = -1;
                
                if (params.pageNum == 1)
                {
                    self.highValueItems = [NSMutableArray array];
                    
                    loads = [del.surveyDB getPVOLocationsForCust:custID];
                    for (int i = 0; i < [loads count]; i++)
                    {
                        PVOInventoryLoad *load = [loads objectAtIndex:i];
                        pvoLoadID = load.pvoLoadID;
                        
                        NSArray *rooms = [del.surveyDB getPVORooms:pvoLoadID withCustomerID:del.customerID];
                        PVORoomSummary *myRoom = nil;
                        for (int j = 0; j < [rooms count]; j++)
                        {
                            myRoom = [rooms objectAtIndex:j];
                            
                            items = [del.surveyDB getPVOItems:pvoLoadID forRoom:myRoom.room.roomID];
                            for (int k = 0; k < [items count]; k++)
                            {
                                myItem = [items objectAtIndex:k];
                                
                                if (!myItem.itemIsDeleted && myItem.highValueCost > 0)
                                {
                                    [_highValueItems addObject:myItem];
    //                                progressCounter++;
    //                                if (![self printSection:@selector(highValueItem) withProgressID:(ARPIN_PVO_HIGH_VALUE_ITEMS_BEGIN + progressCounter)])
    //                                    goto endPage;
                                }
                            }
                        }
                    }
                }
                
                int recordCounter = 0;
                progressCounter = -1;
                for (int k = highValueRecordCounter; k < [_highValueItems count]; k++)
                {
                    if (recordCounter < HIGH_VALUE_ITEMS_PER_PAGE)
                    {
                        myItem = _highValueItems[k];
                        if (![self printSection:@selector(highValueItem) withProgressID:(PVO_HIGH_VALUE_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                    }
                    
                    progressCounter++;
                    recordCounter++;
                }
                
                if (recordCounter < HIGH_VALUE_ITEMS_PER_PAGE)
                {
                    // fill blank space on last page
                    myItem = nil;
                    
                    while (recordCounter < HIGH_VALUE_ITEMS_PER_PAGE)
                    {
                        progressCounter++;
                        if (![self printSection:@selector(highValueItem) withProgressID:(PVO_HIGH_VALUE_ITEMS_BEGIN + progressCounter)])
                            goto endPage;
                        recordCounter++;
                    }
                }

                if (![self printSection:@selector(highValueFooter:) withProgressID:PVO_HIGH_VALUE_ITEMS_HEADER])
                    goto endPage;
                
                docIsFinished = NO;
            }
        }
        @catch (NSException * e) { }
        
        endOfDoc = docIsFinished;
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
	
    int padding = TO_PRINTER(1.);
	NSString *vanLineText = @"";
	
	if (print)
    {
        double scale = 1;
        switch ([del.pricingDB vanline]) {
            case ATLAS:
                vanLineText = @"AtlasLogoBW.png";
                scale = 0.18;
                break;
            default:
                vanLineText = @"";
                break;
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
	//cell.padding = 3;
	cell.underlineValue = FALSE;
	cell.width = width * .1;
	cell.font = PVO_REPORT_BOLD_FONT;
    cell.textPosition = NSTextAlignmentLeft;
	[section addCell:cell];
	
    
    PrintCell *addressheader = [[PrintCell alloc] initWithRes:resolution];
	addressheader.cellName = @"addressheader";
	addressheader.cellType = CELL_LABEL;
	//address.padding = 3;
	addressheader.underlineValue = FALSE;
	addressheader.width = width * .2;
	addressheader.font = PVO_REPORT_FIVEPOINT_FONT;
    addressheader.textPosition = NSTextAlignmentLeft;
	[section addCell:addressheader];
    
	[section duplicateLastCell:@"website" withType:CELL_LABEL withWidth:(width * .2) withAlign:NSTextAlignmentCenter];
	
	//add values
    
        
    vanLineText = @"";
    switch ([del.pricingDB vanline]) {
        case ARPIN:
            vanLineText = [NSString stringWithFormat:@" \r\n%@\r\n%@", @"Arpin Van Lines", @"www.Arpin.com"];
            break;
        case MAYFLOWER:
            vanLineText = [NSString stringWithFormat:@" \r\n%@\r\n%@", @"Mayflower Van Lines", @"www.mayflower.com"];
            break;
        case UNIGROUP:
        case UNITED:
            vanLineText = [NSString stringWithFormat:@" \r\n%@\r\n%@", @"United Van Lines", @"www.UnitedVanLines.com"];
            break;
        //case ATLAS:
            //vanLineText = [NSString stringWithFormat:@" \r\n%@\r\n%@", @"Atlas Van Lines", @"www.AtlasVanLines.com"];
            //break;
        default:
            vanLineText = @"";
            break;
    }
    
    CellValue *blank = [CellValue cellWithLabel:@"ATLAS VAN LINES, INC. \r\n 121 St. George Road \r\n P.O. Box 509 \r\n Evansville, IN 47703 \r\n Tele:(800)252-8885 \r\n MC-79658"];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"addressheader"];

    
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
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", @" "]]]
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
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" Van No."]] withColName:@"VanNo"];
	
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
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"    %@", driver.unitNumber]]]
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
    
	if (driver.reportPreference == PVO_DRIVER_REPORT_CODES && [AppFunctionality showCodesOnInventoryReport])
    {
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE SYMBOLS";
        cell.cellType = CELL_LABEL;
        cell.width = width * .4;
        cell.font = EIGHTPOINT_BOLD_FONT;
        cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        cell.padding = padding;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        
        
        
        [section duplicateLastCell:@"EXCEPTION SYMBOLS" withType:CELL_LABEL withWidth:(width * .35)];
        [section duplicateLastCell:@"LOCATION SYMBOLS" withType:CELL_LABEL withWidth:(width * .25)];
            
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"DESCRIPTIVE SYMBOLS"]] withColName:@"DESCRIPTIVE SYMBOLS"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"EXCEPTION SYMBOLS"]] withColName:@"EXCEPTION SYMBOLS"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"LOCATION SYMBOLS"]] withColName:@"LOCATION SYMBOLS"];
            
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BW";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLACK & WHITE";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        

        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE DBO";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
            
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE DISASSEMBLED BY OWNER";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BE";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BENT";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION M";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION MARRED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        

        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SH";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SHORT";
        cell.cellType = CELL_LABEL;
        cell.width = width * .090;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        

        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 8";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 15";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  BW"]] withColName:@"DESCRIPTIVE BW"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Black & White TV"]] withColName:@"DESCRIPTIVE BLACK & WHITE"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  DBO"]] withColName:@"DESCRIPTIVE DBO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Disassembled by Owner"]] withColName:@"DESCRIPTIVE DISASSEMBLED BY OWNER"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  BE"]] withColName:@"EXCEPTION BE"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Bent"]] withColName:@"EXCEPTION BENT"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  M"]] withColName:@"EXCEPTION M"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Marred"]] withColName:@"EXCEPTION MARRED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  SH"]] withColName:@"EXCEPTION SH"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Short"]] withColName:@"EXCEPTION SHORT"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  1. Arm"]] withColName:@"LOCATION 1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"   8. Right"]] withColName:@"LOCATION 8"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  15. Seat"]] withColName:@"LOCATION 15"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE C";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE COLOR TV";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PB";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PROFESSIONAL BOOKS";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BR";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BROKEN";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION MI";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION MILDEW";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SO";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SOILED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 9";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 16";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
            
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  C"]] withColName:@"DESCRIPTIVE C"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Color TV"]] withColName:@"DESCRIPTIVE COLOR TV"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  PB"]] withColName:@"DESCRIPTIVE PB"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Professional Books"]] withColName:@"DESCRIPTIVE PROFESSIONAL BOOKS"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  BR"]] withColName:@"EXCEPTION BR"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Broken"]] withColName:@"EXCEPTION BROKEN"];    
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  MI"]] withColName:@"EXCEPTION MI"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Mildew"]] withColName:@"EXCEPTION MILDEW"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  SO"]] withColName:@"EXCEPTION SO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Soiled"]] withColName:@"EXCEPTION SOILED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  2. Bottom"]] withColName:@"LOCATION 2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"   9. Side"]] withColName:@"LOCATION 9"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  16. Drawer"]] withColName:@"LOCATION 16"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CP";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CARRIER PACKED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PE";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PROFESSIONAL EQUIPMENT";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BU";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BURNED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION MO";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION MOTHEATEN";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION ST";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION STAINED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 3";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 10";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 17";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  CP"]] withColName:@"DESCRIPTIVE CP"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Carrier Packed"]] withColName:@"DESCRIPTIVE CARRIER PACKED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  PE"]] withColName:@"DESCRIPTIVE PE"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Professional Equipment"]] withColName:@"DESCRIPTIVE PROFESSIONAL EQUIPMENT"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  BU"]] withColName:@"EXCEPTION BU"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Burned"]] withColName:@"EXCEPTION BURNED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  MO"]] withColName:@"EXCEPTION MO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Motheaten"]] withColName:@"EXCEPTION MOTHEATEN"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  ST"]] withColName:@"EXCEPTION ST"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Stained"]] withColName:@"EXCEPTION STAINED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  3. Corner"]] withColName:@"LOCATION 3"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  10. Top"]] withColName:@"LOCATION 10"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  17. Door"]] withColName:@"LOCATION 17"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PBO";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PACKED BY OWNER";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PP";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE PROFESSIONAL PAPERS";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION CH";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION CHIPPED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION P";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION PEELING";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION S";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION STRETCHED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 4";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 11";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 18";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  PBO"]] withColName:@"DESCRIPTIVE PBO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Packed by Owner"]] withColName:@"DESCRIPTIVE PACKED BY OWNER"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  PP"]] withColName:@"DESCRIPTIVE PP"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Professional PAPERS"]] withColName:@"DESCRIPTIVE PROFESSIONAL PAPERS"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  CH"]] withColName:@"EXCEPTION CH"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Chipped"]] withColName:@"EXCEPTION CHIPPED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  P"]] withColName:@"EXCEPTION P"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Peeling"]] withColName:@"EXCEPTION PEELING"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  S"]] withColName:@"EXCEPTION S"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Stretched"]] withColName:@"EXCEPTION STRETCHED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  4. Front"]] withColName:@"LOCATION 4"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  11. Veneer"]] withColName:@"LOCATION 11"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  18. Shelf"]] withColName:@"LOCATION 18"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CD";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CARRIER DISASSEMBLED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE MCU";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE MECHANICAL CONDITION UNKNOWN";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION D";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION DENTED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION R";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION RUBBED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION T";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION TOM";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 5";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 12";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 19";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  CD"]] withColName:@"DESCRIPTIVE CD"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Carrier Disassembled"]] withColName:@"DESCRIPTIVE CARRIER DISASSEMBLED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  MCU"]] withColName:@"DESCRIPTIVE MCU"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Mechanical Condition Unknown"]] withColName:@"DESCRIPTIVE MECHANICAL CONDITION UNKNOWN"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  D"]] withColName:@"EXCEPTION D"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Dented"]] withColName:@"EXCEPTION DENTED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  R"]] withColName:@"EXCEPTION R"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Rubbed"]] withColName:@"EXCEPTION RUBBED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  T"]] withColName:@"EXCEPTION T"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Tom"]] withColName:@"EXCEPTION TOM"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  5. Left"]] withColName:@"LOCATION 5"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  12. Edge"]] withColName:@"LOCATION 12"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  19. Hardware"]] withColName:@"LOCATION 19"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE SW";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE STRETCH WRAPPED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CU";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE CONTENTS & CONDITION UNKNOWN";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION F";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION FADED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION RU";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION RUSTED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION W";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BADLY WORN";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 6";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 13";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION BLANK1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  SW"]] withColName:@"DESCRIPTIVE SW"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Stretch Wrapped"]] withColName:@"DESCRIPTIVE STRETCH WRAPPED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  CU"]] withColName:@"DESCRIPTIVE CU"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Contents & Condition Unknown"]] withColName:@"DESCRIPTIVE CONTENTS & CONDITION UNKNOWN"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  F"]] withColName:@"EXCEPTION F"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Faded"]] withColName:@"EXCEPTION FADED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  RU"]] withColName:@"EXCEPTION RU"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Rusted"]] withColName:@"EXCEPTION RUSTED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  W"]] withColName:@"EXCEPTION W"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Badly Worn"]] withColName:@"EXCEPTION BADLY WORN"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  6. Leg"]] withColName:@"LOCATION 6"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  13. Center"]] withColName:@"LOCATION 13"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"LOCATION BLANK1"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK3";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK4";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION G";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION GOUGED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SC";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION SCRATCHED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION Z";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION CRACKED";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 7";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION 14";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION BLANK2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK3"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK4"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  G"]] withColName:@"EXCEPTION G"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Gouged"]] withColName:@"EXCEPTION GOUGED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  SC"]] withColName:@"EXCEPTION SC"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Scratched"]] withColName:@"EXCEPTION SCRATCHED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  Z"]] withColName:@"EXCEPTION Z"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Cracked"]] withColName:@"EXCEPTION CRACKED"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  7. Rear"]] withColName:@"LOCATION 7"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  14. Inside"]] withColName:@"LOCATION 14"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"LOCATION BLANK2"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .13;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK3";
        cell.cellType = CELL_LABEL;
        cell.width = width * .04;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"DESCRIPTIVE BLANK4";
        cell.cellType = CELL_LABEL;
        cell.width = width * .194;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION L";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION LOOSE";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BLANK1";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BLANK2";
        cell.cellType = CELL_LABEL;
        cell.width = width * .088;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BLANK3";
        cell.cellType = CELL_LABEL;
        cell.width = width * .03;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"EXCEPTION BLANK4";
        cell.cellType = CELL_LABEL;
        cell.width = width * .09;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION BLANK3";
        cell.cellType = CELL_LABEL;
        cell.width = width * .083;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_LEFT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION BLANK4";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_NONE;
        cell.padding = padding;
        [section addCell:cell];
        
        
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"LOCATION BLANK5";
        cell.cellType = CELL_LABEL;
        cell.width = width * .084;
        cell.font = SIXPOINT_FONT;
        cell.borderType = BORDER_RIGHT;
        cell.padding = padding;
        [section addCell:cell];
        
        
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK3"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"DESCRIPTIVE BLANK4"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  L"]] withColName:@"EXCEPTION L"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  -Loose"]] withColName:@"EXCEPTION LOOSE"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"EXCEPTION BLANK1"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"EXCEPTION BLANK2"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"EXCEPTION BLANK3"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"  "]] withColName:@"EXCEPTION BLANK4"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"LOCATION BLANK3"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"LOCATION BLANK4"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"LOCATION BLANK5"];
        
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
        
        
        //set up section...
        section = [[PrintSection alloc] initWithRes:resolution];
        section.borderType = BORDER_NONE;
        
        //set up cells
        cell = [[PrintCell alloc] initWithRes:resolution];
        cell.cellName = @"NOTE";
        cell.cellType = CELL_LABEL;
        cell.width = width * 1.;
        cell.font = EIGHTPOINT_BOLD_FONT;
        cell.borderType = BORDER_LEFT | BORDER_RIGHT;
        cell.padding = padding;
        cell.textPosition = NSTextAlignmentCenter;
        [section addCell:cell];
        
        
            
        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"NOTE: THE OMISSION OF THESE SYMBOLS INDICATES GOOD CONDITION EXCEPT FOR NORMAL WEAR"]] withColName:@"NOTE"];
        
        
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
        
    }
    //set up section...
    section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_NONE;
    
    //set up cells
    cell = [[PrintCell alloc] initWithRes:resolution];
    cell.cellName = @"ITEM NO.1";
    cell.cellType = CELL_LABEL;
    cell.width = width * .05;
    cell.font = SEVENPOINT_FONT;
    cell.borderType = BORDER_LEFT | BORDER_TOP | BORDER_RIGHT | BORDER_BOTTOM;
    cell.padding = padding;
    cell.textPosition = NSTextAlignmentCenter;
    [section addCell:cell];
    
    
    [section duplicateLastCell:@"ARTICLES" withType:CELL_LABEL withWidth:(width * .30)];
    [section duplicateLastCell:@"CP SW PBO" withType:CELL_LABEL withWidth:(width * .165)];
    [section duplicateLastCell:@"CONDITION AT ORGIN" withType:CELL_LABEL withWidth:(width * .20)];
    [section duplicateLastCell:@"EXCEPTIONS" withType:CELL_LABEL withWidth:(width * .287)];
    
    //add values
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"ITEM NO."]] withColName:@"ITEM NO.1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"ARTICLES\r\n "]] withColName:@"ARTICLES"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"   CP   SW   PBO\r\n "]] withColName:@"CP SW PBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"CONDITION AT ORGIN\r\n "]] withColName:@"CONDITION AT ORGIN"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"EXCEPTIONS (IF ANY) AT DESTINATION\r\n "]] withColName:@"EXCEPTIONS"];
    
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
	//set up ADDRESSES section...
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	
	//set up cells
	PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"ItemNo";
	cell.cellType = CELL_LABEL;
    cell.width = width * .05;
	cell.font = SEVENPOINT_FONT;
    cell.borderType = BORDER_TOP | BORDER_RIGHT | BORDER_BOTTOM;
    cell.padding = .1;
    cell.textPosition = NSTextAlignmentCenter;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"Description" withType:CELL_LABEL withWidth:(width * .30)];
    [section duplicateLastCell:@"CPSWPBO" withType:CELL_LABEL withWidth:(width * .165)];
    [section duplicateLastCell:@"ConditionAtOrg" withType:CELL_LABEL withWidth:(width * .20)];
    [section duplicateLastCell:@"ConditionAtDest" withType:CELL_LABEL withWidth:(width * .287)];
    
         
	//add values
	    
     
    
    if (!printingMissingItems)
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"LOT"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"%@", myItem.lotNumber]]]
                     withColName:@"Description"];
    }
    else
    {
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"--- MISSING ITEMS ---"]] withColName:@"Description"];
    }
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CPSWPBO"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionAtOrg"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionAtDest"];
	
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
    
    int cellItemNoHeight = 0, cellDescriptionHeight = 0,
    cellConditionsAtOrgHeight = 0, cellConditionsAtDestHeight = 0, cellCheckboxHeight1 = 0,
    cellCheckboxHeight2 = 0, cellCheckboxHeight3 = 0;
    
	//set up ADDRESSES section...
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	
	//set up cells   
    PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
	cellItemNo.cellName = @"ItemNo";
	cellItemNo.cellType = CELL_LABEL;
	cellItemNo.width = width * .05;
    if (!printingMissingItems && !isOrigin && !myItem.itemIsDelivered)
        cellItemNo.font = PVO_REPORT_BOLD_FONT;
    else
        cellItemNo.font = PVO_REPORT_FONT;
    cellItemNo.textPosition = NSTextAlignmentCenter;
    cellItemNo.borderType = BORDER_RIGHT | BORDER_BOTTOM;
    cellItemNo.wordWrap = TRUE;
	[section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
	cellDescription.cellName = @"Description";
	cellDescription.cellType = CELL_LABEL;
	cellDescription.width = width * .3;
    if (!printingMissingItems && !isOrigin && !myItem.itemIsDelivered)
        cellDescription.font = PVO_REPORT_BOLD_FONT;
    else
        cellDescription.font = PVO_REPORT_FONT;
    cellDescription.borderType = BORDER_RIGHT | BORDER_BOTTOM;
    cellDescription.wordWrap = TRUE;
	[section addCell:cellDescription];
    
    PrintCell *cellCheckbox = [[PrintCell alloc] initWithRes:resolution];
	cellCheckbox.cellName = @"checkbox1";
	cellCheckbox.cellType = CELL_CHECKBOX;
	cellCheckbox.width = (params.contentRect.size.width - TO_PRINTER(1.)) * .05;
	cellCheckbox.font = SIXPOINT_FONT;
    cellCheckbox.borderType = BORDER_BOTTOM;
	[section addCell:cellCheckbox];
    
    PrintCell *cellCheckbox2 = [[PrintCell alloc] initWithRes:resolution];
	cellCheckbox2.cellName = @"checkbox2";
	cellCheckbox2.cellType = CELL_CHECKBOX;
	cellCheckbox2.width = (params.contentRect.size.width - TO_PRINTER(1.)) * .052;
	cellCheckbox2.font = SIXPOINT_FONT;
    cellCheckbox2.borderType = BORDER_BOTTOM;
	[section addCell:cellCheckbox2];
	
    PrintCell *cellCheckbox3 = [[PrintCell alloc] initWithRes:resolution];
	cellCheckbox3.cellName = @"checkbox3";
	cellCheckbox3.cellType = CELL_CHECKBOX;
	cellCheckbox3.width = (params.contentRect.size.width - TO_PRINTER(1.)) * .058;
	cellCheckbox3.font = SIXPOINT_FONT;
    cellCheckbox3.borderType = BORDER_BOTTOM;
	[section addCell:cellCheckbox3];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
	cellConditionsAtOrg.cellType = CELL_LABEL;
	cellConditionsAtOrg.width = width * .2;
	cellConditionsAtOrg.font = PVO_REPORT_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT | BORDER_BOTTOM | BORDER_LEFT;
    cellConditionsAtOrg.wordWrap = TRUE;
	[section addCell:cellConditionsAtOrg];
    
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtDest.cellName = @"ConditionsAtDest";
	cellConditionsAtDest.cellType = CELL_LABEL;
	cellConditionsAtDest.width = width * .287;
	cellConditionsAtDest.font = PVO_REPORT_FONT;
    cellConditionsAtDest.borderType = BORDER_RIGHT | BORDER_BOTTOM;
    cellConditionsAtDest.wordWrap = TRUE;
	[section addCell:cellConditionsAtDest];
    
   
    
	//add values
    if (!printingMissingItems && myItem != nil && myItem.itemIsDelivered)
        countDelivered++;
    
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
    
    //[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"CP"]] withColName:@"checkbox1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"SW"]] withColName:@"checkbox2"];
    //[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"PBO"]] withColName:@"checkbox3"];
    
    
    bool cp = item.isCP;
    bool pbo = item.isPBO;
    
    
    NSArray *symbols = [del.surveyDB getPVOItemDescriptions:myItem.pvoItemID withCustomerID:del.customerID];
    for (PVOItemDescription *symbol in symbols)
    {
        if ([symbol.descriptionCode isEqualToString:@"CP"])
            cp = true;
        if ([symbol.descriptionCode isEqualToString:@"PBO"])
            pbo = true;
        
    }
    
    
    
    
    NSMutableArray *colVals = [[NSMutableArray alloc] init];
    
	if(cp)
		[colVals addObject:[CellValue cellWithValue:@"1" withLabel:@"CP"]];
	else
		[colVals addObject:[CellValue cellWithValue:@"0" withLabel:@"CP"]];
    
    [section addColumnValues:colVals withColName:@"checkbox1"];
    
    
    
    colVals = [[NSMutableArray alloc] init];
    
    if(pbo)
		[colVals addObject:[CellValue cellWithValue:@"1" withLabel:@"PBO"]];
	else
		[colVals addObject:[CellValue cellWithValue:@"0" withLabel:@"PBO"]];
    
    [section addColumnValues:colVals withColName:@"checkbox3"];
    

      
    //conditions at origin
    NSString *conditions = @"";
    
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
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingString:@"; Contents: "];
        else
            conditions = @"Contents: ";
        
        NSArray *cartonContents = [del.surveyDB getPVOCartonContents:myItem.pvoItemID withCustomerID:del.customerID];
        NSString *ct = @"";
        for (PVOCartonContent *contentID in cartonContents)
        {
            PVOCartonContent *content = [del.surveyDB getPVOCartonContent:contentID.contentID withCustomerID:del.customerID];
            if ([ct length] > 0)
                ct = [ct stringByAppendingString:@", "];
            ct = [ct stringByAppendingString:content.description];
            
        }
        
        
        conditions = [conditions stringByAppendingString:ct];
    }
    
    if (myItem.highValueCost > 0)
    {
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingString:[NSString stringWithFormat:@"; %@", [[AppFunctionality getHighValueDescription] uppercaseString]]];
        else
            conditions = [[AppFunctionality getHighValueDescription] uppercaseString];
    }
    
    PVOItemComment *originComment = [del.surveyDB getPVOItemComment:myItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
    if (originComment.comment != nil && [originComment.comment length] > 0)
    {
        if ([conditions length] > 0)
            conditions = [conditions stringByAppendingString:@"; Notes: "];
        else
            conditions = @"Notes: ";
        conditions = [conditions stringByAppendingString:originComment.comment];
    }
    
    
    if ([conditions length] == 0)
        conditions = @"<>";
    
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:conditions]] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:conditions];
    
    // conditions at destination
    conditions = @"";
    
    if (!isOrigin)
    {
        itemDamages = [del.surveyDB getPVOItemDamage:myItem.pvoItemID];
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
        
        
        if (!printingMissingItems && !myItem.itemIsDelivered)
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
                                              [NSNumber numberWithInt:cellCheckboxHeight1],
                                              [NSNumber numberWithInt:cellCheckboxHeight2],
                                              [NSNumber numberWithInt:cellCheckboxHeight3],
                                              [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                              [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                              nil]];
    
    
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCheckbox.overrideHeight = true;
    cellCheckbox.cellHeight = highHeight;
    cellCheckbox2.overrideHeight = true;
    cellCheckbox2.cellHeight = highHeight;
    cellCheckbox3.overrideHeight = true;
    cellCheckbox3.cellHeight = highHeight;
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
	
    
    
    
    
    
	
	return drawn;
}

-(int)blankInvItemRow
{
    int cellItemNoHeight = 0, cellDescriptionHeight = 0,
    cellConditionsAtOrgHeight = 0, cellConditionsAtDestHeight = 0, cellCPHeight = 0,
    cellSWHeight = 0, cellPBOHeight = 0;
    
	//set up ADDRESSES section...
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	
	//set up cells
	PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
	cellItemNo.cellName = @"ItemNo";
	cellItemNo.cellType = CELL_LABEL;
	cellItemNo.width = width * .05;
	cellItemNo.font = PVO_REPORT_FONT;
    cellItemNo.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
	cellDescription.cellName = @"Description";
	cellDescription.cellType = CELL_LABEL;
	cellDescription.width = width * .3;
	cellDescription.font = PVO_REPORT_FONT;
    cellDescription.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellDescription];
    
    PrintCell *cellCP = [[PrintCell alloc] initWithRes:resolution];
    cellCP.cellName = @"CP";
	cellCP.cellType = CELL_CHECKBOX;
	cellCP.width = width * .052;
	cellCP.font = SIXPOINT_FONT;
    cellCP.borderType = BORDER_BOTTOM;
	[section addCell:cellCP];
    
    PrintCell *cellSW = [[PrintCell alloc] initWithRes:resolution];
    cellSW.cellName = @"SW";
	cellSW.cellType = CELL_CHECKBOX;
	cellSW.width = width * .055;
	cellSW.font = SIXPOINT_FONT;
    cellSW.borderType = BORDER_BOTTOM;
	[section addCell:cellSW];
    
    PrintCell *cellPBO = [[PrintCell alloc] initWithRes:resolution];
    cellPBO.cellName = @"PBO";
	cellPBO.cellType = CELL_CHECKBOX;
	cellPBO.width = width * .06;
	cellPBO.font = SIXPOINT_FONT;
    cellPBO.borderType = BORDER_BOTTOM;
	[section addCell:cellPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
	cellConditionsAtOrg.cellType = CELL_LABEL;
	cellConditionsAtOrg.width = width * .2;
	cellConditionsAtOrg.font = PVO_REPORT_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT | BORDER_BOTTOM | BORDER_LEFT;
	[section addCell:cellConditionsAtOrg];
        
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtDest.cellName = @"ConditionsAtDest";
	cellConditionsAtDest.cellType = CELL_LABEL;
	cellConditionsAtDest.width = width * .287;
	cellConditionsAtDest.font = PVO_REPORT_FONT;
    cellConditionsAtDest.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellConditionsAtDest];
	
	//add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:@" "];
    
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Description"];
    cellDescriptionHeight = [cellDescription heightWithText:@" "];
    
	//[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"CPSWPBO"];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:@" "];
    
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtDest"];
    cellConditionsAtDestHeight = [cellConditionsAtDest heightWithText:@" "];
    
    
    CellValue *CP = [CellValue cellWithValue:@"0" withLabel:@"CP"];
    [section addColumnValues:[NSMutableArray arrayWithObject:CP] withColName:@"CP"];
    cellCPHeight = [cellCP heightWithText:@"CP"];
    CellValue *SW = [CellValue cellWithValue:@"0" withLabel:@"SW"];
    [section addColumnValues:[NSMutableArray arrayWithObject:SW] withColName:@"SW"];
    cellSWHeight = [cellSW heightWithText:@"SW "];
    CellValue *PBO = [CellValue cellWithValue:@"0" withLabel:@"PBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:PBO] withColName:@"PBO"];
    cellPBOHeight = [cellPBO heightWithText:@"PBO"];
    
    // set height overrides for highest cell
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:cellItemNoHeight],
                                              [NSNumber numberWithInt:cellDescriptionHeight],
                                              [NSNumber numberWithInt:cellCPHeight],
                                              [NSNumber numberWithInt:cellSWHeight],
                                              [NSNumber numberWithInt:cellPBOHeight],
                                              [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                              [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                              nil]];
    
    
    
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCP.overrideHeight = true;
    cellCP.cellHeight = highHeight;
    cellSW.overrideHeight = true;
    cellSW.cellHeight = highHeight;
    cellPBO.overrideHeight = true;
    cellPBO.cellHeight = highHeight;
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
	
    
	
	return drawn;
    

    
    
}

-(int)getBlankInvItemRowHeight
{
    int cellItemNoHeight = 0, cellDescriptionHeight = 0,
    cellConditionsAtOrgHeight = 0, cellConditionsAtDestHeight = 0, cellCPHeight = 0,
    cellSWHeight = 0, cellPBOHeight = 0;
    
	//set up ADDRESSES section...
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	
	//set up cells
	PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
	cellItemNo.cellName = @"ItemNo";
	cellItemNo.cellType = CELL_LABEL;
	cellItemNo.width = width * .05;
	cellItemNo.font = PVO_REPORT_FONT;
    cellItemNo.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
	cellDescription.cellName = @"Description";
	cellDescription.cellType = CELL_LABEL;
	cellDescription.width = width * .3;
	cellDescription.font = PVO_REPORT_FONT;
    cellDescription.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellDescription];
    
    PrintCell *cellCP = [[PrintCell alloc] initWithRes:resolution];
    cellCP.cellName = @"CP";
	cellCP.cellType = CELL_CHECKBOX;
	cellCP.width = width * .05;
	cellCP.font = SIXPOINT_FONT;
    cellCP.borderType = BORDER_BOTTOM;
	[section addCell:cellCP];
    
    PrintCell *cellSW = [[PrintCell alloc] initWithRes:resolution];
    cellSW.cellName = @"SW";
	cellSW.cellType = CELL_CHECKBOX;
	cellSW.width = width * .055;
	cellSW.font = SIXPOINT_FONT;
    cellSW.borderType = BORDER_BOTTOM;
	[section addCell:cellSW];
    
    PrintCell *cellPBO = [[PrintCell alloc] initWithRes:resolution];
    cellPBO.cellName = @"PBO";
	cellPBO.cellType = CELL_CHECKBOX;
	cellPBO.width = width * .06;
	cellPBO.font = SIXPOINT_FONT;
    cellPBO.borderType = BORDER_BOTTOM;
	[section addCell:cellPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
	cellConditionsAtOrg.cellType = CELL_LABEL;
	cellConditionsAtOrg.width = width * .2;
	cellConditionsAtOrg.font = PVO_REPORT_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT | BORDER_BOTTOM | BORDER_LEFT;
	[section addCell:cellConditionsAtOrg];
    
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtDest.cellName = @"ConditionsAtDest";
	cellConditionsAtDest.cellType = CELL_LABEL;
	cellConditionsAtDest.width = width * .28;
	cellConditionsAtDest.font = PVO_REPORT_FONT;
    cellConditionsAtDest.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellConditionsAtDest];
	
	//add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:@" "];
    
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"Description"];
    cellDescriptionHeight = [cellDescription heightWithText:@" "];
    
	//[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"CPSWPBO"];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:@" "];
    
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtDest"];
    cellConditionsAtDestHeight = [cellConditionsAtDest heightWithText:@" "];
    
    
    CellValue *CP = [CellValue cellWithValue:@"0" withLabel:@"CP"];
    [section addColumnValues:[NSMutableArray arrayWithObject:CP] withColName:@"CP"];
    cellCPHeight = [cellCP heightWithText:@"CP"];
    CellValue *SW = [CellValue cellWithValue:@"0" withLabel:@"SW"];
    [section addColumnValues:[NSMutableArray arrayWithObject:SW] withColName:@"SW"];
    cellSWHeight = [cellSW heightWithText:@"SW "];
    CellValue *PBO = [CellValue cellWithValue:@"0" withLabel:@"PBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:PBO] withColName:@"PBO"];
    cellPBOHeight = [cellPBO heightWithText:@"PBO"];
    
    // set height overrides for highest cell
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:cellItemNoHeight],
                                              [NSNumber numberWithInt:cellDescriptionHeight],
                                              [NSNumber numberWithInt:cellCPHeight],
                                              [NSNumber numberWithInt:cellSWHeight],
                                              [NSNumber numberWithInt:cellPBOHeight],
                                              [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                              [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                              nil]];
    
    
    
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCP.overrideHeight = true;
    cellCP.cellHeight = highHeight;
    cellSW.overrideHeight = true;
    cellSW.cellHeight = highHeight;
    cellPBO.overrideHeight = true;
    cellPBO.cellHeight = highHeight;
    cellConditionsAtOrg.overrideHeight = true;
    cellConditionsAtOrg.cellHeight = highHeight;
    cellConditionsAtDest.overrideHeight = true;
    cellConditionsAtDest.cellHeight = highHeight;

    ////calc height
	int height = [section height];
	
    
	
	return height;
    
}

-(int)invItemsEnd
{
	
    int cellItemNoHeight = 0, cellDescriptionHeight = 0,
    cellConditionsAtOrgHeight = 0, cellConditionsAtDestHeight = 0, cellCPHeight = 0,
    cellSWHeight = 0, cellPBOHeight = 0;
    
	//set up ADDRESSES section...
	PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
	
	//set up cells
	PrintCell *cellItemNo = [[PrintCell alloc] initWithRes:resolution];
	cellItemNo.cellName = @"ItemNo";
	cellItemNo.cellType = CELL_LABEL;
	cellItemNo.width = width * .05;
	cellItemNo.font = SEVENPOINT_BOLD_FONT;
    cellItemNo.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellItemNo];
    
    PrintCell *cellDescription = [[PrintCell alloc] initWithRes:resolution];
	cellDescription.cellName = @"Description";
	cellDescription.cellType = CELL_LABEL;
	cellDescription.width = width * .3;
	cellDescription.font = SEVENPOINT_BOLD_FONT;
    cellDescription.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellDescription];
    
    PrintCell *cellCP = [[PrintCell alloc] initWithRes:resolution];
    cellCP.cellName = @"CP";
	cellCP.cellType = CELL_LABEL;
	cellCP.width = width * .052;
	cellCP.font = SIXPOINT_FONT;
    cellCP.borderType = BORDER_BOTTOM;
	[section addCell:cellCP];
    
    PrintCell *cellSW = [[PrintCell alloc] initWithRes:resolution];
    cellSW.cellName = @"SW";
	cellSW.cellType = CELL_LABEL;
	cellSW.width = width * .055;
	cellSW.font = SIXPOINT_FONT;
    cellSW.borderType = BORDER_BOTTOM;
	[section addCell:cellSW];
    
    PrintCell *cellPBO = [[PrintCell alloc] initWithRes:resolution];
    cellPBO.cellName = @"PBO";
	cellPBO.cellType = CELL_LABEL;
	cellPBO.width = width * .06;
	cellPBO.font = SIXPOINT_FONT;
    cellPBO.borderType = BORDER_BOTTOM;
	[section addCell:cellPBO];
    
    PrintCell *cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
	cellConditionsAtOrg.cellType = CELL_LABEL;
	cellConditionsAtOrg.width = width * .2;
	cellConditionsAtOrg.font = PVO_REPORT_FONT;
    cellConditionsAtOrg.borderType = BORDER_RIGHT | BORDER_BOTTOM | BORDER_LEFT;
	[section addCell:cellConditionsAtOrg];
    
    PrintCell *cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
	cellConditionsAtDest.cellName = @"ConditionsAtDest";
	cellConditionsAtDest.cellType = CELL_LABEL;
	cellConditionsAtDest.width = width * .287;
	cellConditionsAtDest.font = PVO_REPORT_FONT;
    cellConditionsAtDest.borderType = BORDER_RIGHT | BORDER_BOTTOM;
	[section addCell:cellConditionsAtDest];
	
	//add values
    CellValue *blank = [CellValue cellWithLabel:@" "];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
    cellItemNoHeight = [cellItemNo heightWithText:@" "];
    
    
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:
                               (printingMissingItems ? @"--- END MISSING ITEMS ---" : @"--- END OF INVENTORY ---")]]
                 withColName:@"Description"];
    cellDescriptionHeight = [cellDescription heightWithText:@" "];
    
     
     
	//[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"CPSWPBO"];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"CP"];
    cellCPHeight = [cellCP heightWithText:@" "];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"SW"];
    cellSWHeight = [cellSW heightWithText:@" "];
    [section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"PBO"];
    cellPBOHeight = [cellPBO heightWithText:@" "];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtOrg"];
    cellConditionsAtOrgHeight = [cellConditionsAtOrg heightWithText:@" "];
	[section addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionsAtDest"];
    cellConditionsAtDestHeight = [cellConditionsAtDest heightWithText:@" "];
    
    
    
    // set height overrides for highest cell
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:cellItemNoHeight],
                                              [NSNumber numberWithInt:cellDescriptionHeight],
                                              [NSNumber numberWithInt:cellCPHeight],
                                              [NSNumber numberWithInt:cellSWHeight],
                                              [NSNumber numberWithInt:cellPBOHeight],
                                              [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                              [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                              nil]];
    
    
    
    cellItemNo.overrideHeight = true;
    cellItemNo.cellHeight = highHeight;
    cellDescription.overrideHeight = true;
    cellDescription.cellHeight = highHeight;
    cellCP.overrideHeight = true;
    cellCP.cellHeight = highHeight;
    cellSW.overrideHeight = true;
    cellSW.cellHeight = highHeight;
    cellPBO.overrideHeight = true;
    cellPBO.cellHeight = highHeight;
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
	
    
    
    if(!isOrigin && !printingMissingItems)
    {
        //set up ADDRESSES section...
        section = [[PrintSection alloc] initWithRes:resolution];
        
        //set up cells
        cellItemNo = [[PrintCell alloc] initWithRes:resolution];
        cellItemNo.cellName = @"ItemNo";
        cellItemNo.cellType = CELL_LABEL;
        cellItemNo.width = width * .05;
        cellItemNo.font = PVO_REPORT_FONT;
        cellItemNo.borderType = BORDER_RIGHT;
        cellItemNo.textPosition = NSTextAlignmentCenter;
        [section addCell:cellItemNo];
        
        
        cellDescription = [[PrintCell alloc] initWithRes:resolution];
        cellDescription.cellName = @"Description";
        cellDescription.cellType = CELL_LABEL;
        cellDescription.width = width * .3;
        cellDescription.font = PVO_REPORT_FONT;
        cellDescription.borderType = BORDER_RIGHT;
        [section addCell:cellDescription];
        
        cellCP = [[PrintCell alloc] initWithRes:resolution];
        cellCP.cellName = @"CP";
        cellCP.cellType = CELL_LABEL;
        cellCP.width = width * .052;
        cellCP.font = PVO_REPORT_FONT;
        cellCP.borderType = BORDER_RIGHT;
        [section addCell:cellCP];

        cellSW = [[PrintCell alloc] initWithRes:resolution];
        cellSW.cellName = @"SW";
        cellSW.cellType = CELL_LABEL;
        cellSW.width = width * .055;
        cellSW.font = PVO_REPORT_FONT;
        cellSW.borderType = BORDER_RIGHT;
        [section addCell:cellSW];

        cellPBO = [[PrintCell alloc] initWithRes:resolution];
        cellPBO.cellName = @"CP";
        cellPBO.cellType = CELL_LABEL;
        cellPBO.width = width * .06;
        cellPBO.font = PVO_REPORT_FONT;
        cellPBO.borderType = BORDER_RIGHT;
        [section addCell:cellPBO];

        cellConditionsAtOrg = [[PrintCell alloc] initWithRes:resolution];
        cellConditionsAtOrg.cellName = @"ConditionsAtOrg";
        cellConditionsAtOrg.cellType = CELL_LABEL;
        cellConditionsAtOrg.width = width * .2;
        cellConditionsAtOrg.font = PVO_REPORT_FONT;
        cellConditionsAtOrg.borderType = BORDER_RIGHT;
        [section addCell:cellConditionsAtOrg];

        cellConditionsAtDest = [[PrintCell alloc] initWithRes:resolution];
        cellConditionsAtDest.cellName = @"ConditionsAtDest";
        cellConditionsAtDest.cellType = CELL_LABEL;
        cellConditionsAtDest.width = width * .287;
        cellConditionsAtDest.font = PVO_REPORT_FONT;
        cellConditionsAtDest.borderType = BORDER_RIGHT;
        [section addCell:cellConditionsAtDest];
        

        //add values
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"XXX"]] withColName:@"ItemNo"];
        [section addColumnValues:[NSMutableArray arrayWithObject:
                                  [CellValue cellWithLabel:
                                   [NSString stringWithFormat:@"Summary: Inventory - %@ delivered",
                                    [SurveyAppDelegate formatDouble:countDelivered withPrecision:0]]]]
                     withColName:@"Description"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"CP"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"SW"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"PBO"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtOrg"];
        [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@" "]] withColName:@"ConditionsAtDest"];
     
     
        
        // set height overrides for highest cell
        int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                                  [NSNumber numberWithInt:cellItemNoHeight],
                                                  [NSNumber numberWithInt:cellDescriptionHeight],
                                                  [NSNumber numberWithInt:cellCPHeight],
                                                  [NSNumber numberWithInt:cellSWHeight],
                                                  [NSNumber numberWithInt:cellPBOHeight],
                                                  [NSNumber numberWithInt:cellConditionsAtOrgHeight],
                                                  [NSNumber numberWithInt:cellConditionsAtDestHeight],
                                                  nil]];
        
        
        
        cellItemNo.overrideHeight = true;
        cellItemNo.cellHeight = highHeight;
        cellDescription.overrideHeight = true;
        cellDescription.cellHeight = highHeight;
        cellCP.overrideHeight = true;
        cellCP.cellHeight = highHeight;
        cellSW.overrideHeight = true;
        cellSW.cellHeight = highHeight;
        cellPBO.overrideHeight = true;
        cellPBO.cellHeight = highHeight;
        cellConditionsAtOrg.overrideHeight = true;
        cellConditionsAtOrg.cellHeight = highHeight;
        cellConditionsAtDest.overrideHeight = true;
        cellConditionsAtDest.cellHeight = highHeight;
        

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
     

-(int)invFooter:(BOOL)print
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
    
    
    PrintSection *section = [[PrintSection alloc] initWithRes:resolution];
    section.borderType = BORDER_BOTTOM;
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
    section.borderType = BORDER_TOP;
	
	//set up Header cells
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"TapeLotLabel";
	cell.cellType = CELL_LABEL;
	cell.width = width * .08;
	cell.font = PVO_REPORT_FONT;
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
    section.borderType = BORDER_LEFT | BORDER_RIGHT;
	
	//set up Header cells
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"LEGAL1";
	cell.cellType = CELL_LABEL;
	cell.width = width * 0.499;
	cell.font = EIGHTPOINT_BOLD_FONT;
    cell.borderType = BORDER_ALL;
	[section addCell:cell];
	
    
    [section duplicateLastCell:@"LEGAL2" withType:CELL_LABEL withWidth:(width * 0.499)];
    
	
	// add values
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Customer's signature at origin confirms the piece count and condition of goods released to the carrier. \r\n "]] withColName:@"LEGAL1"];
    [section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"Customer's signature at destination means all items loaded have been received and obvious loss or damage has been noted. Signing the inventory does not waive any right to file a claim. "]] withColName:@"LEGAL2"];
    
    
	
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
	
	

    //UIImage *img = [SyncGlobals removeUnusedImageSpace:[driverSig signatureData]];

    
    // customer signatures
    if (print && orgCustSigApplied)
    {
        //UIImage *custSig = [[orgCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[orgCustSig signatureData]];
        CGSize tmpSize = [custSig size];
        if (tmpSize.height > tmpSize.width) tmpSize.height = tmpSize.width;
        
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(params.contentRect.origin.x + (width * 0.2),
                                        params.contentRect.size.height-takeOffBottom+tempDrawn+TO_PRINTER(1.),
                                        tmpSize.width * 0.14,
                                        tmpSize.height * 0.14);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && destCustSigApplied)
    {
        //UIImage *custSig = [[destCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[destCustSig signatureData]];
        CGSize tmpSize = [custSig size];
        if (tmpSize.height > tmpSize.width) tmpSize.height = tmpSize.width;
        
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

//MARK: High Value
-(int)addHighValueHeader
{
    currentPageY += TO_PRINTER(10.);
    [self updateCurrentPageY];
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
	SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
	PrintSection *section;
    CGPoint pos;
    PrintCell *cell;
    int drawn;
    CGFloat tempY;
    
    // ============================================================================================
    
    // Atlas logo
    NSString *vanLineText;
    double scale = 1;
    CGSize imageSize = CGSizeZero;
    switch ([del.pricingDB vanline])
    {
        case ATLAS:
            vanLineText = @"AtlasLogoBW.png";
            scale = 0.18;
            break;
        default:
            vanLineText = @"";
            break;
    }
    
    if ([vanLineText length] > 0)
    {
        UIImage *image1 = [UIImage imageNamed:vanLineText];
        CGSize	tmpSize1 = [image1 size];
        image1 = [SurveyAppDelegate scaleAndRotateImage:image1 withOrientation:UIImageOrientationDownMirrored];
        CGRect imageRect1 = CGRectMake(params.contentRect.origin.x + TO_PRINTER(2.),
                                       leftCurrentPageY,
                                       tmpSize1.width * scale,
                                       tmpSize1.height * scale);
        
        [self drawImage:image1 withCGRect:imageRect1];
        
        imageSize = CGSizeMake(tmpSize1.width * scale, tmpSize1.height * scale);
    }
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .25;
	cell.font = SEVENPOINT_FONT;
	[section addCell:cell];
	
	
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"U.S. DOT No. 125550"]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.y = leftCurrentPageY + (imageSize.height + TO_PRINTER(8.0));
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
    CGFloat yAfterImage = pos.y + drawn;
	

    // ============================================================================================
    
    // report title and Atlas address
    CGFloat addressX = width * 0.2;
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .25;
	cell.font = NINEPOINT_FONT;
	[section addCell:cell];
	
	
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"%@ INVENTORY FORM",
                                                        [[AppFunctionality getHighValueDescription] uppercaseString]]]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.x = addressX;
    pos.y = leftCurrentPageY;
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	tempY = leftCurrentPageY + drawn;
	
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .25;
	cell.font = SIXPOINT_FONT;
	[section addCell:cell];
	
	
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"ATLAS VAN LINES, INC.\r\n1212 ST. GEORGE ROAD, P.O. BOX 509\r\nEVANSVILLE, IN 47703\r\n(800) 252-8885 / (812) 424-2222"]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.x = addressX;
    pos.y = tempY + TO_PRINTER(4.0);
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	CGFloat yAfterAddress = pos.y + drawn;
	

    // ============================================================================================
	
	// registration number
	section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_ALL;
    
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"label";
	cell.width = width * .25;
	cell.font = EIGHTPOINT_FONT;
	cell.cellType = CELL_LABEL;
	[section addCell:cell];
	
    
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:[NSString stringWithFormat:@"ATLAS REGISTRATION NO. \r\n %@ \r\n \r\n ",
                                                        inf.orderNumber]]]
                 withColName:@"label"];
	
	pos = params.contentRect.origin;
	pos.x = width * .75;
    pos.y = leftCurrentPageY;
    
	drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - currentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	
    
    // ============================================================================================
    
    leftCurrentPageY = MAX(yAfterImage, yAfterAddress);    
    [self updateCurrentPageY];
    
    //currentPageY += TO_PRINTER(5.);
    
    // customer
	section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
    
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"Customer";
	cell.cellType = CELL_TEXT_LABEL;
    cell.width = width * 0.5;
	cell.font = NINEPOINT_FONT;
    cell.underlineValue = TRUE;
	[section addCell:cell];
	
    
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithValue:[NSString stringWithFormat:@"%@ %@", cust.firstName, cust.lastName]
                                             withLabel:@"Customer"]]
                 withColName:@"Customer"];
    
	pos = params.contentRect.origin;
    pos.x = width * 0.5;
	pos.y = currentPageY;
	
	drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - currentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	currentPageY += drawn;
	
    
    // ============================================================================================
    
    //currentPageY += TO_PRINTER(5.);
    
    // instructions
    NSString* highValueDesc = [AppFunctionality getHighValueDescription];
    
    NSString *instr = [NSString stringWithFormat: @"Be sure to complete the description and estimated value sections on this form for all items in your shipment considered to be of %@ or that may require additional attention, special packing, crating or handling. If no items are considered to be of %@ or in need of additional attention, write NONE (and sign form appropriately). Examples of %@ Items or items needing additional attention - antiques, art (wall or standing), clocks, collectibles, collections, computer hardware or software, customized items, designer clothing or wardrobe accessories, exercise equipment, fine china, firearms, high end appliances/furniture, home audio/video system, hot tub, memory foam mattress, piano/musical instruments, silver ware, tanning bed, or other high value goods exceeding $3000.00 in value.", highValueDesc, highValueDesc, highValueDesc];
    
	section = [[PrintSection alloc] initWithRes:resolution];
    
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"text";
	cell.width = width;
	cell.font = EIGHTPOINT_FONT;
	[section addCell:cell];
	
	
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:instr]]
                 withColName:@"text"];
	
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - currentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
	
	currentPageY += drawn;
	
    
    // ============================================================================================
    
    
	
	return drawn;
}

#define HV_WIDTH_INVENTORY_NUMBER       0.080f
#define HV_WIDTH_ITEM_DESCRIPTION       0.215f
#define HV_WIDTH_DECLARED_VALUE         0.146f
#define HV_WIDTH_CONDITION_ORIGIN       0.254f
#define HV_WIDTH_CONDITION_DELIVERY     0.215f
#define HV_WIDTH_CUSTOMER_INITIALS      0.092f

-(int)highValueItemsHeader
{
    highValueTotal = 0.0;
    
    [self updateCurrentPageY];
	
    PrintSection *section;
	PrintCell *inventoryNumberCell, *itemDescriptionCell, *declareValueCell, *conditionOriginCell, *conditionDeliveryCell, *initialsCell;
    CGPoint pos;
    CGFloat drawn;
    
	section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_NONE;
    
	inventoryNumberCell = [[PrintCell alloc] initWithRes:resolution];
	inventoryNumberCell.cellName = @"InvNo";
	inventoryNumberCell.width = width * HV_WIDTH_INVENTORY_NUMBER;
	inventoryNumberCell.font = SIXPOINT_FONT;
    inventoryNumberCell.textPosition = NSTextAlignmentCenter;
    inventoryNumberCell.borderType = BORDER_ALL;
	[section addCell:inventoryNumberCell];
    
	itemDescriptionCell = [[PrintCell alloc] initWithRes:resolution];
	itemDescriptionCell.cellName = @"ItemDescrip";
	itemDescriptionCell.width = width * HV_WIDTH_ITEM_DESCRIPTION;
	itemDescriptionCell.font = SIXPOINT_FONT;
    itemDescriptionCell.textPosition = NSTextAlignmentCenter;
    itemDescriptionCell.borderType = BORDER_ALL;
	[section addCell:itemDescriptionCell];
    
	declareValueCell = [[PrintCell alloc] initWithRes:resolution];
	declareValueCell.cellName = @"DeclareValue";
	declareValueCell.width = width * HV_WIDTH_DECLARED_VALUE;
	declareValueCell.font = SIXPOINT_FONT;
    declareValueCell.textPosition = NSTextAlignmentCenter;
    declareValueCell.borderType = BORDER_ALL;
	[section addCell:declareValueCell];
    
	conditionOriginCell = [[PrintCell alloc] initWithRes:resolution];
	conditionOriginCell.cellName = @"ConditionOrigin";
	conditionOriginCell.width = width * HV_WIDTH_CONDITION_ORIGIN;
	conditionOriginCell.font = SIXPOINT_FONT;
    conditionOriginCell.textPosition = NSTextAlignmentCenter;
    conditionOriginCell.borderType = BORDER_ALL;
	[section addCell:conditionOriginCell];
    
	conditionDeliveryCell = [[PrintCell alloc] initWithRes:resolution];
	conditionDeliveryCell.cellName = @"ConditionDelivery";
	conditionDeliveryCell.width = width * HV_WIDTH_CONDITION_DELIVERY;
	conditionDeliveryCell.font = SIXPOINT_FONT;
    conditionDeliveryCell.textPosition = NSTextAlignmentCenter;
    conditionDeliveryCell.borderType = BORDER_ALL;
	[section addCell:conditionDeliveryCell];
    
    initialsCell = [[PrintCell alloc] initWithRes:resolution];
	initialsCell.cellName = @"DestShipInit";
	initialsCell.width = width * HV_WIDTH_CUSTOMER_INITIALS;
	initialsCell.font = PVO_REPORT_FIVEPOINT_FONT;
    initialsCell.textPosition = NSTextAlignmentCenter;
    initialsCell.borderType = BORDER_ALL;
	[section addCell:initialsCell];
	
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"INVENTORY\r\nNUMBER"]] withColName:@"InvNo"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:[NSString stringWithFormat:@"DESCRIPTION OF\r\n%@ ITEMS",
                                                                                       [[AppFunctionality getHighValueDescription] uppercaseString]]]] withColName:@"ItemDescrip"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"ESTIMATED\r\nVALUE"]] withColName:@"DeclareValue"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"NOTES/CONDITION\r\nORIGIN"]] withColName:@"ConditionOrigin"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"NOTES/CONDITION\r\nDELIVERY"]] withColName:@"ConditionDelivery"];
	[section addColumnValues:[NSMutableArray arrayWithObject:[CellValue cellWithLabel:@"CUSTOMER\r\nINITIALS\r\nON RECEIPT"]] withColName:@"DestShipInit"];
	
    CGFloat maxHeight = [initialsCell heightWithText:@"CUSTOMER\r\nINITIALS\r\nON RECEIPT"];
    inventoryNumberCell.overrideHeight = YES;
    inventoryNumberCell.cellHeight = maxHeight;
    itemDescriptionCell.overrideHeight = YES;
    itemDescriptionCell.cellHeight = maxHeight;
    declareValueCell.overrideHeight = YES;
    declareValueCell.cellHeight = maxHeight;
    conditionOriginCell.overrideHeight = YES;
    conditionOriginCell.cellHeight = maxHeight;
    conditionDeliveryCell.overrideHeight = YES;
    conditionDeliveryCell.cellHeight = maxHeight;
    
	pos = params.contentRect.origin;
	pos.y = currentPageY;
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - currentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}

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
//    tempCurrentPageY = currentPageY,
    invNoCellHeight = 0, itemDescripCellHeight = 0, conditionOriginCellHeight = 0, conditionDeliveryCellHeight = 0,
    declareValueCellHeight = 0,
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
	cell.width = width * HV_WIDTH_INVENTORY_NUMBER;
	cell.font = SEVENPOINT_FONT;
    cell.textPosition = NSTextAlignmentCenter;
    cell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
	[borderSection addCell:cell];
	
    
    [borderSection duplicateLastCell:@"ItemDescrip" withType:CELL_LABEL withWidth:(width * HV_WIDTH_ITEM_DESCRIPTION) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"DeclareValue" withType:CELL_LABEL withWidth:(width * HV_WIDTH_DECLARED_VALUE) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"ConditionOrigin" withType:CELL_LABEL withWidth:(width * HV_WIDTH_CONDITION_ORIGIN) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"ConditionDelivery" withType:CELL_LABEL withWidth:(width * HV_WIDTH_CONDITION_DELIVERY) withAlign:NSTextAlignmentCenter];
    [borderSection duplicateLastCell:@"DestShipInit" withType:CELL_LABEL withWidth:(width * HV_WIDTH_CUSTOMER_INITIALS) withAlign:NSTextAlignmentCenter];
    
    //add values
    CellValue *blankTwo = [CellValue cellWithLabel:@" \r\n "];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"InvNo"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"ItemDescrip"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"DeclareValue"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"ConditionOrigin"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"ConditionDelivery"];
    [borderSection addColumnValues:[NSMutableArray arrayWithObject:blankTwo] withColName:@"DestShipInit"];
    
	//set up section
	PrintSection *hvSection = [[PrintSection alloc] initWithRes:resolution];
	hvSection.borderType = BORDER_NONE;
    
	//set up cell(s)
	PrintCell *invNoCell = [[PrintCell alloc] initWithRes:resolution];
	invNoCell.cellName = @"InvNo";
	invNoCell.cellType = CELL_LABEL;
	invNoCell.width = width * HV_WIDTH_INVENTORY_NUMBER;
	invNoCell.font = SEVENPOINT_FONT;
    invNoCell.textPosition = NSTextAlignmentCenter;
    invNoCell.borderType = BORDER_NONE;
	[hvSection addCell:invNoCell];
    
	PrintCell *itemDescripCell = [[PrintCell alloc] initWithRes:resolution];
	itemDescripCell.cellName = @"ItemDescrip";
	itemDescripCell.cellType = CELL_LABEL;
	itemDescripCell.width = width * HV_WIDTH_ITEM_DESCRIPTION;
	itemDescripCell.font = SEVENPOINT_FONT;
    itemDescripCell.textPosition = NSTextAlignmentCenter;
    itemDescripCell.borderType = BORDER_NONE;
	[hvSection addCell:itemDescripCell];
    
	PrintCell *declareValueCell = [[PrintCell alloc] initWithRes:resolution];
	declareValueCell.cellName = @"DeclareValue";
	declareValueCell.cellType = CELL_LABEL;
	declareValueCell.width = width * HV_WIDTH_DECLARED_VALUE;
	declareValueCell.font = SEVENPOINT_FONT;
    declareValueCell.textPosition = NSTextAlignmentCenter;
    declareValueCell.borderType = BORDER_NONE;
	[hvSection addCell:declareValueCell];
    
	PrintCell *conditionOriginCell = [[PrintCell alloc] initWithRes:resolution];
	conditionOriginCell.cellName = @"ConditionOrigin";
	conditionOriginCell.cellType = CELL_LABEL;
	conditionOriginCell.width = width * HV_WIDTH_CONDITION_ORIGIN;
	conditionOriginCell.font = SEVENPOINT_FONT;
    conditionOriginCell.textPosition = NSTextAlignmentCenter;
    conditionOriginCell.borderType = BORDER_NONE;
	[hvSection addCell:conditionOriginCell];
    
	PrintCell *conditionDeliveryCell = [[PrintCell alloc] initWithRes:resolution];
	conditionDeliveryCell.cellName = @"ConditionDelivery";
	conditionDeliveryCell.cellType = CELL_LABEL;
	conditionDeliveryCell.width = width * HV_WIDTH_CONDITION_DELIVERY;
	conditionDeliveryCell.font = SEVENPOINT_FONT;
    conditionDeliveryCell.textPosition = NSTextAlignmentCenter;
    conditionDeliveryCell.borderType = BORDER_NONE;
	[hvSection addCell:conditionDeliveryCell];
    
	PrintCell *destShipInitCell = [[PrintCell alloc] initWithRes:resolution];
	destShipInitCell.cellName = @"DestShipInit";
	destShipInitCell.cellType = CELL_LABEL;
	destShipInitCell.width = width * HV_WIDTH_CUSTOMER_INITIALS;
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
        
        Item *item = [del.surveyDB getItem:myItem.itemID WithCustomer:del.customerID];
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                    [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", item.name]]]
                       withColName:@"ItemDescrip"];
        itemDescripCellHeight = [itemDescripCell heightWithText:[NSString stringWithFormat:@"%@", item.name]];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                    [CellValue cellWithLabel:
                                     [NSString stringWithFormat:@"%@",
                                      [SurveyAppDelegate formatCurrency:myItem.highValueCost withCommas:(BOOL)(myItem.highValueCost > 1)]]]]
                       withColName:@"DeclareValue"];
        declareValueCellHeight = [declareValueCell heightWithText:[NSString stringWithFormat:@"%@",
                                                                   [SurveyAppDelegate formatCurrency:myItem.highValueCost withCommas:(BOOL)(myItem.highValueCost > 1)]]];
        highValueTotal += myItem.highValueCost;
        
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
        
        NSString *originNotes = @"";
        PVOItemComment *originComment = [del.surveyDB getPVOItemComment:myItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
        if (originComment.comment != nil && [originComment.comment length] > 0)
        {
            originNotes = [originNotes stringByAppendingString:originComment.comment];
        }
        
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                    [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", originNotes]]]
                       withColName:@"ConditionOrigin"];
        conditionOriginCellHeight = [conditionOriginCell heightWithText:[NSString stringWithFormat:@"%@", originNotes]];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:
                                    [CellValue cellWithLabel:[NSString stringWithFormat:@"%@", condition]]]
                       withColName:@"ConditionDelivery"];
        conditionDeliveryCellHeight = [conditionDeliveryCell heightWithText:[NSString stringWithFormat:@"%@", condition]];
    }
    else
    {
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"InvNo"];
        invNoCellHeight = [invNoCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ItemDescrip"];
        itemDescripCellHeight = [itemDescripCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DeclareValue"];
        declareValueCellHeight = [declareValueCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionOrigin"];
        conditionOriginCellHeight = [conditionOriginCell heightWithText:@" "];
        
        [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"ConditionDelivery"];
        conditionDeliveryCellHeight = [conditionDeliveryCell heightWithText:@" "];
    }
    
    [hvSection addColumnValues:[NSMutableArray arrayWithObject:blank] withColName:@"DestShipInit"];
    destShipInitCellHeight = [destShipInitCell heightWithText:@" "];
    
    //calculate highest height
    int highHeight = [self findHighestHeight:[NSMutableArray arrayWithObjects:
                                              [NSNumber numberWithInt:invNoCellHeight],
                                              [NSNumber numberWithInt:itemDescripCellHeight],
                                              [NSNumber numberWithInt:declareValueCellHeight],
                                              [NSNumber numberWithInt:conditionOriginCellHeight],
                                              [NSNumber numberWithInt:conditionDeliveryCellHeight],
                                              nil]];
    
    //override all cell heights with highest
    invNoCell.overrideHeight = TRUE;
    invNoCell.cellHeight = highHeight;
    itemDescripCell.overrideHeight = TRUE;
    itemDescripCell.cellHeight = highHeight;
    declareValueCell.overrideHeight = TRUE;
    declareValueCell.cellHeight = highHeight;
    conditionOriginCell.overrideHeight = TRUE;
    conditionOriginCell.cellHeight = highHeight;
    conditionDeliveryCell.overrideHeight = TRUE;
    conditionDeliveryCell.cellHeight = highHeight;
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
        declareValueCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        conditionOriginCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
        conditionDeliveryCell.borderType = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT;
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
                    
                    //calculate x position + 
                    int x = params.contentRect.origin.x + invNoCell.width + itemDescripCell.width + declareValueCell.width + conditionOriginCell.width + conditionDeliveryCell.width;
                    switch (hvi.pvoSigTypeID) {
                        case PVO_HV_INITIAL_TYPE_PACKER:
                            x += ((destShipInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                        case PVO_HV_INITIAL_TYPE_CUSTOMER:
                            x += ((destShipInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                        case PVO_HV_INITIAL_TYPE_DEST_CUSTOMER:
                            x += ((destShipInitCell.width - (tmpSize.width * initScale)) / 2);
                            break;
                    }
                    
                    if (hvi.pvoSigTypeID == PVO_HV_INITIAL_TYPE_CUSTOMER)
                    {
//                        CGRect imgRect = CGRectMake(x, tempCurrentPageY+TO_PRINTER(1.), tmpSize.width * initScale, tmpSize.height * initScale);
                        // not sure if the initials should be printed here or not
                        // so the draw code is commented out below
                        //CGContextDrawImage(context, imgRect, img.CGImage);
                    }
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

- (int)highValueFooter:(BOOL)print
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *orgCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE];
    PVOSignature *destCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DEST_HIGH_VALUE];
    
    BOOL orgCustSigApplied = FALSE, destCustSigApplied = FALSE;
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
    
    CGFloat leftmostX, currX, currY, saveY, currWidth;
    CGFloat sig1X, sig1Y, sig2X, sig2Y;
    NSString *longString;
    
    leftmostX = params.contentRect.origin.x;
    
    [PrintCell staticContextSet:context];

    currX = leftmostX + width * HV_WIDTH_INVENTORY_NUMBER;
    currY = 520.0;
    currWidth = width * HV_WIDTH_ITEM_DESCRIPTION;
    [PrintCell drawTextCellLabel:@"TOTAL" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(12.0) border:BORDER_NONE align:NSTextAlignmentRight];
    
    currX = 190.0;
    currWidth = width * HV_WIDTH_DECLARED_VALUE;
    NSString *valueString = [NSString stringWithFormat:@"%@",
                             [SurveyAppDelegate formatCurrency:highValueTotal withCommas:(BOOL)(highValueTotal > 1)]];
    [PrintCell drawTextCellLabel:valueString x:currX y:currY width:currWidth font:SYSTEM_FONT(10.0) border:BORDER_ALL align:NSTextAlignmentCenter];

    currX = leftmostX;
    currY += 24.0;
    currWidth = width * (HV_WIDTH_INVENTORY_NUMBER + HV_WIDTH_ITEM_DESCRIPTION + HV_WIDTH_DECLARED_VALUE);
    [PrintCell drawTextCellLabel:[NSString stringWithFormat:@"NO %@ ITEMS IN THIS LOAD:", [[AppFunctionality getHighValueDescription] uppercaseString]] x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(12.0) border:BORDER_NONE align:NSTextAlignmentRight];
    
    currY += 10.0;
    currX += (currWidth + 10.0);
    currWidth = width * 0.5;
    [PrintCell drawTextCellLabel:@"SIGNATURE OF CUSTOMER OR CUSTOMER'S REPRESENTATIVE" x:currX y:currY width:currWidth font:SYSTEM_FONT(6.0) border:BORDER_TOP align:NSTextAlignmentCenter];
    
    currX = leftmostX;
    currY += 15.0;
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + width, currY)];
    
#define CENTER_LINE_HEIGHT      150.0
    
    currX += (width / 2.0);
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX, currY + CENTER_LINE_HEIGHT)];
    
#define GUTTER_AROUND_CENTER_LINE   8.0
    
    currX = leftmostX;
    currY += 5.0;
    saveY = currY;
    currWidth = width * 0.5 - GUTTER_AROUND_CENTER_LINE;
    [PrintCell drawTextCellLabel:@"AT ORIGIN_" x:currX y:currY width:currWidth font:SYSTEM_FONT(14.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
    currY += 24.0;
    longString = @"I CERTIFY THE ABOVE LISTED INFORMATION TO BE TRUE, CORRECT AND COMPLETE TO THE BEST OF MY KNOWLEDGE. I HAVE READ AND UNDERSTAND THE STATEMENT OF CUSTOMER RESPONSIBILITIES FORM.";    
    [PrintCell drawTextCellLabel:longString x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(7.0) border:BORDER_NONE align:NSTextAlignmentLeft];

#define SIGNATURE_OFFSET_X      25.0
#define SIGNATURE_OFFSET_Y      -15.0
    
    currY += 50.0;
    [PrintCell drawTextCellLabel:@"X" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(9.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    sig1X = currX + SIGNATURE_OFFSET_X;
    sig1Y = currY + SIGNATURE_OFFSET_Y;
    
    currY += 16.0;
    [PrintCell drawTextCellLabel:@"SIGNATURE OF CUSTOMER OR CUSTOMER'S REPRESENTATIVE                    DATE" x:currX y:currY width:currWidth font:SYSTEM_FONT(6.0) border:BORDER_TOP align:NSTextAlignmentLeft];
    
    currY += 45.0;
    [PrintCell drawTextCellLabel:@"SIGNATURE OF ATLAS REPRESENTATIVE                   AGENT/PVO CODE         DATE" x:currX y:currY width:currWidth font:SYSTEM_FONT(6.0) border:BORDER_TOP align:NSTextAlignmentLeft];
    
    currX = leftmostX + width * 0.5 + GUTTER_AROUND_CENTER_LINE;
    currY = saveY;
    [PrintCell drawTextCellLabel:@"AT DESTINATION_" x:currX y:currY width:currWidth font:SYSTEM_FONT(14.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
    currY += 24.0;
    longString = @"I ACKNOWLEDGE RECEIPT OF ALL ITEMS LISTED ABOVE. ALL ITEMS ARE IN THE SAME CONDITION AS WHEN TENDERED TO ATLAS, UNLESS EXCEPTIONS ARE NOTED ABOVE.";
    [PrintCell drawTextCellLabel:longString x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(7.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
    currY += 50.0;
    [PrintCell drawTextCellLabel:@"X" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(9.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    sig2X = currX + SIGNATURE_OFFSET_X;
    sig2Y = currY + SIGNATURE_OFFSET_Y;
    
    currY += 16.0;
    [PrintCell drawTextCellLabel:@"SIGNATURE OF CUSTOMER OR CUSTOMER'S REPRESENTATIVE                    DATE" x:currX y:currY width:currWidth font:SYSTEM_FONT(6.0) border:BORDER_TOP align:NSTextAlignmentLeft];
    
    currY += 45.0;
    [PrintCell drawTextCellLabel:@"SIGNATURE OF ATLAS REPRESENTATIVE                   AGENT/PVO CODE         DATE" x:currX y:currY width:currWidth font:SYSTEM_FONT(6.0) border:BORDER_TOP align:NSTextAlignmentLeft];
    
    currX = leftmostX;
    currY = saveY + CENTER_LINE_HEIGHT;
    currWidth = width;
    longString = @"ESTIMATED VALUE DOES NOT DETERMINE THE ACTUAL VALUE OF THE GOODS. SHOULD A LOSS OCCUR, THE ACTUAL VALUE MUST BE ESTABLISHED BY THE OWNER OF THE GOODS. THE PURPOSE OF THIS FORM IS TO ASSIST YOU IN DETERMINING THE TOTAL VALUE OF YOUR SHIPMENT AND TO ASSIST ATLAS IN DETERMINING WHICH ITEMS NEED SPECIAL HANDLING AND PROTECTION.";
    [PrintCell drawTextCellLabel:longString x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(7.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
    currY += 30.0;
    [PrintCell drawTextCellLabel:@"DC 2225009 (1212)\r\nRev. E" x:currX y:currY width:currWidth font:SYSTEM_FONT(5.0) border:BORDER_NONE align:NSTextAlignmentRight];
    
#define SIGNATURE_WIDTH_SCALE_FACTOR    0.10
#define SIGNATURE_HEIGHT_SCALE_FACTOR   0.10
    
    // customer signatures
    if (print && orgCustSigApplied)
    {
        //UIImage *custSig = [[orgCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[orgCustSig signatureData]];
        CGSize tmpSize = [custSig size];
        if (tmpSize.height > tmpSize.width) tmpSize.height = tmpSize.width;
        
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(sig1X,
                                        sig1Y,
                                        tmpSize.width * SIGNATURE_WIDTH_SCALE_FACTOR,
                                        tmpSize.height * SIGNATURE_HEIGHT_SCALE_FACTOR);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    if (!isOrigin && print && destCustSigApplied)
    {
        //UIImage *custSig = [[destCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[destCustSig signatureData]];
        CGSize tmpSize = [custSig size];
        if (tmpSize.height > tmpSize.width) tmpSize.height = tmpSize.width;
        
        custSig = [SurveyAppDelegate scaleAndRotateImage:custSig withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(sig2X,
                                        sig2Y,
                                        tmpSize.width * SIGNATURE_WIDTH_SCALE_FACTOR,
                                        tmpSize.height * SIGNATURE_HEIGHT_SCALE_FACTOR);
        [self drawImage:custSig withCGRect:custSigRect];
    }
    
    return 0;
}

-(int)highValueFooterOld:(BOOL)print
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
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
        //UIImage *custSig = [[orgCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[orgCustSig signatureData]];
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
        //UIImage *custSig = [[destCustSig signatureData] retain];
        UIImage *custSig = [SyncGlobals removeUnusedImageSpace:[destCustSig signatureData]];
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

-(int)highValueChecklist
{
    CGFloat currX, currY, saveY, currWidth;
    CGFloat sig1X, sig1Y;
    CGFloat leftmostX = 26.0;
    NSString *longString;
    
    currentPageY += TO_PRINTER(10.);
    [self updateCurrentPageY];
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//	ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
//	SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    PVOSignature *orgCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_ORG_HIGH_VALUE];
    PVOSignature *destCustSig = [del.surveyDB getPVOSignature:custID forImageType:PVO_SIGNATURE_TYPE_DEST_HIGH_VALUE];
    
    BOOL orgCustSigApplied = FALSE, destCustSigApplied = FALSE;
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
	PrintSection *section;
    CGPoint pos;
    PrintCell *cell;
    int drawn;
    CGFloat tempY;
    
    // ============================================================================================
    
    // Atlas logo
    currX = 28.0;
    NSString *vanLineText;
    double scale = 1;
    CGSize imageSize = CGSizeZero;
    switch ([del.pricingDB vanline])
    {
        case ARPIN:
            vanLineText = @"Arpin.png";
            scale = 0.25;
            break;
        case MAYFLOWER:
            vanLineText = @"MayflowerPVO.png";
            scale = 0.38;
            break;
        case UNIGROUP:
        case UNITED:
            vanLineText = @"UnitedPVO.png";
            scale = 0.13;
            break;
        case ATLAS:
            vanLineText = @"AtlasLogoBW.png";
            scale = 0.18;
            break;
        default:
            vanLineText = @"";
            break;
    }
    
    if ([vanLineText length] > 0)
    {
        UIImage *image1 = [UIImage imageNamed:vanLineText];
        CGSize	tmpSize1 = [image1 size];
        image1 = [SurveyAppDelegate scaleAndRotateImage:image1 withOrientation:UIImageOrientationDownMirrored];
        CGRect imageRect1 = CGRectMake(currX,
                                       leftCurrentPageY,
                                       tmpSize1.width * scale,
                                       tmpSize1.height * scale);
        
        [self drawImage:image1 withCGRect:imageRect1];
        
        imageSize = CGSizeMake(tmpSize1.width * scale, tmpSize1.height * scale);
    }
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .25;
	cell.font = SEVENPOINT_FONT;
	[section addCell:cell];
	
	
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"U.S. DOT No. 125550"]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.x = currX;
    pos.y = leftCurrentPageY + (imageSize.height + TO_PRINTER(8.0));
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
//    CGFloat yAfterImage = pos.y + drawn;
	
    
    // ============================================================================================
    
    // report title and Atlas address
    CGFloat addressX = width * 0.2;
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .6;
	cell.font = NINEPOINT_FONT;
	[section addCell:cell];
	
	
    [section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"CUSTOMER RESPONSIBILITIES GUIDE / HIGH VALUE INVENTORY"]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.x = addressX;
    pos.y = leftCurrentPageY;
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	tempY = leftCurrentPageY + drawn;
	
    
	section = [[PrintSection alloc] initWithRes:resolution];
	
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"header";
	cell.width = width * .6;
	cell.font = SIXPOINT_FONT;
	[section addCell:cell];
	
	
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"ATLAS VAN LINES, INC.\r\n1212 ST. GEORGE ROAD, P.O. BOX 509\r\nEVANSVILLE, IN 47703\r\n(800) 252-8885 / (812) 424-2222"]]
                 withColName:@"header"];
	
	pos = params.contentRect.origin;
    pos.x = addressX;
    pos.y = tempY + TO_PRINTER(4.0);
	
	drawn = [section drawSection:context withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - leftCurrentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	CGFloat yAfterAddress = pos.y + drawn;
	
    
    // ============================================================================================
	
	// registration number
	section = [[PrintSection alloc] initWithRes:resolution];
	section.borderType = BORDER_ALL;
    
	cell = [[PrintCell alloc] initWithRes:resolution];
	cell.cellName = @"label";
	cell.width = width * .25;
	cell.font = EIGHTPOINT_FONT;
	[section addCell:cell];
	
    
	[section addColumnValues:[NSMutableArray arrayWithObject:
                              [CellValue cellWithLabel:@"ATLAS REGISTRATION NO.\r\n \r\n "]]
                 withColName:@"label"];
	
	pos = params.contentRect.origin;
	pos.x = width * .75;
    pos.y = leftCurrentPageY;
    
	drawn = [section drawSection:context
                    withPosition:pos
                  andRemainingPX:(params.contentRect.size.height - takeOffBottom) - currentPageY];
	if (drawn == DIDNT_FIT_ON_PAGE)
    {
		[self finishSectionOnNextPage:section];
	}
    
	

    // ============================================================================================

    currX = leftmostX;
    currY = yAfterAddress + 5.0;
    currWidth = width;
    longString = @"The following list sets out your responsibilities prior to and at packing/loading, during transportation, and at time of delivery. This list is meant to alleviate most problems encountered during a relocation. Failure to complete these items may result in damage to your goods as well as to Atlas equipment or personnel. Thank you for taking the time to do the following:";
    [PrintCell drawTextCellLabel:longString x:currX y:currY width:currWidth font:SYSTEM_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
    currY += 44.0;
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + currWidth, currY)];

    currY += 2.0;
    [PrintCell drawTextCellLabel:@"• Pre Packing/Loading •" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentCenter];
    
#define CHECK_BOX_INDENT    10.0
#define ONE_LINE_ADVANCE    16.0
#define TWO_LINE_ADVANCE    30.0
#define THREE_LINE_ADVANCE  42.0
#define FOUR_LINE_ADVANCE   56.0
#define CHECK_BOX_WIDTH     6.0
#define CHECK_BOX_HEIGHT    6.0
#define CHECK_BOX_VERTICAL_OFFSET   CHECK_BOX_HEIGHT - 1.0
#define TEXT_COLUMN_WIDTH   width / 2.0 - CHECK_BOX_INDENT * 2.0
    
    [PrintCell staticFontSet:SYSTEM_FONT(10.0)];
    [PrintCell staticLineWidthSet:0.5];
    
    // left column
    
    currX = leftmostX;
    currY += ONE_LINE_ADVANCE;
    saveY = currY;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    [PrintCell drawTextCellLabel:@"Discard perishable items (food, house plants, etc.)" x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];

    currY += ONE_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Arrange non-Atlas transportation of jewelry, coins, currency, stocks, bonds, legal documents, valuable collectibles, collections, and medicines.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += THREE_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Discard flammables, ammunition, cleaning solutions, paint, liquids, aerosol cans and propane tanks.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Separate and identify items not being packed or transported by Atlas.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Empty attic and crawl space of items to be packed or transported by Atlas.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Remove wall art and ceiling fixtures and prepare them for packing or transport.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Disassemble all particle board, press board and prefab furniture.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Prepare electronics, audio, video and computer equipment for packing or transport.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    // right column
    
    currX = leftmostX + width / 2.0;
    currY = saveY;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    longString = @"Disassemble or unhook appliances, including water and gas connections. Have appliances prepared for transport.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Remove personal items from boats, autos and motorcycles. Make sure the gasoline level is no more than one quarter tank.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += THREE_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Empty gasoline and oil from small engine gas-powered equipment (lawnmowers, blowers, etc.)";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = [NSString stringWithFormat:@"Identify all %@ items on the attached inventory form and give for to the van operator.", [AppFunctionality getHighValueDescription]];
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Advise packers or the van operator of any firearms being packed or transported.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Be present at the time of packing and loading to verify inventory and sign documents.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Check drawers, cabinets and closets to be sure all items are removed.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Perform residence walk through with the van operator after loading is complete and make note of any residence damage on the appropriate documents.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currX = leftmostX;
    currY += (THREE_LINE_ADVANCE + 2.0);
    currWidth = width;
    [PrintCell staticLineWidthSet:1.0];
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + currWidth, currY)];
    
    currY += 2.0;
    [PrintCell drawTextCellLabel:@"• During Transport •" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentCenter];

    // left column
    
    currX = leftmostX;
    currY += ONE_LINE_ADVANCE;
    saveY = currY;
    [PrintCell staticLineWidthSet:0.5];
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    longString = @"Notify your relocation coordinator of any schedule or contact information changes.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Be available to accept delivery at any time during delivery dates.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    // right column
    
    currX = leftmostX + width / 2.0;
    currY = saveY;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    longString = @"Verify total charges due with your move coordinator prior to delivery day. (C.O.D. shipments only)";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Arrange proper payment method (check, money order, credit card) prior to delivery day. (C.O.D. shipments only)";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currX = leftmostX;
    currY += (TWO_LINE_ADVANCE + 2.0);
    currWidth = width;
    [PrintCell staticLineWidthSet:1.0];
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + currWidth, currY)];
    
    currY += 2.0;
    [PrintCell drawTextCellLabel:@"• During Delivery •" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentCenter];
    
    // left column
    
    currX = leftmostX;
    currY += ONE_LINE_ADVANCE;
    saveY = currY;
    [PrintCell staticLineWidthSet:0.5];
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    [PrintCell drawTextCellLabel:@"Be present during entire delivery." x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += ONE_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Verify items delivered by using the Customer Check Off Sheet. Ask your van operator for this before delivery.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += TWO_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = [NSString stringWithFormat:@"Verify receipt of all items listed on %@ Inventory.", [AppFunctionality getHighValueDescription]];
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    // right column
    
    currX = leftmostX + width / 2.0;
    currY = saveY;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    longString = @"Note any loss or damage (including damage to your residence) on Atlas documents prior to the van operator leaving, especially if the delivery is being made to a non-Atlas or mini storage facility.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += FOUR_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Perform residence walk through with the van operator, making note of any residence damage on the appropriate delivery documents.";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currX = leftmostX;
    currY += (THREE_LINE_ADVANCE + 2.0);
    currWidth = width;
    [PrintCell staticLineWidthSet:1.0];
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + currWidth, currY)];
    
    currY += 2.0;
    [PrintCell drawTextCellLabel:@"• Atlas Literature/Forms Received •" x:currX y:currY width:currWidth font:SYSTEM_BOLD_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentCenter];
    
    // left column
    
    currX = leftmostX;
    currY += ONE_LINE_ADVANCE;
    saveY = currY;
    [PrintCell staticLineWidthSet:0.5];
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    [PrintCell drawTextCellLabel:@"Atlas' Important Information Booklet" x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currY += ONE_LINE_ADVANCE;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    longString = @"Personal business card of the survey origin agency representative";
    [PrintCell drawTextCellLabel:longString x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    // right column
    
    currX = leftmostX + width / 2.0;
    currY = saveY;
    [PrintCell drawRectangle:CGRectMake(currX, currY + CHECK_BOX_VERTICAL_OFFSET, CHECK_BOX_WIDTH, CHECK_BOX_HEIGHT)];
    
    currWidth = TEXT_COLUMN_WIDTH;
    [PrintCell drawTextCellLabel:@"Don't Move Gypsy Moth and Gypsy Moth Advisory" x:currX + CHECK_BOX_INDENT y:currY width:currWidth align:NSTextAlignmentLeft];
    
    currX = leftmostX;
    currY += (ONE_LINE_ADVANCE + TWO_LINE_ADVANCE + 2.0);
    currWidth = width;
    [PrintCell staticLineWidthSet:1.0];
    [PrintCell drawLine:CGPointMake(currX, currY) to:CGPointMake(currX + currWidth, currY)];
    
    currX = leftmostX;
    currY += 2.0;
    currWidth = width;
    longString = @"I have discussed the customer responsibilities list above with the Carrier agency representative and understand each of the items and what is expected and required of me. I have received the Atlas literature/forms marked.";
    [PrintCell drawTextCellLabel:longString x:currX y:currY width:currWidth font:SYSTEM_FONT(10.0) border:BORDER_NONE align:NSTextAlignmentLeft];
    
#define SIGNATURE_LINE_OFFSET   14.0
#define CHECKLIST_SIGNATURE_OFFSET_X      125.0
#define CHECKLIST_SIGNATURE_OFFSET_Y      -10.0
        
    currX = leftmostX;
    currY += 45.0;
    [PrintCell drawTextCellLabel:@"Customer's Signature:" x:currX y:currY width:currWidth align:NSTextAlignmentLeft];
    sig1X = currX + CHECKLIST_SIGNATURE_OFFSET_X;
    sig1Y = currY + CHECKLIST_SIGNATURE_OFFSET_Y;
    
    [PrintCell drawLine:CGPointMake(currX + 110.0, currY + SIGNATURE_LINE_OFFSET) to:CGPointMake(width * 0.74, currY + SIGNATURE_LINE_OFFSET)];
    
    currX = width * 0.75;
    [PrintCell drawTextCellLabel:@"Date:" x:currX y:currY width:currWidth align:NSTextAlignmentLeft];
    
    [PrintCell drawLine:CGPointMake(currX + 30.0, currY + SIGNATURE_LINE_OFFSET) to:CGPointMake(width + 20.0, currY + SIGNATURE_LINE_OFFSET)];
    
    currX = leftmostX;
    currY += 30.0;
    [PrintCell drawTextCellLabel:@"Agency Representative's Signature:" x:currX y:currY width:currWidth align:NSTextAlignmentLeft];
    
    [PrintCell drawLine:CGPointMake(currX + 170.0, currY + SIGNATURE_LINE_OFFSET) to:CGPointMake(width * 0.74, currY + SIGNATURE_LINE_OFFSET)];
    
    currX = width * 0.75;
    [PrintCell drawTextCellLabel:@"Date:" x:currX y:currY width:currWidth align:NSTextAlignmentLeft];
    
    [PrintCell drawLine:CGPointMake(currX + 30.0, currY + SIGNATURE_LINE_OFFSET) to:CGPointMake(width + 20.0, currY + SIGNATURE_LINE_OFFSET)];
    
#define CHECKLIST_SIGNATURE_WIDTH_SCALE_FACTOR    0.10
#define CHECKLIST_SIGNATURE_HEIGHT_SCALE_FACTOR   0.10
    
    // customer signatures
    UIImage *customerSignatureImage = nil;
    if (_isDeliveryHighValueDisconnectedReport)
    {
        if (destCustSigApplied)
        {
            customerSignatureImage = [SyncGlobals removeUnusedImageSpace:[destCustSig signatureData]];
        }
    }
    else
    {
        if (orgCustSigApplied)
        {
            customerSignatureImage = [SyncGlobals removeUnusedImageSpace:[orgCustSig signatureData]];
        }
    }
    
    if (customerSignatureImage != nil)
    {
        CGSize tmpSize = [customerSignatureImage size];
        if (tmpSize.height > tmpSize.width) tmpSize.height = tmpSize.width;
        
        customerSignatureImage = [SurveyAppDelegate scaleAndRotateImage:customerSignatureImage withOrientation:UIImageOrientationDownMirrored];
        CGRect custSigRect = CGRectMake(sig1X,
                                        sig1Y,
                                        tmpSize.width * CHECKLIST_SIGNATURE_WIDTH_SCALE_FACTOR,
                                        tmpSize.height * CHECKLIST_SIGNATURE_HEIGHT_SCALE_FACTOR);
        [self drawImage:customerSignatureImage withCGRect:custSigRect];
    }
    
    return 0;
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

@end
