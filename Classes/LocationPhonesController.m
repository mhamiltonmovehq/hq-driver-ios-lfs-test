//
//  LocationPhonesController.m
//  Survey
//
//  Created by Tony Brame on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LocationPhonesController.h"
#import "SurveyAppDelegate.h"
#import "TextWithHeaderCell.h"
#import "SurveyPhone.h"

@implementation LocationPhonesController

@synthesize phones, locationID, custID, phoneController;


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.preferredContentSize = CGSizeMake(320, 44 * 4);
    
    [super viewDidLoad];
}



- (void)viewWillAppear:(BOOL)animated 
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.phones = [del.surveyDB getCustomerPhones:custID withLocationID:locationID];
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [phones count] + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *TextWithHeaderCellID = @"TextWithHeaderCell";
    
    TextWithHeaderCell *thCell = nil;
    
    thCell = (TextWithHeaderCell *)[tableView dequeueReusableCellWithIdentifier:TextWithHeaderCellID];
    if (thCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
        thCell = [nib objectAtIndex:0];
        thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    CGRect rect = thCell.labelHeader.frame;        
    if([phones count] == 0 || [indexPath row] == [phones count])//this is the add new row...
    {
        rect.size.width = 270;
        thCell.labelHeader.textAlignment = NSTextAlignmentCenter;
        thCell.labelHeader.text = @"Add New Phone";
        thCell.labelText.text = @"";
    }
    else
    {
        rect.size.width = 94;
        thCell.labelHeader.textAlignment = NSTextAlignmentRight;
        SurveyPhone *phone = [phones objectAtIndex:[indexPath row]];
        thCell.labelHeader.text = phone.type.name;
        thCell.labelText.text = phone.number;
    }
    
    thCell.labelHeader.frame = rect;
    
    return thCell;
}



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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(phoneController == nil)
    {
        phoneController = [[EditPhoneController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    SurveyPhone *edit;
    
    if([phones count] == 0 || [indexPath row] == [phones count])
    {
        phoneController.originalPhoneTypeID = -1;
        phoneController.newPhone = YES;
        phoneController.title = @"New Phone";
        edit = [[SurveyPhone alloc] init];
        edit.type = nil;//force select
        edit.custID = custID;
        edit.locationTypeId = locationID;
        edit.number = @"";
        phoneController.phone = edit;
        
    }
    else
    {
        edit = (SurveyPhone *)[phones objectAtIndex:[indexPath row]];
        phoneController.newPhone = NO;
        phoneController.title = edit.type.name;
        phoneController.phone = edit;
        phoneController.originalPhoneTypeID = edit.type.phoneTypeID;
    }
    
    phoneController.preferredContentSize = self.preferredContentSize;
    [self.navigationController pushViewController:phoneController animated:YES];
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return [indexPath row] != [phones count];
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        SurveyPhone *removePhone = [phones objectAtIndex:[indexPath row]];
        [del.surveyDB deletePhone:removePhone];
        [phones removeObjectAtIndex:[indexPath row]];
        
        // Animate the deletion from the table.
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                  withRowAnimation:UITableViewRowAnimationFade];        
        
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}




@end

