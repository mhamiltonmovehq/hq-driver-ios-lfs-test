//
//  PVOLandingController.m
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOLandingController.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"
#import "ButtonCell.h"
#import "SwitchCell.h"
#import "SingleDateCell.h"
#import "PVOLocationSummaryController.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"
#import "PVOBarcodeValidation.h"

@implementation PVOLandingController

@synthesize tboxCurrent, inventory, itemNumberString, inventoryController, delegate;
@synthesize driver;

#pragma mark -
#pragma mark Initialization

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if ((self = [super initWithStyle:style])) {
 }
 return self;
 }
 */


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    [super viewDidLoad];
    
    self.title = @"Inventory";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(cmdContinueClick:)];
    basic_info_rows = [[NSMutableArray alloc] init];
    editingRow = -1;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    colors = [del.surveyDB getPVOColors];
    valuationTypes = [del.surveyDB getPVOValuationTypes:[del.pricingDB vanline]];
    locations = [del.surveyDB getPVOLocations:YES isLoading:YES];
    
    packTypes = [[NSDictionary alloc] initWithObjects:@[@"None", @"Custom", @"Full"]
                                              forKeys:@[[NSNumber numberWithInt:PVO_PACK_NONE],[NSNumber numberWithInt:PVO_PACK_CUSTOM],[NSNumber numberWithInt:PVO_PACK_FULL]]];
    
    self.driver = [del.surveyDB getDriverData];
    
#if defined(ATLASNET)
    loadTypes = [del.surveyDB getPVOLoadTypesForAtlas:@[@"Commercial", @"Displays And Exhibits", @"International"]];
    [loadTypes setObject:@"Specialized Trans Grp" forKey:[NSNumber numberWithInt:4]];
#else
    loadTypes = [del.surveyDB getPVOLoadTypes];

#endif

    
    if(editingRow == -1)
    {
        self.inventory = [del.surveyDB getPVOData:del.customerID];
        self.driver = [del.surveyDB getDriverData];
        if ([AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
            self.inventory.usingScanner = NO;
        del.lastPackerInitials = nil;
    }
    
    editingRow = -1;
    
    [self initializeIncludedRows];
    [self.tableView reloadData];
    
    self.title = @"Inventory";
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
}

-(IBAction)cmdContinueClick:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if (!inventory.usingScanner)
    {
        NSString *err = nil;
        if (![PVOBarcodeValidation validateItemNumber:itemNumberString outError:&err])
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@", err] withTitle:@"Invalid Item Number"];
            return;
        }
        else if (![PVOBarcodeValidation validateLotNumber:inventory.currentLotNum outError:&err])
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@", err] withTitle:@"Invalid Lot Number"];
            return;
        }
        if ([AppFunctionality showConfirmLotNumberOnBeginInventory])
        {
            if (![[inventory.currentLotNum lowercaseString] isEqualToString:[inventory.confirmLotNum lowercaseString]])
            {
                [SurveyAppDelegate showAlert:@"Lot number must match confirmation lot number to proceed." withTitle:@"Invalid Lot Number"];
                return;
            }
        }
        if ([AppFunctionality enableValuationType])
        {
            if (inventory.valuationType <= 0 && [del.pricingDB vanline] == ARPIN) //must select a valuation type if arpin
            {
                [SurveyAppDelegate showAlert:@"You must have a valuation type selected to continue." withTitle:@"Invalid Valuation Type"];
                return;
            }
        }
    }
    
    {
        if(delegate != nil && [delegate respondsToSelector:@selector(pvoLandingController:dataEntered:)])
        {
            [delegate pvoLandingController:self dataEntered:inventory];
        }
        else
        {
            //            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            DriverData *data = [del.surveyDB getDriverData];
            BOOL isSpecialProducts = [AppFunctionality isSpecialProducts:[CustomerUtilities customerPricingMode] withLoadType:inventory.loadType];
            
            //check to see if this is a packer - if so, just use a packers inenorty load, and skip the location screen.
            //if special products, stick them in "Commercial" location and continue as well.
            
            if((data.driverType == PVO_DRIVER_TYPE_PACKER || isSpecialProducts)
               && [del.pricingDB vanline] != ATLAS)
            {
                PVOInventoryLoad *myload = nil;
                int myPvoLocID = (isSpecialProducts ? COMMERCIAL_LOC : PACKER_INVENTORY);
                
                //add load, receive items if they exist, then jump to rpom screen
                NSArray *existingLoads = [del.surveyDB getPVOLocationsForCust:del.customerID];
                for (PVOInventoryLoad *ld in existingLoads) {
                    if(ld.pvoLocationID == myPvoLocID)
                        myload = ld;
                }
                
                if(myload == nil)
                {
                    myload = [[PVOInventoryLoad alloc] init];
                    myload.pvoLocationID = myPvoLocID;
                    myload.custID = del.customerID;
                    myload.pvoLoadID = [del.surveyDB updatePVOLoad:myload];
                }
                
                PVOInventoryUnload *myunload = nil;
                int unloadType = [del.surveyDB getPVOReceivedItemsUnloadType:del.customerID];
                if (unloadType > 0)
                {
                    PVOInventoryUnload *unload = [[PVOInventoryUnload alloc] init];
                    unload.pvoLocationID = unloadType;
                    unload.custID = del.customerID;
                    if ([del.surveyDB pvoLocationRequiresLocationSelection:unloadType])
                    {//assumes unload tied to destination address.  will most likely change in future.
                        SurveyLocation *dest = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
                        unload.locationID = dest.locationID;
                    }
                    myunload = unload;
                }
                
                
                //receive all items
                NSArray *receivables = [del.surveyDB getPVOReceivableItems:del.customerID];
                if(receivables != nil && receivables.count > 0)
                {
                    int receiveType = [del.surveyDB getPVOReceivedItemsType:del.customerID];
                    for (PVOItemDetailExtended *item in receivables) {
                        
                        //remove first since the pvoItemID will be overwritten
                        [del.surveyDB removePVOReceivableItem:item.pvoItemID];
                        
                        //receive the item. save remaining item as a new inventory item...
                        item.pvoLoadID = myload.pvoLoadID;
                        item.pvoItemID = 0;
                        if (item.itemIsDelivered && (myunload == nil || myunload.pvoLocationID <= 0))
                            item.itemIsDelivered = NO;
                        
                        if (item.itemIsDelivered && myunload != nil && myunload.pvoLocationID > 0 && myunload.pvoLoadID <= 0)
                        {
                            myunload.loadIDs = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:myload.pvoLoadID], nil];
                            myunload.pvoLoadID = [del.surveyDB savePVOUnload:myunload];
                        }
                        
                        if ([AppFunctionality disableRiderExceptions])
                            item.lockedItem = (receiveType == WAREHOUSE && myload.pvoLocationID != WAREHOUSE); //not grabbing rider exceptions, so lock the item down
                        
                        if (myload.receivedFromPVOLocationID != receiveType)
                        {
                            myload.receivedFromPVOLocationID = receiveType;
                            myload.pvoLoadID = [del.surveyDB updatePVOLoad:myload];
                            item.pvoLoadID = myload.pvoLoadID;
                        }
                        
                        item.pvoItemID = [self saveReceivableItem:item withUnload:myunload];
                    }
                }
                
                
                if(roomController == nil)
                    roomController = [[PVORoomSummaryController alloc] initWithNibName:@"PVORoomSummaryView" bundle:nil];
#ifdef ATLASNET
                roomController.inventory = inventory;
#endif
                roomController.currentLoad = myload;
                
                [self.navigationController pushViewController:roomController animated:YES];
            }
            else//go to loads screen.
            {
                if(inventoryController == nil)
                    inventoryController = [[PVOLocationSummaryController alloc] initWithNibName:@"PVOLocationSummaryView" bundle:nil];
                
                inventoryController.title = @"Location";
                //                inventoryController.inventory = inventory;
                inventoryController.quickAddPopupLoaded = NO;
                
                [self.navigationController pushViewController:inventoryController animated:YES];
            }            
        }
    }
}

-(void)evaluateNewValuationType:(int)newValuationType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ARPIN)
    {
        int oldValuationType = inventory.valuationType;
        //Feature 1043
        if ([del.surveyDB pvoHasHighValueItems:del.customerID] && newValuationType == PVO_VALUATION_RELEASED && oldValuationType == PVO_VALUATION_FVP)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Valuation Type"
                                                            message:[NSString stringWithFormat:@"FVP Valuation was selected previously and items were added to the %1$@ inventory. Selecting Released valuation will remove these items from the %1$@ inventory and they will not be eligible for FVP", [AppFunctionality getHighValueDescription]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Continue", nil];
            alert.tag = newValuationType;
            [alert show];
        }
        else if (![del.surveyDB pvoHasHighValueItems:del.customerID] && newValuationType == PVO_VALUATION_FVP && oldValuationType == PVO_VALUATION_RELEASED)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Valuation Type"
                                                            message:[NSString stringWithFormat:@"Released Valuation was selected previously and there are no items added to the %1$@ inventory. This is the last opportunity to add %1$@ items to ensure proper coverage.", [AppFunctionality getHighValueDescription]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Continue", nil];
            alert.tag = newValuationType;
            [alert show];
        }
        else
        {
            inventory.valuationType = newValuationType;
        }
    }
}
-(int)saveReceivableItem:(PVOItemDetailExtended*)item withUnload:(PVOInventoryUnload*)myunload
{
    item.doneWorking = YES; //always flag as done
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    item.pvoItemID = [del.surveyDB updatePVOItem:item];
    
    //save damages
    for (PVOConditionEntry *condy in item.damageDetails) {
        condy.pvoItemID = item.pvoItemID;
        if (condy.pvoUnloadID > 0) //unload damage
        {
            if (item.itemIsDelivered && myunload != nil && myunload.pvoLoadID > 0)
            {
                condy.pvoLoadID = 0;
                condy.pvoUnloadID = myunload.pvoLoadID;
            }
            else
                continue;
        }
        else //load damage
        {
            condy.pvoLoadID = item.pvoLoadID;
            condy.pvoUnloadID = 0;
        }
        [del.surveyDB savePVODamage:condy];
        
    }
    item.damage = item.damageDetails;
    
    [del.surveyDB savePVODescriptions:item.descriptiveSymbols
                              forItem:item.pvoItemID];
    
    if (item.cartonContentID <= 0 && item.cartonContentsDetail != nil)
    {
        for (PVOItemDetailExtended *ccItem in item.cartonContentsDetail) { //new detailed logic
            ccItem.cartonContentID = [del.surveyDB addPVOCartonContent:ccItem.cartonContentID forPVOItem:item.pvoItemID];
            ccItem.itemNumber = [NSString stringWithFormat:@"%@", item.itemNumber];
            ccItem.lotNumber = [NSString stringWithFormat:@"%@", item.lotNumber];
            ccItem.tagColor = item.tagColor;
            ccItem.pvoItemID = 0;
            ccItem.pvoItemID = [self saveReceivableItem:ccItem withUnload:nil];
        }
    }
    
    return item.pvoItemID;
}

-(void)initializeIncludedRows
{
    [basic_info_rows removeAllObjects];
    
    
    [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_LOAD_TYPE]];
    if ([AppFunctionality enableValuationType])
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_VALUATION_TYPE]];
    [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_CURRENT_COLOR]];
    if([AppFunctionality allowNoCoditionsInventory:[CustomerUtilities customerPricingMode] withLoadType:inventory.loadType])
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_NO_COND]];
    if(![AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_USING_SCANNER]];
    
    if(!inventory.usingScanner)
    {
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_CURRENT_LOT_NUM]];
        if ([AppFunctionality showConfirmLotNumberOnBeginInventory])
            [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_CONFIRM_LOT_NUM]];
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_NEXT_ITEM_ID]];
    }
    
    if([AppFunctionality showTractorTrailerOnBeginInventory:[CustomerUtilities customerPricingMode]])
    {
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_TRACTOR_NUMBER]];
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_TRAILER_NUMBER]];
    }
    if(inventory.loadType == MILITARY)
    {
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_MPRO_WEIGHT]];
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_SPRO_WEIGHT]];
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_CONS_WEIGHT]];
    }
    [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_NEW_PAGE_PER_LOT]];
    
    if ([AppFunctionality showPackOptions])
    {
        [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_PACK_TYPE]];
        if (inventory.packingType != PVO_PACK_NONE)
            [basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_PACK_OT]];
    }
    
    //moved the order of landing page and select location - also i dont think anyone used this, so commenting out for now...
    //[basic_info_rows addObject:[NSNumber numberWithInt:PVO_LAND_ROW_CHANGE_LOCATION]];
}


-(void)pickerValueSelected:(NSNumber*)value
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(editingRow == PVO_LAND_ROW_CURRENT_COLOR)
        inventory.currentColor = [value intValue];
    else if(editingRow == PVO_LAND_ROW_LOAD_TYPE) {
        inventory.loadType = [value intValue];
        if ([del.pricingDB vanline] == ARPIN) {
            [self evaluateNewValuationType:PVO_VALUATION_FVP];
        }
        if(inventory.loadType ==SPECIAL_PRODUCTS){
            ShipmentInfo *s = [del.surveyDB getShipInfo:del.customerID];
            s.itemListID = SPECIAL_PRODUCTS;
            [del.surveyDB updateShipInfo:s];
        } else {
            SurveyCustomer *c = [del.surveyDB getCustomer:del.customerID];
            [del.surveyDB getItemListIDForPricingMode:c.pricingMode];
        }
    } else if(editingRow == PVO_LAND_ROW_PACK_TYPE)
        inventory.packingType = [value intValue];
    else if (editingRow == PVO_LAND_ROW_VALUATION_TYPE)
    {
        [self evaluateNewValuationType:[value intValue]];
    }
    
    //    if(editingRow == PVO_LAND_ROW_CHANGE_LOCATION)
    //    {
    //        //switch all items in current location to new location.
    //        if(currentLoad.pvoLocationID != [value intValue])
    //        {
    //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Change Location"
    //                                                            message:[NSString stringWithFormat:@"Are you sure you would like to change this Location from %@ to %@?  This action cannot be undone.",
    //                                                                     [locations objectForKey:[NSNumber numberWithInt:currentLoad.pvoLocationID]],
    //                                                                     [locations objectForKey:[NSNumber numberWithInt:[value intValue]]]]
    //                                                           delegate:self
    //                                                  cancelButtonTitle:@"No"
    //                                                  otherButtonTitles:@"Yes", nil];
    //            alert.tag = [value intValue];
    //            [alert show];
    //            
    //        }
    //    }
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)updateValueWithField:(UITextField*)field
{
    int row = (int)field.tag;
    
    
    switch (row) {
        case PVO_LAND_ROW_CURRENT_LOT_NUM:
            field.text = [field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            inventory.currentLotNum = field.text;
            break;
        case PVO_LAND_ROW_CONFIRM_LOT_NUM:
            field.text = [field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            inventory.confirmLotNum = field.text;
        case PVO_LAND_ROW_TRAILER_NUMBER:
            inventory.trailerNumber = field.text;
            break;
        case PVO_LAND_ROW_TRACTOR_NUMBER:
            inventory.tractorNumber = field.text;
            break;
        case PVO_LAND_ROW_NEXT_ITEM_ID:
            field.text = [field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self.itemNumberString = field.text;
            inventory.nextItemNum = [field.text intValue];
            break;
        case PVO_LAND_ROW_MPRO_WEIGHT:
            inventory.mproWeight = [field.text intValue];
            break;
        case PVO_LAND_ROW_SPRO_WEIGHT:
            inventory.sproWeight = [field.text intValue];
            break;
        case PVO_LAND_ROW_CONS_WEIGHT:
            inventory.consWeight = [field.text intValue];
            break;
    }
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == PVO_LAND_ROW_USING_SCANNER)
    {
        inventory.usingScanner = sw.on;
        
        [self initializeIncludedRows];
        [self.tableView reloadData];
    }
    else if(sw.tag == PVO_LAND_ROW_NEW_PAGE_PER_LOT)
        inventory.newPagePerLot = sw.on;
    else if(sw.tag == PVO_LAND_ROW_PACK_OT)
        inventory.packingOT = sw.on;
    else if(sw.tag == PVO_LAND_ROW_NO_COND)
        inventory.noConditionsInventory = !sw.on;
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */

- (void)viewWillDisappear:(BOOL)animated {
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if(editingRow == -1)
    {
        if(delegate == nil || ![delegate respondsToSelector:@selector(pvoLandingController:dataEntered:)])
        {//assume delegate will already have handled the save on continue
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            [del.surveyDB updatePVOData:inventory];
        }
    }
    
    [super viewWillDisappear:animated];
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [basic_info_rows count];
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *regname = nil;
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    regname = [NSString stringWithFormat:@"Order: %@\r\n%@ %@", inf.orderNumber, cust.firstName, cust.lastName];
    
    return regname;
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *CellIdentifier = @"ReusableCell";
    LabelTextCell* ltCell = nil;
    SwitchCell* swCell = nil;
    UITableViewCell *simpleCell = nil;
    
    int mproWeight, sproWeight, consWeight;
    
    int row = [[basic_info_rows objectAtIndex:indexPath.row] intValue];
    
    if(row == PVO_LAND_ROW_USING_SCANNER ||
       row == PVO_LAND_ROW_NO_COND ||
       row == PVO_LAND_ROW_NEW_PAGE_PER_LOT ||
       row == PVO_LAND_ROW_PACK_OT)
    {
        swCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        
        if (swCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            swCell = [nib objectAtIndex:0];
            
            [swCell.switchOption addTarget:self
                                    action:@selector(switchChanged:)
                          forControlEvents:UIControlEventValueChanged];
        }
        swCell.switchOption.tag = row;
        
        if(row == PVO_LAND_ROW_USING_SCANNER)
        {
            swCell.switchOption.on = inventory.usingScanner;
            swCell.labelHeader.text = @"Use Scanner";
        }
        else if(row == PVO_LAND_ROW_NO_COND)
        {
            swCell.switchOption.on = !inventory.noConditionsInventory;
            swCell.labelHeader.text = @"Conditions Inv.";
        }
        else if(row == PVO_LAND_ROW_NEW_PAGE_PER_LOT)
        {
            swCell.switchOption.on = inventory.newPagePerLot;
            swCell.labelHeader.text = @"New Page Per Lot";
        }
        else if(row == PVO_LAND_ROW_PACK_OT)
        {
            swCell.switchOption.on = inventory.packingOT;
            swCell.labelHeader.text = @"Packing OT";
        }
    }
    else if(row == PVO_LAND_ROW_CURRENT_LOT_NUM ||
            row == PVO_LAND_ROW_CONFIRM_LOT_NUM ||
            row == PVO_LAND_ROW_NEXT_ITEM_ID ||
            row == PVO_LAND_ROW_TRACTOR_NUMBER ||
            row == PVO_LAND_ROW_TRAILER_NUMBER ||
            row == PVO_LAND_ROW_MPRO_WEIGHT ||
            row == PVO_LAND_ROW_SPRO_WEIGHT ||
            row == PVO_LAND_ROW_CONS_WEIGHT)
    {
        
        ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
        if (ltCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
            ltCell = [nib objectAtIndex:0];
            [ltCell setPVOView];
            [ltCell.tboxValue addTarget:self
                                 action:@selector(textFieldDoneEditing:)
                       forControlEvents:UIControlEventEditingDidEndOnExit];
            ltCell.tboxValue.delegate = self;
        }
        ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        
        ltCell.tboxValue.tag = row;
        ltCell.tboxValue.enabled = true;
        
        switch (row) {
            case PVO_LAND_ROW_CURRENT_LOT_NUM:
                ltCell.labelHeader.text = @"Current Lot #";
                ltCell.tboxValue.text = inventory.currentLotNum;
                ltCell.tboxValue.keyboardType = [PVOBarcodeValidation getKeyboardTypeForLotNumber:[CustomerUtilities customerPricingMode]
                                                                                withCurrentLotNum:inventory.currentLotNum];
                // 1148 OnTime Defect
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                
                if (ltCell.tboxValue.keyboardType == UIKeyboardTypeNumberPad)
                    ltCell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case PVO_LAND_ROW_CONFIRM_LOT_NUM:
                ltCell.labelHeader.text = @"Confirm Lot #";
                ltCell.tboxValue.text = inventory.confirmLotNum;
                ltCell.tboxValue.keyboardType = [PVOBarcodeValidation getKeyboardTypeForLotNumber:[CustomerUtilities customerPricingMode]
                                                                                withCurrentLotNum:inventory.currentLotNum];
                // 1148 OnTime Defect
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                
                if (ltCell.tboxValue.keyboardType == UIKeyboardTypeNumberPad)
                    ltCell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case PVO_LAND_ROW_TRACTOR_NUMBER:
                ltCell.labelHeader.text = @"Tractor #";
                ltCell.tboxValue.text = inventory.tractorNumber;
                ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                break;
            case PVO_LAND_ROW_TRAILER_NUMBER:
                ltCell.labelHeader.text = @"Trailer #";
                ltCell.tboxValue.text = inventory.trailerNumber;
                ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                break;
            case PVO_LAND_ROW_NEXT_ITEM_ID:
                ltCell.labelHeader.text = @"Starting Item #";
                if(inventory.nextItemNum < 10)
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"00%d", inventory.nextItemNum];
                else if(inventory.nextItemNum < 100)
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"0%d", inventory.nextItemNum];
                else
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", inventory.nextItemNum];
                self.itemNumberString = ltCell.tboxValue.text;
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                break;
            case PVO_LAND_ROW_MPRO_WEIGHT:
                ltCell.labelHeader.text = @"MPRO Weight";
                
                mproWeight = [inventory getInventoryMPROWeight];
                if (mproWeight > 0)
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", mproWeight];
                else
                    ltCell.tboxValue.text = @"0";
                ltCell.tboxValue.enabled = NO;
                
                break;
            case PVO_LAND_ROW_SPRO_WEIGHT:
                ltCell.labelHeader.text = @"SPRO Weight";
                sproWeight = [inventory getInventorySPROWeight];
                if (sproWeight > 0)
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", sproWeight];
                else
                    ltCell.tboxValue.text = @"0";
                ltCell.tboxValue.enabled = NO;

                break;
            case PVO_LAND_ROW_CONS_WEIGHT:
                ltCell.labelHeader.text = @"CONS Weight";
                consWeight = [inventory getInventoryConsWeight];
                if (consWeight > 0)
                    ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", consWeight];
                else
                    ltCell.tboxValue.text = @"0";
                ltCell.tboxValue.enabled = NO;

                break;
        }
    }
    else
    {
        simpleCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (simpleCell == nil) {
            simpleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if(row == PVO_LAND_ROW_CURRENT_COLOR)
            simpleCell.textLabel.text = [NSString stringWithFormat:@"Tag Color: %@",
                                         [colors objectForKey:[NSNumber numberWithInt:inventory.currentColor]]];
        else if(row == PVO_LAND_ROW_LOAD_TYPE)
        {
            simpleCell.textLabel.text = [NSString stringWithFormat:@"Load Type: %@",
                                         [loadTypes objectForKey:[NSNumber numberWithInt:inventory.loadType]]];
            if (inventory.lockLoadType)
                simpleCell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if(row == PVO_LAND_ROW_PACK_TYPE)
        {
            simpleCell.textLabel.text = [NSString stringWithFormat:@"Pack Type: %@",
                                         [packTypes objectForKey:[NSNumber numberWithInt:inventory.packingType]]];
        }
        else if(row == PVO_LAND_ROW_CHANGE_LOCATION)
        {
            simpleCell.accessoryType = UITableViewCellAccessoryNone;
            simpleCell.textLabel.text = @"Switch Location";
        }
        else if (row == PVO_LAND_ROW_VALUATION_TYPE)
        {
            
            if (inventory.loadType == MILITARY && [del.pricingDB vanline] == ARPIN) {
                inventory.valuationType = PVO_VALUATION_FVP;
                simpleCell.userInteractionEnabled = NO;
                simpleCell.accessoryType = UITableViewCellAccessoryNone;
                simpleCell.textLabel.textColor = [UIColor darkGrayColor];
            } else {
                simpleCell.userInteractionEnabled = YES;
                simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                simpleCell.textLabel.textColor = [UIColor blackColor];
                
            }
            simpleCell.textLabel.text = [NSString stringWithFormat:@"Valuation Type: %@",
                                         inventory.valuationType > 0 ? [valuationTypes objectForKey:[NSNumber numberWithInt:inventory.valuationType]] : @"None"];
        }
    }
    
    
    return ltCell != nil ? (UITableViewCell*)ltCell : swCell != nil ? (UITableViewCell*)swCell : (UITableViewCell*)simpleCell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [[basic_info_rows objectAtIndex:indexPath.row] intValue];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(row == PVO_LAND_ROW_CURRENT_COLOR)
    {
        editingRow = row;
        [del pushPickerViewController:@"Current Color"
                          withObjects:colors
                 withCurrentSelection:[NSNumber numberWithInt:inventory.currentColor]
                           withCaller:self
                          andCallback:@selector(pickerValueSelected:)
                     andNavController:self.navigationController];
    }
    else if(!inventory.lockLoadType && row == PVO_LAND_ROW_LOAD_TYPE)
    {
        editingRow = row;
        [del pushPickerViewController:@"Load Type"
                          withObjects:loadTypes
                 withCurrentSelection:[NSNumber numberWithInt:inventory.loadType]
                           withCaller:self
                          andCallback:@selector(pickerValueSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == PVO_LAND_ROW_PACK_TYPE)
    {
        editingRow = row;
        [del pushPickerViewController:@"Packing Type"
                          withObjects:packTypes
                 withCurrentSelection:[NSNumber numberWithInt:inventory.packingType]
                           withCaller:self
                          andCallback:@selector(pickerValueSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == PVO_LAND_ROW_VALUATION_TYPE)
    {
        editingRow = row;
        [del pushPickerViewController:@"Valuation Type"
                          withObjects:valuationTypes
                 withCurrentSelection:[NSNumber numberWithInt:inventory.valuationType]
                           withCaller:self
                          andCallback:@selector(pickerValueSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == PVO_LAND_ROW_CHANGE_LOCATION)
    {
        editingRow = row;
        [del popTablePickerController:@"Locations"
                          withObjects:locations
                 withCurrentSelection:nil
                           withCaller:self
                          andCallback:@selector(pickerValueSelected:)
                      dismissOnSelect:TRUE
                    andViewController:self];
    }
    
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    int row = textField.tag;
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    newText = [newText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (row == PVO_LAND_ROW_CURRENT_LOT_NUM)
    {
        NSString *err = nil;
        if (newText != nil && [newText length] > 0 && ![PVOBarcodeValidation validateLotNumber:newText outError:&err])
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@", err] withTitle:@"Invalid Lot Number"];
            return NO;
        }
    }
    else if ((row == PVO_LAND_ROW_MPRO_WEIGHT || row == PVO_LAND_ROW_SPRO_WEIGHT || row == PVO_LAND_ROW_CONS_WEIGHT) && (newText != nil && [newText length] > 4)) //Defect 1042
    {
        NSString* weightType = @"MPRO";
        
        if (row == PVO_LAND_ROW_SPRO_WEIGHT)
            weightType = @"SPRO";
        else if (row == PVO_LAND_ROW_CONS_WEIGHT)
            weightType = @"CONS";
        
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@ Weight cannot exceed 4 numeric characters in length.", weightType]
                           withTitle:[NSString stringWithFormat:@"Invalid %@ Weight", weightType]];
        
        return NO;
    }
    return YES;
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        //I'm using the selected new valuation type as the tag and assigning it back to inventory.valuation type
        if (alertView.tag == PVO_VALUATION_FVP || alertView.tag == PVO_VALUATION_RELEASED)
        {
            if (alertView.tag == PVO_VALUATION_RELEASED)
            {
                //delete high value items? just remove the high value flag
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                [del.surveyDB removeHighValueCostForCustomerItems:del.customerID];
            }
            inventory.valuationType = alertView.tag;
            [self.tableView reloadData];
        }
    }
}


@end

