//
//  NoteViewController.m
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PVODamageController.h"
#import	"TextCell.h"
#import	"SurveyAppDelegate.h"
#import "NoteCell.h"
#import "SwitchCell.h"

@implementation PVODamageController

@synthesize tboxCurrent, description;

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
        
    }
    return self;
}

- (void)viewDidLoad {
	
	self.clearsSelectionOnViewWillAppear = YES;
	self.preferredContentSize = CGSizeMake(320, 416);	
	
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    
	if(tboxCurrent != nil)
		self.description = tboxCurrent.text;
    
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

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    hasDamage = sw.on;
    
    if(tboxCurrent != nil)
        self.description = tboxCurrent.text;
    
    [self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return hasDamage ? 2 : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 0)
		return 44;
	else
		return 130;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *NoteCellID = @"NoteCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
	
	NoteCell *noteCell = nil;
    SwitchCell *swCell = nil;
	UITableViewCell *cell = nil;
	
	if([indexPath row] == 0)
	{
        //switch cell
        swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (swCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            swCell = [nib objectAtIndex:0];
            
			[swCell.switchOption addTarget:self
									action:@selector(switchChanged:) 
						  forControlEvents:UIControlEventValueChanged];
        }
        
        swCell.labelHeader.text = @"Has Property Damage";
        swCell.switchOption.on = hasDamage;
        
	}
	else
	{
		
		noteCell = (NoteCell *)[tableView dequeueReusableCellWithIdentifier:NoteCellID];
		if (noteCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
			noteCell = [nib objectAtIndex:0];
			
			noteCell.tboxNote.returnKeyType = UIReturnKeyDefault;
			
		}
		
		noteCell.tboxNote.text = description;
		[noteCell.tboxNote becomeFirstResponder];
		
		self.tboxCurrent = noteCell.tboxNote;
	}
	
    return cell != nil ? cell : noteCell != nil ? (UITableViewCell*)noteCell : (UITableViewCell*)swCell;
}
	
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end

