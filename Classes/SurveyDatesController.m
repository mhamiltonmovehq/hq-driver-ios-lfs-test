//
//  SurveyDatesController.m
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyDatesController.h"
#import "SingleDateCell.h"
#import "DateRangeCell.h"
#import "SurveyAppDelegate.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"

@implementation SurveyDatesController

@synthesize dates, editingPath, dateController;
@synthesize lockFields;

-(void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
        self.automaticallyAdjustsScrollViewInsets = NO;
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
	self.preferredContentSize = CGSizeMake(320, 416);	
	[super viewDidLoad];
    
    visibleIndividualDates = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
	
    lockFields = [AppFunctionality lockFieldsOnSourcedFromServer] && [CustomerUtilities customerSourcedFromServer];
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	if(!editing)
	{
		//load options
		self.dates = [del.surveyDB getDates:del.customerID];
        if(dates.inventory == nil)
            dates.inventory = [NSDate date];
	}
	
	editing = NO;
	
    [self initializeIncludedIndividualRows];
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

-(void)initializeIncludedIndividualRows
{
    [visibleIndividualDates removeAllObjects];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(del.viewType == OPTIONS_PVO_VIEW)
    {
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_PACK_DATE_SECTION]];
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_LOAD_DATE_SECTION]];
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_DELIVER_DATE_SECTION]];
        
        //removed per defect 285
        //[visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_INVENTORY_DATE_ROW]];
    }
    else
    {
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_SURVEY_DATE_ROW]];
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_SURVEY_TIME_ROW]];
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_DECISION_DATE_ROW]];
        [visibleIndividualDates addObject:[NSNumber numberWithInt:SURVEYDATES_FOLLOW_UP_DATE_ROW]];
    }
    
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(void)datesSaved:(NSArray*)newDates
{
    if (newDates == nil) return;
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    int row = [[visibleIndividualDates objectAtIndex:editingPath.row] intValue];
    
	switch ([editingPath section]) {
		case SURVEYDATES_PACK_DATE_SECTION:
            if (newDates.count > 0)
                dates.packFrom = [newDates objectAtIndex:0];
            if (newDates.count > 1)
                dates.packTo = [newDates objectAtIndex:1];
            if (newDates.count > 2)
                dates.packPrefer = [newDates objectAtIndex:2];
			break;
		case SURVEYDATES_LOAD_DATE_SECTION:
            if (newDates.count > 0)
                dates.loadFrom = [newDates objectAtIndex:0];
            if (newDates.count > 1)
                dates.loadTo = [newDates objectAtIndex:1];
            if (newDates.count > 2)
                dates.loadPrefer = [newDates objectAtIndex:2];
			break;
		case SURVEYDATES_DELIVER_DATE_SECTION:
            if (newDates.count > 0)
                dates.deliverFrom = [newDates objectAtIndex:0];
            if (newDates.count > 1)
                dates.deliverTo = [newDates objectAtIndex:1];
            if (newDates.count > 2)
                dates.deliverPrefer = [newDates objectAtIndex:2];
			break;
		case SURVEYDATES_INDIVIDUAL_DATES_SECTION:
			switch (row) {
				case SURVEYDATES_SURVEY_DATE_ROW:
                    if (newDates.count > 0)
                        dates.survey = [newDates objectAtIndex:0];;
					break;
				case SURVEYDATES_SURVEY_TIME_ROW:
                    if (newDates.count > 0)
                        dates.survey = [newDates objectAtIndex:0];;
					break;
				case SURVEYDATES_FOLLOW_UP_DATE_ROW:
                    if (newDates.count > 0)
                        dates.followUp = [newDates objectAtIndex:0];;
					break;
				case SURVEYDATES_DECISION_DATE_ROW:
                    if (newDates.count > 0)
                        dates.decision = [newDates objectAtIndex:0];;
					break;
				case SURVEYDATES_INVENTORY_DATE_ROW:
                    if (newDates.count > 0)
                        dates.inventory = [newDates objectAtIndex:0];;
					break;
			}
			break;
	}
	
	[del.surveyDB updateDates:dates];
	
	[self.tableView reloadData];
	
}

-(IBAction)noDatesValueChanged:(id)sender
{
	UISwitch *thisSwitch = sender;
	
	switch(thisSwitch.tag)
	{
		case SURVEYDATES_PACK_DATE_SECTION:
			dates.noPack = !thisSwitch.on;
			break;
		case SURVEYDATES_LOAD_DATE_SECTION:
			dates.noLoad = !thisSwitch.on;
			break;
		case SURVEYDATES_DELIVER_DATE_SECTION:
			dates.noDeliver = !thisSwitch.on;
			break;
	}
	
}

- (void)viewWillDisappear:(BOOL)animated {
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	[del.surveyDB updateDates:dates];
	
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [visibleIndividualDates count]; //SURVEYDATES_SECTIONS;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == SURVEYDATES_INDIVIDUAL_DATES_SECTION ? [visibleIndividualDates count] : 1;
}

-(CGFloat) tableView: (UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if([indexPath section] < SURVEYDATES_INDIVIDUAL_DATES_SECTION)
		return 70;
	else
		return 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *SingleDateCellID = @"SingleDateCellID";
    static NSString *DateRangeCellID = @"DateRangeCellID";
	NSDateFormatter *time;
	DateRangeCell *drCell = nil;
	SingleDateCell *sdCell = nil;
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	
	if([indexPath section] < SURVEYDATES_INDIVIDUAL_DATES_SECTION)
	{//date ranges
		drCell = (DateRangeCell *)[tableView dequeueReusableCellWithIdentifier:DateRangeCellID];
		if (drCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DateRangeCell" owner:self options:nil];
			drCell = [nib objectAtIndex:0];
			
			[drCell.switchNoDates addTarget:self
			 action:@selector(noDatesValueChanged:) 
			 forControlEvents:UIControlEventValueChanged];
		}
		
        if(lockFields)
        {
            drCell.accessoryType = UITableViewCellAccessoryNone;
            drCell.switchNoDates.enabled = NO;
        }
        else
        {
            drCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            drCell.switchNoDates.enabled = YES;
        }
        
        int row = [[visibleIndividualDates objectAtIndex:[indexPath section]] intValue];
        
        drCell.switchNoDates.tag = row; //[indexPath section];
		
		switch (row) //([indexPath section])
		{
			case SURVEYDATES_PACK_DATE_SECTION:
				drCell.labelType.text = @"Pack";
                if (dates.packFrom != nil)
                    drCell.labelFromDate.text = [formatter stringFromDate: dates.packFrom];
                if (dates.packTo != nil)
                    drCell.labelToDate.text = [formatter stringFromDate: dates.packTo];
                if (dates.packPrefer != nil)
                    drCell.labelPreferDate.text = [formatter stringFromDate: dates.packPrefer];
				drCell.switchNoDates.on = !dates.noPack && [AppFunctionality enablePackDatesSection];
                
                //NOTE: per feedback from Brian we should not show pack dates for auto inventory records...
                drCell.switchNoDates.enabled = [AppFunctionality enablePackDatesSection];
				break;
			case SURVEYDATES_LOAD_DATE_SECTION:
				drCell.labelType.text = @"Load";
                if (dates.loadFrom != nil)
                    drCell.labelFromDate.text = [formatter stringFromDate: dates.loadFrom];
                if (dates.loadTo != nil)
                    drCell.labelToDate.text = [formatter stringFromDate: dates.loadTo];
                if (dates.loadPrefer != nil)
                    drCell.labelPreferDate.text = [formatter stringFromDate: dates.loadPrefer];
				drCell.switchNoDates.on = !dates.noLoad;
				break;
			case SURVEYDATES_DELIVER_DATE_SECTION:
				drCell.labelType.text = @"Deliver";
                if (dates.deliverFrom != nil)
                    drCell.labelFromDate.text = [formatter stringFromDate: dates.deliverFrom];
                if (dates.deliverTo != nil)
                    drCell.labelToDate.text = [formatter stringFromDate: dates.deliverTo];
                if (dates.deliverPrefer != nil)
                    drCell.labelPreferDate.text = [formatter stringFromDate: dates.deliverPrefer];
				drCell.switchNoDates.on = !dates.noDeliver;
				break;
		}
		[drCell switchNoDatesValueChanged:nil];
		
	}
	else
	{//single date
		sdCell = (SingleDateCell *)[tableView dequeueReusableCellWithIdentifier:SingleDateCellID];
		if (sdCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SingleDateCell" owner:self options:nil];
			sdCell = [nib objectAtIndex:0];
		}
        
        if(lockFields)
            sdCell.accessoryType = UITableViewCellAccessoryNone;
        else
            sdCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        int row = [[visibleIndividualDates objectAtIndex:indexPath.row] intValue];
		
		switch(row)
		{
			case SURVEYDATES_SURVEY_DATE_ROW:
				sdCell.labelType.text = @"Survey";
				sdCell.labelDate.text = [formatter stringFromDate:dates.survey];
				break;
			case SURVEYDATES_SURVEY_TIME_ROW:
				time = [[NSDateFormatter alloc] init];
				[time setDateFormat:@"hh:mm a"];
				sdCell.labelType.text = @"Survey Time";
				sdCell.labelDate.text = [time stringFromDate:dates.survey];
				break;
			case SURVEYDATES_FOLLOW_UP_DATE_ROW:
				sdCell.labelType.text = @"Follow Up";
				sdCell.labelDate.text = [formatter stringFromDate:dates.followUp];
				break;
			case SURVEYDATES_DECISION_DATE_ROW:
				sdCell.labelType.text = @"Decision";
				sdCell.labelDate.text = [formatter stringFromDate:dates.decision];
				break;
			case SURVEYDATES_INVENTORY_DATE_ROW:
				sdCell.labelType.text = @"Inventory";
				sdCell.labelDate.text = [formatter stringFromDate:dates.inventory];
				break;
		}
	}
	
	
    
	UITableViewCell *retval;
	
	if(drCell != nil)
		retval = drCell;
	else
		retval = sdCell;
	
    return retval;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //NOTE: per feedback from Brian we should not show pack dates for auto inventory records... - DY
    //Hiding this section breaks the functionality of the other sections. I put it back in and disabled it. - JL
    if ([indexPath section] == SURVEYDATES_PACK_DATE_SECTION && ![AppFunctionality enablePackDatesSection])
    {
        return;
    }
    
    if(lockFields)
        return;
	
	if(dateController == nil)
	{
		dateController = [[EditDateController alloc] initWithNibName:@"EditDateView" bundle:nil];
		dateController.caller = self;
		dateController.callback = @selector(datesSaved:);
	}
		
	dateController.editingMode = EDIT_DATE_RANGE;
    
    int row = [[visibleIndividualDates objectAtIndex:indexPath.row] intValue];
  	switch([indexPath section])
	{
		case SURVEYDATES_PACK_DATE_SECTION:
			dateController.fromDate = dates.packFrom;
			dateController.toDate = dates.packTo;
            dateController.preferDate = dates.packPrefer;
			dateController.title = @"Pack Dates";
			break;
		case SURVEYDATES_LOAD_DATE_SECTION:
			dateController.fromDate = dates.loadFrom;
			dateController.toDate = dates.loadTo;
            dateController.preferDate = dates.loadPrefer;
			dateController.title = @"Load Dates";
			break;
		case SURVEYDATES_DELIVER_DATE_SECTION:
			dateController.fromDate = dates.deliverFrom;
			dateController.toDate = dates.deliverTo;
            dateController.preferDate = dates.deliverPrefer;
			dateController.title = @"Deliver Dates";
			break;
		case SURVEYDATES_INDIVIDUAL_DATES_SECTION:
            dateController.editingMode = EDIT_DATE_SINGLE;
			switch (row) {
				case SURVEYDATES_SURVEY_DATE_ROW:
					dateController.fromDate = dates.survey;
					dateController.title = @"Survey Date";
					break;
				case SURVEYDATES_SURVEY_TIME_ROW:
					dateController.fromDate = dates.survey;
					dateController.title = @"Survey Time";
					break;
				case SURVEYDATES_FOLLOW_UP_DATE_ROW:
					dateController.fromDate = dates.followUp;
					dateController.title = @"Follow Up Date";
					break;
				case SURVEYDATES_DECISION_DATE_ROW:
					dateController.fromDate = dates.decision;
					dateController.title = @"Decision Date";
					break;
				case SURVEYDATES_INVENTORY_DATE_ROW:
					dateController.fromDate = dates.inventory;
					dateController.title = @"Inventory Date";
					break;
			}
			break;
	}
	
	editing = YES;
	self.editingPath = indexPath;
	//SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	//[del.navController pushViewController:dateController animated:YES];
	[self.navigationController pushViewController:dateController animated:YES];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end

