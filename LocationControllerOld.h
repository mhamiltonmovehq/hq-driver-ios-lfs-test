//
//  LocationController.h
//  Survey
//
//  Created by Tony Brame on 5/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyLocation.h"

@interface LocationController : UIViewController {
	NSInteger custID;
	NSInteger locationID;
	IBOutlet UITextField *tboxAddress;
	IBOutlet UITextField *tboxCity;
	IBOutlet UITextField *tboxState;
	IBOutlet UITextField *tboxZip;
	IBOutlet UITextField *tboxHomePhone;
	IBOutlet UITextField *tboxWorkPhone;
	
	SurveyLocation *location;
}

@property (nonatomic) NSInteger custID;
@property (nonatomic) NSInteger locationID;
@property (nonatomic, retain) UITextField *tboxAddress;
@property (nonatomic, retain) UITextField *tboxCity;
@property (nonatomic, retain) UITextField *tboxState;
@property (nonatomic, retain) UITextField *tboxZip;
@property (nonatomic, retain) UITextField *tboxHomePhone;
@property (nonatomic, retain) UITextField *tboxWorkPhone;
@property (nonatomic, retain) SurveyLocation *location;

-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)backgroundClicked:(id)sender;


@end
