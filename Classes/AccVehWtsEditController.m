//
//  AccVehWtsEditController.m
//  Survey
//
//  Created by Tony Brame on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AccVehWtsEditController.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"

@implementation AccVehWtsEditController

@synthesize vehicle, tboxCurrent;

- (void)viewDidLoad {
	self.contentSizeForViewInPopover = CGSizeMake(320, 416);
	
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(saveVehicle:)];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
*/

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
    [super viewWillAppear:animated];
}

/*
*/

-(void)updateVehicleValueWithField:(UITextField*)field
{
	switch (field.tag) {
		case VEHICLE_NAME:
			vehicle.name = field.text;
			break;
		case VEHICLE_WEIGHT:
			vehicle.weight = [field.text intValue];
			break;
	}
}

-(IBAction)saveVehicle:(id)sender
{
	if(tboxCurrent != nil)
		[self updateVehicleValueWithField:tboxCurrent];
	
	if([vehicle.name length] == 0 || vehicle.weight == 0)
	{
		[SurveyAppDelegate showAlert:@"You must enter a vehicle name and weight to continue." withTitle:@"Vehicle Information Req'd"];
		return;
	}
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateVehicleWeights:vehicle];
	
	[self cancel:self];
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
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

- (void)dealloc {
    [super dealloc];
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
    
    static NSString *CellIdentifier = @"TextCell";
    
	TextCell *textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(textCell == nil)
	{
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
		textCell = [nib objectAtIndex:0];
		textCell.accessoryType = UITableViewCellAccessoryNone;
		textCell.tboxValue.delegate = self;
	}
	
	if(indexPath.row == 0)
	{
		textCell.tboxValue.placeholder = @"Vehicle Name";
		textCell.tboxValue.text = vehicle.name;
		textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
		textCell.tboxValue.tag = VEHICLE_NAME;
	}
	else
	{
		textCell.tboxValue.placeholder = @"Vehicle Weight";
		textCell.tboxValue.text = [NSString stringWithFormat:@"%d", vehicle.weight];
		textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
		textCell.tboxValue.tag = VEHICLE_WEIGHT;
	}
	
	
    return textCell;
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
	[self updateVehicleValueWithField:textField];
}

@end

