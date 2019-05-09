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

//- (void)viewDidLoad {
//    [super viewDidLoad];
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return [super numberOfSectionsInTableView:tableView];
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [super tableView:tableView numberOfRowsInSection:section];
//}

-(BOOL)viewHasCriticalDataToSave
{
    return NO;
}

@end
