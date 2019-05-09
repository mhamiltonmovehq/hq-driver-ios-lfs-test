//
//  PVOSelectCartonContentsController.m
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOSelectCartonContentsController.h"
#import "SurveyAppDelegate.h"
#import "SSCheckBoxView.h"
#import "SearchCell.h"

@implementation PVOSelectCartonContentsController

@synthesize keys, allItems, contentsDictionary, delegate, pvoCartonContentController, searchString, segmentFilter;

- (id)initWithStyle:(UITableViewStyle)style
{
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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self 
                                                                                            action:@selector(addContentItem:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self 
                                                                                            action:@selector(cancel:)];
    

//    NSArray* toolbarItems = [NSArray arrayWithObjects:
//                             [[UIBarButtonItem alloc] initWithTitle:@"Add Selected Items" style:UIBarButtonItemStylePlain target:self
//                                                                           action:@selector(addSelectedItems:)], nil];
//    
//    [toolbarItems makeObjectsPerformSelector:@selector(release)];
//    self.toolbarItems = toolbarItems;
//    self.navigationController.toolbarHidden = NO;
    self.useCheckBoxes = YES;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    if (createNewItemMode)
    {
        createNewItemMode = NO;
    }
    else
    {
        self.selectedItems = [NSMutableArray array];
    }
    
    [self reloadContentsList];
    
    if (_useCheckBoxes)
    {
    }
    
    searching = NO;
    
}

- (IBAction)addSelectedItems:(id)sender
{
    if ([_selectedItems count] == 0)
    {
        [SurveyAppDelegate showAlert:@"You must select one or more items before tapping the 'Add Selected Items' button." withTitle:@"No Items Selected"];
        return;
    }
    
    if (delegate != nil && [delegate respondsToSelector:@selector(contentsController:selectedContents:)])
    {
        [delegate contentsController:self selectedContents:_selectedItems];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(contentsControllerCanceled:)])
        [delegate contentsControllerCanceled:self];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)reloadContentsList
{
    NSMutableArray *itemsArr;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	if(searching && (searchString == nil || [searchString isEqualToString:@""]))
    {
        self.keys = [NSArray array];
        self.contentsDictionary = [NSDictionary dictionary];
        [[self.view viewWithTag:99] setHidden:NO];
        [self.tableView reloadData];
        return;
    }
    
//    if(searching)
//        [[self.view viewWithTag:99] setHidden:YES];
    
    currentSegment = [segmentFilter selectedSegmentIndex];
    
    switch (currentSegment) {
        case 0:
	    itemsArr = [[NSMutableArray alloc] initWithArray:[del.surveyDB getPVOAllCartonContents:self.searchString withCustomerID:del.customerID]];
            break;
            
        default:
            itemsArr = [[NSMutableArray alloc] initWithArray:[del.surveyDB getPVOFavoriteCartonContents:self.searchString]];
            break;
    }
    
    NSMutableDictionary *itemsDict = [PVOCartonContent getDictionaryFromContentList:itemsArr];
    self.contentsDictionary = itemsDict;
    
	
	NSMutableArray *keysArray = [[NSMutableArray alloc] init];
	[keysArray addObjectsFromArray:[[contentsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]];
	
    if([keysArray count] > 0 && !searching)
        [keysArray insertObject:@"{search}" atIndex:0];
    
	self.keys = keysArray;
    
    if(searching && [self.keys count] > 0)
        [[self.view viewWithTag:99] setHidden:YES];
    else
        [[self.view viewWithTag:99] setHidden:NO];
	
	[self.tableView reloadData];
	
}

-(IBAction)addContentItem:(id)sender
{
    PortraitNavController *ctller;
    
    if (currentSegment == 1)
    {
        if (favoriteItems == nil)
            favoriteItems = [[PVOFavoriteCartonContentsController alloc] initWithStyle:UITableViewStylePlain];
        favoriteItems.title = @"Setup Favorites";
        
        ctller = [[PortraitNavController alloc] initWithRootViewController:favoriteItems];
    }
    else
    {
        createNewItemMode = YES;
    
        if(pvoCartonContentController == nil)
            pvoCartonContentController = [[PVONewCartonContentsController alloc] initWithStyle:UITableViewStyleGrouped];
    
        pvoCartonContentController.title = @"Add Content";
        pvoCartonContentController.delegate = self;
        
        ctller = [[PortraitNavController alloc] initWithRootViewController:pvoCartonContentController];
    }
    
    [self presentViewController:ctller animated:YES completion:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(goAwayAfterLoad)
        [self dismissViewControllerAnimated:YES completion:nil];
    goAwayAfterLoad = FALSE;
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

-(void)selectedItem:(PVOCartonContent*)content
{
    if(delegate != nil && [delegate respondsToSelector:@selector(contentsController:selectedContent:)])
        [delegate contentsController:self selectedContent:content];
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    [self.view bringSubviewToFront:[self.view viewWithTag:99]];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    newSearchBar.frame = CGRectMake(0, 20, 320, 44);
    [UIView commitAnimations];
    
    [self performSelector:@selector(shrinkViewForKeyboard) withObject:nil afterDelay:.3f];
    
    [self reloadContentsList];
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
	return keys;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSString *key = [keys objectAtIndex:section];
    if (section == 0 && !searching)
        return 1;
    else
    {
        NSArray *letterSection = [contentsDictionary objectForKey:key];
        return [letterSection count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2

    static NSString *CellIdentifier = @"PVOSelectCartonContentsControllerCell";
    static NSString *SearchCellIdentifier = @"SearchCell";
    
    UILabel *mainLabel;
    SSCheckBoxView *checkBox;
    SearchCell *searchCell = nil;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    
    
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
            
        }
        
    }
    else
    {
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

            if (_useCheckBoxes)
            {
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
        }
        else
        {
            if (_useCheckBoxes)
            {
                mainLabel = (UILabel *)[cell.contentView viewWithTag:LABEL_TAG];
                checkBox = (SSCheckBoxView *)[cell.contentView viewWithTag:CHECK_BOX_TAG];
            }
        }
        
        NSString *key = [keys objectAtIndex:[indexPath section]];
        NSArray *letterSection = [contentsDictionary objectForKey:key];
        
        PVOCartonContent *contents = [letterSection objectAtIndex:[indexPath row]];
        
        if (_useCheckBoxes)
        {
            mainLabel.text = contents.description;
            checkBox.checked = [_selectedItems containsObject:@(contents.contentID)];
        }
        else
        {
            cell.textLabel.text = contents.description;
        }
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
    NSArray *letterSection = [contentsDictionary objectForKey:key];
    
    PVOCartonContent *contents = [letterSection objectAtIndex:[indexPath row]];
    
    if (_useCheckBoxes)
    {
        if ([_selectedItems containsObject:@(contents.contentID)])
        {
            [_selectedItems removeObject:@(contents.contentID)];
        }
        else
        {
            [_selectedItems addObject:@(contents.contentID)];
        }
        
        [self.tableView reloadData];
    }
    else
    {
        [self selectedItem:contents];
    }
}

#pragma mark PVONewCartonContentsControllerDelegate methods

-(void)addContentsController:(PVONewCartonContentsController*)controller addedContent:(PVOCartonContent*)item
{    
    if (_useCheckBoxes)
    {
        [_selectedItems addObject:@(item.contentID)];
        //[self.tableView reloadData];
    }
    else
    {
        goAwayAfterLoad = TRUE;
        [self selectedItem:item];
    }
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.searchString = [searchText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    [self reloadContentsList];
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
    self.searchString = nil;
    
    [self reloadContentsList];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
//    [searchBar resignFirstResponder];
//    [searchBar setShowsCancelButton:NO animated:NO];
//    [searchBar removeFromSuperview];
    [[self.view viewWithTag:99] removeFromSuperview];
    searching = NO;
    self.searchString = nil;
    
    [self reloadContentsList];
}

-(IBAction)segmentFilter_changed:(id)sender
{
    [self reloadContentsList];
}

@end
