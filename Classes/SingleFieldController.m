//
//  SingleFieldController.m
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SingleFieldController.h"
#import	"TextCell.h"
#import	"SurveyAppDelegate.h"


@implementation SingleFieldController

@synthesize tboxCurrent, destString, placeholder, title, caller, callback, keyboard, clearOnEdit, dismiss, modal, requireValue;
@synthesize autocapitalizationType;

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		dismiss = TRUE;
    }
    return self;
}

- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	
	self.clearsSelectionOnViewWillAppear = YES;
	self.preferredContentSize = CGSizeMake(320, 416);
	
	//if new customer view, add buttons and handlers.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
	
    if (title == nil || [title isEqualToString:@""])
        self.title = placeholder;
    else
        self.title = title;
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

/*
*/

/*

*/

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
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

- (void)viewWillDisappear:(BOOL)animated {
		
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


//functions called when in the new customer view
-(IBAction)save:(id)sender
{
	
	if(tboxCurrent != nil)
	{
		self.destString = tboxCurrent.text;
		//self.tboxCurrent = nil;
	}
    
    if (requireValue)
    {
        if (self.destString == nil || [[destString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
        {
            [SurveyAppDelegate showAlert:@"The value entered cannot be empty. Please enter a value to save." withTitle:@"Invalid Data"];
            return; //require data before save
        }
    }
	
	if([caller respondsToSelector:callback] /*&& destString != nil*/)
	{
		[caller performSelector:callback withObject:destString];
	}
	
	//call cancel to clear the view
	if(dismiss)
	{
		[self cancel:nil];
	}
	
}


-(IBAction)cancel:(id)sender
{
	@try 
	{
        if (modal)
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        else
            [self.navigationController popViewControllerAnimated:YES];
		
		self.destString = nil;
	}
	@catch(NSException *exc)
	{
		[SurveyAppDelegate handleException:exc];
	}
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
    
    static NSString *TextCellID = @"TextCell";
	
	TextCell *textCell;
	textCell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:TextCellID];
	if (textCell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
		textCell = [nib objectAtIndex:0];
		
		textCell.tboxValue.returnKeyType = UIReturnKeyDone;
		
	}
	
	textCell.tboxValue.text = destString;
	textCell.tboxValue.keyboardType = keyboard;
	textCell.tboxValue.placeholder = placeholder;
	textCell.tboxValue.clearsOnBeginEditing = clearOnEdit;
    textCell.tboxValue.autocapitalizationType = autocapitalizationType;
	/*if(![textCell.tboxValue isFirstResponder]) -- causing an error
		[textCell.tboxValue becomeFirstResponder];*/
	
	self.tboxCurrent = textCell.tboxValue;
	
    return textCell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;	
}
	
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
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

//#pragma mark Text Field Delegate Methods
/*
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	if(destString != nil)
		
	
	self.destString = textField.text;
}*/


@end

