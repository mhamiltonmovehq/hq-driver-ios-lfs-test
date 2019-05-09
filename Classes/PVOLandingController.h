//
//  PVOLandingController.h
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOInventory.h"
#import "PVOInventoryLoad.h"
#import "PVORoomSummaryController.h"
#import "DriverData.h"
#import "PVOItemDetailExtended.h"
#import "PVOLandingController.h"

@class PVOLocationSummaryController;

@class PVOLandingController;
@protocol PVOLandingControllerDelegate <NSObject>
@optional
-(void)pvoLandingController:(PVOLandingController*)controller dataEntered:(PVOInventory*)data;
@end


#define PVO_LAND_ROW_LOAD_TYPE 0
#define PVO_LAND_ROW_NO_COND 1
#define PVO_LAND_ROW_CURRENT_LOT_NUM 2
#define PVO_LAND_ROW_CONFIRM_LOT_NUM 3
#define PVO_LAND_ROW_CURRENT_COLOR 4
#define PVO_LAND_ROW_USING_SCANNER 5
#define PVO_LAND_ROW_NEXT_ITEM_ID 6
#define PVO_LAND_ROW_TRACTOR_NUMBER 7
#define PVO_LAND_ROW_TRAILER_NUMBER 8
#define PVO_LAND_ROW_MPRO_WEIGHT 9
#define PVO_LAND_ROW_SPRO_WEIGHT 10
#define PVO_LAND_ROW_CONS_WEIGHT 11
#define PVO_LAND_ROW_CHANGE_LOCATION 12
#define PVO_LAND_ROW_NEW_PAGE_PER_LOT 13
#define PVO_LAND_ROW_PACK_TYPE 14
#define PVO_LAND_ROW_PACK_OT 15
#define PVO_LAND_ROW_VALUATION_TYPE 16

#define PVO_LAND_ROW_CONTINUE 0

#define PVO_ALERT_FVP_CONTINUE 100
#define PVO_ALERT_RELEASED_CONTINUE 101

@interface PVOLandingController : PVOBaseTableViewController <UITextFieldDelegate, UIAlertViewDelegate> {
	UITextField *tboxCurrent;
    
	PVOInventory *inventory;
    DriverData *driver;
    
	PVOLocationSummaryController *inventoryController;
    NSMutableArray *basic_info_rows;
    
    NSMutableDictionary *loadTypes;
    NSDictionary *colors;
    NSDictionary *locations;
    NSDictionary *packTypes;
    NSDictionary *valuationTypes;
    
    int editingRow;
    
    NSString *itemNumberString;
    
    //(optional) to allow a object to control the behavior of the screen
    id<PVOLandingControllerDelegate> delegate;
    PVORoomSummaryController *roomController;
}

@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) DriverData *driver;
@property (nonatomic, retain) PVOLocationSummaryController *inventoryController;
@property (nonatomic, retain) NSString *itemNumberString;
@property (nonatomic, retain) id<PVOLandingControllerDelegate> delegate;

-(void)initializeIncludedRows;

-(void)pickerValueSelected:(NSNumber*)value;
-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(UITextField*)field;
-(IBAction)switchChanged:(id)sender;

-(int)saveReceivableItem:(PVOItemDetailExtended*)item withUnload:(PVOInventoryUnload*)myunload;

@end
