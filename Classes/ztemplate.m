//
//  LocalAccShuttleController.m
//  Survey
//
//  Created by Tony Brame on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LocalAccShuttleController.h"
#import "SurveyAppDelegate.h"
#import "LabelTextCell.h"
#import "PopulateLabelTextCell.h"

@implementation LocalAccShuttleController

@synthesize tboxCurrent, acc;

- (void)dealloc {
	[tboxCurrent release];
	[acc release];
	
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

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated {
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
 */

-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}

-(void)updateValueWithField:(UITextField*)field
{
	switch (field.tag) {
		case :
			
			break;
	}
}

-(IBAction)populateWeight:(id)sender
{
	if(tboxCurrent != nil)
		[tboxCurrent resignFirstResponder];
	
	= [CustomerUtilities getTotalCustomerWeight];
	[self.tableView reloadData];
}

-(IBAction)switchChanged:(id)sender
{
	UISwitch *sw = sender;
	= sw.on;
}

-(IBAction)populateCuFt:(id)sender
{
	if(tboxCurrent != nil)
		[tboxCurrent resignFirstResponder];
	
	 = [CustomerUtilities getTotalCustomerCuFt];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	
	if(tboxCurrent != nil)
		[self updateValueWithField:tboxCurrent];
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateLocalAcc:acc];
	
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    static NSString *PopulateLabelTextCellIdentifier = @"PopulateLabelTextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
	LabelTextCell *ltCell = nil;
	PopulateLabelTextCell *pltCell = nil;
	SwitchCell *swCell = nil;
	
	if(indexPath.row == )
	{
		pltCell = (PopulateLabelTextCell*)[tableView dequeueReusableCellWithIdentifier:PopulateLabelTextCellIdentifier];
		if (pltCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PopulateLabelTextCell" owner:self options:nil];
			pltCell = [nib objectAtIndex:0];
			[pltCell.tboxValue addTarget:self 
								  action:@selector(textFieldDoneEditing:) 
						forControlEvents:UIControlEventEditingDidEndOnExit];
		}
		pltCell.tboxValue.delegate = self;
		pltCell.tboxValue.tag = [indexPath row];
		
		if(indexPath.row == LOCAL_ACC_SEL_WEIGHT)
		{
			[pltCell.cmdPopulate addTarget:self 
									action:@selector(populateWeight:) 
						  forControlEvents:UIControlEventTouchUpInside];
			pltCell.labelHeader.text = @"";
			pltCell.tboxValue.text = [SurveyAppDelegate formatDouble: withPrecision:0];
		}
		else
		{
			
			[pltCell.cmdPopulate addTarget:self 
									action:@selector(populateCuFt:) 
						  forControlEvents:UIControlEventTouchUpInside];
			pltCell.labelHeader.text = @"";
			pltCell.tboxValue.text = [SurveyAppDelegate formatDouble: withPrecision:0];		
		}
	}
	else if(indexPath.row == )
	{
		
		swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
		if(swCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
			swCell = [nib objectAtIndex:0];
			[swCell.switchOption addTarget:self
									action:@selector(switchChanged:) 
						  forControlEvents:UIControlEventValueChanged];
		}
		
		swCell.switchOption.on = ;
		swCell.labelHeader.text = @"";
		
	}
	else
	{
		ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
		if (ltCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
			ltCell = [nib objectAtIndex:0];
			[ltCell.tboxValue addTarget:self 
								 action:@selector(textFieldDoneEditing:) 
					   forControlEvents:UIControlEventEditingDidEndOnExit];
		}
		ltCell.tboxValue.delegate = self;
		ltCell.tboxValue.tag = [indexPath row];
		
		switch (indexPath.row) {
			case :
				ltCell.labelHeader.text = @"";
				ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", ];
				break;
			case :
				ltCell.labelHeader.text = @"";
				ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:];
				break;
		}
	}
	
    return ltCell != nil ? (UITableViewCell*)ltCell : pltCell != nil ? (UITableViewCell*)pltCell : (UITableViewCell*)swCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
	if(tboxCurrent != nil)
		[tboxCurrent resignFirstResponder];
	
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

