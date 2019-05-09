//
//  BasicInfoController.h
//  Survey
//
//  Created by Tony Brame on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SurveyCustomer.h"
#import "SurveyCustomerSync.h"
#import "ShipmentInfo.h"
#import "SurveyPhone.h"
#import "PVORoomSummaryController.h"

#define BASIC_INFO_LAST_NAME 1
#define BASIC_INFO_FIRST_NAME 2
#define BASIC_INFO_EMAIL 3
#define BASIC_INFO_WEIGHT 4
#define BASIC_INFO_PRICING_MODE 5
#define BASIC_INFO_SYNC 6
//#define BASIC_INFO_SYNC_TO_QM 6
//#define BASIC_INFO_SYNC_ID 7 - moved to Move Info screen
#define BASIC_INFO_NUM_FIELDS 7
#define BASIC_INFO_ORDER_NUMBER 8
#define BASIC_INFO_GBL_NUMBER 9
#define BASIC_INFO_PRIMARY_PHONE 10
#define BASIC_INFO_PVO_SYNC 11
#define BASIC_INFO_PVO_VIEW_SURVEY 12
#define BASIC_INFO_COMPANY_NAME 13
#define BASIC_INFO_PVO_VIEW_PACKER_INVENTORY 14
#define BASIC_INFO_LANGUAGE 15
#define BASIC_INFO_INVENTORY_TYPE 16
#define BASIC_INFO_PVO_VIEW_PACK_SUMMARY 17

@class SurveyAppDelegate;

@interface BasicInfoController : UITableViewController
    <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{
    BOOL firstLoad;
    BOOL keyboardIsShowing;
    int    keyboardHeight;
    
    SurveyAppDelegate *del;
    int originalPricingMode;
    int originalLanguage;
    int originalItemListID;
}

@property (nonatomic) NSInteger custID;
@property (nonatomic,strong) SurveyCustomer *cust;
@property (nonatomic,strong) NSDictionary *pricingModes;
@property (nonatomic,strong) NSDictionary *inventoryTypes;
@property (nonatomic,strong) NSDictionary *customerPricingModesNew;
@property (nonatomic,strong) SurveyCustomerSync *sync;
@property (nonatomic,strong) ShipmentInfo *info;
@property (nonatomic,strong) UITextField *tboxCurrent;
@property (nonatomic,strong) UIPopoverController *popover;
@property (nonatomic,strong) NSMutableArray *rows;
@property (nonatomic,strong) SurveyPhone *phone;
@property (nonatomic) BOOL newCustomerView;
@property (nonatomic,strong) PVORoomSummaryController *pvoRoomSummaryController;
@property (nonatomic, strong) NSDictionary *languages;

@end
