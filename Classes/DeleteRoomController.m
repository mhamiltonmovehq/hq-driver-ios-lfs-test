//
//  DeleteRoomController.m
//  Survey
//
//  Created by Tony Brame on 11/16/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DeleteRoomController.h"
#import "SurveyAppDelegate.h"
#import "Room.h"
#import "SSCheckBoxView.h"

@implementation DeleteRoomController

@synthesize allRooms, keys;

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
    
    // Create selected rooms array
    self.selectedRooms = [NSMutableArray array];
    self.roomsToUnhide = [NSMutableArray array];
    
    // Create all rooms array
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *rooms = (NSMutableArray*)[del.surveyDB getAllRoomsList:del.customerID withHidden:true];
    
    // Note which rooms were hidden when the view was opened
    for(Room* room in rooms) {
        if(room.isHidden == 1) {
            [_selectedRooms addObject:room];
        }
    }
    
    self.allRooms = [Room getDictionaryFromRoomList:rooms];
    
    // Create all keys array (the 'key' here is the first letter of the room name, aka its table section)
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allRooms allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    // Release object references and reload the tableview
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
    [self reloadRoomsList];
}

-(IBAction)done:(id)sender
{
    // Will dismiss this view when requested
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideChecked:(id)sender
{
    // Display an error message if a user tries to hide 0 rooms
    if ([_selectedRooms count] == 0 && self.roomsToUnhide.count == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more rooms before tapping the Hide button." withTitle:@"No Rooms Selected"];
        return;
    }
    
    // Display an action sheet for the user to confirm that they want to delete the selected rooms
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure that you would like to modify the checked rooms list?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                         destructiveButtonTitle:@"Yes"
                                              otherButtonTitles:nil];
    
    [sheet showInView:self.view];
}

-(void)reloadRoomsList
{
    // Reset list of selected rooms
    self.selectedRooms = [NSMutableArray array];
    
    // Get all rooms list
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *rooms = (NSMutableArray*)[del.surveyDB getAllRoomsList:del.customerID withHidden:true];
    
    // Note which rooms were hidden when the view was opened
    for(Room* room in rooms) {
        if(room.isHidden == 1) {
            [_selectedRooms addObject:room];
        }
    }
    
    // Update the information below for the tableview
    self.allRooms = [Room getDictionaryFromRoomList:rooms];
    
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allRooms allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
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
    NSArray *letterSection = [allRooms objectForKey:key];
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
    
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2
    
    // The blocks below set up the tableview cells
    
    static NSString *CellIdentifier = @"RoomDeleteControllerCell";
    
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
    NSArray *letterSection = [allRooms objectForKey:key];
    
    Room* room = [letterSection objectAtIndex:[indexPath row]];
    NSString *hideStatus = @"";
    
    // Mark hidden rooms as hidden in the tableivew
    if(room.isHidden == 1) {
        hideStatus = @"(Hidden)";
    }
    
    // Set the label and checkbox for the cell
    mainLabel.text = [NSString stringWithFormat:@"%@    %@", room.roomName,hideStatus];
    checkBox.checked = [_selectedRooms containsObject:room];
    
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
    // Get information about the current cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [allRooms objectForKey:key];
    
    Room *contents = [letterSection objectAtIndex:[indexPath row]];
    
    // Add the room to the selected rooms or roomsToHide arrays as necessary
    if ([_selectedRooms containsObject:contents])
    {
        if(contents.isHidden == true) {
            // A previously hidden item has been unchecked - add to unhide list
            [self.roomsToUnhide addObject:contents];
        }
        [_selectedRooms removeObject:contents];
    }
    else
    {
        if(contents.isHidden == true) {
            // A previously hidden item was unselected and is now reselected - remove from unhide list
            [self.roomsToUnhide addObject:contents];
        }
        [_selectedRooms addObject:contents];
    }
    
    // Reload the table using the updated data source
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
        
        // Hide or unhide the room as necessary
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for (Room *room in _selectedRooms)
        {
            [del.surveyDB hideRoom:room.roomID];
        }
        for(Room *room in self.roomsToUnhide) {
            [del.surveyDB unHideRoom:room.roomID];
        }
        
        // Close the view
        [self done:nil];
    }
    
    // editpath release was here
}

@end

