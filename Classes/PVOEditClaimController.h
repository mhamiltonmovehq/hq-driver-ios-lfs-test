//
//  PVOEditClaimController.h
//  Survey
//
//  Created by Tony Brame on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOClaim.h"
#import "PVOClaimItemsController.h"

#define PVO_CLAIM_EMPLOYER_PAID 1
#define PVO_CLAIM_EMPLOYER 2
#define PVO_CLAIM_IN_WAREHOUSE 3
#define PVO_CLAIM_AGENCY_CODE 4

@interface PVOEditClaimController : UITableViewController <UITextFieldDelegate>
{
    NSMutableArray *includedRows;
    PVOClaim *claim;
    UITextField *tboxCurrent;
    PVOClaimItemsController *itemsController;
}

@property (nonatomic, retain) NSMutableArray *includedRows;
@property (nonatomic, retain) PVOClaim *claim;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) PVOClaimItemsController *itemsController;

-(void)initializeIncludedRows;
-(IBAction)cmdNext_Click:(id)sender;
-(IBAction)switchChanged:(id)sender;
-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(UITextField*)tbox;

@end
