//
//  PrinterBonjourController.m
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PrinterBonjourController.h"
#import "StoredPrinter.h"
#import "PrinterNameController.h"

@implementation PrinterBonjourController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	discoverPrinter = [[ePrintDiscoverPrinter alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bonjourDiscoveryDidEndNotification:) name:ePrintDiscoverPrinterUpdateListNotification object:nil];
}



- (void)viewWillAppear:(BOOL)animated {
	
	discovered = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;	
	
	if ( [discoverPrinter startDiscover:(ePrintSupportTypeLpr|ePrintSupportTypePort9100|ePrintSupportTypeAirPort|ePrintSupportTypeSharedPrinter)] ) {
	}
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)bonjourDiscoveryDidEndNotification:(NSNotification *)notification
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	discovered = YES;
	[self.tableView reloadData];
}



- (void)viewWillDisappear:(BOOL)animated {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	
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
    return discovered ? [discoverPrinter serviceCount] : 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	if(!discovered)
	{
		cell.textLabel.text = @"Searching Printers...";
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		cell.textLabel.text = [discoverPrinter nameAtIndex:indexPath.row];
	}
	
    return cell;
}


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
		
		PrinterNameController *ctl = [[PrinterNameController alloc] initWithStyle:UITableViewStyleGrouped];
		ctl.printer = newPrinter;
		[self.navigationController pushViewController:ctl animated:YES];
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


@end

