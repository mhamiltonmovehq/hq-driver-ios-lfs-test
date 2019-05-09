//
//  PVOItemSummaryController.m
//  Survey
//
//  Created by Tony Brame on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "PVOItemSummaryController.h"
#import "SurveyAppDelegate.h"
#import "PVOItemDetail.h"
#import "Item.h"
#import "CustomerUtilities.h"
#import "ButtonCell.h"
#import "AppFunctionality.h"
#import "PVONavigationController.h"
#import "MoveItemsController.h"

@implementation PVOItemSummaryController

@synthesize itemDetail, room, selectItem, portraitNav, inventory, pvoItems, tableView;
@synthesize toolbar, currentLoad, isPackersInvSummary;
@synthesize cmdComplete, cmdVoid, cmdRoomConditions;

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
    
    [super viewDidLoad];
	
    if (!isPackersInvSummary)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                            action:@selector(addItem:)];
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    self.wentToRoomConditions = FALSE;

//	[self buildTitleView];
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.inventory = [del.surveyDB getPVOData:del.customerID];

    NSArray *items = nil;
    if (!isPackersInvSummary)
        items = [del.surveyDB getPVOItems:currentLoad.pvoLoadID forRoom:room.roomID];
    else
        items = [del.surveyDB getPVOReceivableItems:del.customerID ignoreReceived:TRUE forRoom:room.roomID];
        
    self.pvoItems = [NSMutableArray arrayWithArray:items];
    
    //set up toolbar
    roomConditionsEnabled =  [CustomerUtilities roomConditionsEnabled];
    
    if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
        cmdRoomConditions.title = @"Location Cond.";
    else
        cmdRoomConditions.title = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";
    
    if (isPackersInvSummary)
    {//remove from view
        if(tableView.superview != nil)
        {
            CGRect frame = self.tableView.frame;
            frame.size.height += toolbar.frame.size.height;
            tableView.frame = frame;
            [toolbar removeFromSuperview];
        }
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(!isPackersInvSummary && [pvoItems count] == 0 && !self.wentToRoomConditions && roomConditionsEnabled)
        [self roomConditions];
    else if (!isPackersInvSummary && !self.quickAddPopupLoaded && [self.pvoItems count] == 0 && [del.surveyDB getDriverData].quickInventory)
    {//if no items have been added, force the popup
        [self addItem:nil];
    }
    else if (self.forceLaunchAddPopup)
    {//coming from a screen (damages) that forces the add popup
        [self addItem:nil];
    }
    
}


-(IBAction) enterRoomAlias:(id)sender
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Room Alias"
                                                 message:@"Use this option to create a new name for this Room, in this Survey only."
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"OK", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    av.tag = PVO_ITEM_SUMMARY_ALERT_ADD_ALIAS;
    UITextField *tbox = [av textFieldAtIndex:0];
    tbox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    tbox.placeholder = room.roomName;
    [av show];
}


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


-(IBAction)cmdFinishedClick:(id)sender
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Confirm" 
                                                    message:@"Are you sure you would like to mark this inventory as completed?" 
                                                   delegate:self 
                                          cancelButtonTitle:@"No" 
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

-(IBAction)roomMaintenance:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an option"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:[AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions", @"Move Items", nil];
    sheet.tag = PVO_ITEM_SUMMARY_MAINTENANCE;
    
    [sheet showInView:self.view];
}

-(void)roomConditions
{
    if(roomConditions == nil)
        roomConditions = [[PVORoomConditionsController alloc] initWithStyle:UITableViewStyleGrouped];
    
    roomConditions.room = room;
    roomConditions.currentLoad = currentLoad;
    if ([AppFunctionality requiresPropertyCondition])
        roomConditions.title = @"Property Conditions";
    else if (currentLoad.pvoLocationID == COMMERCIAL_LOC)
        roomConditions.title = @"Location Conditions";
    else
        roomConditions.title = @"Room Conditions";
    
    //
	portraitNav = [[PortraitNavController alloc] initWithRootViewController:roomConditions];
	
    self.wentToRoomConditions = TRUE;
    
	[self presentViewController:portraitNav animated:YES completion:nil];
}

-(IBAction)addItem:(id)sender
{
    if (!self.viewHasAppeared)
        return;
    
    self.quickAddPopupLoaded = YES;
    
	if(selectItem == nil)
		selectItem = [[SelectItemWithFilterController alloc] initWithNibName:@"SelectItemWithFilterView" bundle:nil];
	
    selectItem.delegate = self;
    selectItem.currentRoom = room;
    selectItem.showAddItemButton = YES;
    selectItem.showSurveyedFilter = YES;
    selectItem.pvoLocationID = currentLoad.pvoLocationID;
    
    if(!inventory.usingScanner)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        selectItem.title = [NSString stringWithFormat:@"%@: %@",
                            room.roomName,
                            [del.surveyDB nextPVOItemNumber:del.customerID forLot:inventory.currentLotNum withStartingItem:inventory.nextItemNum]];
    }
    else
        selectItem.title = room.roomName;
	
    //odd behavior if I release this local var...
	self.portraitNav = [[PortraitNavController alloc] initWithRootViewController:selectItem];
	
	[self presentViewController:portraitNav animated:YES completion:nil];
	
}

-(IBAction)cmdVoidTagClick:(id)sender
{
    //add a new tag with the VOID item.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    Item *voidItem = [del.surveyDB getItemByItemName:del.customerID withItemName:PVO_VOID_NO_ITEM_NAME];
//    
//    if(voidItem == nil)
//    {
//        voidItem = [[Item alloc] init];
//        voidItem.name = PVO_VOID_NO_ITEM_NAME;
//        int newItemID = [del.surveyDB insertNewItem:voidItem withRoomID:-1 withCustomerID:del.customerID];
//        [voidItem release];
//        
//        voidItem = [del.surveyDB getItem:newItemID];
//    }
    
    Item *voidItem = [del.surveyDB getVoidTagItem];
    //just load this into the ctrller i guess...  always add a new record...
    [self loadController:nil withItem:voidItem];
    
}


-(void)loadController:(PVOItemDetail*)pvoItem withItemID:(int)itemID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	Item *item = [del.surveyDB getItem:itemID WithCustomer:del.customerID];
    
    [self loadController:pvoItem withItem:item];
}

-(void)loadController:(PVOItemDetail *)pvoItem withItem:(Item*)item
{
    if(itemDetail == nil)
        itemDetail = [[PVOItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
    
    itemDetail.title = @"Item Detail";
    itemDetail.pvoItem = pvoItem;
    itemDetail.item = item;
    itemDetail.room =room;
    itemDetail.inventory = inventory;
    itemDetail.currentLoad = currentLoad;
    itemDetail.comingFromItemSummary = YES;
    
    [self.navigationController pushViewController:itemDetail animated:YES];
}

-(void)voidReasonEntered:(NSString*)voidReason
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (voidReason == nil || [voidReason isEqualToString:@""])
    {
        [SurveyAppDelegate showAlert:@"Void Reason is required to continue." withTitle:@"Text Required"];
    }
    else
    {
        [del.surveyDB voidPVOItem:workingItem.pvoItemID withReason:voidReason];
        
        NSArray *items = [del.surveyDB getPVOItems:currentLoad.pvoLoadID forRoom:room.roomID];
        self.pvoItems = [NSMutableArray arrayWithArray:items];
    }
}

-(void)deleteWorkingItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB deletePVOItem:workingItem.pvoItemID withCustomerID:del.customerID];
}

-(void)voidWorkingItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
    if(!workingItem.inventoriedAfterSignature && sig != nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
                                                        message:@"This item was inventoried prior to the customer signing at Origin. If you choose to continue, any signatures will be removed. Would you like to continue?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG_AND_VOID;
        [alert show];
    }
    else
    {
        
        [del pushNoteViewController:workingItem.voidReason
                       withKeyboard:UIKeyboardTypeASCIICapable
                       withNavTitle:@"Void Reason"
                    withDescription:@"Please enter a Void Reason"
                         withCaller:self
                        andCallback:@selector(voidReasonEntered:)
                  dismissController:YES
                           noteType:NOTE_TYPE_NONE
                   andNavController:self.navigationController];
    }
    
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    // Return the number of sections.
    //return 2 to turn on Void Tag button
    return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return [pvoItems count];
    else
        return 1;
}



- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{	
	if(!isPackersInvSummary && [pvoItems count] == 0 && section == 0)
		return [NSString stringWithFormat:@"Select the plus button to add an item to the %@ room.", room.roomName];
	else
		return nil;
	
}


- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
	if(section == 1)
		return @"Use this option to void a tag that has been damaged before assigning to an item.";
	else
		return nil;
	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    
    UITableViewCell *cell = nil;
    ButtonCell *buttonCell = nil;
    
    if(indexPath.section == 1)
    {
		buttonCell = (ButtonCell *)[tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
		
		if (buttonCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
			buttonCell = [nib objectAtIndex:0];
			
			[buttonCell.cmdButton addTarget:self
                                     action:@selector(cmdVoidTagClick:)
                           forControlEvents:UIControlEventTouchUpInside];
            
            [buttonCell.cmdButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:8. topCapHeight:0.]
                                            forState:UIControlStateNormal];
            [buttonCell.cmdButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            buttonCell.cmdButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
            buttonCell.cmdButton.titleLabel.shadowColor = [UIColor lightGrayColor];
            buttonCell.cmdButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
		}
        
        [buttonCell.cmdButton setTitle:@"Void Tag" forState:UIControlStateNormal];
        
        
    }
    else
    {
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.imageView.layer.cornerRadius = 5.0;
            cell.imageView.layer.masksToBounds = YES;
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOItemDetail *pid = [pvoItems objectAtIndex:indexPath.row];
        if(pid.itemIsDeleted)
        {
            if([cell viewWithTag:99] == nil)
            {
                UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, (cell.frame.size.height / 2.0) - 1, cell.frame.size.width - 40, 2)];
                line.backgroundColor = [UIColor blackColor];
                line.tag = 99;
                [cell addSubview:line];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            [[cell viewWithTag:99] removeFromSuperview];
            
            cell.accessoryType = (isPackersInvSummary || pid.lockedItem ?  UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator);
        }
        Item *i = [del.surveyDB getItem:pid.itemID WithCustomer:del.customerID];
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", 
                               pid.itemNumber == nil ? @" - no tag - " : pid.itemNumber, 
                               i.name];
        
        UIImage *myimage = pid.pvoItemID != 0 ? [SurveyImageViewer getDefaultImage:IMG_PVO_ITEMS forItem:pid.pvoItemID] : nil;
        cell.imageView.image = myimage;
    }
    
    return cell != nil ? cell : buttonCell;
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


#pragma mark -
#pragma mark Table view delegate

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([AppFunctionality canDeleteInventoryItems])
        return @"Delete";
    else
        return @"Void";
}

-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !isPackersInvSummary;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        deletingIndex = indexPath;
        workingItem = [pvoItems objectAtIndex:deletingIndex.row];
        
        if ([AppFunctionality canDeleteInventoryItems])
        {
            UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Delete"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Void Item", @"Delete Item", nil];
            as.tag = PVO_ITEM_ALERT_DELETE;
            [as showInView:self.view];
        }
        else
            [self voidWorkingItem];
    }
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    if (!isPackersInvSummary)
    {
        //load up this pid...
        PVOItemDetail *pid = [pvoItems objectAtIndex:indexPath.row];
        if (pid.lockedItem)
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"%@", [pid quickSummaryText]] withTitle:@"Item Quick Summary"];
            return;
        }
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
        if(!pid.inventoriedAfterSignature && sig != nil)
        {
            workingItem = pid;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
                                                            message:@"This item was inventoried prior to the customer signing at Origin. If you choose to continue, any signatures will be removed. Would you like to continue?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG;
            [alert show];
        }
        else
        {
            if(!pid.itemIsDeleted)
                [self loadController:pid withItemID:pid.itemID];
            else
            {
                workingItem = pid;
                [self voidWorkingItem];
            }
        }
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

//- (void)viewDidUnload {
//    [cmdVoid release];
//    cmdVoid = nil;
//    [cmdComplete release];
//    cmdComplete = nil;
//    [cmdRoomConditions release];
//    cmdRoomConditions = nil;
//    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
//    // For example: self.myOutlet = nil;
//}


#pragma mark - SelectItemWithFilterControllerDelegate methods

-(void)itemController:(SelectItemWithFilterController*)controller selectedItem:(Item*)item
{
	//just load this into the ctrller i guess...  always add a new record...
	[self loadController:nil withItem:item];
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if(alertView.tag == PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG || alertView.tag == PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG_AND_VOID)
        {
            [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
            [del.surveyDB setPVOItemsInventoriedBeforeSignature:del.customerID];
            inventory.inventoryCompleted = NO;
            [del.surveyDB updatePVOData:inventory];
            
            [del.surveyDB removeCompletionDate:del.customerID isOrigin:YES];
            
            //move on to item!
            if(!workingItem.itemIsDeleted && alertView.tag == PVO_ITEM_SUMMARY_ALERT_REMOVE_SIG)
            {
                [self loadController:workingItem withItemID:workingItem.itemID];
                workingItem = nil;
            }
            else
            {
                [del pushNoteViewController:workingItem.voidReason
                               withKeyboard:UIKeyboardTypeASCIICapable
                               withNavTitle:@"Void Reason"
                            withDescription:@"Please enter a Void Reason"
                                 withCaller:self
                                andCallback:@selector(voidReasonEntered:)
                          dismissController:YES
                                   noteType:NOTE_TYPE_NONE
                           andNavController:self.navigationController];
                
//                TextViewAlert *alert = [[TextViewAlert alloc] initWithTitle:@"Please enter a reason for voiding this item."
//                                                                requireText:YES
//                                                               existingText:workingItem.voidReason];
//                alert.delegate = self;
            }
        }
//        else if (alertView.tag == PVO_ITEM_SUMMARY_ALERT_ADD_ALIAS)
//        {
//            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//            [del.surveyDB saveRoomAlias:[alertView textFieldAtIndex:0].text withCustomerID:del.customerID andRoomID:room.roomID];
//            
//            [self buildTitleView];
//        }
        else
        {
            inventory.inventoryCompleted = YES;
            [del.surveyDB updatePVOData:inventory];
            
            [del.surveyDB setCompletionDate:del.customerID isOrigin:YES];
            
            //jump back to nav list
            PVONavigationController *navController = nil;
            for (id view in [self.navigationController viewControllers]) {
                if([view isKindOfClass:[PVONavigationController class]])
                    navController = view;
            }
            
            [self.navigationController popToViewController:navController animated:YES];
        }
    }
}


#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
     
        if (actionSheet.tag == PVO_ITEM_SUMMARY_MAINTENANCE)
        {
            if (buttonIndex == PVO_ITEM_SUMMARY_ROOM_CONDITIONS)
            {
                [self roomConditions];
            }
            else if (buttonIndex == PVO_ITEM_SUMMARY_ROOM_MOVE_ITEMS)
            {
                MoveItemsController *navController = [[MoveItemsController alloc] initWithStyle:UITableViewStyleGrouped];
                navController.currentRoomID = room.roomID;
                navController.pvoLoadID = currentLoad.pvoLoadID;
                
                [self.navigationController pushViewController:navController animated:YES];
            }
        }
        else
        {
            if (buttonIndex == PVO_ITEM_DELETE_VOID)
                [self voidWorkingItem];
            else if (buttonIndex == PVO_ITEM_DELETE_DELETE)
                [self deleteWorkingItem];
        
            NSArray *items = [del.surveyDB getPVOItems:currentLoad.pvoLoadID forRoom:room.roomID];
            self.pvoItems = [NSMutableArray arrayWithArray:items];
            
            [self.tableView reloadData];
        }
    }
    
    //[deletingIndex release];
}

@end

