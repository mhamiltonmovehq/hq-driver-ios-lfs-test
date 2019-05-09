//
//  DeleteItemController.m
//  Survey
//
//  Created by Tony Brame on 11/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DeleteItemController.h"
#import "SurveyAppDelegate.h"
#import "Item.h"
#import "SSCheckBoxView.h"

@implementation DeleteItemController

@synthesize allItems, keys, customerId, ignoreItemListId;

- (id)init {
    ignoreItemListId = FALSE;
    return [super init];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        ignoreItemListId = FALSE;
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
    
    // Initialize the top-left cancel button
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                               target:self
                                                                                           action:@selector(done:)];
    
    // Initialize the top-right hide button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                               style:UIBarButtonItemStyleDone
                                                                                                target:self
                                                                              action:@selector(hideChecked:)];
    
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
    
    // Create selected items array
    self.selectedItems = [NSMutableArray array];
    self.itemsToUnhide = [NSMutableArray array];
    
    // Create all items array
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    // OT 20829 - do not make this depend on cust/item lists, must set customerId/list before appearing
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getAllItems:true withCustomerID:customerId withHidden:true ignoreItemListId:ignoreItemListId];
    
#ifdef ATLASNET
    // add special product items if atlasnet
    [items addObjectsFromArray:[del.surveyDB getAllSpecialProductItemsWithCustomerID:del.customerID]];
#endif
    
    // Remove CP/PBO/Bulky - cannot be removed as they are defined in the tariff
    NSMutableArray* toRemove = [NSMutableArray array];
    for(Item* item in items) {
        if(item.isCP || item.isPBO || item.isBulky) {
            [toRemove addObject:item];
        }
        if(item.isHidden == 1) {
            [_selectedItems addObject:item];
        }
    }
    for(Item* item in toRemove) {
        [items removeObject:item];
    }
    
    self.allItems = [Item getDictionaryFromItemList:items];
    
    // Create all keys array (the 'key' here is the first letter of the item name, aka its table section)
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
    [self reloadItemsList];
}

-(IBAction)done:(id)sender
{
    // Will dismiss this view when requested
    [self dismissViewControllerAnimated:YES completion:nil];
 }

- (void)hideChecked:(id)sender
{
    // Display an error message if a user tries to hide 0 items
    if ([_selectedItems count] == 0 && self.itemsToUnhide.count == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more items before tapping the Hide button." withTitle:@"No Items Selected"];
        return;
 }

    // Display an action sheet for the user to confirm that they want to delete the selected items
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure that you would like to modify the visibility of items in the carton contents list?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                         destructiveButtonTitle:@"Yes"
                                              otherButtonTitles:nil];
    
    [sheet showInView:self.view];
    

}

-(void)reloadItemsList
{
    // Reset selected items list
    self.selectedItems = [NSMutableArray array];

    // Get all items list
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getAllItems:true withCustomerID:customerId withHidden:true ignoreItemListId:ignoreItemListId];

#ifdef ATLASNET
    // add special product items
    [items addObjectsFromArray:[del.surveyDB getAllSpecialProductItemsWithCustomerID: customerId]];
#endif
    
    // Remove CP/PBO/Bulky - cannot be removed as they are defined in the tariff
    NSMutableArray* toRemove = [NSMutableArray array];
    for(Item* item in items) {
        if(item.isCP || item.isPBO || item.isBulky) {
            [toRemove addObject:item];
}
        if(item.isHidden == 1) {
            [_selectedItems addObject:item];
        }
    }
    for(Item* item in toRemove) {
        [items removeObject:item];
    }

    self.allItems = [Item getDictionaryFromItemList:items];

    NSMutableArray *keysArray = [[NSMutableArray alloc] init];

    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];

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
    NSArray *letterSection = [allItems objectForKey:key];
    return [letterSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    static NSString *CellIdentifier = @"Cell";
    //
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    
    // The blocks below set up the individual tableview cells
    
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2
    
    static NSString *CellIdentifier = @"ItemDeleteControllerCell";
    
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
    NSArray *letterSection = [allItems objectForKey:key];
    
    Item *item = [letterSection objectAtIndex:[indexPath row]];
    NSString *cube = [item cubeString];
    NSString *hideStatus = @"";
    
    // Mark the cell as hidden if the item is hidden
    if(item.isHidden == 1) {
        hideStatus = @"(Hidden)";
        }
    
    // Set the label and checkbox for the cell
    mainLabel.text = [NSString stringWithFormat:@"%@    %@    %@", item.name, cube,hideStatus];
    checkBox.checked = [_selectedItems containsObject:item];
    
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
    NSArray *letterSection = [allItems objectForKey:key];
    
    Item *item = [letterSection objectAtIndex:[indexPath row]];
    
    // Add the item to the selected items or itemsToHide arrays as necessary
    if ([_selectedItems containsObject:item])
    {
        if(item.isHidden == true) {
            // A previously hidden item has been unchecked - add to unhide list
            [self.itemsToUnhide addObject:item];
        }
        [_selectedItems removeObject:item];
    }
    else
    {
        if(item.isHidden == true) {
            // A previously hidden item was unselected and is now reselected - remove from unhide list
            [self.itemsToUnhide addObject:item];
        }
        [_selectedItems addObject:item];
    }
    
    [tableView reloadData];
    
}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        //        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        //        NSString *key = [keys objectAtIndex:[editPath section]];
        //        NSArray *letterSection = [contentsDictionary objectForKey:key];
        //
        //        PVOCartonContent *contents = [letterSection objectAtIndex:[editPath row]];
        //        [del.surveyDB hidePVOCartonContent:contents.contentID];
        //
        //        [self reloadContentsList];
        
        // Hide or unhide the item as necessary
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for (Item *item in _selectedItems) {
        [del.surveyDB hideItem:item.itemID];
        }
        for(Item *item in self.itemsToUnhide) {
            [del.surveyDB unHideItem:item.itemID];
        }
        
        // Close the view
        [self done:nil];
    }
    
}

@end
