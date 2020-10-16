//
//  PVOItemDetailController.m
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOItemDetailController.h"
#import "SwitchCell.h"
#import "LabelTextCell.h"
#import "NoteCell.h"
#import "SurveyAppDelegate.h"
#import "Prefs.h"
#import "ButtonCell.h"
#import "CustomerUtilities.h"
#import "PVOBarcodeValidation.h"
#import "PVOItemSummaryController.h"
#import "PVOWireFrameTypeController.h"

@implementation PVOItemDetailController

@synthesize pvoItem, item, room, tboxCurrent, inventory, cartonContentsController, imageViewer;
@synthesize focusOnTag, tboxComment, wheelDamageController, buttonDamageController, highValueController;
@synthesize quickScanController, currentLoad, descriptiveScreen, delegate, comingFromItemSummary;
@synthesize portraitNavController, noteController, singleFieldController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

- (void)viewDidLoad
{
    SurveyAppDelegate* del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
    
    includedSections = [[NSMutableDictionary alloc] init];
    dimensionUnitTypes = [del.surveyDB getPVODimensionUnitTypes];
    
    if ([SurveyAppDelegate iOS7OrNewer])
    {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    else
    {
        //pre iOS 7 back btn
        UIImage *backImage = [UIImage imageNamed:@"bar_back"];
        UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
        back.adjustsImageWhenHighlighted = FALSE;
        back.bounds = CGRectMake( 0, 0, backImage.size.width, backImage.size.height);
        [back setImage:backImage forState:UIControlStateNormal];
        [back setImage:[UIImage imageNamed:@"bar_back_highlighted"] forState:UIControlStateHighlighted];
        [back addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithCustomView:back];
        self.navigationItem.leftBarButtonItem = backBtn;
    }
    
    weightTypes = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Actual", @"Constructive", nil]
                                                       forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT_TYPE_ACTUAL_SELECTION],
                                                                [NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE_SELECTION], nil]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (pvoItem.cartonContentID > 0)
        [SurveyAppDelegate setupViewForCartonContent:self.view withTableView:self.tableView];
    
    highValueType = [AppFunctionality getHighValueType];
    grabbingQuickScan = NO;
    
    if(!grabbingBarcodeImage)
    {
        voidingTag = NO;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.pvoItemComment = [del.surveyDB getPVOItemComment:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
        self.cubesheet = [del.surveyDB openCubeSheet:del.customerID];
        
        if(pvoItem == nil)
        {
            if([item.name isEqualToString:PVO_VOID_NO_ITEM_NAME])
            {
                voidingTag = YES;
                //force switch out of scanner mode - if they are voiding a tag it is probably ripped or lost.
                inventory.usingScanner = NO;
                self.navigationItem.prompt = nil;
            }
            
            self.pvoItem = [[PVOItemDetail alloc] init];
            
            if ([AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
                pvoItem.cube = item.cube;
            pvoItem.itemID = item.itemID;
            pvoItem.roomID = room.roomID;
            pvoItem.pvoLoadID = currentLoad.pvoLoadID;
            pvoItem.tagColor = inventory.currentColor;
            pvoItem.cartonContents = item.isCP;
            pvoItem.noExceptions = inventory.noConditionsInventory;
            
            //checks the weight calculation type, assigns the calculated weight to the item
            pvoItem.weight = [self getInitialWeightForItem];
            
            if(item.isCP && [del.surveyDB getDriverData].quickInventory)
                pvoItem.noExceptions = YES;
            
            if(!inventory.usingScanner)
            {
                pvoItem.lotNumber = inventory.currentLotNum;
                pvoItem.itemNumber = [del.surveyDB nextPVOItemNumber:del.customerID forLot:inventory.currentLotNum withStartingItem:inventory.nextItemNum];
                inventory.nextItemNum = inventory.nextItemNum + 1;
            }
            
            if(voidingTag)
            {
                pvoItem.itemIsDeleted = YES;
                pvoItem.voidReason = @"Damaged Tag";
            }
            
            pvoItem.damage = [NSMutableArray array];
            
            //if there is no sig, set inventoriedAfterSignature = true;
            PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
            pvoItem.inventoriedAfterSignature = sig != nil;
            
            DriverData *driver = [del.surveyDB getDriverData];
            if (driver.driverType == PVO_DRIVER_TYPE_PACKER && del.lastPackerInitials != nil)
                pvoItem.packerInitials = [NSString stringWithFormat:@"%@", del.lastPackerInitials];
        }
        
        if(reloadItemUponReturn && pvoItem != nil && pvoItem.pvoItemID > 0)
        {
            self.pvoItem = [del.surveyDB getPVOItem:pvoItem.pvoItemID];
            reloadItemUponReturn = FALSE;
        }
        
        packerInitials = [del.surveyDB getAllPackersInitials];
        
        if (pvoItem.cartonContentID == 0)
        {
            [del setCurrentSocketListener:self];
            [del.linea addDelegate:self];
            
            if(inventory.usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
                self.navigationItem.prompt = @"Scanner is not connected";
            else
                self.navigationItem.prompt = nil;
        }
        else
            self.navigationItem.prompt = nil;
        
        
        [self setupContinueButton];
        [self initializeIncludedRows];
        [self.tableView reloadData];
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop 
                                      animated:YES];
    }
    else
    {
        if (pvoItem != nil && pvoItem.cartonContentID == 0)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            if(inventory.usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
                self.navigationItem.prompt = @"Scanner is not connected";
            else
                self.navigationItem.prompt = nil;
        }
        else
            self.navigationItem.prompt = nil;
        
        [self.tableView reloadData];
        grabbingBarcodeImage = NO;
    }
    
    SurveyAppDelegate* del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

-(IBAction)back:(id)sender
{
    if((pvoItem.pvoItemID == 0 || !pvoItem.doneWorking) || (inventory.usingScanner && (pvoItem.lotNumber == nil || [pvoItem.lotNumber length] == 0)))
    {
        //option to save or not...
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Discard Changes?" 
                                                        message:@"You must continue from this screen to save this record. If you decide to go Back, you will discard this item. Would you like to continue to go Back?" 
                                                       delegate:self 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = 1;
        [alert show];
        return;
    }
    else if (pvoItem.cartonContentID > 0 && pvoItem.highValueCost > 0 && highValueType == HV_DETAILS_FLAG)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOItemDetail *parentItem = [del.surveyDB getPVOItem:[del.surveyDB getPVOItemCartonContent:pvoItem.cartonContentID].pvoItemID];
        @try {
            if(parentItem.highValueCost == 0)
            {
                NSString *highValueDesc = [AppFunctionality getHighValueDescription];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:highValueDesc
                                                                message:[NSString stringWithFormat:@"%1$@ items added to a carton require the carton to be designated as %1$@.  Please tap OK to add %1$@ details to this carton.", highValueDesc ]
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                alert.tag = PVO_ITEM_ALERT_HIGH_VALUE;
                [alert show];
                return; //don't pop, handled by alert view delegate
            }
        }
        @finally {
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setupContinueButton
{
 
    if((pvoItem.noExceptions || voidingTag) && !(item.isCP && pvoItem.cartonContents))
    {
        if (pvoItem.cartonContentID == 0)
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next Item"
                                                                                       style:UIBarButtonItemStylePlain 
                                                                                      target:self 
                                                                                      action:@selector(moveToNextDetail:)];
        }
    }
    else
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue"
                                                                                  style:UIBarButtonItemStylePlain 
                                                                                 target:self 
                                                                                 action:@selector(moveToNextDetail:)];
    
}

-(void)commitAndClearFields
{
    if(tboxCurrent != nil)
    {
        [self updateValueWithField:tboxCurrent];
        [tboxCurrent resignFirstResponder];
        self.tboxCurrent = nil;
    }
    if(tboxComment != nil)
    {
        [self updateValueWithField:tboxComment];
        [tboxComment resignFirstResponder];
        self.tboxComment = nil;
    }
}

-(void)initializeIncludedRows
{
    [includedSections removeAllObjects];
    NSMutableArray *theserows = [[NSMutableArray alloc] init];
    [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_TAG_COLOR]];
    [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_ROOM_NAME]];
    [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_ITEM_NAME]];
    if(!inventory.usingScanner && !voidingTag)
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_LOT_NUM]];
    if (pvoItem.cartonContentID > 0)
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CARTON_CONTENT_NAME]];
    
    [includedSections setObject:theserows forKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECTION_INFO]];
    
    theserows = [[NSMutableArray alloc] init];
    
    if (voidingTag)
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_LOT_NUMBER]];
    
    if(!inventory.usingScanner)
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_ITEM_NUM]];
    else
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SCANNER_NUMBER]];
        
    [includedSections setObject:theserows forKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECTION_TAG]];
    theserows = nil;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    
    if((driver.driverType == PVO_DRIVER_TYPE_PACKER || [AppFunctionality showPackerInitialsForDriver]) && !(pvoItem.cartonContentID > 0)) //only show if not carton content
    {
        if (driver.driverType == PVO_DRIVER_TYPE_PACKER || (item != nil && (item.isCP || item.isCrate))) //only show for CP/Crate items if not a Packer
        {
            theserows = [[NSMutableArray alloc] init];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_PACKER_INITIALS]];
        }
    }
    
    if(!voidingTag)
    {
        if(theserows == nil)
            theserows = [[NSMutableArray alloc] init];
        
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_QTY]];
        
        if (pvoItem.cartonContentID <= 0 && [AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
        {
            if (inventory.loadType == MILITARY && pvoItem.cartonContentID <= 0)
            {
                [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT_TYPE]];
                
                // set the default weightType for military items
                if (pvoItem.weightType == 0) {
                    pvoItem.weightType = PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE;
                }
                
            }
            
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CUBE]];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT]];
            
        }
        
        if((pvoItem.pvoItemID <= 0 || !pvoItem.doneWorking) && driver.driverType != PVO_DRIVER_TYPE_PACKER)// && !item.isCP && !item.isPBO && !item.isCrate)
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_QUICK_SCAN]];
        
        if (pvoItem.cartonContentID <= 0)
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CARTON_CONTENTS]];
        
        if (pvoItem.cartonContentID <= 0 && [AppFunctionality showCPProvided])
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CP_IS_PROVIDED]];
        
        if (inventory.loadType == MILITARY && pvoItem.cartonContentID <= 0)//Remove MPRO and SPRO option from carton contents per defect 1036
        {
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_MPRO]];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SPRO]];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CONS]];
        }
        
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_DESCRIPTIVE]];
        if ([AppFunctionality allowNoCoditionsInventory:[CustomerUtilities customerPricingMode] withLoadType:inventory.loadType])
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_NO_EXC]];
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CAMERA]];
        if (highValueType == HV_DETAILS_FLAG)
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_HIGH_VALUE_SWITCH]];
        else if (highValueType == HV_DETAILS_COST)
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_HIGH_VALUE_COST]];
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_ADDITIONAL]];
        
        if([AppFunctionality includeSecuritySealRowInItemDetails])
        {
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECURITY_SEAL]];
        }
    
        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_COMMENTS]];
        
    }
    
//    if([AppFunctionality includeSecuritySealRowInItemDetails])
//    {
//        [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECURITY_SEAL]];
//    }
    
    if(theserows != nil)
    {
        [includedSections setObject:theserows forKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECTION_ADDITIONAL]];
    }
    
    if(!voidingTag)
    {
        if (item == nil)
            item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
        if((item.isCrate && pvoItem.cartonContentID <= 0) || ([AppFunctionality showCrateDimensionsForCartonContent] && pvoItem.cartonContentID > 0))
        {
            theserows = [[NSMutableArray alloc] init];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CRATE_HAS_DIMS]];
            
            if(pvoItem.hasDimensions)
            {
                [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CRATE_LENGTH]];
                [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CRATE_WIDTH]];
                [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CRATE_HEIGHT]];
                [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_CRATE_DIMENSION_UNIT_TYPE]];
            }
            
            [includedSections setObject:theserows forKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECTION_CRATE_DIMENSIONS]];
        }
        
        if (pvoItem.cartonContentID <= 0)
        {
            theserows = [[NSMutableArray alloc] init];
            [theserows addObject:[NSNumber numberWithInt:PVO_ITEM_DETAIL_DELETE]];
            [includedSections setObject:theserows forKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_SECTION_DELETE]];
        }
        
    }
}

-(IBAction)moveToNextDetail:(id)sender
{
    //save for any changes to propogate to next screen (namely the id)
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self commitAndClearFields];
    
    if([pvoItem.itemNumber length] == 0)
    {
        [SurveyAppDelegate showAlert:@"You must have an item number entered to continue." withTitle:@"Invalid Inventory Number"];
        return;
    }
    
    DriverData *data = [del.surveyDB getDriverData];
    if(data.driverType == PVO_DRIVER_TYPE_PACKER && (pvoItem.packerInitials == nil || pvoItem.packerInitials.length == 0) && pvoItem.cartonContentID <= 0)
    { //only show up if this isn't a carton content item
        [SurveyAppDelegate showAlert:@"You must have packer's initials entered to continue." withTitle:@"Packer's Initials"];
        return;
    }
    
    if(item.isGun || inventory.loadType == MILITARY) //enforce Gun restrictions always
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (item == nil)
            item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
        if (item != nil && item.itemID > 0)
        {
            if (item.isVehicle || item.isGun || item.isElectronic)
            {
                BOOL foundMissingItem = NO;
                NSString *reqFields = @"Required fields must be populated before continuing: ";
                if (inventory.loadType == MILITARY && item.isVehicle && pvoItem.year <= 0)
                {
                    reqFields = [reqFields stringByAppendingString:@"Year"];
                    foundMissingItem = YES;
                }
                if (pvoItem.make == nil || [pvoItem.make isEqualToString:@""])
                {
                    reqFields = [reqFields stringByAppendingFormat:@"%@Make", foundMissingItem ? @", " : @""];
                    foundMissingItem = YES;
                }
                if (pvoItem.modelNumber == nil || [pvoItem.modelNumber isEqualToString:@""])
                {
                    reqFields = [reqFields stringByAppendingFormat:@"%@Model", foundMissingItem ? @", " : @""];
                    foundMissingItem = YES;
                }
                if (pvoItem.serialNumber == nil || [pvoItem.serialNumber isEqualToString:@""])
                {
                    reqFields = [reqFields stringByAppendingFormat:@"%@Serial#", foundMissingItem ? @", " : @""];
                    foundMissingItem = YES;
                }
                if (inventory.loadType == MILITARY && item.isVehicle && pvoItem.odometer <= 0)
                {
                    reqFields = [reqFields stringByAppendingFormat:@"%@Odometer", foundMissingItem ? @", " : @""];
                    foundMissingItem = YES;
                }
                if (item.isGun && (pvoItem.caliberGauge == nil || [pvoItem.caliberGauge isEqualToString:@""]))
                {
                    reqFields = [reqFields stringByAppendingFormat:@"%@Caliber/Gauge", foundMissingItem ? @", " : @""];
                    foundMissingItem = YES;
                }
                
                if (foundMissingItem)
                {
                    [SurveyAppDelegate showAlert:[reqFields stringByAppendingString:@"."] withTitle:@"Required Fields"];
                    return;
                }
            }
        }
    }
    
    pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
    
    if(pvoItem.pvoItemID == -1)
        [self handleDuplicateItem];
    else
    {
        if((voidingTag || pvoItem.noExceptions) && !pvoItem.cartonContents)
        {
            if(delegate != nil && [delegate respondsToSelector:@selector(pvoItemControllerContinueToNextItem:)])
            {
                [del.surveyDB doneWorkingPVOItem:pvoItem.pvoItemID];
                [delegate pvoItemControllerContinueToNextItem:self];
            }
            else
            {
                //next item... so jump back to item list, and tap add button...
                PVOItemSummaryController *itemController = nil;
                for (id view in [self.navigationController viewControllers]) {
                    if([view isKindOfClass:[PVOItemSummaryController class]])
                        itemController = view;
                }
                
                itemController.forceLaunchAddPopup = YES;
                //manually calling this method results in the addItem method being called before itemController's ViewDidAppear method which causes a lot of UI errors
                //                [itemController addItem:self];
                [self.navigationController popToViewController:itemController animated:YES];
            }
        }
        else if(pvoItem.cartonContents)
        {
            reloadItemUponReturn = YES;
            
            if(cartonContentsController == nil)
                cartonContentsController = [[PVOCartonContentsSummaryController alloc] initWithNibName:@"PVOCartonContentsView" bundle:nil];
            cartonContentsController.title = @"Carton Contents";
            cartonContentsController.pvoItem = pvoItem;
            cartonContentsController.hideContinueButton = NO;
            cartonContentsController.resetVistedTags = YES;
            cartonContentsController.quickAddPopupLoaded = NO;
            [self.navigationController pushViewController:cartonContentsController animated:YES];
            
            
            //[cartonContentsController addContentItem:self];
        }
        else
        {
            [self commitAndClearFields];

#ifdef TARGET_IPHONE_SIMULATOR
            [del showPVODamageController:self.navigationController
                                 forItem:pvoItem 
                      showNextItemButton:YES
                               pvoLoadID:pvoItem.pvoLoadID
                     withWireframeOption:[self pvoItemSupportsWireframeExceptions]
                            withDelegate:self];
#else
            [del showPVODamageController:self.navigationController
                                 forItem:pvoItem
                      showNextItemButton:YES
                               pvoLoadID:pvoItem.pvoLoadID
                            withDelegate:self];
#endif
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(pvoItem.pvoItemID <= 0 && comingFromItemSummary && !voidingTag && !inventory.usingScanner && [del.surveyDB getDriverData].quickInventory) // defect 11682
    {//load the danged next screen (maybe just check animated?)
        [self moveToNextDetail:nil];
    }
    
    comingFromItemSummary = NO;
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self commitAndClearFields];
    
    if(!grabbingBarcodeImage)
    {
    
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        //release from kscan notifications
        [del setCurrentSocketListener:nil];
        [del.linea removeDelegate:self];
        
        if (!grabbingQuickScan)
        {
            if(discardChangesAndDelete)
            {
                [del.surveyDB deletePVOItemComment:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
                [del.surveyDB deletePVOItem:pvoItem.pvoItemID withCustomerID:del.customerID];
            }
            else
            {
                pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
                [del.surveyDB savePVOItemComment:self.pvoItemComment.comment withPVOItemID:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
            }
            
            discardChangesAndDelete = FALSE;
        }
    }
    
    self.navigationItem.prompt = nil;
    
    [super viewWillDisappear:animated];
}

-(BOOL)checkForDuplicate
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.surveyDB pvoItemExists:pvoItem])
    {
        [self handleDuplicateItem];
        return TRUE;
    }
    return FALSE;
}

-(void)initialsSelected:(NSString*)initials
{
    pvoItem.packerInitials = initials;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    if (driver.driverType == PVO_DRIVER_TYPE_PACKER)
        del.lastPackerInitials = initials;
}

-(void)unitOfMeasurementSelected:(NSNumber*)value
{
    pvoItem.dimensionUnitType = [value intValue];
    [pvoItem updateCube];
    pvoItem.weight = inventory.weightFactor * pvoItem.cube;
}

-(void)handleDuplicateItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemDetail *prevItem = [del.surveyDB getPVOItem:pvoItem.pvoLoadID forLotNumber:pvoItem.lotNumber withItemNumber:pvoItem.fullItemNumber includeDeleted:TRUE];
    BOOL previousItemIsVoid = (prevItem != nil ? prevItem.itemIsDeleted : FALSE);
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Duplicate Tag"
                                                    delegate:self 
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil 
                                           otherButtonTitles:inventory.usingScanner ? @"Ignore Scan" : @"Re-enter Number", (previousItemIsVoid ? nil :@"Go to Item"), @"Void Item", /*@"Delete Item",*/ nil];
    as.tag = PVO_ITEM_ALERT_DUPLICATE;
    [as showInView:self.view];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)deleteItem:(id)sender
{
    if(pvoItem.pvoItemID == 0 || !pvoItem.doneWorking)
    {
        [SurveyAppDelegate showAlert:@"You must have a saved inventory item before the item can be Voided.  If you have a damaged tag that cannot be scanned, please hit Back, Discard changes, and use the Void Tag feature." withTitle:@"Item Must Exist"];
    }
    else
    {
        if ([AppFunctionality canDeleteInventoryItems])
        {
            UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Delete"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Void Item", @"Delete Item", nil];
            as.tag = PVO_ITEM_ALERT_DELETE;
            [as showInView:self.view];
        }
        else
            [self voidWorkingItem];
    }
}

-(void)deleteWorkingItem
{
    discardChangesAndDelete = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)voidWorkingItem
{
    if(noteController == nil)
        noteController = [[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped];
    noteController.caller = self;
    noteController.callback = @selector(voidReasonEntered:);
    noteController.destString = @"";
    noteController.description = @"Please enter a Void Reason";
    noteController.navTitle = @"Void Reason";
    noteController.keyboard = UIKeyboardTypeASCIICapable;
    noteController.dismiss = YES;
    noteController.modalView = YES;
    noteController.noteType = NOTE_TYPE_NONE;
    noteController.maxLength = -1;
    
    portraitNavController = [[PortraitNavController alloc] initWithRootViewController:noteController];
    
    [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
}

-(void)voidReasonEntered:(NSString*)voidReason
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (voidReason == nil || [voidReason isEqualToString:@""])
    {
        [SurveyAppDelegate showAlert:@"Void Reason is required to continue." withTitle:@"Text Required"];
    }
    else
    {
        pvoItem.voidReason = voidReason;
        pvoItem.itemIsDeleted = YES;
        [del.surveyDB voidPVOItem:pvoItem.pvoItemID withReason:voidReason];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)highValueCostEntered:(NSString*)cost
{
    @try {
        if (cost != nil && [cost length] > 0)
            pvoItem.highValueCost = [cost doubleValue];
    }
    @catch (NSException *exception) {
        pvoItem.highValueCost = 0;
    }
}

-(void)showReleasedValWarning
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[AppFunctionality getHighValueDescription]
                                                    message:[NSString stringWithFormat:@"FVP valuation has not been chosen. Items marked as %@ will not be covered for more than $100 per pound unless FVP is selected.", [AppFunctionality getHighValueDescription]]
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = PVO_ITEM_ALERT_RELEASED_VAL;
    [alert show];
    
    
    return; //don't pop, handled by alert view delegate
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == PVO_ITEM_DETAIL_CARTON_CONTENTS)
        pvoItem.cartonContents = sw.on;
    else if(sw.tag == PVO_ITEM_DETAIL_CP_IS_PROVIDED)
        pvoItem.isCPProvided = sw.on;
    else if(sw.tag == PVO_ITEM_DETAIL_CRATE_HAS_DIMS)
    {
        pvoItem.hasDimensions = sw.on;
        [self initializeIncludedRows];
        [self.tableView reloadData];
    }
    else if(sw.tag == PVO_ITEM_DETAIL_NO_EXC)
    {
        pvoItem.noExceptions = !sw.on;
        [self setupContinueButton];
    }
    else if(sw.tag == PVO_ITEM_DETAIL_HIGH_VALUE_SWITCH)
    {
        pvoItem.highValueCost = (sw.on ? 1 : 0);
        
        //Feature 1043
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (sw.on && !del.showedReleasedValWarning)
        {
            PVOInventory *data = [del.surveyDB getPVOData:del.customerID];
            if (data.valuationType != PVO_VALUATION_FVP)
            {
                [self showReleasedValWarning];
            }
        }
    }
    else if(sw.tag == PVO_ITEM_DETAIL_MPRO)
    {//Item can only be either MPRO or SPRO per defect 1037
        pvoItem.itemIsMPRO = sw.on;
        pvoItem.itemIsSPRO = FALSE;
        pvoItem.itemIsCONS = FALSE;
        [self.tableView reloadData];
    }
    else if(sw.tag == PVO_ITEM_DETAIL_SPRO)
    {//Item can only be either MPRO or SPRO per defect 1037
        pvoItem.itemIsSPRO = sw.on;
        pvoItem.itemIsMPRO = FALSE;
        pvoItem.itemIsCONS = FALSE;
        [self.tableView reloadData];
    }
    else if (sw.tag == PVO_ITEM_DETAIL_CONS)
    {
        pvoItem.itemIsCONS = sw.on;
        pvoItem.itemIsMPRO = FALSE;
        pvoItem.itemIsSPRO = FALSE;
        [self.tableView reloadData];
    }
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)updateValueWithField:(id)field
{
    int row = [(UIView*)field tag];
    
    BOOL updateCube = NO;
    
    switch (row) {
        case PVO_ITEM_DETAIL_ITEM_NUM:
            pvoItem.itemNumber = [field text];
            break;
        case PVO_ITEM_DETAIL_LOT_NUMBER:
            pvoItem.lotNumber = [field text];
            break;
        case PVO_ITEM_DETAIL_QTY:
            pvoItem.quantity = [[field text] intValue];
            break;
        case PVO_ITEM_DETAIL_CRATE_LENGTH:
            pvoItem.length = [[field text] intValue];
            updateCube = YES;
            break;
        case PVO_ITEM_DETAIL_CRATE_WIDTH:
            pvoItem.width = [[field text] intValue];
            updateCube = YES;
            break;
        case PVO_ITEM_DETAIL_CRATE_HEIGHT:
            pvoItem.height = [[field text] intValue];
            updateCube = YES;
            break;
        case PVO_ITEM_DETAIL_COMMENTS:
            self.pvoItemComment.comment = [field text];
            break;
        case PVO_ITEM_DETAIL_CUBE:
            pvoItem.cube = [[field text] doubleValue];
            
            if (pvoItem.weightType == PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE)
            {
                pvoItem.weight = pvoItem.cube * inventory.weightFactor;
                [self.tableView reloadData];
            }
            break;
        case PVO_ITEM_DETAIL_WEIGHT:
            pvoItem.weight = [[field text] intValue];
            break;
    }
    
    if(updateCube) {
        [pvoItem updateCube];
        pvoItem.weight = inventory.weightFactor * pvoItem.cube;
    }
}


-(BOOL)pvoItemSupportsWireframeExceptions
{//brian and jeff originally wanted wireframe to be an option here instead of bulky inventory
    if ([AppFunctionality enableWireframeExceptionsForItems])
    {
        //also add an appfuncitonality method to disable by vanline
    #ifdef TARGET_IPHONE_SIMULATOR
        //    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([item.name containsString:@"Piano"] || [item.name containsString:@"Motorcycle"])
        {
            return YES;
        }
    #endif
    }
    return NO;
}

-(int)getInitialWeightForItem
{
    int retval = 0;
    if (pvoItem.weightType == PVO_ITEM_DETAIL_WEIGHT_TYPE_NONE && pvoItem.weight == 0)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        pvoItem.weightType = PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE;
        
        CubeSheet *cs = [del.surveyDB openCubeSheet:del.customerID];
        double wt = item.cube * cs.weightFactor;
        
        retval = (int)wt;
        
    }
    
    return retval;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [includedSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int mysection = [[[[includedSections allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:section] intValue];
    return [(NSArray*)[includedSections objectForKey:[NSNumber numberWithInt:mysection]] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [self rowTypeForIndexPath:indexPath];
    
    if(row == PVO_ITEM_DETAIL_ROOM_NAME || 
       row == PVO_ITEM_DETAIL_ITEM_NAME || 
       row == PVO_ITEM_DETAIL_TAG_COLOR || 
       row == PVO_ITEM_DETAIL_LOT_NUM ||
       row == PVO_ITEM_DETAIL_CARTON_CONTENT_NAME)
        return 30;
    else if(row == PVO_ITEM_DETAIL_COMMENTS)
        return 130;
    else
        return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([SurveyAppDelegate iOS7OrNewer])
        return CGFLOAT_MIN;
    return UITableViewAutomaticDimension; //default
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    int mysection = [[[[includedSections allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:section] intValue];
    
    if(mysection == PVO_ITEM_DETAIL_SECTION_INFO)
        return @"Item Info";
    else if(mysection == PVO_ITEM_DETAIL_SECTION_TAG)
        return @"Inventory Tag Number";
    else if(mysection == PVO_ITEM_DETAIL_SECTION_ADDITIONAL)
        return @"Additional Item Data";
    else if(mysection == PVO_ITEM_DETAIL_SECTION_CRATE_DIMENSIONS)
    {
        if (pvoItem.cartonContentID <= 0 && item != nil && item.isCrate)
            return @"Crate Dimensions";
        else
            return @"Dimensions";
    }
    
    return nil;
}

-(int)rowTypeForIndexPath:(NSIndexPath *)indexPath
{
    int mysection = [[[[includedSections allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:indexPath.section] intValue];
    return [[[includedSections objectForKey:[NSNumber numberWithInt:mysection]] objectAtIndex:indexPath.row] intValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *NoteCellIdentifier = @"NoteCell";
    static NSString *TextCellIdentifier = @"LabelTextCell";
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    static NSString *ResizeCellIdentifier = @"ResizeCell";
    
    UITableViewCell *cell = nil;
    SwitchCell *swCell = nil;
    LabelTextCell *ltCell = nil;
    NoteCell *noteCell = nil;
    ButtonCell *buttonCell = nil;
    UITableViewCell *resizeCell = nil;
    
    int row = [self rowTypeForIndexPath:indexPath];
    
    if(row == PVO_ITEM_DETAIL_DELETE)
    {
        if ([SurveyAppDelegate iOS7OrNewer])
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            [cell setBackgroundColor:[UIColor redColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            cell.textLabel.text = ([AppFunctionality canDeleteInventoryItems] ? @"Delete" : @"Void");
        }
        else
        {
            buttonCell = (ButtonCell *)[tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
            
            if (buttonCell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
                buttonCell = [nib objectAtIndex:0];
                
                [buttonCell.cmdButton addTarget:self
                                         action:@selector(deleteItem:) 
                               forControlEvents:UIControlEventTouchUpInside];
                [buttonCell.cmdButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:8. topCapHeight:0.] 
                                                forState:UIControlStateNormal];
                [buttonCell.cmdButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                buttonCell.cmdButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
                buttonCell.cmdButton.titleLabel.shadowColor = [UIColor lightGrayColor];
                buttonCell.cmdButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
            }
            
            [buttonCell.cmdButton setTitle:([AppFunctionality canDeleteInventoryItems] ? @"Delete" : @"Void") forState:UIControlStateNormal];
        }
    }
    else if(row == PVO_ITEM_DETAIL_CARTON_CONTENTS ||
            row == PVO_ITEM_DETAIL_NO_EXC ||
            row == PVO_ITEM_DETAIL_CP_IS_PROVIDED ||
            row == PVO_ITEM_DETAIL_CRATE_HAS_DIMS ||
            row == PVO_ITEM_DETAIL_HIGH_VALUE_SWITCH ||
            row == PVO_ITEM_DETAIL_MPRO ||
            row == PVO_ITEM_DETAIL_SPRO ||
            row == PVO_ITEM_DETAIL_CONS)
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
        
        if(row == PVO_ITEM_DETAIL_CARTON_CONTENTS)
        {
            swCell.labelHeader.text = @"Carton Contents";
            swCell.switchOption.on = pvoItem.cartonContents;
        }
        else if(row == PVO_ITEM_DETAIL_NO_EXC)
        {
            swCell.labelHeader.text = @"Exceptions";
            swCell.switchOption.on = !pvoItem.noExceptions;
        }
        else if(row == PVO_ITEM_DETAIL_CP_IS_PROVIDED)
        {
            swCell.labelHeader.text = @"Is Provided";
            swCell.switchOption.on = pvoItem.isCPProvided;
        }
        else if(row == PVO_ITEM_DETAIL_CRATE_HAS_DIMS)
        {
            swCell.labelHeader.text = @"Has Dimensions";
            swCell.switchOption.on = pvoItem.hasDimensions;
        }
        else if(row == PVO_ITEM_DETAIL_HIGH_VALUE_SWITCH)
        {
            swCell.labelHeader.text = [AppFunctionality getHighValueDescription];
            swCell.switchOption.on = (pvoItem.highValueCost > 0);
        }
        else if(row == PVO_ITEM_DETAIL_MPRO)
        {
            swCell.labelHeader.text = @"MPRO";
            swCell.switchOption.on = pvoItem.itemIsMPRO;
        }
        else if(row == PVO_ITEM_DETAIL_SPRO)
        {
            swCell.labelHeader.text = @"SPRO";
            swCell.switchOption.on = pvoItem.itemIsSPRO;
        }
        else if (row == PVO_ITEM_DETAIL_CONS)
        {
            swCell.labelHeader.text = @"CONS";
            swCell.switchOption.on = pvoItem.itemIsCONS;
        }
    }
    else if(row == PVO_ITEM_DETAIL_ITEM_NUM ||
            row == PVO_ITEM_DETAIL_QTY ||
            row == PVO_ITEM_DETAIL_CUBE ||
            row == PVO_ITEM_DETAIL_WEIGHT ||
            row == PVO_ITEM_DETAIL_CRATE_LENGTH ||
            row == PVO_ITEM_DETAIL_CRATE_WIDTH ||
            row == PVO_ITEM_DETAIL_CRATE_HEIGHT ||
            row == PVO_ITEM_DETAIL_LOT_NUMBER)
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
            ltCell.tboxValue.font = [UIFont systemFontOfSize:17.];
        }
        
        ltCell.tboxValue.tag = row;
        ltCell.tboxValue.enabled = YES;
        ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
        
        if(row == PVO_ITEM_DETAIL_ITEM_NUM)
        {
            ltCell.labelHeader.text = @"Item Number";
            ltCell.tboxValue.text = pvoItem.itemNumber;
            ltCell.tboxValue.enabled = (pvoItem.cartonContentID <= 0);
        }
        if (row == PVO_ITEM_DETAIL_LOT_NUMBER)
        {
            ltCell.labelHeader.text = @"Lot Number";
            ltCell.tboxValue.text = pvoItem.lotNumber;
            ltCell.tboxValue.enabled = (pvoItem.cartonContentID <= 0);
        }
        else if(row == PVO_ITEM_DETAIL_QTY)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (item == nil) item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
            ltCell.labelHeader.text = @"Quantity";
            if(pvoItem.quantity > 0)
                ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", pvoItem.quantity];
            else
                ltCell.tboxValue.text = @"";
            ltCell.tboxValue.enabled = !((item.isCP || item.isPBO || item.isCrate) && pvoItem.cartonContentID <= 0);
        }
        else if(row == PVO_ITEM_DETAIL_CUBE)
        {
            ltCell.labelHeader.text = @"Cube";
            ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:pvoItem.cube];
            
            [ltCell.tboxValue setDelegate:self];
            [ltCell.tboxValue addTarget:self
                                 action:@selector(cubeTextFieldFinished:)
                       forControlEvents:UIControlEventEditingDidEnd];
            
        }
        else if(row == PVO_ITEM_DETAIL_WEIGHT)
        {
            ltCell.labelHeader.text = @"Weight";
            
            if (inventory.loadType == MILITARY && pvoItem.cartonContentID <= 0)
            {
                if (pvoItem.weightType == PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE)
                {
                    pvoItem.weight = pvoItem.cube * inventory.weightFactor;
                    
                    ltCell.tboxValue.enabled = false;
                    
                    [ltCell.tboxValue setDelegate:self];
                }
                else
                {
                    ltCell.tboxValue.enabled = true;
                }
                
            }
            
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", pvoItem.weight];
        }
        else if(row == PVO_ITEM_DETAIL_CRATE_LENGTH)
        {
            ltCell.labelHeader.text = @"Length";
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", pvoItem.length];
        }
        else if(row == PVO_ITEM_DETAIL_CRATE_WIDTH)
        {
            ltCell.labelHeader.text = @"Width";
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", pvoItem.width];
        }
        else if(row == PVO_ITEM_DETAIL_CRATE_HEIGHT)
        {
            ltCell.labelHeader.text = @"Height";
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", pvoItem.height];
        }
    }
    
    else if(row == PVO_ITEM_DETAIL_COMMENTS)
    {
        noteCell = (NoteCell*)[tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
        if (noteCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
            noteCell = [nib objectAtIndex:0];
            noteCell.tboxNote.delegate = self;
        }
        
        //noteCell.tboxNote.placeholder = @"Comment";
        
        noteCell.tboxNote.tag = row;
        //noteCell.tboxNote.text = pvoItem.comments;
        
        //Downloaded item notes were printing over top of placeholder bc TextChanged wasn't being hit. Defect 1040
        [noteCell.tboxNote setPlaceholder:@"Comment" withText:self.pvoItemComment.comment];
        
    }
    else if(row == PVO_ITEM_DETAIL_ADDITIONAL || row == PVO_ITEM_DETAIL_CRATE_DIMENSION_UNIT_TYPE ||
            row == PVO_ITEM_DETAIL_SECURITY_SEAL)
    {
        resizeCell = [tableView dequeueReusableCellWithIdentifier:ResizeCellIdentifier];
        if (resizeCell == nil) {
            resizeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ResizeCellIdentifier];
        }
        
        resizeCell.imageView.image = nil;
        resizeCell.accessoryType = UITableViewCellAccessoryNone;
        resizeCell.textLabel.textColor = [UIColor blackColor];
        resizeCell.textLabel.numberOfLines = 1;
        resizeCell.textLabel.minimumFontSize = 7;
        resizeCell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        if(row == PVO_ITEM_DETAIL_ADDITIONAL)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (item == nil) item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
            resizeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (item.isGun || (inventory.loadType == MILITARY && (item.isVehicle || item.isElectronic)))
            {
                NSString *label = [NSString stringWithFormat:@"%@%@%@%@",
                                   (inventory.loadType == MILITARY && item.isVehicle ? @"Year/" : @""),
                                   @"Make/Model/Serial#/",
                                   (inventory.loadType == MILITARY && item.isVehicle ? @"Odometer/" : @""),
                                   (item.isGun ? @"Caliber/Gauge/" : @"")];
                resizeCell.textLabel.text = [label substringToIndex:[label length]-1]; //drop off last "/"
            }
            else
                resizeCell.textLabel.text = @"Model/Serial#";
        }
        else if(row == PVO_ITEM_DETAIL_SECURITY_SEAL)
        {
            resizeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            resizeCell.textLabel.text = @"Security Seal Number";
        }

        else if(row == PVO_ITEM_DETAIL_CRATE_DIMENSION_UNIT_TYPE)
        {
            
            resizeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            resizeCell.textLabel.text = [NSString stringWithFormat:@"Unit of Measurement: %@",
                                         pvoItem.dimensionUnitType == 0 ? @"None" :
                                         [dimensionUnitTypes objectForKey:[NSNumber numberWithInt:pvoItem.dimensionUnitType]]];
        }
    }
    else
    {
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell.textLabel setTextColor:[UIColor blackColor]];
        [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
        
        if(row == PVO_ITEM_DETAIL_ROOM_NAME)
            cell.textLabel.text = [NSString stringWithFormat:@"Room: %@", room.roomName];
        else if(row == PVO_ITEM_DETAIL_ITEM_NAME)
            cell.textLabel.text = [NSString stringWithFormat:@"Item: %@", item.name];
        else if(row == PVO_ITEM_DETAIL_CARTON_CONTENT_NAME)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOCartonContent *cc = [del.surveyDB getPVOItemCartonContent:pvoItem.cartonContentID];
            PVOCartonContent *thecontent = [del.surveyDB getPVOCartonContent:cc.contentID withCustomerID:del.customerID];
            cell.textLabel.text = [NSString stringWithFormat:@"Content: %@", thecontent.description];

        }
        else if(row == PVO_ITEM_DETAIL_TAG_COLOR)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSDictionary *dict = [del.surveyDB getPVOColors];
            cell.textLabel.text = [NSString stringWithFormat:@"Tag Color: %@", 
                                   [dict objectForKey:[NSNumber numberWithInt:pvoItem.tagColor]]];
        }
        else if(row == PVO_ITEM_DETAIL_CAMERA)
        {
            UIImage *myimage = pvoItem.pvoItemID != 0 ? [SurveyImageViewer getDefaultImage:IMG_PVO_ITEMS forItem:pvoItem.pvoItemID] : nil;
            if(myimage == nil)
                myimage = [UIImage imageNamed:@"img_photo.png"];
            cell.textLabel.text = @"Manage Photos";
            cell.imageView.image = myimage;
        }
        else if(row == PVO_ITEM_DETAIL_HIGH_VALUE_COST)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [AppFunctionality getHighValueDescription];
        }
        else if(row == PVO_ITEM_DETAIL_LOT_NUM)
            cell.textLabel.text = [NSString stringWithFormat:@"Lot Number: %@", pvoItem.lotNumber];
        else if(row == PVO_ITEM_DETAIL_QUICK_SCAN)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Quick Scan";
        }
        else if(row == PVO_ITEM_DETAIL_SCANNER_NUMBER)
        {
            if([pvoItem.itemNumber length] == 0)
            {
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.text = @"Please Scan Item Tag";
            }
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Tag: %@", [pvoItem displayInventoryNumber]];
        }
        else if(row == PVO_ITEM_DETAIL_DESCRIPTIVE)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Descriptive Symbols";
        }
        else if(row == PVO_ITEM_DETAIL_PACKER_INITIALS)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"Packer: %@", pvoItem.packerInitials == nil || pvoItem.packerInitials.length == 0 ? @"None" : pvoItem.packerInitials];
        }
        else if (row == PVO_ITEM_DETAIL_WEIGHT_TYPE)
        {
            NSString *weightType = @"";
            
            if (pvoItem.weightType == PVO_ITEM_DETAIL_WEIGHT_TYPE_ACTUAL)
                weightType = [weightTypes objectForKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT_TYPE_ACTUAL_SELECTION]];
            else
                weightType = [weightTypes objectForKey:[NSNumber numberWithInt:PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE_SELECTION]];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"Weight type: %@", weightType];
        }
        
    }
    
    return cell != nil ? cell : resizeCell != nil ? resizeCell : swCell != nil ? (UITableViewCell*)swCell : ltCell != nil ? (UITableViewCell*)ltCell : noteCell != nil ? (UITableViewCell*)noteCell : buttonCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self commitAndClearFields];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [self rowTypeForIndexPath:indexPath];
    
    if(row == PVO_ITEM_DETAIL_SCANNER_NUMBER)
    {
//        if([Prefs betaPassword] != nil && [[Prefs betaPassword] isEqualToString:@"camera"])
//        {
            if(zbar == nil)
                zbar = [ZBarReaderViewController new];
            zbar.readerDelegate = self;
            [self presentViewController:zbar animated:YES completion:nil];
            grabbingBarcodeImage = YES;
//        }
    }
    else if(row == PVO_ITEM_DETAIL_CAMERA)
    {
        if ([self forceValidTagForScan])
            return;
        
        if(imageViewer == nil)
            imageViewer = [[SurveyImageViewer alloc] init];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
        if(pvoItem.pvoItemID == -1)
            [self handleDuplicateItem];
        else
        {
            imageViewer.photosType = IMG_PVO_ITEMS;
            imageViewer.customerID = del.customerID;
            imageViewer.subID = pvoItem.pvoItemID;
            
            imageViewer.caller = self.view;
            
            imageViewer.viewController = self;
            
            [imageViewer loadPhotos];
        }
        
    }
    else if(row == PVO_ITEM_DETAIL_QUICK_SCAN)
    {
        if ([self forceValidTagForScan])
            return;
        
        if([pvoItem.itemNumber length] == 0 && !inventory.usingScanner)
        {
            [SurveyAppDelegate showAlert:@"You must have the first item number entered to continue." withTitle:@"Invalid Inventory Number"];
            return;
        }
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if([pvoItem.itemNumber length] > 0)
        {
            /*pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
            
            if(pvoItem.pvoItemID == -1)
                [self handleDuplicateItem];*/
            // per defect 365, we save item once quantity is captured 
            PVOItemDetail *prevItem = [del.surveyDB getPVOItem:pvoItem.pvoLoadID forLotNumber:pvoItem.lotNumber withItemNumber:pvoItem.fullItemNumber includeDeleted:TRUE];
            if (prevItem != nil && (pvoItem.pvoItemID <= 0 || prevItem.pvoItemID != pvoItem.pvoItemID))
            {
                [self handleDuplicateItem];
            }
        }
        else
            discardChangesAndDelete = TRUE;//make sure it doesn't try to save
        
        if(pvoItem.pvoItemID != -1)
        {
            if (inventory.usingScanner) //go ahead and save the first item if we're using a scanner
            {
                pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
                [del.surveyDB savePVOItemComment:self.pvoItemComment.comment withPVOItemID:pvoItem.pvoItemID withCommentType:COMMENT_TYPE_LOADING];
            }
            
            grabbingQuickScan = YES;
            if(quickScanController == nil)
                quickScanController = [[PVOQuickScanController alloc] initWithStyle:UITableViewStyleGrouped];
            quickScanController.title = @"Quick Scan";
            quickScanController.inventory = inventory;
            quickScanController.pvoItem = pvoItem;
            quickScanController.quantity = 0;
            quickScanController.managingPhotos = NO;
            quickScanController.updatePvoItemAfterQuantity = YES;
            quickScanController.hideBackButtonWithScanner = NO; //reset, will be set once item is scanned
            quickScanController.currentLoad = currentLoad;
            [self.navigationController pushViewController:quickScanController animated:YES];
        }
    }
    else if(row == PVO_ITEM_DETAIL_HIGH_VALUE_COST)
    {
        if ([self forceValidTagForScan])
            return;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
        if(pvoItem.pvoItemID == -1)
            [self handleDuplicateItem];
        else
        {
            if ([AppFunctionality grabHighValueInitials])
            {
                if(highValueController == nil)
                    highValueController = [[PVOHighValueController alloc] initWithNibName:@"PVOHighValueView" bundle:nil];
                
                reloadItemUponReturn = YES;
                highValueController.pvoItem = pvoItem;
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:highValueController];
                portraitNavController.modalPresentationStyle = UIModalPresentationFullScreen;

                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
            }
            else
            {
                [del pushSingleFieldController:(pvoItem.highValueCost > 0 ? [SurveyAppDelegate formatDouble:pvoItem.highValueCost withPrecision:2] : @"")
                                   clearOnEdit:NO
                                  withKeyboard:UIKeyboardTypeDecimalPad
                               withPlaceHolder:[NSString stringWithFormat:@"%@ Cost", [AppFunctionality getHighValueDescription]]
                                    withCaller:self
                                   andCallback:@selector(highValueCostEntered:)
                             dismissController:YES
                              andNavController:self.navigationController];
            }
        }
    }
    else if(row == PVO_ITEM_DETAIL_PACKER_INITIALS)
    {
        if ([self forceValidTagForScan])
            return;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *driver = [del.surveyDB getDriverData];
        if(packerInitials.count == 0)
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"You must have initials entered from the main %@ setup screen to select a packer.",
                                          (driver != nil && driver.driverType == PVO_DRIVER_TYPE_PACKER ? @"Packers" : @"Driver")]
                               withTitle:@"No Initials"];
        }
        else
        {
            if (driver != nil && driver.driverType != PVO_DRIVER_TYPE_PACKER)
                pvoItem.packerInitials = nil; //clear em for the driver, in case they select cancel
            grabbingBarcodeImage = YES;
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            [del pushTablePickerController:@"Packers"
                               withObjects:packerInitials
                      withCurrentSelection:pvoItem.packerInitials
                                withCaller:self
                               andCallback:@selector(initialsSelected:)
                           dismissOnSelect:YES
                          andNavController:self.navigationController];
        }
    }
    else if(row == PVO_ITEM_DETAIL_DESCRIPTIVE)
    {
        if ([self forceValidTagForScan])
            return;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
        if(pvoItem.pvoItemID == -1)
            [self handleDuplicateItem];
        else
        {
            if(descriptiveScreen == nil)
            {
                descriptiveScreen = [[SelectObjectController alloc] initWithStyle:UITableViewStylePlain];
            }
                descriptiveScreen.choices = [del.surveyDB getAllPVOItemDescriptions:pvoItem.pvoItemID withCustomerID:del.customerID];
                descriptiveScreen.displayMethod = @selector(listItemDisplay);
                descriptiveScreen.multipleSelection = YES;
                descriptiveScreen.title = @"Descriptive";
                descriptiveScreen.controllerPushed = YES;
                descriptiveScreen.allowsNoSelection = YES;
                descriptiveScreen.delegate = self;
            
            if (pvoItem.cartonContentID > 0)
                [SurveyAppDelegate setupViewForCartonContent:descriptiveScreen.view withTableView:descriptiveScreen.tableView];
            
            //pre-selecting items handled in delegate method
            
            [self.navigationController pushViewController:descriptiveScreen animated:YES];
            
        }
        
    }
    else if(row == PVO_ITEM_DETAIL_ADDITIONAL ||
            row == PVO_ITEM_DETAIL_SECURITY_SEAL)
    {//addtional fields (currently serial/model)
        if ([self forceValidTagForScan])
            return;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
        if(pvoItem.pvoItemID == -1)
            [self handleDuplicateItem];
        else
        {
            if(addController == nil)
                addController = [[PVOItemAdditionalController alloc] initWithStyle:UITableViewStyleGrouped];
            if (self.item == nil)
                self.item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
            
            addController.item = self.item;
            addController.pvoItem = self.pvoItem;
            addController.usingScanner = inventory.usingScanner;
            addController.inventory = inventory;
            addController.enteringSecuritySeal = row == PVO_ITEM_DETAIL_SECURITY_SEAL;

            [self.navigationController pushViewController:addController animated:YES];
        }
    }
    
    else if(row == PVO_ITEM_DETAIL_DELETE)
    {
        if ([SurveyAppDelegate iOS7OrNewer])
        { //currently only runs for iOS 7+
            [self deleteItem:nil];
        }
    }
    else if(row == PVO_ITEM_DETAIL_CRATE_DIMENSION_UNIT_TYPE)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Unit of Measurement"
                          withObjects:dimensionUnitTypes
                 withCurrentSelection:[NSNumber numberWithInt:pvoItem.dimensionUnitType]
                           withCaller:self
                          andCallback:@selector(unitOfMeasurementSelected:)
                     andNavController:self.navigationController];
        
        
        
    }
    else if(row == PVO_ITEM_DETAIL_WEIGHT_TYPE)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Weight Type"
                          withObjects:weightTypes
                 withCurrentSelection:[NSNumber numberWithInt:pvoItem.weightType - 1]
                           withCaller:self
                          andCallback:@selector(weightTypeSelected:)
                     andNavController:self.navigationController];
    }
}

- (IBAction)cubeTextFieldFinished:(UITextField*)textField
{
    double cube = [textField.text doubleValue];
    double weight = cube * self.cubesheet.weightFactor;

    if (pvoItem.weight != weight)
    {
        pvoItem.cube = cube;
        pvoItem.weight = weight;
        [self.tableView reloadData];
    }
}

-(IBAction)weightTypeSelected:(id)sender
{
    int selectedWeightType = [sender intValue];
    pvoItem.weightType = selectedWeightType + 1;
}

-(BOOL)forceValidTagForScan
{
    if (inventory.usingScanner)
    {
        if (pvoItem.lotNumber == nil || pvoItem.itemNumber == nil || [pvoItem.lotNumber length] == 0 || [pvoItem.itemNumber length] == 0)
        {
            [SurveyAppDelegate showAlert:@"A valid tag must be scanned first to continue." withTitle:@"Invalid Tag"];
            return YES;
        }
    }
    return NO;
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
    
    if (row == PVO_ITEM_DETAIL_CUBE)
    {
        BOOL error = NO;
        NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setAllowsFloats:YES];
        NSNumber *newCube = [numFormatter numberFromString:newText];
        if ([newText length] > 0 && newCube == nil)
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@", @"Cube can only contain numbers."] withTitle:@"Invalid Cube"];
            error = YES;
        }
        
        return !error;
    }
    
    return YES;
}

#pragma mark UITextViewDelegate methods

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.tboxComment = textView;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    [self updateValueWithField:textView];
}

#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(alertView.tag == 1)
    {
        if(buttonIndex != [alertView cancelButtonIndex])
        {
            discardChangesAndDelete = YES;
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
    else if(alertView.tag == PVO_ITEM_ALERT_HIGH_VALUE)
    {
        if (pvoItem.cartonContentID > 0)
        {
            if (buttonIndex != [alertView cancelButtonIndex])
            {
                PVOItemDetail *parentItem = [del.surveyDB getPVOItem:[del.surveyDB getPVOItemCartonContent:pvoItem.cartonContentID].pvoItemID];
                parentItem.highValueCost = 1;
                [del.surveyDB updatePVOItem:parentItem];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        else
        {
            //            if(buttonIndex == [alertView cancelButtonIndex])
            //                pvoItem.highValueCost = 0;
            //            else
            //            {
            //                pvoItem.highValueCost = 1;
            //
            //                if(highValueController == nil)
            //                    highValueController = [[PVOHighValueController alloc] initWithNibName:@"PVOHighValueView" bundle:nil];
            //
            //                highValueController.title = @"High Value";
            //                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            //                pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
            //                if(pvoItem.pvoItemID == -1)
            //                    [self handleDuplicateItem];
            //                else
            //                {
            //                    reloadItemUponReturn = YES;
            //                    highValueController.pvoItem = pvoItem;
            //                    [self.navigationController pushViewController:highValueController animated:YES];
            //                }
            //            }
        }
    }
    else if (alertView.tag == PVO_ITEM_ALERT_RELEASED_VAL)
    {
        del.showedReleasedValWarning = YES;
    }
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if(actionSheet.tag == PVO_ITEM_ALERT_DELETE)
        {
            if (buttonIndex == PVO_ITEM_DELETE_VOID)
                [self voidWorkingItem];
            else if (buttonIndex == PVO_ITEM_DELETE_DELETE)
                [self deleteWorkingItem];
        }
        else
        {
            if(buttonIndex == PVO_ITEM_DUPLICATE_IGNORE)
            {
                if(inventory.usingScanner)
                    pvoItem.lotNumber = @"";
                
                pvoItem.itemNumber = @"";
                [self.tableView reloadData];
            }
            else if (buttonIndex == PVO_ITEM_DUPLICATE_GO_TO_ITEM)
            {
                PVOItemDetail *tempItem = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                                            forLotNumber:pvoItem.lotNumber 
                                          withItemNumber:pvoItem.itemNumber];
                
                
                PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
                if(!tempItem.inventoriedAfterSignature && sig != nil)
                    [SurveyAppDelegate showAlert:@"This item was inventoried prior to the customer signing at Origin. You must remove the customer's signature to go to this item." withTitle:@"Completed"];
                else
                {
                    self.pvoItem = tempItem;
                    self.item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
                    self.room = [del.surveyDB getRoom:pvoItem.roomID WithCustomerID:del.customerID];
                    [self setupContinueButton];
                    [self initializeIncludedRows];
                    [self.tableView reloadData];
                    discardChangesAndDelete = NO;
                }
            }
            else if (buttonIndex == PVO_ITEM_DUPLICATE_VOID)
            {
                PVOItemDetail *tempItem = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                                                       forLotNumber:pvoItem.lotNumber
                                                     withItemNumber:pvoItem.itemNumber];
                
                PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
                if(!tempItem.inventoriedAfterSignature && sig != nil)
                    [SurveyAppDelegate showAlert:@"This item was inventoried prior to the customer signing at Origin. You must remove the customer's signature to void this item." withTitle:@"Completed"];
                else
                {
                    self.pvoItem = tempItem;
                    [self voidWorkingItem];
                }
            }
            else if (buttonIndex == PVO_ITEM_DUPLICATE_DELETE)
            {
                discardChangesAndDelete = YES;
                PVOItemDetail *toDelete = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                                                       forLotNumber:pvoItem.lotNumber 
                                                     withItemNumber:pvoItem.itemNumber];
                
                PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
                if(!toDelete.inventoriedAfterSignature && sig != nil)
                    [SurveyAppDelegate showAlert:@"This item was inventoried prior to the customer signing at Origin. You must remove the customer's signature to void this item." withTitle:@"Completed"];
                else
                {
                    [del.surveyDB deletePVOItem:toDelete.pvoItemID withCustomerID:del.customerID];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        }
    }
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
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"ScanAPI is reporting an error: %d",result] withTitle:@"Scanner Error"];
}

-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(id<ISktScanDecodedData>) decodedData{
    
    NSString *data = [[NSString stringWithUTF8String:(const char *)[decodedData getData]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([data length] >= 6)
    {
        NSString *err = nil;
        if (![PVOBarcodeValidation validateBarcode:data outError:&err])
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid Barcode received, %@", err] withTitle:@"Invalid Barcode"];
        else
        {
            pvoItem.lotNumber = [data substringToIndex:[data length]-3];
            pvoItem.itemNumber = [data substringFromIndex:[data length]-3];
            [self.tableView reloadData];
            [self checkForDuplicate];
        }
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters." withTitle:@"Invalid Barcode"];
    
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

#pragma mark - SelectObject delegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    //build array to save
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
    PVOItemDescription *toAdd;
    for (PVOItemDescription *selected in collection) {
        toAdd = [[PVOItemDescription alloc] init];
        toAdd.descriptionCode = selected.descriptionCode;
        toAdd.description = selected.description;
        toAdd.pvoItemID = pvoItem.pvoItemID;
        [selectedItems addObject:toAdd];
    }
    
    [del.surveyDB savePVODescriptions:selectedItems forItem:pvoItem.pvoItemID];
    
}

-(NSMutableArray*)selectObjectControllerPreSelectedItems:(SelectObjectController*)controller
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *selectedItemsInDB = [del.surveyDB getPVOItemDescriptions:pvoItem.pvoItemID withCustomerID:del.customerID];
    NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
    for (PVOItemDescription *pid in selectedItemsInDB) {
        for (PVOItemDescription *avail in controller.choices) {
            if([avail.descriptionCode isEqualToString:pid.descriptionCode])
                [selectedItems addObject:avail];
        }
    }
    
    return selectedItems;
}

#pragma mark - ZBarReaderDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    NSString *barcode = nil;
    for(ZBarSymbol *symbol in results)
    {
        if(barcode != nil)
            barcode = nil;
        else
            barcode = [NSString stringWithString:symbol.data];
        
    }
    
    if(barcode != nil && [barcode length] >= 6)
    {
        NSString *err = nil;
        if (![PVOBarcodeValidation validateBarcode:barcode outError:&err])
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid Barcode received, %@", err] withTitle:@"Invalid Barcode"];
        else
        {
            pvoItem.lotNumber = [barcode substringToIndex:[barcode length]-3];
            pvoItem.itemNumber = [barcode substringFromIndex:[barcode length]-3];
            [self.tableView reloadData];
            [self checkForDuplicate];
        }
    }
    else if(barcode == nil)
        [SurveyAppDelegate showAlert:@"Invalid or more than one barcode received, please re-scan, and be sure to only scan one barcode." withTitle:@"Invalid Barcode"];
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters." withTitle:@"Invalid Barcode"];
    
    grabbingBarcodeImage = NO;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    zbar = nil;
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
        NSString *err = nil;
        if (![PVOBarcodeValidation validateBarcode:data outError:&err])
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid Barcode received, %@", err] withTitle:@"Invalid Barcode"];
        else
        {
            pvoItem.lotNumber = [data substringToIndex:[data length]-3];
            pvoItem.itemNumber = [data substringFromIndex:[data length]-3];
            [self.tableView reloadData];
            [self checkForDuplicate];
        }
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters." withTitle:@"Invalid Barcode"];
    
}

#pragma mark - PVOCartonContentsSummaryControllerDelegate methods

-(void)pvoContentsControllerContinueToNextItem:(PVOCartonContentsSummaryController*)controller
{
    if(delegate != nil && [delegate respondsToSelector:@selector(pvoItemControllerContinueToNextItem:)])
        [delegate pvoItemControllerContinueToNextItem:self];
    else 
    {
        //next item... so jump back to item list, and tap add button...
        PVOItemSummaryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOItemSummaryController class]])
                itemController = view;
        }
        
        itemController.forceLaunchAddPopup = YES;
        //manually calling this method results in the addItem method being called before itemController's ViewDidAppear method which causes a lot of UI errors
        //                [itemController addItem:self];
        [self.navigationController popToViewController:itemController animated:YES];
    }
}

#pragma mark - PVODamageControllerDelegate methods

-(void)pvoDamageControllerContinueToNextItem:(id)controller
{
    if(delegate != nil && [delegate respondsToSelector:@selector(pvoItemControllerContinueToNextItem:)])
        [delegate pvoItemControllerContinueToNextItem:self];
    else 
    {
        //next item... so jump back to item list, and tap add button...
        PVOItemSummaryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOItemSummaryController class]])
                itemController = view;
        }
        
        itemController.forceLaunchAddPopup = YES;
        //manually calling this method results in the addItem method being called before itemController's ViewDidAppear method which causes a lot of UI errors
        //                [itemController addItem:self];
        [self.navigationController popToViewController:itemController animated:YES];
    }
}


#pragma mark - PVOWiretypeControllerDelegate methods

-(NSDictionary*)getWireFrameTypes:(id)controller
{
//        if(indexPath.row == 0)P
//            cell.textLabel.text = @"Car";
//        else if(indexPath.row == 1)
//            cell.textLabel.text = @"Truck";
//        else if(indexPath.row == 2)
//            cell.textLabel.text = @"SUV";
//        else if(indexPath.row == 3)
//            cell.textLabel.text = @"Photo";
    
    if ([item.name containsString:@"Piano"])
    {
        return [[NSDictionary alloc] initWithObjects:@[@"Piano", @"Photo"]
                                             forKeys:@[[NSNumber numberWithInt:5],[NSNumber numberWithInt:4]]];
    }
    else if ([item.name containsString:@"Motorcycle"])
    {
        return [[NSDictionary alloc] initWithObjects:@[@"Motorcycle", @"Photo"]
                                             forKeys:@[[NSNumber numberWithInt:6],[NSNumber numberWithInt:4]]];
    }
}

-(void)saveWireFrameTypeIDForDelegate:(int)selectedWireframeType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    pvoItem.wireframeType = selectedWireframeType;
    [del.surveyDB updatePVOItem:pvoItem];
    
}

#pragma mark - DamageViewHolderDelegate method
-(void)wireframeDamagesChosen:(id)controller
{
    
    PVOWireFrameTypeController *wireframe = [[PVOWireFrameTypeController alloc] initWithStyle:UITableViewStyleGrouped];
    
    //            wireframe.vehicle = veh;
    wireframe.delegate = self;
    wireframe.wireframeItemID = pvoItem.pvoItemID;
    wireframe.isOrigin = true;
    wireframe.isAutoInventory = NO;
    
//    [SurveyAppDelegate setDefaultBackButton:self];
    [self.navigationController pushViewController:wireframe animated:YES];
}


@end
