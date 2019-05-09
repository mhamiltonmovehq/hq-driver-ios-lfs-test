//
//  PVODelBatchCartonContentsController.h
//  Survey
//
//  Created by Brian Prescott on 4/25/13.
//
//

#import <UIKit/UIKit.h>
#import "PVODelBatchExcController.h"
#import "PVOCartonContentsSummaryController.h"

@class PVOInventoryUnload;
@class PVOInventoryLoad;

@interface PVODelBatchCartonContentsController : UITableViewController
{
    NSString *currentTag;
    BOOL editing;
    
    BOOL moveToNextItem;

    PVOInventoryUnload *currentUnload;
    PVOInventoryLoad *currentLoad;
    NSArray *duplicatedTags;
    PVODelBatchExcController *exceptionsController;
}

@property (nonatomic) BOOL moveToNextItem;

@property (nonatomic, retain) PVOInventoryUnload *currentUnload;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) NSArray *duplicatedTags;

@end
