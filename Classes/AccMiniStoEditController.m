//
//  AccMiniStoEditController.m
//  Survey
//
//  Created by Tony Brame on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AccMiniStoEditController.h"
#import "TextWithHeaderCell.h"
#import "OrigDestCell.h"
#import "SurveyAppDelegate.h"
#import "SurveyLocation.h"

@implementation AccMiniStoEditController


@synthesize storage;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(saveWFChange:)];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancelWFChange:)];
	
}
/*
*/

- (void)viewWillAppear:(BOOL)animated {
	
	
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

-(IBAction)locationChanged:(id)sender
{
	UISegmentedControl *ctl = sender;
	if(ctl.selectedSegmentIndex == ORIG_DEST_ORIGIN)
		storage.locationID = ORIGIN_LOCATION_ID;
	else
		storage.locationID = DESTINATION_LOCATION_ID;
}

-(IBAction)weightChanged:(NSString*)weight
{
	storage.weight = [weight intValue];
}

-(IBAction)save:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateMiniStorage:storage];
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
	/*SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.navController popViewControllerAnimated:YES];*/
}

/*
*/
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
	
	static NSString *THCellIdentifier = @"TextWithHeaderCell";
	static NSString *ODCellIdentifier = @"OrigDestCell";
	
    TextWithHeaderCell *thCell = nil;
	OrigDestCell *origDestCell = nil;
	
	if([indexPath row] == 0)
	{
		
		thCell = (TextWithHeaderCell*)[tableView dequeueReusableCellWithIdentifier:THCellIdentifier];
		if(thCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
			thCell = [nib objectAtIndex:0];
			thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		thCell.labelHeader.text = @"Weight";
		if(storage.weight == 0)
			thCell.labelText.text = @"(Shipment Weight)";
		else
			thCell.labelText.text = [NSString stringWithFormat:@"%d lbs.", storage.weight];
		
	}
	else
	{
		
		origDestCell = (OrigDestCell*)[tableView dequeueReusableCellWithIdentifier:ODCellIdentifier];
		if(origDestCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrigDestCell" owner:self options:nil];
			origDestCell = [nib objectAtIndex:0];
			
			[origDestCell.segmentOrigDest addTarget:self
			 action:@selector(locationChanged:) 
			 forControlEvents:UIControlEventValueChanged];
			
		}
		
		origDestCell.segmentOrigDest.selectedSegmentIndex = 
			storage.locationID == ORIGIN_LOCATION_ID ? ORIG_DEST_ORIGIN : ORIG_DEST_DESTINATION;
	}
	
    return thCell != nil ? (UITableViewCell*)thCell : (UITableViewCell*)origDestCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	[del pushSingleFieldController:[NSString stringWithFormat:@"%d",storage.weight] 
					   clearOnEdit:NO 
					  withKeyboard:UIKeyboardTypeNumberPad 
				   withPlaceHolder:@"Mini Storage Weight" 
						withCaller:self 
					   andCallback:@selector(weightChanged:) 
				 dismissController:YES];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	if([indexPath row] == 0)
		return YES;
	else
		return NO;
}

/*
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


- (void)dealloc {
    [super dealloc];
}


@end

