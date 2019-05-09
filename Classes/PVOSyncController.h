//
//  PVOSyncController.h
//  Survey
//
//  Created by Tony Brame on 9/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOSync.h"

#define PVO_SYNC_ALERT_CONFIRM_INT_ID 10
#define PVO_SYNC_ALERT_CONFIRM_MERGE 11
#define PVO_SYNC_ALERT_DRIVER_PACKER 12

#define PVO_SYNC_TYPE 1
#define PVO_SYNC_LOC_ORDER_NUM 2
#define PVO_SYNC_INT_ORDER_NUM 3
#define PVO_SYNC_DOWNLOAD 4
//required for packer download
#define PVO_SYNC_INT_CUST_LAST_NAME 5
#define PVO_SYNC_INT_AGENCY_CODE 6

@interface PVOSyncController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    BOOL downloading;
    PVOSync *sync;
    UITextField *tboxCurrent;
    NSMutableArray *includedRows;
    int requestType;
    NSString *orderNum;
    NSString *localOrderNum;
    
    BOOL editing;
}

@property (nonatomic, retain) PVOSync *sync;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) NSString *orderNum;
@property (nonatomic, retain) NSString *localOrderNum;


-(IBAction)cancel:(id)sender;
-(IBAction)requestTypeChanged:(id)sender;

-(void)updateProgress:(NSString*)textToAdd;

-(void)beginSync:(BOOL)merge;
-(void)initializeIncludedRows;

-(void)updateValueWithField:(UITextField*)tbox;

-(void)checkMerge;

@end
