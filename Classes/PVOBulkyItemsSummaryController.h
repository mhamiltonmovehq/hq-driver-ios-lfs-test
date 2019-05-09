//
//  PVOBulkyItemsSummaryController.h
//  Survey
//
//  Created by Justin on 7/6/16.
//
//

#import <UIKit/UIKit.h>
#import "PVOBulkyDetailsController.h"

@interface PVOBulkyItemsSummaryController : UITableViewController

@property (nonatomic, retain) PVOBulkyDetailsController *bulkyDetailsController;
@property (nonatomic, retain) NSIndexPath *deleteIndex;
@property (nonatomic, retain) NSArray *bulkyItems;
@property (nonatomic) int pvoBulkyItemTypeID;
@property (nonatomic) BOOL isOrigin;

@end
