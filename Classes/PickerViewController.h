//
//  PickerViewController.h
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PickerViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate> {
	//key is the display string
	NSDictionary *options;
	NSArray *keys;
	IBOutlet UIPickerView *picker;
	IBOutlet UITableView *tableView;
	SEL callback;
	NSObject *caller;
	NSNumber *currentSelection;
	UIPopoverController *popover;
	BOOL isPickerPopover;
}

@property (nonatomic) SEL callback;
@property (nonatomic) BOOL isPickerPopover;

@property (nonatomic, retain) NSDictionary *options;
@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) UIPickerView *picker;
@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSNumber *currentSelection;
@property (nonatomic, retain) UIPopoverController *popover;

-(void) cancel:(id)sender;
-(void) save:(id)sender;

@end
