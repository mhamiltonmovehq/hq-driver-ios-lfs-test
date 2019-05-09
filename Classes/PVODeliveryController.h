//
//  PVODeliveryController.h
//  Survey
//
//  Created by Tony Brame on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVODelBatchExcController.h"
#import "SignatureViewController.h"
#import "ScanApiHelper.h"
#import "DTDevices.h"
#import "TextAlertViewController.h"
#import "LandscapeNavController.h"
#import "PVOItemSummaryController.h"
#import "AddRoomController.h"
#import "PortraitNavController.h"
#import "PVORoomSummaryController.h"
#import "SurveyImageViewer.h"

@class PVOInventoryUnload;

#define PVO_DELIVERY_USING_SCANNER 0
#define PVO_DELIVERY_DOWNLOAD_ALL 1
#define PVO_DELIVERY_LOT_NUMBER 2
#define PVO_DELIVERY_ITEM_NUMBER 3
#define PVO_DELIVERY_WAIVE_RIGHTS 4
#define PVO_DELIVERY_DELIVER_ALL 5

#define PVO_DELIVERY_VIEW_RECENT 0
#define PVO_DELIVERY_VIEW_REMAINING 1

#define PVO_DELIVERY_ALERT_BATCH_ERRORS 100
#define PVO_DELIVERY_ALERT_BATCH_EXCEPTIONS 101
#define PVO_DELIVERY_ALERT_DUPE_EXCEPTIONS 102
#define PVO_DELIVERY_ALERT_HVI_INITIALS 103
#define PVO_DELIVERY_ALERT_DELIVER_ALL 104
#define PVO_DELIVERY_ALERT_DELIVER_ONE 105
#define PVO_DELIVERY_ALERT_MANUAL_EXCEPTIONS 106
#define PVO_DELIVERY_ROOM_CONDITIONS 107


#define PVO_DELIVERY_SIGVIEW_DELIVER_ALL 150
#define PVO_DELIVERY_SIGVIEW_WAIVE_RIGHTS 160


@interface PVODeliveryController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate,
SignatureViewControllerDelegate, ScanApiHelperDelegate, DTDeviceDelegate, UIActionSheetDelegate,
AddRoomControllerDelegate> {
    IBOutlet UITableView *optionsTable;
    IBOutlet UITableView *recentTable;
    NSMutableArray *optionRows;
    NSMutableArray *recentlyDelivered;
    
    NSMutableArray *remainingItems;
    
    BOOL usingScanner;
    
    NSString *currentLotNumber;
    NSString *currentItemNumber;
    
    UITextField *tboxCurrent;
    
    NSArray *lots;
    
    int recentView;
    
    BOOL reloadOnAppear;
    
    NSMutableString *syncMessages;
    
    NSMutableArray *duplicatedBatchTags;
    
    PVODelBatchExcController *deliveryBatchExceptions;
    
    PVOInventoryUnload *currentUnload;
    
    SignatureViewController *signatureController;
    
    TextAlertViewController *alertController;
    
    LandscapeNavController *sigNav;
    
    BOOL deliverAllNoScanner;
    
    AddRoomController* addRoomController;
    PVOItemSummaryController* itemSummary;
    PortraitNavController* newNav;
    PVORoomConditionsController* roomConditions;
    PVORoomSummaryController* roomController;
    //PVOInventory* inventory;
    
    SurveyImageViewer* imageViewer;
    
    BOOL roomConditionsDidShow;
}

@property (nonatomic, retain) UITableView *optionsTable;
@property (nonatomic, retain) UITableView *recentTable;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) NSString *currentLotNumber;
@property (nonatomic, retain) NSString *currentItemNumber;
@property (nonatomic, retain) NSArray *lots;
@property (nonatomic, retain) NSMutableArray *remainingItems;
@property (nonatomic, retain) PVODelBatchExcController *deliveryBatchExceptions;
@property (nonatomic, retain) PVOInventoryUnload *currentUnload;
@property (nonatomic, retain) SignatureViewController *signatureController;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentView;
@property (nonatomic, retain) NSMutableArray *deliverAllHighValueItems;
@property (nonatomic) int editingRow;
@property (nonatomic) BOOL deliveringAll;

-(void)initializeRowsIncluded;

-(void)updateValueWithField:(UITextField*)fld;

-(IBAction)switchChanged:(id)sender;

-(void)lotChanged:(NSString*)newLot;

-(void)setupTableHeight;

//-(IBAction)continue_Click:(id)sender;
//-(IBAction)complete_Click:(id)sender;
-(IBAction)segmentRecentView_Changed:(id)sender;

-(void)addSyncMessage:(NSString*)message;

-(void)showSignatureScreen:(int)tag;

-(UIAlertView*)buildCustomerConfirmAlert;

-(void)continueToDeliverAll;

-(void)continueToNextScreen;

@end
