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
#import "PVOUploadReportView.h"
#import "PVOItemDetailExtended.h"
#import "PVORoomSummaryController.h"
#import "DTDevices.h"

@class PVOInventoryLoad;

#define PVO_RECEIVE_USING_SCANNER 0
#define PVO_RECEIVE_DOWNLOAD_ALL 1
#define PVO_RECEIVE_ITEM_NUMBER 3
#define PVO_RECEIVE_DELIVER_ALL 4

#define PVO_RECEIVE_VIEW_RECENT 0
#define PVO_RECEIVE_VIEW_REMAINING 1

#define PVO_RECEIVE_ALERT_BATCH_ERRORS 100
#define PVO_RECEIVE_ALERT_BATCH_EXCEPTIONS 101
#define PVO_RECEIVE_ALERT_DUPE_EXCEPTIONS 102
#define PVO_RECEIVE_ALERT_DELIVER_ALL 104
#define PVO_RECEIVE_ALERT_DELIVER_ONE 105
#define PVO_RECEIVE_ALERT_MANUAL_EXCEPTIONS 106


@interface PVOReceiveController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate, 
ScanApiHelperDelegate, PVOUploadReportViewDelegate, DTDeviceDelegate> {
    IBOutlet UITableView *optionsTable;
    IBOutlet UITableView *recentTable;
    NSMutableArray *optionRows;
    NSMutableArray *recentlyDelivered;
    
    NSMutableArray *remainingItems;
    
    BOOL usingScanner;
    
    NSString *currentItemNumber;
    NSString *currentLotNumber;
    
    UITextField *tboxCurrent;
    
    int recentView;
    
    NSMutableString *syncMessages;
    
    NSMutableArray *duplicatedBatchTags;
    
    PVODelBatchExcController *deliveryBatchExceptions;
    
    PVOInventoryLoad *currentLoad;
    PVOInventoryUnload *currentUnload;
    
    PVOUploadReportView *receiverView;
    
    //used for the dupe exceptions alert...
    PVOItemDetailExtended *tempItem;
    PVORoomSummaryController *roomController;
    
    BOOL loadTheThings;
    BOOL hideAlerts;
    
    int receiveType;
    
    enum PVO_RECEIVE_TYPE receivingType;
}

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, retain) UITableView *optionsTable;
@property (nonatomic, retain) UITableView *recentTable;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) NSString *currentItemNumber;
@property (nonatomic, retain) NSString *currentLotNumber;
@property (nonatomic, retain) NSMutableArray *remainingItems;
@property (nonatomic, retain) PVODelBatchExcController *deliveryBatchExceptions;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) PVOInventoryUnload * currentUnload;
@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic) BOOL loadTheThings;
@property (nonatomic) BOOL hideAlerts;
@property (nonatomic) int receiveType;
@property (nonatomic) enum PVO_RECEIVE_TYPE receivingType;
@property (nonatomic) BOOL skipInventoryProcess;

-(void)initializeRowsIncluded;

-(void)updateValueWithField:(UITextField*)fld;

-(IBAction)switchChanged:(id)sender;

-(void)setupTableHeight;

-(IBAction)continue_Click:(id)sender;
-(IBAction)segmentRecentView_Changed:(id)sender;

-(void)addSyncMessage:(NSString*)message;
-(int)saveReceivableItem:(PVOItemDetailExtended*)item;

@end
