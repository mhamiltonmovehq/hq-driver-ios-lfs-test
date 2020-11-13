//
//  BasicInfoController.m
//  Survey
//
//  Created by Tony Brame on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BasicInfoController.h"
#import "SurveyCustomer.h"
#import "SurveyAppDelegate.h"
#import "CustomerOptionsController.h"
#import "RootViewController.h"
#import "TextCell.h"
#import "SwitchCell.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"
#import "LabelTextCell.h"
#import "FloatingLabelTextCell.h"
#import "EmailTableViewCell.h"


@implementation BasicInfoController

@synthesize custID, cust, newCustomerView, tboxCurrent, sync, pricingModes, inventoryTypes, popover, rows, info, officePhone, mobilePhone, homePhone, pvoRoomSummaryController;
@synthesize customerPricingModesNew;

SurveyPhone *selectedPhoneForAccessory;

-(void)initializeRows
{
    DriverData *data = [del.surveyDB getDriverData];
    
    [rows removeAllObjects];
    
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_LAST_NAME]];
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_FIRST_NAME]];
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_ACCOUNT]];
    
    if (data.driverType != PVO_DRIVER_TYPE_PACKER) {
        [rows addObject:[NSNumber numberWithInt:BASIC_INFO_EMAIL]];
    }
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_ESTIMATED_WEIGHT]];
    
    if(del.viewType == OPTIONS_PVO_VIEW) {
        [rows addObject:[NSNumber numberWithInt:BASIC_INFO_ORDER_NUMBER]];
        
        PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
        if (inventory != nil && inventory.loadType == MILITARY) {
            [rows addObject:[NSNumber numberWithInt:BASIC_INFO_GBL_NUMBER]];
        }
    }
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_PRICING_MODE]];
    
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_OFFICE_PHONE]];
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_MOBILE_PHONE]];
    [rows addObject:[NSNumber numberWithInt:BASIC_INFO_HOME_PHONE]];
    
    if(!newCustomerView)
    {
        CubeSheet *cs = [del.surveyDB openCubeSheet:custID];
        if([[del.surveyDB getRoomSummaries:cs customerID:custID] count] >= 0) {
            [rows addObject:[NSNumber numberWithInt:BASIC_INFO_PVO_VIEW_SURVEY]];
            
            if ([[del.surveyDB getSurveyedPackingItems:cs.csID].list count] > 0) {
                [rows addObject:[NSNumber numberWithInt:BASIC_INFO_PVO_VIEW_PACK_SUMMARY]];
            }
        }
        if ([del.surveyDB hasPVOReceivableItems:custID receivedType:PACKER_INVENTORY ignoreReceived:TRUE]) {
            [rows addObject:[NSNumber numberWithInt:BASIC_INFO_PVO_VIEW_PACKER_INVENTORY]];
        }
    }
    if ([AppFunctionality enableLanguageSelection:self.cust.pricingMode])
        [rows addObject:[NSNumber numberWithInt:BASIC_INFO_LANGUAGE]];   
}

- (void)moveItems:(int)newPricingMode language:(int)newLanguageCode
{
    // move the cubesheet room IDs from the old custom item list to the new one
    NSArray *arr = [del.surveyDB getAllSurveyedItems:custID];
    NSMutableArray *oldRoomIDs = [NSMutableArray array];
    NSMutableArray *oldItemIDs = [NSMutableArray array];
    for (SurveyedItemsList *sil in arr) {
        [oldRoomIDs addObject:@(sil.room.roomID)];
        for (NSString *key in [sil.list allKeys]) {
            SurveyedItem *sItem = sil.list[key];
            if (![oldItemIDs containsObject:@(sItem.itemID)]) {
                [oldItemIDs addObject:@(sItem.itemID)];
            }
        }
    }
    
    NSMutableArray *newRoomIDs = [NSMutableArray array];
    for (NSNumber *n in oldRoomIDs) {
        Room *oldRoom = [del.surveyDB getRoomIgnoringItemListID:[n intValue]];
        Room *newRoom = [del.surveyDB getRoomByName:oldRoom.roomName languageCode:newLanguageCode itemListID:newPricingMode];
        if (newRoom.roomID > 0) {
            [newRoomIDs addObject:@(newRoom.roomID)];
        } else {
            [newRoomIDs addObject:n];
        }
    }
    
    NSMutableArray *newItemIDs = [NSMutableArray array];
    for (NSNumber *n in oldItemIDs) {
        Item *oldItem = [del.surveyDB getItem:[n intValue]];
        Item *newItem = [del.surveyDB getItemByItemName:custID itemName:oldItem.name languageCode:newLanguageCode itemListID:newPricingMode];
        if (newItem.itemID > 0) {
            [newItemIDs addObject:@(newItem.itemID)];
        } else {
            [newItemIDs addObject:n];
        }
    }
    
    // go through the tables and switch the old room and item IDs for the new ones
    for (int idx = 0; idx < [newRoomIDs count]; idx++) {
        [del.surveyDB updateRoomIDsForSurveyedItems:[oldRoomIDs[idx] intValue] toNewRoomID:[newRoomIDs[idx] intValue]];
    }
    
    for (int idx = 0; idx < [newItemIDs count]; idx++) {
        [del.surveyDB updateItemIDsForSurveyedItems:[oldItemIDs[idx] intValue] toNewItemID:[newItemIDs[idx] intValue]];
    }
}

-(void)pricingModeChanged:(NSNumber*)newID
{
    int newPricingMode = [newID intValue];
    
    [self moveItems:newPricingMode language:info.language];
    
    cust.pricingMode = [newID intValue];
    if ([newID intValue] != CNGOV && [newID intValue] != CNCIV) {
        //if its not canada reset itemlist and language to 0 (non-canada, english)
        info.itemListID = 0;
        info.language = 0;
    } else
        //find the customItemList id for the pricing mode and update the current itemlist id
        info.itemListID = [del.surveyDB getItemListIDForPricingMode:[newID intValue]];
    
    [del.surveyDB updateCustomerPricingMode:custID pricingMode:cust.pricingMode];
    [del.surveyDB updateShipInfo:custID languageCode:info.language customItemList:info.itemListID];
    
    [self.tableView reloadData];
}

-(void)languageChanged:(NSNumber *)newID
{
    self.info.language = [newID intValue];
    [del.surveyDB updateShipInfo:custID languageCode:info.language customItemList:info.itemListID];
}

-(void)inventoryTypeChanged:(NSNumber*)newID
{
    cust.inventoryType = [newID intValue];
    [self.tableView reloadData];
}

-(void)syncSwitched:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == BASIC_INFO_SYNC) {
        sync.syncToQM = sw.on;
    } else if(sw.tag == BASIC_INFO_PVO_SYNC) {
        sync.syncToPVO = sw.on;
    }
}

-(void) emailSelected:(id)sender
{
    [self updateCustomerValueWithField:tboxCurrent];
    
    if([cust.email length] > 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Email"
                              message:[NSString stringWithFormat:@"Would you like to send an email to %@?", cust.email]
                              delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil];
        
        [alert show];
    } else {
        [SurveyAppDelegate showAlert:@"You must have an email address entered to send a message." withTitle:@"Email Required"];
    }
    
}

//functions called when in the new customer view
-(void)save:(id)sender
{
    if(tboxCurrent != nil) {
        [self updateCustomerValueWithField:tboxCurrent];
    }
    
    if(cust.lastName == nil || [cust.lastName length] == 0) {
        [SurveyAppDelegate showAlert:@"Customer must have a last name to be saved." withTitle:@"Name Required"];
        return;
    }
    
    if(newCustomerView == YES) {
        sync.createdOnDevice = TRUE;
        cust.custID = [del.surveyDB insertNewCustomer:cust
                                             withSync:sync
                                          andShipInfo:info];
    } else {
        [del.surveyDB updateCustomer:cust];
        [del.surveyDB updateCustomerSync:sync];
        [del.surveyDB updateShipInfo:info];
    }
    
    [self insertOrUpdatePhone:officePhone];
    [self insertOrUpdatePhone:mobilePhone];
    [self insertOrUpdatePhone:homePhone];
    
    //call cancel to clear the view
    [self cancel:nil];
}


-(void)cancel:(id)sender
{
    // if sender is not nil, the user tapped the Cancel button
    // if sender is nil, the user tapped the Save button and the code is coming here to close out the view controller
    if (sender != nil) {
        if (originalPricingMode != cust.pricingMode) {
            [self moveItems:originalPricingMode language:originalLanguage];
            [del.surveyDB updateCustomerPricingMode:custID pricingMode:originalPricingMode];
            [del.surveyDB updateShipInfo:custID languageCode:originalLanguage customItemList:originalItemListID];
        } else if (originalLanguage != info.language) {
            NSLog(@"language changed");
        }
    }
    
    @try {
        if(popover != nil) {
            [popover dismissPopoverAnimated:YES];
            [popover.delegate popoverControllerDidDismissPopover:popover];
        }
        
        if(newCustomerView == YES) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else
            [del.navController popViewControllerAnimated:YES];
        
        
        if(tboxCurrent != nil) {
            [tboxCurrent resignFirstResponder];
            self.tboxCurrent = nil;
        }
    } @catch(NSException *exc) {
        [SurveyAppDelegate handleException:exc];
    }
}

-(void)updateCustomerValueWithField:(UITextField*)fld
{
    if(cust == nil)
        return;
    
    switch (fld.tag) {
        case BASIC_INFO_ACCOUNT:
            cust.account = fld.text;
            break;
        case BASIC_INFO_LAST_NAME:
            cust.lastName = fld.text;
            break;
        case BASIC_INFO_FIRST_NAME:
            cust.firstName = fld.text;
            break;
        case BASIC_INFO_EMAIL:
            cust.email = fld.text;
            break;
        case BASIC_INFO_ORDER_NUMBER:
            info.orderNumber = fld.text;
            break;
        case BASIC_INFO_GBL_NUMBER:
            info.gblNumber = fld.text;
            break;
        case BASIC_INFO_ESTIMATED_WEIGHT:
            @try {
                cust.estimatedWeight = [fld.text intValue];
            } @catch(NSException *exc) {
                cust.estimatedWeight = 0;
            }
            break;
        case BASIC_INFO_OFFICE_PHONE:
            officePhone.number = fld.text;
            break;
        case BASIC_INFO_MOBILE_PHONE:
            mobilePhone.number = fld.text;
            break;
        case BASIC_INFO_HOME_PHONE:
            homePhone.number = fld.text;
            break;
    }
}

-(void)insertOrUpdatePhone:(SurveyPhone*)phone {
    if(phone.custID <= 0) {
        phone.custID = cust.custID;
        [del.surveyDB insertPhone:phone];
    } else {
        [del.surveyDB updatePhone:phone];
    }
}

#pragma mark - Table view data source and delegate -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *SwitchIdentifier = @"SwitchCell";
    static NSString *CellIdentifier = @"SimpleCell";
    FloatingLabelTextCell* cell = nil;
    SwitchCell *switchCell = nil;
    EmailTableViewCell *emailCell = nil;
    UITableViewCell *simpleCell = nil;
    
    int row = [[rows objectAtIndex:[indexPath row]] intValue];
    if(row == BASIC_INFO_SYNC || row == BASIC_INFO_PVO_SYNC) {
        switchCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchIdentifier];
        
        if (switchCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            switchCell = [nib objectAtIndex:0];
            
            [switchCell.switchOption addTarget:self
                                        action:@selector(syncSwitched:)
                              forControlEvents:UIControlEventValueChanged];
        }
        
        switchCell.switchOption.tag = row;
        switchCell.labelHeader.text = @"Synchronize";
        
        if(row == BASIC_INFO_SYNC)
            switchCell.switchOption.on = sync.syncToQM > 0;
        else if(row == BASIC_INFO_PVO_SYNC)
            switchCell.switchOption.on = sync.syncToPVO > 0;
        
    } else if (row == BASIC_INFO_PRICING_MODE || row == BASIC_INFO_PVO_VIEW_SURVEY ||
             row == BASIC_INFO_PVO_VIEW_PACKER_INVENTORY || row == BASIC_INFO_LANGUAGE ||
             row == BASIC_INFO_INVENTORY_TYPE || row == BASIC_INFO_PVO_VIEW_PACK_SUMMARY) {
        simpleCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (simpleCell == nil) {
            simpleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if(row == BASIC_INFO_PRICING_MODE) {
            if([pricingModes objectForKey:[NSNumber numberWithInt:cust.pricingMode]] == nil) {
                simpleCell.textLabel.text = @"Unknown Pricing Mode";
            } else {
                NSString *pricingModeLabel = ([del.pricingDB vanline] == ARPIN) ? @"Registration Type" : @"Pricing Mode";
                simpleCell.textLabel.text = [NSString stringWithFormat:@"%@: %@", pricingModeLabel, [pricingModes objectForKey:[NSNumber numberWithInt:cust.pricingMode]]];
            }
        } else if(row == BASIC_INFO_PVO_VIEW_SURVEY) {
            simpleCell.textLabel.text = @"View Survey Results";
        } else if (row == BASIC_INFO_PVO_VIEW_PACK_SUMMARY) {
            simpleCell.textLabel.text = @"View Survey Packing Summary";
        } else if (row == BASIC_INFO_PVO_VIEW_PACKER_INVENTORY) {
            simpleCell.textLabel.text = @"View Packer's Inventory";
        } else if (row == BASIC_INFO_INVENTORY_TYPE) {
            simpleCell.textLabel.text = [NSString stringWithFormat:@"Inventory Type: %@", [inventoryTypes objectForKey:[NSNumber numberWithInt:cust.inventoryType]]];
        } else if (row == BASIC_INFO_LANGUAGE) {
            simpleCell.textLabel.text = [self.languages objectForKey:@(self.info.language)];
        }
    } else if(row == BASIC_INFO_EMAIL) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EmailCell" owner:self options:nil];
        emailCell = [nib objectAtIndex:0];
        
        emailCell.emailInput.enabled = (![AppFunctionality lockFieldsOnSourcedFromServer] || !info.sourcedFromServer);
        
        [emailCell.emailInput setDelegate:self];
        emailCell.emailInput.returnKeyType = UIReturnKeyDone;
        emailCell.accessoryType = UITableViewCellAccessoryNone;
        
        [emailCell.emailInput addTarget:self
                                 action:@selector(textFieldDoneEditing:)
                       forControlEvents:UIControlEventEditingDidEndOnExit];
        
        [emailCell.sendEmailBtn addTarget:self action:@selector(emailSelected:) forControlEvents:UIControlEventTouchUpInside];
        
        emailCell.emailInput.autocorrectionType = UITextAutocorrectionTypeNo;
        emailCell.emailInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
        emailCell.emailInput.text = cust.email;
        emailCell.emailInput.textAlignment = NSTextAlignmentLeft;
        emailCell.emailInput.tag = BASIC_INFO_EMAIL;
        emailCell.emailInput.placeholder = @"Email";
        emailCell.emailInput.keyboardType = UIKeyboardTypeEmailAddress;
        
        if(tboxCurrent == emailCell.emailInput)
            self.tboxCurrent = nil;
    } else {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FloatingLabelTextCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        
        cell.tboxValue.enabled = (![AppFunctionality lockFieldsOnSourcedFromServer] || !info.sourcedFromServer);
        cell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
        
        [cell.tboxValue setDelegate:self];
        cell.tboxValue.returnKeyType = UIReturnKeyDone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.tboxValue addTarget:self
                           action:@selector(textFieldDoneEditing:)
                 forControlEvents:UIControlEventEditingDidEndOnExit];
        
        //if it wasn't created yet, go ahead and load the data to it now.
        switch (row) {
            case BASIC_INFO_ACCOUNT:
                cell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.tboxValue.text = cust.account;
                cell.tboxValue.placeholder = @"Account";
                cell.tboxValue.tag = BASIC_INFO_ACCOUNT;
                cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                break;
                break;
            case BASIC_INFO_FIRST_NAME:
                cell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.tboxValue.text = cust.firstName;
                cell.tboxValue.placeholder = @"First Name";
                cell.tboxValue.tag = BASIC_INFO_FIRST_NAME;
                cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                break;
            case BASIC_INFO_LAST_NAME:
                cell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.tboxValue.text = cust.lastName;
                cell.tboxValue.placeholder = @"Last Name";
                cell.tboxValue.tag = BASIC_INFO_LAST_NAME;
                cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                break;
            case BASIC_INFO_ESTIMATED_WEIGHT:
                if(cust.estimatedWeight == 0)
                    cell.tboxValue.text = @"";
                else
                    cell.tboxValue.text = [NSString stringWithFormat:@"%d", cust.estimatedWeight];
                cell.tboxValue.placeholder = @"Estimated Weight";
                cell.tboxValue.tag = BASIC_INFO_ESTIMATED_WEIGHT;
                cell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case BASIC_INFO_ORDER_NUMBER:
                cell.tboxValue.text = info.orderNumber;
                cell.tboxValue.placeholder = @"Order Number";
                cell.tboxValue.tag = BASIC_INFO_ORDER_NUMBER;
                cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case BASIC_INFO_GBL_NUMBER:
                cell.tboxValue.text = info.gblNumber;
                cell.tboxValue.placeholder = @"GBL Number";
                cell.tboxValue.tag = BASIC_INFO_GBL_NUMBER;
                cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case BASIC_INFO_OFFICE_PHONE:
                cell.tboxValue.text = [CustomerUtilities formatPhoneString:(NSMutableString*)officePhone.number];
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
                cell.tboxValue.placeholder = @"Office Phone";
                cell.tboxValue.tag = BASIC_INFO_OFFICE_PHONE;
                cell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case BASIC_INFO_MOBILE_PHONE:
                cell.tboxValue.text = [CustomerUtilities formatPhoneString:(NSMutableString*)mobilePhone.number];
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
                cell.tboxValue.placeholder = @"Mobile Phone";
                cell.tboxValue.tag = BASIC_INFO_MOBILE_PHONE;
                cell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            case BASIC_INFO_HOME_PHONE:
                cell.tboxValue.text = [CustomerUtilities formatPhoneString:(NSMutableString*)homePhone.number];
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
                cell.tboxValue.placeholder = @"Home Phone";
                cell.tboxValue.tag = BASIC_INFO_HOME_PHONE;
                cell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                cell.tboxValue.clearsOnBeginEditing = NO;
                break;
            default:
                break;
                
        }
        
        if(tboxCurrent == cell.tboxValue)
            self.tboxCurrent = nil;
    }
    
    UITableViewCell *returnCell;
    if (cell != nil)
        returnCell = cell;
    else if(switchCell != nil)
        returnCell = switchCell;
    else if(emailCell != nil)
        returnCell = emailCell;
    else
        returnCell = simpleCell;
    return returnCell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [[rows objectAtIndex:[indexPath row]] intValue];
    if(row == BASIC_INFO_PRICING_MODE || row == BASIC_INFO_PVO_VIEW_SURVEY ||
       row == BASIC_INFO_PVO_VIEW_PACKER_INVENTORY || row == BASIC_INFO_LANGUAGE ||
       row == BASIC_INFO_INVENTORY_TYPE || row == BASIC_INFO_PVO_VIEW_PACK_SUMMARY)
        return indexPath;
    else
        return nil;
}

- (void)callOrTextPhone: (SurveyPhone*) phone{
    if([phone.number length] == 0)
        [SurveyAppDelegate showAlert:@"You must have a phone number entered to call or text." withTitle:@"Number Required"];
    else
    {
        if(tboxCurrent != nil)
        {
            [self updateCustomerValueWithField:tboxCurrent];
            [tboxCurrent resignFirstResponder];
        }
        
        //ask them to perform actions - call/sms
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"What action would you like to take for this phone number?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Call", @"SMS Message", nil];
        [sheet showInView:self.view];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SurveyPhone* phone;
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    if (row == BASIC_INFO_OFFICE_PHONE) {
        phone = officePhone;
    } else if (row == BASIC_INFO_MOBILE_PHONE) {
        phone = mobilePhone;
    } else if (row == BASIC_INFO_HOME_PHONE) {
        phone = homePhone;
    }
    selectedPhoneForAccessory = phone;
    
    //call or text the phone number...
    [self callOrTextPhone: phone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    if(row == BASIC_INFO_PVO_VIEW_SURVEY)
    {
        SurveySummaryController *surveySummaryController = [[SurveySummaryController alloc] initWithNibName:@"SurveySummaryView" bundle:nil];
        surveySummaryController.title = @"Room Summary";
        surveySummaryController.customerID = custID;
        surveySummaryController.cubesheet = [del.surveyDB openCubeSheet:custID];
        [self.navigationController pushViewController:surveySummaryController animated:YES];
    }
    else if (row == BASIC_INFO_PVO_VIEW_PACK_SUMMARY)
    {
        //load the survey view...
        ItemViewController *itemView = [[ItemViewController alloc] initWithNibName:@"ItemView" bundle:nil];
        itemView.cubesheet = [del.surveyDB openCubeSheet:custID];
        itemView.isPackingSummary = YES;
        
        [self.navigationController pushViewController:itemView animated:YES];
    }
    else if (row == BASIC_INFO_PVO_VIEW_PACKER_INVENTORY)
    {
        if (pvoRoomSummaryController == nil)
            pvoRoomSummaryController = [[PVORoomSummaryController alloc] initWithNibName:@"PVORoomSummaryView" bundle:nil];
        
        pvoRoomSummaryController.inventory = nil;
        pvoRoomSummaryController.currentLoad = nil;
        pvoRoomSummaryController.isPackersInvSummary = TRUE;
        [self.navigationController pushViewController:pvoRoomSummaryController animated:YES];
    }
    else if (row == BASIC_INFO_LANGUAGE)
    {
        [del pushPickerViewController:@"Language"
                          withObjects:self.languages
                 withCurrentSelection:@(self.info.language)
                           withCaller:self
                          andCallback:@selector(languageChanged:)
                     andNavController:self.navigationController];
    }
    else if (row == BASIC_INFO_PRICING_MODE)
    {
        if(self.customerPricingModesNew != nil && [self.customerPricingModesNew count] > 0)
        {
            [del pushPickerViewController:@"Pricing Mode"
                              withObjects:self.customerPricingModesNew
                     withCurrentSelection:[NSNumber numberWithInt:cust.pricingMode]
                               withCaller:self
                              andCallback:@selector(pricingModeChanged:)
                         andNavController:self.navigationController];
        }
        
    }
    else if (row == BASIC_INFO_INVENTORY_TYPE)
    {
        if (self.inventoryTypes != nil && [self.inventoryTypes count] > 0)
        {
            [del pushPickerViewController:@"Inventory Types"
                              withObjects:self.inventoryTypes
                     withCurrentSelection:[NSNumber numberWithInt:cust.inventoryType]
                               withCaller:self
                              andCallback:@selector(inventoryTypeChanged:)
                         andNavController:self.navigationController];
        }
    }
}

#pragma mark - UITextFieldDelegate -

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateCustomerValueWithField:textField];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if(textField.tag == BASIC_INFO_OFFICE_PHONE) {
        officePhone.number = @"";
    } else if(textField.tag == BASIC_INFO_MOBILE_PHONE) {
        mobilePhone.number = @"";
    } else if(textField.tag == BASIC_INFO_HOME_PHONE) {
        homePhone.number = @"";
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSInteger tag = textField.tag;
    if(tag != BASIC_INFO_OFFICE_PHONE &&
       tag != BASIC_INFO_MOBILE_PHONE &&
       tag != BASIC_INFO_HOME_PHONE)
        return YES;
    
    //get my current string...
    NSMutableString *str = [[NSMutableString alloc] initWithString:textField.text];
    
    //they are deleting the number before the dash, delete both...
    if(range.location == 4 && range.length == 1)
    {
        range.location = 3;
        range.length = 2;
    }
    //insert string
    [str replaceCharactersInRange:range withString:string];
    
    [str replaceOccurrencesOfString:@"(" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
    [str replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
    [str replaceOccurrencesOfString:@")" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
    [str replaceOccurrencesOfString:@"-" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
    
    NSMutableString * newString = [CustomerUtilities formatPhoneString:str];
    if(tag == BASIC_INFO_OFFICE_PHONE) {
        officePhone.number = newString;
    } else if(tag == BASIC_INFO_MOBILE_PHONE) {
        mobilePhone.number = newString;
    } else if(tag == BASIC_INFO_HOME_PHONE) {
        homePhone.number = newString;
    }
    
    textField.text = newString;
    
    return NO;
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - UIAlertViewDelegate -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(alertView.tag == PVO_SYNC_ALERT_DRIVER_PACKER)
        {
            DriverData *data = [del.surveyDB getDriverData];
            data.driverType = buttonIndex + 1;
            [del.surveyDB updateDriverData:data];
            [self.tableView reloadData];
        }
        else
        {
            //send a gd email...
            NSURL *url;
            url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", cust.email]];
            
            if([[UIApplication sharedApplication] canOpenURL:url])
                [[UIApplication sharedApplication] openURL:url];
            else
                [SurveyAppDelegate showAlert:@"Your device does not support this type of functionality." withTitle:@"Error"];
        }
    }
}

#pragma mark - UIActionSheetDelegate -

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        NSURL *url;
        
        NSMutableString *num = [[NSMutableString alloc] initWithString:selectedPhoneForAccessory.number];
        [num replaceOccurrencesOfString:@"(" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
        [num replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
        [num replaceOccurrencesOfString:@")" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
        [num replaceOccurrencesOfString:@"-" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
        
        if(buttonIndex == 0) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", num]];
        } else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", num]];
        }
        
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            NSString *error = [NSString stringWithFormat:@"Error Contacting %@", num];
            [SurveyAppDelegate showAlert:@"Your device does not support this type of functionality." withTitle:error];
        }
    }
}

#pragma mark - View lifecycle -

- (void)viewDidLoad
{
    del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    //if new customer view, add buttons and handlers.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    
    rows = [[NSMutableArray alloc] init];
    
    [super viewDidLoad];
    
    NSDictionary *dict = [CustomerUtilities getPricingModes];
    self.pricingModes = dict;
    
    dict = [CustomerUtilities getInventoryTypes];
    self.inventoryTypes = dict;
    
    dict = [AppFunctionality getPricingModesForNewJob];
    self.customerPricingModesNew = dict;
    
    if (newCustomerView == NO) {
        self.cust = [del.surveyDB getCustomer:custID];
        self.sync = [del.surveyDB getCustomerSync:custID];
        self.info = [del.surveyDB getShipInfo:custID];
        NSMutableArray *phones = [del.surveyDB getCustomerPhones:custID withLocationID:ORIGIN_LOCATION_ID];
        for(SurveyPhone *phone in phones) {
            // 1-2-3 == mobile-home-office from PhoneTypes table in surveyDB (no enum/obj holds it)
            NSInteger typeId = phone.type.phoneTypeID;
            if (typeId == 1) {
                if (mobilePhone == nil) mobilePhone = phone;
            } else if (typeId == 2) {
                if (homePhone == nil) homePhone = phone;
            } else if (typeId == 3) {
                if (officePhone == nil) officePhone = phone;
            }
        }
    }
    else {
        self.cust = [[SurveyCustomer alloc] init];
        self.sync = [[SurveyCustomerSync alloc] init];
        self.info = [[ShipmentInfo alloc] init];
        self.info.gblNumber = @"";
        self.info.orderNumber = @"";
        self.cust.pricingMode = INTERSTATE;
        if (self.customerPricingModesNew != nil && [self.customerPricingModesNew count] > 0)
            cust.pricingMode = [[[self.customerPricingModesNew allValues] objectAtIndex:0] intValue]; //first value in pricing mode dictionary
        
        if ([del.surveyDB isAutoInventoryUnlocked])
            self.cust.inventoryType = AUTO;
        else
            self.cust.inventoryType = STANDARD;
    }
    
    // Initializes phones if null after attempting to load
    self.officePhone = [CustomerUtilities setupContactPhone:officePhone withPhoneTypeId:3];
    self.mobilePhone = [CustomerUtilities setupContactPhone:mobilePhone withPhoneTypeId:1];
    self.homePhone = [CustomerUtilities setupContactPhone:homePhone withPhoneTypeId:2];
    
    originalPricingMode = cust.pricingMode;
    originalLanguage = info.language;
    originalItemListID = info.itemListID;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.languages = [del.surveyDB getLanguages];
    
    [self initializeRows];
    [self.tableView reloadData];
}

- (void)viewDidAppear: (BOOL) animated
{
    [super viewDidAppear:animated];
    
    DriverData *driver = [del.surveyDB getDriverData];
    [del.surveyDB updateDriverData:driver];
    if(driver.driverType == PVO_DRIVER_TYPE_NONE)
    {
        
        
        if (![AppFunctionality disablePackersInventory])
        {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Driver Type"
                                                         message:@"Please select your driver type.  This setting can be adjusted from the Driver screen in the future."
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Driver",@"Packer", nil];
            av.tag = PVO_SYNC_ALERT_DRIVER_PACKER;
            [av show];
        }
        else
        {
            driver.driverType = PVO_DRIVER_TYPE_DRIVER;
            [del.surveyDB updateDriverData:driver];
            [self.tableView reloadData];
        }
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Memory management


@end
