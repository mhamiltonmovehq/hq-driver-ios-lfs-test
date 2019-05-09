//
//  InfoController.h
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShipmentInfo.h"
#import "SurveyCustomerSync.h"
#import "SignatureViewController.h"

#define INFO_LEAD_SOURCE 0 //text or standard to picker
#define INFO_MILEAGE 1 //text or standard to generate mileage
#define INFO_ORDER_NUMBER 2 //text
#define INFO_ESTIMATE_TYPE 4 //standard to picker
#define INFO_JOB_STATUS 5 //standard to picker
#define INFO_LEAD_SOURCE_SUB 6 //standard to picker
#define INFO_SIGNATURE 7

@interface InfoController : UITableViewController <UITextFieldDelegate> {
    BOOL leadSourceText;
    BOOL milesEditable;
    UITextField *tboxCurrent;
    ShipmentInfo *info;
    SurveyCustomerSync *sync;
    BOOL keyboardIsShowing;
    int keyboardHeight;
    NSMutableDictionary *estimateTypes;
    NSMutableDictionary *jobStatuses;
    BOOL editing;
    NSArray *leadSources;
    NSMutableArray *rows;
    
    UIPopoverController *popover;
    
    SignatureViewController *sigController;
}

@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) ShipmentInfo *info;
@property (nonatomic, strong) SurveyCustomerSync *sync;
@property (nonatomic, strong) NSMutableDictionary *estimateTypes;
@property (nonatomic, strong) NSMutableDictionary *jobStatuses;
@property (nonatomic, strong) NSArray *leadSources;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) SignatureViewController *sigController;

-(void) keyboardWillShow:(NSNotification *)note;
-(void) keyboardWillHide:(NSNotification *)note;
-(void)updateValueWithField:(UITextField*)fld;

-(void)estimateTypeSelected:(NSNumber*)estimateTypeID;
-(void)jobStatusSelected:(NSNumber*)jobStatusID;
-(void)leadSourceSelected:(NSString*)leadSource;
-(void)subLeadSourceSelected:(NSString*)subLeadSource;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

-(void)initializeRows;

-(int)rowTypeForIndex:(NSIndexPath*)idx;

@end
