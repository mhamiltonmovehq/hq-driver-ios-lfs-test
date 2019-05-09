//
//  MoveItemsController.m
//  Survey
//
//  Created by Lee Zumstein on 1/16/13.
//
//

#import "MoveItemsController.h"
#import "SurveyAppDelegate.h"
#import "Room.h"
#import "CubeSheet.h"
#import "PVOItemSummaryController.h"

@implementation MoveItemsController

@synthesize selectMoveItemsController, currentRoomID, cubeSheet, allRooms;
@synthesize dismiss, popover, pvoLoadID;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        dismiss = TRUE;
    }
    return self;
}

- (void)viewDidLoad
{
//    self.clearsSelectionOnViewWillAppear = YES;
//    self.preferredContentSize = CGSizeMake(320, 416);
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    //    [SurveyAppDelegate minimizeTableHeaderAndFooterViews:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = @"Move Items To...";
    
    
    allRooms = [del.surveyDB getAllRoomsList:del.customerID withCheckInclude:NO limitToCustomer:NO withPVOLocationID:[del.surveyDB getPVOLoad:pvoLoadID].pvoLocationID withHidden:NO];
    //[del.surveyDB getAllRoomsListWithPVOLocationID:[del.surveyDB getPVOLoad:pvoLoadID].pvoLocationID];
    
    cubeSheet = [del.surveyDB openCubeSheet:del.customerID];
    
    int removeRoomIndex = -1;
    for (int i=0; i < [allRooms count];i++)
    {
        Room *r = [allRooms objectAtIndex:i];
        if (r.roomID == currentRoomID) {
            removeRoomIndex = i;
            i = [allRooms count];
        }
    }
    if (removeRoomIndex >= 0)
        [allRooms removeObjectAtIndex:removeRoomIndex];
    
    
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)cancel:(id)sender
{
    //    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    PVOItemSummaryController *itemController = nil;
    for (id view in [self.navigationController viewControllers]) {
        if([view isKindOfClass:[PVOItemSummaryController class]])
            itemController = view;
    }
    itemController.wentToRoomConditions = YES;
    [self.navigationController popToViewController:itemController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [allRooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    Room *room = [allRooms objectAtIndex:[indexPath row]];
    cell.textLabel.text = room.roomName;
    
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
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (selectMoveItemsController == nil)
        selectMoveItemsController = [[SelectMoveItemsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    Room *room = [allRooms objectAtIndex:[indexPath row]];
    Room *currentRoom = [del.surveyDB getRoom:currentRoomID WithCustomerID:del.customerID];
    
    selectMoveItemsController.moveToRoom = [del.surveyDB getRoom:room.roomID WithCustomerID:del.customerID];
    selectMoveItemsController.inventoryItemsList = [NSMutableArray arrayWithArray:[del.surveyDB getPVOItems:pvoLoadID forRoom:currentRoom.roomID]];
    //    selectMoveItemsController.popover = self.popover;
    [self.navigationController pushViewController:selectMoveItemsController animated:YES];
}

@end
