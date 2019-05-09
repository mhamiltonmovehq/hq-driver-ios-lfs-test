//
//  PVORoomSummaryController.h
//  Survey
//
//  Created by Tony Brame on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOItemSummaryController.h"
#import "AddRoomController.h"
#import "Room.h"
#import "PVOInventory.h"
#import "PVOInventoryLoad.h"
#import "DeleteItemController.h"
#import "DeleteRoomController.h"
#import "PVODeleteCCController.h"
#import "PVOFavoriteItemsController.h"
#import "PVOSkipItemNumberController.h"
#import "PVOBaseViewController.h"

@interface PVORoomSummaryController : PVOBaseViewController
<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIActionSheetDelegate, AddRoomControllerDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UIToolbar *toolbar;
    
	PVOItemSummaryController *itemSummary;
	//all rooms 
	NSMutableArray *rooms;
	
	AddRoomController *addRoomController;
	
	PortraitNavController *portraitNavController;
    
	DeleteItemController *itemDelete;
	DeleteRoomController *roomDelete;
	PVODeleteCCController *contentsDelete;
    PVOFavoriteItemsController *favorites;
	
	PVOInventory *inventory;
    PVOInventoryLoad *currentLoad;
    
    NSIndexPath *deleteIndex;
    
    BOOL isPackersInvSummary;
    IBOutlet UIBarButtonItem *cmdComplete;
    IBOutlet UIBarButtonItem *cmdMaintenance;
    
    int lastRoomID;
    
    PVORoomConditionsController* roomConditions;
    
    PVOInventoryUnload* currentUnload;
}

@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIToolbar *toolbar;

@property (nonatomic, retain) PVOItemSummaryController *itemSummary;
@property (nonatomic, retain) NSMutableArray *rooms;
@property (nonatomic, retain) AddRoomController *addRoomController;
@property (nonatomic, retain) PortraitNavController *portraitNavController;

//@property (nonatomic) BOOL firstRoomPopupLoaded;

@property (nonatomic, retain) DeleteItemController *itemDelete;
@property (nonatomic, retain) DeleteRoomController *roomDelete;
@property (nonatomic, retain) PVODeleteCCController *contentsDelete;
@property (nonatomic, retain) PVOFavoriteItemsController *favorites;

@property (nonatomic) BOOL isPackersInvSummary;
@property (nonatomic, retain) UIBarButtonItem *cmdComplete;
@property (nonatomic, retain) UIBarButtonItem *cmdMaintenance;

@property (nonatomic) int lastRoomID;

@property (nonatomic, retain)PVOInventoryUnload* currentUnload;

-(IBAction)addRoom:(id)sender;

-(void)roomAdded:(Room*)room;

-(void)gotoRoom:(Room*)room;

-(void)textValueEntered:(NSString*)newValue;

-(IBAction)cmdFinishedClick:(id)sender;
-(IBAction)cmdMaintenance:(id)sender;

-(void)setupToolbarItems;

@end
