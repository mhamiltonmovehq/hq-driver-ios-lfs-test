//
//  SelectNewAgencyController.h
//  Survey
//
//  Created by Tony Brame on 7/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyAgent.h"

#define SORT_NAME 0
#define SORT_CODE 1

#define STATE_SECTION 0
#define NAME_SECTION 1

@interface SelectNewAgencyController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UITableView *tableView;
    IBOutlet UIPickerView *picker;
    IBOutlet UISegmentedControl *sortByControl;
    NSMutableArray *states;
    NSMutableArray *agencies;
    NSString *currentState;
    NSString *currentAgency;
    SEL callback;
    NSObject *caller;
}

@property (nonatomic) SEL callback;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) UISegmentedControl *sortByControl;
@property (nonatomic, strong) NSMutableArray *states;
@property (nonatomic, strong) NSMutableArray *agencies;
@property (nonatomic, strong) NSString *currentState;
@property (nonatomic, strong) NSString *currentAgency;
@property (nonatomic, strong) NSObject *caller;

-(IBAction)switchSort:(id)sender;
-(void)selectAgency:(id)sender;

@end
