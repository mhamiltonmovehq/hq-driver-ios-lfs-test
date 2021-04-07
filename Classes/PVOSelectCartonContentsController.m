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

@synthesize keys, allItems, contentsDictionary, delegate, pvoCartonContentController, segmentFilter, searchBar, keyboardVisible;

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    self.useCheckBoxes = YES;
    self.searchBar.delegate = self;
    self.keyboardVisible = NO;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
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
    self.searchBar.text = @"";

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)reloadContentsList
{
    self.contentsDictionary = [PVOCartonContent getDictionaryFromContentList:[self getFilteredCartonContentList:self.searchBar.text]];

	NSMutableArray *keysArray = [[NSMutableArray alloc] init];
	[keysArray addObjectsFromArray:[[contentsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
	self.keys = keysArray;
	
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
    NSArray *letterSection = [contentsDictionary objectForKey:key];
    return [letterSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#define CHECK_BOX_TAG   1
#define LABEL_TAG       2

    static NSString *CellIdentifier = @"PVOSelectCartonContentsControllerCell";
    
    UILabel *mainLabel;
    SSCheckBoxView *checkBox;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
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
    
    return cell;
}

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
    self.searchBar.text = [searchText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    [self reloadContentsList];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];

    [self reloadContentsList];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self reloadContentsList];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

-(IBAction)segmentFilter_changed:(id)sender
{
    self.contentsDictionary = [PVOCartonContent getDictionaryFromContentList:[self getFilteredCartonContentList: @""]];
    self.searchBar.text = @"";

    [self reloadContentsList];
}

#pragma mark - Helpers -
-(NSArray*)getFilteredCartonContentList:(NSString*) searchString {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* filteredResults = [[NSArray alloc] init];
    currentSegment = [segmentFilter selectedSegmentIndex];
    
    switch (currentSegment) {
        case 0:
            filteredResults = [[NSMutableArray alloc] initWithArray:
                         [del.surveyDB getPVOAllCartonContents:searchString withCustomerID:del.customerID]];
            break;
            
        default:
            filteredResults = [[NSMutableArray alloc] initWithArray:
                         [del.surveyDB getPVOFavoriteCartonContents:searchString]];
            break;
    }
    return filteredResults;
}

- (void)keyboardWillShow: (NSNotification *) sender {
    if (!keyboardVisible) {
        keyboardVisible = YES;
        CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect frame = self.view.frame;
        frame.size.height -= keyboardFrame.size.height;
        self.view.frame = frame;
    }
}

- (void)keyboardWillHide: (NSNotification *) sender {
    if (keyboardVisible) {
        keyboardVisible = NO;
        CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect frame = self.view.frame;
        frame.size.height += keyboardFrame.size.height;
        self.view.frame = frame;
    }
}



@end
