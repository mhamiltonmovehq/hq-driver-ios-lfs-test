//
//  PVODelBatchCartonContentsController.m
//  Survey
//
//  Created by Brian Prescott on 4/25/13.
//
//

#import "PVODelBatchCartonContentsController.h"

#import "SurveyAppDelegate.h"

@implementation PVODelBatchCartonContentsController

@synthesize moveToNextItem, currentLoad, currentUnload, duplicatedTags;

- (void)moveToNextItem:(id)sender
{
    if(exceptionsController == nil)
        exceptionsController = [[PVODelBatchExcController alloc] initWithStyle:UITableViewStylePlain];
    exceptionsController.title = @"Exceptions";
    exceptionsController.duplicatedTags = duplicatedTags;
    exceptionsController.moveToNextItem = YES;

    exceptionsController.currentLoad = currentLoad;

    [self.navigationController pushViewController:exceptionsController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [duplicatedTags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PVODelBatchCartonContentsControllerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *tag = [duplicatedTags objectAtIndex:indexPath.row];
    
    NSString *currentLotNumber = [tag substringToIndex:[tag length]-3];
    NSString *currentItemNumber = [tag substringFromIndex:[tag length]-3];
    
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    
    PVOItemDetail *item = nil;
    if(currentLoad != nil)
        item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                           forLotNumber:currentLotNumber
                         withItemNumber:currentItemNumber];
    else
        item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID
                                    forLotNumber:currentLotNumber
                                  withItemNumber:currentItemNumber];
    
    if(item != nil)
    {
//        if([visitedTags containsObject:tag])
//            cell.accessoryType = UITableViewCellAccessoryCheckmark;
//        else
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        Item *i = [del.surveyDB getItem:item.itemID];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", tag, i.name];
        
        PVOItemDetail *item = nil;
        if(currentLoad != nil)
            item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                               forLotNumber:currentLotNumber
                             withItemNumber:currentItemNumber];
        else
            item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID
                                        forLotNumber:currentLotNumber
                                      withItemNumber:currentItemNumber];
        NSArray *cartonContents = [[del.surveyDB getPVOCartonContents:item.pvoItemID] autorelease];
        if ([cartonContents count] == 0)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
        [i release];
        [item release];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"%@: NOT FOUND", tag];
    }
    
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType != UITableViewCellAccessoryNone)
    {
        editing = TRUE;
        
        currentTag = [duplicatedTags objectAtIndex:indexPath.row];
        
        NSString *currentLotNumber = [currentTag substringToIndex:[currentTag length]-3];
        NSString *currentItemNumber = [currentTag substringFromIndex:[currentTag length]-3];
        
        SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
        PVOItemDetail *item = nil;
        if(currentLoad != nil)
            item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID
                               forLotNumber:currentLotNumber
                             withItemNumber:currentItemNumber];
        else
            item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID
                                        forLotNumber:currentLotNumber
                                      withItemNumber:currentItemNumber];
        
        PVOCartonContentsSummaryController *cartonContentsController = [[PVOCartonContentsSummaryController alloc] initWithNibName:@"PVOCartonContentsView" bundle:nil];
        cartonContentsController.title = @"Carton Contents";
        cartonContentsController.pvoItem = item;
        cartonContentsController.hideContinueButton = YES;
        [self.navigationController pushViewController:cartonContentsController animated:YES];
        [cartonContentsController release];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (moveToNextItem)
    {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                   style:UIBarButtonItemStyleBordered
                                                                                  target:self
                                                                                  action:@selector(moveToNextItem:)] autorelease];
    }
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [currentLoad release];
    [currentUnload release];
    [duplicatedTags release];
    
    [super dealloc];
}

@end
