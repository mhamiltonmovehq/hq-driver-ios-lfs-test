//
//  DriverDataController.h
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DriverData.h"
#import "SignatureViewController.h"
#import "LandscapeNavController.h"
#import "PackerInitialsController.h"
#import "PVOBaseTableViewController.h"


#define DRIVER_DATA_SECTION_DRIVERPACKER 0
#define DRIVER_DATA_SECTION_HAULINGAGENT 1
#define DRIVER_DATA_SECTION_APPLICATION_OPTIONS 2




#define DRIVER_DATA_VANLINE 0
#define DRIVER_DATA_HAULING_AGENT 1
#define DRIVER_DATA_SAFETY_NUMBER 2
#define DRIVER_DATA_DRIVER_NAME 3
#define DRIVER_DATA_DRIVER_NUMBER 4
#define DRIVER_DATA_HAULING_EMAIL 5
#define DRIVER_DATA_HAULING_EMAIL_CC_BCC 6
#define DRIVER_DATA_DRIVER_EMAIL 7
#define DRIVER_DATA_DRIVER_EMAIL_CC_BCC 8
#define DRIVER_DATA_UNIT_NUMBER 9
#define DRIVER_DATA_DAMAGE_VIEW 10
#define DRIVER_DATA_SIGNATURE 11
#define DRIVER_DATA_ROOM_CONDITIONS 12
#define DRIVER_DATA_DRIVER_PASSWORD 13
#define DRIVER_DATA_REPORT_PREFERENCE 14
#define DRIVER_DATA_ARPIN_SYNC_PREFERENCE 15
#define DRIVER_DATA_TRACTOR_NUMBER 16
#define DRIVER_DATA_QUICK_INVENTORY 17
#define DRIVER_DATA_SHOW_TRACTOR_TRAILER 18
#define DRIVER_DATA_SAVE_TO_CAM_ROLL 19
#define DRIVER_DATA_DRIVER_TYPE 20
#define DRIVER_DATA_PACKER_INITIALS 21
#define DRIVER_DATA_USE_SCANNER 22
#define DRIVER_DATA_MOVE_HQ_SETTINGS 23
#define DRIVER_DATA_PACKER_NAME 24
#define DRIVER_DATA_PACKER_EMAIL 25
#define DRIVER_DATA_PACKER_EMAIL_CC_BCC 26

#define DRIVER_DATA_SWITCH_HAULING_EMAIL_CC 100
#define DRIVER_DATA_SWITCH_HAULING_EMAIL_BCC 101
#define DRIVER_DATA_SWITCH_DRIVER_EMAIL_CC 102
#define DRIVER_DATA_SWITCH_DRIVER_EMAIL_BCC 103

@interface DriverDataController : PVOBaseTableViewController <UITextFieldDelegate, SignatureViewControllerDelegate> {
    DriverData *data;
    NSMutableDictionary *rows;
    NSMutableDictionary *vanlines;
    NSMutableDictionary *damageOptions;
    NSMutableDictionary *reportOptions;
    NSMutableDictionary *syncOptions;
    NSMutableDictionary *driverTypes;
    NSMutableDictionary *emailOptions;
    UITextField *tboxCurrent;
    BOOL editing;
    
    int selectingRow;
    
    SignatureViewController *sigView;
    LandscapeNavController *sigNav;
    
    PackerInitialsController *packerInitialController;
}

@property (nonatomic, strong) DriverData *data;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) NSMutableArray *sections;

-(void)initializeIncludedRows;

-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(UITextField*)fld;
-(IBAction)valueSelected:(id)sender;
-(IBAction)done:(id)sender;
-(IBAction)switchChanged:(id)sender;

@end
