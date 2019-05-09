//
//  PVOLocationSummary.m
//  Survey
//
//  Created by Tony Brame on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOLocationSummaryController.h"
#import "SurveyAppDelegate.h"
#import "RoomSummaryCell.h"
#import "SurveyLocation.h"
#import "SelectLocationController.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"
#import "RootViewController.h"

@implementation PVOLocationSummaryController

@synthesize addedLocations, tableView;
@synthesize locations, roomController, selectLocation, inventory;
@synthesize itemDelete, roomDelete, contentsDelete, favorites;


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
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.locations = [del.surveyDB getPVOLocations:YES isLoading:YES];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addLocation:)];
    
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:@"Location"];
}

-(void)pickerValueSelected:(NSNumber*)newValue
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //create the new pvo load...
    newLoad = [[PVOInventoryLoad alloc] init];
    newLoad.pvoLocationID = [newValue intValue];
    newLoad.custID = del.customerID;
    
    //check to see if location selection is required...
    if([del.surveyDB pvoLocationRequiresLocationSelection:[newValue intValue]])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        
        //load the location select form.
        if(selectLocation == nil)
            selectLocation = [[SelectLocationController alloc] initWithStyle:UITableViewStyleGrouped];
        selectLocation.title = @"Select Location";
        selectLocation.delegate = self;
        selectLocation.locationID = ORIGIN_LOCATION_ID;
        
        newNav = [[PortraitNavController alloc] initWithRootViewController:selectLocation];
        [self presentViewController:newNav animated:YES completion:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        newLoad.pvoLoadID = [del.surveyDB updatePVOLoad:newLoad];
        [self loadRoomsScreen:newLoad];
    }
}

-(void)textValueEntered:(NSString*)newValue
{
    inventory.weightFactor = [newValue doubleValue];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB updatePVOData:inventory];
}

-(void)continueToRoomsScreen
{
    [self.navigationController pushViewController:roomController animated:YES];
}

-(void)loadRoomsScreen:(PVOInventoryLoad*)pvoLoad
{
    if(_receiveOnly){
        [self loadReceivablesScreen:pvoLoad];
        return;
    }
    
    if(roomController == nil)
        roomController = [[PVORoomSummaryController alloc] initWithNibName:@"PVORoomSummaryView" bundle:nil];
    
//    roomController.inventory = inventory;
    roomController.currentLoad = pvoLoad;
    roomController.quickAddPopupLoaded = NO;
    
    
    //before we go, check for receivables...
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    if(data.driverType == PVO_DRIVER_TYPE_DRIVER)
    {
        //receive all items
        NSArray *receivables = [del.surveyDB getPVOReceivableItems:del.customerID];
        
        if(receivables.count > 0)
        {
            //get to the receive screen (or choppa)!
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receivables"
                                                         message:@"You have receivable items on this record.  Would you like to continue to the receive screen?"
                                                        delegate:self
                                               cancelButtonTitle:@"No"
                                               otherButtonTitles:@"Yes", nil];
            
            av.tag = PVO_LOCATIONS_ALERT_RECEIVE;
            [av show];
        }
        else
            [self continueToRoomsScreen];
        
    }
    else
        [self continueToRoomsScreen];

    
}

-(void)loadReceivablesScreen:(PVOInventoryLoad *)load
{
    //load the receive screen.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray *receivables = [del.surveyDB getPVOReceivableItems:del.customerID];
    if(receiveController == nil)
        receiveController = [[PVOReceiveController alloc] initWithNibName:@"PVOReceiveView" bundle:nil];
    receiveController.loadTheThings = NO;
    receiveController.remainingItems = [NSMutableArray arrayWithArray:receivables];
    receiveController.currentLoad = load;
    receiveController.receivingType = PVO_RECEIVE_ON_DOWNLOAD;
    receiveController.skipInventoryProcess = _receiveOnly;
    
    int unloadType = [del.surveyDB getPVOReceivedItemsUnloadType:del.customerID];
    if (unloadType > 0)
    {
        PVOInventoryUnload *unload = [[PVOInventoryUnload alloc] init];
        unload.pvoLocationID = unloadType;
        unload.custID = del.customerID;
        if ([del.surveyDB pvoLocationRequiresLocationSelection:unloadType])
        {//assumes unload tied to destination address.  will most likely change in future.
            SurveyLocation *dest = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
            unload.locationID = dest.locationID;
        }
        receiveController.currentUnload = unload; //lets receive controller save if needed
    }
    else
        receiveController.currentUnload = nil;
    receiveController.inventory = self.inventory;
    [self.navigationController pushViewController:receiveController animated:YES];
    
}

-(IBAction)addLocation:(id)sender
{
    if (!self.viewHasAppeared)
        return;
    
    self.quickAddPopupLoaded = YES;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driverData = [del.surveyDB getDriverData];
    
    int supportedNumLoads = [AppFunctionality supportedNumberOfPVOLoads:[CustomerUtilities customerPricingMode]];
    if (supportedNumLoads > 0 && supportedNumLoads <= [del.surveyDB getPVOLoadCount:del.customerID])
    {
        [SurveyAppDelegate showAlert:@"Total number of supported Loads has been reached." withTitle:@"Maximum Loads"];
    }
    else
    {
        [del popTablePickerController:@"Locations"
                          withObjects:[del.surveyDB getPVOLocations:NO isLoading:YES isDriverInv:driverData.driverType == PVO_DRIVER_TYPE_DRIVER]
                 withCurrentSelection:nil
                           withCaller:self 
                          andCallback:@selector(pickerValueSelected:) 
                      dismissOnSelect:TRUE
                    andViewController:self
                 skipInventoryProcess:_receiveOnly];
    }
}

-(IBAction)maintenance:(id)sender
{
    UIActionSheet *sheet = nil;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Changes will be enforced on the Master Item/Room list."
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Skip Item Number",
                  [NSString stringWithFormat:@"Weight Factor: %@", [SurveyAppDelegate formatDouble:inventory.weightFactor]], nil];
    }
    else
    {
        sheet = [[UIActionSheet alloc] initWithTitle:@"Changes will be enforced on the Master Item/Room list."
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:@"Skip Item Number", nil];
    }
    sheet.tag = ACTION_SHEET_LIST_MAINTENANCE;
    [sheet showInView:self.view];
}

- (IBAction)cmdSaveToServerClick:(id)sender
{
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.inventory = [del.surveyDB getPVOData:del.customerID];
    
    DriverData *driver = [del.surveyDB getDriverData];
    self.addedLocations = [NSMutableArray arrayWithArray:[del.surveyDB getPVOLocationsForCust:del.customerID
                                                                                withDriverType:driver.driverType]];
    
    [del setTitleForDriverOrPackerNavigationItem:self.navigationItem forTitle:@"Location"];
    
    [self.tableView reloadData];
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!self.quickAddPopupLoaded && self.addedLocations.count == 0 && [del.surveyDB getDriverData].quickInventory)
    {
        [self addLocation:nil];
    }
    else if (self.forceLaunchAddPopup || (_receiveOnly && self.addedLocations.count == 0))
    {
        [self addLocation:nil];
    }
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
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [addedLocations count];
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([addedLocations count] == 0)
        return @"Tap the plus to add a location for this inventory.";
    else
        return  nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RoomSummaryCell";
    
    RoomSummaryCell *cell = (RoomSummaryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RoomSummaryCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [cell.cmdImages removeFromSuperview];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOInventoryLoad *load = [addedLocations objectAtIndex:indexPath.row];
    
    if([del.surveyDB pvoLocationRequiresLocationSelection:load.pvoLocationID])
    {
        SurveyLocation *loc = [del.surveyDB getCustomerLocation:load.locationID];
        cell.labelRoomName.text = [NSString stringWithFormat:@"%@: %@", loc.name,
                                   [locations objectForKey:[NSNumber numberWithInt:load.pvoLocationID]]];
    }
    else
    {
        cell.labelRoomName.text = [NSString stringWithFormat:@"%@",
                                   [locations objectForKey:[NSNumber numberWithInt:load.pvoLocationID]]];
    }
    
    if ([AppFunctionality showCubeAndWeight:[del.surveyDB getPVOData:del.customerID]])
        cell.labelSummary.text = [[NSString alloc] initWithFormat:@"%d Items, %@ cu ft, %@ lbs",
                                  [del.surveyDB getPVOItemCountForLocation:load.pvoLoadID includeDeleted:NO ignoreItemList:YES],
                                  [[NSNumber numberWithDouble:load.cube] stringValue],
                                  [[NSNumber numberWithInt:load.weight] stringValue]];

    else
        cell.labelSummary.text = [NSString stringWithFormat:@"%d Items", [del.surveyDB getPVOItemCountForLocation:load.pvoLoadID includeDeleted:NO ignoreItemList:YES]];
    
    return cell;
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PVOInventoryLoad *load = [addedLocations objectAtIndex:indexPath.row];
    [self loadRoomsScreen:load];
    
}


#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        if(buttonIndex == 0)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOSkipItemNumberController *controller = [[PVOSkipItemNumberController alloc] initWithNibName:@"PVOSkipItemNumberView" bundle:nil];
            controller.defaultLotNumber = inventory.currentLotNum;
            controller.custID = del.customerID;
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:controller];
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
        }/*
        else if(buttonIndex == 1)
        {
            if(newNav != nil)
                
            
            if(itemDelete == nil)
                itemDelete = [[DeleteItemController alloc] initWithStyle:UITableViewStylePlain];
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:itemDelete];
            
            itemDelete.title = @"Hide Item";
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
        }
        else if(buttonIndex == 2)
        {
            if(newNav != nil)
                
            
            if(roomDelete == nil)
                roomDelete = [[DeleteRoomController alloc] initWithStyle:UITableViewStylePlain];
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:roomDelete];
            
            roomDelete.title = @"Hide Room";
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
        }
        else if(buttonIndex == 3)
        {
            if(newNav != nil)
                
            
            if(contentsDelete == nil)
                contentsDelete = [[PVODeleteCCController alloc] initWithStyle:UITableViewStylePlain];
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:contentsDelete];
            
            contentsDelete.title = @"Hide Contents";
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
            
        }
        else if(buttonIndex == 4)
        {
            if(newNav != nil)
                
            
            if(favorites == nil)
                favorites = [[PVOFavoriteItemsController alloc] initWithStyle:UITableViewStyleGrouped];
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:favorites];
            
            favorites.title = @"Favorite Items";
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
            
        }
        else */if(buttonIndex == 1)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            [del pushSingleFieldController:[SurveyAppDelegate formatDouble:inventory.weightFactor]
                               clearOnEdit:NO
                              withKeyboard:UIKeyboardTypeDecimalPad
                           withPlaceHolder:@"Weight Factor"
                                withCaller:self
                               andCallback:@selector(textValueEntered:)
                         dismissController:YES
                          andNavController:self.navigationController];
        }
    }
}

#pragma mark - SelectLocationControllerDelegate methods

-(void)locationSelected:(SelectLocationController*)controller withLocation:(SurveyLocation*)location
{
    //check to see if this one is already assigned..
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.surveyDB locationAvailableForPVOLoad:location.locationID])
    {
        newLoad.locationID = location.locationID;
        newLoad.pvoLoadID = [del.surveyDB updatePVOLoad:newLoad];
        
        [self loadRoomsScreen:newLoad];
    }
    else
        [SurveyAppDelegate showAlert:@"This location has already been selected for a Load, please select a different location, or add a new location." withTitle:@"Location Selected"];
}

-(BOOL)shouldDismiss:(SelectLocationController*)controller
{
    return newLoad.locationID >= 0;
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == PVO_LOCATIONS_ALERT_RECEIVE)
    {
        if(alertView.cancelButtonIndex == buttonIndex)
            [self continueToRoomsScreen];
        else
        {
            [self loadReceivablesScreen:roomController.currentLoad];
        }
    }
}

@end
