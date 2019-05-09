//
//  ThirdPartyController.m
//  Survey
//
//  Created by Tony Brame on 8/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ThirdPartyController.h"
#import "SurveyAppDelegate.h"

@implementation ThirdPartyController

@synthesize tableView, applied, choices, categoriesController, editingPath, locationID;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	self.contentSizeForViewInPopover = CGSizeMake(320, 416);
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	NSMutableDictionary *dict = [del.surveyDB getThirdPartyChoices];
	self.choices = dict;
	[dict release];
	
	self.title = @"Third Party";
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self
																						   action:@selector(addThirdPartyItem:)];
	
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	self.applied = [del.surveyDB getThirdPartyApplied:del.customerID withLocation:locationID];
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}


-(IBAction) doneEditingNote:(NSString*)note
{
	ThirdPartyApplied *app = [applied objectAtIndex:[editingPath row]];
	app.note = note;
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateThirdPartyApplied:app];
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(IBAction) addThirdPartyItem:(id)sender
{
	
	if(categoriesController == nil)
	{
		categoriesController = [[ThirdPartyCategoriesController alloc] initWithStyle:UITableViewStylePlain];
	}
	
	categoriesController.choices = choices;
	categoriesController.locID = locationID;
	
	[self.navigationController pushViewController:categoriesController animated:YES];
	
}


-(IBAction) switchLocation:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	self.applied = [del.surveyDB getThirdPartyApplied:del.customerID withLocation:locationID];
	
	[self.tableView reloadData];
	
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


- (void)dealloc {
	[tableView release];
	[applied release];
	[choices release];
	[categoriesController release];
	
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [applied count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	ThirdPartyApplied *app = [applied objectAtIndex:[indexPath row]];
	if([app.note length] > 0)
		cell.textLabel.text = [NSString stringWithFormat:@"%d - ** %@", app.quantity, app.description];
	else
		cell.textLabel.text = [NSString stringWithFormat:@"%d - %@", app.quantity, app.description];
	
    return cell;
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
	self.editingPath = indexPath;
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	ThirdPartyApplied *app = [applied objectAtIndex:[indexPath row]];
	
	[del pushNoteViewController:app.note 
				   withKeyboard:UIKeyboardTypeASCIICapable 
				   withNavTitle:@"Note" 
				withDescription:[NSString stringWithFormat:@"Note For: %@", app.description] 
					 withCaller:self 
					andCallback:@selector(doneEditingNote:) 
			  dismissController:YES
					   noteType:NOTE_TYPE_THIRD_PARTY
			   andNavController:self.navigationController];
	
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	return YES;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
	SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
	
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		ThirdPartyApplied *app = [applied objectAtIndex:[indexPath row]];
		[del.surveyDB deleteThirdPartyApplied:app.recID];
		
		self.applied = [del.surveyDB getThirdPartyApplied:del.customerID withLocation:locationID];
		
        // Animate the deletion from the table.
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
				  withRowAnimation:UITableViewRowAnimationFade];
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
