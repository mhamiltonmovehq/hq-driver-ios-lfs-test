//
//  PVOItemAdditionalController.m
//  Survey
//
//  Created by Tony Brame on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScanOrEnterValueController.h"
#import "TextCell.h"
#import "OrigDestCell.h"
#import "SurveyAppDelegate.h"

@implementation ScanOrEnterValueController

@synthesize usingScanner, tboxCurrent, delegate, description, data;

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
    [super viewDidLoad];

    rows = [[NSMutableArray alloc] init];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(scanOrEnterValueControllerShowDone:)])
    {
        if([delegate scanOrEnterValueControllerShowDone:self])
        {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                      target:self 
                                                                                      action:@selector(cmdDoneClick:)];
        }
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" 
                                                                               style:UIBarButtonItemStylePlain 
                                                                              target:self 
                                                                              action:@selector(cmdContinueClick:)];
    
}

-(IBAction)cmdDoneClick:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(scanOrEnterValueControllerDone:)])
        [delegate scanOrEnterValueControllerDone:self];
}

-(IBAction)cmdContinueClick:(id)sender
{
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if(data == nil || [data length] == 0)
        [SurveyAppDelegate showAlert:@"You must have a value entered to continue." withTitle:@"Data Required"];
    
    [self valueEntered:data];
}

-(void)viewWillAppear:(BOOL)animated
{
    if(delegate != nil && [delegate respondsToSelector:@selector(scanOrEnterValueWillDisplay:)])
        [delegate scanOrEnterValueWillDisplay:self];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del setCurrentSocketListener:self];
    [del.linea addDelegate:self];
    
    
    [self initializeIncludedRows];
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)updateValueWithField:(UITextField*)tbox
{
    switch (tbox.tag) {
        case SCAN_ENTER_TEXT:
            self.data = tbox.text;
            break;
    }
}

-(void)valueEntered:(NSString*)val
{
    if(delegate != nil && [delegate respondsToSelector:@selector(scanOrEnterValueController:dataEntered:)])
    {
        [delegate scanOrEnterValueController:self dataEntered:val];
    }
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)initializeIncludedRows
{

    [rows removeAllObjects];
    
    [rows addObject:[NSNumber numberWithInt:SCAN_ENTER_MODE]];
    
    if(usingScanner)
    {
        [rows addObject:[NSNumber numberWithInt:SCAN_ENTER_SCANNER]];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if(!del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
            self.navigationItem.prompt = @"Scanner is not connected";
        else
            self.navigationItem.prompt = nil;
    }
    else 
    {
        self.navigationItem.prompt = nil;
        [rows addObject:[NSNumber numberWithInt:SCAN_ENTER_TEXT]];
    }
    
}

-(IBAction)segmentChanged:(id)sender
{
    UISegmentedControl *segment = sender;
    usingScanner = segment.selectedSegmentIndex == 1;
    
    [self initializeIncludedRows];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:nil];
    [del.linea removeDelegate:self];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    return [rows count];
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *header = nil;
    
    if(delegate != nil && [delegate respondsToSelector:@selector(scanOrEnterValueHeaderText:)])
        header = [delegate scanOrEnterValueHeaderText:self];
    
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *OrigDestCellIdentifier = @"OrigDestCell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    TextCell *textCell = nil;
    OrigDestCell *odCell = nil;
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    if(row == SCAN_ENTER_MODE)
    {
        odCell = (OrigDestCell*)[tableView dequeueReusableCellWithIdentifier:OrigDestCellIdentifier];
        if(odCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrigDestCell" owner:self options:nil];
            odCell = [nib objectAtIndex:0];
            odCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [odCell.segmentOrigDest removeAllSegments];
        
        odCell.segmentOrigDest.tag = row;
        
        [odCell.segmentOrigDest insertSegmentWithTitle:@"Scanner" atIndex:0 animated:NO];
        [odCell.segmentOrigDest insertSegmentWithTitle:@"Manual" atIndex:0 animated:NO];
        odCell.segmentOrigDest.selectedSegmentIndex = usingScanner ? 1 : 0;
        [odCell.segmentOrigDest addTarget:self
                                   action:@selector(segmentChanged:) 
                         forControlEvents:UIControlEventValueChanged];
    }
    else if(row == SCAN_ENTER_TEXT)
    {//text cells
        textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        if (textCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            [textCell.tboxValue addTarget:self 
                                   action:@selector(textFieldDoneEditing:) 
                         forControlEvents:UIControlEventEditingDidEndOnExit];
            textCell.tboxValue.delegate = self;
            textCell.tboxValue.font = [UIFont systemFontOfSize:17.];
            textCell.tboxValue.returnKeyType = UIReturnKeyDone;
        }
        textCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        textCell.tboxValue.tag = row;
        
        textCell.tboxValue.text = data;
        textCell.tboxValue.placeholder = description;
        
    }
    else 
    {//standard cells with option to tap to scan
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        [cell.textLabel setTextColor:[UIColor blackColor]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if(data == nil || [data length] == 0)
        {
            [cell.textLabel setTextColor:[UIColor redColor]];
            cell.textLabel.text = @"Waiting For Scan";
        }
        else
            cell.textLabel.text = data;
    }
    
    return cell != nil ? cell : odCell != nil ? odCell : textCell;
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
    if(tboxCurrent != nil)
        [tboxCurrent resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}



#pragma mark - UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateValueWithField:textField];
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
    
    self.data = [[NSString stringWithUTF8String:(const char *)[decodedData getData]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [self.tableView reloadData];
    
}

-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(!SKTSUCCESS(result))
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error initializing ScanAPI: %d",result] withTitle:@"Scanner Error"];
    } else {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving ScanObject:%d",result] withTitle:@"Scanner Error"];
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
    self.data = barcode;
    
    [self.tableView reloadData];
    
}


@end
