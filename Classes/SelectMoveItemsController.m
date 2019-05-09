//
//  MoveItemsController.m
//  Survey
//
//  Created by Lee Zumstein on 1/16/13.
//
//

#import "SelectMoveItemsController.h"
#import "Room.h"
#import "SurveyedItemsList.h"
#import "SurveyAppDelegate.h"
#import "PVOItemSummaryController.h"

@implementation SelectMoveItemsController

@synthesize dismiss, isSave;
@synthesize itemsToMove, moveToRoom, inventoryItemsList;

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
    //                                                                                          target:self
    //                                                                                          action:@selector(cancel:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    [super viewDidLoad];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    //    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = moveToRoom.roomName;
    
    if (itemsToMove == nil)
        itemsToMove = [[NSMutableArray alloc] init];
    [itemsToMove removeAllObjects];
    
    //    if(surveyedItems == nil)
    //        surveyedItems = [[NSMutableArray alloc] init];
    //    [surveyedItems removeAllObjects];
    //
    //
    //    NSEnumerator *enumerator = [inventoryItemsList objectEnumerator];
    //    SurveyedItem *si;
    //    while (si = [enumerator nextObject])
    //    {
    //        if (si != nil)
    //        {
    //            si.item = [del.surveyDB getItem:si.itemID];
    //            [surveyedItems addObject:si];
    //        }
    //    }
    //    [inventoryItemsList sortUsingComparator:^NSComparisonResult(id a, id b){
    //        NSString *first = [(SurveyedItem*)a item].name;
    //        NSString *second = [(SurveyedItem*)b item].name;
    //        return [first compare:second];
    //    }];
    
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidUnload {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)save:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    for (PVOItemDetail *item in itemsToMove) {
        [del.surveyDB movePVOInventoryItem:item toNewRoom:moveToRoom];  // :si toNewRoom:moveToRoom];
    }
    
    isSave = TRUE;
    
    // call cancel to clear view
    if (dismiss) {
        [self cancel:nil];
    }
}

-(IBAction)cancel:(id)sender
{
    @try {
        //        [self.navigationController popViewControllerAnimated:YES];
        
        
        PVOItemSummaryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOItemSummaryController class]])
                itemController = view;
        }
        itemController.wentToRoomConditions = YES;
        [self.navigationController popToViewController:itemController animated:YES];
        
    }
    @catch (NSException *exc) {
        [SurveyAppDelegate handleException:exc];
        
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [inventoryItemsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        if ([itemsToMove containsObject:[inventoryItemsList objectAtIndex:[indexPath row]]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    PVOItemDetail *pid = [inventoryItemsList objectAtIndex:indexPath.row];
    if(pid.itemIsDeleted)
    {
        if([cell viewWithTag:99] == nil)
        {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, (cell.frame.size.height / 2.0) - 1, cell.frame.size.width - 40, 2)];
            line.backgroundColor = [UIColor blackColor];
            line.tag = 99;
            [cell addSubview:line];
        }
    }
    else
    {
        [[cell viewWithTag:99] removeFromSuperview];
    }
    
    Item *item = [del.surveyDB getItem:pid.itemID WithCustomer:del.customerID];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", pid.itemNumber ,item.name];
    
    
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
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [itemsToMove removeObject:[inventoryItemsList objectAtIndex:[indexPath row]]];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [itemsToMove addObject:[inventoryItemsList objectAtIndex:[indexPath row]]];
    }
}

@end
