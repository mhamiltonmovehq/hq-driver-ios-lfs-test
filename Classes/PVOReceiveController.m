//
//  PVODeliveryController.m
//  Survey
//
//  Created by Tony Brame on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOReceiveController.h"
#import "SwitchCell.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "CustomerUtilities.h"
#import "DriverData.h"
#import "PVOSync.h"
#import "CustomerOptionsController.h"

@implementation PVOReceiveController

@synthesize optionsTable, recentTable, tboxCurrent, currentItemNumber, currentLoad;
@synthesize remainingItems, deliveryBatchExceptions, currentLotNumber, loadTheThings;
@synthesize currentUnload;
@synthesize hideAlerts;
@synthesize receiveType;
@synthesize receivingType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        receiverView = [[PVOUploadReportView alloc] init];
        receiverView.delegate = self;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.optionsTable];
    if ([SurveyAppDelegate iOS7OrNewer])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [super viewDidLoad];
    
    recentView = PVO_RECEIVE_VIEW_REMAINING; //default to remaining items per defect 1290
    self.segmentControl.selectedSegmentIndex = PVO_RECEIVE_VIEW_REMAINING;
    optionRows = [[NSMutableArray alloc] init];
    recentlyDelivered = [[NSMutableArray alloc] init];
    self.title = @"Receive";
    
    if ((receivingType & PVO_RECEIVE_ON_DOWNLOAD) || _skipInventoryProcess)
    {
        NSString *bt = _skipInventoryProcess ? @"Complete" : @"Continue";
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:bt
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(complete_Click:)];
    }
}

-(IBAction)complete_Click:(id)sender
{
    //get on to the rooms screen!
    if(_skipInventoryProcess){
        //jump back to nav list
        CustomerOptionsController *c = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[CustomerOptionsController class]])
                c = view;
        }
        
        if(c != nil){
            [self.navigationController popToViewController:c animated:YES];
        } else {
            [self.navigationController pushViewController:c animated:YES];
        }
        
    } else {
        if(roomController == nil)
            roomController = [[PVORoomSummaryController alloc] initWithNibName:@"PVORoomSummaryView" bundle:nil];
        
        roomController.inventory = self.inventory;
        roomController.currentLoad = self.currentLoad;
        
        [self.navigationController pushViewController:roomController animated:YES];
    }
}

-(IBAction)continue_Click:(id)sender
{
    //deliver the current item...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
    {
        [self updateValueWithField:tboxCurrent];
        [tboxCurrent resignFirstResponder];
        self.tboxCurrent = nil;
    }
    
    NSString *resetItemNumber = @"";
    
    PVOItemDetailExtended *remainingitem = nil, *recentItem = nil;
    
    for (PVOItemDetailExtended *i in remainingItems) {
        if([i.itemNumber isEqualToString:currentItemNumber])
        {
            // Restructured this if/else statement to fix OT 21183
            if(currentLotNumber != nil && [i.lotNumber isEqualToString:currentLotNumber]) {
                remainingitem = i;
                break;
            } else if(currentLotNumber == nil) {
                remainingitem = i;
                break;
            }
        }
    }
    
    if(remainingitem == nil)
    {
        for (PVOItemDetailExtended *i in recentlyDelivered) {
            if([i.itemNumber isEqualToString:currentItemNumber])
            {
                if(currentLotNumber != nil && [i.lotNumber isEqualToString:currentLotNumber])
                    recentItem = i;
                else if(currentLotNumber == nil)
                    recentItem = i;
                
                break;
            }
        }
    }
    
    self.currentLotNumber = nil;
    
    if(currentItemNumber == nil || [currentItemNumber length] == 0)
    {
        [self addSyncMessage:@"You must enter an item number to continue."];
    }
    else if(remainingitem == nil && recentItem == nil)
    {
        [self addSyncMessage:[NSString stringWithFormat:@"Item %@ not found on receive order!", currentItemNumber]];
    }
    else if(recentItem != nil)
    {
        //item already received...
        //ask to Cancel & Rescan, or Add Exceptions
        
//        if(del.kscan.IsSynchronizeOn)
//        {
//            NSString *tagToAdd = [NSString stringWithFormat:@"%@%@", recentItem.lotNumber, currentItemNumber];
//            if(![duplicatedBatchTags containsObject:tagToAdd])
//                [duplicatedBatchTags addObject:tagToAdd];
//        }
//        else
        {//ask to add exceptions
            UIAlertView *alert = nil;
            
            alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Tag" 
                                               message:[NSString stringWithFormat:@"Item %@ has already been received. Would you like to cancel entry or enter exceptions for this item?", [recentItem displayInventoryNumber]] 
                                              delegate:self
                                     cancelButtonTitle:@"Cancel" 
                                     otherButtonTitles:@"Exceptions", nil];
            alert.tag = PVO_RECEIVE_ALERT_DUPE_EXCEPTIONS;
            [alert show];
            
            tempItem = recentItem;
            
            //not sure what this is
            resetItemNumber = [NSString stringWithString:currentItemNumber];
        }
    }
    else
    {
        BOOL isStoredInDB = (self.receivingType & PVO_RECEIVE_ON_DOWNLOAD);
        
        if (isStoredInDB)
            [del.surveyDB removePVOReceivableItem:remainingitem.pvoItemID];
        
        if(!hideAlerts && !remainingitem.itemIsDeleted && remainingitem.highValueCost > 0) {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Item %@ is a %@ item.",
                                          [remainingitem displayInventoryNumber], [[AppFunctionality getHighValueDescription] lowercaseString]]
                               withTitle:[AppFunctionality getHighValueDescription]];
        }
        
        //receive the item. save remaining item as a new inventory item...
        remainingitem.pvoLoadID = self.currentLoad.pvoLoadID;
        remainingitem.pvoItemID = 0;
        if (remainingitem.itemIsDelivered && (self.currentUnload == nil || self.currentUnload.pvoLocationID <= 0))
            remainingitem.itemIsDelivered = false; //remove delivered flag, no unload available
        
        if (remainingitem.itemIsDelivered && self.currentUnload != nil && self.currentUnload.pvoLocationID > 0 && self.currentUnload.pvoLoadID <= 0)
        {
            //save unload, found delviered item
            self.currentUnload.loadIDs = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:currentLoad.pvoLoadID], nil];
            self.currentUnload.pvoLoadID = [del.surveyDB savePVOUnload:self.currentUnload];
        }
        if ([AppFunctionality disableRiderExceptions])
            remainingitem.lockedItem = (receiveType == WAREHOUSE && self.currentLoad.pvoLocationID != WAREHOUSE); //not grabbing rider exceptions, so lock the item down
        
        //save receive type on load (feature 367)
        if (self.currentLoad.receivedFromPVOLocationID != receiveType)
        {
            self.currentLoad.receivedFromPVOLocationID = receiveType;
            self.currentLoad.pvoLoadID = [del.surveyDB updatePVOLoad:currentLoad];
            remainingitem.pvoLoadID = self.currentLoad.pvoLoadID;
        }
        
        //save item
        remainingitem.pvoItemID = [self saveReceivableItem:remainingitem];
        
        [recentlyDelivered insertObject:remainingitem atIndex:0];
        
        PVOItemDetailExtended *toremove = nil;
        for (PVOItemDetailExtended *itemDetail in remainingItems) {
            if([itemDetail.itemNumber isEqualToString:remainingitem.itemNumber] && [itemDetail.lotNumber isEqualToString:remainingitem.lotNumber])
                toremove = itemDetail;
        }
        if(toremove != nil)
            [remainingItems removeObject:toremove];
        
        [recentTable reloadData];
        
    }
    
    self.currentItemNumber = resetItemNumber;
    
    [optionsTable reloadData];
}

-(int)saveReceivableItem:(PVOItemDetailExtended*)item
{
    item.doneWorking = YES; //always flag as done
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    item.pvoItemID = [del.surveyDB updatePVOItem:item];
    
    //save damages
    for (PVOConditionEntry *condy in item.damageDetails) {
        condy.pvoItemID = item.pvoItemID;
        condy.pvoLoadID = 0;
        condy.pvoUnloadID = 0;
        if (item.cartonContentID <= 0)
        {
            if (condy.damageType == DAMAGE_LOADING || condy.damageType == DAMAGE_RIDER)
            {
                condy.pvoLoadID = item.pvoLoadID;
                condy.pvoUnloadID = 0;
            }
            else if (condy.damageType == DAMAGE_UNLOADING)
            {
                condy.pvoLoadID = 0;
                condy.pvoUnloadID = currentUnload.pvoLoadID;
            }
        }
        [del.surveyDB savePVODamage:condy];
        
    }
    item.damage = item.damageDetails;
    
    //save comments
    for (PVOItemComment *comment in item.itemCommentDetails) {
        [del.surveyDB savePVOItemComment:comment.comment withPVOItemID:item.pvoItemID withCommentType:comment.commentType];
    }
    
    [del.surveyDB savePVODescriptions:item.descriptiveSymbols
                              forItem:item.pvoItemID];
    
    if (item.cartonContentID <= 0 && item.cartonContentsDetail != nil)
    {
        //[del.surveyDB updatePVOCartonContents:item.pvoItemID withContents:item.cartonContentsDetail]; //old logic
        for (PVOItemDetailExtended *ccItem in item.cartonContentsDetail) { //new detailed logic
            ccItem.cartonContentID = [del.surveyDB addPVOCartonContent:ccItem.cartonContentID forPVOItem:item.pvoItemID];
            ccItem.itemNumber = [NSString stringWithFormat:@"%@", item.itemNumber];
            ccItem.lotNumber = [NSString stringWithFormat:@"%@", item.lotNumber];
            ccItem.tagColor = item.tagColor;
            ccItem.pvoItemID = 0;
            ccItem.pvoItemID = [self saveReceivableItem:ccItem];
        }
    }
    
    return item.pvoItemID;
}


-(void)addSyncMessage:(NSString*)message
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    if(del.kscan.IsSynchronizeOn)
//    {
//        if(syncMessages == nil)
//            syncMessages = [[NSMutableString alloc] initWithString:message];
//        else
//            [syncMessages appendFormat:@"\r\n%@", message];
//    }
//    else
    {
        [SurveyAppDelegate showAlert:message withTitle:@"Error"];
        [SurveyAppDelegate soundAlert];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    
    [del setCurrentSocketListener:self];
    [del.linea addDelegate:self];
    
    //get the entries from the server...
    usingScanner = del.socketConnected || [del.linea connstate] == CONN_CONNECTED;
    
    if ([AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
        usingScanner = NO;
    
    
    if(usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
        self.navigationItem.prompt = @"Scanner is not connected";
    else
        self.navigationItem.prompt = nil;
    
    if (self.receivingType & PVO_RECEIVE_ON_DOWNLOAD)
        self.receiveType = [del.surveyDB getPVOReceivedItemsType:del.customerID];
    
    if(!loadTheThings)
    {
        self.currentItemNumber = @"";
        
        [self initializeRowsIncluded];
        
        [recentlyDelivered removeAllObjects];
        
        [self.recentTable reloadData];
        [self.optionsTable reloadData];
        
        [self setupTableHeight];
    }
    
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    if(loadTheThings)
        [receiverView receiveLoad];
    
    loadTheThings = FALSE;
    [super viewDidAppear:animated];
}


-(void)setupTableHeight
{
    //the big size is
    //156 options, 216 recent...
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:1.];
    
    CGRect optionsFrame = optionsTable.frame;
    CGRect recentFrame = recentTable.frame;
    
    CGSize optionsFrameSizeThatFits = [optionsTable sizeThatFits:CGSizeMake(optionsFrame.size.width, FLT_MAX)];
    
    CGFloat rootOptionsFrameHeight = optionsFrame.size.height;
    CGFloat rootRecentFrameHeight = recentFrame.size.height;
    
    CGFloat sizeToMove = optionsFrameSizeThatFits.height - rootOptionsFrameHeight;
    
    optionsFrame.size.height = rootOptionsFrameHeight + sizeToMove;
    recentFrame.origin.y = rootOptionsFrameHeight + sizeToMove;
    recentFrame.size.height = rootRecentFrameHeight - sizeToMove;
    
    optionsTable.frame = optionsFrame;
    recentTable.frame = recentFrame;
    
    [UIView commitAnimations];
}

-(void)initializeRowsIncluded
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    
    [optionRows removeAllObjects];
    
    if (![AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
        [optionRows addObject:[NSNumber numberWithInt:PVO_RECEIVE_USING_SCANNER]];
    
    
    /*if(usingScanner && [del.kscan IsKDCConnected])
        [optionRows addObject:[NSNumber numberWithInt:PVO_RECEIVE_DOWNLOAD_ALL]];
    else*/ if(!usingScanner)
        [optionRows addObject:[NSNumber numberWithInt:PVO_RECEIVE_ITEM_NUMBER]];

    [optionRows addObject:[NSNumber numberWithInt:PVO_RECEIVE_DELIVER_ALL]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:nil];
    [del.linea removeDelegate:self];
    
    hideAlerts = NO;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setSegmentControl:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)updateValueWithField:(UITextField*)fld
{
    self.currentItemNumber = fld.text;
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    usingScanner = sw.on;
    
    [self initializeRowsIncluded];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
        self.navigationItem.prompt = @"Scanner is not connected";
    else
        self.navigationItem.prompt = nil;
    
    [self.recentTable reloadData];
    [self.optionsTable reloadData];
    [self setupTableHeight];
}

-(IBAction)segmentRecentView_Changed:(id)sender
{
    UISegmentedControl *segment = sender;
    recentView = segment.selectedSegmentIndex;
    
    [recentTable reloadData];
}

-(BOOL)receivableItemHasDamages:(PVOItemDetailExtended*)pvoItem
{
    for (PVOConditionEntry *entry in pvoItem.damageDetails)
    {
        if (entry.damageType != DAMAGE_UNLOADING)
            return true;
    }
    return false;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == optionsTable)
        return [optionRows count];
    else if(recentView == PVO_RECEIVE_VIEW_RECENT)
        return [recentlyDelivered count];
    else if(recentView == PVO_RECEIVE_VIEW_REMAINING)
        return [remainingItems count];
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if(tableView == optionsTable && usingScanner && [del.kscan IsKDCConnected])
//        return @"Scan to receive item, or tap 'Download Batch' to retrieve stored codes from scanner.";
//    else
        return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView == optionsTable)
        return nil;
    else if(recentView == PVO_RECEIVE_VIEW_RECENT)
        return @"Recently Received";
    else if(recentView == PVO_RECEIVE_VIEW_REMAINING)
        return [NSString stringWithFormat:@"Remaining Items (%lu)", (unsigned long)[remainingItems count]];
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *TextCellIdentifier = @"LabelTextCell";
    
    UITableViewCell *cell = nil;
    SwitchCell *swCell = nil;
    LabelTextCell *ltCell = nil;
    
    if(tableView == optionsTable)
    {
        int row = [[optionRows objectAtIndex:indexPath.row] intValue];
        
        
        if(row == PVO_RECEIVE_USING_SCANNER)
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
            
            swCell.labelHeader.text = @"Using Scanner";
            swCell.switchOption.on = usingScanner;
        }
        else if(row == PVO_RECEIVE_ITEM_NUMBER)
        {
            ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
            if (ltCell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
                ltCell = [nib objectAtIndex:0];
                [ltCell.tboxValue addTarget:self 
                                     action:@selector(textFieldDoneEditing:) 
                           forControlEvents:UIControlEventEditingDidEndOnExit];
                ltCell.tboxValue.delegate = self;
                ltCell.tboxValue.returnKeyType = UIReturnKeyDone;
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                ltCell.tboxValue.font = [UIFont systemFontOfSize:17.];
            }
            
            ltCell.tboxValue.tag = row;
            
            ltCell.labelHeader.text = @"Item Number";
            ltCell.tboxValue.text = currentItemNumber == nil ? @"" : currentItemNumber;
        }
        else
        {
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor blackColor];
            
            if(row == PVO_RECEIVE_DOWNLOAD_ALL)
                cell.textLabel.text = @"Download Batch";
            else if(row == PVO_RECEIVE_DELIVER_ALL)
                cell.textLabel.text = @"Receive All Remaining";
            
        }
    }
    else
    {//recently delivered...
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSMutableArray *touse = recentView == PVO_RECEIVE_VIEW_RECENT ? recentlyDelivered : remainingItems;
        
        PVOItemDetailExtended *pvoitem = [touse objectAtIndex:indexPath.row];
//        PVOItemDetail *pvoitem = [touse objectAtIndex:indexPath.row];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
        cell.textLabel.text = [NSString stringWithFormat:@"%@-%@%@", [pvoitem displayInventoryNumber], item.name, [self receivableItemHasDamages:pvoitem] ? @"*" : @""];
    }
    
    return cell != nil ? cell : swCell != nil ? (UITableViewCell*)swCell : (UITableViewCell*)ltCell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

#pragma mark - Table view delegate

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([AppFunctionality canDeleteInventoryItems])
        return @"Details";
}

-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return true;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
//        deletingIndex = [indexPath retain];
//        workingItem = [[pvoItems objectAtIndex:deletingIndex.row] retain];
        
        NSMutableArray *touse = recentView == PVO_RECEIVE_VIEW_RECENT ? recentlyDelivered : remainingItems;
        
        PVOItemDetailExtended *pvoitem = [touse objectAtIndex:indexPath.row];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
        
        [tv reloadData];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:item.name
                                                        message:pvoitem.quickSummaryText
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tboxCurrent != nil)
    {
        [self updateValueWithField:tboxCurrent];
        [tboxCurrent resignFirstResponder];
        self.tboxCurrent = nil;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(tableView == optionsTable)
    {
        //SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        int row = [[optionRows objectAtIndex:indexPath.row] intValue];
        
        if (row == PVO_RECEIVE_DOWNLOAD_ALL)
        {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Batch" 
                                                                message:@"This option will receive all items stored in your scanner.  Would you like to continue?" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"No" 
                                                      otherButtonTitles:@"Yes", nil];
                [alert show];
        }
        else if (row == PVO_RECEIVE_DELIVER_ALL)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Receive All" 
                                                            message:@"This option will receive all remaining items.  Would you like to continue?" 
                                                           delegate:self 
                                                  cancelButtonTitle:@"No" 
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = PVO_RECEIVE_ALERT_DELIVER_ALL;
            [alert show];
        }
    }
    else if(recentView == PVO_RECEIVE_VIEW_REMAINING)
    {   
        PVOItemDetail *pvoitem = [remainingItems objectAtIndex:indexPath.row];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        
        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
        
        self.currentItemNumber = pvoitem.itemNumber;
        self.currentLotNumber = pvoitem.lotNumber;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Receive Item" 
                                                        message:[NSString stringWithFormat:@"Would you like to continue to receive item %@?", 
                                                                 [NSString stringWithFormat:@"%@-%@", [pvoitem displayInventoryNumber], item.name]] 
                                                       delegate:self 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = PVO_RECEIVE_ALERT_DELIVER_ONE;
        [alert show];
    }
    else if(recentView == PVO_RECEIVE_VIEW_RECENT)
    {   
        PVOItemDetail *pvoitem = [recentlyDelivered objectAtIndex:indexPath.row];
        
        self.currentItemNumber = pvoitem.itemNumber;
        self.currentLotNumber = pvoitem.lotNumber;
        
        //no alert needed, user will be alerted from duplicate tag.
        [self continue_Click:nil];
    }
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.text.length == 2 && 
       range.location == 2 && range.length == 0)
    {
        textField.text = [textField.text stringByAppendingString:string];
        [self continue_Click:textField];
        return NO;
    }
    else
        return YES;
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == PVO_RECEIVE_ALERT_BATCH_ERRORS)
    {//show exceptions alert if needed
        
        if([duplicatedBatchTags count] > 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Messages" 
                                               message:@"All Barcodes synchronized successfully. Duplicate scans were detected. Tap Continue to enter exceptions for these items." 
                                              delegate:self 
                                     cancelButtonTitle:nil 
                                     otherButtonTitles:@"Continue", nil];
            alert.tag = PVO_RECEIVE_ALERT_BATCH_EXCEPTIONS;
            [alert show];
        }
        else
            duplicatedBatchTags;
    }
    else if(alertView.tag == PVO_RECEIVE_ALERT_BATCH_EXCEPTIONS)
    {
        //load exceptions view if necessary
        if([duplicatedBatchTags count] > 0)
        {
            if(deliveryBatchExceptions == nil)
                deliveryBatchExceptions = [[PVODelBatchExcController alloc] initWithStyle:UITableViewStyleGrouped];
            deliveryBatchExceptions.excType = EXC_CONTROLLER_RECEIVE;
            deliveryBatchExceptions.duplicatedTags = duplicatedBatchTags;
            deliveryBatchExceptions.title = @"Add Info";
            deliveryBatchExceptions.currentLoad = currentLoad;
            [self.navigationController pushViewController:deliveryBatchExceptions animated:YES];
        }
    }
    else if(alertView.tag == PVO_RECEIVE_ALERT_DELIVER_ALL)
    {   
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableArray *hvItems = [NSMutableArray array];
            NSString *descrip;
            hideAlerts = YES;
            while([remainingItems count] > 0)
            {
                PVOItemDetail *pvoitem = [remainingItems objectAtIndex:0];
                self.currentItemNumber = pvoitem.itemNumber;
                self.currentLotNumber = pvoitem.lotNumber;
                [self continue_Click:nil];
                if(!pvoitem.itemIsDeleted && pvoitem.highValueCost > 0)
                {
                    descrip = [NSString stringWithFormat:@"%@", [pvoitem displayInventoryNumber]];
                    if (pvoitem.itemID > 0)
                    {
                        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
                        if (item != nil && item.name != nil && ![item.name isEqualToString:@""])
                            descrip = [descrip stringByAppendingFormat:@" - %@", item.name];
                    }
                    if (descrip != nil && ![descrip isEqualToString:@""])
                        [hvItems addObject:descrip];
                }
            }
            hideAlerts = NO;
            if (hvItems != nil && [hvItems count] > 0)
            {
                descrip = @"";
                [hvItems sortUsingSelector:@selector(compare:)];
                for (NSString *hvi in hvItems)
                    descrip = [descrip stringByAppendingFormat:@"%@%@", descrip.length > 0 ? @"\r\n" : @"", hvi];
                
                [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"The following items are %@:\r\n%@", [[AppFunctionality getHighValueDescription] lowercaseString], descrip]
                                   withTitle:[AppFunctionality getHighValueDescription]];
            }
            //[hvItems release];
        }
    }
    else if(alertView.tag == PVO_RECEIVE_ALERT_DELIVER_ONE)
    {   
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            hideAlerts = NO;
            //currents set when row was selected.
            [self continue_Click:nil];
        }
    }
    else if (alertView.tag == PVO_RECEIVE_ALERT_DUPE_EXCEPTIONS)
    {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            if(buttonIndex == 1)
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                
                [del showPVODamageController:self.navigationController 
                                     forItem:tempItem
                          showNextItemButton:NO 
                                   pvoLoadID:currentLoad.pvoLoadID];
            }
        }
    }
//    else
//    {
//        if(buttonIndex != alertView.cancelButtonIndex)
//        {
//            //start the batch download
//            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//            [del StartSynchronize];
//        }
//    }
}


#pragma mark - Socket Scanner delegate methods

-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = TRUE;
    self.navigationItem.prompt = nil;
}

-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = FALSE;
    self.navigationItem.prompt = @"Scanner is not connected";
}

-(void) onError:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"ScanAPI is reporting an error: %ld",result] withTitle:@"Scanner Error"];
}

-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(id<ISktScanDecodedData>) decodedData{
    
    NSString *data = [[NSString stringWithUTF8String:(const char *)[decodedData getData]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([data length] >= 6)
    {
        self.currentLotNumber = [data substringToIndex:[data length]-3];
        self.currentItemNumber = [data substringFromIndex:[data length]-3];
        [self continue_Click:nil];
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
    
}

-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(!SKTSUCCESS(result))
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error initializing ScanAPI: %ld",result] withTitle:@"Scanner Error"];
    } else {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving ScanObject:%ld",result] withTitle:@"Scanner Error"];
}


#pragma mark - LineaDelegate methods

-(void)connectionState:(int)state {
    
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
            self.navigationItem.prompt = @"Scanner is not connected";
			break;
		case CONN_CONNECTED:
            self.navigationItem.prompt = nil;
			break;
	}
}

-(void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
    [self barcodeData:barcode type:-1];//dont care about type...
}

-(void)barcodeData:(NSString *)barcode type:(int)type
{
    
    NSString *data = barcode;
    
    if([data length] >= 6)
    {
        self.currentLotNumber = [data substringToIndex:[data length]-3];
        self.currentItemNumber = [data substringFromIndex:[data length]-3];
        [self continue_Click:nil];
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
    
}


#pragma mark - PVOUploadReportViewDelegate methods

-(void)receiveCompleted:(PVOUploadReportView *)uploadReportView withItems:(NSArray *)pvoItems
{
    //i have all of my items, load up the views...
    
    //not asking to import all as is or deliver individually as those options will be in the form.
    
    //recentView = PVO_RECEIVE_VIEW_REMAINING;
    
    //remove any existing items, don't need to receive it multiple times
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (pvoItems != nil && [pvoItems count] > 0)
    {
        NSMutableArray *newList = [[NSMutableArray alloc] init];
        for (PVOItemDetailExtended *item in pvoItems)
        {
            if (item == nil || [del.surveyDB pvoInventoryItemExists:del.customerID
                                                     withItemNumber:item.itemNumber
                                                       andLotNumber:item.lotNumber
                                                        andTagColor:item.tagColor])
                continue;
            [newList addObject:item];
        }
        pvoItems = [NSArray arrayWithArray:newList];
    }
    
    if([pvoItems count] > 0)
    {
        //save load type
        PVOInventory *invData = [del.surveyDB getPVOData:del.customerID];
        self.receiveType = uploadReportView.sync.loadType;
        invData.loadType = self.receiveType;
        [del.surveyDB updatePVOData:invData];
        //[invData release];
        
        //create Load
        self.currentLoad = [[PVOInventoryLoad alloc] init];
        self.currentLoad.pvoLocationID = uploadReportView.sync.receivedType;
        self.currentLoad.custID = del.customerID;
        BOOL requiresLocationSelection = [del.surveyDB pvoLocationRequiresLocationSelection:currentLoad.pvoLocationID];
        if (requiresLocationSelection)
        {
            //grab origin location
            SurveyLocation *orig = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
            self.currentLoad.locationID = orig.locationID;
        }
        PVOInventoryLoad *existing = [del.surveyDB getFirstPVOLoad:del.customerID forPVOLocationID:self.currentLoad.pvoLocationID];
        if (existing != nil)
        {
            if (existing.pvoLoadID > 0 && (!requiresLocationSelection || existing.locationID == self.currentLoad.locationID))
                self.currentLoad.pvoLoadID = existing.pvoLoadID;
        }
        self.currentLoad.pvoLoadID = [del.surveyDB updatePVOLoad:self.currentLoad];
        
        if (uploadReportView.sync.receivedUnloadType > 0)
        {
            //create unload
            self.currentUnload = [[PVOInventoryUnload alloc] init];
            self.currentUnload.pvoLocationID = uploadReportView.sync.receivedUnloadType;
            self.currentUnload.loadIDs = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:self.currentLoad.pvoLoadID], nil];
            requiresLocationSelection = [del.surveyDB pvoLocationRequiresLocationSelection:currentUnload.pvoLocationID];
            if (requiresLocationSelection)
            {
                //grab dest location
                SurveyLocation *dest = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
                currentUnload.locationID = dest.locationID;
            }
            PVOInventoryUnload *existingUnload = [del.surveyDB getFirstPVOUnload:del.customerID forPVOLocationID:self.currentUnload.pvoLocationID];
            if (existingUnload != nil)
            {
                if (existingUnload.pvoLoadID > 0 && (!requiresLocationSelection || existingUnload.locationID == self.currentUnload.pvoLocationID))
                    self.currentUnload.pvoLoadID = existingUnload.pvoLoadID;
            }
            self.currentUnload.pvoLoadID = [del.surveyDB savePVOUnload:self.currentUnload];
        }
    }
    
    self.currentItemNumber = @"";
    
    [self initializeRowsIncluded];
    
    [recentlyDelivered removeAllObjects];
    
    //get remaining items for lot if not using scanner, otherwise get all remaining items
    
    //only show those items that haven't been imported... do this later
    
    self.remainingItems = [NSMutableArray arrayWithArray:pvoItems];
    
    [self.recentTable reloadData];
    [self.optionsTable reloadData];
    
    [self setupTableHeight];
}

@end
