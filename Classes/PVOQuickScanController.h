//
//  PVOQuickScanController.h
//  Survey
//
//  Created by Tony Brame on 9/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOInventory.h"
#import "PVOItemDetail.h"
#import "PVODelBatchExcController.h"
#import "ScanApiHelper.h"
#import "SurveyImageViewer.h"
#import "DTDevices.h"

@class PVOInventoryLoad;

@interface PVOQuickScanController : UITableViewController <ScanApiHelperDelegate, DTDeviceDelegate>
{
    NSMutableArray *addedTags;
    NSMutableArray *visitedTags;
    BOOL askingForQuantity;
    int quantity;
    PVOInventory *inventory;
    
    UITextField *tboxCurrent;
    
    PVOItemDetail *pvoItem;
    PVOInventoryLoad *currentLoad;
    PVODelBatchExcController *exceptionsController;
    
    SurveyImageViewer *imageViewer;
    
    BOOL managingPhotos;
    BOOL updatePvoItemAfterQuantity;
    
    BOOL hideBackButtonWithScanner;
}

@property (nonatomic) int quantity;
@property (nonatomic) BOOL managingPhotos;
@property (nonatomic) BOOL updatePvoItemAfterQuantity;
@property (nonatomic, retain) PVOItemDetail *pvoItem;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;

@property (nonatomic, retain) NSMutableArray *addedTags;
@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) PVODelBatchExcController *exceptionsController;

@property (nonatomic) BOOL hideBackButtonWithScanner;

-(IBAction)cmdContinueSelected:(id)sender;
-(PVOItemDetail*)getQuickScanCopy:(PVOItemDetail*)fromItem;

@end
