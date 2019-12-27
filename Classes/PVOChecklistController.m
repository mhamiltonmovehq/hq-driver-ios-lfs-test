//
//  ChecklistController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVOChecklistController.h"
#import "AutoSizeLabelCell.h"
//#import "OrderDetailController.h"
#import "SurveyAppDelegate.h"
#import "CustomerUtilities.h"
#import "SurveyCustomer.h"
#import "OLCombinedQuestionAnswer.h"

@interface PVOChecklistController ()

@end

@implementation PVOChecklistController

//@synthesize order, process;
@synthesize checklist;
//@synthesize tableChecklist;
//@synthesize tableSummary;
@synthesize vehicle;
@synthesize isOrigin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.contentSizeForViewInPopover = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(cmdNextClick:)];
    
    // Init our Customer object so we don't on every viewWillAppear, for pulling OpListID
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    customer = [del.surveyDB getCustomer:del.customerID];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = @"Checklist";
    
    //[self.tableSummary reloadData];
    
    [super viewWillAppear:animated];
    
    //[self.tableChecklist reloadData];
    
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    //self.checklist = [del.surveyDB getCheckListItems:del.customerID withVehicleID:vehicle.vehicleID withAgencyCode:data.haulingAgent];
    int listID = [del.surveyDB getOpListIDForBusinessLine:customer.pricingMode withAgent:data.haulingAgent];
    self.checklist = [del.surveyDB getOpListQuestionsAndAnswersWithListID:listID withCustomerID:del.customerID withVehicleID:vehicle.vehicleID];
    
    
    if ([self.checklist count] <= 0 && [self isMovingToParentViewController])
    {
        [self cmdNextClick:self];
        return;
    }
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    //disabled, user will need to check mark every item whenever the enter an item JL
    //    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    //    [del.surveyDB saveVehicleCheckList:checklist];
    [self saveOpListResponses];
    
    [super viewWillDisappear:animated];
}

//- (void)viewDidUnload
//{
//    [self setTableChecklist:nil];
//    [self setTableSummary:nil];
//    [super viewDidUnload];
//    // Release any retained subviews of the main view.
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc
{
}

- (IBAction)cmdNextClick:(id)sender
{
    if(![self verifyFieldsAreComplete])
        return;
    
    [self.navigationController popViewControllerAnimated:YES];
    //[self.navigationController pushViewController:wireframe animated:YES];
}


-(BOOL)verifyFieldsAreComplete
{
    for (int i = 0; i < [checklist count]; i++)
    {
        OLCombinedQuestionAnswer *item = checklist[i];
        
        if(item.answer.yesNoResponse == NO)
        {
            [SurveyAppDelegate showAlert:@"All Items must be checked before continuing." withTitle:@"Items must be checked"];
            return FALSE;
        }
        
    }
    
    return TRUE;
}

- (IBAction)cmdPreviousClick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) saveOpListResponses
{
    // Save applied OpListItems
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    for (OLCombinedQuestionAnswer *item in checklist)
    {
        [del.surveyDB saveOpListItem:item.answer];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //    if(tableView == tableSummary)
    //        return 2;
    //    else
    //        return [checklist count];
    
    return [checklist count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    if(tableView == tableSummary)
    //        return 30;
    //    else
    //    {
    OLCombinedQuestionAnswer *item = checklist[indexPath.row];
    return [AutoSizeLabelCell sizeOfCellForText:item.question.question];
    //    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Pre-Ship Checklist";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    static NSString *CellIdentifier = @"Cell";
    static NSString *AutoSizeCellIdentifier = @"AutoSizeLabelCell";
    
    //    UITableViewCell *cell = nil;
    AutoSizeLabelCell *sizeCell = nil;
    
    //    if(tableView == self.tableSummary)
    //    {
    //        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //        if (cell == nil) {
    //            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    //            cell.accessoryType = UITableViewCellAccessoryNone;
    //            cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
    //            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    //        }
    //
    //        if(indexPath.row == 0)
    //        {
    //            SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    //            SurveyCustomer *customer = [del.surveyDB getCustomer:del.customerID];
    //
    //            cell.textLabel.text = @"Owner";
    //            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", customer.lastName, customer.firstName];
    //        }
    //        else
    //        {
    //            cell.textLabel.text = @"Service Status";
    //            cell.detailTextLabel.text = @"Service Type Description Goes Here?"; //[order serviceTypeDescrition];
    //        }
    //    }
    //    else
    //    {
    
    sizeCell = (AutoSizeLabelCell*)[tableView dequeueReusableCellWithIdentifier:AutoSizeCellIdentifier];
    
    if (sizeCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AutoSizeLabelCell" owner:self options:nil];
        sizeCell = [nib objectAtIndex:0];
    }
    sizeCell.accessoryType = UITableViewCellAccessoryNone;
    
    OLCombinedQuestionAnswer *item = checklist[indexPath.row];
    sizeCell.text = item.question.question;
    
    if(item.answer.yesNoResponse == YES)
        sizeCell.accessoryType = UITableViewCellAccessoryCheckmark;
    //    }
    
    //    return cell != nil ? cell : sizeCell;
    return sizeCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    
    //    if(tableView != self.tableSummary)
    //    {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    OLCombinedQuestionAnswer *item = checklist[indexPath.row];
    if(item.answer.yesNoResponse == YES)
    {//remove it, clear check
        cell.accessoryType = UITableViewCellAccessoryNone;
        item.answer.yesNoResponse = NO;
    }
    else
    {//add and check
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        item.answer.yesNoResponse = YES;
    }
    
    //    }
    
}

@end
