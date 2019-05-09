//
//  SelectNewAgencyController.m
//  Survey
//
//  Created by Tony Brame on 7/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SelectNewAgencyController.h"
#import "SurveyAgent.h"
#import "SurveyAppDelegate.h"
#import "ButtonCell.h"

@implementation SelectNewAgencyController

@synthesize picker, sortByControl, tableView, states, agencies, currentState, caller, callback, currentAgency;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    self.preferredContentSize = CGSizeMake(320, 416);
    [super viewDidLoad];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
//test
- (void)viewWillAppear:(BOOL)animated
{
    int agentIndex = -1;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(states == nil)
        self.states = [del.pricingDB getAgencyStates];
    
    [states    sortUsingSelector:@selector(compare:)];
     
    if(currentState == nil)
    {
        [picker selectRow:0 inComponent:STATE_SECTION animated:NO];
        self.currentState = [states objectAtIndex:0];
    }
    else
    {
        NSInteger* stateIndex = [states indexOfObject:self.currentState];
        [self.picker selectRow:stateIndex inComponent:STATE_SECTION animated:NO];
    }
    self.agencies = [del.pricingDB getAgentsList:currentState sortByCode:sortByControl.selectedSegmentIndex == SORT_CODE];
    if([agencies count] <= 0)
    {
        [picker selectRow:0 inComponent:STATE_SECTION animated:NO];
        self.currentState = [states objectAtIndex:0];
        self.agencies = [del.pricingDB getAgentsList:currentState sortByCode:sortByControl.selectedSegmentIndex == SORT_CODE];
    }
    else if (self.currentAgency != nil && self.currentAgency.length > 0)
    {
        for (int i = 0; i < self.agencies.count; ++i)
        {
            SurveyAgent* surveyAgent = [agencies objectAtIndex:i];
            
            if ([surveyAgent.name isEqualToString:self.currentAgency])
            {
                agentIndex = i;
                break;
            }
        }
    }
    
    [self.picker reloadComponent:STATE_SECTION];
    [self.picker reloadComponent:NAME_SECTION];
    
    [super viewWillAppear:animated];
    
    if (agentIndex >= 0)
        [self.picker selectRow:agentIndex inComponent:NAME_SECTION animated:NO];
}

-(IBAction)switchSort:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.agencies = [del.pricingDB getAgentsList:currentState sortByCode:sortByControl.selectedSegmentIndex == SORT_CODE];
    [picker reloadComponent:NAME_SECTION];
}

-(void)selectAgency:(id)sender
{
    if([caller respondsToSelector:callback])
    {
        [caller performSelector:callback withObject:[agencies objectAtIndex:[picker selectedRowInComponent:NAME_SECTION]]];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    //SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[del.navController popViewControllerAnimated:YES];
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




#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == STATE_SECTION)
        return [self.states count];
    
    return [self.agencies count];
}

#pragma mark Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == STATE_SECTION)
        return [self.states objectAtIndex:row];
    
    SurveyAgent *agent;
    agent = [agencies objectAtIndex:row];
    
    return [NSString stringWithFormat:@"%@ - %@", agent.code, agent.name];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (component == STATE_SECTION)
    {
        NSString *selectedState = [self.states objectAtIndex:row];
        
        self.currentState = selectedState;
        
        self.agencies = [del.pricingDB getAgentsList:currentState sortByCode:sortByControl.selectedSegmentIndex == SORT_CODE];
        
        [picker selectRow:0 inComponent:NAME_SECTION animated:YES];
        [picker reloadComponent:NAME_SECTION];
    }
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == STATE_SECTION)
        return 50;
    
    return 245;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)thisTableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)thisTableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)thisTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [thisTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Set up the cell...
    cell.textLabel.text = @"Use Selected Agency";
    
    return cell;
}


- (void)tableView:(UITableView *)thisTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectAgency:thisTableView];
    
    [thisTableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
