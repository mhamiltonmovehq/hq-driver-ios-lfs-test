//
//  FavoriteContentsController.m
//  Mobile Mover
//
//  Created by Jason Gorringe on 1/3/18.
//

#import "FavoriteContentsController.h"
#import "SurveyAppDelegate.h"
#import "SSCheckBoxView.h"

@implementation FavoriteContentsController

@synthesize allItems, keys;

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
    
    [super viewDidLoad];
    
    // Initialize the top-left cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(done:)];
    
    // Initialize the top-right hide button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(hideChecked:)];
    
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
    
    // Create selected items array
    self.selectedItems = [NSMutableArray array];
    
    // Create all items array
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getPVOAllCartonContents:@"" withCustomerID:del.customerID];

    self.allItems = [PVOCartonContent getDictionaryFromContentList:items];
    
    // Create all keys array (the 'key' here is the first letter of the item name, aka its table section)
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    // Release object references and reload the tableview
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
    [self reloadItemsList];
}

-(IBAction)done:(id)sender
{
    // Will dismiss this view when requested
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideChecked:(id)sender
{
    // Display an error message if a user tries to hide 0 items
    if ([_selectedItems count] == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more carton contents before tapping the Add button." withTitle:@"No Items Selected"];
        return;
    }
    
    // Display an action sheet for the user to confirm that they want to delete the selected items
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure that you would like to add the selected items to the favorite carton contents list?"
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
    
    NSMutableArray *items = (NSMutableArray*)[del.surveyDB getPVOAllCartonContents:@"" withCustomerID:del.customerID];
    
    self.allItems = [PVOCartonContent getDictionaryFromContentList:items];
    
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[allItems allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    
    [self.tableView reloadData];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    //    static NSString *CellIdentifier = @"Cell";
    //
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2
    
    static NSString *CellIdentifier = @"ItemDeleteControllerCell";
    
    UILabel *mainLabel;
    SSCheckBoxView *checkBox;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        checkBox = [[SSCheckBoxView alloc] initWithFrame:CGRectMake(4.0, 4.0, 30.0, 30.0)
                                                    style:kSSCheckBoxViewStyleGlossy
                                                  checked:NO];
        checkBox.tag = CHECK_BOX_TAG;
        [cell.contentView addSubview:checkBox];
        
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 280.0, 44.0)];
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
    
    PVOCartonContent *item = [letterSection objectAtIndex:[indexPath row]];
    
    mainLabel.text = [NSString stringWithFormat:@"%@", item.description];
    checkBox.checked = [_selectedItems containsObject:item];
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [keys objectAtIndex:[indexPath section]];
    NSArray *letterSection = [allItems objectForKey:key];
    
    PVOCartonContent *item = [letterSection objectAtIndex:[indexPath row]];
    
    if ([_selectedItems containsObject:item])
    {
        [_selectedItems removeObject:item];
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
        //        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        //        NSString *key = [keys objectAtIndex:[editPath section]];
        //        NSArray *letterSection = [contentsDictionary objectForKey:key];
        //
        //        PVOCartonContent *contents = [letterSection objectAtIndex:[editPath row]];
        //        [del.surveyDB hidePVOCartonContent:contents.contentID];
        //
        //        [self reloadContentsList];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for (PVOCartonContent *item in _selectedItems) {
            [del.surveyDB addPVOFavoriteCartonContents:item.contentID];
        }
        
        [self done:nil];
    }
    
}

@end


