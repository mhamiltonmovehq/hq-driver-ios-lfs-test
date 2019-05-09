//
//  PVOItemAdditionalController.h
//  Survey
//
//  Created by Tony Brame on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanApiHelper.h"
#import "DTDevices.h"

#define SCAN_ENTER_MODE 0
#define SCAN_ENTER_TEXT 1
#define SCAN_ENTER_SCANNER 2


@class ScanOrEnterValueController;
@protocol ScanOrEnterValueControllerDelegate <NSObject>
@optional
-(void)scanOrEnterValueController:(ScanOrEnterValueController*)controller dataEntered:(NSString*)data;
-(BOOL)scanOrEnterValueControllerShowDone:(ScanOrEnterValueController*)controller;
-(void)scanOrEnterValueControllerDone:(ScanOrEnterValueController*)controller;
-(NSString*)scanOrEnterValueHeaderText:(ScanOrEnterValueController*)controller;
-(void)scanOrEnterValueWillDisplay:(ScanOrEnterValueController*)controller;
@end


@interface ScanOrEnterValueController : UITableViewController <UITextFieldDelegate, ScanApiHelperDelegate, DTDeviceDelegate>
{
    NSString *description;
    
    BOOL usingScanner;
    
    NSMutableArray *rows;
    UITextField *tboxCurrent;
    
    NSString *data;
    
    id<ScanOrEnterValueControllerDelegate> delegate;
}

@property (nonatomic) BOOL usingScanner;

@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *data;
@property (nonatomic, strong) id<ScanOrEnterValueControllerDelegate> delegate;

-(void)initializeIncludedRows;

-(IBAction)cmdContinueClick:(id)sender;
-(IBAction)cmdDoneClick:(id)sender;

-(IBAction)segmentChanged:(id)sender;
-(void)updateValueWithField:(UITextField*)tbox;
-(IBAction)textFieldDoneEditing:(id)sender;

-(void)valueEntered:(NSString*)val;

@end
