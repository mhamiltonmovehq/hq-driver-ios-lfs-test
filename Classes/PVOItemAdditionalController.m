//
//  PVOItemAdditionalController.m
//  Survey
//
//  Created by Tony Brame on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOItemAdditionalController.h"
#import "TextCell.h"
#import "OrigDestCell.h"
#import "SurveyAppDelegate.h"

@implementation PVOItemAdditionalController

@synthesize item, pvoItem, inventory, usingScanner, tboxCurrent, scannerInView;

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
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];

    rows = [[NSMutableArray alloc] init];
    
    self.title = @"Add'l Fields";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initializeIncludedRows];
    [self.tableView reloadData];
    
    if (pvoItem.cartonContentID > 0)
        [SurveyAppDelegate setupViewForCartonContent:self.view withTableView:self.tableView];
    
    [super viewWillAppear:animated];
}

-(void)updateValueWithField:(UITextField*)tbox
{
    switch (tbox.tag) {
        case PVO_ADD_YEAR_TEXT:
            pvoItem.year = [tbox.text intValue];
            break;
        case PVO_ADD_MAKE_TEXT:
            pvoItem.make = tbox.text;
            break;
        case PVO_ADD_MODEL_TEXT:
            pvoItem.modelNumber = tbox.text;
            break;
        case PVO_ADD_SERIAL_TEXT:
            pvoItem.serialNumber = tbox.text;
            break;
        case PVO_ADD_SECURITY_SEAL_TEXT:
            pvoItem.securitySealNumber = tbox.text;
            break;
        case PVO_ADD_ODOMETER_TEXT:
            pvoItem.odometer = [tbox.text intValue];
            break;
        case PVO_ADD_CALIBER_GAUGE_TEXT:
            pvoItem.caliberGauge = tbox.text;
            break;
    }
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)initializeIncludedRows
{

    [rows removeAllObjects];
    
    [rows addObject:[NSNumber numberWithInt:PVO_ADD_SCANNER]];
    
    if (!_enteringSecuritySeal && item != nil && (item.isGun || (inventory != nil && inventory.loadType == MILITARY)))
    {
        if (inventory != nil && inventory.loadType == MILITARY && item.isVehicle)
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_YEAR_TEXT]];
        if (item.isGun || (inventory != nil && inventory.loadType == MILITARY && (item.isVehicle || item.isElectronic)))
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_MAKE_TEXT]];
    }
    
    if(usingScanner)
    {
        if(_enteringSecuritySeal)
        {
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_SECURITY_SEAL_SCANNER]];
        }
        else
        {
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_MODEL_SCANNER]];
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_SERIAL_SCANNER]];
        }
    }
    else
    {
        if(_enteringSecuritySeal)
        {
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_SECURITY_SEAL_TEXT]];
        }
        else
        {
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_MODEL_TEXT]];
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_SERIAL_TEXT]];
        }
    }
    
    if (!_enteringSecuritySeal && item != nil && (item.isGun || (inventory != nil && inventory.loadType == MILITARY)))
    {
        if (inventory != nil && inventory.loadType == MILITARY && item.isVehicle)
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_ODOMETER_TEXT]];
        if (item.isGun)
            [rows addObject:[NSNumber numberWithInt:PVO_ADD_CALIBER_GAUGE_TEXT]];
    }
}

-(IBAction)segmentChanged:(id)sender
{
    UISegmentedControl *segment = sender;
    usingScanner = segment.selectedSegmentIndex == 1;
    
    [self initializeIncludedRows];
    [self.tableView reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *OrigDestCellIdentifier = @"OrigDestCell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    TextCell *textCell = nil;
    OrigDestCell *odCell = nil;
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    if(row == PVO_ADD_SCANNER)
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
    else if(row == PVO_ADD_MODEL_TEXT ||
            row == PVO_ADD_SERIAL_TEXT ||
            row == PVO_ADD_YEAR_TEXT ||
            row == PVO_ADD_MAKE_TEXT ||
            row == PVO_ADD_ODOMETER_TEXT ||
            row == PVO_ADD_CALIBER_GAUGE_TEXT ||
            row == PVO_ADD_SECURITY_SEAL_TEXT)
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
        
        if(row == PVO_ADD_SECURITY_SEAL_TEXT)
        {
            textCell.tboxValue.text = pvoItem.securitySealNumber;
            textCell.tboxValue.placeholder = @"Security Seal Number";
        }
        else if(row == PVO_ADD_MODEL_TEXT)
        {
            textCell.tboxValue.text = pvoItem.modelNumber;
            textCell.tboxValue.placeholder = @"Model Number";
        }
        else if(row == PVO_ADD_SERIAL_TEXT)
        {
            textCell.tboxValue.text = pvoItem.serialNumber;
            textCell.tboxValue.placeholder = @"Serial Number";
        }
        else if(row == PVO_ADD_YEAR_TEXT)
        {
            textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            if (pvoItem.year > 0)
                textCell.tboxValue.text = [SurveyAppDelegate formatDouble:pvoItem.year withPrecision:0];
            else
                textCell.tboxValue.text = nil;
            textCell.tboxValue.placeholder = @"Year";
        }
        else if(row == PVO_ADD_MAKE_TEXT)
        {
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            textCell.tboxValue.text = pvoItem.make;
            textCell.tboxValue.placeholder = @"Make";
        }
        else if(row == PVO_ADD_ODOMETER_TEXT)
        {
            textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            if (pvoItem.odometer > 0)
                textCell.tboxValue.text = [SurveyAppDelegate formatDouble:pvoItem.odometer withPrecision:0];
            else
                textCell.tboxValue.text = nil;
            textCell.tboxValue.placeholder = @"Odometer";
        }
        else if(row == PVO_ADD_CALIBER_GAUGE_TEXT)
        {
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            textCell.tboxValue.text = pvoItem.caliberGauge;
            textCell.tboxValue.placeholder = @"Caliber or Gauge";
        }
    }
    else 
    {//standard cells with option to tap to scan
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        [cell.textLabel setTextColor:[UIColor blackColor]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if(row == PVO_ADD_SECURITY_SEAL_SCANNER)
        {
            if([pvoItem.securitySealNumber length] == 0)
            {
                [cell.textLabel setTextColor:[UIColor redColor]];
                cell.textLabel.text = @"Tap To Scan Security Seal Number";
            }
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Security Seal #: %@", pvoItem.securitySealNumber];
        }
        else if(row == PVO_ADD_MODEL_SCANNER)
        {
            if(pvoItem.modelNumber == nil || [pvoItem.modelNumber length] == 0)
            {
                [cell.textLabel setTextColor:[UIColor redColor]];
                cell.textLabel.text = @"Tap To Scan Model Number";
            }
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Model #: %@", pvoItem.modelNumber];
        }
        else if(row == PVO_ADD_SERIAL_SCANNER)
        {
            if(pvoItem.serialNumber == nil || [pvoItem.serialNumber length] == 0)
            {
                [cell.textLabel setTextColor:[UIColor redColor]];
                cell.textLabel.text = @"Tap To Scan Serial Number";
            }
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Serial #: %@", pvoItem.serialNumber];
        }
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
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    
    if(row == PVO_ADD_SERIAL_SCANNER ||
       row == PVO_ADD_MODEL_SCANNER ||
       row == PVO_ADD_SECURITY_SEAL_SCANNER)
    {
        if(scannerInView == nil)
            scannerInView = [[ScannerInputView alloc] init];
        scannerInView.delegate = self;
        scannerInView.tag = row;
        [scannerInView waitForInput];
    }
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

#pragma mark - ScannerInputViewDelegate methods

-(void)scannerInput:(ScannerInputView*)scannerView withValue:(NSString*)scannerValue
{
    if(scannerView.tag == PVO_ADD_SERIAL_SCANNER)
        pvoItem.serialNumber = scannerValue;
    else if(scannerView.tag == PVO_ADD_MODEL_SCANNER)
        pvoItem.modelNumber = scannerValue;
    else if(scannerView.tag == PVO_ADD_SECURITY_SEAL_SCANNER)
        pvoItem.securitySealNumber = scannerValue;
    
    [self.tableView reloadData];
}

@end
