//
//  NewRoomController.m
//  Survey
//
//  Created by mmqa3 on 10/19/15.
//
//


#import "NewRoomController.h"
#import "NewItemController.h"
#import "TextCell.h"
#import "SwitchCell.h"
#import "SurveyAppDelegate.h"



@implementation NewRoomController



@synthesize room, tboxCurrent, popover, caller, callback, portraitNavController, pvoLocationID;



- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.preferredContentSize = CGSizeMake(320, (4 * 44) + 20);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.title = @"New Room";
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
}

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
    
    if (room.roomName == nil || [[room.roomName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
    {
        [SurveyAppDelegate showAlert:@"New Room Name must not be blank." withTitle:@"Error"];
        return;
    }    
    
    //update database here... add item.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    Room *r = [del.surveyDB insertNewRoom:room.roomName withCustomerID:(isSingleUse ? del.customerID : -1) withPVOLocationID:(pvoLocationID < 0 ? 0 : pvoLocationID)];
    
    
    if([caller respondsToSelector:callback])
    {
        [caller performSelector:callback withObject:r];
    }
    
    [self cancel:self];
}



-(void)updateItemValueWithField:(UITextField*)textField
{
    switch(textField.tag)
    {
        case NEW_ROOM_NAME:
            room.roomName = textField.text;
            break;
    }    
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
    return NEW_ROOM_NUM_ROWS;
}



// Customize the appearance of table view cells.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
    TextCell *textCell = nil;
    SwitchCell *switchCell = nil;

    if([indexPath row] == NEW_ROOM_NAME)
    {
        textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
        
        if (textCell == nil) {
            
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            textCell.tboxValue.delegate = self;
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            
        }
        
        textCell.tboxValue.placeholder = @"Room Name";
        textCell.tboxValue.text = room.roomName;
        textCell.tboxValue.tag = NEW_ROOM_NAME;
        
    }
    else if([indexPath row] == NEW_ROOM_IS_SINGLE_USE)
    {
        switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        
        if (switchCell == nil) {
            
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            switchCell = [nib objectAtIndex:0];
            
        }
        
        [switchCell.switchOption addTarget:self
                                    action:@selector(isSingleUseSwitched:)
                          forControlEvents:UIControlEventValueChanged];
        
        switchCell.labelHeader.text = @"Is Single Use";
        switchCell.switchOption.on = isSingleUse;
        
    }
    
    
    return textCell != nil ? (UITableViewCell*)textCell :
    
    (UITableViewCell*)switchCell;
    
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == NEW_ITEM_ROOM)
        return indexPath;    
    else
        return nil;
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateItemValueWithField:textField];
}


@end
