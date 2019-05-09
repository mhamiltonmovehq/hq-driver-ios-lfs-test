//
//  PVOFavoriteItemsByRoomController.m
//  Survey
//
//  Created by Jason Gorringe on 8/24/18.
//

#import "PVOFavoriteItemsByRoomController.h"
#import "SurveyAppDelegate.h"

@implementation PVOFavoriteItemsByRoomController

@synthesize favoriteItemsRooms, addItemRoomController, indexPathToDelete;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
    
    // Add menu bar items
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addRoom:)] init];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.favoriteItemsRooms = [NSMutableArray arrayWithArray:[[del.surveyDB getPVOFavoriteItemsRooms] init]];
    
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

#pragma mark - Selectors

-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)addRoom:(id)sender
{
    newNav = nil;
    
    if(addItemRoomController == nil)
        addItemRoomController = [[AddFavoriteItemRoomController alloc] initWithStyle:UITableViewStylePlain];
    addItemRoomController.title = @"Select Room";
    addItemRoomController.delegate = self;
    
    newNav = [[PortraitNavController alloc] initWithRootViewController:addItemRoomController];
    
    [self presentViewController:newNav animated:YES completion:nil];
}

#pragma mark - FavoriteItemsByRoomDelegate functions

// Called once a room is chosen from AddFavoriteItemRoomController, launches item selection
-(void)roomChosen:(Room*)room {
    // Get items for room
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* items = [del.surveyDB getPVOFavoriteItemsForRoom:room];
    
    newNav = nil;
    
    if(addItemsForRoomController == nil)
        addItemsForRoomController = [[AddFavoriteItemsForRoomController alloc] initWithStyle:UITableViewStylePlain];
    addItemsForRoomController.title = @"Select Items";
    addItemsForRoomController.delegate = self;
    addItemsForRoomController.room = room;
    addItemsForRoomController.favorites = [items copy];
    
    items = nil;
    
    newNav = [[PortraitNavController alloc] initWithRootViewController:addItemsForRoomController];
    
    [self presentViewController:newNav animated:YES completion:nil];
}

// Called once items are chosen from AddFavoriteItemsForRoomController, reloads room list
-(void)itemsChosen:(NSArray*)items forRoom:(Room*)room {
    // Items for room have been selected, make the change in the DB and reload the tableview
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB addPVOFavoriteItemRoom:room.roomID withItems:items];
    
    self.favoriteItemsRooms = [NSMutableArray arrayWithArray:[[del.surveyDB getPVOFavoriteItemsRooms] init]];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [favoriteItemsRooms count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([favoriteItemsRooms count] == 0)
        return @"Tap the plus sign to select a room to add favorites.";
    else
        return nil;
}

-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Get room
        Room *room = [favoriteItemsRooms objectAtIndex:indexPath.row];
        indexPathToDelete = indexPath;
        
        // Display an action sheet for the user to confirm that they want to delete the selected items
        NSString* asTitle = [NSString stringWithFormat:@"Are you sure that you would like to delete the favorite items list for %@?",room.roomName];
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:asTitle
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                             destructiveButtonTitle:@"Yes"
                                                  otherButtonTitles:nil];
        
        [sheet showInView:self.view];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] init];
    }
    
    Room *room = [favoriteItemsRooms objectAtIndex:indexPath.row];
    cell.textLabel.text = room.roomName;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Get room
    Room *chosenRoom = [favoriteItemsRooms objectAtIndex:indexPath.row];
    
    // Get items for room
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* items = [del.surveyDB getPVOFavoriteItemsForRoom:chosenRoom];
    
    newNav = nil;
    
    if(addItemsForRoomController == nil)
        addItemsForRoomController = [[AddFavoriteItemsForRoomController alloc] initWithStyle:UITableViewStylePlain];
    addItemsForRoomController.title = @"Select Items";
    addItemsForRoomController.delegate = self;
    addItemsForRoomController.room = chosenRoom;
    addItemsForRoomController.favorites = [items copy];
    
    items = nil;
    
    newNav = [[PortraitNavController alloc] initWithRootViewController:addItemsForRoomController];
    
    [self presentViewController:newNav animated:YES completion:nil];
}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        // Remove the specified room
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        Room *room = [favoriteItemsRooms objectAtIndex:indexPathToDelete.row];
        
        [del.surveyDB removePVOFavoriteItemRoom:room.roomID];
        
        [favoriteItemsRooms removeObjectAtIndex:indexPathToDelete.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathToDelete] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    indexPathToDelete = nil;
}

@end
