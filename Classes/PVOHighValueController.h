//
//  PVOHighValueController.h
//  Survey
//
//  Created by Tony Brame on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignatureView.h"
#import "PVOItemDetail.h"

@interface PVOHighValueController : UIViewController {
    IBOutlet UITextField *tboxValue;
    IBOutlet SignatureView *packerInitials;
    IBOutlet SignatureView *shipperInitials;
    PVOItemDetail *pvoItem;
}

@property (nonatomic, strong) UITextField *tboxValue;
@property (nonatomic, strong) SignatureView *packerInitials;
@property (nonatomic, strong) SignatureView *shipperInitials;
@property (nonatomic, strong) PVOItemDetail *pvoItem;

-(IBAction)done:(id)sender;
-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)clearSignature:(id)sender;

@end
