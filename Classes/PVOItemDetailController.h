//
//  PVOItemDetailController.h
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOInventory.h"
#import "PVOItemDetail.h"
#import "Item.h"
#import "Room.h"
#import "PVODamageWheelController.h"
#import "PVODamageButtonController.h"
#import "PVOCartonContentsSummaryController.h"
#import "SurveyImageViewer.h"
#import "PVOHighValueController.h"
#import "PVOQuickScanController.h"
#import "PVOInventoryLoad.h"
#import "SelectObjectController.h"
#import "ZBarSDK.h"
#import "ScanApiHelper.h"
#import "DTDevices.h"
#import "PVOItemAdditionalController.h"
#import "TextViewAlert.h"
#import "PortraitNavController.h"
#import "NoteViewController.h"
#import "AppFunctionality.h"
#import "SingleFieldController.h"
#import "PVOItemComment.h"
#import "PVOBaseTableViewController.h"
#import "PVOWireFrameTypeController.h"
#import "PVODamageViewHolder.h"
#import "CubeSheet.h"


#define PVO_ITEM_DETAIL_SECTION_INFO 0
#define PVO_ITEM_DETAIL_SECTION_TAG 1
#define PVO_ITEM_DETAIL_SECTION_ADDITIONAL 2
#define PVO_ITEM_DETAIL_SECTION_CRATE_DIMENSIONS 3
#define PVO_ITEM_DETAIL_SECTION_DELETE 4

#define PVO_ITEM_DETAIL_ROOM_NAME 0
#define PVO_ITEM_DETAIL_ITEM_NAME 1
#define PVO_ITEM_DETAIL_TAG_COLOR 2
#define PVO_ITEM_DETAIL_ITEM_NUM 3
#define PVO_ITEM_DETAIL_CARTON_CONTENTS 4
#define PVO_ITEM_DETAIL_MPRO 5
#define PVO_ITEM_DETAIL_SPRO 6
#define PVO_ITEM_DETAIL_CONS 7
#define PVO_ITEM_DETAIL_NO_EXC 8
#define PVO_ITEM_DETAIL_QTY 9
#define PVO_ITEM_DETAIL_CAMERA 10
#define PVO_ITEM_DETAIL_HIGH_VALUE_SWITCH 11
#define PVO_ITEM_DETAIL_HIGH_VALUE_COST 12
#define PVO_ITEM_DETAIL_COMMENTS 13
#define PVO_ITEM_DETAIL_LOT_NUM 14
#define PVO_ITEM_DETAIL_SCANNER_NUMBER 15
#define PVO_ITEM_DETAIL_QUICK_SCAN 16
#define PVO_ITEM_DETAIL_DESCRIPTIVE 17
#define PVO_ITEM_DETAIL_ADDITIONAL 18
#define PVO_ITEM_DETAIL_DELETE 19
#define PVO_ITEM_DETAIL_CUBE 20
#define PVO_ITEM_DETAIL_WEIGHT 21
#define PVO_ITEM_DETAIL_CRATE_HAS_DIMS 22
#define PVO_ITEM_DETAIL_CRATE_LENGTH 23
#define PVO_ITEM_DETAIL_CRATE_WIDTH 24
#define PVO_ITEM_DETAIL_CRATE_HEIGHT 25
#define PVO_ITEM_DETAIL_CRATE_DIMENSION_UNIT_TYPE 26
#define PVO_ITEM_DETAIL_PACKER_INITIALS 27
#define PVO_ITEM_DETAIL_CARTON_CONTENT_NAME 28
#define PVO_ITEM_DETAIL_CP_IS_PROVIDED 29
#define PVO_ITEM_DETAIL_WEIGHT_TYPE 30
#define PVO_ITEM_DETAIL_LOT_NUMBER 31
#define PVO_ITEM_DETAIL_SECURITY_SEAL 32

#define PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE_SELECTION 0
#define PVO_ITEM_DETAIL_WEIGHT_TYPE_ACTUAL_SELECTION 1

#define PVO_ITEM_ALERT_DUPLICATE 0
#define PVO_ITEM_ALERT_DELETE 1
#define PVO_ITEM_ALERT_HIGH_VALUE 2
#define PVO_ITEM_ALERT_RELEASED_VAL 3

#define PVO_ITEM_DELETE_VOID 0
#define PVO_ITEM_DELETE_DELETE 1

#define PVO_ITEM_DUPLICATE_IGNORE 0
#define PVO_ITEM_DUPLICATE_GO_TO_ITEM 1
#define PVO_ITEM_DUPLICATE_VOID 2
#define PVO_ITEM_DUPLICATE_DELETE 3

@class PVOItemDetailController;
@protocol PVOItemDetailControllerDelegate <NSObject>
@optional
-(void)pvoItemControllerContinueToNextItem:(PVOItemDetailController*)controller;
@end


@interface PVOItemDetailController : PVOBaseTableViewController
<UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate,
SelectObjectControllerDelegate, ZBarReaderDelegate, ScanApiHelperDelegate, DTDeviceDelegate,
PVODamageControllerDelegate, PVOWireFrameTypeControllerDelegate, PVODamageViewHolderDelegate, UITextViewDelegate> {
    
    NSMutableDictionary *includedSections;
    NSArray *packerInitials;
    NSDictionary *dimensionUnitTypes;
    
    PVOInventoryLoad *currentLoad;
    PVOItemDetail *pvoItem;
    
    Item *item;
    Room *room;
    UITextField *tboxCurrent;
    UITextView *tboxComment;
    
    SurveyImageViewer *imageViewer;
    
    BOOL focusOnTag;
    
    PVODamageWheelController *wheelDamageController;
    PVODamageButtonController *buttonDamageController;
    PVOCartonContentsSummaryController *cartonContentsController;
    PVOHighValueController *highValueController;
    PVOQuickScanController *quickScanController;
    PVOItemAdditionalController *addController;
    PortraitNavController *portraitNavController;
    NoteViewController *noteController;
    SingleFieldController *singleFieldController;
    
    BOOL discardChangesAndDelete;
    
    BOOL reloadItemUponReturn;
    
    SelectObjectController *descriptiveScreen;
    
    ZBarReaderViewController *zbar;
    
    BOOL grabbingBarcodeImage;
    
    BOOL scannerConnected;
    
    BOOL comingFromItemSummary;
    
    id<PVOItemDetailControllerDelegate> delegate;
    
    //this indicates that the item being added is simply a voided item to rid a tag that has been damaged
    BOOL voidingTag;
    
    BOOL grabbingQuickScan;
    
    enum HV_DETAILS_TYPE highValueType;
    
    NSMutableDictionary* weightTypes;
}

@property (nonatomic) BOOL focusOnTag;
@property (nonatomic) BOOL comingFromItemSummary;

@property (nonatomic, retain) id<PVOItemDetailControllerDelegate> delegate;
@property (nonatomic, retain) SurveyImageViewer *imageViewer;
@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) PVOItemDetail *pvoItem;
@property (nonatomic, retain) PVOItemComment *pvoItemComment;
@property (nonatomic, retain) PVODamageWheelController *wheelDamageController;
@property (nonatomic, retain) PVODamageButtonController *buttonDamageController;
@property (nonatomic, retain) PVOCartonContentsSummaryController *cartonContentsController;
@property (nonatomic, retain) PVOHighValueController *highValueController;
@property (nonatomic, retain) PVOQuickScanController *quickScanController;
@property (nonatomic, retain) SelectObjectController *descriptiveScreen;
@property (nonatomic, retain) PortraitNavController *portraitNavController;
@property (nonatomic, retain) NoteViewController *noteController;
@property (nonatomic, retain) SingleFieldController *singleFieldController;

@property (nonatomic, retain) Item *item;
@property (nonatomic, retain) Room *room;
@property (nonatomic, retain) CubeSheet *cubesheet;

@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) UITextView *tboxComment;

-(int)rowTypeForIndexPath:(NSIndexPath *)indexPath;
-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(id)field;

-(IBAction)switchChanged:(id)sender;
-(IBAction)moveToNextDetail:(id)sender;
-(IBAction)deleteItem:(id)sender;

-(void)initializeIncludedRows;
-(void)setupContinueButton;
-(IBAction)back:(id)sender;

-(BOOL)checkForDuplicate;
-(void)handleDuplicateItem;

-(void)commitAndClearFields;

-(void)initialsSelected:(NSString*)initials;

-(void)voidReasonEntered:(NSString*)voidReason;

-(void)highValueCostEntered:(NSString*)cost;

-(BOOL)forceValidTagForScan;

-(void)deleteWorkingItem;
-(void)voidWorkingItem;

@end
