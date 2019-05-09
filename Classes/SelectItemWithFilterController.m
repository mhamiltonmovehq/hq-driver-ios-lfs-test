//
//  SelectItemWithFilterController.m
//  Survey
//
//  Created by Tony Brame on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SelectItemWithFilterController.h"
#import "SurveyAppDelegate.h"
#import "ItemViewController.h"
#import "ItemCell.h"
#import "SearchCell.h"
#import "NewItemController.h"
#import "AppFunctionality.h"
#import "CustomerUtilities.h"

@implementation SelectItemWithFilterController

@synthesize itemsTable, items, labelNoFavorites, searchString;
@synthesize segmentFilter, keys, currentRoom, delegate, showAddItemButton;
@synthesize itemController, showSurveyedFilter, pvoLocationID;
@synthesize showCPButton, showPBOButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.itemsTable];
    
    [super viewDidLoad];
    
    BOOL cancel = YES;
    if(delegate != nil && [delegate respondsToSelector:@selector(itemControllerShouldShowCancel:)])
        cancel = [delegate itemControllerShouldShowCancel:self];
    
    if(cancel)
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancel:)];
	
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ItemType *itemTypes = [AppFunctionality getItemTypes:[CustomerUtilities customerPricingMode]
                                          withDriverType:[del.surveyDB getDriverData].driverType
                                            withLoadType:[del.surveyDB getPVOData:del.customerID].loadType];
    
    loadType = [del.surveyDB getPVOData:del.customerID].loadType;
    
    [segmentFilter removeAllSegments];
    
    if(showSurveyedFilter)
    {
        //check to see if there are any items first...
        NSArray *temp = [self surveyedItemsForRoom];
        if(temp.count > 0)
        {
            [segmentFilter insertSegmentWithTitle:@"Srvy" atIndex:0 animated:NO];
            [segmentFilter insertSegmentWithTitle:@"Fav" atIndex:0 animated:NO];
        }
        else
        {
            [segmentFilter insertSegmentWithTitle:@"Favorites" atIndex:0 animated:NO];
            lastSegment = lastSegment == 5 ? 0 : lastSegment;
        }
        
        
        
    }
    else
    {
        [segmentFilter insertSegmentWithTitle:@"Favorites" atIndex:0 animated:NO];
        lastSegment = lastSegment == 5 ? 0 : lastSegment;
    }
    
    showCPButton = YES;
    showPBOButton = YES;
    if (itemTypes != nil)
    {
        if (itemTypes.allowedItems != nil && [itemTypes.allowedItems count] > 0)
        {
            if (![itemTypes isAllowedItemType:ITEM_TYPE_CP])
                showCPButton = NO;
            if (![itemTypes isAllowedItemType:ITEM_TYPE_PBO])
                showPBOButton = NO;
        }
        if (itemTypes.hiddenItems != nil && [itemTypes.hiddenItems count] > 0)
        {
            if ([itemTypes isHiddenItemType:ITEM_TYPE_CP])
                showCPButton = NO;
            if ([itemTypes isHiddenItemType:ITEM_TYPE_PBO])
                showPBOButton = NO;
        }
    }
    
#ifdef ATLASNET
    if(loadType == SPECIAL_PRODUCTS)
    {
        showPBOButton = NO;
        showCPButton = NO;
    }
#endif
    if (showPBOButton)
        [segmentFilter insertSegmentWithTitle:@"PBO" atIndex:0 animated:NO];
    if (showCPButton)
        [segmentFilter insertSegmentWithTitle:@"CP" atIndex:0 animated:NO];
    
    [segmentFilter insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
    
#ifdef ATLASNET
    if(loadType != SPECIAL_PRODUCTS)
    [segmentFilter insertSegmentWithTitle:@"Typical" atIndex:0 animated:NO];
#else
    [segmentFilter insertSegmentWithTitle:@"Typical" atIndex:0 animated:NO];
#endif
    
    
    searching = NO;
    
    segmentFilter.selectedSegmentIndex = lastSegment;
    
    if(showAddItemButton)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                              target:self
                                                                                              action:@selector(addNewItem:)];
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    [super viewWillAppear:animated];
    
    if(!dontReloadOnAppear)
        [self reloadItemsList];
    dontReloadOnAppear = NO;
}

-(NSArray*)surveyedItemsForRoom
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    CubeSheet *cs = [del.surveyDB openCubeSheet:del.customerID];
    SurveyedItemsList *sil = [del.surveyDB getRoomSurveyedItems:currentRoom withCubesheetID:cs.csID overrideLimit:NO];
    NSMutableArray *arr = [del.surveyDB getItemsFromSurveyedItems:sil withCustomerID:del.customerID];
    return arr;
}

-(IBAction)dismissKeyboard:(id)sender
{
    
}

-(BOOL)shouldDismiss
{
    BOOL dismiss = YES;
    if(delegate != nil && [delegate respondsToSelector:@selector(itemControllerShouldDismiss:)])
        dismiss = [delegate itemControllerShouldDismiss:self];
    return dismiss;
}

-(IBAction)addNewItem:(id)sender
{
	if(itemController == nil)
	{
		itemController = [[NewItemController alloc] initWithStyle:UITableViewStyleGrouped];
		itemController.caller = self;
		itemController.callback = @selector(itemAdded:);
	}
	
	itemController.room = currentRoom;
    itemController.pvoLocationID = pvoLocationID;
	Item *newItem = [[Item alloc] init];
	newItem.name = @"";
	itemController.item = newItem;
	
	
    if(newNav != nil)
    {
        
        newNav = nil;
    }
    
	newNav = [[PortraitNavController alloc] initWithRootViewController:itemController];
	
	[self.navigationController presentViewController:newNav animated:YES completion:nil];
}

-(IBAction) itemAdded:(Item*)newItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //always look at all
    if (loadType == SPECIAL_PRODUCTS && [del.pricingDB vanline] == ATLAS) {
        [segmentFilter setSelectedSegmentIndex:ALL_VIEW - 1]; //No "Typical" tab with STG.  Need to display all tab, but subtract 1 to account for the missing tab.
    } else {
        [segmentFilter setSelectedSegmentIndex:ALL_VIEW];
    }
    
    //reload once to load all items to get an index from
	[self reloadItemsList];
    
    //jump to the new item
    NSArray *myitems = [items objectForKey:[[newItem.name uppercaseString] substringToIndex:1]];
    
    int section = -1;
    for (int i = 0; i < [keys count]; i++) {
        if([[keys objectAtIndex:i] isEqualToString:[[newItem.name uppercaseString] substringToIndex:1]])
            section = i;
    }
    
    if(myitems != nil && section != -1)
    {
        NSIndexPath *idx = nil;
        for (int i = 0; i < [myitems count]; i++) {
            if([[[myitems objectAtIndex:i] name] isEqualToString:newItem.name])
            {
                idx = [NSIndexPath indexPathForRow:i inSection:section];
            }
        }
        
        if(idx != nil)
            [itemsTable scrollToRowAtIndexPath:idx atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    }
    
    dontReloadOnAppear = YES;
    
}

-(IBAction)cancel:(id)sender
{
    if([self shouldDismiss])
        [self dismissViewControllerAnimated:YES completion:nil];
    else
    {
        if(delegate != nil && [delegate respondsToSelector:@selector(itemControllerWasCancelled:)])
            [delegate itemControllerWasCancelled:self];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)reloadItemsList
{
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSMutableArray *itemsArr = nil;
    NSMutableArray *favoritesByRoomArr = nil;
    
    if(searching && (searchString == nil || [searchString isEqualToString:@""]))
    {
        self.keys = [NSArray array];
        self.items = [NSDictionary dictionary];
        [[self.view viewWithTag:99] setHidden:NO];
        [self.itemsTable reloadData];
        return;
    }
    
    labelNoFavorites.hidden = YES;
    lastSegment = [segmentFilter selectedSegmentIndex];
    currentSegment = [segmentFilter selectedSegmentIndex];
    if (!showCPButton && currentSegment >= CP_VIEW)
        currentSegment++; //hiding CP view, skip it
    if (!showPBOButton && currentSegment >= PBO_VIEW)
        currentSegment++; //hiding PBO view, skip it
    
    
    if(loadType == SPECIAL_PRODUCTS && [del.pricingDB vanline] == ATLAS)
    {
        switch (currentSegment)
        {
            case 0: // all view
                itemsArr = [del.surveyDB getAllSpecialProductItemsWithCustomerID:del.customerID];
                break;
            case 1: // favorites
                itemsArr = [del.surveyDB getFavoriteSpecialProductItems];
                break;
            default: // empty views aside from all and favorites
                itemsArr = [[NSMutableArray alloc] init];
                break;
        }
    } else {
        switch (currentSegment)
        {
		case TYPICAL_VIEW:
                itemsArr = (NSMutableArray *)[del.surveyDB getTypicalItemsForRoom:currentRoom withPVOLocationID:self.pvoLocationID withCustomerID:del.customerID];
                break;
		case ALL_VIEW:
                itemsArr = (NSMutableArray *)[del.surveyDB getAllItemsWithPVOLocationID:self.pvoLocationID WithCustomerID:del.customerID];
                [self removeItemsFromTabs:itemsArr delegate:del];
                break;
		case CP_VIEW:
                itemsArr = (NSMutableArray *)[del.surveyDB getCPItemsWithPVOLocationID:self.pvoLocationID withCustomerID:del.customerID];
                [self removeItemsFromTabs:itemsArr delegate:del];
                break;
		case PBO_VIEW:
                itemsArr = (NSMutableArray *)[del.surveyDB getPBOItemsWithPVOLocationID:self.pvoLocationID withCustomerID:del.customerID];
                [self removeItemsFromTabs:itemsArr delegate:del];
                break;
		case 4://make show favorites view
                itemsArr = (NSMutableArray *)[del.surveyDB getPVOFavoriteItemsWithCustomerID:del.customerID];
                favoritesByRoomArr = (NSMutableArray*)[del.surveyDB getPVOFavoriteItemsForRoom:currentRoom];
                labelNoFavorites.hidden = [itemsArr count] != 0 || [favoritesByRoomArr count] != 0;
                break;
		case 5://show surveyed view
                itemsArr = (NSMutableArray *)[self surveyedItemsForRoom];
                break;
        }
    }
    
    if(currentSegment != 4) { // Not in favorites
    if(searching)
    {
        [[self.view viewWithTag:99] setHidden:YES];
        NSMutableArray *toremove = [[NSMutableArray alloc] init];
        for (Item *i in itemsArr) {
            if([i.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location == NSNotFound)
                [toremove addObject:i];
        }
        [itemsArr removeObjectsInArray:toremove];
        [itemsArr sortUsingSelector:@selector(sortByName:)];
    }
    
	NSMutableDictionary *itemsDict = [Item getDictionaryFromItemList:itemsArr];
	self.items = itemsDict;
	
	
	NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    [keysArray addObjectsFromArray:[[items allKeys] sortedArrayUsingSelector:@selector(compare:)]];
	
    if([keysArray count] > 0 && !searching)
        [keysArray insertObject:@"{search}" atIndex:0];
    
	self.keys = keysArray;
	
	
    } else { // Favorite
        if(searching)
        {
            [[self.view viewWithTag:99] setHidden:YES];
            NSMutableArray *toremove = [[NSMutableArray alloc] init];
            for (Item *i in itemsArr) {
                if([i.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location == NSNotFound)
                    [toremove addObject:i];
            }
            [itemsArr removeObjectsInArray:toremove];
            [itemsArr sortUsingSelector:@selector(sortByName:)];
	
            [[self.view viewWithTag:99] setHidden:YES];
            NSMutableArray *toremove2 = [[NSMutableArray alloc] init];
            for (Item *i in favoritesByRoomArr) {
                if([i.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location == NSNotFound)
                    [toremove2 addObject:i];
            }
            [favoritesByRoomArr removeObjectsInArray:toremove2];
            [favoritesByRoomArr sortUsingSelector:@selector(sortByName:)];
        }
        
        // Sort items within their two groups
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        NSArray* itemsArrSorted = [itemsArr sortedArrayUsingDescriptors:@[sort]];
        NSArray* favoritesByRoomArrSorted = [favoritesByRoomArr sortedArrayUsingDescriptors:@[sort]];
        
        NSString* rmFavesLabel = [NSString stringWithFormat:@"%@ Favorites",currentRoom.roomName];
        NSString* favesLabel = @"Favorites";
        
        NSMutableDictionary *bothDict = [[NSMutableDictionary alloc] init];
        [bothDict setObject:favoritesByRoomArrSorted forKey:rmFavesLabel];
        [bothDict setObject:itemsArrSorted forKey:favesLabel];
        self.items = bothDict;
        
        NSMutableArray *keysArray = [[NSMutableArray alloc] init];
        [keysArray addObject:rmFavesLabel];
        [keysArray addObject:favesLabel];
        
        if([keysArray count] > 0 && !searching)
            [keysArray insertObject:@"{search}" atIndex:0];
        
        self.keys = keysArray;
        
    }
    
    
    
	[self.itemsTable reloadData];

    //per email 11/29, don't scroll to top
//    if([keys count] > 1 && !searching)
//        [self.itemsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
	
}

// OT 20271 - remove CN items from US HHG orders
-(void)removeItemsFromTabs:(NSMutableArray *)itemsArr delegate:(SurveyAppDelegate *)del {
    //Set up
    SurveyCustomer* cust = [del.surveyDB getCustomer:del.customerID];
    int pricingMode = [cust pricingMode];
    NSMutableArray* toRemove = [[NSMutableArray alloc] init];
    
    // US Interstate and Local pricing
    if(pricingMode == INTERSTATE || pricingMode == LOCAL) {
        for(Item* item in itemsArr) {
            int list = [del.surveyDB getItemListIDForItem:item];
            if(list == CNCIV || list == CNGOV) { // Remove all CN items
                [toRemove addObject:item];
            }
        }
    }
    // CNCIV and CNGOV
    else if(pricingMode == CNCIV || pricingMode == CNGOV) {
        for(Item* item in itemsArr) {
            int list = [del.surveyDB getItemListIDForItem:item];
            if(list == INTERSTATE || list == LOCAL) { // Remove all US items
                [toRemove addObject:item];
            }
        }
    }
    
    //Remove
    for(Item* item in toRemove) {
        if([itemsArr containsObject:item]) {
            [itemsArr removeObject:item];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)segmentFilter_Changed:(id)sender
{
    [self reloadItemsList];
}

-(IBAction)cmdSearchClick:(id)sender
{
    searching = YES;
    
    if([self.view viewWithTag:99] == nil)
    {
        UIView *viewLoading = [[UIView alloc] initWithFrame:self.view.frame];
        viewLoading.backgroundColor = [UIColor blackColor];
        viewLoading.alpha = .75;
        viewLoading.tag = 99;
        [self.view addSubview:viewLoading];
    }
    
    UISearchBar *newSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, 320, 44)];
    newSearchBar.showsCancelButton = NO;
    newSearchBar.delegate = self;
    newSearchBar.placeholder = @"Search";
    [newSearchBar setShowsCancelButton:YES animated:YES];
    [self.navigationController.view addSubview:newSearchBar];
    [self.navigationController.view bringSubviewToFront:newSearchBar];
    [newSearchBar becomeFirstResponder];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    newSearchBar.frame = CGRectMake(0, 20, 320, 44);
    [UIView commitAnimations];
    
    [self performSelector:@selector(shrinkViewForKeyboard) withObject:nil afterDelay:.3f];
    
    [self reloadItemsList];
}

-(void) shrinkViewForKeyboard
{
    CGRect frame = self.view.frame;
    frame.size.height -= 216;
    self.view.frame = frame;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [keys count];
}

-(NSString*) tableView: (UITableView*)tableView titleForHeaderInSection: (NSInteger) section
{
    if(section == 0 && !searching)
        return nil;
	NSString *key = [keys objectAtIndex:section];
	return key;
}

-(NSArray*) sectionIndexTitlesForTableView:(UITableView*)tableView
{
    if(segmentFilter.selectedSegmentIndex != 4) {
	return keys;
    } else {
        return nil; // For favorites, changed for OT 7985
}

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *key = [keys objectAtIndex:section];
    if(section == 0 && !searching)
        return 1;
    else
    {
        NSArray *letterSection = [items objectForKey:key];
        return [letterSection count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ItemCell *cell = nil;
    SearchCell *searchCell = nil;

    static NSString *ItemCellIdentifier = @"ItemCell";
    static NSString *SearchCellIdentifier = @"SearchCell";
    
    if(indexPath.section == 0 && !searching)
    {
        searchCell = (SearchCell *)[tableView dequeueReusableCellWithIdentifier:SearchCellIdentifier];
        if (searchCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SearchCell" owner:self options:nil];
            searchCell = [nib objectAtIndex:0];
            searchCell.accessoryType = UITableViewCellAccessoryNone;
            searchCell.searchBar.delegate = self;
            [searchCell.cmdSearch addTarget:self
                                     action:@selector(cmdSearchClick:) 
                           forControlEvents:UIControlEventTouchUpInside];
            //self.searchDisplayController.searchBar = searchCell.searchBar;
			/*[searchCell.searchBar addTarget:self 
                                     action:@selector(textFieldDoneEditing:) 
                           forControlEvents:UIControlEventEditingDidEndOnExit];*/
        }
        
    }
    else
    {
        cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:ItemCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ItemCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            //[cell removeCounts];
        }
        
        NSString *key = [keys objectAtIndex:[indexPath section]];
        NSArray *letterSection = [items objectForKey:key];
        
        Item *item = [letterSection objectAtIndex:[indexPath row]];
        cell.labelName.text = item.name;
        
        
        //if surveyed, set up so there is a surveyed item count,
        //if not, only show cube and hide the count as it is not applicable
        if(segmentFilter.selectedSegmentIndex == 5)
        {
            cell.labelNotShip.hidden = YES;
            cell.labelShip.hidden = NO;
            cell.labelCube.frame = CGRectMake(181, 10, 44, 22);
            cell.labelCube.hidden = YES;
            
            //get the surveyed item count...
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            CubeSheet *cs = [del.surveyDB openCubeSheet:del.customerID];
            SurveyedItemsList *sil = [del.surveyDB getRoomSurveyedItems:currentRoom withCubesheetID:cs.csID];
            SurveyedItem *si = [sil.list objectForKey:[NSString stringWithFormat:@"%d", item.itemID]];
            if(si != nil)
            {
                cell.labelShip.text = [NSString stringWithFormat:@"%d", si.shipping];
                cell.labelNotShip.text = [NSString stringWithFormat:@"%d", si.notShipping];
            }
            else
            {
                cell.labelShip.text = @"";
                cell.labelNotShip.text = @"";
            }
        }
        else
        {
            cell.labelNotShip.hidden = YES;
            cell.labelShip.hidden = YES;
            cell.labelCube.frame = CGRectMake(238, 10, 44, 22);
        }
        
        NSString *cubeString = [item cubeString];
        cell.labelCube.text = cubeString;
        
    }
    
    return searchCell == nil ? cell : searchCell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [items objectForKey:key];
    
    Item *item = [letterSection objectAtIndex:[indexPath row]];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(itemController:selectedItem:)])
        [delegate itemController:self selectedItem:item];
    
    
    if([self shouldDismiss])
        [self dismissViewControllerAnimated:YES completion:nil];
    //else, let the other controller do the work...
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.searchString = searchText;
    [self reloadItemsList];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    //resize table view, end search
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:NO];
    [searchBar removeFromSuperview];
    
    [[self.view viewWithTag:99] removeFromSuperview];
    
    CGRect frame = self.view.frame;
    frame.size.height += 216;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    self.view.frame = frame;
    [UIView commitAnimations];
    
    searching = NO;
    [self reloadItemsList];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searching = NO;
    self.searchString = nil;
    
}

@end
