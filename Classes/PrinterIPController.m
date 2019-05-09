//
//  PrinterIPController.m
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PrinterIPController.h"
#import "TextCell.h"
//#define Printer ePrint_Printer
#import "ePrint.h"
//#undef Printer
#import "StoredPrinter.h"
#import "SurveyAppDelegate.h"
#import "PrinterNameController.h"

@implementation PrinterIPController

@synthesize ipAddress, tboxCurrent, sendMeThePrinter, printerReceptacle;

- (void)viewWillAppear:(BOOL)animated {
	self.title = @"IP Address";
	[self.tableView reloadData];
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
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
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *TextCellIdentifier = @"TextCell";
    
    static NSString *CellIdentifier = @"Cell";
    
	UITableViewCell *cell = nil;
	TextCell *textCell = nil;
	
	if(indexPath.row == 1)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		cell.textLabel.text = @"Use This Address";
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
		
		textCell.tboxValue.text = ipAddress;
		textCell.tboxValue.placeholder = @"IP Address";
	}
	
    return cell != nil ? cell : (UITableViewCell*)textCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if(indexPath.row == 1)
	{
		if(tboxCurrent != nil)
			self.ipAddress = tboxCurrent.text;
		
		if(ipAddress != nil && [ipAddress length] > 0)
		{
			//get the kind, then continue to load the name controller (may take a cpl secs)
			
			// Fing printer info
			NSDictionary	*printerInfo = nil;
			printerInfo = [ePrint printerInformation:ipAddress];	/* This may takes few seconds */
			if ( [printerInfo count] > 0 ) 
			{
				if ( [[printerInfo objectForKey:ePrintInformationPrinterKind] intValue] == ePrintPrinterKindUNKNOWN ) 
				{
					/* printer not found */
					[SurveyAppDelegate showAlert:@"Unable to locate printer with that IP." withTitle:@"Error"];
				}
				else 
				{
					//set address, kind, then move to the next controller
					StoredPrinter *newPrinter = [[StoredPrinter alloc] init];
					newPrinter.name = ipAddress;
					newPrinter.address = ipAddress;
					newPrinter.printerKind = [[printerInfo objectForKey:ePrintInformationPrinterKind] intValue];
					
					if(printerReceptacle != nil)
					{
						[printerReceptacle performSelector:sendMeThePrinter withObject:newPrinter];
						[self.navigationController dismissViewControllerAnimated:YES completion:nil];
					}
					else
					{
						PrinterNameController *ctl = [[PrinterNameController alloc] initWithStyle:UITableViewStyleGrouped];
						ctl.printer = newPrinter;
						[self.navigationController pushViewController:ctl animated:YES];
						
					}
					
				}
			}
			else 
			{
				[SurveyAppDelegate showAlert:@"Unable to locate printer with that IP.  printerInfo count is 0." withTitle:@"Error"];
			}
			
		}
		else 
		{
			[SurveyAppDelegate showAlert:@"You must enter an ip address to continue" withTitle:@"IP Address"];
		}

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
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	self.ipAddress = textField.text;
}

@end

