//
//  PVOLocationSummary.h
//  Survey
//
//  Created by Tony Brame on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOLandingController.h"
#import "DeleteItemController.h"
#import "DeleteRoomController.h"
#import "PVODeleteCCController.h"
#import "PVOFavoriteItemsController.h"
#import "SelectLocationController.h"
#import "PVORoomSummaryController.h"
#import "PVOSkipItemNumberController.h"
#import "PVOReceiveController.h"

@class PVOInventoryLoad;
@class SurveyLocation;

#define PVO_LOCATIONS_ALERT_RECEIVE 100

@interface PVOLocationSummaryController : PVOBaseViewController 
<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, SelectLocationControllerDelegate> {
    NSMutableArray *addedLocations;
    NSDictionary *locations;
    
    IBOutlet UITableView *tableView;
    
    PortraitNavController *newNav;
    
    DeleteItemController *itemDelete;
    DeleteRoomController *roomDelete;
    PVODeleteCCController *contentsDelete;
    PVOFavoriteItemsController *favorites;
    PVORoomSummaryController *roomController;
    
    PVOInventory *inventory;
    
    SelectLocationController *selectLocation;
    
    PVOInventoryLoad *newLoad;
    
    PVOReceiveController *receiveController;
}

@property (nonatomic, strong) PVOInventory *inventory;
@property (nonatomic, strong) PVORoomSummaryController *roomController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *addedLocations;
@property (nonatomic, strong) NSDictionary *locations;
@property (nonatomic, strong) DeleteItemController *itemDelete;
@property (nonatomic, strong) DeleteRoomController *roomDelete;
@property (nonatomic, strong) PVODeleteCCController *contentsDelete;
@property (nonatomic, strong) PVOFavoriteItemsController *favorites;
@property (nonatomic, strong) SelectLocationController *selectLocation;
@property (nonatomic) BOOL receiveOnly;

//@property (nonatomic) BOOL firstLocationPopupLoaded;

-(IBAction)addLocation:(id)sender;
-(IBAction)maintenance:(id)sender;
- (IBAction)cmdSaveToServerClick:(id)sender;

-(void)pickerValueSelected:(NSNumber*)newValue;
-(void)textValueEntered:(NSString*)newValue;

-(void)continueToRoomsScreen;
-(void)loadRoomsScreen:(PVOInventoryLoad*)pvoLoad;

@end
