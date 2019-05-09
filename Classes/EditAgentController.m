//
//  EditAgentController.m
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditAgentController.h"
#import "TextWithHeaderCell.h"
#import "SingleFieldController.h"
#import "SurveyAppDelegate.h"
#import "SelectNewAgencyController.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"

@implementation EditAgentController

@synthesize agent, currentState, editingPath, editController, editing, selectAgentController;
@synthesize lockFields;

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
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Set As Default" 
															style:UIBarButtonItemStylePlain 
														   target:self 
														   action:@selector(cmd_DefaultPressed:)];
	self.navigationItem.rightBarButtonItem = btn;
		
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {
	
    lockFields = ([AppFunctionality lockFieldsOnSourcedFromServer] && [CustomerUtilities customerSourcedFromServer]);
	
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

-(IBAction)cmd_DefaultPressed:(id)sender
{
	int tempCID = agent.itemID;
	agent.itemID = DEFAULT_AGENCY_CUST_ID;
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[del.surveyDB saveAgent:agent];
	
	agent.itemID = tempCID;
	
	[SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Default %@ Agency Saved", self.title] 
					   withTitle:@"Default"];
}

- (void)viewWillDisappear:(BOOL)animated {
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[del.surveyDB saveAgent:agent];
	
	[super viewWillDisappear:animated];
}


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


-(void) doneEditing:(NSString*)newValue
{
	
	switch([editingPath row])
	{
		case AGENT_CODE_ROW:
			agent.code = newValue;
			break;
		case AGENT_NAME_ROW:
			agent.name = newValue;
			break;
		case AGENT_ADDRESS_ROW:
			agent.address = newValue;
			break;
		case AGENT_CITY_ROW:
			agent.city = newValue;
			break;
		case AGENT_STATE_ROW:
			agent.state = newValue;
			break;
		case AGENT_ZIP_ROW:
			agent.zip = newValue;
			break;
		case AGENT_PHONE_ROW:
			agent.phone = newValue;
			break;
		case AGENT_FAX_ROW:
			agent.fax = newValue;
			break;
		case AGENT_EMAIL_ROW:
			agent.email = newValue;
			break;
		case AGENT_CONTACT_ROW:
			agent.contact = newValue;
			break;
	}
	
}


-(void) newAgentSelected:(SurveyAgent*)newAgent
{
	int custid = agent.itemID;
	int agentid = agent.agencyID;
	self.agent = newAgent;
	agent.itemID = custid;
	agent.agencyID = agentid;
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

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (lockFields ? 1 : 2);
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0 && !lockFields)
		return 1;
	else
		return 10;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TextWithHeaderCell";
    static NSString *RegCellIdentifier = @"BasicCell";
    
	UITableViewCell *regCell = nil;
	TextWithHeaderCell *cell = nil;
	
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *surveyCustomer = [del.surveyDB getCustomer:del.customerID];
    NSString *stateLabel, *zipLabel;
    BOOL isCanadian = [surveyCustomer isCanadianCustomer];
    if (isCanadian)
    {
        stateLabel = @"Prov";
        zipLabel = @"PC";
    }
    else
    {
        stateLabel = @"ST";
        zipLabel = @"ZIP";
    }
	
	if([indexPath section] == STATE_FILTER_SECTION && !lockFields)
	{
		regCell = [tableView dequeueReusableCellWithIdentifier:RegCellIdentifier];
		if(regCell == nil)
		{
			regCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RegCellIdentifier];
			regCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
        
		regCell.textLabel.text = @"Select New Agency";
	}
	else
	{
		cell = (TextWithHeaderCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
			cell = [nib objectAtIndex:0];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
        
        if(lockFields)
            cell.accessoryType = UITableViewCellAccessoryNone;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		switch ([indexPath row]) {
			case AGENT_CODE_ROW:
				cell.labelHeader.text = @"Code";
				cell.labelText.text = agent.code;
				break;
			case AGENT_NAME_ROW:
				cell.labelHeader.text = @"Name";
				cell.labelText.text = agent.name;
				break;
			case AGENT_ADDRESS_ROW:
				cell.labelHeader.text = @"Address";
				cell.labelText.text = agent.address;
				break;
			case AGENT_CITY_ROW:
				cell.labelHeader.text = @"City";
				cell.labelText.text = agent.city;
				break;
			case AGENT_STATE_ROW:
				cell.labelHeader.text = stateLabel;
				cell.labelText.text = agent.state;
				break;
			case AGENT_ZIP_ROW:
				cell.labelHeader.text = zipLabel;
				cell.labelText.text = agent.zip;
				break;
			case AGENT_PHONE_ROW:
				cell.labelHeader.text = @"Phone";
				cell.labelText.text = agent.phone;
				break;
			case AGENT_FAX_ROW:
				cell.labelHeader.text = @"Fax";
				cell.labelText.text = agent.fax;
				break;
			case AGENT_EMAIL_ROW:
				cell.labelHeader.text = @"Email";
				cell.labelText.text = agent.email;
				break;
			case AGENT_CONTACT_ROW:
				cell.labelHeader.text = @"Contact";
				cell.labelText.text = agent.contact;
				break;
		}
	}
    	
    return regCell == nil ? (UITableViewCell*)cell : regCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(lockFields)
        return;
	
	editing = YES;
	
	if([indexPath section] == STATE_FILTER_SECTION && !lockFields)
	{
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (![del.pricingDB hasAgencies])
        {
            [SurveyAppDelegate showAlert:@"No Agencies present to select." withTitle:@"No Agencies"];
        }
        else
        {
            if(selectAgentController == nil)
            {
                selectAgentController = [[SelectNewAgencyController alloc] initWithNibName:@"SelectNewAgencyView" bundle:nil];
                selectAgentController.caller = self;
                selectAgentController.callback = @selector(newAgentSelected:);
            }
            
            selectAgentController.sortByControl.selectedSegmentIndex = SORT_NAME;
            
            if(agent.state != nil && [agent.state length] > 0)
                selectAgentController.currentState = agent.state;
            else
                selectAgentController.currentState = nil;
            
            if (agent.name != nil && [agent.name length] > 0)
                selectAgentController.currentAgency = agent.name;
            else
                selectAgentController.currentAgency = nil;
            
            //[del.navController pushViewController:selectAgentController animated:YES];
            [self.navigationController pushViewController:selectAgentController animated:YES];
        }
	}
	else
	{
		self.editingPath = indexPath;
		if(editController == nil)
		{
			editController = [[SingleFieldController alloc] initWithStyle:UITableViewStyleGrouped];
			editController.caller = self;
			editController.callback = @selector(doneEditing:);
		}
		
		switch([indexPath row])
		{
			case AGENT_CODE_ROW:
				editController.destString = agent.code;
				break;
			case AGENT_NAME_ROW:
				editController.destString = agent.name;
				break;
			case AGENT_ADDRESS_ROW:
				editController.destString = agent.address;
				break;
			case AGENT_CITY_ROW:
				editController.destString = agent.city;
				break;
			case AGENT_STATE_ROW:
				editController.destString = agent.state;
				break;
			case AGENT_ZIP_ROW:
				editController.destString = agent.zip;
				break;
			case AGENT_PHONE_ROW:
				editController.destString = agent.phone;
				break;
			case AGENT_FAX_ROW:
				editController.destString = agent.fax;
				break;
			case AGENT_EMAIL_ROW:
				editController.destString = agent.email;
				break;
			case AGENT_CONTACT_ROW:
				editController.destString = agent.contact;
				break;
		}
		
		//[del.navController pushViewController:editController animated:YES];
		[self.navigationController pushViewController:editController animated:YES];
		
	}
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

