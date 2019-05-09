//
//  PurgeController.m
//  Survey
//
//  Created by Tony Brame on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PurgeController.h"
#import "SurveyAppDelegate.h"
#import "CustomerListItem.h"

@implementation PurgeController

@synthesize purge;


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(IBAction)dateSelected:(NSDate*)date
{
	self.purge = date;
	//seconds
	NSTimeInterval interval;
	interval = 1;
	//one sec
	interval *= 60;
	//one min
	interval *= 60;
	//one hour
	interval *= 24;
	//one day
	interval *= 60;
	//sixty days
	interval *= -1;
	if([purge compare:[[NSDate date] dateByAddingTimeInterval:interval]] == NSOrderedDescending)
	{
		[SurveyAppDelegate showAlert:@"It is not recommended that you select a date within 60 days from the current date." withTitle:@"Warning"];
	}
	
	[self.tableView reloadData];
	
}

-(IBAction)save:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CustomerFilterOptions *options = [[CustomerFilterOptions alloc] init];
    options.dateFilter = SHOW_DATE_LOAD;
    options.statusFilter = SHOW_STATUS_ALL;
	NSArray *items = [del.surveyDB getCustomerList:options];
    
	CustomerListItem *item;
	int count = 0;
	for(int i = 0; i < [items count]; i++)
	{
		item = [items objectAtIndex:i];
		if([item.date compare:purge] == NSOrderedAscending)
		{
			count++;
		}
	}
	
	if(count > 0)
	{
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:
                                [NSString stringWithFormat:@"You are about to delete %d customer(s) from %@.  This data CAN NOT be retrieved. Would you like to continue?", count, @"Mobile Mover"]
														   delegate:self 
												  cancelButtonTitle:@"No" 
											 destructiveButtonTitle:@"Yes" 
												  otherButtonTitles:nil];
		
		[sheet showInView:self.view];
		
	}
	else 
	{
		[SurveyAppDelegate showAlert:@"There are no customers that match the provided criteria." withTitle:@"Warning"];
	}

	
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	cell.textLabel.text = [formatter stringFromDate:self.purge];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
	return @"Purge Date:";
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
	return @"Customers with a load date prior\r\nto selection will be deleted.";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	[del pushSingleDateViewController:purge 
						 withNavTitle:@"Purge Date" 
						   withCaller:self 
						  andCallback:@selector(dateSelected:)
					 andNavController:self.navigationController
                     usingOldCallback:TRUE];
	
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

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
        CustomerFilterOptions *options = [[CustomerFilterOptions alloc] init];
        options.dateFilter = SHOW_DATE_LOAD;
        options.statusFilter = SHOW_STATUS_ALL;
        NSArray *items = [del.surveyDB getCustomerList:options];
        
        
		CustomerListItem *item;
		for(int i = 0; i < [items count]; i++)
		{
			item = [items objectAtIndex:i];
			if([item.date compare:purge] == NSOrderedAscending)
			{
				[del.surveyDB deleteCustomer:item.custID];
			}
		}
		[self cancel:nil];
	}
}

@end

