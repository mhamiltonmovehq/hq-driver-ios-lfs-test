//
//  NoteViewController.m
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NoteViewController.h"
#import	"TextCell.h"
#import	"SurveyAppDelegate.h"
#import "NoteCell.h"

@implementation NoteViewController

@synthesize tboxCurrent, destString, description, navTitle, caller, callback, keyboard, /*clearOnEdit,*/ dismiss, modalView, noteType, commonNotes, popover, maxLength;

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

-(void)addStringToNote:(NSString*)note
{
	if(tboxCurrent != nil)
	{
		NSMutableString *current = [[NSMutableString alloc] initWithString:tboxCurrent.text];
		[current appendFormat:@"%@%@", (current.length == 0 ? @"" : @"\r\n"), note];
        if (maxLength > 0 && current.length > maxLength)
        {
            [SurveyAppDelegate showAlert:
             [NSString stringWithFormat:@"Notes length cannot exceed %d characters in length.", maxLength]
                               withTitle:@"Character Limit Exceeded"];
        }
        else
        {
            self.destString = current;
        }
	}
}

- (void)viewWillAppear:(BOOL)animated {
	
	self.title = navTitle;
	
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
		if(popover != nil)
		{
			[popover dismissPopoverAnimated:YES];
			[popover.delegate popoverControllerDidDismissPopover:popover];
		}
		else if (modalView)
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        else
            [self.navigationController popViewControllerAnimated:YES];
	}
	@catch(NSException *exc)
	{
		[SurveyAppDelegate handleException:exc];
	}
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 0)
		return 44;
	else
		return 130;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *NoteCellID = @"NoteCell";
    static NSString *BasicCellID = @"BasicCell";
	
	NoteCell *noteCell = nil;
	UITableViewCell *cell = nil;
	
	if([indexPath row] == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:BasicCellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicCellID];
		}
		
		if(noteType == NOTE_TYPE_NONE)
			cell.accessoryType = UITableViewCellAccessoryNone;
		else
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
		cell.textLabel.text = description;
	}
	else
	{
		
		noteCell = (NoteCell *)[tableView dequeueReusableCellWithIdentifier:NoteCellID];
		if (noteCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
			noteCell = [nib objectAtIndex:0];
			
			noteCell.tboxNote.returnKeyType = UIReturnKeyDefault;
			
		}
		
		noteCell.tboxNote.text = self.destString;
		noteCell.tboxNote.keyboardType = keyboard;
		//[noteCell.tboxNote becomeFirstResponder];
        if (maxLength > 0)
        {
            noteCell.tboxNote.delegate = self; //enforce length
            noteCell.tboxNote.tag = indexPath.row;
        }
		
		self.tboxCurrent = noteCell.tboxNote;
	}
	
    return cell != nil ? cell : (UITableViewCell*)noteCell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 0 && noteType != NOTE_TYPE_NONE)
		return indexPath;
	else
		return nil;	
}
	
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(tboxCurrent != nil)
	{
		self.destString = tboxCurrent.text;
	}
	
	if(commonNotes == nil)
	{
		self.commonNotes = [[CommonNotesController alloc] initWithStyle:UITableViewStyleGrouped];
		commonNotes.caller = self;
		commonNotes.callback = @selector(addStringToNote:);
	}
	
	commonNotes.noteType = noteType;
	[self.navigationController pushViewController:commonNotes animated:YES];
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

/*
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	if(destString != nil)
 
	
	self.destString = textField.text;
}
 */

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (maxLength <= 0) return YES;
    
    int row = textView.tag;
    if (row > 0) {
        NSString *newNote = [textView.text stringByReplacingCharactersInRange:range withString:text];
        if (newNote.length > maxLength)
        {
            [SurveyAppDelegate showAlert:
             [NSString stringWithFormat:@"Notes length cannot exceed %d characters in length.", maxLength]
                               withTitle:@"Character Limit Exceeded"];
            return NO;
        }
    }
    return YES;
}

@end

