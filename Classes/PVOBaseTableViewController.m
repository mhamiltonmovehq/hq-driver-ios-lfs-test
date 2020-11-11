//
//  PVOBaseTableViewController.m
//  Survey
//
//  Created by Justin on 1/6/16.
//
//

#import "PVOBaseTableViewController.h"

@interface PVOBaseTableViewController ()

@end

@implementation PVOBaseTableViewController

-(BOOL)viewHasCriticalDataToSave
{
    return NO;
}

-(void) reloadData {
    [self.tableView reloadData];
}

@end
