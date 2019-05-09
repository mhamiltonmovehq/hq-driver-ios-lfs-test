//
//  PVOEditAutoViewController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOVehicle.h"
#import "SurveyAppDelegate.h"
#import "TextCell.h"
#import "PVOCheckListController.h"

#define AUTO_INV_DECL_VALUE 0
#define AUTO_INV_TYPE 1
#define AUTO_INV_YEAR 2
#define AUTO_INV_MAKE 3
#define AUTO_INV_MODEL 4
#define AUTO_INV_COLOR 5
#define AUTO_INV_VIN 6
#define AUTO_INV_LICENSE 7
#define AUTO_INV_LICENSE_ST 8
#define AUTO_INV_ODOMETER 9

@interface PVOAutoEditViewController : UITableViewController <UITextFieldDelegate>
{
    PVOVehicle *vehicle;
    
    UITextField *tboxCurrent;
    
    PVOChecklistController *checkListController;
    
    BOOL keyboardIsShowing;
    int	keyboardHeight;
    
    BOOL isOrigin;
}

@property (nonatomic, retain) PVOVehicle *vehicle;

@property (nonatomic, retain) UITextField *tboxCurrent;

@property (nonatomic, retain) PVOChecklistController *checkListController;

@property (nonatomic) BOOL isOrigin;

@end
