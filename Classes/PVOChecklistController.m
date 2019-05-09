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

@interface PVOChecklistController ()

@end

@implementation PVOChecklistController

@synthesize checklist;
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
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(cmdNextClick:)];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = @"Checklist";
    
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    self.checklist = [del.surveyDB getCheckListItems:del.customerID withVehicleID:vehicle.vehicleID withAgencyCode:data.haulingAgent];
        
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
    [super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)cmdNextClick:(id)sender 
{
    if(![self verifyFieldsAreComplete])
        return;
    
    if(wireframe == nil)
        wireframe = [[PVOWireFrameTypeController alloc] initWithStyle:UITableViewStyleGrouped];
    
    wireframe.wireframeItemID = vehicle.vehicleID;
    wireframe.selectedWireframeTypeID = vehicle.wireframeType;
    wireframe.isOrigin = isOrigin;
    wireframe.isAutoInventory = YES; //not sure that we need checklists in here, maybe we'll add it once people have moveHq?
    wireframe.delegate = self;
    
    [SurveyAppDelegate setDefaultBackButton:self];
    [self.navigationController pushViewController:wireframe animated:YES];
}


-(BOOL)verifyFieldsAreComplete
{
    for (int i = 0; i < [checklist count]; i++)
    {
        PVOCheckListItem *item = checklist[i];
        
        if(item != nil && !item.isChecked)
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [checklist count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PVOCheckListItem *item = checklist[indexPath.row];
    return [AutoSizeLabelCell sizeOfCellForText:item.description];

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
    static NSString *AutoSizeCellIdentifier = @"AutoSizeLabelCell";

    AutoSizeLabelCell *sizeCell = nil;
    sizeCell = (AutoSizeLabelCell*)[tableView dequeueReusableCellWithIdentifier:AutoSizeCellIdentifier];
    
    if (sizeCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AutoSizeLabelCell" owner:self options:nil];
        sizeCell = [nib objectAtIndex:0];
    }
    sizeCell.accessoryType = UITableViewCellAccessoryNone;
    
    PVOCheckListItem *item = checklist[indexPath.row];
    sizeCell.text = item.description;
    
    if(item.isChecked)
        sizeCell.accessoryType = UITableViewCellAccessoryCheckmark;

    return sizeCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    PVOCheckListItem *item = checklist[indexPath.row];
    if(item.isChecked)
    {//remove it, clear check
        cell.accessoryType = UITableViewCellAccessoryNone;
        item.isChecked = NO;
    }
    else 
    {//add and check
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        item.isChecked = YES;
    }
}

#pragma mark - PVOWiretypeControllerDelegate methods

-(NSDictionary*)getWireFrameTypes:(id)controller
{
    return [[NSDictionary alloc] initWithObjects:@[@"Car", @"Truck", @"SUV", @"Photo"]
                                         forKeys:@[[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],[NSNumber numberWithInt:3],[NSNumber numberWithInt:4]]];
    
}

-(void)saveWireFrameTypeIDForDelegate:(int)selectedWireframeType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    vehicle.wireframeType = selectedWireframeType;
    [del.surveyDB saveVehicle:vehicle];
    
}

@end
