//
//  PVOBulkyInventoryController.m
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import "PVOBulkyInventoryController.h"
#import "PVOBulkyDetailsController.h"
#import "PVOAutoEditViewController.h"
#import "PVOAutoInventoryController.h"
#import "PVOBulkyItemsSummaryController.h"
#import "SurveyAppDelegate.h"

@interface PVOBulkyInventoryController ()

@end

@implementation PVOBulkyInventoryController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Bulky Items";
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    _bulkyItems = [del.pricingDB getAllWireframeItems];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadBulkyItem:(Item*)item
{
    //get all current bulkies for the selected item IE show all Automobiles done in bulky inventory so far
//    PVOBulkyDetailsController *bulkyDetails = [[PVOBulkyDetailsController alloc] initWithStyle:UITableViewStyleGrouped];
//    [self.navigationController pushViewController:bulkyDetails animated:YES];
    
    if (_bulkySummaryController == nil)
        _bulkySummaryController = [[PVOBulkyItemsSummaryController alloc] initWithStyle:UITableViewStyleGrouped];
    
    _bulkySummaryController.pvoBulkyItemTypeID = item.cartonBulkyID;
    _bulkySummaryController.isOrigin = _isOrigin;
    
    [self.navigationController pushViewController:_bulkySummaryController animated:YES];
    
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    Item *item = [_bulkyItems objectAtIndex:indexPath.row];
    int itemCount = [del.surveyDB getPVOBulkyItemCount:item.cartonBulkyID forCustomer:del.customerID];
    
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d items", itemCount];;
    
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self loadBulkyItem:[_bulkyItems objectAtIndex:indexPath.row]];
}





@end
