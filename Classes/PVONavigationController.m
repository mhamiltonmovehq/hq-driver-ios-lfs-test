//
//  PVONavigationController.m
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PVONavigationController.h"
#import "SurveyAppDelegate.h"
#import "PVONavigationCategory.h"
#import "PVODrawer.h"
#import "ArpinPVODrawer.h"
#import "AtlasNetPVODrawer.h"
#import "GetReport.h"
#import "Prefs.h"
#import "ReportOption.h"
#import "AppFunctionality.h"
#import "PVOSync.h"
#import "WebSyncRequest.h"
#import "PVOInventory.h"
#import "PVONavigationListItem.h"

@implementation PVONavigationController

@synthesize cmdPrevious, cmdNext, tableView, cmdDone, currentPage, valInitialsController, servicesController;
@synthesize pvoNote, confirmPaymentController, propertyDamageController, signatureController, landingController;
@synthesize reweighController, weightsController, finalDelDate, deliveryController, inventory, toolbar, selectedItem;
@synthesize syncButton;
@synthesize attachDocController;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        rows = [[NSMutableArray alloc] init];
        self.pvoNote = @"";
        self.finalDelDate = [NSDate date];
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
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    SurveyCustomerSync *custSync = [del.surveyDB getCustomerSync:del.customerID];
//    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
//    ShipmentInfo *info = [del.surveyDB getShipInfo:del.customerID];
//    
//    int vanlineID = info.
    
    [super viewWillAppear:animated];
    
    self.title = @"Shipment Menu";
    
    //get all nav items and sorted categories
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ShipmentInfo *info = [del.surveyDB getShipInfo:del.customerID];
    DriverData *driverData = [del.surveyDB getDriverData];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    allNavItems = [del.pricingDB getPVOListItems:driverData.driverType withSourcedFromServer:info.sourcedFromServer withHaulingAgentCode:driverData.haulingAgent withPricingMode:cust.pricingMode];
    
    categories = [del.pricingDB getPVOCategoriesFromIDs:[allNavItems allKeys]];
    
    self.inventory = [del.surveyDB getPVOData:del.customerID];
    
    [self setNextAndPrevious];
    [self setupCurrentPage];
    
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
    
    @autoreleasepool {
        if (self.printController != nil) {
            [self.printController.view removeFromSuperview];
            self.printController = nil;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


-(IBAction)previous:(id)sender
{
    currentPage = previousPage;
    
    [self setNextAndPrevious];
    [self setupCurrentPage];
}

-(IBAction)next:(id)sender
{
    currentPage = nextPage;
    
    [self setNextAndPrevious];
    [self setupCurrentPage];
}

-(IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)sync:(id)sender
{
    if ([SurveyAppDelegate iOS7OrNewer])
        [self setSyncButtonUnhighlighted];
    
    //begin async sync process...
    if ([AppFunctionality disableSynchronization])
    {
        [SurveyAppDelegate showAlert:@"Online synchronization has been disabled with this version of Mobile Mover." withTitle:@"Sync Disabled"];
    }
    else
    {
        BOOL hasInternet = [SurveyAppDelegate hasInternetConnection:TRUE];
        if (hasInternet)
        {
            UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"This option will save your latest changes to the server.  Would you like to continue?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            v.tag = PVO_ALERT_CONFIRM_SYNC;
            [v show];
        }
        else
        {
            [SurveyAppDelegate showAlert:@"An internet connection is required to save latest changes to server.  Please connect to the internet to proceed."
                               withTitle:@"Internet Required"];
        }
    }
}


-(void)updateProgress:(NSString*)textToAdd
{
    if (_currentSyncMessage == nil)
        _currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    if([_currentSyncMessage isEqualToString:@""])
        [_currentSyncMessage appendString:textToAdd];
    else
        [_currentSyncMessage appendString:[NSString stringWithFormat:@"\r\n%@", textToAdd]];
}

-(NSMutableArray*)getDocsToUpload
{
    if (docsToUpload != nil) docsToUpload = nil;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSMutableArray *retval = [[NSMutableArray alloc] init];
    for (PVONavigationListItem *li in rows) {
        if([li isReportOption] && [li completed] && [li enabled])
        {
            int dataToCheck = [li getPVOChangeDataToCheck];
            
            //make sure it is waiting for upload
            if([del.surveyDB pvoCheckDataIsDirty:dataToCheck forCustomer:del.customerID])
                [retval addObject:li];
        }
    }
    return retval;
}

-(void)syncCompleted
{
    NSString *syncTitle;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.pricingDB vanline] == ARPIN){
        syncTitle = @"SAVE TO ARPIN";
    } else {
        syncTitle = @"Save To Server";
    }

#ifdef ATLASNET
    syncTitle = @"Save To Atlas";
#endif

    
    [uploadProgress removeFromSuperview];
    
    if ([AppFunctionality enableDocumentUploadWithSaveToServer])
    {
        SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
        uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Uploading Reports"];

        PreviewPDFController *p = [[PreviewPDFController alloc] init];
        p.delegate = self;
        p.allDirtyReportsFinishedUploading = @selector(dirtyUploadFinished);
        p.customers = [NSMutableArray arrayWithObject:[del.surveyDB getCustomer:del.customerID]];
        p.uploadingDirtyReports = YES;
        [p uploadAllDirtyReports];
    }
    else
    {
        [SurveyAppDelegate showAlert:_currentSyncMessage withTitle:syncTitle];
        //[currentSyncMessage release];
        [self.tableView reloadData];
    }
}

-(void)dirtyUploadFinished
{
    NSString *syncTitle;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.pricingDB vanline] == ARPIN){
        syncTitle = @"SAVE TO ARPIN";
    } else {
        syncTitle = @"Save To Server";
    }
    
#ifdef ATLASNET
    syncTitle = @"Save To Atlas";
#endif
    
    if (_currentSyncMessage != nil && ![_currentSyncMessage isEqualToString:@""])
        [SurveyAppDelegate showAlert:_currentSyncMessage withTitle:syncTitle];
    
    [self.tableView reloadData];
    
    [uploadProgress removeFromSuperview];
    
    [self.tableView reloadData];
    
    return;
}

-(void)beginDocUpload
{
    //get all available documents that can be uploaded, generate and upload HTML reports
    uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Uploading Reports"];
    
    docsToUpload = [self getDocsToUpload];
    [self uploadNextDoc];
}

-(void)startServerSync
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanline = [del.pricingDB vanline];

    [del.surveyDB removeAllCustomerSyncFlags];

    NSString *syncTitle;
    if (vanline == ARPIN) {
        syncTitle = @"Saving To Arpin";
    } else if (vanline == ATLAS) {
        syncTitle = @"Saving To Atlas";
    } else {
        syncTitle = @"Saving To Server";
    }
    uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:syncTitle andProgressBar:YES];
    
    PVOSync *sync = [[PVOSync alloc] init];
    
    SurveyCustomerSync *custSync = [del.surveyDB getCustomerSync:del.customerID];
    custSync.syncToPVO = YES;
    [del.surveyDB updateCustomerSync:custSync];
    
    sync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORIES;
    
    sync.updateWindow = self;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncCompleted);
    
    sync.delegate = self;
    
    _currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    [del.operationQueue addOperation:sync];
}

-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete
{
    [self syncProgressUpdate:sync withMessage:message andPercentComplete:percentComplete animated:YES];
}

-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete animated:(BOOL)animated
{
    [uploadProgress updateProgressBar:percentComplete animated:animated];
}

-(void)singleValueEntered:(NSString*)newValue
{
    if(selectedItem.navItemID == PVO_ENTER_TARE_WEIGHT)
        tareWeight = [newValue intValue];
    else if(selectedItem.navItemID == PVO_GROSS_WEIGHT)
        grossWeight = [newValue intValue];
}

-(void)doneEditingNote:(NSString*)newValue
{
    self.pvoNote = newValue;
}

-(void)setNextAndPrevious
{
    if([categories count] < 2)
    {
        if(toolbar.superview != nil)
        {
            CGRect frame = self.tableView.frame;
            frame.size.height += toolbar.frame.size.height;
            tableView.frame = frame;
            [toolbar removeFromSuperview];
        }
        /*NSMutableArray *arry = [NSMutableArray arrayWithArray:[toolbar items]];
         if([arry count] > 1)
         {
         [arry removeObject:cmdNext];
         [arry removeObject:cmdPrevious];
         [toolbar setItems:arry animated:NO];
         }*/
    }
    else
    {
        if (toolbar.superview == nil)
        { //add it back to view
            CGRect frame = self.tableView.frame;
            frame.size.height -= toolbar.frame.size.height;
            tableView.frame = frame;
            [self.view addSubview:toolbar];
        }
        
        NSString *strPrev = @"Previous";
        NSString *strNext = @"Next";
        
        cmdNext.enabled = YES;
        cmdPrevious.enabled = YES;
        
        
        BOOL reloadTBItems = FALSE;
        NSMutableArray *tbItems = [toolbar.items mutableCopy];
        if (![tbItems containsObject:cmdNext]) {
            [tbItems insertObject:cmdNext atIndex:2];
            reloadTBItems = TRUE;
        }
        if (![tbItems containsObject:cmdPrevious]) {
            [tbItems insertObject:cmdPrevious atIndex:0];
            reloadTBItems = TRUE;
        }
        if (reloadTBItems)
            [toolbar setItems:tbItems animated:NO];
        
        previousPage = currentPage - 1;
        nextPage = currentPage + 1;
        
        PVONavigationCategory *catPrev = nil;
        if(previousPage > 0)
            catPrev = [categories objectAtIndex:previousPage-1];
        
        PVONavigationCategory *catNext = nil;
        if(nextPage <= [categories count])
            catNext = [categories objectAtIndex:nextPage-1];
        
        if(catPrev != nil)
            strPrev = catPrev.description;
        else {
            cmdPrevious.enabled = NO;
            tbItems = [toolbar.items mutableCopy];
            [tbItems removeObject:cmdPrevious];
            [toolbar setItems:tbItems animated:NO];
        }
        
        if(catNext != nil)
            strNext = catNext.description;
        else {
            cmdNext.enabled = NO;
            tbItems = [toolbar.items mutableCopy];
            [tbItems removeObject:cmdNext];
            [toolbar setItems:tbItems animated:NO];
        }
        
        cmdPrevious.title = strPrev;
        cmdNext.title = strNext;
    }
}

-(void)loadPrintScreen
{
    //This report should be signed in the delivery screen when all items are delivered.
    BOOL hideSignButton = selectedItem.navItemID == PVO_P_DELIVER_ALL_CONFIRM;
    self.printController = [[PreviewPDFController alloc] initWithNibName:@"PreviewPDF" bundle:nil];
    self.printController.pvoItem = selectedItem;
    self.printController.navOptionText = selectedItem.display;
    self.printController.useDisconnectedReports = useDisconnectedReports;
    self.printController.title = @"Report Preview";
    self.printController.hideActionsOptions = NO;
    self.printController.noSignatureAllowed = hideSignButton;
    self.printController.pdfPath = nil;

    if(selectedItem.reportTypeID == 3066)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        // 1850 as Dest
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = IN_STORAGE;
        [del.surveyDB updateShipInfo:info];
    }
    else if(selectedItem.reportTypeID == 3073)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        // 1850 as Dest
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = IN_TRANSIT;
        [del.surveyDB updateShipInfo:info];
    }
    
    [self.navigationController pushViewController:self.printController animated:YES];
}

-(void)loadSignature:(NSString*)displayText
{
    if(signatureController == nil)
        signatureController = [[PVOSignatureController alloc] initWithNibName:@"PVOSignatureView" bundle:nil displayText:displayText];
    else
        signatureController.tboxDescription.text = displayText;
    signatureController.delegate = self;
    [self.navigationController pushViewController:signatureController animated:YES];
}

-(void)setupCurrentPage
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(currentPage == PVO_DONE)
    {
        [self done:nil];
        return;
    }
    
    [rows removeAllObjects];
    
    PVONavigationCategory *category = [categories objectAtIndex:currentPage-1];
    
    PVONavigationListItem *crew = [[PVONavigationListItem alloc] init];
    crew.navItemID = PVO_CREW;
    crew.display = @"Crew";
    crew.reportNoteType = -1;
    crew.reportTypeID = -1;
    
    PVONavigationListItem *actions = [[PVONavigationListItem alloc] init];
    actions.navItemID = PVO_ACTIONS;
    actions.display = category.categoryID == 1 ? @"Origin Actions" : @"Destination Actions";
    actions.reportNoteType = -1;
    actions.reportTypeID = -1;
    actions.itemCategory = category.categoryID;
    
    PVONavigationListItem *checklist = [[PVONavigationListItem alloc] init];
    checklist.navItemID = PVO_CHECKLIST;
    checklist.display = @"Checklist";
    checklist.reportNoteType = -1;
    checklist.reportTypeID = -1;
    checklist.itemCategory = category.categoryID;
    
    [rows addObject:crew];
    [rows addObject:actions];
    [rows addObject:checklist];
    
    
    for (NSNumber* cat in allNavItems)
    {
        _checklistCompleted = [del.surveyDB areAllQuestionsAnsweredWithCustomerID:del.customerID withVehicleID:[cat intValue]];
        
        if (!_checklistCompleted)
        {
            for (PVONavigationListItem* item in allNavItems[cat])
            {
                item.enabledOverride = -1;
            }
        }
    }
    
    [rows addObjectsFromArray:[allNavItems objectForKey:[NSNumber numberWithInt:category.categoryID]]];
    
    //set up all completed, enabled, required... should be driven from DB?
    //no need for enabled, already driven from DB
    //logic need for every Item id tho to determine if it is completed.  required?
    
    /*PVOSignature *sig;
    
    for (PVONavigationListItem *item in rows) 
    {
        switch (item.navItemID) 
        {
            case PVO_ENTER_TARE_WEIGHT:
                item.completed = tareWeight > 0;
                break;
            case PVO_INVENTORY:
            case PVO_P_INV_CARTON_DETAIL:
                sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
                if(item.navItemID == PVO_INVENTORY)
                    item.completed = inventory.inventoryCompleted || sig != nil;
                else
                    item.completed = sig != nil;
                [sig release];
                break;
            case PVO_GENERAL_COMMENTS:
                item.completed = [pvoNote length] > 0;
                break;
            case PVO_PAYMENT_METHOD:
                item.completed = confirmPaymentController != nil && confirmPaymentController.paymentMethod != 0;
                break;
            case PVO_ORG_PROPERTY_DAMAGE:
                item.completed = propertyDamageController != nil;
                break;
            case PVO_DELIVER_SHIPMENT:
            case PVO_P_DEL_EXCP:
                sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
                if(item.navItemID == PVO_DELIVER_SHIPMENT)
                    item.completed = inventory.deliveryCompleted || sig != nil;
                else
                    item.completed = sig != nil;
                [sig release];
                break;
            default:
                item.completed = NO;
                break;
        }
    }*/
    
    [self.tableView reloadData];
}

-(void)showPickerForInventoryReportTypes
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    imageDisplayTypes = [NSMutableDictionary dictionary];
    
    [imageDisplayTypes setObject:@"None" forKey:[NSNumber numberWithInt:IMAGES_NONE]];
    [imageDisplayTypes setObject:@"Inline Images" forKey:[NSNumber numberWithInt:IMAGES_INLINE]];
    [imageDisplayTypes setObject:@"Image Attachment" forKey:[NSNumber numberWithInt:IMAGES_ATTACHMENT]];
        
    [del popTablePickerController:@"Image Display"
                      withObjects:imageDisplayTypes
             withCurrentSelection:nil
                       withCaller:self
                      andCallback:@selector(imageDisplayTypeSeleceted:)
                  dismissOnSelect:YES
                andViewController:self];
}

-(void)imageDisplayTypeSeleceted:(id)sender
{
    self.selectedItem.imageDisplayType = [sender intValue];
    [self continueToSelectedItem];
}

-(BOOL)stopBecause113OrAboveInvReportOffline {
    // Temporary fix to force HTML reports for 11.3+ devices on inventory reports (OT 20803)
    if((selectedItem.reportTypeID == 1 || selectedItem.reportTypeID == 6) && ![SurveyAppDelegate hasInternetConnection:TRUE] && [[[UIDevice currentDevice] systemVersion] compare:@"11.3" options:NSNumericSearch] != NSOrderedAscending) {
        [SurveyAppDelegate showAlert:@"Disconnected reports are not available for this option.  You must connect to the Internet to run this report."
                           withTitle:@"Disconnected Not Available"];
        return TRUE;
    } else {
        return FALSE;
    }
}

-(void)continueToSelectedItem
{
    if([self stopBecause113OrAboveInvReportOffline]) {
        return;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL hasHTMLReports, isForceDisc, doesntHaveOffline;
    NSString *appName = @"Mobile Mover";
#ifdef ATLASNET
    appName = @"AtlasNet";
#endif
    
    
    if(selectedItem.reportTypeID != -1 && selectedItem.navItemID != PVO_AUTO_INVENTORY_REPORT_ORIG && selectedItem.navItemID != PVO_AUTO_INVENTORY_REPORT_DEST)
    {
        hasHTMLReports = [del.surveyDB htmlReportExistsForReportType:selectedItem.reportTypeID];
        isForceDisc = ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcedisc"].location != NSNotFound);
        doesntHaveOffline = [self isReportAndNoDisconnected:selectedItem.reportTypeID];
        
        if (!hasHTMLReports && doesntHaveOffline && (isForceDisc || ![SurveyAppDelegate hasInternetConnection:TRUE]))
            [SurveyAppDelegate showAlert:@"Disconnected reports are not available for this option.  You must connect to the Internet to run this report."
                               withTitle:@"Disconnected Not Available"];
        else
            [self loadPrintScreen];
        
        return;
    }
    
    if([del.pricingDB pvoNavItemHasReportSections:selectedItem.navItemID])
    {
        //this is a dynamic report entry record
        if(dynamicReportSections == nil)
            dynamicReportSections = [[PVODynamicReportSectionsController alloc] initWithStyle:UITableViewStyleGrouped];
        dynamicReportSections.navItem = selectedItem;
        
        [self.navigationController pushViewController:dynamicReportSections animated:YES];
        
        return;
    }
    
    switch (selectedItem.navItemID) {
        case PVO_DOV_DETAILS:
            break;
        case PVO_BOL_DETAILS:
            break;
        case PVO_INVENTORY:
            //landing first...
            if(landingController == nil)
                landingController = [[PVOLandingController alloc] initWithStyle:UITableViewStyleGrouped];
            landingController.title = @"Inventory";
            
            //landingController.currentLoad = pvoLoad;
            
            [self.navigationController pushViewController:landingController animated:YES];
            break;
        case PVO_CONFIRM_VALUATION:
            if(valInitialsController == nil)
                valInitialsController = [[PVOValInitialController alloc] initWithNibName:@"PVOValInitialView" bundle:nil];
            valInitialsController.delegate = self;
            valInitialsController.title = @"Valuation";
            [self.navigationController pushViewController:valInitialsController animated:YES];
            break;
        case PVO_ORIGIN_SERVICES:
        case PVO_DEST_SERVICES:
            if(servicesController == nil)
                servicesController = [[PVOServicesController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:servicesController animated:YES];
            break;
        case PVO_PAYMENT_METHOD:
            if(confirmPaymentController == nil)
                confirmPaymentController = [[PVOConfirmPaymentController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:confirmPaymentController animated:YES];
            break;
        case PVO_ORG_PROPERTY_DAMAGE:
        case PVO_DEST_PROPERTY_DAMAGE:
            if(propertyDamageController == nil)
                propertyDamageController = [[PVODamageController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:propertyDamageController animated:YES];
            break;
        case PVO_GENERAL_COMMENTS:
            [del pushNoteViewController:pvoNote 
                           withKeyboard:UIKeyboardTypeASCIICapable 
                           withNavTitle:@"General Comments" 
                        withDescription:@"General Comments"
                             withCaller:self 
                            andCallback:@selector(doneEditingNote:) 
                      dismissController:YES
                               noteType:NOTE_TYPE_NONE];
            break;
        case PVO_ENTER_TARE_WEIGHT:
            [del pushSingleFieldController:tareWeight == 0 ? @"" : [NSString stringWithFormat:@"%d", tareWeight]
                               clearOnEdit:NO 
                              withKeyboard:UIKeyboardTypeNumberPad 
                           withPlaceHolder:@"Tare Weight" 
                                withCaller:self 
                               andCallback:@selector(singleValueEntered:) 
                         dismissController:YES 
                          andNavController:self.navigationController];
            break;
        case PVO_GROSS_WEIGHT:
            [del pushSingleFieldController:grossWeight == 0 ? @"" : [NSString stringWithFormat:@"%d", grossWeight]
                               clearOnEdit:NO 
                              withKeyboard:UIKeyboardTypeNumberPad 
                           withPlaceHolder:@"Gross Weight" 
                                withCaller:self 
                               andCallback:@selector(singleValueEntered:) 
                         dismissController:YES 
                          andNavController:self.navigationController];
            break;
        case PVO_REWEIGH:
            if(reweighController == nil)
                reweighController = [[PVOReweighController alloc] initWithStyle:UITableViewStyleGrouped];
            reweighController.delegate = self;
            [self.navigationController pushViewController:reweighController animated:YES];
            break;
        case PVO_FINAL_DEL_DATE:
            [del pushSingleDateViewController:self.finalDelDate 
                                 withNavTitle:@"Deliver Date" 
                                   withCaller:self 
                                  andCallback:@selector(dateEntered:withIgnore:) 
                             andNavController:self.navigationController];
            break;
        case PVO_DELIVER_SHIPMENT:
            if(deliveryController == nil)
                deliveryController = [[PVODeliverySummaryController alloc] initWithStyle:UITableViewStyleGrouped];
            deliveryController.title = @"Deliveries";
            [self.navigationController pushViewController:deliveryController animated:YES];
            break;
        case PVO_WEIGHT_TICKET:
            if(weightsController == nil)
                weightsController = [[PVOWeightTicketSummaryController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:weightsController animated:YES];
            break;
        case PVO_UPLOAD_ORG_DOCS:
        case PVO_UPLOAD_DEST_DOCS:
            //upload the documents...
            uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Uploading Reports"];
            _currentSyncMessage = [[NSMutableString alloc] init];
            [self uploadNextDoc];
            break;
        case PVO_ATTACH_DOCUMENT_ORG:
        case PVO_ATTACH_DOCUMENT_DEST:
            if(self.attachDocController == nil)
                self.attachDocController = [[PVOAttachDocController alloc] initWithNibName:@"PVOAttachDocView" bundle:nil];
            attachDocController.caller = self.view;
            attachDocController.viewController = self;
            attachDocController.navItemID = selectedItem.navItemID;
            attachDocController.category = [[categories objectAtIndex:(currentPage-1)] description];
            
            [attachDocController promptForDocument];
            break;
        case PVO_AUTO_INVENTORY_ORIG:
        case PVO_AUTO_INVENTORY_DEST:
            if(autoInventoryController == nil)
                autoInventoryController = [[PVOAutoInventoryController alloc] initWithStyle:UITableViewStyleGrouped];
            
            autoInventoryController.isOrigin = selectedItem.navItemID == PVO_AUTO_INVENTORY_ORIG;
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:autoInventoryController animated:YES];
            break;
        case PVO_AUTO_INVENTORY_REPORT_ORIG:
        case PVO_AUTO_INVENTORY_REPORT_DEST:
            if(autoInventorySignController == nil)
                autoInventorySignController = [[PVOAutoInventorySignController alloc] initWithStyle:UITableViewStyleGrouped];
            
            autoInventorySignController.isOrigin = selectedItem.navItemID == PVO_AUTO_INVENTORY_REPORT_ORIG;
            autoInventorySignController.selectedItem = selectedItem;
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:autoInventorySignController animated:YES];
            break;
        case PVO_BULKY_INVENTORY_ORIG:
        case PVO_BULKY_INVENTORY_DEST:

            if(bulkyInventoryController == nil)
                bulkyInventoryController = [[PVOBulkyInventoryController alloc] initWithStyle:UITableViewStyleGrouped];
            
            bulkyInventoryController.isOrigin = selectedItem.navItemID == PVO_BULKY_INVENTORY_ORIG;
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:bulkyInventoryController animated:YES];
            break;
        case PVO_CREW:
            
            if(crewController == nil)
                crewController = [[CrewViewController alloc] init];
            
            crewController.title = @"Crew";
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:crewController animated:YES];
            
            break;
        case PVO_ACTIONS:
            
            if(actionsController == nil)
                actionsController = [[PVOActionItemsController alloc] initWithStyle:UITableViewStyleGrouped];
            
            actionsController.title = @"Actions";
            
            actionsController.isOrigin = selectedItem.itemCategory == 1;
            
            actionsController.actionTimes = [del.surveyDB getPVOActionTime:del.customerID];
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:actionsController animated:YES];
            
            break;
        case PVO_CHECKLIST:
            
            if(checklistController == nil)
                checklistController = [[PVOChecklistController alloc] initWithStyle:UITableViewStyleGrouped];
            
            checklistController.vehicle = [[PVOVehicle alloc] init];
            checklistController.vehicle.vehicleID = selectedItem.itemCategory;
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:checklistController animated:YES];
            break;
        default:
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"This functionality is not supported with this version of %@. Please check the App Store for any available updates.", appName]
                               withTitle:@"Update Required"];
            [tableView reloadData];
            break;
    }
}

//-(IBAction)uiCatchUp:(id)timer
//{
//    [self startServerSync];
//}

-(void)uploadNextDoc
{
    if([docsToUpload count] == 0)
    {
        NSString *syncTitle;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if([del.pricingDB vanline] == ARPIN){
            syncTitle = @"SAVE TO ARPIN";
        } else {
            syncTitle = @"Save To Server";
        }
#ifdef ATLASNET
        syncTitle = @"Save To Atlas";
#endif
        
        if (_currentSyncMessage != nil && ![_currentSyncMessage isEqualToString:@""])
            [SurveyAppDelegate showAlert:_currentSyncMessage withTitle:syncTitle];
        
        [self.tableView reloadData];

        [uploadProgress removeFromSuperview];
        
        [self.tableView reloadData];
        
        return;
    }
    
    PVONavigationListItem* navItem = [docsToUpload objectAtIndex:0];
    
    if (navItem.reportTypeID <= 0)
    {
        [docsToUpload removeObjectAtIndex:0];
        [self uploadNextDoc];
    }
    
    [self beginGatheringReport:navItem];
    return;
    
}

-(void)beginGatheringReport:(PVONavigationListItem*)currentNavItem
{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL generateReportWithOption = FALSE;
    
    WebSyncRequest *req = [[WebSyncRequest alloc] init];
    req.type = WEB_REPORTS;
    req.functionName = @"GetPVOReport";
//    req.serverAddress = @"print.moverdocs.com";
    req.serverAddress = @"homesafe-docs.movehq.com";

    
    req.pitsDir = @"PVOReports";
    
    if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"webdir:"].location != NSNotFound)
    {//override the default virtual directory
        NSRange addpre = [[Prefs betaPassword] rangeOfString:@"webdir:"];
        req.pitsDir = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
        addpre = [req.pitsDir rangeOfString:@" "];
        if (addpre.location != NSNotFound)
            req.pitsDir = [req.pitsDir substringToIndex:addpre.location];
    }
    
    if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"md:"].location != NSNotFound)
    {
        NSRange addpre = [[Prefs betaPassword] rangeOfString:@"md:"];
        req.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
        addpre = [req.serverAddress rangeOfString:@" "];
        if (addpre.location != NSNotFound)
            req.serverAddress = [req.serverAddress substringToIndex:addpre.location];
    }
    
    NSString *dest;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"%d", [del.pricingDB vanline]] forKey:@"vanLineId"];
    [dict setObject:[NSString stringWithFormat:@"%d", currentNavItem.reportTypeID] forKey:@"reportID"];
    if (([Prefs reportsPassword] == nil || [[Prefs reportsPassword] length] == 0) && [AppFunctionality defaultReportingServiceCustomReportPass] != nil)
        [dict setObject:[AppFunctionality defaultReportingServiceCustomReportPass] forKey:@"customReportsPassword"];
    else
        [dict setObject:[Prefs reportsPassword] == nil ? @"" : [Prefs reportsPassword] forKey:@"customReportsPassword"];
    
    ReportOption *opt = nil;
    if([SurveyAppDelegate hasInternetConnection:TRUE] && [req getData:&dest withArguments:dict needsDecoded:YES withSSL:YES])
    {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[dest dataUsingEncoding:NSUTF8StringEncoding]];
        ReportOptionParser *xmlParser = [[ReportOptionParser alloc] init];
        parser.delegate = xmlParser;
        [parser parse];
        
        //now I have the option, generate the report...
        if([xmlParser.entries count] > 0)
        {
            opt = [xmlParser.entries objectAtIndex:0];
            opt.reportLocation = xmlParser.address;
            opt.reportTypeID = currentNavItem.reportTypeID;
            
            generateReportWithOption = TRUE;
        }
    }
    else
    {
        //need to pull the reportID for the type
        ReportOption *html = [del.surveyDB getHTMLReportDataForReportType:currentNavItem.reportTypeID];
        if (html != nil && [del.surveyDB htmlReportExists:html])
        {//found file previously download
            opt = html;
            opt.htmlSupported = YES;
        }
    }
    
    
    if (opt.htmlSupported)
    {//connected, check the html version
        generateReportWithOption = NO;
        //i dont think we should download updated reports right here because its not what the customer signed
        [self loadHTMLReport:opt withPVONavItem:currentNavItem];
    }
    
    if(generateReportWithOption)
    {
        //start the thread on the operation queue
        GetReport *reportObject = [[GetReport alloc] init];
        reportObject.emailReport = NO;
        reportObject.caller = self;
        reportObject.updateCallback = @selector(updateFromGetReport:);
        reportObject.option = opt;
        [del.operationQueue addOperation:reportObject];
    }
}

-(void)loadHTMLReport:(ReportOption*)currentOption withPVONavItem:(PVONavigationListItem*)currentNavItem
{
    //get the latest info for the report from the database
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ReportOption *option = [del.surveyDB getHTMLReportDataForReportType:currentNavItem.reportTypeID];
    
    htmlGenerator = [[HTMLReportGenerator alloc] init];
    htmlGenerator.delegate = self;
    htmlGenerator.pvoReportTypeID = currentNavItem.reportTypeID;
    htmlGenerator.pvoReportID = option.reportID;
    htmlGenerator.pageSize = option.pageSize;
    
    [htmlGenerator generateReportWithZipBundle:option.htmlBundleLocation
                                containingHTML:option.htmlTargetFile
                                   forCustomer:del.customerID
                               forPVONavItemID:currentNavItem.navItemID
                          withImageDisplayType:-1];
    
}


-(void) uploadDocGenerated:(NSString*)update
{
    
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	if(update != nil &&![update isEqualToString:@"start printing disconnected"] &&
	   ![update isEqualToString:@"Successfully saved file."])
	{
        [SurveyAppDelegate showAlert:update withTitle:@"Upload Generate Error"];
        [uploadProgress removeFromSuperview];
    }
    else
    {
        PVONavigationListItem *navItem = [docsToUpload objectAtIndex:0];
//        [uploader release];
        //im showing my own loading screen.
        uploader = [[PVOUploadReportView alloc] init];
        uploader.suppressLoadingScreen = YES;
        uploader.delegate = self;
        uploader.updateCallback = @selector(updateProgress:);
        
        int additionalParamInfo = navItem.navItemID;
        [uploader uploadDocument:navItem.reportTypeID withAdditionalInfo:additionalParamInfo];
    }
    
}

-(void)askToContinue:(NSString*)continueText
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
                                                    message:continueText
                                                   delegate:self 
                                          cancelButtonTitle:@"No" 
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [super viewWillDisappear:animated];
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

-(void)dateEntered:(NSDate*)newValue withIgnore:(NSDate*)date2
{
    self.finalDelDate = newValue;
}

-(BOOL)isReportAndNoDisconnected:(int)reportTypeID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (reportTypeID > 0)
    {
        //chekc for an HTML report record, if it exists, return false, since we have an "offline" report
        ReportOption* htmlReportOption = nil;
        @try {
            htmlReportOption = [del.surveyDB getHTMLReportDataForReportType:reportTypeID];
            if (htmlReportOption != nil && htmlReportOption.reportID > 0)
            {
                //check that the file is found on the device storage
                if ([del.surveyDB htmlReportExists:htmlReportOption])
                    return NO;
            }
        }
        @finally {
            if (htmlReportOption != nil)
                htmlReportOption = nil;
        }
    }
    
    id disconnectedDrawer = nil;
    switch ([del.pricingDB vanline]) {
        case ARPIN:
            disconnectedDrawer = [[ArpinPVODrawer alloc] init];
            break;
        case ATLAS:
            disconnectedDrawer = [[AtlasNetPVODrawer alloc] init];
            break;
        default:
            disconnectedDrawer = [[PVODrawer alloc] init];
            break;
    }
        
    BOOL isReportAndNoDisconnected = reportTypeID > 0;
    if(isReportAndNoDisconnected)
    {
        NSDictionary *items = [disconnectedDrawer availableReports];
        for (NSNumber *num in [items allKeys]) {
            if([num intValue] == reportTypeID)
                isReportAndNoDisconnected = FALSE;
        }
    }
    
    return isReportAndNoDisconnected;
}

-(BOOL)promptToRemoveSignatures
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (selectedItem.navItemID == PVO_BOL_DETAILS)
    {
        //Don't prompt to remove the signatures for BOL details. BOL details is tied to two separate reports. its possible the user would go into BOL details > general details > then run and sign the Origin BOL, then later need to go back into BOL detail > sit details.
        return false;
    }
    
    BOOL removeSigs = NO;
    PVOSignature *sig;
    for (NSString *sigid in [selectedItem.signatureIDs componentsSeparatedByString:@","]) {
        sig = [del.surveyDB getPVOSignature:del.customerID forImageType:[sigid intValue]];
        if(sig != nil)
        {
            removeSigs = YES;
        }
    }
    
    if(removeSigs)
    {
        [self askToContinue:@"A signature for this report exists.  If you choose to continue, the signature for this report will be removed.  Would you like to continue?"];
        return TRUE;
    }
    else
        return false;
}

-(BOOL)promptForConfirmationDetails
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //check to see if there's any confirmation dialog required in the pricing databases.
    if([del.pricingDB pvoNavItemHasConfirmation:selectedItem.navItemID])
    {
        PVOConfirmationDetails *details = [del.pricingDB getPVOConfirmationDetails:selectedItem.navItemID];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
                                                        message:details.confirmationText
                                                       delegate:self
                                              cancelButtonTitle:details.cancelButtonText
                                              otherButtonTitles:details.continueButtonText, nil];
        alert.tag = PVO_ALERT_CONFIRMATION_DETAIL;
        [alert show];

        return YES;
    }
    else
        return NO;
}

-(BOOL)getAutoInventorySignatures
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *vehicles = [del.surveyDB getAllVehicles:del.customerID];
    
    if (vehicles == nil || [vehicles count] == 0)
    {
        
    }
    
    [del popTablePickerController:@"Image Display"
                      withObjects:imageDisplayTypes
             withCurrentSelection:nil
                       withCaller:self
                      andCallback:@selector(imageDisplayTypeSeleceted:)
                  dismissOnSelect:YES
                andViewController:self];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *date = [cust getFormattedLastSaveToServerDate:YES];
    
    if(date != nil && date.length > 0) {
        return 65;
    } else {
        return 50;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *regname = nil;
    ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
    regname = [NSString stringWithFormat:@"Order: %@\r\n%@ %@", inf.orderNumber, cust.firstName, cust.lastName];
    NSString *date = [cust getFormattedLastSaveToServerDate:YES];
    
    UIView *syncView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    [syncView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *reglabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 200, 50)];
    reglabel.numberOfLines = 2;
    [reglabel setBackgroundColor:[UIColor clearColor]];
    reglabel.text = regname;
    reglabel.font = [UIFont boldSystemFontOfSize:18];
    reglabel.textColor = [UIColor darkGrayColor];
    
    [syncView addSubview:reglabel];
    
    // OT 2582 - last sync date feature
    if(date != nil && date.length > 0) {
        UILabel *lastSaveDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 310, 15)];
        lastSaveDateLabel.numberOfLines = 1;
        [lastSaveDateLabel setBackgroundColor:[UIColor clearColor]];
        lastSaveDateLabel.text = date;
        lastSaveDateLabel.font = [UIFont systemFontOfSize:11];
        lastSaveDateLabel.textColor = [UIColor darkGrayColor];
        lastSaveDateLabel.textAlignment = NSTextAlignmentRight;
        [syncView addSubview:lastSaveDateLabel];
    }
    
    syncButton = [[UIButton alloc] initWithFrame:CGRectMake(230, 3, 80, 44)];
    
    [syncButton addTarget:self action:@selector(sync:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([SurveyAppDelegate iOS7OrNewer])
    {
        [syncButton.layer setCornerRadius:4.f];
        [syncButton.layer setBorderWidth:1.5f];
        [syncButton.layer setBorderColor:[[SurveyAppDelegate getiOSBlueButtonColor] CGColor]];
        [syncButton setBackgroundColor:[SurveyAppDelegate getiOSBlueButtonColor]];
        [syncButton addTarget:self action:@selector(setSyncButtonHighlighted) forControlEvents:UIControlEventTouchDown];
        [syncButton addTarget:self action:@selector(setSyncButtonUnhighlighted) forControlEvents:UIControlEventTouchDragExit];
        [syncButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else
    {
        [syncButton setBackgroundImage:[[UIImage imageNamed:@"blueButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.]
                              forState:UIControlStateNormal];
        [syncButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
    syncButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    syncButton.titleLabel.numberOfLines = 2;
    syncButton.titleLabel.textAlignment = NSTextAlignmentCenter;
#ifdef ATLASNET
    [syncButton setTitle:@"Save To\r\nAtlas" forState:UIControlStateNormal];
#else
    if([del.pricingDB vanline] == ARPIN){
        [syncButton setTitle:@"SAVE TO\r\nARPIN" forState:UIControlStateNormal];
    } else {
        [syncButton setTitle:@"Save To\r\nServer" forState:UIControlStateNormal];
    }
#endif
    if ([AppFunctionality enableSaveToServer])
    {
        [syncView addSubview:syncButton];
    }
    
    //[syncButton release];
    
    return syncView;
}

-(void)setSyncButtonHighlighted
{
    syncButton.alpha = 0.3f;
}

-(void)setSyncButtonUnhighlighted
{
    syncButton.alpha = 1.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    PVONavigationListItem *item = [rows objectAtIndex:[indexPath row]];
    
//    int reportType = [self getPrintDocTypeForRow:item.navItemID];
    
    
    static NSString *BasicCellIdentifier = @"Cell";
    static NSString *SubHeaderCellIdentifier = @"SubHeaderCell";
    
    UITableViewCell *cell = nil;
    
    if([self isReportAndNoDisconnected:item.reportTypeID])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SubHeaderCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SubHeaderCellIdentifier];
        }
        
        cell.detailTextLabel.text = @"Report Option only available online.";
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicCellIdentifier];
        }
    }
    
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.text = item.display;
    
    //first check for existence of a global upload docs option.
    //if it exists, check if it is a report, then show clear/check/upload
    //if not, show old disclosure/check
    
    //Make sure the user is able to have doc progress, and make sure its enabled for the report
#if defined(ATLASNET)
    BOOL showReportProgress = [item enableUploadFromShipmentMenu] && [AppFunctionality enableDocumentUploadWithSaveToServer];
    //BOOL showReportProgress = YES;
#else
    BOOL showReportProgress = [item enableUploadFromShipmentMenu] && [AppFunctionality enableDocumentUploadWithSaveToServer];
#endif
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(showReportProgress && item.completed && item.enabled)
    {
        //if it is not uploaded show upload icon, uploaded and signed show check
        int data = [item getPVOChangeDataToCheck];
        if([del.surveyDB pvoCheckDataIsDirty:data forCustomer:del.customerID])
        {
            //show upload icon
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upload_accessory.png"]];
        }
        else
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        if(item.enabled){
            cell.accessoryType = [item completed] ?
            UITableViewCellAccessoryCheckmark :
            UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    
    cell.textLabel.textColor = item.enabled ? [UIColor blackColor] : [UIColor grayColor];
    
    
    if(item.navItemID == PVO_UPLOAD_ORG_DOCS || item.navItemID == PVO_UPLOAD_DEST_DOCS)
    {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if([del.pricingDB vanline] == ARPIN){
        if(item.isReportOption){
            if(!item.hasRequiredSignatures){
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if(![item getReportWasUploaded:del.customerID]) {
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upload_accessory.png"]];
            } else {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
    
    return cell;
}

-(int)getPrintDocTypeForRow:(int)rowType
{
    switch (rowType) {
            
        case PVO_BOL_ORIGIN:
        case PVO_BOL_SIT:
        case PVO_BOL_DEST:
            return GENERATE_BOL;
            
        case PVO_DOV:
            return DECLARATION_OF_VALUE;
            
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
        case PVO_P_RIDER_EXCEPTIONS:
            return RIDER_EXCEPTIONS;
    }
    
    return -1;
}


#pragma mark - Table view delegate

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PVONavigationListItem *item = [rows objectAtIndex:[indexPath row]];
    return item.enabled ? indexPath : nil;
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedItem = [rows objectAtIndex:[indexPath row]];
    
    DriverData *data = [del.surveyDB getDriverData];
    
    UIAlertView *alert = nil;
    
    // check if the delivery is completed before allowing the document to be viewed
    PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
    
    if([del.pricingDB pvoNavItemHasReportSections:selectedItem.navItemID])
    {//this is a dynamic report entry record
        //see if there is any data... if so, ask them to remove the signature to continue -
        if ([self promptToRemoveSignatures])
            return;
    }
    /*
    if (!inv.deliveryCompleted)
    {
        [SurveyAppDelegate showAlert:@"You must complete the delivery before viewing this document!" withTitle:@"Delivery Required" withDelegate:self];
    }
    */
    switch (selectedItem.navItemID) {
        case PVO_INVENTORY:
            //if driver, don't let them continue with no packer's initials.
            if ([AppFunctionality removeSignatureOnNavigateIntoCompletedInv] && [selectedItem completed])
            {
                [self askToContinue:@"This inventory has been marked completed and/or a signature exists at Origin. If you choose to continue, any signatures will be removed, and the inventory marked incomplete. Would you like to continue?"];
            }
            else if(data.driverType == PVO_DRIVER_TYPE_PACKER && [del.surveyDB getAllPackersInitials].count == 0)
            {
                [SurveyAppDelegate showAlert:@"You must have initials entered from the main Packers setup screen to begin your Packer's Inventory." withTitle:@"Packer's Initials"];
            }
            else
                [self continueToSelectedItem];
            break;
        case PVO_P_ORG_HIGH_VALUE:
            if(![del.surveyDB pvoHasHighValueItems:del.customerID] && [del.pricingDB vanline] == ARPIN)
            {
                NSString *message = [NSString stringWithFormat:@"%1$@ items have not been added to the Inventory. This is the last opportunity to add %1$@ items before signing. Do you wish to continue to %1$@ signing?", [AppFunctionality getHighValueDescription]];
                
                alert = [[UIAlertView alloc] initWithTitle:[AppFunctionality getHighValueDescription]
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Yes", nil];
                alert.tag = PVO_ALERT_CONFIRM_HIGH_VALUE;
                [alert show];
            }
            else
                [self continueToSelectedItem];
            break;
        case PVO_DELIVER_SHIPMENT:
            if(selectedItem.completed)//see if they are sure they would like to continue...
                [self askToContinue:@"This inventory has been marked as delivered and/or a signature exists at Destination. If you choose to continue, any signatures will be removed, and the delivery marked incomplete. Would you like to continue?"];
            else
                [self continueToSelectedItem];
            break;
            
        case PVO_UPLOAD_ORG_DOCS:
        case PVO_UPLOAD_DEST_DOCS:
            if ([AppFunctionality disableSynchronization])
            {
                [SurveyAppDelegate showAlert:@"Online synchronization has been disabled with this version of Mobile Mover." withTitle:@"Sync Disabled"];
            }
            else
            {
                docsToUpload = [self getDocsToUpload];
                
                if (![SurveyAppDelegate hasInternetConnection:TRUE])
                {
                    [SurveyAppDelegate showAlert:@"An internet connection is required to upload documents.  Please connect to the internet to proceed."
                                       withTitle:@"Internet Required"];
                }
                else if([docsToUpload count] > 0)
                    [self askToContinue:@"This will upload your documents and save your inventory to the server."];
                else
                {
                    [SurveyAppDelegate showAlert:@"No documents are currently available for upload." withTitle:@"No Documents Available"];
                }
            }
            break;
        case PVO_VIEW_BOL:
            alert = [[UIAlertView alloc] initWithTitle:@"Estimated Charges"
                                               message:@"Exclude Estimated Charges?  Available for RSG Natl Acct and Part NAC/Part COD only."
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:@"Yes", @"No", nil];
            [alert show];
            break;
        case PVO_AUTO_INVENTORY_ORIG:
        case PVO_AUTO_INVENTORY_DEST:
            [self continueToSelectedItem];
            break;
        case PVO_AUTO_INVENTORY_REPORT_ORIG:
        case PVO_AUTO_INVENTORY_REPORT_DEST:
            [self continueToSelectedItem];
            break;
        default:
            if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcedisc?"].location != NSNotFound)
            {
                
                UIAlertView *discAlert = [[UIAlertView alloc] initWithTitle:@"Use Disconnected Reports?"
                                                                    message:@"Choose online or offline reporting."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Online"
                                                          otherButtonTitles:@"Offline", nil];
                
                discAlert.tag = PVO_ALERT_USE_DISCONNECTED;
                [discAlert show];
            }
            else
            {
                if ([AppFunctionality mustCompleteDeliveryForDestReports] && !inv.deliveryCompleted && (selectedItem.navItemID == PVO_P_DEL_HIGH_VALUE || selectedItem.navItemID == PVO_P_DEL_EXCP))
                {
                    [self showIncompleteDeliveryAlert];
                    return;
                }
                if ([del.surveyDB htmlReportSupportsImages:selectedItem.reportTypeID] && [del.surveyDB customerHasImages:del.customerID])
                {
                    [self showPickerForInventoryReportTypes];
                    return;
                }
                
                //check to see if there's any confirmation dialog required in the pricing databases.
//                if([del.pricingDB pvoNavItemHasConfirmation:selectedItem.navItemID])
//                {
//                    PVOConfirmationDetails *details = [del.pricingDB getPVOConfirmationDetails:selectedItem.navItemID];
//                    
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
//                                                                    message:details.confirmationText
//                                                                   delegate:self
//                                                          cancelButtonTitle:details.cancelButtonText
//                                                          otherButtonTitles:details.continueButtonText, nil];
//                    alert.tag = PVO_ALERT_CONFIRMATION_DETAIL;
//                    [alert show];
//                    
//                    
//                    [details release];
//                }
//                else
                if (![self promptForConfirmationDetails])
                    [self continueToSelectedItem];
            }
            break;
    }
    
    //[inv release];
}

-(void)showIncompleteDeliveryAlert {
    [SurveyAppDelegate showAlert:@"You must complete the delivery before viewing this document!" withTitle:@"Delivery Incomplete"];
}


#pragma mark - PVOValInitialControllerDelegate methods

-(void)initialsEntered:(PVOValInitialController *)initialController
{
    //load up signature screen...
    [self loadSignature:@"Valuation Statement.  Your signature is required here: I acknowledge that I have declared a value for my shipment and selected a deductible amount, if appropriate, and received a list of charges showing the various brackets of valuation available to me."];
}

#pragma - PVOSignatureControllerDelegate methods

-(void)signatureEntered:(PVOSignatureController *)sigController
{
    [self.navigationController popToViewController:self animated:YES];
}


#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(alertView.tag == PVO_ALERT_CONFIRM_SYNC)
    {
        
        if(alertView.cancelButtonIndex != buttonIndex)
        {
            if ([SurveyAppDelegate hasInternetConnection:TRUE])
                [self startServerSync];
            else
            {
                [SurveyAppDelegate showAlert:@"An internet connection is required to save latest changes to server.  Please connect to the internet to proceed."
                                   withTitle:@"Internet Required"];
            }
        }
        
    }
    else if(alertView.tag == PVO_ALERT_CONFIRM_HIGH_VALUE)
    {
        
        if(alertView.cancelButtonIndex != buttonIndex)
        {
            //get the type... fvp, then 0.60
//            del.hviValType = buttonIndex;
            [self continueToSelectedItem];
        }
        
    }
    else if(alertView.tag == PVO_ALERT_USE_DISCONNECTED)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            useDisconnectedReports = NO;
            [self continueToSelectedItem];
        }
        else
        {
            useDisconnectedReports = YES;
            [self continueToSelectedItem];
        }
    }
    else if (alertView.tag == PVO_ALERT_CONFIRMATION_DETAIL)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            [self continueToSelectedItem];
        }
    }
    else if (alertView.tag == PVO_ALERT_UPLOAD_DOCUMENTS)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            [self beginDocUpload];
        }
    }
    else if(alertView.cancelButtonIndex != buttonIndex)
    {
        //remove all items that need removed...
        switch (selectedItem.navItemID) {
            case PVO_INVENTORY:
                //remove origin signature, and mark inventory incomplete.
                inventory.inventoryCompleted = FALSE;
                [del.surveyDB updatePVOData:inventory];
                
                [del.surveyDB removeCompletionDate:del.customerID isOrigin:YES];
                
                [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
                break;
            case PVO_DELIVER_SHIPMENT:
                //remove origin signature, and mark inventory incomplete.
                inventory.deliveryCompleted = FALSE;
                [del.surveyDB updatePVOData:inventory];
                
                [del.surveyDB removeCompletionDate:del.customerID isOrigin:NO];
                
                [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DEST_INVENTORY];
                [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_DELIVER_ALL];
                break;
            case PVO_VIEW_BOL:
                //need to pass a flag to the report to show estimated charges or not based on the selection...
                additionalReportData = [NSNumber numberWithBool:buttonIndex == 0];
                break;
        }
        
        //remove any signatures...
        for (NSString *sigid in [selectedItem.signatureIDs componentsSeparatedByString:@","]) {
            [del.surveyDB deletePVOSignature:del.customerID forImageType:[sigid intValue]];
        }
        
        if (![self promptForConfirmationDetails])
            [self continueToSelectedItem];
    }

    else
    {
//        [docsToUpload release];
    }
}

#pragma mark - PVOUploadReportViewDelegate methods

-(void)uploadCompleted:(PVOUploadReportView*)uploadReportView
{
//    [self updateProgress:@"Successfully uploaded report."];
    PVONavigationListItem *navItem = [docsToUpload objectAtIndex:0];
    
    //found; reset dirty flags for current doc...
    int data = [navItem getPVOChangeDataToCheck];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB pvoSetDataIsDirty:NO forType:data forCustomer:del.customerID];
    
    [docsToUpload removeObjectAtIndex:0];
    
    [self uploadNextDoc];
    //[self done:nil];
}

-(void)uploadError:(PVOUploadReportView *)uploadReportView
{
    //doesnt update dirty flag
    [docsToUpload removeObjectAtIndex:0];
    
    [self uploadNextDoc];
}

#pragma mark - HTMLReportGeneratorDelegate methods

- (void)htmlReportGenerator:(HTMLReportGenerator*)generator fileSaved:(NSString*)filepath
{
    //    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self uploadDocGenerated:nil];
}

@end
