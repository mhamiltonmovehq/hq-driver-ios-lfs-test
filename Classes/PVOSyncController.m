//
//  PVOSyncController.m
//  Survey
//
//  Created by Tony Brame on 9/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOSyncController.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"
#import "OrigDestCell.h"
#import "AppFunctionality.h"

@implementation PVOSyncController

@synthesize sync, tboxCurrent, orderNum, localOrderNum;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)beginSync:(BOOL)merge
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    sync.syncAction = PVO_SYNC_ACTION_DOWNLOAD;
    sync.updateWindow = self;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncCompleted);
    sync.mergeCustomer = merge;
    sync.downloadRequestType = requestType;
    sync.orderNumber = (requestType == 0 ? self.orderNum : self.localOrderNum);
    
    [del.operationQueue addOperation:sync];
    
    downloading = TRUE;
    [self.tableView reloadData];
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
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self 
                                                                                            action:@selector(cancel:)];
    
    includedRows = [[NSMutableArray alloc] init];
}

-(IBAction)cancel:(id)sender
{
    [sync cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)requestTypeChanged:(id)sender
{
    UISegmentedControl *seg = sender;
    requestType = seg.selectedSegmentIndex;
    [self initializeIncludedRows];
    [self.tableView reloadData];
}

-(void)initializeIncludedRows
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [includedRows removeAllObjects];
    
    
#ifndef ATLASNET
    [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_TYPE]];
        
    DriverData *data = [del.surveyDB getDriverData];
    if ([AppFunctionality showAgencyCodeOnDownload] && data.driverType == PVO_DRIVER_TYPE_PACKER)
    {
        [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_INT_AGENCY_CODE]];
    }
    
    if(requestType == 1) //local
        [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_LOC_ORDER_NUM]];
    else //interstate
    {
        [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_INT_ORDER_NUM]];
    }
#else
    [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_INT_ORDER_NUM]];
#endif
    
    
    [includedRows addObject:[NSNumber numberWithInt:PVO_SYNC_DOWNLOAD]];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    downloading = FALSE;
    
    if(!editing)
        self.sync = [[PVOSync alloc] init];
    
    editing = FALSE;
    
    [self initializeIncludedRows];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
}

- (void)viewDidAppear:(BOOL)animated
{
    //check driver/packer setting
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    
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
            [self initializeIncludedRows];
            [self.tableView reloadData];
        }
    }
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.orderNum = nil;
    self.localOrderNum = nil;
    
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

-(void)updateValueWithField:(UITextField*)tbox
{
    if(tbox.tag == PVO_SYNC_LOC_ORDER_NUM)
        self.localOrderNum = tbox.text;
    else if (tbox.tag == PVO_SYNC_INT_ORDER_NUM)
        self.orderNum = tbox.text;
//    else if(tbox.tag == PVO_SYNC_INT_CUST_LAST_NAME)
//        sync.customerLastName = tbox.text;
    else if(tbox.tag == PVO_SYNC_INT_AGENCY_CODE)
        sync.overrideAgencyCode = tbox.text;
}

-(IBAction)doneEditingText:(id)sender
{
	[tboxCurrent resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)updateProgress:(NSString*)textToAdd
{
    [SurveyAppDelegate showAlert:textToAdd withTitle:@"Download"];
}

-(void)syncCompleted
{
	[self cancel:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return downloading ? 0 : [includedRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *OrigDestCellIdentifier = @"OrigDestCell";
    
    UITableViewCell *cell = nil;
    TextCell *textCell = nil;
    OrigDestCell *odCell = nil;
    
    int row = [[includedRows objectAtIndex:indexPath.row] intValue];
    
    if(row == PVO_SYNC_TYPE)
    {
        odCell = (OrigDestCell*)[tableView dequeueReusableCellWithIdentifier:OrigDestCellIdentifier];
        if(odCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrigDestCell" owner:self options:nil];
            odCell = [nib objectAtIndex:0];
            odCell.accessoryType = UITableViewCellAccessoryNone;
            [odCell.segmentOrigDest addTarget:self
                                       action:@selector(requestTypeChanged:)
                             forControlEvents:UIControlEventValueChanged];
        }
        
        [odCell.segmentOrigDest removeAllSegments];
        
        [odCell.segmentOrigDest insertSegmentWithTitle:@"All Others" atIndex:0 animated:NO];
        [odCell.segmentOrigDest insertSegmentWithTitle:@"Interstate" atIndex:0 animated:NO];
        
        odCell.segmentOrigDest.selectedSegmentIndex = requestType;
    }
    else if(row == PVO_SYNC_DOWNLOAD)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"Download";
    }
    else
    {
        textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        if(textCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            textCell.accessoryType = UITableViewCellAccessoryNone;
            textCell.tboxValue.delegate = self;
        }
        
        textCell.tboxValue.tag = row;
        
        textCell.tboxValue.returnKeyType = UIReturnKeyDone;
        [textCell.tboxValue addTarget:self 
                               action:@selector(doneEditingText:) 
                     forControlEvents:UIControlEventEditingDidEndOnExit];
    
        textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        
        
        textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        if(row == PVO_SYNC_LOC_ORDER_NUM || row == PVO_SYNC_INT_ORDER_NUM)
        {
            if (row == PVO_SYNC_INT_ORDER_NUM)
                textCell.tboxValue.text = self.orderNum;
            else
                textCell.tboxValue.text = self.localOrderNum;
            textCell.tboxValue.placeholder = @"Order Number";
        }
//        else if(row == PVO_SYNC_INT_CUST_LAST_NAME)
//        {//not using customer last name for sync
//            textCell.tboxValue.text = sync.customerLastName;
//            textCell.tboxValue.placeholder = @"Customer Last Name";
//        }
        else if(row == PVO_SYNC_INT_AGENCY_CODE)
        {
            textCell.tboxValue.text = @"";
            textCell.tboxValue.placeholder = @"Hauling Agt #";
        }
    }
    
    return textCell != nil ? textCell : cell != nil ? cell : odCell;
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

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(!downloading)
        return nil;
    
    UIView *waitView;
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] 
                                         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activity startAnimating];
    
    CGRect mytest = CGRectMake(0, 0, self.view.frame.size.width, activity.frame.size.height);
    waitView = [[UIView alloc] initWithFrame:mytest];
    [waitView setBackgroundColor:[UIColor clearColor]];
    
    [waitView addSubview:activity];
    
    //height...21
    mytest = CGRectMake(activity.frame.size.height + 5, (activity.frame.size.height - 21) / 2, 200, 21);
    UILabel *waitingLabel = [[UILabel alloc] initWithFrame:mytest];
    waitingLabel.text = @"Downloading...";
    [waitingLabel setBackgroundColor:[UIColor clearColor]];
    
    [waitView addSubview:waitingLabel];
    
    return waitView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [[includedRows objectAtIndex:indexPath.row] intValue];
    if(row == PVO_SYNC_DOWNLOAD)
    {
        if(tboxCurrent != nil)
            [self updateValueWithField:tboxCurrent];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *data = [del.surveyDB getDriverData];
        
        sync.orderNumber = (requestType == 0 ? self.orderNum : self.localOrderNum);
        
        if(sync.orderNumber == nil || [sync.orderNumber length] == 0)
            [SurveyAppDelegate showAlert:@"You must have an order number entered to continue." withTitle:@"Order Number"];
#ifndef ATLASNET
        if([AppFunctionality showAgencyCodeOnDownload] && data.driverType == PVO_DRIVER_TYPE_PACKER && (sync.overrideAgencyCode == nil || sync.overrideAgencyCode.length == 0))
            [SurveyAppDelegate showAlert:@"You must have a customer last name entered to continue." withTitle:@"Last Name"];
        else
#endif
        {
            //check for dupes first, ask to merge or create new.
            if(requestType == 1)
                [self checkMerge];
            else
            {//confirm int order id
                if ([SurveyAppDelegate hasInternetConnection:TRUE])
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Order Number"
                                                                    message:[NSString stringWithFormat:@"You are attempting to download order:\r\n%@", sync.orderNumber]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Continue", nil];
                    alert.tag = PVO_SYNC_ALERT_CONFIRM_INT_ID;
                    [alert show];
                    
                }
                else
                {
                    [SurveyAppDelegate showAlert:@"An internet connection is required to download order details.  Please connect to the internet to proceed."
                                       withTitle:@"Internet Required"];
                }
            }
        }
        
    }
}

-(void)checkMerge
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomerByOrderNumber:sync.orderNumber];
    if(cust != nil && (int)cust.pricingMode == requestType)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Merge?"
                                                        message:[NSString stringWithFormat:@"A %@record with this order number already exists on this device. "
                                                                 "If an order is found, would you like to Merge the data from the server into your existing "
                                                                 "record, or create a new record?", cust.pricingMode == LOCAL ? @"local " : @""]
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Merge", @"Create New", nil];
        alert.tag = PVO_SYNC_ALERT_CONFIRM_MERGE;
        [alert show];
        
    }
    else
        [self beginSync:NO];
}

#pragma mark - UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(doneEditingText:)];
    
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(alertView.tag == PVO_SYNC_ALERT_CONFIRM_INT_ID)
            [self checkMerge];
        else if(alertView.tag == PVO_SYNC_ALERT_DRIVER_PACKER)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            DriverData *data = [del.surveyDB getDriverData];
            data.driverType = buttonIndex + 1;
            [del.surveyDB updateDriverData:data];
            [self initializeIncludedRows];
            [self.tableView reloadData];
        }
        else if(alertView.tag == PVO_SYNC_ALERT_CONFIRM_MERGE)
            [self beginSync:buttonIndex == 1];
    }
}

@end
