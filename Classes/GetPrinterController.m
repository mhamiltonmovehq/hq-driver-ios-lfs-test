//
//  GetPrinterController.m
//  Survey
//
//  Created by Tony Brame on 6/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GetPrinterController.h"


@implementation GetPrinterController

@synthesize timer, selectedPrinter, ipController;

- (void)bonjourDiscoveryDidEndNotification:(NSNotification *)notification
{
	searching = FALSE;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	discovered = YES;
	[self.tableView reloadData];
}

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
    [super viewDidLoad];
	discoverPrinter = nil;
	
	self.title = @"Select A Printer";
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																		 target:self 
																		 action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = btn;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)beginSearch
{
	searching = TRUE;
	if(discoverPrinter == nil)
		discoverPrinter = [[ePrintDiscoverPrinter alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bonjourDiscoveryDidEndNotification:) name:ePrintDiscoverPrinterUpdateListNotification object:nil];
	
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:15. 
												  target:self 
												selector:@selector(discoveryTimedOut) 
												userInfo:nil 
												 repeats:YES];
	
	discovered = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;	
	
	if ( [discoverPrinter startDiscover:(ePrintSupportTypeLpr|ePrintSupportTypePort9100|ePrintSupportTypeAirPort|ePrintSupportTypeSharedPrinter)] ) {
	}
	
	
	[self.tableView reloadData];
}

- (void)discoveryTimedOut
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[discoverPrinter stopDiscover];
	[timer invalidate];
	searching = FALSE;
	[self.tableView reloadData];
}



- (void)viewWillAppear:(BOOL)animated {
	
	[self beginSearch];
	
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(!discovered && !searching)
		return 2;
	else if(discovered)
		return [discoverPrinter serviceCount];
	else
		return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	if(!discovered && searching)
	{
		cell.textLabel.text = @"Searching Printers...";
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if(!discovered && !searching)
	{
		if(indexPath.row == 0)
		{
			cell.textLabel.text = @"Re-try Search";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else 
		{
			cell.textLabel.text = @"Manually Enter IP Address";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
	}
	else if(discovered)
	{
		cell.textLabel.text = [discoverPrinter nameAtIndex:indexPath.row];
	}
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
	if(!discovered && !searching && section == 0)
		return @"We were not able to discover your printer. Please verify your network connections, and try again. If you know the ip address of your printer, select to enter manually below.";
	else		
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if(discovered)
	{
		//set address, kind, then move to the next controller
		StoredPrinter *newPrinter = [[StoredPrinter alloc] init];
		newPrinter.isBonjour = YES;
		newPrinter.bonjourSettings = [discoverPrinter serviceAtIndex:indexPath.row];
		newPrinter.name = [discoverPrinter nameAtIndex:indexPath.row];
		newPrinter.printerKind = [[[discoverPrinter printerInformation:newPrinter.bonjourSettings] 
								   objectForKey:ePrintInformationPrinterKind] 
								  intValue];
		
		self.selectedPrinter = newPrinter;
		
		//		
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	}
	else if(!discovered && !searching)
	{
		if(indexPath.row == 0)
		{
			[self beginSearch];
		}
		else 
		{
			//load the IPAddress Controller...
			if(ipController == nil)
				ipController = [[PrinterIPController alloc] initWithStyle:UITableViewStyleGrouped];
			
			ipController.sendMeThePrinter = @selector(sendMeAPrinter:);
			ipController.printerReceptacle = self;
			[self.navigationController pushViewController:ipController animated:YES];
		}
		
	}
}

-(void)sendMeAPrinter:(StoredPrinter*)printer
{
	self.selectedPrinter = printer;
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

