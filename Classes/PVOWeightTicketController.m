//
//  PVOAllWeightsController.m
//  Survey
//
//  Created by Tony Brame on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOWeightTicketController.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"
#import "PVOPrintController.h"
#import "PVOSync.h"

@implementation PVOWeightTicketController

@synthesize tboxCurrent;
@synthesize delegate, weightTicket;

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

-(IBAction)cancel_Click:(id)sender
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Discard?"
                                                 message:@"If you have made any changes to this weight ticket, they will be lost.  Are you sure you want to discard any changes to this Weight Ticket?"
                                                delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"Yes", nil];
    
    [av show];
    
}

-(BOOL)validateSave
{
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    weightTicket.weightTicketID = [del.surveyDB savePVOWeightTicket:weightTicket];
    
    UIImage *myimage = [SurveyImageViewer getDefaultImage:IMG_PVO_WEIGHT_TICKET forItem:weightTicket.weightTicketID];
    
    //check all values to ensure it can be saved...
    if(weightTicket.description == nil || weightTicket.description.length == 0 ||
       weightTicket.grossWeight == 0 ||
       weightTicket.weightType == PVO_WEIGHT_TICKET_NONE ||
       myimage == nil)
    {
        [SurveyAppDelegate showAlert:@"You must have an image, description, weight, and weight type entered to continue." withTitle:@"Data Required"];
        return FALSE;
    }
    else
        return TRUE;
}

-(IBAction)save_Click:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(weightDataEntered:)])
        [delegate weightDataEntered:self];
    
    if([self validateSave])
        [self.navigationController popViewControllerAnimated:YES];
}

-(void)updateValueWithField:(UITextField*)fld
{
    if(fld.tag == PVO_WEIGHT_TICKET_DESCRIPTION)
        weightTicket.description = fld.text;
    else if(fld.tag == PVO_WEIGHT_TICKET_WEIGHT)
        weightTicket.grossWeight = [fld.text intValue];
}

-(void)weightTypeSelected:(NSNumber*)weightType
{
    weightTicket.weightType = [weightType intValue];
}

-(void)ticketDateSelected:(NSDate*)newDate withIgnore:(NSDate*)ignore
{
    weightTicket.ticketDate = newDate;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(cancel_Click:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(save_Click:)];
    
    self.title = @"Weight Ticket";
    
    self.weightTypes = [NSMutableDictionary dictionaryWithObjects:@[@" - None - ", @"Gross", @"Tare", @"Net"]
                                                          forKeys:@[[NSNumber numberWithInt:PVO_WEIGHT_TICKET_NONE],
                                                                    [NSNumber numberWithInt:PVO_WEIGHT_TICKET_GROSS],
                                                                    [NSNumber numberWithInt:PVO_WEIGHT_TICKET_TARE],
                                                                    [NSNumber numberWithInt:PVO_WEIGHT_TICKET_NET]]];
    
    rows = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [self initializeIncludedRows];
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

/*
 #define PVO_WEIGHT_TICKET_IMAGE 0
 #define PVO_WEIGHT_TICKET_DATE 1
 #define PVO_WEIGHT_TICKET_DESCRIPTION 2
 #define PVO_WEIGHT_TICKET_WEIGHT 3
 #define PVO_WEIGHT_TICKET_WEIGHT_TYPE 4
 #define PVO_WEIGHT_TICKET_UPLOAD 5*/

-(void)initializeIncludedRows
{
    [rows removeAllObjects];
    
    [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_IMAGE]];
    [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_DATE]];
    [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_DESCRIPTION]];
    [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_WEIGHT]];
    [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_WEIGHT_TYPE]];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.pricingDB vanline] == ATLAS)
        [rows addObject:[NSNumber numberWithInt:PVO_WEIGHT_TICKET_UPLOAD]];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    
    UITableViewCell *cell = nil;
    LabelTextCell *ltCell = nil;
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    if(row == PVO_WEIGHT_TICKET_IMAGE ||
       row == PVO_WEIGHT_TICKET_DATE ||
       row == PVO_WEIGHT_TICKET_WEIGHT_TYPE ||
       row == PVO_WEIGHT_TICKET_UPLOAD)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.imageView.image = nil;
        
        if(row == PVO_WEIGHT_TICKET_IMAGE)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"View/Add Image";
            
            UIImage *myimage = [SurveyImageViewer getDefaultImage:IMG_PVO_WEIGHT_TICKET forItem:weightTicket.weightTicketID];
            if(myimage == nil)
                myimage = [UIImage imageNamed:@"img_photo.png"];
            cell.imageView.image = myimage;
        }
        else if(row == PVO_WEIGHT_TICKET_DATE)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"Date: %@ %@", [SurveyAppDelegate formatDate:weightTicket.ticketDate],
                                   [SurveyAppDelegate formatTime:weightTicket.ticketDate]];
        }
        else if(row == PVO_WEIGHT_TICKET_WEIGHT_TYPE)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [NSString stringWithFormat:@"Weight Type: %@",
                                   [self.weightTypes objectForKey:[NSNumber numberWithInt:weightTicket.weightType]]];
        }
        else if(row == PVO_WEIGHT_TICKET_UPLOAD)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"Upload Ticket";
        }
    }
    else
    {
        //text field
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
        
        ltCell.tboxValue.tag = row;
        if(row == PVO_WEIGHT_TICKET_WEIGHT)
        {
            ltCell.labelHeader.text = @"Weight";
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", weightTicket.grossWeight];
        }
        else if(row == PVO_WEIGHT_TICKET_DESCRIPTION)
        {
            ltCell.labelHeader.text = @"Description";
            ltCell.tboxValue.text = weightTicket.description;
        }
    }
    
    return cell != nil ? cell : ltCell;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(row == PVO_WEIGHT_TICKET_IMAGE)
    {
        weightTicket.weightTicketID = [del.surveyDB savePVOWeightTicket:weightTicket];
        
        if(images == nil)
            images = [[SurveyImageViewer alloc] init];
        
        images.photosType = IMG_PVO_WEIGHT_TICKET;
        images.customerID = del.customerID;
        images.subID = weightTicket.weightTicketID;
        images.maxPhotos = 1;
        
        images.caller = self.view;
        
        images.viewController = self;
        
        [images loadPhotos];
    }
    else if(row == PVO_WEIGHT_TICKET_WEIGHT_TYPE)
    {
        [del pushPickerViewController:@"Weight Type"
                          withObjects:self.weightTypes
                 withCurrentSelection:[NSNumber numberWithInt:weightTicket.weightType]
                           withCaller:self
                          andCallback:@selector(weightTypeSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == PVO_WEIGHT_TICKET_DATE)
    {
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Select an Edit Type"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Change Time", @"Change Date", nil];
        [as showInView:self.view];
    }
    else if(row == PVO_WEIGHT_TICKET_UPLOAD)
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Document?"
                                                        message:@"Are you sure you would like to upload this document to Atlas?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = PVO_ALERT_UPLOAD_WEIGHT_TICKET;
        [alert show];
        
    }
}


#pragma UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        if(alertView.tag == PVO_ALERT_UPLOAD_WEIGHT_TICKET)
        {
            
            //load upload view...
            if(uploader == nil)
                uploader = [[PVOUploadReportView alloc] init];
            
            if(![self validateSave])
                return;
            
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            //the easiest thing to do was save to the report.pdf file (even though this is a jpg), that that's what we're doing...
            NSMutableArray *arr = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_WEIGHT_TICKET
                                                    withSubID:weightTicket.weightTicketID loadAllItems:NO];
            if(arr != nil && [arr count] > 0)
            {
                NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
                SurveyImage *image = [arr objectAtIndex:0];
                NSString *filePath = image.path;
                NSString *fullPath = [docsDir stringByAppendingPathComponent:filePath];
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                
                NSData *data = [PVOSync getResizedPhotoData:[UIImage imageWithContentsOfFile:fullPath]];
                if(data == nil)
                {
                    [SurveyAppDelegate showAlert:@"Unable to load weight ticket image." withTitle:@"File Error"];
                    return;
                }
                
                if([fileManager fileExistsAtPath:[docsDir stringByAppendingPathComponent:@"temp.pdf"]])
                    [fileManager removeItemAtPath:[docsDir stringByAppendingPathComponent:@"temp.pdf"] error:nil];
                
                [fileManager createFileAtPath:[docsDir stringByAppendingPathComponent:@"temp.pdf"]
                                     contents:data
                                   attributes:nil];
                
            }
            
            [uploader uploadDocument:WEIGHT_TICKET];
            
        }
        else
        {
            //discard changes...
            [self.navigationController popViewControllerAnimated:YES];
            
            if(weightTicket.newRecord)
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                [del.surveyDB deletePVOWeightTicket:weightTicket.weightTicketID forCustomer:del.customerID];
            }
        }
    }
}

#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != actionSheet.cancelButtonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if(buttonIndex == 0)
        {
            [del pushSingleTimeViewController:weightTicket.ticketDate
                                 withNavTitle:@"Ticket Time"
                                   withCaller:self
                                  andCallback:@selector(ticketDateSelected:withIgnore:)
                             andNavController:self.navigationController];
        }
        else if(buttonIndex == 1)
        {
            [del pushSingleDateViewController:weightTicket.ticketDate
                                 withNavTitle:@"Ticket Date"
                                   withCaller:self
                                  andCallback:@selector(ticketDateSelected:withIgnore:)
                             andNavController:self.navigationController];
        }
    }
}

@end
