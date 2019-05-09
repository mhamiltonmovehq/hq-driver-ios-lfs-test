//
//  EditDateController.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOBaseViewController.h"

#define EDIT_DATE_RANGE 1
#define EDIT_DATE_SINGLE 2
#define EDIT_TIME_RANGE 3
#define EDIT_TIME_SINGLE 4
#define EDIT_DATE_TIME_RANGE 5
#define EDIT_DATE_TIME_SINGLE 6

#define EDIT_DATE_FROM_IDX 0
#define EDIT_DATE_TO_IDX 1
#define EDIT_DATE_PREFER_IDX 2

@interface EditDateController : PVOBaseViewController
<UITableViewDelegate, UITableViewDataSource>{
    
    IBOutlet UITableView *tableView;
    IBOutlet UIDatePicker *datePicker;
    
    NSDate *fromDate;
    NSDate *toDate;
    NSDate *preferDate;
    
    int editingMode;
    int editingFromTo;
    
    NSObject *caller;
    SEL callback;
    
    BOOL isDatePopover;
    UIPopoverController *popover;
    
    BOOL useOldMethodCallback;
}

@property (nonatomic) SEL callback;

@property (nonatomic, strong) NSObject *caller;

@property (nonatomic) int editingMode;
@property (nonatomic, strong) NSDate *fromDate;
@property (nonatomic, strong) NSDate *toDate;
@property (nonatomic, strong) NSDate *preferDate;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@property (nonatomic) BOOL isDatePopover;
@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic) BOOL useOldMethodCallback;

-(void)updateDatePicker;

-(IBAction)cancel:(id)sender;
-(IBAction)done:(id)sender;
-(IBAction)dateSelected:(id)sender;

@end
