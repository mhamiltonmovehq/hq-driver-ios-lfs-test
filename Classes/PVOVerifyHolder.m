//
//  PVOVerifyHolder.m
//  Survey
//
//  Created by Tony Brame on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOVerifyHolder.h"
#import "SurveyAppDelegate.h"
#import "PVOVerifyInventoryItem.h"

@implementation PVOVerifyHolder


-(id)initFromView:(UIViewController*)vc
{
    self = [super init];
    
    if(self)
    {
        selectedLoads = [[NSMutableArray alloc] init];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        selectController = [[SelectObjectController alloc] init];
        selectController.delegate = self;
        selectController.multipleSelection = YES;
        selectController.title = @"Select Verify Loads";
        selectController.displayMethod = @selector(orderNumber);
        
        selectController.choices = [del.surveyDB getPVOVerifyInventoryOrders];
        
        navController = [[PortraitNavController alloc] initWithRootViewController:selectController];
        
        [vc presentViewController:navController animated:YES completion:nil];
        
    }
    
    return self;
}

//will either load the landing page for orders that need it, or load the scanner screen if all of the orders have landing data
-(void)loadNextScreen
{
    //just grab the first customer id...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *data = [selectedLoads objectAtIndex:0];

    del.customerID = data.custID;
    
    if(landingController == nil)
        landingController = [[PVOLandingController alloc] initWithStyle:UITableViewStyleGrouped];
    
    landingController.delegate = self;
    [navController pushViewController:landingController animated:YES];
    
}

-(void)roomSelected:(Room*)room
{
    //add this room to each inventory...
    currentRoom = room;
    
    //now go on to the scan screen...
    if(scanSerialController == nil)
    {
        scanSerialController = [[ScanOrEnterValueController alloc] initWithStyle:UITableViewStyleGrouped];
        scanSerialController.title = @"Serial Number";
        scanSerialController.description = @"Serial Number";
        scanSerialController.delegate = self;
    }
    
    [navController pushViewController:scanSerialController animated:YES];
}

-(void)continueToItemDetails
{
    if(itemDetailController == nil)
    {
        itemDetailController = [[PVOItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
        itemDetailController.title = @"Item";
        itemDetailController.delegate = self;
    }
    
    //get the item.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int itemID = [del.surveyDB getItemID:currentItem.articleDescription];
    if(itemID == 0)
    {
        Item *newItem = [[Item alloc] init];
        newItem.name = currentItem.articleDescription;
        itemID = [del.surveyDB insertNewItem:newItem withRoomID:currentRoom.roomID withCustomerID:del.customerID];
//        itemID = [del.surveyDB getItemID:currentItem.articleDescription];
    }
    
    itemDetailController.item = [del.surveyDB getItem:itemID WithCustomer:del.customerID];
    itemDetailController.room = currentRoom;
    
    PVOItemDetail *pid = [[PVOItemDetail alloc] init];
    pid.itemID = itemID;
    pid.roomID = currentRoom.roomID;
    pid.serialNumber = currentItem.serialNumber;
    
    //load the load... (first verify inventory load for customer)
    NSArray *loads = [del.surveyDB getPVOLocationsForCust:currentItem.custID];
    for (PVOInventoryLoad *load in loads) {
        if(load.pvoLocationID == 8)
        {
            pid.pvoLoadID = load.pvoLoadID;
            break;
        }
    }
    
    PVOInventory *inv = [del.surveyDB getPVOData:currentItem.custID];
    pid.tagColor = inv.currentColor;
    pid.cartonContents = [[del.surveyDB getItem:pid.itemID WithCustomer:del.customerID] isCP];
    pid.noExceptions = inv.noConditionsInventory;
    
    if(notPickingUp || !inv.usingScanner)
    {
        if(notPickingUp)
        {
            pid.lotNumber = @"99900";
            pid.itemIsDeleted = YES;
            pid.voidReason = @"Item not found in verify inventory list, and driver has chosen not to pick up item.";
        }
        else
            pid.lotNumber = inv.currentLotNum;
        
        pid.itemNumber = [del.surveyDB nextPVOItemNumber:currentItem.custID forLot:inv.currentLotNum];
        inv.nextItemNum = inv.nextItemNum + 1;
    }
    pid.damage = [NSMutableArray array];
    
    pid.verifyStatus = @"L";
    if(currentItem.orderNumber == nil)
    {
        if(notPickingUp)
            pid.verifyStatus = @"VN";
        else
            pid.verifyStatus = @"VL";
    }
    
    itemDetailController.pvoItem = pid;
    
    [navController pushViewController:itemDetailController animated:YES];
    
}


#pragma mark - SelectObjectControllerDelegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    if(controller == selectSingleLoadController)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        currentItem.custID = del.customerID;
        //currentItem.custID = [[collection objectAtIndex:0] custID];
        //now, get the item description for this ole guy...
        
        if(selectItemController == nil)
            selectItemController = [[SelectItemWithFilterController alloc] initWithNibName:@"SelectItemWithFilterView" bundle:nil];
        
        selectItemController.title = @"Select Item";
        selectItemController.delegate = self;
        selectItemController.currentRoom = currentRoom;
        selectItemController.showAddItemButton = YES;
        selectItemController.showSurveyedFilter = YES;
        
        [navController pushViewController:selectItemController animated:YES];
    }
    else
    {
        selectedLoads = [[NSMutableArray alloc] initWithArray:collection];
        
        [self loadNextScreen];
    }
}

-(NSMutableArray*)selectObjectControllerPreSelectedItems:(SelectObjectController*)controller
{
    if(controller == selectSingleLoadController)
        return [NSMutableArray array];
    else
        return selectedLoads;
}

-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller
{
    return NO;
}

#pragma mark - PVOLandingControllerDelegate methods

-(void)pvoLandingController:(PVOLandingController*)controller dataEntered:(PVOInventory*)data
{
    //don't go to locations summary, go to location type select screen, OR JUST DEFAULT TO Verify Inveotnry???  
    //I am going with defatuling all to Verify Inventory so we don't have to worry about selecting a location dependent option...

    //save for all of the orders, then continue to the locations page
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    for (PVOVerifyInventoryItem *verifyItem in selectedLoads) {
        data.custID = verifyItem.custID;
        [del.surveyDB updatePVOData:data];
        
        BOOL found = NO;
        NSArray *locs = [del.surveyDB getPVOLocationsForCust:verifyItem.custID];
        for (PVOInventoryLoad *ld in locs) {
            if(ld.pvoLocationID == 8)
                found = TRUE;
        }
        
        if(!found)
        {
            //add a new location
            PVOInventoryLoad *newLoad = [[PVOInventoryLoad alloc] init];
            newLoad.pvoLocationID = 8;
            newLoad.custID = verifyItem.custID;
            newLoad.pvoLoadID = [del.surveyDB updatePVOLoad:newLoad];
        }
        
    }
    
    //load select room screen...
    
    if(addRoomController == nil)
        addRoomController = [[AddRoomController alloc] initWithStyle:UITableViewStylePlain andPushed:YES];
    
    addRoomController.delegate = self;
    addRoomController.caller = self;
    addRoomController.callback = @selector(roomSelected:);
    
    [navController pushViewController:addRoomController animated:YES];
    
}


#pragma mark - AddRoomControllerDelegate methods

-(BOOL)addRoomControllerShouldDismiss:(AddRoomController *)controller
{
    return NO;
}

#pragma mark - ScanOrEnterValueControllerDelegate methods

-(void)scanOrEnterValueController:(ScanOrEnterValueController*)controller dataEntered:(NSString*)data
{
    //find out if this was a verified item or not.  
    //if everything checks out, open the item detail screen for the order and load it belongs to
    //else, ask the right questions...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *items = [del.surveyDB getPVOVerifyInventoryItems];
    
    currentItem = nil;
    for (PVOVerifyInventoryItem *i in items) {
        if(i.serialNumber != nil && [i.serialNumber isEqualToString:data])
        {
            currentItem = i;
            break;
        }
    }
    
    if(currentItem == nil)
    {
        //not found, prompt user for action
        currentItem = [[PVOVerifyInventoryItem alloc] init];
        currentItem.serialNumber = data;
        //using this to flag controller that this is a not found item.
        currentItem.orderNumber = nil;
        
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Item Not Found!  Would you like to pick it up anyway?" 
                                                        delegate:self 
                                               cancelButtonTitle:@"Cancel" 
                                          destructiveButtonTitle:nil 
                                               otherButtonTitles:@"Yes", @"No", nil];
        [as showInView:navController.view];
    }
    else
    {
        [self continueToItemDetails];
    }
    
}

-(BOOL)scanOrEnterValueControllerShowDone:(ScanOrEnterValueController*)controller
{
    return YES;
}

-(void)scanOrEnterValueControllerDone:(ScanOrEnterValueController*)controller
{
    [navController dismissViewControllerAnimated:YES completion:nil];
}

-(NSString*)scanOrEnterValueHeaderText:(ScanOrEnterValueController*)controller
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [NSString stringWithFormat:@"%d item(s) remaining", [del.surveyDB getPVOVerifyInventoryItemCount:selectedLoads]];
}

-(void)scanOrEnterValueWillDisplay:(ScanOrEnterValueController*)controller
{//clear the serial number...
    controller.data = @"";
}

#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    notPickingUp = FALSE;
    if(buttonIndex != actionSheet.cancelButtonIndex)
    {
        notPickingUp = buttonIndex == PVO_VERIFY_DONT_PICK_UP;
        
        if(selectSingleLoadController == nil)
        {
            selectSingleLoadController = [[SelectObjectController alloc] init];
        
            selectSingleLoadController.delegate = self;
            selectSingleLoadController.multipleSelection = NO;
            selectSingleLoadController.title = @"Select Load";
            selectSingleLoadController.displayMethod = @selector(orderNumber);
            selectSingleLoadController.controllerPushed = YES;
        }
        
        selectSingleLoadController.choices = selectedLoads;
        
        [navController pushViewController:selectSingleLoadController animated:YES];
        
    }
}

#pragma mark - SelectItemWithFilterControllerDelegate methods

-(void)itemController:(SelectItemWithFilterController*)controller selectedItem:(Item*)item
{
    currentItem.articleDescription = item.name;
    [self continueToItemDetails];
}

-(BOOL)itemControllerShouldShowCancel:(SelectItemWithFilterController*)controller
{
    return NO;
}

-(BOOL)itemControllerShouldDismiss:(SelectItemWithFilterController*)controller
{
    return NO;
}

#pragma mark - PVOItemDetailControllerDelegate methods

-(void)pvoItemControllerContinueToNextItem:(PVOItemDetailController*)controller
{
    //delete the item we were working on...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB pvoDeleteVerifyItem:currentItem];
    
    [navController popToViewController:scanSerialController animated:YES];
}

@end
