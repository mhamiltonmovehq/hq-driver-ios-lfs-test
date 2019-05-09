//
//  SurveyAgentsController.m
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyAgentsController.h"
#import "SurveyAgent.h"
#import "AgentSummaryCell.h"
#import "SurveyAppDelegate.h"
#import "EditAgentController.h"
#import "CustomerUtilities.h"

@implementation SurveyAgentsController

@synthesize editAgentController;

-(void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	self.preferredContentSize = CGSizeMake(320, 416);	
	[super viewDidLoad];
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

- (void)viewWillAppear:(BOOL)animated {
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
	
	[super viewWillDisappear:animated];
}

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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(CGFloat) tableView: (UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return 95;//for address summary cells
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"AgentSummaryCell";
    
    AgentSummaryCell *cell = (AgentSummaryCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AgentSummaryCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
    
    // Set up the cell...
	switch ([indexPath section]) {
		case AGENT_BOOKING:
			cell.labelHeader.text = @"Booking";
			break;
		case AGENT_ORIGIN:
			cell.labelHeader.text = @"Origin";
			break;
		case AGENT_DESTINATION:
			cell.labelHeader.text = @"Destination";
			break;
	}
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	SurveyAgent *agent = [del.surveyDB getAgent:del.customerID withAgentID:[indexPath section]];
	
	if([agent.code length] == 0 && 
		[agent.name length] == 0 && 
		[agent.city length] == 0 && 
		[agent.state length] == 0)
	{
		cell.labelName.text = @"";
		cell.labelCode.text = @"no agency selected";
		cell.labelCity.text = @"";
	}
	else
	{
		cell.labelName.text = agent.name;
		cell.labelCode.text = [NSString stringWithFormat:@"Code: %@", agent.code];
		cell.labelCity.text = [NSString stringWithFormat:@"%@, %@", agent.city, agent.state];
	}
	
	
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    
	if(editAgentController == nil)
	{
		editAgentController = [[EditAgentController alloc] initWithStyle:UITableViewStyleGrouped];
	}
	
	switch ([indexPath section]) {
		case AGENT_BOOKING:
			editAgentController.title = @"Booking";
			break;
		case AGENT_ORIGIN:
			editAgentController.title = @"Origin";
			break;
		case AGENT_DESTINATION:
			editAgentController.title = @"Destination";
			break;
	}
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	editAgentController.agent = [del.surveyDB getAgent:del.customerID withAgentID:[indexPath section]];
	
	//[del.navController pushViewController:editAgentController animated:YES];
	[self.navigationController pushViewController:editAgentController animated:YES];
	
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

