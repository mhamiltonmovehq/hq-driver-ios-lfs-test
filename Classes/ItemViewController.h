//
//  ItemViewController.h
//  Survey
//
//  Created by Tony Brame on 5/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "Item.h"
#import "CubeSheet.h"
#import "SurveyedItemsList.h"
#import "ItemDetailController.h"
#import "NewItemController.h"
#import "HelpViewController.h"
#import "UIItemTable.h"
#import "PortraitNavController.h"

#define TYPICAL_VIEW 0
#define ALL_VIEW 1
#define CP_VIEW 2
#define PBO_VIEW 3
#define SURVEYED_VIEW 4

@interface ItemViewController : UIViewController 
	<UITableViewDelegate, UITableViewDataSource>{
		Room *currentRoom;
		NSMutableArray *keys;
		NSMutableDictionary *items;
		IBOutlet UISegmentedControl *viewControl;
		IBOutlet UIItemTable *itemTable;
		SurveyedItemsList *surveyedItems;
		CubeSheet *cubesheet;
		ItemDetailController *detailController;
		BOOL editing;
		NewItemController *itemController;
		PortraitNavController *portraitNavController;
		HelpViewController *helpView;
        BOOL isPackingSummary;
}

@property (nonatomic, retain) HelpViewController *helpView;
@property (nonatomic, retain) PortraitNavController *portraitNavController;
@property (nonatomic, retain) NewItemController *itemController;
@property (nonatomic, retain) Room *currentRoom;
@property (nonatomic, retain) NSMutableArray *keys;
@property (nonatomic, retain) NSMutableDictionary *items;
@property (nonatomic, retain) SurveyedItemsList *surveyedItems;
@property (nonatomic, retain) UISegmentedControl *viewControl;
@property (nonatomic, retain) UIItemTable *itemTable;
@property (nonatomic, retain) CubeSheet *cubesheet;
@property (nonatomic, retain) ItemDetailController *detailController;
@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL isPackingSummary;

-(IBAction) switchView:(id)sender;
-(IBAction) addItem:(id)sender;
-(IBAction) itemAdded:(Item*)newItem;

-(IBAction) userNeedsHelp:(id)sender;

-(void)reloadItemsList;

//-(IBAction) decrementShipping: (Item*)item;

-(void) setSurveyedItem: (SurveyedItem*)item;

//called from UIItemTable
-(void) swipeRightAt:(PassTouchPoint*)point;
-(void) swipeLeftAt:(PassTouchPoint*)point;

@end
