//
//  PVOActionItems.m
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import "PVOActionItemsController.h"
#import "PVOActionCell.h"
#import "PVOSync.h"

@interface PVOActionItemsController ()

@end

@implementation PVOActionItemsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PVOActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PVOActionCell"];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PVOActionCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    cell.delegate = self;
    
    if (indexPath.row == 0)
    {
        cell.actionTime = _isOrigin ? _actionTimes.origStarted : _actionTimes.destStarted;
        [cell.buttonAction setTitle:@"Start Job" forState:UIControlStateNormal];
        [cell.labelAction setText:@"Started:"];
        
        [cell setActionTime: _isOrigin ? _actionTimes.origStarted : _actionTimes.destStarted];
        cell.callback = @selector(actionStarted:);
    }
    else
    {
        cell.actionTime = _isOrigin ? _actionTimes.origArrived : _actionTimes.destArrived;
        [cell.buttonAction setTitle:_isOrigin ? @"Arrived at Origin" : @"Arrived at Destination" forState:UIControlStateNormal];
        [cell.labelAction setText:@"Arrived:"];
        
        [cell setActionTime: _isOrigin ? _actionTimes.origArrived : _actionTimes.destArrived];
        cell.callback = @selector(actionArrived:);
    }
    
    return cell;
}

- (void) actionStarted:(NSDate*)newDate
{
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if(_isOrigin)
    {
        _actionTimes.origStarted = newDate;
    }
    else
    {
        _actionTimes.destStarted = newDate;
    }
    
    _actionTimes.pvoActionTimesId = [del.surveyDB savePVOActionTime:_actionTimes];
    
    
    if(_isOrigin)
    {
        // After save, set Pack status and sync up
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = PACKED;
        [del.surveyDB updateShipInfo:info];
        
        SurveyCustomerSync *custSync = [del.surveyDB getCustomerSync:del.customerID];
        custSync.syncToPVO = YES;
        [del.surveyDB updateCustomerSync:custSync];
        
        PVOSync* sync = [[PVOSync alloc] init];
        sync.syncAction = PVO_SYNC_ACTION_UPDATE_ORDER_STATUS;
        sync.orderStatus = [ShipmentInfo getStatusString:info.status];
        sync.orderNumber = info.orderNumber;
        [del.operationQueue addOperation:sync];
    }
    else
    {
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = OUT_FOR_DELIVERY;
        [del.surveyDB updateShipInfo:info];
        
        SurveyCustomerSync *custSync = [del.surveyDB getCustomerSync:del.customerID];
        custSync.syncToPVO = YES;
        [del.surveyDB updateCustomerSync:custSync];
        
        PVOSync* sync = [[PVOSync alloc] init];
        sync.syncAction = PVO_SYNC_ACTION_UPDATE_ORDER_STATUS;
        sync.orderStatus = [ShipmentInfo getStatusString:info.status];
        sync.orderNumber = info.orderNumber;
        [del.operationQueue addOperation:sync];
    }
    
    [self.tableView reloadData];
}

- (void) actionArrived:(NSDate*)newDate
{
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if(_isOrigin)
    {
        _actionTimes.origArrived = newDate;
    }
    else
    {
        _actionTimes.destArrived = newDate;
    }
    
    _actionTimes.pvoActionTimesId = [del.surveyDB savePVOActionTime:_actionTimes];
    [self.tableView reloadData];
}

@end
