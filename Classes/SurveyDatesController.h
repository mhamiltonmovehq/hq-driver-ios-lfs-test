//
//  SurveyDatesController.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyDates.h"
#import "EditDateController.h"

#define SURVEYDATES_SECTIONS 3

#define SURVEYDATES_PACK_DATE_SECTION 0

#define SURVEYDATES_LOAD_DATE_SECTION 1

#define SURVEYDATES_DELIVER_DATE_SECTION 2

#define SURVEYDATES_INDIVIDUAL_DATES_SECTION 3

#define SURVEYDATES_SURVEY_DATE_ROW 0
#define SURVEYDATES_SURVEY_TIME_ROW 1
#define SURVEYDATES_DECISION_DATE_ROW 2
#define SURVEYDATES_FOLLOW_UP_DATE_ROW 3
#define SURVEYDATES_INVENTORY_DATE_ROW 4

@interface SurveyDatesController : UITableViewController <UIAlertViewDelegate> {
	BOOL editing;
	SurveyDates *dates;
	NSIndexPath *editingPath;
	EditDateController *dateController;
    
    NSMutableArray *visibleIndividualDates;
    
    BOOL lockFields;
}

@property (nonatomic, retain) SurveyDates *dates;
@property (nonatomic, retain) NSIndexPath *editingPath;
@property (nonatomic, retain) EditDateController *dateController;
@property (nonatomic) BOOL lockFields;

-(void)initializeIncludedIndividualRows;

-(void)datesSaved:(NSArray*)dates;

-(IBAction)noDatesValueChanged:(id)sender;

@end
