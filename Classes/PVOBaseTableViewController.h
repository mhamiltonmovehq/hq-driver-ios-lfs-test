//
//  PVOBaseTableViewController.h
//  Survey
//
//  Created by Justin on 1/6/16.
//
//

#import <UIKit/UIKit.h>

@interface PVOBaseTableViewController : UITableViewController


-(void)reloadData;
-(BOOL)viewHasCriticalDataToSave;

@end
