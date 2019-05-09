//
//  EditDateController.m
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditDateController.h"
#import "EditDateCell.h"

@implementation EditDateController

@synthesize tableView, datePicker, editingMode, fromDate, toDate, preferDate, caller, callback, useOldMethodCallback;

@synthesize isDatePopover;
@synthesize popover;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.preferredContentSize = CGSizeMake(320, 416);
    
    if(isDatePopover)
    {
        self.view.frame = CGRectMake(0, 0, 320, 216);
        CGRect newFrame = self.datePicker.frame;
        newFrame.origin.y = 0;
        self.datePicker.frame = newFrame;
        self.preferredContentSize = CGSizeMake(320, 216);
        self.tableView.hidden = TRUE;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
    
    
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {
    
    datePicker.timeZone = [NSTimeZone systemTimeZone];
    
    //handle nulls.  default to today
    if (self.fromDate == nil)
        self.fromDate = [NSDate date];
    if (self.toDate == nil)
        self.toDate = [NSDate date];
    if (self.preferDate == nil)
        self.preferDate = [NSDate date];
    
    [self.tableView reloadData];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
                                animated:YES 
                          scrollPosition:UITableViewScrollPositionMiddle];
    
    if(editingMode == EDIT_DATE_RANGE || 
       editingMode == EDIT_DATE_SINGLE)
        datePicker.datePickerMode = UIDatePickerModeDate;
    else if(editingMode== EDIT_DATE_TIME_RANGE ||
            editingMode == EDIT_DATE_TIME_SINGLE)
        datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    else
        datePicker.datePickerMode = UIDatePickerModeTime;
    
    editingFromTo = EDIT_DATE_FROM_IDX;
    [self updateDatePicker];
    
    [super viewWillAppear:animated];
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

-(IBAction)cancel:(id)sender
{
    if(isDatePopover)
        [self.popover dismissPopoverAnimated:YES];
    else
        [self.navigationController popViewControllerAnimated:YES];
}


-(IBAction)done:(id)sender
{
    if([caller respondsToSelector:callback])
    {
        NSMethodSignature *methodSig = [[caller class] instanceMethodSignatureForSelector:callback]; //always includes at least two arguments
        if ([methodSig numberOfArguments] == 4 || useOldMethodCallback)
            [caller performSelector:callback withObject:fromDate withObject:toDate]; //old method
        else if ([methodSig numberOfArguments] == 3)
            [caller performSelector:callback withObject:[NSMutableArray arrayWithObjects:fromDate, toDate, preferDate, nil]]; //new method
    }
    [self cancel:self];
}

-(IBAction)dateSelected:(id)sender
{
    
    if(editingFromTo == EDIT_DATE_FROM_IDX)
    {
        self.fromDate = [datePicker date];
        if((editingMode == EDIT_DATE_RANGE || editingMode == EDIT_TIME_RANGE || editingMode == EDIT_DATE_TIME_RANGE) &&
           [fromDate compare:toDate] == NSOrderedDescending)
        {//if the from date is later than the todate
            //make them the same
            if(editingMode == EDIT_TIME_RANGE || editingMode == EDIT_DATE_TIME_RANGE)
                self.toDate = [fromDate dateByAddingTimeInterval:3600];//add one hour for the time setting
            else
            {
                self.toDate = fromDate;
                self.preferDate = fromDate;
            }
        }
        if (editingMode == EDIT_DATE_RANGE && [fromDate compare:preferDate] == NSOrderedDescending)
            self.preferDate = fromDate;
    }
    else if(editingFromTo == EDIT_DATE_TO_IDX)
    {
        self.toDate = [datePicker date];
        if((editingMode == EDIT_DATE_RANGE || editingMode == EDIT_TIME_RANGE || editingMode == EDIT_DATE_TIME_RANGE) &&
           [toDate compare:fromDate] == NSOrderedAscending)
        {//if the to date is earlier than the fromdate
            //make them the same
            if(editingMode == EDIT_TIME_RANGE || editingMode == EDIT_DATE_TIME_RANGE)
                self.fromDate = [toDate dateByAddingTimeInterval:-3600];//subtract one hour for the time setting
            else
            {
                self.fromDate = toDate;
                self.preferDate = toDate;
            }
        }
        if (editingMode == EDIT_DATE_RANGE && [toDate compare:preferDate] == NSOrderedAscending)
            self.preferDate = toDate;
    }
    else if (editingFromTo == EDIT_DATE_PREFER_IDX)
    {
        self.preferDate = [datePicker date];
        if(editingMode == EDIT_DATE_RANGE)
        {
            //from <= prefer <= to (prefer should fall in middle)
            if ([toDate compare:preferDate] == NSOrderedAscending)
                self.toDate = preferDate;
            if ([fromDate compare:preferDate] == NSOrderedDescending)
                self.fromDate = preferDate;
        }
    }
    
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:editingFromTo inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}

-(void)updateDatePicker
{
    
    if(editingFromTo == EDIT_DATE_FROM_IDX)
        [datePicker setDate:fromDate animated:YES];
    else if (editingFromTo == EDIT_DATE_TO_IDX)
        [datePicker setDate:toDate animated:YES];
    else if (editingFromTo == EDIT_DATE_PREFER_IDX)
        [datePicker setDate:preferDate animated:YES];
    
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */

/*
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

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
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(editingMode == EDIT_DATE_RANGE)
        return 3;
    else if (editingMode == EDIT_TIME_RANGE ||
             editingMode == EDIT_DATE_TIME_RANGE)
        return 2;
    else
        return 1;
}

-(CGFloat) tableView: (UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *EditDateCellID = @"EditDateCellID";
    
    EditDateCell *cell = nil;
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //11-19-2009 12:51 PM
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"h:mm a"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if(editingMode == EDIT_DATE_RANGE || 
       editingMode == EDIT_DATE_SINGLE)
        [formatter setDateFormat:@"MM/dd/yyyy"];
    else if(editingMode == EDIT_DATE_TIME_RANGE ||
            editingMode == EDIT_DATE_TIME_SINGLE)
        [formatter setDateFormat:@"MM/dd/yyyy h:mm a"];
    else
        [formatter setDateFormat:@"h:mm a"];
    
    cell = (EditDateCell *)[self.tableView dequeueReusableCellWithIdentifier:EditDateCellID];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EditDateCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    if([indexPath row] == EDIT_DATE_FROM_IDX)//from
    {
        if(editingMode == EDIT_DATE_RANGE ||
           editingMode == EDIT_DATE_TIME_RANGE)
            cell.labelHeader.text = @"From";
        else if (editingMode == EDIT_TIME_SINGLE)
        {//time
            cell.labelHeader.text = @"Time";
        }
        else//single date
            cell.labelHeader.text = @"Date";
        
        cell.labelDate.text = [formatter stringFromDate:fromDate];
    }
    else if ([indexPath row] == EDIT_DATE_TO_IDX)//to
    {
        //single date
        cell.labelHeader.text = @"To";
        cell.labelDate.text = [formatter stringFromDate:toDate];
    }
    else//prefer
    {
        //single date
        cell.labelHeader.text = @"Prefer";
        cell.labelDate.text = [formatter stringFromDate:preferDate];
    }
    
    
    return (UITableViewCell*)cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    editingFromTo = [indexPath row];
    [self updateDatePicker];
    //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}


@end
