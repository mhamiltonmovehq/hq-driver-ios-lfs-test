//
//  PickerViewController.m
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PickerViewController.h"
#import "SurveyAppDelegate.h"

@implementation PickerViewController

@synthesize options, picker, callback, caller, keys, tableView, currentSelection, popover, isPickerPopover;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
 */

- (void)viewWillAppear:(BOOL)animated {
	
	self.keys = [[options allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	[tableView reloadData];
	[picker reloadComponent:0];
	 
    [super viewWillAppear:animated];
	
	if([currentSelection intValue] != -1)
	{
		for(int i = 0; i < [keys count]; i++)
		{
			if([currentSelection isEqualToNumber:[keys objectAtIndex:i]])
				[picker selectRow:i inComponent:0 animated:YES];
		}
	}
	else 
	{
		int row = [picker selectedRowInComponent:0];
		if(row != -1)
			[picker selectRow:-1 inComponent:0 animated:YES];
	}

	
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	if(!isPickerPopover)
		self.preferredContentSize = CGSizeMake(320, 416);
	else
	{
		self.view.frame = CGRectMake(0, 0, 320, 216);
		CGRect newFrame = self.picker.frame;
		newFrame.origin.y = 0;
		self.picker.frame = newFrame;
		self.preferredContentSize = CGSizeMake(320, 216);
		self.tableView.hidden = TRUE;
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
    [super viewDidLoad];
}

-(void) cancel:(id)sender
{
	if(popover != nil)
		[popover dismissPopoverAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

-(void) save:(id)sender
{
	
	if([caller respondsToSelector:callback])
	{
		int row = [picker selectedRowInComponent:0];
		//returns selected key (id)
		if(row != -1)
		{
			[caller performSelector:callback withObject:[keys objectAtIndex:row]];
		}
		else if([currentSelection intValue] == -1)
		{
			[caller performSelector:callback withObject:@""];			
		}

	}
	
	[self cancel:sender];
}

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

#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [keys count];
}

#pragma mark Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [options objectForKey:[keys objectAtIndex:row]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 295;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)thisTableView {
    return 0;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)thisTableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)thisTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [thisTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Set up the cell...
	cell.textLabel.text = @"Use Selected Agency";
	
    return cell;
}


- (void)tableView:(UITableView *)thisTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	[self save:thisTableView];
	
	[thisTableView deselectRowAtIndexPath:indexPath animated:YES];
	
}

@end
