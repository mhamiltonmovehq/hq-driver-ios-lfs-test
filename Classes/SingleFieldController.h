//
//  SingleFieldController.h
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SingleFieldController : UITableViewController
	<UITableViewDelegate, UITableViewDataSource>
{
	NSString *destString;
	NSString *placeholder;
    NSString *title;
	UITextField *tboxCurrent;
	SEL callback;
	NSObject *caller;
	UIKeyboardType keyboard;
	BOOL clearOnEdit;
	BOOL dismiss;
    BOOL modal;
    BOOL requireValue;
    UITextAutocapitalizationType autocapitalizationType;
}

@property (nonatomic) SEL callback;
@property (nonatomic) UIKeyboardType keyboard;
@property (nonatomic) BOOL clearOnEdit;
@property (nonatomic) BOOL dismiss;
@property (nonatomic) BOOL modal;
@property (nonatomic) BOOL requireValue;

@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) NSString *destString;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) UITextField *tboxCurrent;

@property (nonatomic) UITextAutocapitalizationType autocapitalizationType;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
