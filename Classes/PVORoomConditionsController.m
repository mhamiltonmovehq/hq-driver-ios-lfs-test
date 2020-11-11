//
//  PVORoomConditionsController.m
//  Survey
//
//  Created by Tony Brame on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "PVORoomConditionsController.h"
#import "SurveyAppDelegate.h"
#import "SwitchCell.h"
#import "NoteCell.h"

@implementation PVORoomConditionsController

@synthesize room, currentLoad, conditions, tboxCurrent, currentUnload;

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
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
    
    self.title = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self 
                                                                                            action:@selector(done:)];
    
    rows = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    floorTypes = [AppFunctionality requiresPropertyCondition] ? [del.surveyDB getPVOPropertyTypes] : [del.surveyDB getPVORoomFloorTypes];

    if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
        self.title = @"Location Conditions";
    else
        self.title = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";
    
    [super viewWillAppear:animated];
    
    if(!editing)
    {
        if (currentLoad != nil)
            self.conditions = [del.surveyDB getPVORoomConditions:currentLoad.pvoLoadID andRoomID:room.roomID];
        else
            self.conditions = [del.surveyDB getPVODestinationRoomConditions:currentUnload.pvoLoadID andRoomID:room.roomID];
    }
    
    editing = FALSE;
    
    
    
    [self initializeIncludedRows];
    [self reloadData];
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:self.title];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)initializeIncludedRows
{
    [rows removeAllObjects];
    [rows addObject:[NSNumber numberWithInt:PVO_ROOM_COND_FLOOR_TYPE]];
    [rows addObject:[NSNumber numberWithInt:PVO_ROOM_COND_CAMERA]];
    [rows addObject:[NSNumber numberWithInt:PVO_ROOM_COND_DAMAGE]];
    
    if(conditions.hasDamage)
        [rows addObject:[NSNumber numberWithInt:PVO_ROOM_COND_DAMAGE_DETAIL]];
}

-(void)floorTypeSelected:(NSNumber*)newID
{
    conditions.floorTypeID = [newID intValue];
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    conditions.hasDamage = sw.on;
    
    conditions.damageDetail = self.tboxCurrent.text; // defect 11805
    
    [self initializeIncludedRows];
    [self reloadData];
}

-(IBAction)done:(id)sender
{
    if(tboxCurrent != nil)
    {
        conditions.damageDetail = tboxCurrent.text;
        self.tboxCurrent = nil;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.currentLoad != nil)
        [del.surveyDB savePVORoomConditions:conditions];
    else
        [del.surveyDB savePVODestinationRoomConditions:conditions];
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

/*
 *  Saves current text to damageDetail and resigns first responder (releases keyboard)
 *  Added 3/17/16 BB
 */
-(void)commitAndClearFields
{
    if (tboxCurrent != nil) {
        conditions.damageDetail = tboxCurrent.text;
        [tboxCurrent resignFirstResponder];
        self.tboxCurrent = nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [rows count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    if(row == PVO_ROOM_COND_DAMAGE_DETAIL)
        return 130;
    else
        return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *NoteCellID = @"NoteCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
	
	NoteCell *noteCell = nil;
    SwitchCell *swCell = nil;
	UITableViewCell *cell = nil;
	
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
	if(row == PVO_ROOM_COND_FLOOR_TYPE || 
       row == PVO_ROOM_COND_CAMERA)
	{
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.imageView.layer.cornerRadius = 5.0;
            cell.imageView.layer.masksToBounds = YES;
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = nil;
        
        if(row == PVO_ROOM_COND_FLOOR_TYPE)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            NSString *floorType = [floorTypes objectForKey:[NSNumber numberWithInt:conditions.floorTypeID]];
            if(floorType == nil){
                cell.textLabel.text = [AppFunctionality requiresPropertyCondition] ? @" - Select Property Type - " : @" - Select Floor Type - ";
            }else{
                NSString *t = [AppFunctionality requiresPropertyCondition] ? @"Property: " : @"Floor: ";
                cell.textLabel.text = [NSString stringWithFormat:@"%@%@", t, floorType];
            }
        }
        else if(row == PVO_ROOM_COND_CAMERA)
        {
            
            int imgType = currentUnload == nil ? IMG_PVO_ROOMS : IMG_PVO_DESTINATION_ROOMS;
            UIImage *myimage = conditions.roomConditionsID != 0 ? [SurveyImageViewer getDefaultImage:imgType forItem:conditions.roomConditionsID] : nil;
            if(myimage == nil)
                myimage = [UIImage imageNamed:@"img_photo.png"];
            cell.imageView.image = myimage;
            if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
                cell.textLabel.text = @"Manage Location Photos";
            else
                cell.textLabel.text = @"Manage Room Photos";
        }
    }
	else if(row == PVO_ROOM_COND_DAMAGE)
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
        
        swCell.labelHeader.text = @"Has Damage";
        swCell.switchOption.on = conditions.hasDamage;
        
	}
	else if(row == PVO_ROOM_COND_DAMAGE_DETAIL)
	{
		
		noteCell = (NoteCell *)[tableView dequeueReusableCellWithIdentifier:NoteCellID];
		if (noteCell == nil) {
            
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
			noteCell = [nib objectAtIndex:0];
			
			noteCell.tboxNote.returnKeyType = UIReturnKeyDefault;
            
            noteCell.tboxNote.delegate = self;
			
		}
		
		noteCell.tboxNote.text = conditions.damageDetail;
		//[noteCell.tboxNote becomeFirstResponder];
		
		self.tboxCurrent = noteCell.tboxNote;
        
	}
    
	
    return cell != nil ? cell : noteCell != nil ? (UITableViewCell*)noteCell : (UITableViewCell*)swCell;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self commitAndClearFields];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = [[rows objectAtIndex:indexPath.row] intValue];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	if(row == PVO_ROOM_COND_FLOOR_TYPE)
    {
        editing = YES;
        
        [del pushPickerViewController:[AppFunctionality requiresPropertyCondition] ? @"Property Type" : @"Floor Type"
                          withObjects:floorTypes 
                 withCurrentSelection:[NSNumber numberWithInt:conditions.floorTypeID] 
                           withCaller:self 
                          andCallback:@selector(floorTypeSelected:) 
                     andNavController:self.navigationController];
        
    }
    else if(row == PVO_ROOM_COND_CAMERA)
    {
        //editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if(imageViewer == nil)
            imageViewer = [[SurveyImageViewer alloc] init];
        
        if (currentLoad != nil)
            conditions.roomConditionsID = [del.surveyDB savePVORoomConditions:conditions];
        else
            conditions.roomConditionsID = [del.surveyDB savePVODestinationRoomConditions:conditions];
        
        if (currentUnload == nil)
            imageViewer.photosType = IMG_PVO_ROOMS;
        else
            imageViewer.photosType = IMG_PVO_DESTINATION_ROOMS;
        
        imageViewer.customerID = del.customerID;
        imageViewer.subID = conditions.roomConditionsID;
        imageViewer.caller = self.view;
        imageViewer.viewController = self;
        imageViewer.dismissDelegate = self;
        imageViewer.dismissCallback = @selector(reloadData);
        [imageViewer loadPhotos];
    }
}

#pragma mark UITextViewDelegate methods

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.tboxCurrent = textView;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    conditions.damageDetail = textView.text;
    
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB saveRoomAlias:[alertView textFieldAtIndex:0].text withCustomerID:del.customerID andRoomID:room.roomID];
        //[self buildTitleView];
    }
}

@end
