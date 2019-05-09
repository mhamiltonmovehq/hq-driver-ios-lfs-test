//
//  EditPhoneController.h
//  Survey
//
//  Created by Tony Brame on 5/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyPhone.h"
#import "PhoneTypeController.h"
#import "PVOBaseTableViewController.h"

#define EDIT_PHONE_SECTIONS 2

#define	EDIT_PHONE_NUMBER 0
#define EDIT_PHONE_TYPE 1

@interface EditPhoneController : PVOBaseTableViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
	SurveyPhone *phone;
	UITextField *tboxCurrent;
	Boolean newPhone;
	PhoneTypeController *phoneTypeController;
    NSInteger originalPhoneTypeID;
    int locationID;
    BOOL primaryChanged;
    SurveyPhone *oldPhone;
}

@property (nonatomic) Boolean newPhone;
@property (nonatomic) NSInteger originalPhoneTypeID;
@property (nonatomic) int locationID;
@property (nonatomic, retain) SurveyPhone *phone;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) PhoneTypeController *phoneTypeController;
@property (nonatomic) BOOL primaryChanged;
@property (nonatomic, retain) SurveyPhone *oldPhone;


-(void)updatePrimaryPhones;
-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

-(IBAction)textFieldDoneEditing:(id)sender;

@end
