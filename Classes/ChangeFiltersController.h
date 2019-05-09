//
//  ChangeFiltersController.h
//  Survey
//
//  Created by Tony Brame on 10/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomerFilterOptions.h"

@interface ChangeFiltersController : UITableViewController {
	CustomerFilterOptions *filters;
	
	NSMutableDictionary *sort;
	NSMutableDictionary *status;
	NSMutableDictionary *dates;
	
	UIPopoverController *popover;
	
	int editRow;
}

@property (nonatomic, retain) CustomerFilterOptions *filters;
@property (nonatomic, retain) NSMutableDictionary *sort;
@property (nonatomic, retain) NSMutableDictionary *status;
@property (nonatomic, retain) NSMutableDictionary *dates;
@property (nonatomic, retain) UIPopoverController *popover;

-(void)initializeLists;

-(void)valueUpdated:(NSNumber*)newValue;
-(void)dateUpdated:(NSDate*)date withIgnore:(NSDate*)ignore;
-(IBAction)done:(id)sender;

@end
