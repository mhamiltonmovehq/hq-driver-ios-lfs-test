//
//  NewItemController.m
//  Survey
//
//  Created by Tony Brame on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NewItemController.h"
#import "TextCell.h"
#import "SwitchCell.h"
#import "SurveyAppDelegate.h"

@implementation NewItemController

@synthesize tboxCurrent, item, addRoom, room, callback, caller, portraitNavController, popover, pvoLocationID;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.preferredContentSize = CGSizeMake(320, (4 * 44) + 20);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];

}

- (void)viewWillAppear:(BOOL)animated {
    
    self.title = @"New Item";
    
    [self.tableView reloadData];
    [super viewWillAppear:animated];
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
*/

/*
*/
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

-(void) cancel:(id)sender
{
    if(popover != nil)
    {
        [popover dismissPopoverAnimated:YES];
        [popover.delegate popoverControllerDidDismissPopover:popover];
    }
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) save:(id)sender
{
    if(tboxCurrent != nil)
        [self updateItemValueWithField:tboxCurrent];
    
    if (item.name == nil || [[item.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
    {
        [SurveyAppDelegate showAlert:@"New Item Name must not be blank." withTitle:@"Error"];
        return;
    }
    
    //update database here... add item.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int languageCode = [del.surveyDB getLanguageForCustomer:del.customerID];
    int itemListId = [del.surveyDB getCustomerItemListID:del.customerID];
    
    item.itemID = [del.surveyDB insertNewItem:item
                                   withRoomID:room == nil ? -1 : room.roomID
                               withCustomerID:(isSingleUse ? del.customerID : -1)
                      includeCubeInValidation:YES
                            withPVOLocationID:(pvoLocationID < 0 ? 0 : pvoLocationID)
                             withLanguageCode:languageCode
                               withItemListId:itemListId
            checkForAdditionalCustomItemLists:NO];
    
    if([caller respondsToSelector:callback])
    {
        [caller performSelector:callback withObject:item];
    }
    
    [self cancel:self];
}

-(void) roomSelected:(Room*)newRoom
{
    self.room = newRoom;
    
    [self.tableView reloadData];
}

-(void)updateItemValueWithField:(UITextField*)textField
{
    switch(textField.tag)
    {
        case NEW_ITEM_NAME:
            item.name = textField.text;
            break;
        case NEW_ITEM_CUBE:
            item.cube = [textField.text doubleValue];
            break;
    }
}

-(IBAction)isCrateSwitched:(id)sender
{
    UISwitch *sw = sender;
    item.isCrate = sw.on;
}

-(IBAction)isSingleUseSwitched:(id)sender
{
    UISwitch *sw = sender;
    isSingleUse = sw.on;
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



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return NEW_ITEM_NUM_ROWS;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
    TextCell *textCell = nil;
    SwitchCell *switchCell = nil;
    UITableViewCell *cell = nil;
    
    if([indexPath row] == NEW_ITEM_NAME || 
        [indexPath row] == NEW_ITEM_CUBE)
    {
        textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        if (textCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            textCell.tboxValue.delegate = self;
        }
        
        if([indexPath row] == NEW_ITEM_NAME)
        {
            textCell.tboxValue.placeholder = @"Item Name";
            textCell.tboxValue.text = item.name;
            textCell.tboxValue.tag = NEW_ITEM_NAME;
        }
        else
        {
            textCell.tboxValue.placeholder = @"Item Cube";
            textCell.tboxValue.text = [[NSNumber numberWithDouble:item.cube] stringValue];            
            textCell.tboxValue.tag = NEW_ITEM_CUBE;
        }
        
        
    }
    else if([indexPath row] == NEW_ITEM_IS_CRATE)
    {
        switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (switchCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            switchCell = [nib objectAtIndex:0];
            
            [switchCell.switchOption addTarget:self
             action:@selector(isCrateSwitched:) 
             forControlEvents:UIControlEventValueChanged];
        }
        
        switchCell.labelHeader.text = @"Is Crate";
        switchCell.switchOption.on = item.isCrate;
        
    }
    else if ([indexPath row] == NEW_ITEM_IS_SINGLE_USE)
    {
        switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (switchCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            switchCell = [nib objectAtIndex:0];
            
            [switchCell.switchOption addTarget:self
                                        action:@selector(isSingleUseSwitched:)
                              forControlEvents:UIControlEventValueChanged];
        }
        
        switchCell.labelHeader.text = @"Is Single Use";
        switchCell.switchOption.on = isSingleUse;
    }
    else
    {//room - to take them to a picker
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if(room     != nil)
            cell.textLabel.text = [NSString stringWithFormat:@"Room: %@", room.roomName];
        else
            cell.textLabel.text = @"Room: None Selected";
        
    }
    
    
    return cell != nil ? cell :
        textCell != nil ? (UITableViewCell*)textCell : 
        (UITableViewCell*)switchCell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == NEW_ITEM_ROOM)
        return indexPath;
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == NEW_ITEM_ROOM)
    {//put the add room ctllr out there
        if(addRoom == nil)
        {
            addRoom = [[AddRoomController alloc] initWithStyle:UITableViewStylePlain];
            addRoom.caller = self;
            addRoom.callback = @selector(roomSelected:);
        }
        addRoom.title = @"Select Item Room";
        addRoom.pushed = TRUE;
        
        
        [self.navigationController pushViewController:addRoom animated:YES];
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


#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
    
    //[SurveyAppDelegate scrollTableToTextField:textField withTable:self.tableView atRow:textField.tag];
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateItemValueWithField:textField];
}

@end

