//
//  EditSmartItemController.m
//  Survey
//
//  Created by Tony Brame on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditSmartItemController.h"
#import "SwitchCell.h"
#import "SurveyAppDelegate.h"
#import "NoteCell.h"
#import "TextCell.h"
#import "OrigDestCell.h"

@implementation EditSmartItemController

@synthesize item, currentView, currentField, selectItemController, thirdPartyScreen;

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
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
}



- (void)viewWillAppear:(BOOL)animated {
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	if(item.itemID != 0)
	{
		Item *i = [del.surveyDB getItem:item.itemID];
		self.title = i.name;
		[i release];
	}
	
    [super viewWillAppear:animated];
	
	[self.tableView reloadData];
	
}


- (void)viewDidAppear:(BOOL)animated {
	
	if(shownItemScreen && item.itemID == 0)
	{
		shownItemScreen = FALSE;
		[self.navigationController dismissModalViewControllerAnimated:YES];
	}
	else if(item.itemID == 0)
	{//pop up the select controller
		if(selectItemController == nil)
			selectItemController = [[DeleteItemController alloc] initWithStyle:UITableViewStylePlain];
		
		selectItemController.onlySelectAnItem = TRUE;
		selectItemController.caller = self;
		selectItemController.callback = @selector(itemSelected:);
		selectItemController.title = @"Select An Item";
		
		PortraitNavController *ctller = [[PortraitNavController alloc] initWithRootViewController:selectItemController];
		
		[self.navigationController presentModalViewController:ctller animated:YES];
		shownItemScreen = TRUE;
		
	}
	else
		shownItemScreen = FALSE;
	
    [super viewDidAppear:animated];
}

-(void)itemSelected:(Item*)newItem
{
	item.itemID = newItem.itemID;
}

-(void)thirdPartySelected:(ThirdPartyChoice*)tp
{
	item.thirdPartyServiceID = tp.tpID;
}

-(IBAction)switchChanged:(id)sender
{
	UISwitch *sw = sender;
	
	if(sw.tag == SMART_ITEM_MISC_ITEM_DISCOUNT_SWITCH)
	{
		item.miscItemDiscount = sw.on;
	}
	else 
	{
		switch(sw.tag)
		{
			case SMART_ITEM_NOTE:
				item.addNote = sw.on;
				break;
			case SMART_ITEM_THIRD_PARTY:
				item.addThirdParty = sw.on;
				break;
			case SMART_ITEM_MISC_ITEM:
				item.addMiscItem = sw.on;
				break;
		}
	}
	
	[self.tableView reloadData];
}

-(IBAction)origDestChanged:(id)sender
{
	UISegmentedControl *segment = sender;
	item.thirdPartyLocationID = segment.selectedSegmentIndex == ORIG_DEST_ORIGIN ? APPLY_SMART_ITEM_TP_ORIGIN : 
	segment.selectedSegmentIndex ==  ORIG_DEST_DESTINATION ? APPLY_SMART_ITEM_TP_DESTINATION :
	APPLY_SMART_ITEM_TP_BOTH;
}

-(IBAction)save:(id)sender
{
	if(item.itemID == 0)
	{
		[SurveyAppDelegate showAlert:@"You must have an item selected to save." withTitle:@"Select an item."];
		return;
	}
	
	if(item.addThirdParty && item.thirdPartyServiceID == 0)
	{
		[SurveyAppDelegate showAlert:@"You must have a third party item selected to save." withTitle:@"Select a third party item."];
		return;
	}
	
	if(currentField != nil)
		[self updateValueWithField:currentField];
	
	if(currentView != nil)
		[self updateValueWithView:currentView];
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateSmartItem:item];
	
	[self cancel:sender];
}

-(IBAction)cancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(void)updateValueWithField:(UITextField*)fld
{
	if(fld.tag == 1)
		item.miscItemDescription = fld.text;
	else
		item.miscItemCharge = [fld.text doubleValue];
}

-(void)updateValueWithView:(UITextView*)textView
{
	if(textView.tag == SMART_ITEM_NOTE)
		item.noteText = textView.text;
	else
		item.thirdPartyNote = textView.text;

}

-(IBAction)textFieldDoneEditing:(id) sender
{
	[sender resignFirstResponder];
}

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
    return SMART_ITEM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
		case SMART_ITEM_THIRD_PARTY:
			return item.addThirdParty ? 4 : 1;
		case SMART_ITEM_NOTE:
			return item.addNote ? 2 : 1;
		case SMART_ITEM_MISC_ITEM:
			return item.addMiscItem ? 4 : 1;
	}
	
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(([indexPath section] == SMART_ITEM_NOTE && [indexPath row] > 0) || 
	   ([indexPath section] == SMART_ITEM_THIRD_PARTY && [indexPath row] == 3))
		return 130;
	else
		return 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
    static NSString *BasicCellIdentifier = @"Cell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *NoteCellIdentifier = @"NoteCell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *OrigDestCellIdentifier = @"OrigDestCell";
	
	
	UITableViewCell *cell = nil;
	SwitchCell *swCell = nil;
	NoteCell *noteCell = nil;
	TextCell *textCell = nil;	
	OrigDestCell *odCell = nil;
	
	
	if(indexPath.row == 0 || 
	   ([indexPath section] == SMART_ITEM_MISC_ITEM && indexPath.row == 3))
	{
		swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
		
		if (swCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
			swCell = [nib objectAtIndex:0];
			[swCell.switchOption addTarget:self
									action:@selector(switchChanged:)
						  forControlEvents:UIControlEventValueChanged];
		}
		
		swCell.switchOption.tag = indexPath.section;
		
		if([indexPath section] == SMART_ITEM_MISC_ITEM && indexPath.row == 3)
		{
			swCell.switchOption.tag = SMART_ITEM_MISC_ITEM_DISCOUNT_SWITCH;
			swCell.labelHeader.text = @"Apply Discount";
			swCell.switchOption.on = item.miscItemDiscount;
		}
		else 
		{
			switch([indexPath section])
			{
				case SMART_ITEM_THIRD_PARTY:
					swCell.labelHeader.text = @"Add Third Party Item";
					swCell.switchOption.on = item.addThirdParty;
					break;
				case SMART_ITEM_NOTE:
					swCell.labelHeader.text = @"Add Customer Note";
					swCell.switchOption.on = item.addNote;
					break;
				case SMART_ITEM_MISC_ITEM:
					swCell.labelHeader.text = @"Add Misc Item";
					swCell.switchOption.on = item.addMiscItem;
					break;
			}
		}

		
	}
	else if([indexPath section] == SMART_ITEM_THIRD_PARTY && indexPath.row == 2)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicCellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		if(item.thirdPartyServiceID != 0)
		{
			ThirdPartyChoice *choice = [del.surveyDB getThirdPartyChoice:item.thirdPartyServiceID];
			cell.textLabel.text = choice.description;
			[choice release];
		}
		else
			cell.textLabel.text = @" <Please Select an Item> ";

	}
	else if([indexPath section] == SMART_ITEM_THIRD_PARTY && indexPath.row == 1)
	{
		odCell = (OrigDestCell*)[tableView dequeueReusableCellWithIdentifier:OrigDestCellIdentifier];
		if(odCell == nil)
		{
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OrigDestCell" owner:self options:nil];
			odCell = [nib objectAtIndex:0];
			[odCell.segmentOrigDest setTitle:@"Dest" forSegmentAtIndex:1];
			[odCell.segmentOrigDest insertSegmentWithTitle:@"Both" atIndex:2 animated:YES];
			
			[odCell.segmentOrigDest addTarget:self
									   action:@selector(origDestChanged:) 
							 forControlEvents:UIControlEventValueChanged];
		}
		
		if(item.thirdPartyLocationID == APPLY_SMART_ITEM_TP_ORIGIN)
			odCell.segmentOrigDest.selectedSegmentIndex = ORIG_DEST_ORIGIN;
		else if(item.thirdPartyLocationID == APPLY_SMART_ITEM_TP_DESTINATION)
			odCell.segmentOrigDest.selectedSegmentIndex = ORIG_DEST_DESTINATION;
		else
			odCell.segmentOrigDest.selectedSegmentIndex = 2;
				
	}
	else if(([indexPath section] == SMART_ITEM_NOTE && [indexPath row] > 0) || 
			([indexPath section] == SMART_ITEM_THIRD_PARTY && [indexPath row] == 3))
	{
		noteCell = (NoteCell*)[tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
		
		if (noteCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
			noteCell = [nib objectAtIndex:0];
			noteCell.tboxNote.delegate = self;
			/*[noteCell.tboxNote addTarget:self 
								  action:@selector(textFieldDoneEditing:) 
						forControlEvents:UIControlEventEditingDidEndOnExit];*/
		}
		
		noteCell.tboxNote.tag = indexPath.section;
		//noteCell.tboxNote.placeholder = @"Note To Add";
		if([indexPath section] == SMART_ITEM_NOTE)
		{
			noteCell.tboxNote.keyboardType = UIKeyboardTypeASCIICapable;
			noteCell.tboxNote.text = item.noteText;
		}
		else 
		{
			noteCell.tboxNote.keyboardType = UIKeyboardTypeASCIICapable;
			noteCell.tboxNote.text = item.thirdPartyNote;
		}

	}
	else if([indexPath section] == SMART_ITEM_MISC_ITEM) 
	{
		textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
		
		if (textCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
			textCell = [nib objectAtIndex:0];
			textCell.tboxValue.delegate = self;
			[textCell.tboxValue addTarget:self 
								   action:@selector(textFieldDoneEditing:) 
						 forControlEvents:UIControlEventEditingDidEndOnExit];
		}
		
		textCell.tboxValue.tag = [indexPath row];
		if([indexPath row] == 1)
		{
			textCell.tboxValue.placeholder = @"Description";
			textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
			textCell.tboxValue.text = item.miscItemDescription;
		}
		else
		{
			textCell.tboxValue.placeholder = @"Item Cost";
			textCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
			textCell.tboxValue.text = [SurveyAppDelegate formatDouble:item.miscItemCharge];
		}
	}


    
    // Configure the cell...
    
    return cell != nil ? cell : 
	swCell != nil ? (UITableViewCell*)swCell : 
	noteCell != nil ? (UITableViewCell*)noteCell : 
	odCell != nil ? (UITableViewCell*)odCell : (UITableViewCell*)textCell;
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
	
	if([indexPath section] == SMART_ITEM_THIRD_PARTY && [indexPath row] == 2)
	{//load third party select screen...
		if(thirdPartyScreen == nil)
			thirdPartyScreen = [[ThirdPartyCategoriesController alloc] initWithStyle:UITableViewStylePlain];
		
		thirdPartyScreen.onlySelectAService = TRUE;
		thirdPartyScreen.caller = self;
		thirdPartyScreen.callback = @selector(thirdPartySelected:);
		
		[self.navigationController pushViewController:thirdPartyScreen animated:YES];
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


- (void)dealloc {
	[item release];
	[currentView release];
	[currentField release];
	[selectItemController release];
	[thirdPartyScreen release];
    [super dealloc];
}


#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.currentField = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
}

#pragma mark UITextViewDelegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	self.currentView = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateValueWithView:textView];
}

@end

