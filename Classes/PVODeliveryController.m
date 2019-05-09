//
//  PVODeliveryController.m
//  Survey
//
//  Created by Tony Brame on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODeliveryController.h"
#import "SwitchCell.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "CustomerUtilities.h"
#import "PVODelBatchExcController.h"
#import "PVONavigationController.h"
#import "PVOItemComment.h"

@implementation PVODeliveryController

@synthesize optionsTable, recentTable, tboxCurrent, currentLotNumber, currentItemNumber;
@synthesize lots, remainingItems, deliveryBatchExceptions, currentUnload, signatureController;
@synthesize deliverAllHighValueItems;
@synthesize deliveringAll;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)])
        self.extendedLayoutIncludesOpaqueBars = NO;
    
    optionRows = [[NSMutableArray alloc] init];
    //per defect 308, always pull delivered items.  pulled in viewWillAppear
    //recentlyDelivered = [[NSMutableArray alloc] init];
    
    if ([AppFunctionality enableDestinationRoomConditions])
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self 
                                                                              action:@selector(options_Click:)];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Deliveries" style:UIBarButtonItemStylePlain target:self action:@selector(handleBackPressed)];
        self.navigationItem.hidesBackButton = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Complete"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(complete_Click:)];
    }
    
    
    reloadOnAppear = TRUE;
    
    self.deliveringAll = FALSE;
    
}
-(void)handleBackPressed
{
    roomConditionsDidShow = false;
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)options_Click:(id)sender
{
    UIActionSheet *sheet;
    sheet = [[UIActionSheet alloc] initWithTitle:@"Additional Options"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"Complete", @"Manage Rooms", nil];
    
    [sheet showInView:self.view];
    
}


-(IBAction)complete_Click:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    inventory.deliveryCompleted = YES;
    [del.surveyDB updatePVOData:inventory];
    //[inventory release];
    
    [del.surveyDB setCompletionDate:del.customerID isOrigin:NO];
    
    //jump back to nav list
    PVONavigationController *navController = nil;
    for (id view in [self.navigationController viewControllers]) {
        if([view isKindOfClass:[PVONavigationController class]])
            navController = view;
    }
    
    [self.navigationController popToViewController:navController animated:YES];
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
    
    PVOItemDetail *item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID
                                               forLotNumber:currentLotNumber
                                             withItemNumber:currentItemNumber];
    
    NSString *resetItemNumber = @"";
    
    if(currentLotNumber == nil || [currentLotNumber length] == 0)
    {
        [self addSyncMessage:@"You must select a lot number to continue."];
    }
    else if(currentLotNumber == nil || [currentLotNumber length] == 0)
    {
        [self addSyncMessage:@"You must enter an item number to continue."];
    }
    else if(item == nil)
    {
        [self addSyncMessage:[NSString stringWithFormat:@"Item %@ not in shipment, please return to truck!", currentItemNumber]];
    }
    else if(item.itemIsDelivered)
    {
        //item already delivered...
        //ask to Cancel & Rescan, or Add Exceptions
        
        //        if(del.kscan.IsSynchronizeOn || deliverAllNoScanner)
        //        {
        //            NSString *tagToAdd = [NSString stringWithFormat:@"%@%@", currentLotNumber, currentItemNumber];
        //            if(![duplicatedBatchTags containsObject:tagToAdd])
        //                [duplicatedBatchTags addObject:tagToAdd];
        //        }
        //        else
        {//ask to add exceptions
            UIAlertView *alert = nil;
            
            if([AppFunctionality grabHighValueInitials] && item.highValueCost > 0)
                alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Tag"
                                                   message:[NSString stringWithFormat:@"Item %@ has already been delivered. Would you like to cancel entry, enter exceptions, or enter %@ initials for this item?", [item displayInventoryNumber], [AppFunctionality getHighValueInitialsDescriptions]]
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Exceptions", @"Undeliver", [NSString stringWithFormat:@"%@ Initials", [AppFunctionality getHighValueInitialsDescriptions]], nil];
            else
                alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Tag"
                                                   message:[NSString stringWithFormat:@"Item %@ has already been delivered. Would you like to cancel entry or enter exceptions for this item?", [item displayInventoryNumber]]
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Exceptions", @"Undeliver", @"Comment", @"Manage Photos", nil];
            alert.tag = PVO_DELIVERY_ALERT_DUPE_EXCEPTIONS;
            [alert show];
            
            resetItemNumber = [NSString stringWithString:currentItemNumber];
        }
    }
    else
    {
        item.itemIsDelivered = YES;
        [del.surveyDB updatePVOItem:item withDataUpdateType:PVO_DATA_DELIVER_ITEMS];
        
        [recentlyDelivered insertObject:item atIndex:0];
        
        PVOItemDetail *toremove = nil;
        for (PVOItemDetail *itemDetail in remainingItems) {
            if([itemDetail.itemNumber isEqualToString:item.itemNumber] &&
               [itemDetail.lotNumber isEqualToString:currentLotNumber])
                toremove = itemDetail;
        }
        if(toremove != nil)
            [remainingItems removeObject:toremove];
        
        if([AppFunctionality grabHighValueInitials] && item.highValueCost > 0)
        {
            if (deliverAllNoScanner && deliverAllHighValueItems != nil)
            {
                [deliverAllHighValueItems addObject:item];
            }
            else
            {
                [self promptForHighValueInitials:item];
                resetItemNumber = [NSString stringWithString:currentItemNumber];
            }
        }
        
        
        
        if (!deliverAllNoScanner && !self.deliveringAll)
            [recentTable reloadData];
    }
    
    self.currentItemNumber = resetItemNumber;
    
    if (!deliverAllNoScanner && !self.deliveringAll)
        [optionsTable reloadData];
}


-(void)continueToNextScreen
{
    //deliver the current item...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
    {
        [self updateValueWithField:tboxCurrent];
        [tboxCurrent resignFirstResponder];
        self.tboxCurrent = nil;
    }
    
    PVOItemDetail *item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                               forLotNumber:currentLotNumber 
                                             withItemNumber:currentItemNumber];
    
    NSString *resetItemNumber = @"";
    
    if(currentLotNumber == nil || [currentLotNumber length] == 0)
    {
        [self addSyncMessage:@"You must select a lot number to continue."];
    }
    else if(currentLotNumber == nil || [currentLotNumber length] == 0)
    {
        [self addSyncMessage:@"You must enter an item number to continue."];
    }
    else if(item == nil)
    {
        [self addSyncMessage:[NSString stringWithFormat:@"Item %@ not in shipment, please return to truck!", currentItemNumber]];
    }
    else if(item.itemIsDelivered)
    {
        //item already delivered...
        //ask to Cancel & Rescan, or Add Exceptions
        
//        if(del.kscan.IsSynchronizeOn || deliverAllNoScanner)
//        {
//            NSString *tagToAdd = [NSString stringWithFormat:@"%@%@", currentLotNumber, currentItemNumber];
//            if(![duplicatedBatchTags containsObject:tagToAdd])
//                [duplicatedBatchTags addObject:tagToAdd];
//        }
//        else
        {//ask to add exceptions
            UIAlertView *alert = nil;
            
            if([AppFunctionality grabHighValueInitials] && item.highValueCost > 0)
                alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Tag" 
                                                   message:[NSString stringWithFormat:@"Item %@ has already been delivered. Would you like to cancel entry, enter exceptions, or enter %@ initials for this item?", [item displayInventoryNumber], [AppFunctionality getHighValueInitialsDescriptions]]
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel" 
                                         otherButtonTitles:@"Exceptions", @"Undeliver", [NSString stringWithFormat:@"%@ Initials", [AppFunctionality getHighValueInitialsDescriptions]], nil];
            else
                alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Tag" 
                                                   message:[NSString stringWithFormat:@"Item %@ has already been delivered. Would you like to cancel entry or enter exceptions for this item?", [item displayInventoryNumber]] 
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Exceptions", @"Undeliver", nil];
            alert.tag = PVO_DELIVERY_ALERT_DUPE_EXCEPTIONS;
            [alert show];
            
            resetItemNumber = [NSString stringWithString:currentItemNumber];
        }
    }
    else
    {
        item.itemIsDelivered = YES;
        [del.surveyDB updatePVOItem:item withDataUpdateType:PVO_DATA_DELIVER_ITEMS];
        
        [recentlyDelivered insertObject:item atIndex:0];
        
        PVOItemDetail *toremove = nil;
        for (PVOItemDetail *itemDetail in remainingItems) {
            if([itemDetail.itemNumber isEqualToString:item.itemNumber] && 
               [itemDetail.lotNumber isEqualToString:currentLotNumber])
                toremove = itemDetail;
        }
        if(toremove != nil)
            [remainingItems removeObject:toremove];
        
        if([AppFunctionality grabHighValueInitials] && item.highValueCost > 0)
        {
            if (deliverAllNoScanner && deliverAllHighValueItems != nil)
            {
                [deliverAllHighValueItems addObject:item];
            }
            else
            {
                [self promptForHighValueInitials:item];
                resetItemNumber = [NSString stringWithString:currentItemNumber];
            }
        }
        
        
        
        if (!deliverAllNoScanner)
            [recentTable reloadData];
    }
    
    self.currentItemNumber = resetItemNumber;
    
    if (!deliverAllNoScanner)
        [optionsTable reloadData];
}

-(void)promptForHighValueInitials:(PVOItemDetail*)item
{
    [self promptForHighValueInitials:item withDelay:-1];
}

-(void)promptForHighValueInitials:(PVOItemDetail*)item withDelay:(double)seconds
{
    if (seconds > 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self promptForHighValueInitials:item withDelay:-1];
        });
        return;
    }
    
    if ([AppFunctionality grabHighValueInitials])
    {
        self.currentLotNumber = [item lotNumber];
        self.currentItemNumber = [item fullItemNumber];
        
        NSString *highValueDesc = [AppFunctionality getHighValueDescription];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:highValueDesc
                                                        message:[NSString stringWithFormat:@"Item %@ is a %@ item. Would you like to enter Delivery Confirmation initials at this time?",
                                                                 [item displayInventoryNumber], highValueDesc]
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = PVO_DELIVERY_ALERT_HVI_INITIALS;
        [alert show];
        
    }
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
    
    if(reloadOnAppear)
    {
        recentView = PVO_DELIVERY_VIEW_REMAINING;
        self.segmentView.selectedSegmentIndex = PVO_DELIVERY_VIEW_REMAINING;
        
        usingScanner = del.socketConnected || [del.linea connstate] == CONN_CONNECTED;
        
        if ([AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
            usingScanner = NO;
            
        self.currentItemNumber = @"";
        self.lots = [del.surveyDB getPVOLots:currentUnload.pvoLoadID];
        if([lots count] > 0 && (currentLotNumber == nil || [self.currentLotNumber isEqualToString:@""]))
        {
            for (NSString *lotnum in lots) {
                self.currentLotNumber = lotnum;
                self.remainingItems = [NSMutableArray arrayWithArray:
                                       [del.surveyDB getRemainingPVOItems:currentUnload.pvoLoadID forLot:lotnum]
                                        ];
                if([remainingItems count] != 0)
                    break;
            }
        }
        
        [self initializeRowsIncluded];
        
        //[self reloadItems]; // why?
        
        [self.recentTable reloadData];
        [self.optionsTable reloadData];
        
        
        [self setupTableHeight];
    }
    
    if(usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
        self.navigationItem.prompt = @"Scanner is not connected";
    else
        self.navigationItem.prompt = nil;
    
    
    
    reloadOnAppear = TRUE;
    
    [super viewWillAppear:animated];
}

-(void)reloadItems
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    recentlyDelivered = [[del.surveyDB getDeliveredPVOItems:currentUnload.pvoLoadID] mutableCopy];
    
    //get remaining items for lot if not using scanner, otherwise get all remaining items
    self.remainingItems = [NSMutableArray arrayWithArray:
                           [del.surveyDB getRemainingPVOItems:currentUnload.pvoLoadID forLot:currentLotNumber useLotNumber:!usingScanner]];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self showRoomConditionsDialog];
    [super viewDidAppear:animated];
}

-(void)showRoomConditionsDialog
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ARPIN) {
        if (!roomConditionsDidShow) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Manage Rooms"
                                                            message:@"Would you like to enter destination room conditions?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = PVO_DELIVERY_ROOM_CONDITIONS;
            [alert show];
            
        }
    }
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
    PVOInventory *inventory = [del.surveyDB getPVOData:del.customerID];
    
    [optionRows removeAllObjects];
    
    if (![AppFunctionality disableScanner:[CustomerUtilities customerPricingMode] withDriverType:driver.driverType])
        [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_USING_SCANNER]];
    
    
    /*if(usingScanner && [del.kscan IsKDCConnected])
        [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_DOWNLOAD_ALL]];
    else*/ if(!usingScanner)
    {
        if([lots count] > 1)
            [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_LOT_NUMBER]];
        
        [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_ITEM_NUMBER]];
    }
    
    if (inventory.loadType != MILITARY || [del.pricingDB vanline] == ARPIN)
    {
        if ([AppFunctionality allowWaiveRightsOnDelivery])
            [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_WAIVE_RIGHTS]];
        
        [optionRows addObject:[NSNumber numberWithInt:PVO_DELIVERY_DELIVER_ALL]];
    }
    
    //[inventory release];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:nil];
    [del.linea removeDelegate:self];
    
    [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    [UIView setAnimationsEnabled:YES];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setSegmentView:nil];
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
    
    self.remainingItems = [NSMutableArray arrayWithArray:
                           [del.surveyDB getRemainingPVOItems:currentUnload.pvoLoadID forLot:currentLotNumber useLotNumber:!usingScanner]];
    
    [self.recentTable reloadData];
    [self.optionsTable reloadData];
    
    [self setupTableHeight];
        
}

-(void)lotChanged:(NSString*)newLot
{
    self.currentLotNumber = newLot;
    
    reloadOnAppear = TRUE;
}

-(void)showSignatureScreen:(int)tag
{
    if(signatureController == nil)
        signatureController = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
    
    signatureController.tag = tag;
    signatureController.delegate = self;
    signatureController.saveBeforeDismiss = NO;

    if (tag == PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS || tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL];
        signatureController.requireSignatureBeforeSave = YES;
    }
    else
    {
        signatureController.sigType = PVO_HV_INITIAL_TYPE_DEST_CUSTOMER;
        signatureController.requireSignatureBeforeSave = NO;
    }
    
    sigNav = [[LandscapeNavController alloc] initWithRootViewController:signatureController];
    //sigNav.navigationBarHidden = YES;
    
    [self presentViewController:sigNav animated:YES completion:nil];
}

-(UIAlertView*)buildCustomerConfirmAlert
{
    NSString *msg = [AppFunctionality deliverAllPVOItemsAlertConfirm];
    if (msg != nil && [msg length] > 0)
    {
        return [[UIAlertView alloc] initWithTitle:@"Confirm"
                                          message:msg
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Continue", nil];
    }
    return nil;
    
}

-(IBAction)segmentRecentView_Changed:(id)sender
{
    UISegmentedControl *segment = sender;
    recentView = segment.selectedSegmentIndex;
    
    [self reloadItems];
    [recentTable reloadData];
}

-(void)doneEditing:(NSString*)newValue

{    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemDetail *item = nil;
    if (_editingRow >= 0)
    {
        NSMutableArray *touse = recentView == PVO_DELIVERY_VIEW_RECENT ? recentlyDelivered : remainingItems;
        item = [touse objectAtIndex:_editingRow];
    }
    else
        item = [del.surveyDB getPVOItemForUnload:currentUnload.custID forLotNumber:self.currentLotNumber withItemNumber:self.currentItemNumber];
    if (item == nil) return;
    
    [del.surveyDB savePVOItemComment:newValue withPVOItemID:item.pvoItemID withCommentType:COMMENT_TYPE_UNLOADING];
    if (_editingRow < 0)
        
    
    self.currentItemNumber = @"";
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
    else if(recentView == PVO_DELIVERY_VIEW_RECENT)
        return [recentlyDelivered count];
    else if(recentView == PVO_DELIVERY_VIEW_REMAINING)
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
//        return @"Scan to deliver item, or tap 'Download Batch' to retrieve stored codes from scanner.";
//    else
        return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView == optionsTable)
        return nil;
    else if(recentView == PVO_DELIVERY_VIEW_RECENT)
        return @"Delivered";//@"Recently Delivered";
    else if(recentView == PVO_DELIVERY_VIEW_REMAINING)
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
        
        
        if(row == PVO_DELIVERY_USING_SCANNER)
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
        else if(row == PVO_DELIVERY_ITEM_NUMBER)
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
            
            if(row == PVO_DELIVERY_LOT_NUMBER)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                if(currentLotNumber == nil)
                    cell.textLabel.text = @" - Select Current Lot - ";
                else
                    cell.textLabel.text = [NSString stringWithFormat:@"Lot: %@", currentLotNumber];
            }
            else if(row == PVO_DELIVERY_DOWNLOAD_ALL)
                cell.textLabel.text = @"Download Batch";
            else if(row == PVO_DELIVERY_WAIVE_RIGHTS)
                cell.textLabel.text = @"Waive Rights";
            else if(row == PVO_DELIVERY_DELIVER_ALL)
                cell.textLabel.text = @"Deliver All Remaining";
            
        }
    }
    else
    {//recently delivered...
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSMutableArray *touse = recentView == PVO_DELIVERY_VIEW_RECENT ? recentlyDelivered : remainingItems;
        
        PVOItemDetail *pvoitem = [touse objectAtIndex:indexPath.row];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
        cell.textLabel.text = [NSString stringWithFormat:@"%@-%@%@", [pvoitem displayInventoryNumber], item.name, ([[del.surveyDB getPVOItemDamage:pvoitem.pvoItemID] count] > 0 ? @"*" : @"")];
        
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
        
        PVOItemDetail *pvoitem = [touse objectAtIndex:indexPath.row];
        
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
        _editingRow = 0;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        int row = [[optionRows objectAtIndex:indexPath.row] intValue];
        if(row == PVO_DELIVERY_LOT_NUMBER)
        {
            reloadOnAppear = FALSE;
            [del pushTablePickerController:@"Select Current Lot" 
                               withObjects:lots 
                      withCurrentSelection:currentLotNumber 
                                withCaller:self 
                               andCallback:@selector(lotChanged:) 
                           dismissOnSelect:NO 
                          andNavController:self.navigationController];
        }
        else if (row == PVO_DELIVERY_DOWNLOAD_ALL)
        {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Batch" 
                                                                message:@"This option will unload all items stored in your scanner.  Would you like to continue?" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"No" 
                                                      otherButtonTitles:@"Yes", nil];
                [alert show];
                
        }
        else if (row == PVO_DELIVERY_WAIVE_RIGHTS)
        {
            reloadOnAppear = FALSE;
            
            UIAlertView *alert = [self buildCustomerConfirmAlert];
            if (alert != nil)
            {
                alert.tag = PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS;
                [alert show];
                
            }
            else
            {
                [self showSignatureScreen:PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS];
            }
        }
        else if (row == PVO_DELIVERY_DELIVER_ALL)
        {
            UIAlertView *alert = nil;
            if ([AppFunctionality requireSignatureForDeliverAll])
            {
                alert = [[UIAlertView alloc] initWithTitle:@"Deliver All"
                                                   message:@"This option will prompt for customer signature before allowing to proceed with "
                                                            "delivery of all remaining items from your Load(s).  Would you like to continue?"
                                                  delegate:self
                                         cancelButtonTitle:@"No"
                                         otherButtonTitles:@"Yes", nil];
            }
            else
            {
                alert = [[UIAlertView alloc] initWithTitle:@"Deliver All"
                                                   message:@"This option will unload all remaining items from your Load(s).  Would you like to continue?"
                                                  delegate:self
                                         cancelButtonTitle:@"No"
                                         otherButtonTitles:@"Yes", nil];
            }
            alert.tag = PVO_DELIVERY_ALERT_DELIVER_ALL;
            [alert show];
            
        }
    }
    else if(recentView == PVO_DELIVERY_VIEW_REMAINING)
    {
        _editingRow = indexPath.row;
        
        PVOItemDetail *pvoitem = [remainingItems objectAtIndex:indexPath.row];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        Item *item = [del.surveyDB getItem:pvoitem.itemID WithCustomer:del.customerID];
        
        self.currentItemNumber = pvoitem.itemNumber;
        self.currentLotNumber = pvoitem.lotNumber;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deliver Item" 
                                                        message:[NSString stringWithFormat:@"Would you like to continue to deliver item %@?", 
                                                                 [NSString stringWithFormat:@"%@-%@", [pvoitem displayInventoryNumber], item.name]] 
                                                       delegate:self 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = PVO_DELIVERY_ALERT_DELIVER_ONE;
        [alert show];
        
        
    }
    else if(recentView == PVO_DELIVERY_VIEW_RECENT)
    {
        _editingRow = indexPath.row;
        
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
        _editingRow = NSNotFound;
        [self continue_Click:textField];
        return NO;
    }
    else
        return YES;
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == PVO_DELIVERY_ROOM_CONDITIONS) {
        roomConditionsDidShow = true;
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            [self launchRoomSummary];
        }
    }
    if(alertView.tag == PVO_DELIVERY_ALERT_BATCH_ERRORS)
    {//show exceptions alert if needed
        
        if([duplicatedBatchTags count] > 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Messages" 
                                               message:@"All Barcodes synchronized successfully. Duplicate"/* High Value */" scans were detected. Tap Continue to enter exceptions"/*/initials*/" for these items."
                                              delegate:self 
                                     cancelButtonTitle:nil 
                                     otherButtonTitles:@"Continue", nil];
            alert.tag = PVO_DELIVERY_ALERT_BATCH_EXCEPTIONS;
            [alert show];
            
        }
    }
    else if(alertView.tag == PVO_DELIVERY_ALERT_BATCH_EXCEPTIONS)
    {
        //load exceptions view if necessary
        if([duplicatedBatchTags count] > 0)
        {
            reloadOnAppear = FALSE;
            if(deliveryBatchExceptions == nil)
                deliveryBatchExceptions = [[PVODelBatchExcController alloc] initWithStyle:UITableViewStyleGrouped];
            deliveryBatchExceptions.excType = EXC_CONTROLLER_DELIVERY;
            deliveryBatchExceptions.duplicatedTags = duplicatedBatchTags;
            deliveryBatchExceptions.title = @"Add Info";
            deliveryBatchExceptions.currentUnload = currentUnload;
            [self.navigationController pushViewController:deliveryBatchExceptions animated:YES];
        }
    }
    else if(alertView.tag == PVO_DELIVERY_ALERT_DELIVER_ALL)
    {   
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            if ([AppFunctionality requireSignatureForDeliverAll])
            {
                UIAlertView *alert = [self buildCustomerConfirmAlert];
                if (alert != nil)
                {
                    alert.tag = PVO_DELIVERY_SIGVIEW_DELIVER_ALL;
                    [alert show];
                    
                }
                else
                {
                    reloadOnAppear = FALSE;
                    [self showSignatureScreen:PVO_DELIVERY_SIGVIEW_DELIVER_ALL];
                }
            }
            else
                [self continueToDeliverAll];
        }
    }
    else if(alertView.tag == PVO_DELIVERY_ALERT_DELIVER_ONE)
    {   
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            if (_editingRow >=0)
            {
                //currents set when row was selected.
                NSMutableArray *touse = recentView == PVO_DELIVERY_VIEW_RECENT ? recentlyDelivered : remainingItems;
                PVOItemDetail *pvoItem = [touse objectAtIndex:_editingRow];
                self.currentLotNumber = pvoItem.lotNumber;
                self.currentItemNumber = pvoItem.itemNumber;
            }
            
            //currents set when row was selected.
            [self continue_Click:nil];
        }
    }
    else if (alertView.tag == PVO_DELIVERY_ALERT_DUPE_EXCEPTIONS)
    {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOItemDetail *pvoItem = nil;
            if (_editingRow >= 0)
            {
                NSMutableArray *touse = recentView == PVO_DELIVERY_VIEW_RECENT ? recentlyDelivered : remainingItems;
                pvoItem = [touse objectAtIndex:_editingRow];
            }
            else
                pvoItem = [del.surveyDB getPVOItemForUnload:currentUnload.custID forLotNumber:self.currentLotNumber withItemNumber:self.currentItemNumber];
            if (pvoItem == nil) return;
            
            if(buttonIndex == 1)
            {
                //dismissing this manually before we leave because exceptions is two tables and the height is set manually, when the scanner prompt disappears the tables aren't resizing
                if (self.navigationItem.prompt != nil)
                    self.navigationItem.prompt = nil;
                reloadOnAppear = FALSE;
                [del showPVODamageController:self.navigationController 
                                     forItem:pvoItem
                          showNextItemButton:NO 
                                 pvoUnloadID:currentUnload.pvoLoadID];
                
                self.currentItemNumber = @"";
                return;
            }
            else if(buttonIndex == 2)
            {
                //undeliver item...
                pvoItem.itemIsDelivered = NO;
                
                [del.surveyDB updatePVOItem:pvoItem];
                
                //undeliver should remove delivery exceptions, comments, and photos
                [del.surveyDB deletePVODamage:pvoItem.pvoItemID withDamageType:DAMAGE_UNLOADING];
                
                [del.surveyDB deletePVOItemComment:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_UNLOADING];
                
                [del.surveyDB deletePVOItemPhotos:pvoItem.pvoItemID withPhotoType:IMG_PVO_DESTINATION_ITEMS];
                
                self.currentItemNumber = @"";
                
                [self reloadItems];
                
                [recentTable reloadData];
                [optionsTable reloadData];
                
            }
            else if (buttonIndex == 3)
            {
                reloadOnAppear = FALSE;
                
                PVOItemComment *itemComment = [del.surveyDB getPVOItemComment:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_UNLOADING]; // GET DELIVERY NOTE
                
                [del pushNoteViewController:itemComment.comment
                               withKeyboard:UIKeyboardTypeASCIICapable
                               withNavTitle:@"Comment"
                            withDescription:[NSString stringWithFormat:@"Delivery Comment"]
                                 withCaller:self
                                andCallback:@selector(doneEditing:)
                          dismissController:YES
                                   noteType:NOTE_TYPE_NONE
                           andNavController:self.navigationController];
            }
            else if (buttonIndex == 4)
            {
                reloadOnAppear = FALSE;
                
                if(imageViewer == nil)
                    imageViewer = [[SurveyImageViewer alloc] init];
                
                imageViewer.photosType = IMG_PVO_DESTINATION_ITEMS;
                imageViewer.customerID = del.customerID;
                imageViewer.subID = pvoItem.pvoItemID;
                    
                imageViewer.caller = self.view;
                    
                imageViewer.viewController = self;
                    
                [imageViewer loadPhotos];
            }
            else if (buttonIndex == 5)
            {
                reloadOnAppear = FALSE;
                //load up the signature form.
                [self showSignatureScreen:0];
            }
            if (_editingRow < 0) // i really only want to release this if it came from the db not from the *touse array
                pvoItem = nil;
        }
    }
    else if (alertView.tag == PVO_DELIVERY_ALERT_HVI_INITIALS)
    {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            reloadOnAppear = FALSE;
            //load up the signature form.
            [self showSignatureScreen:0];
        }
        else if (deliverAllNoScanner)
        {
            //see if we need to prompt for the next high value item
            if (deliverAllHighValueItems != nil && [deliverAllHighValueItems count] > 0)
            {
                [deliverAllHighValueItems removeObjectAtIndex:0];
                if ([deliverAllHighValueItems count] > 0)
                    [self promptForHighValueInitials:[deliverAllHighValueItems objectAtIndex:0]];
                else
                    deliverAllNoScanner = NO; //found the end, done
            }
            else
                deliverAllNoScanner = NO; //found the end, done
        }
    }
    else if (alertView.tag == PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS || alertView.tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL) //customer sig confirm
    {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            //get signature, show custom sig text...
            reloadOnAppear = FALSE;
            [self showSignatureScreen:alertView.tag];
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
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"ScanAPI is reporting an error: %d", (int)result] withTitle:@"Scanner Error"];
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
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error initializing ScanAPI: %d",(int)result] withTitle:@"Scanner Error"];
    } else {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving ScanObject:%d",(int)result] withTitle:@"Scanner Error"];
}


#pragma mark - SignatureViewControllerDelegate methods


-(UIImage*)signatureViewImage:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIImage *img = nil;
    
    if(sigController.tag == PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS || sigController.tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL)
    {
        PVOSignature *retval = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL];
        return retval == nil ? nil : [retval signatureData];
    }
    
    return img;
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(sigController.tag == PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS || sigController.tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL)
    {
        [del.surveyDB savePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL withImage:signature];
        [del.surveyDB savePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY withImage:signature];
        
        if (sigController.tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL)
        {
            [self continueToDeliverAll];
        }
    }
    else
    {
        PVOItemDetail *item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID
                                                   forLotNumber:currentLotNumber 
                                                 withItemNumber:currentItemNumber];
        [del.surveyDB savePVOHighValueInitial:item.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_DEST_CUSTOMER withImage:signature];
        
        
        if (deliverAllNoScanner)
        {
            //see if we need to prompt for the next high value item
            if (deliverAllHighValueItems != nil && [deliverAllHighValueItems count] > 0)
            {
                [deliverAllHighValueItems removeObjectAtIndex:0];
                if ([deliverAllHighValueItems count] > 0)
                    [self promptForHighValueInitials:[deliverAllHighValueItems objectAtIndex:0] withDelay:0.2];
                else
                    deliverAllNoScanner = NO;//found the end, done
            }
            else
                deliverAllNoScanner = NO;//found the end, done
        }
    }
}

-(void)continueToDeliverAll
{
    self.deliveringAll = TRUE;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //now, deliver all...
    deliverAllNoScanner = YES;
    duplicatedBatchTags = [[NSMutableArray alloc] init];
    deliverAllHighValueItems = [[NSMutableArray alloc] init];
    
    for (NSString *lotNum in lots)
    {
        self.remainingItems = [NSMutableArray arrayWithArray:
                               [del.surveyDB getRemainingPVOItems:currentUnload.pvoLoadID forLot:lotNum]];
        
        while([remainingItems count] > 0)
        {
            PVOItemDetail *pvoitem = [remainingItems objectAtIndex:0];
            self.currentLotNumber = pvoitem.lotNumber;
            self.currentItemNumber = pvoitem.itemNumber;
            [self continue_Click:nil];
        }
    }
    
    [optionsTable reloadData];
    [recentTable reloadData];
    
    if([duplicatedBatchTags count] > 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Messages"
                                                        message:@"All Barcodes delivered successfully. Duplicate"/* high value */" items were detected. Tap Continue to enter exceptions"/*/initials*/" for these items."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Continue", nil];
        alert.tag = PVO_DELIVERY_ALERT_BATCH_EXCEPTIONS;
        [alert show];
        
    }
    
    if([deliverAllHighValueItems count] > 0)
    {
        //have high value items, start prompting for initials
        [self promptForHighValueInitials:[deliverAllHighValueItems objectAtIndex:0]];
    }
    else
        deliverAllNoScanner = NO;
    
    self.deliveringAll = FALSE;
}

-(NSString*)signatureViewTextForDisplay:(SignatureViewController*)sigController
{
    if(sigController.tag == PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS ||
       sigController.tag == PVO_DELIVERY_SIGVIEW_DELIVER_ALL)
    {
        return [AppFunctionality deliverAllPVOItemsSignatureLegal];
    }
    else
    {
        return nil;
    }
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
}//?

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

-(void)roomAdded:(Room*)room
{
    [addRoomController cancel:nil];
    
    if(roomConditions == nil)
        roomConditions = [[PVORoomConditionsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    roomConditions.room = room;
    roomConditions.currentLoad = currentUnload;
    if (currentUnload.pvoLocationID == COMMERCIAL_LOC)
        roomConditions.title = @"Location Conditions";
    else
        roomConditions.title = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";
    
    //
    newNav = [[PortraitNavController alloc] initWithRootViewController:roomConditions];
    
    //wentToRoomConditions = TRUE;
    
    [self presentViewController:newNav animated:YES completion:nil];
    //[self.navigationController pushViewController:roomConditions animated:YES];
}

#pragma mark Actionsheet

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        if (buttonIndex == 0)
        {
            [self complete_Click:self];
        }
        else if (buttonIndex == 1)
        {
            [self launchRoomSummary];
            
            /* ADD ROOM - NEED THIS!
            if(addRoomController == nil)
                addRoomController = [[AddRoomController alloc] initWithStyle:UITableViewStylePlain];
            
            addRoomController.delegate = self;
            addRoomController.caller = self;
            addRoomController.callback = @selector(roomAdded:);
            addRoomController.pvoLocationID = currentUnload.pvoLocationID; //0;//currentLoad.pvoLocationID;
             
            
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:addRoomController];
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
             */
            
        }
    }
}

-(void)launchRoomSummary
{
    if(roomController == nil)
        roomController = [[PVORoomSummaryController alloc] initWithNibName:@"PVORoomSummaryView" bundle:nil];
    
    roomController.inventory = nil;
    roomConditions.currentLoad = nil;
    roomController.currentUnload = currentUnload;
    roomController.quickAddPopupLoaded = NO;
    
    [self.navigationController pushViewController:roomController animated:YES];
}

@end
