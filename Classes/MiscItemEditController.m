//
//  MiscItemEditController.m
//  Survey
//
//  Created by Tony Brame on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MiscItemEditController.h"
#import "SurveyAppDelegate.h"
#import "SwitchCell.h"
#import "TextCell.h"

@implementation MiscItemEditController

@synthesize miscItem, tboxCurrent;

- (void)dealloc {
	[miscItem release];
	[tboxCurrent release];
	
    [super dealloc];
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
	
	self.contentSizeForViewInPopover = CGSizeMake(320, 416);
	
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
}



- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
    [super viewWillAppear:animated];
}


-(void)updateValueWithField:(UITextField*)text
{
	switch (text.tag) {
		case MISC_DESCRIPTION:
			miscItem.description = text.text;
			break;
		case MISC_RATE:
			miscItem.rate = [text.text doubleValue];
			break;
	}
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
	
	[super viewWillDisappear:animated];
}

-(IBAction)discountedChanged:(id)sender
{
	UISwitch *sw = sender;
	miscItem.discounted = sw.on;
}

-(IBAction)save:(id)sender
{
	if(tboxCurrent != nil)
		[self updateValueWithField:tboxCurrent];
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	[del.surveyDB updateMiscItem:miscItem];
	
	[self cancel:sender];
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
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
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
	TextCell *textCell = nil;
	SwitchCell *swCell = nil;
	
	if([indexPath row] == MISC_DISCOUNT)
	{
		swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
		if(textCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
			swCell = [nib objectAtIndex:0];
			
			[swCell.switchOption addTarget:self
			 action:@selector(discountedChanged:) 
			 forControlEvents:UIControlEventValueChanged];
		}
		
		swCell.switchOption.on = miscItem.discounted;
		swCell.labelHeader.text = @"Discounted";
	}
	else
	{
		textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if(textCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
			textCell = [nib objectAtIndex:0];
			textCell.accessoryType = UITableViewCellAccessoryNone;
			textCell.tboxValue.delegate = self;
		}
		
		if(indexPath.row == MISC_DESCRIPTION)
		{
			textCell.tboxValue.placeholder = @"Item Name";
			textCell.tboxValue.text = miscItem.description;
			textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
			textCell.tboxValue.tag = MISC_DESCRIPTION;
		}
		else if(indexPath.row == MISC_RATE)
		{
			textCell.tboxValue.placeholder = @"Item Rate";
			textCell.tboxValue.text = [NSString stringWithFormat:@"%@", [SurveyAppDelegate formatDouble:miscItem.rate]];
			textCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
			textCell.tboxValue.tag = MISC_RATE;
		}
	}
	
	
    return textCell != nil ? (UITableViewCell*)textCell : (UITableViewCell*)swCell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
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
	[self updateValueWithField:textField];
}


@end

