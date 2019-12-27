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
    
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = @"Checklist";
    
    //[self.tableSummary reloadData];
    
    [super viewWillAppear:animated];
    
    //[self.tableChecklist reloadData];
    
    SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
    customer = [del.surveyDB getCustomer:del.customerID];
    DriverData *data = [del.surveyDB getDriverData];
    int listID = [del.surveyDB getOpListIDForBusinessLine:customer.pricingMode withAgent:data.haulingAgent];
    _sections = [del.surveyDB getOpListSections:listID];
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
}


-(BOOL)verifyFieldsAreComplete
{
    for (NSMutableArray* section in checklist) {
        for (int i = 0; i < [section count]; i++)
        {
            OLCombinedQuestionAnswer *item = section[i];
        
            if(item.answer.yesNoResponse == NO)
            {
                [SurveyAppDelegate showAlert:@"All Items must be checked before continuing." withTitle:@"Items must be checked"];
                return FALSE;
            }
        
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
    
    for (NSMutableArray* section in checklist) {
        for (OLCombinedQuestionAnswer *item in section)
        {
            [del.surveyDB saveOpListItem:item.answer];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [checklist count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [checklist[section] count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OLCombinedQuestionAnswer *item = checklist[indexPath.section][indexPath.row];
    return [AutoSizeLabelCell sizeOfCellForText:item.question.question];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ((OLSection*)_sections[section]).sectionName;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *AutoSizeCellIdentifier = @"AutoSizeLabelCell";
    
    AutoSizeLabelCell *sizeCell = nil;
    
    sizeCell = (AutoSizeLabelCell*)[tableView dequeueReusableCellWithIdentifier:AutoSizeCellIdentifier];
    
    if (sizeCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AutoSizeLabelCell" owner:self options:nil];
        sizeCell = [nib objectAtIndex:0];
    }
    sizeCell.accessoryType = UITableViewCellAccessoryNone;
    
    OLCombinedQuestionAnswer *item = checklist[indexPath.section][indexPath.row];
    sizeCell.text = item.question.question;
    
    if(item.answer.yesNoResponse == YES)
        sizeCell.accessoryType = UITableViewCellAccessoryCheckmark;

    return sizeCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    OLCombinedQuestionAnswer *item = checklist[indexPath.section][indexPath.row];
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
    
}

@end
