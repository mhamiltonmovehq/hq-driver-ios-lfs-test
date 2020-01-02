//
//  PVOActionItems.m
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import "PVOActionItemsController.h"
#import "PVOActionCell.h"

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
    
    [del.surveyDB savePVOActionTime:_actionTimes];
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
    
    [del.surveyDB savePVOActionTime:_actionTimes];
    [self.tableView reloadData];
}

@end
