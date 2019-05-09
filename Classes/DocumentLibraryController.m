//
//  DocumentLibraryController.m
//  Survey
//
//  Created by Tony Brame on 5/22/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "DocumentLibraryController.h"
#import "SurveyAppDelegate.h"
#import "ButtonCell.h"
#import "DocumentCell.h"
#import "ZipArchive.h"

#define SEGMENT_CUSTOMER        0
#define SEGMENT_REFERENCE       1

@implementation DocumentLibraryController

@synthesize emailSent, selectedReports;

- (void)redraw
{
    if (selectedReports == nil)
        selectedReports = [[NSMutableArray alloc] init];
    
    if ([selectedReports count] > 0 && emailSent)
    {
        self.navigationItem.rightBarButtonItem = nil;
        [selectedReports removeAllObjects];
        
    }
    
    if (selectedSegment == SEGMENT_CUSTOMER)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                target:self
                                                                                                action:@selector(addDocument:)];
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (selectedSegment == SEGMENT_CUSTOMER)
    {
        self.docs = [NSMutableArray arrayWithArray:[del.surveyDB getCustomerDocs:_customerID]];
    }
    else
    {
        BOOL sourcedFromServer = NO;
        if (_customerID > 0){
            ShipmentInfo *info = [del.surveyDB getShipInfo:_customerID];
            sourcedFromServer = info.sourcedFromServer;
            
        }
        self.docs = [NSMutableArray arrayWithArray:[del.surveyDB getGlobalDocs:sourcedFromServer ? [del.pricingDB vanline] : -1]];
        
    }
    
//    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cmdCancelClick:)];
//    ShipmentInfo* shipInfo = [del.surveyDB getShipInfo:_customerID];
    
    self.title = @"Documents";
    
    if (_customerMode)
    {
        selectedSegment = SEGMENT_CUSTOMER;
        NSArray *itemArray = @ [ @"Customer", @"Reference" ];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        segmentedControl.frame = CGRectMake(0.0, 0.0, 240.0, 30.0);
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentedControl.selectedSegmentIndex = selectedSegment;
        [segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
        UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
        UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

        self.toolbarItems = @ [ flex1, item, flex2 ];
    }
    else
    {
        selectedSegment = SEGMENT_REFERENCE;
    }
}

- (void)segmentedControlChanged:(UISegmentedControl *)segment
{
    selectedSegment = segment.selectedSegmentIndex;
    if (selectedSegment == SEGMENT_CUSTOMER)
    {
        //NSLog(@"Customer selected");
    }
    else
    {
        //NSLog(@"Reference selected");
    }
    
    if ([selectedReports count] > 0 && selectedSegment == SEGMENT_CUSTOMER)
    {
        self.navigationItem.rightBarButtonItems = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Email" style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(sendEmail:)];
    }
    else if ([selectedReports count] > 0 && selectedSegment == SEGMENT_REFERENCE)
    {
        self.navigationItem.rightBarButtonItem = nil;
        UIBarButtonItem *email = [[UIBarButtonItem alloc] initWithTitle:@"Email" style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(sendEmail:)];
        
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(addDocument:)];
        self.navigationItem.rightBarButtonItems = @ [add, email];
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    [self redraw];
}

-(IBAction)cmdCancelClick:(id)sender
{
    if (_customerMode)
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.navigationController.toolbarHidden = YES;            
        } completion:^(BOOL finished) {
            if (_specialSurveyHDMode)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
    else
    {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    if (_customerMode)
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.navigationController.toolbarHidden = NO;
        }];
    }
    
    [self redraw];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)addDocument:(id)sender
{
    //load screen to enter values.
    if(self.addDocController == nil)
        self.addDocController = [[AddDocLibEntryController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [self.navigationController pushViewController:self.addDocController animated:YES];
    
}

-(IBAction)refreshAllDocuments:(id)sender
{
    //here it is...
    //loop through all documents, and save each
    currentIdx = 0;
    DocLibraryEntry *entry = [self.docs objectAtIndex:currentIdx];
    while (entry != nil && (entry.url == nil || [entry.url isEqualToString:@""])) {
        currentIdx++;
        if (currentIdx == [self.docs count])
            entry = nil;
        else
            entry = [self.docs objectAtIndex:currentIdx];
    }
    
    if (entry != nil) {
        entry.delegate = self;
        [entry downloadDoc];
    } else {
        [SurveyAppDelegate showAlert:@"No Online documents available to refresh." withTitle:@"Refresh"];
    }
}

-(void)dealloc
{
    self.docs = nil;
    self.deletePath = nil;
    self.addDocController = nil;
    self.previewController = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (selectedSegment == SEGMENT_CUSTOMER)
    {
        return 1;
    }
    else
    {
        return self.docs.count == 0 ? 1 : 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return section == 0 ? [self.docs count] : 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && self.docs.count == 0)
    {
        if (selectedSegment == SEGMENT_CUSTOMER)
        {
            return @"No documents found for this customer.";
        }
        else
        {
            return @"No documents found, tap the + button to add a new document.";
        }
    }
    
//    if(section == 1)
//        return @"This option is used to redownload all documents to your device with the latest version contained at the URL.";
//    else
    
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
//    if(section == 1 || (section == 0 && self.docs.count == 0))
//        return [UIImage imageNamed:@"atlas_Loop_Logo.png"].size.height;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *CellIdentifier = @"Cell";
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    static NSString *CustomButtonCellIdentifier = @"CustomButtonCell";
    static NSString *DocumentCellID = @"DocumentCell";
    
    ButtonCell *buttonCell = nil;
    DocumentCell *cell = nil;
    UITableViewCell *cellButton = nil;
    
    if(indexPath.section == 0)
    {
        if ([SurveyAppDelegate iOS7OrNewer])
        {
            [tableView setSeparatorColor:[UIColor lightGrayColor]];
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        }
        
        cell = (DocumentCell*)[tableView dequeueReusableCellWithIdentifier:DocumentCellID]; //cellidentifier
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DocumentCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        DocLibraryEntry *entry = [self.docs objectAtIndex:indexPath.row];
        if (![selectedReports containsObject:[self.docs objectAtIndex:indexPath.row]])
            cell.tboxCheck.hidden = TRUE;
        cell.tboxDocumentsLabel.text = entry.docName;
        
        //if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
        //    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        //else
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        
        if (selectedSegment == SEGMENT_CUSTOMER)
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"M/d/yyyy h:mm a"];
            cell.tboxDocuments.text = [formatter stringFromDate:entry.savedDate];
        }
        else
        {
            if(entry.url != nil && entry.url.length != 0)
                cell.tboxDocuments.text = entry.url;
            else
                cell.tboxDocuments.text = @"";
        }
    }
    else
    {
        if ([SurveyAppDelegate iOS7OrNewer])
        {
            [tableView setSeparatorColor:[UIColor clearColor]];
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
            cellButton = [tableView dequeueReusableCellWithIdentifier:CustomButtonCellIdentifier];
            if (cellButton == nil) {
                cellButton = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomButtonCellIdentifier];
                
                [cellButton setBackgroundColor:[UIColor lightGrayColor]];
                [cellButton.textLabel setTextColor:[UIColor blackColor]];
                [cellButton.textLabel setTextAlignment:NSTextAlignmentCenter];
                
                cellButton.accessoryType = UITableViewCellAccessoryNone;
                cellButton.textLabel.text = @"Refresh All Documents";
            }
        }
        else
        {
            buttonCell = (ButtonCell*)[tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
            if(buttonCell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
                buttonCell = [nib objectAtIndex:0];
                buttonCell.accessoryType = UITableViewCellAccessoryNone;
                
                [buttonCell.cmdButton setBackgroundImage:[[UIImage imageNamed:@"whiteButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.] forState:UIControlStateNormal];
                [buttonCell.cmdButton setBackgroundImage:[[UIImage imageNamed:@"blueButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.] forState:UIControlStateHighlighted];
                
                [buttonCell.cmdButton setTitle:@"Refresh All Documents" forState:UIControlStateNormal];
                
                [buttonCell.cmdButton addTarget:self action:@selector(refreshAllDocuments:) forControlEvents:UIControlEventTouchUpInside];
                
                [buttonCell.cmdButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [buttonCell.cmdButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
                
                UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
                backView.backgroundColor = [UIColor clearColor];
                buttonCell.backgroundView = backView;
            }
        }
    }
	
    return cell != nil ? cell : (cellButton != nil ? cellButton : buttonCell);
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        self.deletePath = indexPath;
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                     message:@"Are you sure you would like to delete this document?"
                                                    delegate:self
                                           cancelButtonTitle:@"No"
                                           otherButtonTitles:@"Yes", nil];
        [av show];
    }
}




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

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0){
        
        if(self.previewController == nil)
            self.previewController = [[PreviewPDFController alloc] initWithNibName:@"PreviewPDF" bundle:nil];
        
        self.previewController.noSignatureAllowed = YES;
        self.previewController.noSaveOptionsAllowed = YES;
        self.previewController.hideActionsOptions = YES;
        
        DocLibraryEntry *entry = [self.docs objectAtIndex:indexPath.row];
        self.previewController.pdfPath = [entry fullDocPath];
        
        [self.navigationController pushViewController:self.previewController animated:YES];
        
        entry = nil;
        
    }
    
    //holdView = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //open up the preview...
    if(selectedSegment == SEGMENT_CUSTOMER && _customerMode)
    {
        DocumentCell *dcell = (DocumentCell *)[tableView cellForRowAtIndexPath:indexPath];
        
//        DocLibraryEntry *entry = [self.docs objectAtIndex:indexPath.row];
        
        
        if([selectedReports containsObject:[self.docs objectAtIndex:indexPath.row]])
        {
            //uitvc.accessoryType = UITableViewCellAccessoryNone;
            dcell.tboxCheck.hidden = TRUE;
            [selectedReports removeObject:[self.docs objectAtIndex:indexPath.row]];
        }
        else
        {
            //uitvc.accessoryType = UITableViewCellAccessoryCheckmark;
            dcell.tboxCheck.hidden = FALSE;
            [selectedReports addObject:[self.docs objectAtIndex:indexPath.row]];
        }
        
//        entry = nil;
//        [entry release];
    }
    else if(selectedSegment == SEGMENT_REFERENCE || !_customerMode)
    {
        if(indexPath.section == 0) {
            DocumentCell *dcell = (DocumentCell *)[tableView cellForRowAtIndexPath:indexPath];
            
            //          DocLibraryEntry *entry = [self.docs objectAtIndex:indexPath.row];
            
            
            if([selectedReports containsObject:[self.docs objectAtIndex:indexPath.row]])
            {
                //uitvc.accessoryType = UITableViewCellAccessoryNone;
                dcell.tboxCheck.hidden = TRUE;
                [selectedReports removeObject:[self.docs objectAtIndex:indexPath.row]];
            }
            else
            {
                //uitvc.accessoryType = UITableViewCellAccessoryCheckmark;
                dcell.tboxCheck.hidden = FALSE;
                [selectedReports addObject:[self.docs objectAtIndex:indexPath.row]];
            }
        }
        else {
            // added 3/19/16 to fix defect #14171 BBoat
            int row = indexPath.row;
            if (row == 0)
                [self refreshAllDocuments:nil];
            
        }
    }
    if ([selectedReports count] > 0 && selectedSegment != SEGMENT_REFERENCE)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Email" style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(sendEmail:)];
    }
    else if ([selectedReports count] > 0 && (selectedSegment == SEGMENT_REFERENCE || !_customerMode))
    {
        UIBarButtonItem *email = [[UIBarButtonItem alloc] initWithTitle:@"Email" style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(sendEmail:)];
        
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(addDocument:)];
        self.navigationItem.rightBarButtonItems = @ [add, email];
    }
    else if ([selectedReports count] == 0 && (selectedSegment == SEGMENT_REFERENCE))
    {
        self.navigationItem.rightBarButtonItems = nil;
        self.navigationItem.rightBarButtonItem = nil;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                target:self
                                                                                                action:@selector(addDocument:)];
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
    
}

-(IBAction)sendEmail:(id)sender
{
    if (_customerMode){
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Select a Recipient"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Send to Self", @"Send to Customer", nil];
        [as showInView:self.view];
    }
    else
        [self processEmail];
}

-(void)processEmail
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    defaults = [del.surveyDB getReportDefaults];
    NSMutableArray *temparray = [[NSMutableArray alloc] init];
    NSString *fromEmail;
    NSString *fromName;
    NSString *body;
    NSString *subject;
    
    tempobj = [[TempEmail alloc] init];
    
    if (sendee == SEND_TO_AGENT )
    {
        tempobj.toEmail = defaults.agentEmail;
        tempobj.toName = defaults.agentName;
        fromEmail = cust.email;
        fromName = cust.lastName;
        
        body = [NSString stringWithFormat:@"Attached is the documentation for the following customer: \n %@", fromName];
        if (_customerMode){
            body = [NSString stringWithFormat:@"Attached is the documentation for the following customer: \n %@", fromName];
            subject = [NSString stringWithFormat:@"%@'s Inventory Documentation", fromName];
        }
        else{
            body = [NSString stringWithFormat:@"Attached is the reference documentation for Inventory"];
            subject = [NSString stringWithFormat:@"Reference Documentation"];
        }
    }
    else if (sendee == SEND_TO_CUSTOMER)
    {
        tempobj.toEmail = cust.email;
        tempobj.toName = cust.lastName;
        fromEmail = defaults.agentEmail;
        fromName = defaults.agentName;
        body = defaults.body;
        subject = defaults.subject;
    }
    
    if (tempobj.toEmail != nil)
        [temparray addObject:tempobj.toEmail];
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        mailer.mailComposeDelegate = self;
        
        [mailer setSubject:subject];
        
        
        if ([temparray count] > 0)
            [mailer setToRecipients:temparray];
        
        //        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        ZipArchive *zipper = [[ZipArchive alloc] init];
        NSString *zipPath = [docsDir stringByAppendingPathComponent:@"inventoryDocuments.zip"];
        [zipper CreateZipFile2:zipPath];
        int i = 0;
        for (i = 0; i < [selectedReports count]; i++)
        {
            DocLibraryEntry *temp = [selectedReports objectAtIndex:i];
            NSLog(@"temppath = '%@'", temp.docPath);
            
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyyMMddhhmmss"];
            
            NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
            NSString *correctedName = [[temp.docName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
            correctedName = [correctedName stringByReplacingOccurrencesOfString:@" " withString:@"-"];
            NSString *dateAdded = [correctedName stringByAppendingString:[NSString stringWithFormat:@"-%@", [formatter stringFromDate:temp.savedDate]]];
            NSLog(@"correctedName  = %@", dateAdded);
            [zipper addFileToZip:[docsDir stringByAppendingPathComponent:temp.docPath] newname:[NSString stringWithFormat:@"%@.pdf",dateAdded]];
            
        }
        [zipper CloseZipFile2];
        
        NSData *file = [NSData dataWithContentsOfFile:zipPath];
        [mailer addAttachmentData:file mimeType:@"application/zip" fileName:@"inventoryDocuments.zip"];
        
        
        [mailer setMessageBody:body isHTML:NO];
        
        [self presentViewController:mailer animated:YES completion:nil];
        
        
    }
    
    tempobj = nil;
    temparray = nil;
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        [del.surveyDB deleteDocLibraryEntry:[self.docs objectAtIndex:self.deletePath.row]];
        [self.docs removeObject:[self.docs objectAtIndex:self.deletePath.row]];
        
        if(self.docs.count > 0)
            [self.tableView deleteRowsAtIndexPaths:@[self.deletePath] withRowAnimation:UITableViewRowAnimationFade];
        else
        {
            //            [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - DocumentLibraryEntryDelegate methods

-(void)documentDownloaded:(DocLibraryEntry *)entry
{
    currentIdx++;
    if(currentIdx < self.docs.count)
    {
        DocLibraryEntry *entry = [self.docs objectAtIndex:currentIdx];
        while (entry != nil && (entry.url == nil || [entry.url isEqualToString:@""])) {
            currentIdx++;
            if (currentIdx == [self.docs count])
                entry = nil;
            else
                entry = [self.docs objectAtIndex:currentIdx];
        }
        if (entry != nil) {
            entry.delegate = self;
            [entry downloadDoc];
        } else {
            [SurveyAppDelegate showAlert:@"All documents downloaded!" withTitle:@"Refresh"];
        }
    }
    else
    {
        [SurveyAppDelegate showAlert:@"All documents downloaded!" withTitle:@"Refresh"];
    }
}

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex != [actionSheet cancelButtonIndex]){
        if (buttonIndex == 0)
        {
            sendee = SEND_TO_AGENT;
        }
        else if (buttonIndex == 1)
        {
            sendee = SEND_TO_CUSTOMER;
        }
    }
    
    [self processEmail];
}

-(void)doneSendingDocuments
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //holdView = YES;
    emailSent = TRUE;
    [self redraw];
    
}
@end
