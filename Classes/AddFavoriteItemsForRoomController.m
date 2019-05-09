//
//  AddFavoriteItemsForRoomController.m
//  Mobile Mover
//
//  Created by Jason Gorringe on 8/24/18.
//

#import "AddFavoriteItemsForRoomController.h"
#import "SurveyAppDelegate.h"
#import "Item.h"
#import "SSCheckBoxView.h"

@implementation AddFavoriteItemsForRoomController

@synthesize allItems, keys;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Create menu bar buttons
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancel:)] init];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(addChecked:)] init];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Create selected items array
    self.selectedItems = [NSMutableArray array];
    
    // Create all items array
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getAllItems];
    
    self.allItems = [Item getDictionaryFromItemList:items];
    
    // Pre-select items that are already favorites
    [self convertFavoritesToSelectedItems:[items copy]];
    
    // Create all keys array (the 'key' here is the first letter of the item name, aka its table section)
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    // Nil object references and reload the tableview
    keysArray = nil;
    items = nil;
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
    [self reloadItemsList];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addChecked:(id)sender
{
    // Display an error message if a user tries to hide 0 items
    if ([_selectedItems count] == 0 && [self.favorites count] == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more items before tapping the Add button." withTitle:@"No Items Selected"];
        return;
    }
    
    // Display an action sheet for the user to confirm that they want to delete the selected items
    NSString* asTitle = [NSString stringWithFormat:@"Are you sure that you would like to add the selected items to the favorite items list for %@?",self.room.roomName];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:asTitle
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                         destructiveButtonTitle:@"Yes"
                                              otherButtonTitles:nil];
    
    [sheet showInView:self.view];
    
}

-(void)reloadItemsList
{
    self.selectedItems = [NSMutableArray array];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getAllItems];
    
    self.allItems = [Item getDictionaryFromItemList:items];
    
    // Pre-select items that are already favorites
    [self convertFavoritesToSelectedItems:[items copy]];
    
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    keysArray = nil;
    items = nil;
    
    [self.tableView reloadData];
    
}

// Adds the specified favorite items to the selected items list so they will have checkmarks
-(void)convertFavoritesToSelectedItems:(NSArray*)items {
    for(Item* i in self.favorites) {
        for(Item* j in items) {
            if(i.itemID == j.itemID) {
                [self.selectedItems addObject:i];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [keys count];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [keys objectAtIndex:section];
    NSArray *letterSection = [allItems objectForKey:key];
    return [letterSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2
    
    static NSString *CellIdentifier = @"ItemDeleteControllerCell";
    
    UILabel *mainLabel;
    SSCheckBoxView *checkBox;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] init];
        
        checkBox = [[[SSCheckBoxView alloc] initWithFrame:CGRectMake(4.0, 4.0, 30.0, 30.0)
                                                    style:kSSCheckBoxViewStyleGlossy
                                                  checked:NO] init];
        checkBox.tag = CHECK_BOX_TAG;
        [cell.contentView addSubview:checkBox];
        
        mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 280.0, 44.0)] init];
        mainLabel.tag = LABEL_TAG;
        mainLabel.font = [UIFont boldSystemFontOfSize:17.0];
        mainLabel.textAlignment = NSTextAlignmentLeft;
        mainLabel.textColor = [UIColor blackColor];
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
    }
    else
    {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
        checkBox = (SSCheckBoxView *)[cell.contentView viewWithTag:CHECK_BOX_TAG];
    }
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [allItems objectForKey:key];
    
    Item *item = [letterSection objectAtIndex:[indexPath row]];
    NSString *cube = [item cubeString];
    
    mainLabel.text = [NSString stringWithFormat:@"%@    %@", item.name, cube];
    
    // Check the box if the item is selected
    checkBox.checked = FALSE;
    for(Item* i in self.selectedItems) {
        if(i.itemID == item.itemID) {
            checkBox.checked = TRUE;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [allItems objectForKey:key];
    
    Item *item = [letterSection objectAtIndex:[indexPath row]];
    
    // Add or remove the item from the selected items list
    BOOL selected = FALSE;
    Item* toRemove;
    for(Item* i in self.selectedItems) {
        if(i.itemID == item.itemID) {
            selected = TRUE;
            toRemove = i;
        }
    }
    
    if(selected)
    {
        [_selectedItems removeObject:toRemove];
    }
    else
    {
        [_selectedItems addObject:item];
    }
    
    [tableView reloadData];
    
}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        [self cancel:nil];
        
        [self.delegate itemsChosen:_selectedItems forRoom:self.room];
    }
    
}

@end

