//
//  PVOBulkyItemsSummaryController.m
//  Survey
//
//  Created by Justin on 7/6/16.
//
// The purpose of this controller is to show all previously "inventoried" bulky items, analogous to the PVOVehicleInventoryController. Decided to start fresh rather than try to make that controller generic.

#import "PVOBulkyItemsSummaryController.h"
#import "PVOBulkyInventoryController.h"
#import "PVOBulkyDetailsController.h"
#import "PVOAutoEditViewController.h"
#import "PVOAutoInventoryController.h"
#import "SurveyAppDelegate.h"

@implementation PVOBulkyItemsSummaryController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Bulky Items";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                                           target:self
                                                                                                                           action:@selector(addPVOBulkyItem:)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    //get all bulky items of the selected type
    [self reloadBulkyItems];
    [self.tableView reloadData];
}

-(void)reloadBulkyItems
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    _bulkyItems = [del.surveyDB getPVOBulkyInventoryItems:del.customerID withPVOBulkyItemType:_pvoBulkyItemTypeID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadBulkyItem:(PVOBulkyInventoryItem*)item
{
    PVOBulkyDetailsController *editBulkyController = [[PVOBulkyDetailsController alloc] initWithStyle:UITableViewStyleGrouped];
    editBulkyController.pvoBulkyItem = item;
    editBulkyController.isOrigin = _isOrigin;
    
    [self.navigationController pushViewController:editBulkyController animated:YES];
    
}

-(void)deleteBulky:(NSIndexPath*)indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOBulkyInventoryItem *bulky = [_bulkyItems objectAtIndex:[indexPath row]];
    [del.surveyDB deletePVOBulkyInventoryItem:bulky.pvoBulkyItemID];
    
    [self reloadBulkyItems];
    
    // Animate the deletion from the table.
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
}
-(IBAction)addPVOBulkyItem:(id)sender
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    //check for BOL signature, ask to remove before continuing
//    if ([del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG] != NULL || [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST] != NULL)
//    {
//        [self showRemoveBOLSignaturesAlert:AUTO_INVENTORY_ADD_VEHICLE_ALERT];
//    }
//    else
//    {
//        [self continueToAddVehicle];
//    }
    
    [self continueToAddBulky];
}

-(void)continueToAddBulky
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (_bulkyDetailsController == nil)
        _bulkyDetailsController = [[PVOBulkyDetailsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    PVOBulkyInventoryItem *newBulkyItem = [[PVOBulkyInventoryItem alloc] init];
    newBulkyItem.pvoBulkyItemTypeID = _pvoBulkyItemTypeID;
    _bulkyDetailsController.pvoBulkyItem = newBulkyItem;
    _bulkyDetailsController.isOrigin = _isOrigin;
    
    [self.navigationController pushViewController:_bulkyDetailsController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_bulkyItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    PVOBulkyInventoryItem *item = [_bulkyItems objectAtIndex:indexPath.row];
    NSString *bulkyName = [del.pricingDB getPVOBulkyTypeDescription:item.pvoBulkyItemTypeID];
    NSString *subText = [item getFormattedDetails];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", bulkyName];
    cell.detailTextLabel.text = subText;
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self loadBulkyItem:[_bulkyItems objectAtIndex:indexPath.row]];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        _deleteIndex = indexPath;
        
        //BOL signature will be removed if they delete / add a vehicle, confirm first
//        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//        if ([del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG] != NULL || [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST] != NULL)
//        {
//            [self showRemoveBOLSignaturesAlert:AUTO_INVENTORY_DELETE_VEHICLE_ALERT];
//        }
//        else
//        {
            [self deleteBulky:indexPath];
//        }
    }
}





@end
