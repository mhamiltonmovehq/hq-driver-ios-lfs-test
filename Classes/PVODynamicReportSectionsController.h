//
//  PVODynamicReportSectionsController.h
//  Survey
//
//  Created by Tony Brame on 5/1/14.
//
//

#import <UIKit/UIKit.h>

@class PVONavigationListItem;
@class PVODynamicReportEntryController;

@interface PVODynamicReportSectionsController : UITableViewController

@property (nonatomic, retain) NSArray *sections;

@property (nonatomic, retain) PVONavigationListItem *navItem;

@property (nonatomic, retain) PVODynamicReportEntryController *entryController;

@end
