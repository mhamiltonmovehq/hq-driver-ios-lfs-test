//
//  PVOItemSummaryController.h
//  Survey
//
//  Created by Tony Brame on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOItemDetailController.h"
#import "Room.h"
#import "SelectItemWithFilterController.h"
#import "PVOInventory.h"
#import "PVORoomConditionsController.h"
#import "PVOInventoryLoad.h"
#import "TextViewAlert.h"
#import "PortraitNavController.h"
#import "PVOBaseViewController.h"

#define PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG 1000
#define PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG_AND_VOID 1001
#define PVO_ITEM_SUMMARY_ALERT_ADD_ALIAS 1002

#define PVO_ITEM_SUMMARY_MAINTENANCE 1002

#define PVO_ITEM_SUMMARY_ROOM_CONDITIONS 0
#define PVO_ITEM_SUMMARY_ROOM_MOVE_ITEMS 1

@interface PVOItemSummaryController : PVOBaseViewController <UITableViewDelegate, UITableViewDataSource,
SelectItemWithFilterControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    IBOutlet UITableView *tableView;
	PVOItemDetailController *itemDetail;
	Room *room;
	SelectItemWithFilterController *selectItem;
	PortraitNavController *portraitNav;
	PVOInventoryLoad *currentLoad;
    NSMutableArray *pvoItems;
    
    IBOutlet UIToolbar *toolbar;
    
    IBOutlet UIBarButtonItem *cmdRoomMaintenance;
    IBOutlet UIBarButtonItem *cmdComplete;
    IBOutlet UIBarButtonItem *cmdVoid;
    
    PVORoomConditionsController *roomConditions;
    
    //BOOL wentToRoomConditions;
    BOOL roomConditionsEnabled;
    
    NSIndexPath *deletingIndex;
    
    PVOItemDetail *workingItem;
    
    BOOL isPackersInvSummary;
}

@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) NSMutableArray *pvoItems;
@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, retain) PVOItemDetailController *itemDetail;
@property (nonatomic, retain) Room *room;
@property (nonatomic, retain) SelectItemWithFilterController *selectItem;
@property (nonatomic, retain) PortraitNavController *portraitNav;
@property (nonatomic, retain) UIToolbar *toolbar;

@property (nonatomic) BOOL wentToRoomConditions;
@property (nonatomic) BOOL isPackersInvSummary;

@property (nonatomic, retain) UIBarButtonItem *cmdRoomConditions;
@property (nonatomic, retain) UIBarButtonItem *cmdComplete;
@property (nonatomic, retain) UIBarButtonItem *cmdVoid;

-(IBAction)addItem:(id)sender;

-(void)loadController:(PVOItemDetail*)item withItemID:(int)itemID;

-(IBAction)cmdFinishedClick:(id)sender;

-(IBAction)roomMaintenance:(id)sender;

-(IBAction)cmdVoidTagClick:(id)sender;

-(void)voidReasonEntered:(NSString*)voidReason;

-(void)deleteWorkingItem;
-(void)voidWorkingItem;

@end
