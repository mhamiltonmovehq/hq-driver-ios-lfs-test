//
//  PVOClaimItemDetailController.h
//  Survey
//
//  Created by Tony Brame on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOClaimItem.h"
#import "SurveyImageViewer.h"

#define PVO_CLAIM_ITEM_NUMBER 0
#define PVO_CLAIM_ITEM_NAME 1
#define PVO_CLAIM_ITEM_ROOM 2

#define PVO_CLAIM_ITEM_DAMAGE_DESCRIPTION 0
#define PVO_CLAIM_ITEM_IMAGES 1
#define PVO_CLAIM_ITEM_WEIGHT 2
#define PVO_CLAIM_ITEM_AGE 3
#define PVO_CLAIM_ITEM_ORIGINAL_COST 4
#define PVO_CLAIM_ITEM_REPLACEMENT_COST 5
#define PVO_CLAIM_ITEM_REPAIR_COST 6

@interface PVOClaimItemDetailController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>
{
    PVOClaimItem *item;
    UITextField *tboxCurrent;
    UITextView *tviewCurrent;
    SurveyImageViewer *imageViewer;
}

@property (nonatomic, retain) PVOClaimItem *item;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) UITextView *tviewCurrent;

-(void)updateValueWithField:(UITextField*)tbox;
-(IBAction)textFieldDoneEditing:(id)sender;

@end
