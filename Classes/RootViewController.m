//
//  RootViewController.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import	"SurveyAppDelegate.h"
#import "CustomerListItem.h"
#import "CustomerOptionsController.h"
#import "SplashViewController.h"
#import "BasicInfoController.h"
#import "CustomerCell.h"
#import "DownloadController.h"
#import "DriverDataController.h"
#import "DocumentLibraryController.h"
#import "AllNavController.h"
#import "AppFunctionality.h"
#import "AutoBackup.h"
#import "Prefs.h"

@implementation RootViewController

@synthesize customers, optionsController, navController, tblView, syncViewController;
@synthesize aboutView, cmdSort, purgeController, backupController, filterController;
@synthesize toolbarOptions, pvoDownload;
@synthesize pj673PrintSettings;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		
		
	}
	return self;
}

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    filters = [[CustomerFilterOptions alloc] init];
	filters.sortBy = SORT_BY_NAME;
	filters.dateFilter = SHOW_ORDER_NUMBER;
	filters.statusFilter = SHOW_STATUS_ALL;
	
    
    pj673PrintSettings = [[PJ673PrintSettings alloc] init];
    [pj673PrintSettings loadPreferences];
    
	//set the title for the main
	self.title = @"Customers";
    
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //remove all subviews from toolbarOptions and recreate.
    for (id subview in toolbarOptions.subviews) {
        if([subview isKindOfClass:[UIBarButtonItem class]])
            [subview removeFromSuperview];
    }
    
#if defined(DEBUG)
    NSLog(@"User name: %@", [Prefs username]);
    NSLog(@"Password: %@", [Prefs password]);
    NSLog(@"Beta password: %@", [Prefs betaPassword]);
    NSLog(@"Reports password: %@", [Prefs reportsPassword]);
#endif
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //make sure pricing and mileage is open
    [del openPricingDB];
    
    self.customers = [del.surveyDB getCustomerList:filters];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [array addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                    target:nil
                                                                    action:nil]];
    
    if (![AppFunctionality disableDocumentsLibrary])
    {
        [array addObject:[[UIBarButtonItem alloc]
                           initWithTitle:@"Docs" style:UIBarButtonItemStylePlain
                           target:self
                           action:@selector(cmdDocuments_Click:)]];
    }
    
    //    [array addObject:[[UIBarButtonItem alloc] initWithTitle:@"Verify"
    //                                                       style:UIBarButtonItemStylePlain
    //                                                      target:self
    //                                                      action:@selector(cmdSort_Click:)]];
    
    
    //    [array addObject:[[UIBarButtonItem alloc] initWithTitle:@"Sync"
    //                                                       style:UIBarButtonItemStylePlain
    //                                                      target:self
    //                                                      action:@selector(cmdSync_Click:)]];
    [array addObject:[[UIBarButtonItem alloc] initWithTitle:@"Maintenance"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(cmdMaintenance_Click:)]];
    
    DriverData *data = [del.surveyDB getDriverData];
    
    [array addObject:[[UIBarButtonItem alloc] initWithTitle:(data.driverType == PVO_DRIVER_TYPE_PACKER ? @"Packer" : @"Driver")
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(cmdDriver_Click:)]];
    
    
    [array addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                    target:nil
                                                                    action:nil]];
    
    [toolbarOptions setItems:array];
    [self.view bringSubviewToFront:toolbarOptions];
    [self.tblView reloadData];
    
//    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:@"Customers"];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //check for auto backup stuff...
    AutoBackup *backup = [[AutoBackup alloc] init];
    backup.caller = self;
    backup.finishedBackup = @selector(finishedBackup);
    [backup beginBackup];
}

#pragma mark - Instance Methods -

-(void)reloadTableViewData {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    self.customers = [del.surveyDB getCustomerList:filters];
    [tblView reloadData];
}

- (IBAction)cmdDocuments_Click:(id)sender
{
    //    if(self.docsController == nil)
    //    {
    //        self.docsController = [[DocumentLibraryController alloc] initWithStyle:UITableViewStyleGrouped];
    //    }
    //
    //    self.docsController.customerMode = NO;
    //
    //    self.newNavController = [[AllNavController alloc] initWithRootViewController:self.docsController];
    
    //SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DocumentLibraryController *content = [[DocumentLibraryController alloc] initWithStyle:UITableViewStyleGrouped];
    AllNavController *nav = [[AllNavController alloc] initWithRootViewController:content];
    [self presentViewController:nav animated:YES completion:nil];

}

-(IBAction) cmdSync_Click:(id)sender
{
	if(syncViewController == nil)
	{
		syncViewController = [[SyncViewController alloc] initWithNibName:@"SyncView" bundle:nil];
		syncViewController.title = @"Synchronizing...";
	}
	
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[del.navController presentViewController:syncViewController animated:YES completion:nil];
	
}

-(IBAction) cmdDriver_Click:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DriverData *driverData = [del.surveyDB getDriverData];
    DriverDataController *drv = [[DriverDataController alloc] initWithStyle:UITableViewStyleGrouped];
    drv.title = [NSString stringWithFormat:@"%@ Data", driverData == nil || driverData.driverType != PVO_DRIVER_TYPE_PACKER ? @"Driver" : @"Packer"];
    
    navController = [[PortraitNavController alloc] initWithRootViewController:drv];
    navController.dismissDelegate = self;
    navController.dismissCallback = @selector(updateDriverButton);

    [del.navController presentViewController:navController animated:YES completion:nil];
}

-(void) updateDriverButton {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    for (UIBarButtonItem *item in toolbarOptions.items) {
        if ([item.title isEqualToString:@"Driver"] || [item.title isEqualToString:@"Packer"]) {
            DriverData *data = [del.surveyDB getDriverData];
            item.title = data.driverType == PVO_DRIVER_TYPE_PACKER ? @"Packer" : @"Driver";
        }
    }
}

-(IBAction) cmdMaintenance_Click:(id)sender;
{
    UIActionSheet *sheet;
    BOOL showDemoOrders = ([AppFunctionality getDemoOrderNumbers] != nil);
    sheet = [[UIActionSheet alloc] initWithTitle:@"Additional Options"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"List Maintenance", @"Backup", @"Purge", @"About", @"Maintenance Refresh", @"View Filters", @"Preferences",
             (showDemoOrders ? @"Demo Orders" : @"Brother PJ-673 Settings"), (showDemoOrders ? @"Brother PJ-673 Settings" : nil), nil];
    
    [sheet showInView:self.view];
	
}

-(void)loadFiltersScreen
{
    if(filterController == nil)
        filterController = [[ChangeFiltersController alloc] initWithStyle:UITableViewStyleGrouped];
    
    filterController.filters = filters;
    self.navController = [[PortraitNavController alloc] initWithRootViewController:filterController];
    
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(IBAction) cmdSort_Click:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([[del.surveyDB getPVOVerifyInventoryOrders] count] > 0)
    {
        verifyHolder =  [[PVOVerifyHolder alloc] initFromView:self];
    }
    else
        [SurveyAppDelegate showAlert:@"No Verify Orders are present on this device.  Please perform a Sync to bring down all pending Verify Orders." withTitle:@"No Orders Found"];
	
}

-(IBAction)addCustomer:(id)sender
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"How Would You Like To Add A New Record?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Create New", @"Download", nil];
    action.tag = ACTION_SHEET_CREATE;
    [action showInView:self.view];
}

-(void)createNewCustomer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BasicInfoController *addController = [[BasicInfoController alloc] initWithStyle:UITableViewStyleGrouped];
        addController.title = @"New Customer";
        addController.newCustomerView = YES;
    //recreate it each time...
    navController = [[PortraitNavController alloc] initWithRootViewController:addController];
    navController.dismissDelegate = self;
    navController.dismissCallback = @selector(reloadTableViewData);
    
    [del.navController presentViewController:navController animated:YES completion:nil];
}

-(void)handleDownloadCustomer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([AppFunctionality disableSynchronization])
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Online synchronization has been disabled with this version of %@.", @"Mobile Mover"]
                           withTitle:@"Sync Disabled"];
    }
    else
    {
        BOOL performSync = YES;
        int vanlineID = [del.pricingDB vanline];
        DriverData *driver = [del.surveyDB getDriverData];
        if (vanlineID == ATLAS)
        {
            if (driver == nil || ((driver.driverNumber == nil || [driver.driverNumber length] == 0) &&
                                  (driver.haulingAgent == nil || [driver.haulingAgent length] == 0)))
            {
                [SurveyAppDelegate showAlert:@"You must have a driver number or hauling agent code entered from the Driver screen "
                 "in order to download a shipment."
                                   withTitle:@"Credentials Required"];
                performSync = NO;
            }
        }
        else if (vanlineID == ARPIN)
        {
            if (driver == nil)
            {
                [SurveyAppDelegate showAlert:@"You must have driver information entered from the Driver screen "
                 "in order to download a shipment."
                                   withTitle:@"Driver Info Required"];
                performSync = NO;
            }
            else {
                //if a driver does not have a hauling agent code or driver# / password entered OR packers inventory mode and enter agency on download screen is disabled
                if (driver.driverType != PVO_DRIVER_TYPE_PACKER || (driver.driverType == PVO_DRIVER_TYPE_PACKER && ![AppFunctionality showAgencyCodeOnDownload]))
                {
                    if (driver.syncPreference == PVO_ARPIN_SYNC_BY_DRIVER &&
                             (driver.driverNumber == nil || [driver.driverNumber length] == 0 ||
                              driver.driverPassword == nil || [driver.driverPassword length] == 0))
                    {
                        [SurveyAppDelegate showAlert:@"You must have a driver number and password entered from the Driver screen "
                         "in order to download a shipment by driver number and password."
                                           withTitle:@"Driver Info Required"];
                        performSync = NO;
                    }
                    else if (driver.syncPreference == PVO_ARPIN_SYNC_BY_AGENT &&
                             (driver.haulingAgent == nil || [driver.haulingAgent length] == 0))
                    {
                        [SurveyAppDelegate showAlert:@"You must have an agency number entered from the Driver screen "
                         "in order to download a shipment by agent number."
                                           withTitle:@"Driver Info Required"];
                        performSync = NO;
                    }
                }
            }
        }
        
        if (performSync)
        {
            if(pvoDownload == nil)
                pvoDownload = [[PVOSyncController alloc] initWithStyle:UITableViewStyleGrouped];
            pvoDownload.title = @"Download";
            navController = [[PortraitNavController alloc] initWithRootViewController:pvoDownload];
            navController.dismissDelegate = self;
            navController.dismissCallback = @selector(reloadTableViewData);
            
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}

-(IBAction) cmdPackers_Click:(id)sender
{
    if(packerInitialController == nil)
        packerInitialController = [[PackerInitialsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    packerInitialController.isModal = YES;
    UINavigationController *newNav = [[UINavigationController alloc] initWithRootViewController:packerInitialController];
    [self presentViewController:newNav animated:YES completion:nil];
}

-(void)finishedBackup
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //NSLog(@"ShortcutType:%@", del.launchedShortcutItem.type);
    
    if (del.launchedShortcutItem != nil)
    {
        if([del.launchedShortcutItem.type isEqualToString:@"CreateNewShortcut"])
        {
            [self createNewCustomer];
        }
        else if([del.launchedShortcutItem.type isEqualToString:@"DownloadShortcut"])
        {
            [self handleDownloadCustomer];
        }
        
        del.launchedShortcutItem = nil;
    }
    
    if([del.pricingDB vanline] == ARPIN){
        if([SurveyAppDelegate hasInternetConnection]){
            _numDirtyReports = [[del.surveyDB getAllDirtyReports] count];
            if(_numDirtyReports > 0){
                UIAlertController *a = [UIAlertController
                                        alertControllerWithTitle:@"Upload Reports"
                                        message:@"This device has reports that have not been uploaded.  Would you like to upload them now?"
                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *n = [UIAlertAction
                                    actionWithTitle:@"No"
                                    style:UIAlertActionStyleDefault
                                    handler:nil];
                
                UIAlertAction *y = [UIAlertAction
                                    actionWithTitle:@"Yes"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        
                                        [self setupProgressView];
                                        
                                        PreviewPDFController *p = [[PreviewPDFController alloc] init];
                                        p.delegate = self;
                                        p.dirtyReportUploadFinished = @selector(dirtyUploadFinished);
                                        p.customers = [del.surveyDB getCustomerList:nil];
                                        p.uploadingDirtyReports = YES;
                                        [p uploadAllDirtyReports];
                                    }];
                
                [a addAction:n];
                [a addAction:y];
                
                [self presentViewController:a animated:YES completion:nil];
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(void)setupProgressView
{
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.dirtyReportProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Uploading Reports" andProgressBar:YES];
    [del.navController.topViewController.view addSubview:_dirtyReportProgress];
    [del.navController.topViewController.view bringSubviewToFront:_dirtyReportProgress];
}

-(void)dirtyUploadFinished
{
    double percent = self.dirtyReportProgress.progressBar.progress + (float)1/_numDirtyReports;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dirtyReportProgress updateProgressBar:percent];
    });
    
    if(percent == 1){
        [SurveyAppDelegate showAlert:@"Upload process complete." withTitle:nil];
        [_dirtyReportProgress removeFromSuperview];
        [tblView reloadData];
    }
}

#pragma mark - Table Data Source Methods -

-(NSInteger)tableView: (UITableView *)thisTableView numberOfRowsInSection: (NSInteger)section
{
    return [self.customers count];
}

-(UITableViewCell*)tableView: (UITableView *)thisTableView
       cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    static NSString *CustomerCellID = @"CustomerCellID";
    
    CustomerCell *cell = (CustomerCell *)[thisTableView dequeueReusableCellWithIdentifier:CustomerCellID];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomerCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSUInteger row = [indexPath row];
    
    CustomerListItem *item = [customers objectAtIndex:row];
    
    cell.labelName.text = item.name;
    NSMutableString *labelDateText;
    
    if(filters.dateFilter == SHOW_ORDER_NUMBER)
    {
        labelDateText = [NSMutableString stringWithString:item.orderNumber];
    }
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        labelDateText = [NSMutableString stringWithString:[formatter stringFromDate:item.date]];
    }
    
    SurveyCustomer *cust = [del.surveyDB getCustomer:item.custID];
    
    NSString *lastSyncDate = [cust getFormattedLastSaveToServerDate:NO];
    if ([lastSyncDate length] > 0)
    {
        [labelDateText appendFormat:@"  (%@)", lastSyncDate];
    }
    
    cell.labelDate.text = labelDateText;
    
    BOOL noAccessory = true;
    NSArray *d = [del.surveyDB getUploadTrackingRecordsForCustomer:item.custID];
    for(NSNumber *n in d){
        PVONavigationListItem *p = [[PVONavigationListItem alloc] init];
        p.navItemID = n.intValue;
        p.custID = item.custID;
        if(p.hasRequiredSignatures){
            noAccessory = false;
            break;
        }
    }
    
    if(!noAccessory){
        if([[del.surveyDB getAllDirtyReportsForCustomer:item.custID] count] > 0){
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upload_accessory.png"]];
        } else {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
	return (UITableViewCell*)cell;
	
}

#pragma mark - Table View Delegate Methods -

-(void)tableView:(UITableView *)thisTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB requiresUpdate])
    {
        [thisTableView deselectRowAtIndexPath:indexPath animated:YES];
        [SurveyAppDelegate showAlert:@"The pricing database is out of date. Tap the Maintenance option on the bottom of the Customers list and select Maintenance Refresh when you are connected to the internet to download the latest update." withTitle:@"Pricing database update recommended"];
    }
    
	//get the customer display, set it to the ctl, then push the ctllr
	
    CustomerListItem *item = [customers objectAtIndex:indexPath.row];
    
    //lazy load the optionsController
    if(optionsController == nil)
        optionsController = [[CustomerOptionsController alloc] initWithNibName:@"CustomerOptionsView" bundle:nil];
    
    optionsController.title = item.name;
    optionsController.selectedItem = item;
    
    del.customerID = item.custID;
    [del.navController pushViewController:optionsController	animated:YES];
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    return nil;
    
	//show tiral message
    //	NSString *retval = nil;
    //	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //	ActivationRecord *rec = [del.surveyDB getActivation];
    //
    //	if(!rec.unlocked)
    //	{//in trial mode
    //		//3600 secs in an hr
    //		NSDate *trialEnd = [rec.trialBegin addTimeInterval:TRIAL_DAYS * 24 * 3600];
    //		NSTimeInterval timeremaining = abs([trialEnd timeIntervalSinceNow]);
    //		long totalsecs = (long)timeremaining;
    //		long totalhours = totalsecs / 3600;
    //		int totaldays = totalhours / 24;
    //		retval = [NSString stringWithFormat:@"Trial Mode: %d Days Remaining", totaldays];
    //	}
    //	[rec release];
    //	return retval;
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
	return nil;//[filters currentFilterString];
}


// Invoked when the user touches Edit.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // Updates the appearance of the Edit|Done button as necessary.
    [super setEditing:editing animated:animated];
    [self.tblView setEditing:editing animated:YES];
    // Disable the add button while editing.
    if (editing) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		@try {
            CustomerListItem *item = [customers objectAtIndex:[indexPath row]];
            NSString *message = [NSString stringWithFormat:@"Are you sure you would like to delete record for %@?", item.name];
            UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:@"Delete Customer"
                                                    message:message
                                             preferredStyle:UIAlertControllerStyleAlert];
        
            [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                [del.surveyDB deleteCustomer:item.custID];
                
                [self.customers removeObject:item];
                // Animate the deletion from the table.
                [self.tblView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
                }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
        }
		@catch (NSException * e) {
			[SurveyAppDelegate handleException:e];
		}
		
    }
}

#pragma mark - action sheet stuff -

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		if(actionSheet.tag == ACTION_SHEET_CREATE)
        {
            if(buttonIndex == 0)
                [self createNewCustomer];
            else
            {
                [self handleDownloadCustomer];
            }
        }
        else if (actionSheet.tag == ACTION_SHEET_ITEM_LIST_SETTINGS)
        {
            if(buttonIndex == 0)
            {
                if(itemDelete == nil) {
                    itemDelete = [[DeleteItemController alloc] initWithStyle:UITableViewStylePlain];
                }
                
                itemDelete.customerId = -1;
                itemDelete.ignoreItemListId = TRUE;
                
                navController = [[PortraitNavController alloc] initWithRootViewController:itemDelete];
                
                itemDelete.title = @"Hide Item";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
            }
            else if(buttonIndex == 1)
            {
                if(roomDelete == nil)
                    roomDelete = [[DeleteRoomController alloc] initWithStyle:UITableViewStylePlain];
                
                navController = [[PortraitNavController alloc] initWithRootViewController:roomDelete];
                
                roomDelete.title = @"Hide Room";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
            }
            else if(buttonIndex == 2)
            {
                if(contentsDelete == nil)
                    contentsDelete = [[PVODeleteCCController alloc] initWithStyle:UITableViewStylePlain];
                
                navController = [[PortraitNavController alloc] initWithRootViewController:contentsDelete];
                
                contentsDelete.title = @"Hide Contents";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
                
            }
            else if(buttonIndex == 3)
            {
                if(favorites == nil)
                    favorites = [[PVOFavoriteItemsController alloc] initWithStyle:UITableViewStyleGrouped];
                
                navController = [[PortraitNavController alloc] initWithRootViewController:favorites];
                
                favorites.title = @"Favorite Items";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
                
            }
            else if(buttonIndex == 4)
            {
                // Favorite Items By Room (OT 7985)
                if(favoritesByRoom == nil)
                    favoritesByRoom = [[PVOFavoriteItemsByRoomController alloc] initWithStyle:UITableViewStyleGrouped];
                
                navController = [[PortraitNavController alloc] initWithRootViewController:favoritesByRoom];
                
                favoritesByRoom.title = @"Favorite Items By Room";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
                
            }
            else if (buttonIndex == 5) {
                if(favoritesCartonContents == nil)
                    favoritesCartonContents = [[PVOFavoriteCartonContentsController alloc] initWithStyle:UITableViewStyleGrouped];
                
                navController = [[PortraitNavController alloc] initWithRootViewController:favoritesCartonContents];
                
                favoritesCartonContents.title = @"Favorite Carton Contents";
                
                [self.navigationController presentViewController:navController animated:YES completion:nil];
            }
        }
		else
		{
            BOOL showDemoOrders = ([AppFunctionality getDemoOrderNumbers] != nil);
            if (!showDemoOrders && buttonIndex >= OPTIONS_DEMO_ORDERS)
                buttonIndex = buttonIndex + 1;
            
            if (buttonIndex == OPTIONS_LIST_MAINTENANCE)
            {
                UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"List Maintenance"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:@"Hide Items", @"Hide Rooms", @"Hide Carton Content", @"Item Favorites", @"Item Favorites By Room", @"Carton Contents Favorites", nil];
                sheet.tag = ACTION_SHEET_ITEM_LIST_SETTINGS;
                [sheet showInView:self.view];
                
            }
            else if(buttonIndex == OPTIONS_ABOUT)
			{
				if(aboutView == nil)
				{
					aboutView = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
					aboutView.title = @"About Survey";
				}
                
                navController = [[PortraitNavController alloc] initWithRootViewController:aboutView];
				[del.navController presentViewController:navController animated:YES completion:nil];
			}
			else if(buttonIndex == OPTIONS_PURGE)
			{
				if(purgeController == nil)
				{
					purgeController = [[PurgeController alloc] initWithStyle:UITableViewStyleGrouped];
					purgeController.title = @"Purge Surveys";
				}
				
				//seconds
				NSTimeInterval interval;
				interval = 1;
				//one sec
				interval *= 60;
				//one min
				interval *= 60;
				//one hour
				interval *= 24;
				//one day
				interval *= 60;
				//sixty days
				interval *= -1;
                purgeController.purge = [[NSDate date] dateByAddingTimeInterval:interval];
				
				//recreate it each time...
				self.navController = [[PortraitNavController alloc] initWithRootViewController:purgeController];
				
				[del.navController presentViewController:navController animated:YES completion:nil];
			}
			else if(buttonIndex == OPTIONS_BACKUP)
			{
				if(backupController == nil)
				{
					backupController = [[BackupController alloc] initWithStyle:UITableViewStyleGrouped];
					backupController.title = @"Backup";
				}
				//recreate it each time...
				self.navController = [[PortraitNavController alloc] initWithRootViewController:backupController];
				[del.navController presentViewController:navController animated:YES completion:nil];
			}
			else if(buttonIndex == OPTIONS_VIEW_FILTERS)
			{
                if ([SurveyAppDelegate iOS8OrNewer])
                    [self loadFiltersScreen];
                else
                    [SurveyAppDelegate showAlert:@"You must upgrade to iOS 8 to use this shortcut." withTitle:@"Not Supported"];
			}
            else if (buttonIndex == OPTIONS_VIEW_PREFERENCES)
            {
                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
            else if (buttonIndex == OPTIONS_DEMO_ORDERS)
            {
                NSString *message = [AppFunctionality getDemoOrderDisplay];
                [SurveyAppDelegate showAlert:message withTitle:@"Demo Order Numbers"];
            }
            else if (buttonIndex == OPTIONS_BROTHER_PJ673_SETTINGS)
            {
                [self showBrotherPJ673Settings];
            }
			else if(buttonIndex == OPTIONS_TARIFF_REFRESH) // || buttonIndex == OPTIONS_HTML_REPORTS_REFRESH)
			{//download test
				DownloadController *download = [[DownloadController alloc] initWithNibName:@"DownloadView" bundle:nil];
				download.dismiss = YES;
                download.downloadHTMLReportsOnly = NO; //buttonIndex == OPTIONS_HTML_REPORTS_REFRESH;
                navController = [[PortraitNavController alloc] initWithRootViewController:download];
				[del.navController presentViewController:navController animated:YES completion:nil];
			}
		}
	}
}

#pragma mark - Brother PJ-673 settings -

- (void)showBrotherPJ673Settings
{
    BrotherPrinterSettingsController *brotherIPCtl = [[BrotherPrinterSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *myNavController = [[UINavigationController alloc] initWithRootViewController:brotherIPCtl];
    [self presentViewController:myNavController animated:YES completion:nil];
}

-(void)brotherIPUpdated:(NSString*)address
{
    [pj673PrintSettings saveIPAddress:address];
}


@end
