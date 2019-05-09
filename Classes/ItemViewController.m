//
//  ItemViewController.m
//  Survey
//
//  Created by Tony Brame on 5/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ItemViewController.h"
#import "Item.h"
#import "SurveyAppDelegate.h"
#import "ItemCell.h"
#import "SurveyedItem.h"
#import "CustomerUtilities.h"

@implementation ItemViewController

@synthesize currentRoom, keys, items, viewControl, itemTable, surveyedItems, cubesheet, detailController, editing, itemController, portraitNavController, helpView;
@synthesize isPackingSummary;

- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
	
	//set up hooks for swipes on table
	itemTable.caller = self;
	itemTable.rightCallback = @selector(swipeRightAt:);
	itemTable.leftCallback = @selector(swipeLeftAt:);
	
	/*self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self
																						   action:@selector(addItem:)];*/
    self.navigationItem.rightBarButtonItem = nil;
	
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	
	if(!editing)
	{
        viewControl.selectedSegmentIndex = SURVEYED_VIEW;
        
		
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
		
        if (isPackingSummary)
        {
            self.title = @"Packing Summary";
            self.surveyedItems = [del.surveyDB getSurveyedPackingItems:cubesheet.csID];
        }
        else
        {
            self.title = currentRoom.roomName;
            self.surveyedItems = [del.surveyDB getRoomSurveyedItems:currentRoom withCubesheetID:cubesheet.csID];
        }
		
		[self reloadItemsList];
	}
	
	editing = NO;
	
    [super viewWillAppear:animated];
}


-(IBAction) addItem:(id)sender
{
	if(itemController == nil)
	{
		itemController = [[NewItemController alloc] initWithStyle:UITableViewStyleGrouped];
		itemController.caller = self;
		itemController.callback = @selector(itemAdded:);
	}
	
	itemController.room = currentRoom;
	Item *newItem = [[Item alloc] init];
	newItem.name = @"";
	itemController.item = newItem;
	
	
	self.portraitNavController = [[PortraitNavController alloc] initWithRootViewController:itemController];
	
	/*SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	[del.navController presentViewController:newNav animated:YES completion:nil];*/
	[self.navigationController presentViewController:portraitNavController animated:YES completion:nil];
}

-(IBAction) itemAdded:(Item*)newItem
{
	[self reloadItemsList];
}

-(void)reloadItemsList
{
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSMutableArray *itemsArr;
	//NSMutableArray *tempIDs;
	
	switch ([viewControl selectedSegmentIndex])
	{
		case TYPICAL_VIEW:
			itemsArr = [del.surveyDB getTypicalItemsForRoom:currentRoom withPVOLocationID:-1 withCustomerID:del.customerID];
			break;
		case ALL_VIEW:
			itemsArr = [del.surveyDB getAllItemsWithPVOLocationID:-1 WithCustomerID:del.customerID];
			break;
		case CP_VIEW:
			itemsArr = [del.surveyDB getCPItemswithCustomerID:del.customerID];
			break;
		case PBO_VIEW:
			itemsArr = [del.surveyDB getPBOItemsWithCustomerID:del.customerID];
			break;
		case SURVEYED_VIEW:
			itemsArr = [del.surveyDB getItemsFromSurveyedItems:surveyedItems withCustomerID:del.customerID];
			break;
		default:
			itemsArr = [del.surveyDB getTypicalItemsForRoom:currentRoom withPVOLocationID:-1 withCustomerID:del.customerID];
			break;
	}
	NSMutableDictionary *itemsDict = [Item getDictionaryFromItemList:itemsArr];
	self.items = itemsDict;
	
	
	NSMutableArray *keysArray = [[NSMutableArray alloc] init];
	
	[keysArray addObjectsFromArray:[[items allKeys] sortedArrayUsingSelector:@selector(compare:)]];
	
	self.keys = keysArray;
	
	[self.itemTable reloadData];
	
}

-(void)setSurveyedItem: (SurveyedItem*)item
{
	
	@try
	{
		SurveyedItem *newItem = [[SurveyedItem alloc] initWithSurveyedItem:item];
		
		[surveyedItems.list setObject:newItem forKey:[NSString stringWithFormat:@"%d", item.itemID]];
		
		
		
		[self.itemTable reloadData];
	}
	@catch (NSException *exc) {
		[SurveyAppDelegate showAlert:exc.reason withTitle:@"ERROR"];
	}
	
}

-(IBAction) switchView:(id)sender
{	
	[self reloadItemsList];
}


/*-(IBAction) decrementShipping: (Item*)item
{
	SurveyedItem *si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
	
	if(si != nil)
	{
		if(si.shipping > 0)
		{
			si.shipping--;
			
			[self.itemTable reloadData];
		}
	}
	
}*/

-(IBAction) userNeedsHelp:(id)sender
{
	//SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	if(helpView == nil)
	{
		helpView = [[HelpViewController alloc] initWithNibName:@"HelpView" bundle:nil];
		helpView.title = @"Survey Help";
	}
	
	[self.navigationController presentViewController:helpView animated:YES completion:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
	
	if(!editing)
	{
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

		[del.surveyDB saveSurveyedItems:surveyedItems];
	}
	
	[super viewWillDisappear:animated];
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
	
    return [keys count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString *key = [keys objectAtIndex:section];
	NSArray *letterSection = [items objectForKey:key];
	return [letterSection count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    ItemCell *cell;
		
	@try {
		
		static NSString *ItemCellIdentifier = @"ItemCell";
		
		cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:ItemCellIdentifier];
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ItemCell" owner:self options:nil];
			cell = [nib objectAtIndex:0];
			
			cell.caller = self;
			//cell.itemCellLeftSwipe = @selector(decrementShipping:);
		}
		
		NSString *key = [keys objectAtIndex:[indexPath section]];
		NSArray *letterSection = [items objectForKey:key];
		
		Item *item = [letterSection objectAtIndex:[indexPath row]];
		cell.labelName.text = item.name;
		
		SurveyedItem *si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
		if(si == nil)
		{
			cell.labelShip.text = @"0";
			cell.labelNotShip.text = @"0";
            [cell.labelNotShip setHidden:TRUE];
			
			NSString *cubeString = [item cubeString];
			cell.labelCube.text = cubeString;
			[cell.labelCube setHidden:TRUE];
		}
		else
		{
			cell.labelShip.text = [NSString stringWithFormat:@"%d", si.shipping];
			cell.labelNotShip.text = [NSString stringWithFormat:@"%d", si.notShipping];
            [cell.labelNotShip setHidden:TRUE];
			
			NSString *cubeString = [Item formatCube:si.cube];
			cell.labelCube.text = cubeString;
			[cell.labelCube setHidden:TRUE];
			
		}	
		
		cell.item = item;
	}
	@catch (NSException * e) {
		[SurveyAppDelegate showAlert:e.reason withTitle:@"ERROR"];
	}
	
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	//we are using this for item detail swipes.
    return YES;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	[SurveyAppDelegate showAlert:@"edit" withTitle:@"edit"];
	
	//tableView.editing= FALSE;
	[tableView setEditing:NO animated:NO];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
    }   
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

-(NSString*) tableView: (UITableView*)tableView titleForHeaderInSection: (NSInteger) section
{
	NSString *key = [keys objectAtIndex:section];
	return key;
}

-(NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
	return keys;
}

-(void) swipeRightAt:(PassTouchPoint*)point
{
    //for PVO, disable detail functionality for now...
    return;
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	BOOL added = FALSE;
	NSIndexPath *indexPath = [itemTable indexPathForRowAtPoint:point.point];
	
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *letterSection = [items objectForKey:key];
	
	Item *item = [letterSection objectAtIndex:[indexPath row]];
	
	//ItemCell *cell = (ItemCell *)[itemTable cellForRowAtIndexPath:indexPath];
	
	SurveyedItem *si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
	
	if(si == nil)
	{
		si = [[SurveyedItem alloc] init];
		si.siID = -1;
		si.itemID = item.itemID;
		si.roomID = currentRoom.roomID;
		si.csID = cubesheet.csID;
		si.cube = item.cube;
		si.shipping = 1;
		
		if(item.isCP)
		{
			si.packing = si.shipping;
//            if([item isMattress])
//                si.unpacking = si.shipping;
		}
		
		[surveyedItems.list setObject:si forKey:[NSString stringWithFormat:@"%d", item.itemID]];
		
		added = TRUE;
	}
	
	//go to detail
	editing = YES;
	
	if(detailController == nil)
	{
		ItemDetailController *ctl = [[ItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
		ctl.caller = self;
		ctl.callback = @selector(setSurveyedItem:);
		self.detailController = ctl;
		
	}
	
	if(si.siID == -1)
	{
		si.siID = [del.surveyDB insertNewSurveyedItem:si];
		[self setSurveyedItem:si];
		si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
	}
	
	detailController.si = si;
	detailController.item = item;
	detailController.title = item.name;
	
	
	[self.navigationController pushViewController:detailController animated:YES];
	
}

-(void) swipeLeftAt:(PassTouchPoint*)point
{
    //for PVO, disable detail functionality for now...
    return;
    
	NSIndexPath *indexPath = [itemTable indexPathForRowAtPoint:point.point];
	
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *letterSection = [items objectForKey:key];
	
	Item *item = [letterSection objectAtIndex:[indexPath row]];
	
	SurveyedItem *si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
	
	if(si == nil)
		return;
	
	if(si.shipping > 0)
	{
		si.shipping--;
		//decrement packing as well
		if(si.packing > 0)
			si.packing = si.shipping;
		if(si.unpacking > 0)
			si.unpacking = si.shipping;
	}
	
	[itemTable reloadData];
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
	[self.itemTable deselectRowAtIndexPath:indexPath animated:YES];
    
    //for PVO, disable detail functionality for now...
    return;
	
	//had to add this so it didnt reselect the row when the user lifted their finger.
	if(itemTable.justProcessedSwipe)
	{
		itemTable.justProcessedSwipe = FALSE;
		return;
	}
	
	//NSLog(@"DID SELECT ROW");
	bool added = NO;
	
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *letterSection = [items objectForKey:key];
	
	Item *item = [letterSection objectAtIndex:[indexPath row]];
	
	ItemCell *cell = (ItemCell *)[tableView cellForRowAtIndexPath:indexPath];
		
	SurveyedItem *si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
	
	if(si == nil && !cell.processedLeftSwipe)
	{
		if(item.isCrate)
		{
			CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
			PassTouchPoint *pt = [[PassTouchPoint alloc] init];
			pt.point = CGPointMake(rect.origin.x + (rect.size.width / 2), rect.origin.y + (rect.size.height / 2));
			[self swipeRightAt:pt];
			return;
		}
		
		si = [[SurveyedItem alloc] init];
		si.siID = -1;
		si.itemID = item.itemID;
		si.roomID = currentRoom.roomID;
		si.csID = cubesheet.csID;
		si.cube = item.cube;
		if(cell.cellHeld)
			si.notShipping = 1;
		else
			si.shipping = 1;
		
		if(cell.item.isCP)
		{
			si.packing = si.shipping;
//            if([item isMattress])
//                si.unpacking = si.shipping;
		}
		
		[surveyedItems.list setObject:si forKey:[NSString stringWithFormat:@"%d", item.itemID]];
		
		added = YES;
	}
	
	/*if(cell.processedLeftSwipe && si != nil)
	{
		if(si.shipping > 0)
		{
			si.shipping--;
			//decrement packing as well
			if(si.packing > 0)
				si.packing = si.shipping;
			if(si.unpacking > 0)
				si.unpacking = si.shipping;
		}
	}
	else if(cell.processedRightSwipe)
	{
		//go to detail
		editing = YES;

		if(detailController == nil)
		{
			ItemDetailController *ctl = [[ItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
			ctl.caller = self;
			ctl.callback = @selector(setSurveyedItem:);
			self.detailController = ctl;
			
		}
		
		del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		if(si.siID == -1)
		{
			si.siID = [del.surveyDB insertNewSurveyedItem:si];
			[self setSurveyedItem:si];
			si = [surveyedItems.list objectForKey:[NSString stringWithFormat:@"%d", cell.item.itemID]];
		}
		
		detailController.si = [si retain];
		detailController.item = cell.item;
		detailController.title = cell.item.name;
		
		
		[del.navController pushViewController:detailController animated:YES];
		
		
	}
	else*/ 
	
	if(cell.cellHeld && !added)
	{
		si.notShipping++;
	}
	else if(!added)//tap
	{
		if(si != nil)
		{
			si.shipping++;
			if(item.isCP)
			{
				si.packing = si.shipping;
//                if([item isMattress])
//                    si.unpacking = si.shipping;
			}
		}
	}
	[tableView reloadData];
	
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



@end

