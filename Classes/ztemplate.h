//
//  LocalAccShuttleController.h
//  Survey
//
//  Created by Tony Brame on 9/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocalAcc.h"

#define LOCAL_ACC_SHUTTLE_OT 0
#define LOCAL_ACC_SHUTTLE_MEN 1
#define LOCAL_ACC_SHUTTLE_VANS 2
#define LOCAL_ACC_SHUTTLE_HOURS 3
#define LOCAL_ACC_SHUTTLE_WEIGHT 4
#define LOCAL_ACC_SHUTTLE_CUFT 5

@interface LocalAccShuttleController : UITableViewController <UITextFieldDelegate> {
	UITextField *tboxCurrent;
	LocalAcc *acc;
}

@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) LocalAcc *acc;


-(IBAction)switchChanged:(id)sender;
-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(UITextField*)field;

@end
