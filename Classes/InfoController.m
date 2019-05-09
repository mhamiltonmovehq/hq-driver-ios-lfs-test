//
//  InfoController.m
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InfoController.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"
#import "CustomerUtilities.h"

@implementation InfoController

@synthesize tboxCurrent, info, estimateTypes, jobStatuses, sync, leadSources, popover, sigController;



-(void)initializeRows
{
    [rows removeAllObjects];
    [rows addObject:[NSString stringWithFormat:@"%d", INFO_LEAD_SOURCE]];
    [rows addObject:[NSString stringWithFormat:@"%d", INFO_MILEAGE]];
    [rows addObject:[NSString stringWithFormat:@"%d", INFO_ORDER_NUMBER]];
    
    [rows addObject:[NSString stringWithFormat:@"%d", INFO_ESTIMATE_TYPE]];
    [rows addObject:[NSString stringWithFormat:@"%d", INFO_JOB_STATUS]];
    
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
        milesEditable = FALSE;
        leadSourceText = TRUE;
        editing = FALSE;
        rows = [[NSMutableArray alloc] init];
    }
    return self;
}



- (void)viewDidLoad {
    self.preferredContentSize = CGSizeMake(320, 416);    
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
}



- (void)viewWillAppear:(BOOL)animated {
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(!editing)
    {
        leadSourceText = [leadSources count] == 0;
        
        milesEditable  = FALSE;
        
        self.estimateTypes = [CustomerUtilities getEstimateTypes];
        self.jobStatuses = [CustomerUtilities getJobStatuses];
    }
    editing = FALSE;
    
    [self initializeRows];
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
        
}

-(void)viewDidAppear:(BOOL)animated
{
    
    //if(tboxCurrent != nil)
    //    [tboxCurrent resignFirstResponder];
    
    [super viewDidAppear:animated];
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

-(IBAction)save:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    [del.surveyDB updateShipInfo:info];
    [del.surveyDB updateCustomerSync:sync];
    
    [self cancel:sender];
}

-(IBAction)cancel:(id)sender
{
    if(popover != nil)
    {
        [popover dismissPopoverAnimated:YES];
        [popover.delegate popoverControllerDidDismissPopover:popover];
    }
    else
        [self.navigationController popViewControllerAnimated:YES];
}

-(void)estimateTypeSelected:(NSNumber*)estimateTypeID;
{
    info.type = [estimateTypeID intValue];
}

-(void)jobStatusSelected:(NSNumber*)jobStatusID
{
    info.status = [jobStatusID intValue];
    
    [self initializeRows];
    [self.tableView reloadData];
}

-(void)subLeadSourceSelected:(NSString*)subLeadSource
{
    info.subLeadSource = subLeadSource;
}

-(void)leadSourceSelected:(NSString*)leadSource
{
    info.leadSource = leadSource;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];    
    
    [super viewWillDisappear:animated];
}


-(void)updateValueWithField:(UITextField*)fld
{
    
    switch (fld.tag) 
    {
        case INFO_LEAD_SOURCE:
            info.leadSource = fld.text;
            break;
        case INFO_MILEAGE:
            info.miles = [fld.text intValue];
            break;
        case INFO_ORDER_NUMBER:
            info.orderNumber = fld.text;
            break;
    }
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [rows count];
}

-(int)rowTypeForIndex:(NSIndexPath*)idx
{
    return [[rows objectAtIndex:[idx row]] intValue];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *BasicCellIdentifier = @"Cell";
    static NSString *TextCellIdentifier = @"TextCell";
    
    UITableViewCell *cell = nil;
    TextCell *textCell = nil;
    int row = [self rowTypeForIndex:indexPath];
    
    if(row == INFO_ESTIMATE_TYPE || 
        row == INFO_JOB_STATUS || 
        (!milesEditable && row == INFO_MILEAGE) ||
        (!leadSourceText && row == INFO_LEAD_SOURCE) || 
       row == INFO_LEAD_SOURCE_SUB || 
       row == INFO_SIGNATURE)
    {
        [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicCellIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        switch (row) {
            case INFO_LEAD_SOURCE:
                if([info.leadSource length] == 0)
                    cell.textLabel.text = @"Select a Lead Source";
                else
                    cell.textLabel.text = info.leadSource;
                break;
            case INFO_LEAD_SOURCE_SUB:
                if([info.subLeadSource length] == 0)
                    cell.textLabel.text = @"Select Sub Lead Source";
                else
                    cell.textLabel.text = info.subLeadSource;
                break;
            case INFO_MILEAGE:
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text = [NSString stringWithFormat:@"%d     (Tap To Re-generate)", info.miles];
                break;
            case INFO_ESTIMATE_TYPE:
                cell.textLabel.text = [estimateTypes objectForKey:[NSNumber numberWithInt:info.type]];
                break;
            case INFO_JOB_STATUS:
                cell.textLabel.text = [jobStatuses objectForKey:[NSNumber numberWithInt:info.status]];
                break;
            case INFO_SIGNATURE:
                cell.textLabel.text = @"Enter Signature";
                break;
        }
    }
    else
    {
        textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        
        if (textCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
        }
        
        textCell.tboxValue.tag = row;
        switch (row) {
            case INFO_LEAD_SOURCE:
                textCell.tboxValue.placeholder = @"Lead Source";
                textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                textCell.tboxValue.text = info.leadSource;
                textCell.tboxValue.delegate = self;
                break;
            case INFO_MILEAGE:
                textCell.tboxValue.placeholder = @"Mileage";
                textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
                if(info.miles > 0)
                    textCell.tboxValue.text = [NSString stringWithFormat:@"%d", info.miles];
                else
                    textCell.tboxValue.text = @"";
                textCell.tboxValue.delegate = self;
                break;
            case INFO_ORDER_NUMBER:
                textCell.tboxValue.placeholder = @"QM Order Number";
                textCell.tboxValue.text = info.orderNumber;
                textCell.tboxValue.delegate = self;
                break;
        }
        
    }
    
    
    return cell != nil ? cell : textCell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[tableView cellForRowAtIndexPath:indexPath] class] == [TextCell class])
        return nil;
    else
        return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    int row = [self rowTypeForIndex:indexPath];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    editing = TRUE;
    
    NSMutableDictionary *dict;
    NSArray *array;
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    switch (row) {
        case INFO_LEAD_SOURCE:
            //take to lead source selection
            dict = [[NSMutableDictionary alloc] init];
            for(int i = 0; i < [leadSources count]; i++)
            {
                [dict setObject:[leadSources objectAtIndex:i] forKey:[leadSources objectAtIndex:i]];
            }
            [del pushPickerViewController:@"Lead Source" 
                              withObjects:dict 
                     withCurrentSelection:[NSNumber numberWithInt:-1]
                               withCaller:self 
                              andCallback:@selector(leadSourceSelected:)
                         andNavController:self.navigationController];
            break;
        case INFO_LEAD_SOURCE_SUB:
            //take to sub lead source selection
            dict = [[NSMutableDictionary alloc] init];
            for(int i = 0; i < [array count]; i++)
            {
                [dict setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i]];
            }
            [del pushPickerViewController:@"Sub Lead Source" 
                              withObjects:dict 
                     withCurrentSelection:[NSNumber numberWithInt:-1]
                               withCaller:self 
                              andCallback:@selector(subLeadSourceSelected:)
                         andNavController:self.navigationController];
            break;
        case INFO_MILEAGE:
            //generate miles
            //info.miles = [CustomerUtilities getMileage];  this method does not exist
            [self.tableView reloadData];
            break;
        case INFO_ESTIMATE_TYPE:
            [del pushPickerViewController:@"Estimate Type" 
                              withObjects:estimateTypes 
                     withCurrentSelection:[NSNumber numberWithInt:info.type]
                               withCaller:self 
                              andCallback:@selector(estimateTypeSelected:)
                         andNavController:self.navigationController];
            break;
        case INFO_JOB_STATUS:
            [del pushPickerViewController:@"Job Status" 
                              withObjects:jobStatuses 
                     withCurrentSelection:[NSNumber numberWithInt:info.status]
                               withCaller:self 
                              andCallback:@selector(jobStatusSelected:)
                         andNavController:self.navigationController];
            break;
            
        case INFO_SIGNATURE:
            if(sigController == nil)
                sigController = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
            sigController.saveBeforeDismiss = NO;
            [self.navigationController pushViewController:sigController animated:YES];
            break;
    }
}


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


#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
    
    //row throws it off...
    //[SurveyAppDelegate scrollTableToTextField:textField withTable:self.tableView atRow:textField.tag];
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}


@end

