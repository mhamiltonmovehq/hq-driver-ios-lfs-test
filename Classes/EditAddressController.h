//
//  EditAddressController.h
//  Survey
//
//  Created by Tony Brame on 5/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyLocation.h"
#import "PVOBaseTableViewController.h"

#define EDIT_ADDRESS_ADDRESS1 0
#define EDIT_ADDRESS_ADDRESS2 1
#define EDIT_ADDRESS_CITY 2
//same row, but need different tags
#define EDIT_ADDRESS_STATE 3
#define EDIT_ADDRESS_ZIP 4
#define EDIT_ADDRESS_NAME 5
#define EDIT_ADDRESS_SZ_ROW 6
#define EDIT_ADDRESS_TAKE_ME 8

#define EDIT_ADDRESS_LAST_NAME 9
#define EDIT_ADDRESS_FIRST_NAME 10
#define EDIT_ADDRESS_COMPANY_NAME 11

@interface EditAddressController : PVOBaseTableViewController
    <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,UIActionSheetDelegate>
{
    SurveyLocation *location;
    UITextField *tboxCurrent;
    BOOL newLocation;
    BOOL saved;
    BOOL extraStop;
    NSMutableArray *rows;
    
    BOOL lockFields;
}

@property (nonatomic) BOOL newLocation;
@property (nonatomic) BOOL saved;
@property (nonatomic) BOOL extraStop;
@property (nonatomic) BOOL lockFields;

@property (nonatomic, strong) SurveyLocation *location;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) NSMutableArray *rows;


-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateLocationValueWithField:(UITextField*)fld;

-(void)countySelected:(NSString*)county;
-(void)stateSelected:(NSString*)state;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

-(void)theyWantToGoToAddress:(id)sender;
-(void)gotoAddress;

-(void)initializeRows;
-(int)getRowTypeFromIndex:(NSIndexPath*)path;


@end
