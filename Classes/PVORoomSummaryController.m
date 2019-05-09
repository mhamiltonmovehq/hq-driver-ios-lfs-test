//
//  PVORoomSummaryController.m
//  Survey
//
//  Created by Tony Brame on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVORoomSummaryController.h"
#import "SurveyAppDelegate.h"
#import "PVOItemDetail.h"
#import "RoomSummaryCell.h"
#import "PVONavigationController.h"
#import "RoomSummary.h"
#import "RootViewController.h"

@implementation PVORoomSummaryController

@synthesize itemSummary, rooms, addRoomController, portraitNavController, inventory, tableView, toolbar, currentLoad;
@synthesize isPackersInvSummary, cmdComplete;
@synthesize cmdMaintenance, itemDelete, roomDelete, contentsDelete, favorites;
@synthesize lastRoomID, currentUnload;

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
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];

	self.title = @"Rooms";
	
	self.rooms = [NSMutableArray array];
	
    if (!isPackersInvSummary)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(addRoom:)];
    else
        self.navigationItem.rightBarButtonItem = nil;
    
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    if (!isPackersInvSummary)
        self.inventory = [del.surveyDB getPVOData:del.customerID];
    
    if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
        self.title = @"Location";
    else
        self.title = @"Rooms";
    
    if (![self isUnload])
    {
        if (!isPackersInvSummary)
            self.rooms = (NSMutableArray *)[del.surveyDB getPVORooms:currentLoad.pvoLoadID withCustomerID:del.customerID];
        else
            self.rooms = [del.surveyDB getPVOReceivableRooms:del.customerID];
    }
    else
    {
        self.rooms = (NSMutableArray *)[del.surveyDB getPVODestinationRooms:currentUnload.pvoLoadID];
 
    }
    
    
    if (isPackersInvSummary)
    {//remove from view
        if(tableView.superview != nil)
        {
            [self hideToolbar];
        }
    }
    else
    {
        [self setupToolbarItems];
    }
    
	[self.tableView reloadData];
	
    
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
    
    if ([self isUnload])
    {// hide if it's destination rooms
        [self hideToolbar];
    }
    
}

-(void)hideToolbar {
    CGRect frame = self.tableView.frame;
    frame.size.height += toolbar.frame.size.height;
    tableView.frame = frame;
    [toolbar removeFromSuperview];
}

-(BOOL)isUnload {
    if (currentUnload != nil && currentUnload.pvoLoadID > 0)
        return YES;
    return NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!self.quickAddPopupLoaded && self.rooms.count == 0 && [del.surveyDB getDriverData].quickInventory)
    {
        [self addRoom:nil];
    }
    else if (self.forceLaunchAddPopup)
    {
        [self addRoom:nil];
    }
}

-(void)setupToolbarItems
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    if (driver.driverType == PVO_DRIVER_TYPE_PACKER)
    {
        if (![self.toolbar.items containsObject:self.cmdMaintenance])
        {//add maintenance
            NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
            [toolbarItems insertObject:self.cmdMaintenance atIndex:2];
            [self.toolbar setItems:toolbarItems animated:NO];
        }
    }
    else if ([self.toolbar.items containsObject:self.cmdMaintenance])
    {//remove maintenance
        NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
        [toolbarItems removeObject:self.cmdMaintenance];
        [self.toolbar setItems:toolbarItems animated:NO];
    }
}


-(IBAction)addRoom:(id)sender
{
    if (!self.viewHasAppeared)
        return;
    
    self.quickAddPopupLoaded = YES;
    
	if(addRoomController == nil)
		addRoomController = [[AddRoomController alloc] initWithStyle:UITableViewStylePlain];
	
    addRoomController.delegate = self;
	addRoomController.caller = self;
	addRoomController.callback = @selector(roomAdded:);
    
    if (![self isUnload])
        addRoomController.pvoLocationID = currentLoad.pvoLocationID;
	else
        addRoomController.pvoLocationID = currentUnload.pvoLocationID;
    
	portraitNavController = [[PortraitNavController alloc] initWithRootViewController:addRoomController];
    
    // fix for defect# - sets last packer initials to null upon adding a new room
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.lastPackerInitials = nil;
	
	[self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
}

-(void)roomAdded:(Room*)room
{
	[self gotoRoom:room];
}

-(void)textValueEntered:(NSString*)newValue
{
    inventory.weightFactor = [newValue doubleValue];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB updatePVOData:inventory];
}


-(IBAction)cmdFinishedClick:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Confirm" 
                                                    message:@"Are you sure you would like to mark this inventory as completed?" 
                                                   delegate:self 
                                          cancelButtonTitle:@"No" 
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

-(IBAction)cmdMaintenance:(id)sender
{
    UIActionSheet *sheet = nil;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Changes will be enforced on the Master Item/Room list."
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Skip Item Number", @"Hide Items", @"Hide Rooms", @"Hide Carton Contents", @"Setup Favorites",
                 [NSString stringWithFormat:@"Weight Factor: %@", [SurveyAppDelegate formatDouble:inventory.weightFactor]], nil];
    }
    else
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Changes will be enforced on the Master Item/Room list."
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Skip Item Number", @"Hide Items", @"Hide Rooms", @"Hide Carton Contents", @"Setup Favorites", nil];
    }
    sheet.tag = ACTION_SHEET_LIST_MAINTENANCE;
    [sheet showInView:self.view];
}

-(void)gotoRoom:(Room*)room
{
    if (currentUnload != nil)
    {
        // pop the view controller
        [addRoomController cancel:nil];
        
        if(roomConditions == nil)
            roomConditions = [[PVORoomConditionsController alloc] initWithStyle:UITableViewStyleGrouped];
        
        roomConditions.room = room;
        roomConditions.currentLoad = nil;
        roomConditions.currentUnload = currentUnload;
        
        if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
            roomConditions.title = @"Location Conditions";
        else
            roomConditions.title = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";
        
        portraitNavController = [[PortraitNavController alloc] initWithRootViewController:roomConditions];
        
        [self presentViewController:portraitNavController animated:YES completion:nil];
    }
    else 
    {
        if(itemSummary == nil)
            itemSummary = [[PVOItemSummaryController alloc] initWithNibName:@"PVOItemSummaryView" bundle:nil];
        
        itemSummary.title = room.roomName;
        itemSummary.room = room;
        //        itemSummary.inventory = inventory;
        itemSummary.currentLoad = currentLoad;
        itemSummary.isPackersInvSummary = isPackersInvSummary;
        itemSummary.quickAddPopupLoaded = NO;
        itemSummary.wentToRoomConditions = FALSE;
        
        [self.navigationController pushViewController:itemSummary animated:YES];
    }
}


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return [rooms count];
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
//	if(!isPackersInvSummary && [rooms count] == 0)
    if([rooms count] == 0)
		return [NSString stringWithFormat:@"Select the plus button to add a room to the %@ Inventory.", driver.driverType == PVO_DRIVER_TYPE_PACKER ? @"Packer" : @"Driver"]; //Defect 897
	else
		return nil;
	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        static NSString *CellIdentifier = @"RoomSummaryCell";
    
        RoomSummaryCell *cell = (RoomSummaryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RoomSummaryCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
	
        [cell.cmdImages removeFromSuperview];
		
        PVORoomSummary *r = [rooms objectAtIndex:indexPath.row];
	
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *alias = [del.surveyDB getRoomAlias:del.customerID withRoomID:r.room.roomID];
        if(alias != nil)
            cell.labelRoomName.text = alias;
        else
            cell.labelRoomName.text = r.room.roomName;
    
    
        PVORoomConditions *conditions = nil;
    int imageType = ([self isUnload] ? IMG_PVO_DESTINATION_ROOMS : IMG_PVO_ROOMS);
    
        if (![self isUnload])
            conditions = [del.surveyDB getPVORoomConditions:currentLoad.pvoLoadID andRoomID:r.room.roomID];
        else
            conditions = [del.surveyDB getPVODestinationRoomConditions:currentUnload.pvoLoadID andRoomID:r.room.roomID];
    
        if (![self isUnload])
        {
            if ([AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
                cell.labelSummary.text = [[NSString alloc] initWithFormat:@"%d Items, %@ cu ft, %@ lbs",
                                          r.numberOfItems,
                                          [[NSNumber numberWithDouble:r.cube] stringValue],
                                          [[NSNumber numberWithInt:r.weight] stringValue]];
            else
                cell.labelSummary.text = [NSString stringWithFormat:@"%d Items", r.numberOfItems];
        }
        else
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableArray* totalPhotos = [del.surveyDB getImagesList:del.customerID withPhotoType:imageType withSubID:conditions.roomConditionsID loadAllItems:NO];
            
            cell.labelSummary.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)[totalPhotos count]];
        }
    
        UIImage *myimage = conditions.roomConditionsID != 0 ? [SurveyImageViewer getDefaultImage:imageType forItem:conditions.roomConditionsID] : nil;
        [cell setImage:myimage];
    
        return cell;
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

-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !isPackersInvSummary; //only allow for non-summary view
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        @try {
            deleteIndex = indexPath;
            PVORoomSummary *room = [rooms objectAtIndex:[deleteIndex row]];
            
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:
                                    [NSString stringWithFormat:@"Are you sure you would like to delete room %@?", room.room.roomName]
                                                               delegate:self
                                                      cancelButtonTitle:@"No"
                                                 destructiveButtonTitle:@"Yes"
                                                      otherButtonTitles:nil];
            sheet.tag = ACTION_SHEET_DELETE;
            [sheet showInView:self.view];
        }
        @catch (NSException *e) {
            [SurveyAppDelegate handleException:e];
        }
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    PVORoomSummary *r = [rooms objectAtIndex:indexPath.row];

    if (lastRoomID != r.room.roomID) {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        del.lastPackerInitials = nil;
        lastRoomID = r.room.roomID;
    }
	
	[self gotoRoom:r.room];
	
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    cmdMaintenance = nil;
    toolbar = nil;
    cmdComplete = nil;
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        inventory.inventoryCompleted = YES;
        [del.surveyDB updatePVOData:inventory];
        
        [del.surveyDB setCompletionDate:del.customerID isOrigin:YES];
        
        //jump back to nav list
        PVONavigationController *navController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVONavigationController class]])
                navController = view;
        }
        
        [self.navigationController popToViewController:navController animated:YES];
    }
}

#pragma mark - action sheet stuff
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (buttonIndex != [actionSheet cancelButtonIndex])
    {
        if (actionSheet.tag == ACTION_SHEET_DELETE)
        {
            if (currentLoad != nil)
            {
                [del.surveyDB deletePVOItemsInRoom:currentLoad.pvoLoadID
                                       andRoom:[[rooms objectAtIndex:[deleteIndex row]] room].roomID];
            }
            else
            {
                [del.surveyDB deletePVODestinationRoom:currentUnload.pvoLoadID
                                               andRoom:[[rooms objectAtIndex:[deleteIndex row]] room].roomID];
            }
            
            [rooms removeObjectAtIndex:[deleteIndex row]];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIndex]
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
        else if (actionSheet.tag == ACTION_SHEET_LIST_MAINTENANCE)
        {
            if(buttonIndex == 0)
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                PVOSkipItemNumberController *controller = [[PVOSkipItemNumberController alloc] initWithNibName:@"PVOSkipItemNumberView" bundle:nil];
                controller.defaultLotNumber = inventory.currentLotNum;
                controller.custID = del.customerID;
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:controller];
                
                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
            }
            else if(buttonIndex == 1)
            {
                if(itemDelete == nil) {
                    itemDelete = [[DeleteItemController alloc] initWithStyle:UITableViewStylePlain];
                }
                
                itemDelete.customerId = del.customerID;
                itemDelete.ignoreItemListId = FALSE;
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:itemDelete];
                
                itemDelete.title = @"Hide Item";
                
                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
            }
            else if(buttonIndex == 2)
            {
                if(roomDelete == nil)
                    roomDelete = [[DeleteRoomController alloc] initWithStyle:UITableViewStylePlain];
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:roomDelete];
                
                roomDelete.title = @"Hide Room";
                
                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
            }
            else if(buttonIndex == 3)
            {
                if(contentsDelete == nil)
                    contentsDelete = [[PVODeleteCCController alloc] initWithStyle:UITableViewStylePlain];
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:contentsDelete];
                
                contentsDelete.title = @"Hide Contents";
                
                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
                
            }
            else if(buttonIndex == 4)
            {
                if(favorites == nil)
                    favorites = [[PVOFavoriteItemsController alloc] initWithStyle:UITableViewStyleGrouped];
                
                portraitNavController = [[PortraitNavController alloc] initWithRootViewController:favorites];
                
                favorites.title = @"Favorite Items";
                
                [self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
                
            }
            else if(buttonIndex == 5)
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                [del pushSingleFieldController:[SurveyAppDelegate formatDouble:inventory.weightFactor]
                                   clearOnEdit:NO
                                  withKeyboard:UIKeyboardTypeDecimalPad
                               withPlaceHolder:@"Weight Factor"
                                    withCaller:self
                                   andCallback:@selector(textValueEntered:)
                             dismissController:YES
                              andNavController:self.navigationController];
            }
        }
    }
    
    if(deleteIndex != nil)
	{
		deleteIndex = nil;
	}
}


#pragma mark - AddRoomControllerDelegate methods

-(NSArray*)addRoomControllerCustomRoomsList:(AddRoomController*)controller
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    CubeSheet *cs = [del.surveyDB openCubeSheet:del.customerID];
    NSArray *roomSummaries = [del.surveyDB getRoomSummaries:cs customerID:del.customerID];
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    for (RoomSummary *rs in roomSummaries) {
        [retval addObject:rs.room];
    }

    return retval;
}

-(NSString*)addRoomControllerCustomRoomsHeader:(AddRoomController*)controller
{
    return @"Surveyed Rooms";
}

@end

