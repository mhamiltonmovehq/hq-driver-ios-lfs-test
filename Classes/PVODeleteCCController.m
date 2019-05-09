//
//  PVODeleteCCController.m
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODeleteCCController.h"
#import "SurveyAppDelegate.h"
#import "SSCheckBoxView.h"

@implementation PVODeleteCCController

@synthesize keys, allItems, contentsDictionary, setupFavorites;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up top left cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self
                                                                                            action:@selector(done:)];
    
    // Set up top right Hide button
    if (!setupFavorites)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(hideChecked:)];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue"
                                                                                   style:UIBarButtonItemStyleDone
                                                                                  target:self
                                                                                  action:@selector(addFavorites:)];
    }
    
}

// Handle adding favorites within this view (separated this into a different controller, but leaving this method here in case any other legacy methods call it
-(void)addFavorites:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    for  (PVOCartonContent *item in _selectedItems)
    {
        [del.surveyDB addPVOFavoriteCartonContents:item.contentID];
    }
    [self done:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    // Allocate arrays
    self.selectedItems = [NSMutableArray array];
    self.itemsToUnhide = [NSMutableArray array];
    
    // Get all carton contents
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.allItems = [del.surveyDB getPVOAllCartonContents:@"" withCustomerID:del.customerID includeFavorites:-1 withHidden:YES];
    
    // Note which carton contents were already hidden when the view was opened
    for(PVOCartonContent* pvocc in self.allItems) {
        if(pvocc.isHidden == 1) {
            [_selectedItems addObject:pvocc];
        }
    }
    
    [self reloadContentsList];
}

-(IBAction)done:(id)sender
{
    // Close the view once finished
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideChecked:(id)sender
{
    // Show an alert if nothing was selected to be hidden
    if ([_selectedItems count] == 0 && self.itemsToUnhide.count == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more items before tapping the Hide button." withTitle:@"No Items Selected"];
        return;
    }
    
    // Display a confirmation
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure that you would like to modify the visibility of items in the carton contents list?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                         destructiveButtonTitle:@"Yes"
                                              otherButtonTitles:nil];
    
    [sheet showInView:self.view];
}

-(void)reloadContentsList
{
    // Reset selected carton contents array
    self.selectedItems = [NSMutableArray array];
    
    // Pull down all carton contents list
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.allItems = [del.surveyDB getPVOAllCartonContents:@"" withCustomerID:del.customerID includeFavorites:-1 withHidden:YES];
    
    // Note which carton contents were already hidden when the view was opened
    for(PVOCartonContent* pvocc in self.allItems) {
        if(pvocc.isHidden == 1) {
            [_selectedItems addObject:pvocc];
        }
    }
    
    // Set up variables for tableview setup
    NSMutableDictionary *itemsDict = [PVOCartonContent getDictionaryFromContentList:allItems];
	self.contentsDictionary = itemsDict;
	
	NSMutableArray *keysArray = [[NSMutableArray alloc] init];
	
	[keysArray addObjectsFromArray:[[contentsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]];
	
	self.keys = keysArray;
		
	[self.tableView reloadData];
	
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    // Force portrait
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [keys count];
}

-(NSString*) tableView: (UITableView*)tableView titleForHeaderInSection: (NSInteger) section
{
	NSString *key = [keys objectAtIndex:section];
	return key;
}

-(NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
	return keys;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *key = [keys objectAtIndex:section];
	NSArray *letterSection = [contentsDictionary objectForKey:key];
	return [letterSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2
    
    // The blocks below set up the individual cells in the tableview
    
    static NSString *CellIdentifier = @"PVODeleteCCControllerCell";
    
    UILabel *mainLabel;
    SSCheckBoxView *checkBox;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        checkBox = [[SSCheckBoxView alloc] initWithFrame:CGRectMake(4.0, 4.0, 30.0, 30.0)
                                                    style:kSSCheckBoxViewStyleGlossy
                                                  checked:NO];
        checkBox.tag = CHECK_BOX_TAG;
        [cell.contentView addSubview:checkBox];
        
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 280.0, 44.0)];
        mainLabel.tag = LABEL_TAG;
        mainLabel.font = [UIFont boldSystemFontOfSize:17.0];
        mainLabel.textAlignment = NSTextAlignmentLeft;
        mainLabel.textColor = [UIColor blackColor];
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
    }
    else
    {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
        checkBox = (SSCheckBoxView *)[cell.contentView viewWithTag:CHECK_BOX_TAG];
    }
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [contentsDictionary objectForKey:key];
    
    PVOCartonContent *contents = [letterSection objectAtIndex:[indexPath row]];
    NSString *hideStatus = @"";
    
    // If the carton content is hidden, mark it as soon on the tableview cell label
    if(contents.isHidden == 1) {
        hideStatus = @"(Hidden)";
    }
    
    // Set the label and checkbox
    mainLabel.text = [NSString stringWithFormat:@"%@    %@", contents.description,hideStatus];
    checkBox.checked = [_selectedItems containsObject:contents];

    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Handle a tableview cell click
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [contentsDictionary objectForKey:key];
    
    PVOCartonContent *contents = [letterSection objectAtIndex:[indexPath row]];
    
    // Add or remove it from the selected items and itemsToUnhide arrays as needed
    if ([_selectedItems containsObject:contents])
    {
        if(contents.isHidden == true) {
            // A previously hidden item has been unchecked - add to unhide list
            [self.itemsToUnhide addObject:contents];
        }
        [_selectedItems removeObject:contents];
    }
    else
    {
        if(contents.isHidden == true) {
            // A previously hidden item was unselected and is now reselected - remove from unhide list
            [self.itemsToUnhide addObject:contents];
        }
        [_selectedItems addObject:contents];
    }
    
    // Reload the table using the updated data source
    [tableView reloadData];

}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
//		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//        NSString *key = [keys objectAtIndex:[editPath section]];
//        NSArray *letterSection = [contentsDictionary objectForKey:key];
//        
//        PVOCartonContent *contents = [letterSection objectAtIndex:[editPath row]];
//		[del.surveyDB hidePVOCartonContent:contents.contentID];
//		
//        [self reloadContentsList];

        // Hide or unhide the carton content as necessary
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for (PVOCartonContent *item in _selectedItems)
        {
            [del.surveyDB hidePVOCartonContent:item.contentID];
		}
        for(PVOCartonContent *item in self.itemsToUnhide) {
            [del.surveyDB unhidePVOCartonContent:item.contentID];
        }
        
        // Close the view
		[self done:nil];
    }
}

@end
