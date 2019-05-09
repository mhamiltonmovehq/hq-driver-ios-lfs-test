//
//  SurveySummaryController.m
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveySummaryController.h"
#import "AddRoomController.h"
#import "SurveyAppDelegate.h"
#import "Room.h"
#import "ItemViewController.h"
#import "RoomSummaryCell.h"
#import "RoomSummary.h"

@implementation SurveySummaryController

@synthesize addRoomController, cubesheet, itemView, summaries, pickerWeightFactor, tblView;
@synthesize weightFactors, cmdWeightFactor, imageViewer, addRoomNav, itemDelete, roomDelete;
@synthesize caller, roomChanged, toolbar, popover, surveyFAQ, syncController;

#pragma mark - Utility methods

-(void)loadWeightFactors
{
	self.weightFactors = [[NSMutableArray alloc] init];
	double i = WEIGHT_FACTOR_MIN;
	for(i = WEIGHT_FACTOR_MIN; i <= WEIGHT_FACTOR_MAX; i += WEIGHT_FACTOR_INCREMENT)
	{
		[weightFactors addObject:[[NSNumber numberWithDouble:i] stringValue]];
	}
	
}

-(IBAction) addRoom:(id)sender
{
	if(addRoomController == nil)
	{
		addRoomController = [[AddRoomController alloc] initWithStyle:UITableViewStylePlain];
		addRoomController.caller = self;
		addRoomController.callback = @selector(roomSelected:);
	}
	
	if(addRoomNav == nil)
	{
		PortraitNavController *navCont = [[PortraitNavController alloc] initWithRootViewController:addRoomController];
		self.addRoomNav = navCont;
	}
	
	[self.navigationController presentViewController:addRoomNav animated:YES completion:nil];
}

-(IBAction)roomSelected:(Room*)selection
{
	if(itemView == nil)
		itemView = [[ItemViewController alloc] initWithNibName:@"ItemView" bundle:nil];

	itemView.currentRoom = selection;
	itemView.cubesheet = cubesheet;
	
	[del.navController pushViewController:itemView animated:YES];
	
	//since the animation of the closing of the other form is executing, manually call the viewWillAppear method on this control.
	[itemView viewWillAppear:YES];
}

-(void)setWeightFactor
{
	double wf;
	NSString *weight;
	for(int i = 0; i < [weightFactors count]; i++)
	{
		weight = [weightFactors objectAtIndex:i];
		wf = [weight doubleValue];
		if(wf == cubesheet.weightFactor)
		{
			//set selection
			[pickerWeightFactor selectRow:i inComponent:0 animated:NO];
			break;
		}
	}
	
	cmdWeightFactor.title = [NSString stringWithFormat:@"Weight Factor: %@", weight];
}

-(IBAction) changeWeightFactor:(id)sender
{
	tblView.allowsSelection = FALSE;
	
	[self.view bringSubviewToFront:pickerWeightFactor];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(saveWFChange:)];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						   target:self
																						   action:@selector(cancelWFChange:)];
}

-(IBAction) cancelWFChange:(id)sender
{
	[self.view sendSubviewToBack:pickerWeightFactor];
	
	if(popover == nil)
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							   target:self
																							   action:@selector(addRoom:)];
	else
		self.navigationItem.rightBarButtonItem = nil;
	
	self.navigationItem.leftBarButtonItem = nil;
	tblView.allowsSelection = TRUE;
}

-(IBAction) saveWFChange:(id)sender
{
	NSString *selected = [weightFactors objectAtIndex:[pickerWeightFactor selectedRowInComponent:0]];
	cubesheet.weightFactor = [selected doubleValue];
	
	cmdWeightFactor.title = [NSString stringWithFormat:@"Weight Factor: %@", selected];	
	
	[self cancelWFChange:sender];
	//reload
	[self viewWillAppear:NO];
}

-(IBAction)addPhotosToRoom:(id)sender
{
	if(imageViewer == nil)
		self.imageViewer = [[SurveyImageViewer alloc] init];
	
	imageViewer.photosType = IMG_ROOMS;
	imageViewer.customerID = del.customerID;
	UIButton *cmd = sender;
	RoomSummary *rs = [summaries objectAtIndex:cmd.tag];
	imageViewer.subID = rs.room.roomID;
	
	imageViewer.caller = self.view;
	
	imageViewer.viewController = self;
	
	[imageViewer loadPhotos];
	
}

-(IBAction) maintenanceClick:(id)sender
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Changes will be enforced on the Master Item/Room list."
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Hide Items", @"Hide Rooms", @"Manage Smart Items", @"Download Item Lists", @"View All Photos", nil]; //@"Frequently Asked Questions",nil];
	
	[sheet showInView:self.view];
	
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
	/*if(section == 0)
		return 1;
	else*/
		return [summaries count];
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
	if(section == 0)
	{
		
		RoomSummary *rs = [RoomSummary totalRoomSummary:summaries];
		
		NSString *summary;
		if(rs.shipping > 0)
			summary = [[NSString alloc] initWithFormat:@"%d items"/*, %@ cu ft, %@ lbs"*/,
					   rs.shipping/*,
					   [[NSNumber numberWithDouble:rs.cube] stringValue], 
					   [[NSNumber numberWithDouble:rs.weight] stringValue]*/];
		else
            summary = @"(no items surveyed)";
				
		return summary;
		
	}
	else		
		return nil;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"RoomSummaryCell";
    
    RoomSummaryCell *cell = (RoomSummaryCell *)[tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RoomSummaryCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
		[cell.cmdImages addTarget:self
		 action:@selector(addPhotosToRoom:) 
		 forControlEvents:UIControlEventTouchUpInside];
    }
	
    [cell.cmdImages removeFromSuperview];
	
	RoomSummary *rs = nil;
	/*if([indexPath section] == 0)
	{
		rs = [RoomSummary totalRoomSummary:summaries];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{*/
		rs = [summaries objectAtIndex:[indexPath row]];
	//}
	cell.labelRoomName.text = rs.room.roomName;
	
	NSString *summary;
	if(rs.shipping > 0)
		summary = [[NSString alloc] initWithFormat:@"%d items"/*, %@ cu ft, %@ lbs"*/,
						 rs.shipping/*,
						 [[NSNumber numberWithDouble:rs.cube] stringValue], 
						 [[NSNumber numberWithDouble:rs.weight] stringValue]*/];
	else
        summary = @"(no items surveyed)";
	
    cell.labelSummary.text = summary;
	
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	RoomSummary *rs = [summaries objectAtIndex:[indexPath row]];
	
	if(caller != nil)
	{
		if([caller respondsToSelector:roomChanged])
			[caller performSelector:roomChanged withObject:rs.room];
	}
	else
	{
		if(itemView == nil)
			itemView = [[ItemViewController alloc] initWithNibName:@"ItemView" bundle:nil];
		
		itemView.currentRoom = rs.room;
		itemView.cubesheet = cubesheet;
		
		[self.navigationController pushViewController:itemView animated:YES];
	}
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [self.weightFactors count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{	
	return [weightFactors objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 295;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		if(buttonIndex == DELETE_ITEMS)
		{
            if(itemDelete == nil) {
                itemDelete = [[DeleteItemController alloc] initWithStyle:UITableViewStylePlain];
            }
            
            itemDelete.customerId = del.customerID;
            itemDelete.ignoreItemListId = FALSE;
			
			deleteNav = [[PortraitNavController alloc] initWithRootViewController:itemDelete];
			
			itemDelete.title = @"Hide Item";
			
			[self.navigationController presentViewController:deleteNav animated:YES completion:nil];
		}
		else if(buttonIndex == DELETE_ROOMS)
		{
			if(roomDelete == nil)
				roomDelete = [[DeleteRoomController alloc] initWithStyle:UITableViewStylePlain];
			
			deleteNav = [[PortraitNavController alloc] initWithRootViewController:roomDelete];
			
			roomDelete.title = @"Hide Room";
			
			[self.navigationController presentViewController:deleteNav animated:YES completion:nil];
		}
		else if(buttonIndex == SURVEY_DOWNLOAD_CUSTOM_ITEM_LISTS)
		{
			if(syncController == nil)
			{
				syncController = [[SyncViewController alloc] initWithNibName:@"SyncView" bundle:nil];
				syncController.title = @"Synchronizing...";
			}
			syncController.downloadCustomItemLists = TRUE;
			[self presentViewController:syncController animated:YES completion:nil];
		}
		else if(buttonIndex == SURVEY_VIEW_ALL_PHOTOS)
		{
            SurveyImageViewer *siv = [[SurveyImageViewer alloc] init];
            siv.customerID = del.customerID;
            siv.viewController = self;
            siv.photosType = IMG_ALL;
            
            [siv viewExistingPhotos];
            
		}
		else if(buttonIndex == SURVEY_FAQ)
		{
			if(surveyFAQ == nil)
				surveyFAQ = [[SurveyFAQViewController alloc] initWithNibName:@"SurveyFAQ" bundle:nil];
			
			[self.navigationController presentViewController:surveyFAQ animated:YES completion:nil];
		}
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tblView];
    
    self.preferredContentSize = CGSizeMake(320, 416);
    
    [super viewDidLoad];
    
    //load weight factors;
    [self loadWeightFactors];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.summaries = [del.surveyDB getRoomSummaries:cubesheet customerID:_customerID];
    
    //set the weight factor;
    [self setWeightFactor];
    
    [self.tblView reloadData];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [del.surveyDB updateCubeSheet:cubesheet];
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
