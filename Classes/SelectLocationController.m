//
//  SelectLocationController.m
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyAppDelegate.h"
#import "SelectLocationController.h"
#import "AddressSummaryCell.h"
#import "TextWithHeaderCell.h"
#import "SurveyPhone.h"
#import	"SurveyLocation.h"
#import "EditAddressController.h"
#import "EditPhoneController.h"
#import "CustomerUtilities.h"

@implementation SelectLocationController

@synthesize locationID, locations, editAddressController, delegate;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	
	self.preferredContentSize = CGSizeMake(320, 416);
	
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                            action:@selector(cancel:)];
}


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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
	
    
	if(editAddressController != nil && editAddressController.saved && editAddressController.newLocation)
	{
        [self locationSelected:editAddressController.location];
    }
    else
    {
        //load the arrays with customer data
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.locations = [del.surveyDB getCustomerLocations:del.customerID atOrigin:locationID == ORIGIN_LOCATION_ID];
        
        
        [super viewWillAppear:animated];
        
        [self.tableView reloadData];
    }
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)locationSelected:(SurveyLocation*)location
{
    if(delegate != nil && [delegate respondsToSelector:@selector(locationSelected:withLocation:)])
        [delegate locationSelected:self withLocation:location];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(shouldDismiss:)])
    {
        if([delegate shouldDismiss:self])
            [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	
	
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; //[locations count] + 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section == 0)
        return [locations count];
    else
        return 1;
}

-(CGFloat) tableView: (UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if([indexPath section] == 0)
		return 85;
	else
		return 44;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *AddressSummaryCellID = @"AddressSummaryCell";
    static NSString *TextWithHeaderCellID = @"TextWithHeaderCell";
    
	AddressSummaryCell *addCell = nil;
	TextWithHeaderCell *thCell = nil;
    // Set up the cell...
	UITableViewCell *cell = nil;
	CGRect rect;
	
	if([indexPath section] == 0)
	{
        SurveyLocation *loc = [locations objectAtIndex:[indexPath row]];
		
        addCell = (AddressSummaryCell *)[tableView dequeueReusableCellWithIdentifier:AddressSummaryCellID];
        if (addCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddressSummaryCell" owner:self options:nil];
            addCell = [nib objectAtIndex:0];
            addCell.accessoryType = UITableViewCellAccessoryNone;
        }
        addCell.labelName.text = loc.name;
        NSString *address;
        
        if([loc.address1 length] > 0 || [loc.city length] > 0 || [loc.state length]  > 0 || [loc.zip length] > 0)
            address = [[NSString alloc] initWithFormat:@"%@\r\n%@, %@ %@",loc.address1, loc.city, loc.state, loc.zip];
        else
            address = @"no data";
		
        addCell.labelAddress.text = address;
		
    }
	else
	{//add new location        
        thCell = (TextWithHeaderCell *)[tableView dequeueReusableCellWithIdentifier:TextWithHeaderCellID];
        if (thCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
            thCell = [nib objectAtIndex:0];
            thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        thCell.labelHeader.textAlignment = NSTextAlignmentCenter;
        rect = thCell.labelHeader.frame;
        rect.size.width = 270;
        thCell.labelHeader.frame = rect;
        
        
        thCell.labelHeader.text = @"Add New Location";
        thCell.labelText.text = @"";
	}
    
	if(addCell != nil)
		cell = addCell;
	else
		cell = thCell;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    SurveyLocation *newLoc;
	
	if([indexPath section] == 0)
	{
        //select existing...
        SurveyLocation *loc = [locations objectAtIndex:[indexPath row]];
        
        //call back to delegate
        [self locationSelected:loc];
    }
    else
    {
		if(editAddressController == nil)
			editAddressController = [[EditAddressController alloc] initWithStyle:UITableViewStyleGrouped];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        newLoc = [[SurveyLocation alloc] init];
        newLoc.custID = del.customerID;
        newLoc.isOrigin = locationID == ORIGIN_LOCATION_ID;
        editAddressController.location = newLoc;
        editAddressController.newLocation = TRUE;
    
		[self.navigationController pushViewController:editAddressController	animated:YES];
    }
	
}



@end

