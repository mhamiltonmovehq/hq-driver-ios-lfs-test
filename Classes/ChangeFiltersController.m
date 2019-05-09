//
//  ChangeFiltersController.m
//  Survey
//
//  Created by Tony Brame on 10/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ChangeFiltersController.h"
#import "SurveyAppDelegate.h"

@implementation ChangeFiltersController

@synthesize filters, sort, status, dates, popover;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
	self.preferredContentSize = CGSizeMake(320, 416);
	
	self.title = @"Change Filters";
	
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)];
    
}



- (void)viewWillAppear:(BOOL)animated {
	
	[self initializeLists];
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

-(void)initializeLists
{
	self.sort = [NSMutableDictionary dictionary];
	self.status = [NSMutableDictionary dictionary];
	self.dates = [NSMutableDictionary dictionary];
	
	[sort setObject:@"Name" forKey:[NSNumber numberWithInt:SORT_BY_NAME]];
	[sort setObject:@"Date" forKey:[NSNumber numberWithInt:SORT_BY_DATE]];
	[sort setObject:@"Order Number" forKey:[NSNumber numberWithInt:SORT_BY_ORDER_NUMBER]];
	
	[dates setObject:@"Order Number" forKey:[NSNumber numberWithInt:SHOW_ORDER_NUMBER]];
	[dates setObject:@"Survey Date" forKey:[NSNumber numberWithInt:SHOW_DATE_SURVEY]];
	[dates setObject:@"Pack Date" forKey:[NSNumber numberWithInt:SHOW_DATE_PACK]];
	[dates setObject:@"Load Date" forKey:[NSNumber numberWithInt:SHOW_DATE_LOAD]];
	[dates setObject:@"Deliver Date" forKey:[NSNumber numberWithInt:SHOW_DATE_DELIVER]];
	[dates setObject:@"Follow Up Date" forKey:[NSNumber numberWithInt:SHOW_DATE_FOLLOWUP]];
	[dates setObject:@"Decision Date" forKey:[NSNumber numberWithInt:SHOW_DATE_DECISION]];
	
	[status setObject:@"All" forKey:[NSNumber numberWithInt:SHOW_STATUS_ALL]];
	[status setObject:@"Estimate" forKey:[NSNumber numberWithInt:SHOW_STATUS_ESTIMATE]];
	[status setObject:@"Booked" forKey:[NSNumber numberWithInt:SHOW_STATUS_BOOKED]];
	[status setObject:@"Lost" forKey:[NSNumber numberWithInt:SHOW_STATUS_LOST]];
	[status setObject:@"Closed" forKey:[NSNumber numberWithInt:SHOW_STATUS_CLOSED]];
	[status setObject:@"OA" forKey:[NSNumber numberWithInt:SHOW_STATUS_OA]];
	
}

-(IBAction)done:(id)sender
{
	if(popover != nil)
	{
		[popover dismissPopoverAnimated:YES];
		[popover.delegate popoverControllerDidDismissPopover:popover];
	}
	else
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)valueUpdated:(NSNumber*)newValue
{
	switch (editRow) {
		case 0:
			filters.sortBy = [newValue intValue];
			break;
		case 1:
			filters.dateFilter = [newValue intValue];
			break;
		case 2:
			filters.statusFilter = [newValue intValue];
			break;
	}
}

-(void)dateUpdated:(NSDate*)date withIgnore:(NSDate*)ignore
{
	filters.date = date;
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    //hide the date selection if we are showing order number...
    return filters.dateFilter == SHOW_ORDER_NUMBER ? 3 : 4;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	if([indexPath row] == 0)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"Sort By: %@", [sort objectForKey:[NSNumber numberWithInt:filters.sortBy]]];
	}
	
	if([indexPath row] == 1)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"2nd Column: %@", [dates objectForKey:[NSNumber numberWithInt:filters.dateFilter]]];
	}
	
	if([indexPath row] == 2)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"Filter By Status: %@", [status objectForKey:[NSNumber numberWithInt:filters.statusFilter]]];
	}
	if([indexPath row] == 3)
	{
		NSString *display = @"All";
		if(filters.date != nil)
			display = [SurveyAppDelegate formatDate:filters.date]; 
		
		cell.textLabel.text = [NSString stringWithFormat:@"Show Date: %@", display];
	}
    
    return cell;
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


#pragma mark -
#pragma mark Table view delegate

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
    /*if(filters.dateFilter == SHOW_ORDER_NUMBER)
        return @"To Remove Filter Date, Right swipe on Date, and tap Delete.";
    else*/
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *values;
	NSString *header = @"";
	NSNumber *num;
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	editRow = [indexPath row];
	
	if(editRow == 3)
	{
		[del pushSingleDateViewController:filters.date == nil ? [NSDate date] : filters.date
							 withNavTitle:@"Show Date" 
							   withCaller:self 
							  andCallback:@selector(dateUpdated:withIgnore:) 
						 andNavController:self.navigationController];
	}
	else
	{
		if([indexPath row] == 0)
		{
			header = @"Sort By";
			values = sort;
			num = [NSNumber numberWithInt:filters.sortBy];
		}
		else if([indexPath row] == 1)
		{
			header = @"2nd Column";
			values = dates;
			num = [NSNumber numberWithInt:filters.dateFilter];
		}
		else if([indexPath row] == 2)
		{
			header = @"Status Filter";
			values = status;
			num = [NSNumber numberWithInt:filters.statusFilter];
		}
		
		[del pushPickerViewController:header 
						  withObjects:values 
				 withCurrentSelection:num 
						   withCaller:self 
						  andCallback:@selector(valueUpdated:) 
					 andNavController:self.navigationController];
	}
	
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	
	if ([indexPath row] == 3)
	{
		return YES;
	}
	
    return NO;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		filters.date = nil;
		[tv reloadData];
		
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


@end

