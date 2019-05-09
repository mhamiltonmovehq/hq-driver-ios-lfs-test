//
//  PVOEditClaimController.m
//  Survey
//
//  Created by Tony Brame on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOEditClaimController.h"
#import "SurveyAppDelegate.h"
#import "SwitchCell.h"
#import "LabelTextCell.h"

@implementation PVOEditClaimController

@synthesize tboxCurrent;
@synthesize claim, itemsController;
@synthesize includedRows;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.includedRows = [NSMutableArray array];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                               style:UIBarButtonItemStylePlain 
                                                                              target:self 
                                                                              action:@selector(cmdNext_Click:)];
    
    self.title = @"Edit Claim";
}

-(IBAction)cmdNext_Click:(id)sender
{
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    claim.pvoClaimID = [del.surveyDB savePVOClaim:claim];
    
    if(itemsController == nil)
        itemsController = [[PVOClaimItemsController alloc] initWithNibName:@"PVOClaimItemsView" bundle:nil];
    itemsController.claim = claim;
    [self.navigationController pushViewController:itemsController animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self initializeIncludedRows];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

-(void)initializeIncludedRows
{
    [includedRows removeAllObjects];
    
    [includedRows addObject:[NSNumber numberWithInt:PVO_CLAIM_EMPLOYER_PAID]];
    
    if(claim.employerPaid)
        [includedRows addObject:[NSNumber numberWithInt:PVO_CLAIM_EMPLOYER]];
    
    [includedRows addObject:[NSNumber numberWithInt:PVO_CLAIM_IN_WAREHOUSE]];
    
    if(claim.shipmentInWarehouse)
        [includedRows addObject:[NSNumber numberWithInt:PVO_CLAIM_AGENCY_CODE]];
        
}

-(void)updateValueWithField:(UITextField*)tbox
{
    if(tbox.tag == PVO_CLAIM_EMPLOYER)
        claim.employer = tbox.text;
    else if(tbox.tag == PVO_CLAIM_AGENCY_CODE)
        claim.agencyCode = tbox.text;
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == PVO_CLAIM_IN_WAREHOUSE)
        claim.shipmentInWarehouse = sw.on;
    else if(sw.tag == PVO_CLAIM_EMPLOYER_PAID)
        claim.employerPaid = sw.on;
    
    [self initializeIncludedRows];
    [self.tableView reloadData];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [includedRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *TextCellIdentifier = @"LabelTextCell";
    
    SwitchCell *swCell = nil;
    LabelTextCell *ltCell = nil;
    
    int row = [[includedRows objectAtIndex:indexPath.row] intValue];
    
    if(row == PVO_CLAIM_EMPLOYER_PAID || 
       row == PVO_CLAIM_IN_WAREHOUSE)
    {
		swCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
		
		if (swCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
			swCell = [nib objectAtIndex:0];
			
			[swCell.switchOption addTarget:self
									action:@selector(switchChanged:) 
						  forControlEvents:UIControlEventValueChanged];
		}
        swCell.switchOption.tag = row;
        
        if(row == PVO_CLAIM_IN_WAREHOUSE)
        {
            swCell.switchOption.on = claim.shipmentInWarehouse;
            swCell.labelHeader.text = @"In Warehouse";
        }
        else if(row == PVO_CLAIM_EMPLOYER_PAID)
        {
            swCell.switchOption.on = claim.employerPaid;
            swCell.labelHeader.text = @"Employer Paid";
        }
        
    }
    else
    {
        
		ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
		if (ltCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
			ltCell = [nib objectAtIndex:0];
			[ltCell.tboxValue addTarget:self 
								 action:@selector(textFieldDoneEditing:) 
					   forControlEvents:UIControlEventEditingDidEndOnExit];
			ltCell.tboxValue.delegate = self;
            ltCell.tboxValue.returnKeyType = UIReturnKeyDone;
            ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            ltCell.tboxValue.font = [UIFont systemFontOfSize:17.];
            [ltCell setPVOView];
		}
        
        ltCell.tboxValue.tag = row;
        
        if(row == PVO_CLAIM_EMPLOYER)
        {
            ltCell.labelHeader.text = @"Employer";
            ltCell.tboxValue.text = claim.employer;
        }
        else if(row == PVO_CLAIM_AGENCY_CODE)
        {
            ltCell.labelHeader.text = @"Agency Code";
            ltCell.tboxValue.text = claim.agencyCode;
        }
    }
    
    return swCell != nil ? swCell : ltCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
}

@end
