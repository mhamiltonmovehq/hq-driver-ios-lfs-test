//
//  PVOBulkyInventoryController.h
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import <UIKit/UIKit.h>
#import "PVOBulkyItemsSummaryController.h"

@interface PVOBulkyInventoryController : UITableViewController
{
    
}

@property (nonatomic, retain) PVOBulkyItemsSummaryController *bulkySummaryController;
@property (nonatomic, retain) NSArray *bulkyItems;
@property (nonatomic) BOOL isOrigin;


@end