//
//  PVOItemAdditionalController.h
//  Survey
//
//  Created by Tony Brame on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOItemDetail.h"
#import "PVOInventory.h"
#import "ScannerInputView.h"
#import "Item.h"

#define PVO_ADD_SCANNER 0
#define PVO_ADD_YEAR_TEXT 1
#define PVO_ADD_MAKE_TEXT 2
#define PVO_ADD_MODEL_TEXT 3
#define PVO_ADD_SERIAL_TEXT 4
#define PVO_ADD_MODEL_SCANNER 5
#define PVO_ADD_SERIAL_SCANNER 6
#define PVO_ADD_ODOMETER_TEXT 7
#define PVO_ADD_CALIBER_GAUGE_TEXT 8
#define PVO_ADD_SECURITY_SEAL_SCANNER 9
#define PVO_ADD_SECURITY_SEAL_TEXT 10

@interface PVOItemAdditionalController : UITableViewController <UITextFieldDelegate, ScannerInputViewDelegate>
{
    Item *item;
    PVOItemDetail *pvoItem;
    PVOInventory *inventory;
    
    BOOL usingScanner;
    
    NSMutableArray *rows;
    UITextField *tboxCurrent;
    
    ScannerInputView *scannerInView;
}

@property (nonatomic) BOOL usingScanner;
@property (nonatomic) BOOL enteringSecuritySeal;


@property (nonatomic, strong) Item *item;
@property (nonatomic, strong) PVOItemDetail *pvoItem;
@property (nonatomic, strong) PVOInventory *inventory;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) ScannerInputView *scannerInView;

-(void)initializeIncludedRows;

-(IBAction)segmentChanged:(id)sender;
-(void)updateValueWithField:(UITextField*)tbox;
-(IBAction)textFieldDoneEditing:(id)sender;

@end
