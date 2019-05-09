//
//  PVOConfirmPaymentController.h
//  Survey
//
//  Created by Tony Brame on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PVO_CONFIRM_PAY_METHOD 0
#define PVO_CONFIRM_PAY_PREPAID 1
#define PVO_CONFIRM_PAY_AMOUNT 2

enum PAYMENT_METHODS {
    COD = 1,
    PREPAID = 2,
    NATL_ACCOUNT = 3
};

@interface PVOConfirmPaymentController : UITableViewController <UITextFieldDelegate> {
    NSMutableDictionary *paymentOptions;
    BOOL prepaid;
    UITextField *tboxCurrent;
    double amount;
    int paymentMethod;
}

@property (nonatomic) int paymentMethod;
@property (nonatomic, strong) UITextField *tboxCurrent;

-(void)updateValueWithField:(UITextField*)fld;
-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)switchChanged:(id)sender;
-(void)paymentMethodSelected:(NSNumber*)newValue;

@end
