//
//  ProcessReportController.m
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProcessReportController.h"
#import <BRPtouchPrinterKit/BRPtouchPrinter.h>
#import "SurveyAppDelegate.h"
#import "NoteCell.h"
#import "TextCell.h"
#import "CustomerUtilities.h"
#import "SyncGlobals.h"
#import "Base64.h"
#import "GetReport.h"
#import "OrigDestCell.h"
#import "SwitchCell.h"
#import "Prefs.h"
#import "PortraitNavController.h"
#import "MBProgressHUD.h"
#import "PreviewPDFController.h"
#import "AppFunctionality.h"

@implementation ProcessReportController

@synthesize activity, labelLoading, tableView, defaults, tboxCurrent;
@synthesize reportAddress, rows;

@synthesize viewPrintProgress;
@synthesize labelPrintPage, pvoReportTypeID;
@synthesize progressPage, uploader;
@synthesize progressJob, reportOption, printType;
@synthesize ccEmails, bccEmails;
@synthesize pj673PrintSettings;
@synthesize getPrinter, pdfPath;
@synthesize uploadProgress;
@synthesize pvoNavItemID;
@synthesize delegate;

@synthesize agentEmailPlaceholder, agentNamePlaceholder;


- (NSString *)fetchSSID
{
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    //NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    NSDictionary *info = nil;
    NSString *theSSID = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        //NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        if ([info valueForKey:@"SSID"])
        {
            theSSID = [NSString stringWithString:[info valueForKey:@"SSID"]];
        }
        
        if (info && [info count]) {
            break;
        }
    }
    return theSSID;
}

- (size_t)getPDFPageCount: (NSURL *)pdfURL
{
    
    // Open PDF File to get page count
    CGPDFDocumentRef pdfDocRef;
    size_t pdfPageCount=0;
    pdfDocRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    if (pdfDocRef != NULL)
    {
        pdfPageCount = CGPDFDocumentGetNumberOfPages(pdfDocRef);
        CGPDFDocumentRelease(pdfDocRef);
    }
    
    return pdfPageCount;
}

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */


- (void)viewDidLoad {
    
    printer = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(print_PrintComplete:)
                                                 name:ePrintCompleteNotification
                                               object:nil];
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.title = @"Print";
    
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                         target:self 
                                                                         action:@selector(done:)];
    self.navigationItem.leftBarButtonItem = btn;
    
    additionalEmails = [[NSMutableArray alloc] init];
    
    if (ccEmails == nil)
        ccEmails = [[NSMutableArray alloc] init];
    if (bccEmails == nil)
        bccEmails = [[NSMutableArray alloc] init];
    
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (gettingAPrinter && ![AppFunctionality useAirPrintForPrinting] && getPrinter != nil)
    {
        if(getPrinter.selectedPrinter != nil)
        {
            getPrinter.selectedPrinter.quality = quality;
            [self printPDFFile:getPrinter.selectedPrinter];
        }
    }
    else {
        if (printType == PRINT_HARD_COPY) {
            labelLoading.text = @"Checking Brother Status";
            activity.hidden = NO;
            [activity startAnimating];
            
            [PJ673PrintSettings hasBrotherAttachedWithDelegate:self];
        } else {
            [self initializeScreen];
        }
    }
    [super viewWillAppear:animated];
}

-(void)initializeScreen
{
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    if (!comingFromMailer)
    {
        [additionalEmails removeAllObjects];
        color = YES;
        quality = 0;
        
        if (ccEmails == nil)
            ccEmails = [[NSMutableArray alloc] init];
        if (bccEmails == nil)
            bccEmails = [[NSMutableArray alloc] init];
        
        [self.tableView reloadData];
        
        viewPrintProgress.hidden = YES;
        
        labelLoading.text = @"Loading Report Options";
        activity.hidden = YES;
        labelLoading.hidden = YES;
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(keyboardWillShow:)
         name:UIKeyboardWillShowNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(keyboardWillHide:)
         name:UIKeyboardWillHideNotification
         object:nil];
        
        keyboardIsShowing = NO;
        
        if(printType == PRINT_HARD_COPY)
            self.navigationItem.rightBarButtonItem = nil;
        else
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options" 
                                                                                       style:UIBarButtonItemStylePlain
                                                                                      target:self 
                                                                                      action:@selector(options:)];
        
        [self initializeRows];
        
        if(printType == PRINT_EMAIL)
        {
            self.title = @"Email";
            
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
            ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
            
            self.defaults = [del.surveyDB getReportDefaults];
            
            //per call with Brian 7.17.12, subject no longer saved as part of defaults
            defaults.subject = [NSString stringWithFormat:@"Inventory Documentation - %@, %@: %@", cust.lastName, cust.firstName, inf.orderNumber];
            
            if(del.viewType == OPTIONS_PVO_VIEW && defaults.newRec)
            {
                defaults.body = @"Attached is the documentation for your Inventory.";
                DriverData *data = [del.surveyDB getDriverData];
                if(data.driverType == PVO_DRIVER_TYPE_DRIVER) {
                    defaults.agentEmail = data.driverEmail;
                    defaults.agentName = data.driverName;
                    self.agentEmailPlaceholder = @"Driver's Email";
                    self.agentNamePlaceholder = @"Driver's Name";
                } else if (data.driverType == PVO_DRIVER_TYPE_PACKER) {
                    defaults.agentEmail = data.packerEmail;
                    defaults.agentName = data.packerName;
                    self.agentEmailPlaceholder = @"Packer's Email";
                    self.agentNamePlaceholder = @"Packer's Name";
                }
            }
            
            defaults.toEmail = cust.email;
            
        }
        
        [self initializeRows];
        [self.tableView reloadData];
    }
    
    comingFromMailer = NO;
    
}


- (void)viewDidAppear:(BOOL)animated {
    
    gettingAPrinter = NO;
    
    [super viewDidAppear:animated];
}

-(BOOL)canSendFromDevice
{
    return [MFMailComposeViewController canSendMail] && [AppFunctionality allowSendingReportEmailFromDevice];
}

-(void)initializeRows
{
    if(rows == nil)
        rows = [[NSMutableArray alloc] init];
    
    [rows removeAllObjects];
    
    if(printType == PRINT_EMAIL)
    {
        BOOL canSendFromDevice = [self canSendFromDevice];
        if (canSendFromDevice)
            [rows addObject:[NSNumber numberWithInt:REPORT_SEND_FROM_DEVICE]];
        if (!canSendFromDevice || !defaults.sendFromDevice)
        {
            [rows addObject:[NSNumber numberWithInt:REPORT_EMAIL]];
            [rows addObject:[NSNumber numberWithInt:REPORT_NAME]];
        }
        [rows addObject:[NSNumber numberWithInt:REPORT_TO]];
        if (additionalEmails != nil && [additionalEmails count] > 0)
            for (int i=0;i<[additionalEmails count];i++)
                [rows addObject:[NSNumber numberWithInt:REPORT_ADDL_EMAIL_ROW]];
        if (ccEmails != nil && [ccEmails count] > 0)
            for (int i=0;i<[ccEmails count]; i++)
                [rows addObject:[NSNumber numberWithInt:REPORT_CC_EMAIL_ROW]];
        if (bccEmails != nil && [bccEmails count] > 0)
            for (int i=0;i<[bccEmails count];i++)
                [rows addObject:[NSNumber numberWithInt:REPORT_BCC_EMAIL_ROW]];
        [rows addObject:[NSNumber numberWithInt:REPORT_SUBJECT]];
        [rows addObject:[NSNumber numberWithInt:REPORT_BODY]];
    }
}

-(int)getRowTypeForRowIndex:(int)index inSection:(int)section
{
    if (section == 0 && printType == PRINT_EMAIL)
        return [[rows objectAtIndex:index] intValue];
    return index;
}

-(int)getArrayIndexForRowIndex:(int)index andRowType:(int)rowType
{
    if (rowType == REPORT_ADDL_EMAIL_ROW || rowType == REPORT_CC_EMAIL_ROW || rowType == REPORT_BCC_EMAIL_ROW)
        return index - [rows indexOfObject:[NSNumber numberWithInt:rowType]];
    return index; //isn't a row with an array
}

-(void) keyboardWillShow:(NSNotification *)note
{
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue: &keyboardBounds];
    keyboardHeight = keyboardBounds.size.height;
    if (keyboardIsShowing == NO)
    {
        keyboardIsShowing = YES;
        CGRect frame = self.view.frame;
        frame.size.height -= keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        self.view.frame = frame;
        [UIView commitAnimations];
    }
}

-(void) keyboardWillHide:(NSNotification *)note
{
    if (keyboardIsShowing == YES)
    {
        keyboardIsShowing = NO;
        CGRect frame = self.view.frame;
        frame.size.height += keyboardHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        self.view.frame = frame;
        [UIView commitAnimations];
    }
}

-(IBAction)printQualityChanged:(id)sender
{
    UISegmentedControl *ctl = sender;
    quality = ctl.selectedSegmentIndex;
}

-(IBAction)switchChanged:(id)sender
{
    //also used for color chage (switch cell)
    UISwitch *sw = sender;
    
    if (printType == PRINT_HARD_COPY)
        color = sw.on;
    else if (printType == PRINT_EMAIL)
    {
        defaults.sendFromDevice = sw.on;
        
        if (self.tboxCurrent != nil)
        {
            [self updateValueWithField:self.tboxCurrent];
            [self.tboxCurrent resignFirstResponder];
            self.tboxCurrent = nil;
        }
        [self initializeRows];
        [self.tableView reloadData];
    }
}

-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)print_SetProgressNumber
{
    NSString *str = nil;
    
    str = [NSString stringWithFormat:@"%ld / %lu", (long)printer.printPageNumber, (unsigned long)[pdfDrawer pageNumber]];
    
    labelPrintPage.text = str;
    progressPage.progress = printer.pageProgress;
    float    jobProgress = [printer jobProgress];
    if ( jobProgress >= 0 ) {
        progressJob.progress = jobProgress;
    }
}

- (void)print_PrintComplete:(NSNotification *)notification
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                         target:self
                                                                         action:@selector(done:)];
    self.navigationItem.leftBarButtonItem = btn;
    
    [timer invalidate];
    
    [activity stopAnimating];
    
    NSInteger result = [[notification object] integerValue];
    labelPrintPage.text = [NSString stringWithFormat:@"Done Printing Result : %ld", (long)result];
    labelLoading.text = @"Print Completed";
}


-(IBAction)options:(id)sender
{
    if(printType == PRINT_EMAIL)
    {
        
        if(tboxCurrent != nil)
        {
            [self updateValueWithField:tboxCurrent];
            [tboxCurrent resignFirstResponder];
        }
        
        UIActionSheet *as = nil;
        
        if([additionalEmails count] == 0)
            as = [[UIActionSheet alloc] initWithTitle:@"Options" 
                                             delegate:self 
                                    cancelButtonTitle:@"Cancel" 
                               destructiveButtonTitle:nil 
                                    otherButtonTitles:@"Save Values As Default",@"Add a Recipient", nil];
        else
            as = [[UIActionSheet alloc] initWithTitle:@"Options" 
                                             delegate:self 
                                    cancelButtonTitle:@"Cancel" 
                               destructiveButtonTitle:nil 
                                    otherButtonTitles:@"Save Values As Default",@"Add a Recipient", @"Remove Last Recipient", nil];
        
        [as showInView:self.view];
        
    }
}

-(void)updateValueWithField:(id)fld
{
    UIView *fldView = fld;
    int rowIndex = [fldView tag];
    int rowType = [self getRowTypeForRowIndex:rowIndex inSection:0];
    if (rowType == REPORT_EMAIL)
        defaults.agentEmail = [fld text];
    else if (rowType == REPORT_NAME)
        defaults.agentName = [fld text];
    else if (rowType == REPORT_TO)
        defaults.toEmail = [fld text];
    else if (rowType == REPORT_ADDL_EMAIL_ROW)
        [additionalEmails replaceObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType] withObject:[fld text]];
    else if (rowType == REPORT_CC_EMAIL_ROW)
        [ccEmails replaceObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType] withObject:[fld text]];
    else if (rowType == REPORT_BCC_EMAIL_ROW)
        [bccEmails replaceObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType] withObject:[fld text]];
    else if (rowType == REPORT_SUBJECT)
        defaults.body = [fld text];
    else if (rowType == REPORT_BODY)
        defaults.subject = [fld text];
}

-(IBAction)cancelPrint:(id)sender
{
    [printer printCancel];
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

-(void)printPDFFile:(StoredPrinter*)withPrinter
{
    
    if (brotherPrinterMode)
    {
        [activity stopAnimating];
        activity.hidden = YES;
        labelLoading.hidden = YES;
        
//        NSString *pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
        NSURL *pdfUrl = [NSURL fileURLWithPath:self.pdfPath];
        NSLog(@"PDF is ready for Brother print");
        
        NSLog(@"Beginning the manual print");
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.labelText = @"Printing report";
        hud.detailsLabelText = @"Please wait...";
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        [self printPDFManually:pdfUrl progressView:hud];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        NSLog(@"Ending the manual print");
        
        return;
    }
    
    if(withPrinter == nil)
    {
        [SurveyAppDelegate showAlert:@"Printer Not Found" withTitle:@"The selected printer is invalid, please retry print job."];
        [self done:nil];
        return;
    }
    
    //self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                         target:self
                                                                         action:@selector(cancelPrint:)];
    self.navigationItem.leftBarButtonItem = btn;
    
    NSDictionary *printSettingsDict = [CustomerUtilities getPrintSettings:withPrinter];
    
    
    if(printer == nil)
        printer = [[ePrint alloc] init];
    
    if(pdfDrawer == nil)
        pdfDrawer = [[PDFDraw alloc] init];
    
    if(self.pdfPath != nil)
        pdfDrawer.pdfPath = self.pdfPath;
    
    pdfDrawer.resolution = 300;
    
    [pdfDrawer setup];
    
    SEL calback = [pdfDrawer getCallback];
    
    
    [printer doPrint:printSettingsDict target:pdfDrawer callback:calback];
    
    
    activity.hidden = NO;
    [activity startAnimating];
    
    viewPrintProgress.hidden = NO;
    labelLoading.text = @"Printing Report";
    labelLoading.hidden = NO;
    
    progressJob.progress = 0;
    progressPage.progress = 0;
    labelPrintPage.text = @"";
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    timer = [NSTimer scheduledTimerWithTimeInterval:.1
                                             target:self
                                           selector:@selector(print_SetProgressNumber)
                                           userInfo:nil
                                            repeats:YES];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self initializeRows];
    [self.tableView reloadData];
}

-(void) updateEmailProgress:(NSString*)update
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    if(printType == PRINT_HARD_COPY)
    {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
    else
    {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        if (uploadProgress != nil)
        {
            [uploadProgress removeFromSuperview];
            uploadProgress = nil;
        }
        
        //let the pdf preview controller know to save the inventory data to server, TFS 22450 upload data after print or emailing report
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([del.pricingDB vanline] == ATLAS)
        {
            if(delegate != nil && [delegate respondsToSelector:@selector(emailFinishedSending:withUpdate:)])
                [delegate emailFinishedSending:self withUpdate:update];
        }
        else
        {
            //prompt them to save email if different
            [SurveyAppDelegate showAlert:update withTitle:@"Email"];
        }
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        
        if(![cust.email isEqualToString:defaults.toEmail])
        {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Email Address" message:@"The email address entered is different from the email address stored for this customer.  Would you like to update the customer's email address with this email address?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            
            [av show];
            return;
        }
    }

    //if(!docAlreadyFinishedProcessing
    [self documentProcessed];
    
    //[self done:nil];
}

-(void)documentProcessed
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([del.pricingDB vanline] == ARPIN && uploader != nil)
    {
        //if it is Arpin interstate, we used to regenerate the report for the cover sheet
        //now, we upload it as is, and set a Request object flag to have the cover sheet inserted in the sync service
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        if (cust.pricingMode == 0)
            del.uploadingArpinDoc = [del.pricingDB vanline] == ARPIN;
        
        int additionalParamInfo = pvoNavItemID;
        
        uploader.delegate = self;
        [uploader uploadDocument:pvoReportTypeID withAdditionalInfo:additionalParamInfo];
    }
    else if(printType == PRINT_EMAIL)
        [self done:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];    
    
    
    [super viewWillDisappear:animated];
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

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    //either email values, or print quality options
    if(activity.hidden)
        return 2;
    else
        return 0;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    if(section == 0 && printType == PRINT_EMAIL)
        return [rows count];
    else if(section == 0 && printType == PRINT_HARD_COPY)
        return 2;//for quality and color
    else
        return 1;//print/send email
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(printType == PRINT_EMAIL && [indexPath section] == 0 &&
       [self getRowTypeForRowIndex:indexPath.row inSection:indexPath.section] == REPORT_BODY)
        return 130;
    else
        return 44;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    if(printType == PRINT_EMAIL && section == 0)
        return @"Email Setup";
    else if(printType == PRINT_HARD_COPY && section == 0)
        return @"Print Quality";
    else
        return nil;
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *NoteCellIdentifier = @"NoteCell";
    static NSString *OrigDestCellIdentifier = @"OrigDestCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
    UITableViewCell *cell = nil;
    TextCell *textCell = nil;
    NoteCell *noteCell = nil;
    OrigDestCell *odCell = nil;
    SwitchCell *switchCell = nil;
    
    if(printType == PRINT_HARD_COPY && indexPath.section == 0)
    {//give them quality and color options
        
        if(indexPath.row == 0)
        {
            odCell = (OrigDestCell*)[tableView dequeueReusableCellWithIdentifier:OrigDestCellIdentifier];
            if(odCell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrigDestCell" owner:self options:nil];
                odCell = [nib objectAtIndex:0];
                odCell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            [odCell.segmentOrigDest removeAllSegments];
            [odCell.segmentOrigDest removeTarget:self 
                                          action:@selector(printTypeChanged:) 
                                forControlEvents:UIControlEventValueChanged];
            [odCell.segmentOrigDest removeTarget:self 
                                          action:@selector(printQualityChanged:) 
                                forControlEvents:UIControlEventValueChanged];
            
            [odCell.segmentOrigDest insertSegmentWithTitle:@"High" atIndex:0 animated:NO];
            [odCell.segmentOrigDest insertSegmentWithTitle:@"Normal" atIndex:0 animated:NO];
            [odCell.segmentOrigDest insertSegmentWithTitle:@"Draft" atIndex:0 animated:NO];
            StoredPrinter *defPrint = [del.surveyDB getDefaultPrinter];
            if(defPrint != nil)
            {
                odCell.segmentOrigDest.selectedSegmentIndex = defPrint.quality;
            }
            else
            {
                odCell.segmentOrigDest.selectedSegmentIndex = quality;
            }
            [odCell.segmentOrigDest addTarget:self
                                       action:@selector(printQualityChanged:) 
                             forControlEvents:UIControlEventValueChanged];
        }
        else 
        {//color switch
            switchCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
            
            if (switchCell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
                switchCell = [nib objectAtIndex:0];
                
                [switchCell.switchOption addTarget:self
                                            action:@selector(switchChanged:) 
                                  forControlEvents:UIControlEventValueChanged];
            }
            switchCell.switchOption.tag = indexPath.section;
            switchCell.switchOption.on = color;
            switchCell.labelHeader.text = @"Color";
        }
    }
    else if(printType == PRINT_EMAIL && indexPath.section == 0)
    {
        int rowIndex = indexPath.row;
        int rowType = [self getRowTypeForRowIndex:indexPath.row inSection:indexPath.section];
        if (rowType == REPORT_SEND_FROM_DEVICE) {
            switchCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
            if (switchCell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
                switchCell = [nib objectAtIndex:0];
                
                [switchCell.switchOption addTarget:self
                                            action:@selector(switchChanged:)
                                  forControlEvents:UIControlEventValueChanged];
            }
            switchCell.switchOption.tag = indexPath.section;
            switchCell.switchOption.on = defaults.sendFromDevice;
            switchCell.switchOption.enabled = YES;
            switchCell.labelHeader.text = @"Send From Device";
        } else if(rowType == REPORT_BODY) {
            noteCell = (NoteCell*)[tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
            if(noteCell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
                noteCell = [nib objectAtIndex:0];
                noteCell.accessoryType = UITableViewCellAccessoryNone;
                noteCell.tboxNote.delegate = self;
            }
            
            noteCell.tboxNote.tag = [indexPath row];
            noteCell.tboxNote.text = defaults.body;
        } else {
            textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
            if(textCell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
                textCell = [nib objectAtIndex:0];
                textCell.accessoryType = UITableViewCellAccessoryNone;
                textCell.tboxValue.delegate = self;
            }
            textCell.tboxValue.tag = [indexPath row];
            textCell.tboxValue.enabled = YES;
            
            textCell.tboxValue.returnKeyType = UIReturnKeyDone;
            [textCell.tboxValue addTarget:self 
                                   action:@selector(doneEditingText:) 
                         forControlEvents:UIControlEventEditingDidEndOnExit];
            
            if (rowType == REPORT_EMAIL) {
                textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.text = defaults.agentEmail;
                textCell.tboxValue.placeholder = self.agentEmailPlaceholder;
            } else if (rowType == REPORT_NAME) {
                textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                textCell.tboxValue.text = defaults.agentName;
                textCell.tboxValue.placeholder = self.agentNamePlaceholder;
            } else if (rowType == REPORT_TO) {
                textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.text = defaults.toEmail;
                textCell.tboxValue.placeholder = @"Customer's Email";
            } else if (rowType == REPORT_ADDL_EMAIL_ROW) {
                textCell.tboxValue.text = [additionalEmails objectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]];
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.placeholder = @"Add'l Recipient";
            } else if (rowType == REPORT_CC_EMAIL_ROW) {
                textCell.tboxValue.text = [NSString stringWithFormat:@"CC: %@", [ccEmails objectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]]];
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.placeholder = @"CC Email";
                textCell.tboxValue.enabled = NO;
            } else if (rowType == REPORT_BCC_EMAIL_ROW) {
                textCell.tboxValue.text = [NSString stringWithFormat:@"BCC: %@", [bccEmails objectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]]];
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.placeholder = @"BCC Email";
                textCell.tboxValue.enabled = NO;
            } else if (rowType == REPORT_SUBJECT) {
                textCell.tboxValue.text = defaults.subject;
                textCell.tboxValue.placeholder = @"Email Subject";
            }
        }
    }
    else if(indexPath.row == 0 && indexPath.section == 1)
    {
        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if(printType == PRINT_HARD_COPY)
            cell.textLabel.text = @"Print Report";
        else
        {
            if ([self canSendFromDevice] && defaults.sendFromDevice)
                cell.textLabel.text = @"Generate Email";
            else
                cell.textLabel.text = @"Send Email";
        }
        
        
    }
    else if(printType == PRINT_EMAIL && indexPath.row == 1 && indexPath.section == 1)
    {
        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.text = @"Send to Self";
        
    }
    
    return cell != nil ? cell : 
    noteCell != nil ? (UITableViewCell*)noteCell : 
    textCell != nil ? (UITableViewCell*)textCell : 
    switchCell != nil ? (UITableViewCell*)switchCell :
    odCell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (printType == PRINT_EMAIL && indexPath.section == 0)
    {
        int rowType = [self getRowTypeForRowIndex:indexPath.row inSection:indexPath.section];
        switch (rowType) {
            case REPORT_ADDL_EMAIL_ROW:
            case REPORT_CC_EMAIL_ROW:
            case REPORT_BCC_EMAIL_ROW:
                return YES;
            default:
                return NO;
        }
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (printType == PRINT_EMAIL && indexPath.section == 0)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            BOOL reload = NO;
            int rowIndex = indexPath.row;
            int rowType = [self getRowTypeForRowIndex:rowIndex inSection:indexPath.section];
            if (rowType == REPORT_ADDL_EMAIL_ROW)
            {
                [additionalEmails removeObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]];
                reload = YES;
            }
            else if (rowType == REPORT_CC_EMAIL_ROW)
            {
                [ccEmails removeObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]];
                reload = YES;
            }
            else if (rowType == REPORT_BCC_EMAIL_ROW)
            {
                [bccEmails removeObjectAtIndex:[self getArrayIndexForRowIndex:rowIndex andRowType:rowType]];
                reload = YES;
            }
            if (reload)
            {
                if (tboxCurrent != nil && [(UIView*)tboxCurrent tag] == indexPath.row)
                {
                    [tboxCurrent removeTarget:self action:@selector(doneEditingText:) forControlEvents:UIControlEventEditingDidEndOnExit]; //remove done editing call
                    [tboxCurrent setDelegate:nil]; //clear delegate
                    tboxCurrent = nil; //clear editing row, don't care about it anymore
                }
                [self initializeRows];
                [self.tableView reloadData];
            }
        }
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if(indexPath.section == 1 && printType == PRINT_EMAIL)
    {
        BOOL isSendFromDevice = [self canSendFromDevice] && defaults.sendFromDevice;
        
        if(defaults.toEmail == nil || [defaults.toEmail length] == 0 ||
            (!isSendFromDevice && (defaults.agentEmail == nil || [defaults.agentEmail length] == 0)))
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"You must have a %@to email address entered to email a report.",
                                          isSendFromDevice ? @"from and " : @""]
                               withTitle:@"Email Required"];
            return;
        }
        
        for (NSString *addEmail in additionalEmails) {
            if (addEmail == nil || [addEmail isEqualToString:@""])
            {
                [SurveyAppDelegate showAlert:@"All email addresses must be entered to email a report." withTitle:@"Email Required"];
                return;
            }
        }
        
        if (isSendFromDevice)
        {
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            mailer.mailComposeDelegate = self;
            
            [mailer setSubject:[NSString stringWithFormat:@"%@", defaults.subject == nil ? @"" : defaults.subject]];
            NSMutableArray *recipients = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"%@", defaults.toEmail], nil];
            if (additionalEmails != nil && [additionalEmails count] > 0)
                for (NSString *addlEmail in additionalEmails)
                    if (addlEmail != nil && [addlEmail length] > 0)
                        [recipients addObject:[NSString stringWithFormat:@"%@", addlEmail]];
            [mailer setToRecipients:recipients];
            if (ccEmails != nil && [ccEmails count] > 0)
            {
                recipients = [[NSMutableArray alloc] init];
                for (NSString *ccEmail in ccEmails)
                    if (ccEmail != nil && [ccEmail length] > 0)
                        [recipients addObject:[NSString stringWithFormat:@"%@", ccEmail]];
                if ([recipients count] > 0)
                    [mailer setCcRecipients:recipients];
            }
            if (bccEmails != nil && [bccEmails count] > 0)
            {
                recipients = [[NSMutableArray alloc] init];
                for (NSString *bccEmail in bccEmails)
                    if (bccEmail != nil && [bccEmail length] > 0)
                        [recipients addObject:[NSString stringWithFormat:@"%@", bccEmail]];
                if ([recipients count] > 0)
                    [mailer setBccRecipients:recipients];
            }
            
            [mailer setMessageBody:[NSString stringWithFormat:@"%@", defaults.body == nil ? @"" : defaults.body] isHTML:NO];
            
            [mailer addAttachmentData:[NSData dataWithContentsOfFile:pdfPath] mimeType:@"application/pdf" fileName:@"report.pdf"];
            
            comingFromMailer = YES;
            [self presentViewController:mailer animated:YES completion:NULL];
            
            return;
        }
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        GetReport *reportObject = [[GetReport alloc] init];
        reportObject.emailReport = TRUE;
        reportObject.caller = self;
        reportObject.updateCallback = @selector(updateEmailProgress:);
        reportObject.option = reportOption;
        reportObject.defaults = defaults;
        reportObject.additionalEmails = additionalEmails;
        reportObject.ccEmails = ccEmails;
        reportObject.bccEmails = bccEmails;
        reportObject.pvoNavItemID = self.pvoNavItemID;
        
        if (reportOption.htmlSupported)
        {
            reportObject.requestDelegate = self;
            reportObject.pdfFilesToSend = [NSDictionary dictionaryWithObject:pdfPath forKey:@"report.pdf"];
            uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Emailing Report" andProgressBar:YES];
        }
        else
        {
            reportObject.requestDelegate = nil;
            
            labelLoading.text = @"Generating/Emailing Document";
            
            activity.hidden = FALSE;
            labelLoading.hidden = FALSE;
            [activity startAnimating];
        }
        
        [del.operationQueue addOperation:reportObject];
        
        [self.tableView reloadData];
        
        
    }
    else if(indexPath.section == 1 && printType == PRINT_HARD_COPY)
    {
        
        if (brotherPrinterMode)
        {
            [activity stopAnimating];
            activity.hidden = YES;
            labelLoading.hidden = YES;
            
            NSURL *pdfUrl = [NSURL fileURLWithPath:pdfPath];
            NSLog(@"PDF is ready for Brother print");
            
            NSLog(@"Beginning the manual print");
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeDeterminate;
            hud.labelText = @"Printing report";
            hud.detailsLabelText = @"Please wait...";
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
            [self printPDFManually:pdfUrl progressView:hud];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSLog(@"Ending the manual print");
            
            return;
        }
        else
        {
            if ([AppFunctionality useAirPrintForPrinting])
            {
                //airprint right here, actually no - don't even need the process form
                UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
                printController.showsPageRange = YES;
                
                NSString *pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
                if([UIPrintInteractionController canPrintURL:[NSURL fileURLWithPath:pdfPath]])
                {
                    printController.printingItem = [NSURL fileURLWithPath:pdfPath];
                    [printController presentAnimated:YES completionHandler:nil];
        //            [printController presentFromBarButtonItem:actionButton
        //                                             animated:YES
        //                                    completionHandler:nil];
                }
                else
                    [SurveyAppDelegate showAlert:@"Cannot print document." withTitle:@"Print Error"];
            }
            else
            {
                [UIApplication sharedApplication].idleTimerDisabled = YES;
                self.navigationItem.rightBarButtonItem.enabled = NO;
                
                self.navigationItem.leftBarButtonItem.enabled = NO;
                
                if(getPrinter == nil)
                    getPrinter = [[GetPrinterController alloc] initWithStyle:UITableViewStyleGrouped];
                
                gettingAPrinter = TRUE;
                
                PortraitNavController *navCtl = [[PortraitNavController alloc] initWithRootViewController:getPrinter];
                [self.navigationController presentViewController:navCtl animated:YES completion:nil];/// getPrinter
            }
        }
        
        
    }
}

#pragma mark - Brother printer methods
    
-(void) printPDFUsingProgressView: (NSURL *)pdfURL
{
    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    
    if (pdfPageCount > 0)
    {
        // print using the Progress View.
        if(pj673PrintSettings.IPAddress == nil || pj673PrintSettings.IPAddress.length == 0)
        {
            [SurveyAppDelegate showAlert:@"Please enter the IP Address for your printer from the Maintenance menu on the Customers screen." withTitle:@"IP Address Required"];
            return;
        }
        
        BRPtouchPrinter *ptp = [[BRPtouchPrinter alloc] initWithPrinterName:@"Brother PJ-673"];
        
        [ptp setIPAddress:pj673PrintSettings.IPAddress];
        
        [ptp setPrintInfo:[PJ673PrintSettings defaultPrintInfo]];
        
        NSUInteger pageIndexes[] = {0};
        if ([ptp isPrinterReady])
            [ptp printPDFAtPath:pdfURL.path pages:pageIndexes length:0 copy:1 timeout:500];
        else
            [SurveyAppDelegate showAlert:@"Please check network settings, and connection with printer." withTitle:@"Printer Not Ready"];
        
    }
}

-(void) printPDFManually:(NSURL *)pdfURL progressView:(MBProgressHUD *)hud
{
    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    
    if (pdfPageCount > 0)
    {
        // print using the Progress View.
        if(pj673PrintSettings.IPAddress == nil || pj673PrintSettings.IPAddress.length == 0)
        {
            [SurveyAppDelegate showAlert:@"Please enter the IP Address for your printer from the Maintenance menu on the Customers screen." withTitle:@"IP Address Required"];
            return;
        }
        
        BRPtouchPrinter *ptp = [[BRPtouchPrinter alloc] initWithPrinterName:@"Brother PJ-673"];
        
        [ptp setIPAddress:pj673PrintSettings.IPAddress];
        
        [ptp setPrintInfo:[PJ673PrintSettings defaultPrintInfo]];
        
        NSUInteger pageIndexes[] = {0};
        if ([ptp isPrinterReady])
            [ptp printPDFAtPath:pdfURL.path pages:pageIndexes length:0 copy:1 timeout:500];
        else
            [SurveyAppDelegate showAlert:@"Please check network settings, and connection with printer." withTitle:@"Printer Not Ready"];
        
    }
}

//-(void)updateFromGetReport:(NSString*)result
//{
//    
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
//    if(![result isEqualToString:@"start printing disconnected"] &&
//       ![result isEqualToString:@"Successfully saved file."])
//    {
//        [SurveyAppDelegate showAlert:result withTitle:@"Upload Generate Error"];
//        
//    }
//    else
//        [uploader uploadDocument:pvoReportTypeID];
//    
//}


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

-(IBAction)doneEditingText:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
    self.tboxCurrent = nil;
}

#pragma mark Text View Delegate Methods

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.tboxCurrent = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self updateValueWithField:textView];
    self.tboxCurrent = nil;
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != actionSheet.cancelButtonIndex)
    {
        if(buttonIndex == 0)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            [del.surveyDB saveReportDefaults:defaults];
        }
        else if(buttonIndex == 1)
        {
            [additionalEmails addObject:@""];
            [self initializeRows];
            [tableView reloadData];
        }
        else if(buttonIndex == 2)
        {
            [additionalEmails removeLastObject];
            [self initializeRows];
            [tableView reloadData];
        }
    }
}

#pragma mark - PVOUploadReportViewDelegate methods

-(void)uploadCompleted:(PVOUploadReportView*)uploadReportView
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.uploadingArpinDoc = NO;
    [self done:nil];
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        cust.email = defaults.toEmail;
        [del.surveyDB updateCustomer:cust];
    }
    //always finish
    [self documentProcessed];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultFailed)
            [SurveyAppDelegate showAlert:@"Send Failed, unable to send email." withTitle:@"Unable To Email"];
        else if (result != MFMailComposeResultCancelled)
            [self updateEmailProgress:[NSString stringWithFormat:@"Email successfully %@.", result == MFMailComposeResultSaved ? @"saved" : @"sent"]];
    }];
}

#pragma mark - WebSyncRequestDelegate methods

-(void)progressUpdate:(WebSyncRequest *)request isResponse:(BOOL)isResponse withBytesSent:(NSInteger)sent withTotalBytes:(NSInteger)total
{
    if (uploadProgress != nil)
    {
        double percentForRequest = 0.85f; //percentage of the progress bar to use for the request (upload)
        double progress = (sent * 1.0f) / (total * 1.0f);
        if (isResponse)
            [uploadProgress updateProgressBar:(percentForRequest + (progress * (1. - percentForRequest)))];
        else
            [uploadProgress updateProgressBar:progress * percentForRequest];
        
#ifdef TARGET_IPHONE_SIMULATOR
        NSLog(@"Sent:%f of Total:%f Percent:%f", (sent / 1.0f), (total / 1.0f), progress * percentForRequest);
#endif
    }
}

-(void)completed:(WebSyncRequest *)request withSuccess:(BOOL)success andData:(NSString *)response
{
    if (uploadProgress != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [uploadProgress removeFromSuperview];
            uploadProgress = nil;
        });
    }
}

#pragma mark - PJ673PrintSettingsDelegate methods

-(void)pj673SettingsFoundReadyPrinter:(NSNumber*)printerFound
{
    brotherPrinterMode = [printerFound boolValue];
    
    if (brotherPrinterMode)
    {
        NSLog(@"brother mode");
        self.pj673PrintSettings = [[PJ673PrintSettings alloc] init];
        [pj673PrintSettings loadPreferences];
    }
    
    [self initializeScreen];
}

@end

