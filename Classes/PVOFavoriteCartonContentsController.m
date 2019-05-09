//
//  PVOFavoriteCartonContentsController.m
//  Survey
//
//  Created by Justin Little on 10/3/2014.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOFavoriteCartonContentsController.h"
#import "SurveyAppDelegate.h"

@implementation PVOFavoriteCartonContentsController

@synthesize favoriteContents, favoriteContentsController;

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
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addItem:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
    
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
    [self reloadContentList];
    [self.tableView reloadData];
}



-(void)reloadContentList
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.favoriteContents = [NSMutableArray arrayWithArray:[del.surveyDB getPVOFavoriteCartonContents:nil]];
    
    /*
    [SurveyAppDelegate addMessageToTableViewHeader:self.tableView
                                       withMessage:@"Tap the plus sign to add a favorite carton contents to the favorites view."
                                       showMessage:[self.favoriteContents count] == 0]; */
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}



-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



-(IBAction)addItem:(id)sender

{    
    if(favoriteContentsController == nil)
        favoriteContentsController = [[FavoriteContentsController alloc] initWithStyle:UITableViewStylePlain];
    
    favoriteContentsController.title = @"Add Favorite";
    
    newNav = [[PortraitNavController alloc] initWithRootViewController:favoriteContentsController];
    
    [self presentViewController:newNav animated:YES completion:nil];
}



-(void)itemAdded:(PVOCartonContent*)ccItem
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB addPVOFavoriteCartonContents:ccItem.contentID];
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
    return 1;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [favoriteContents count];
}



-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section

{
    //    if([favoriteContents count] == 0)
    //        return @"Tap the plus sign to add a favorite carton content to the favorites view.";
    //    else
    return nil;
}



-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath

{
    return YES;
}



-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath

{
    if(editingStyle == UITableViewCellEditingStyleDelete)
        
    {
        //remove it...
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOCartonContent *ccItem = [favoriteContents objectAtIndex:indexPath.row];
        
        
        [del.surveyDB removePVOFavoriteCartonContents:ccItem.contentID];
        [favoriteContents removeObjectAtIndex:indexPath.row];
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        [self reloadContentList];
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    PVOCartonContent *ccItem = [favoriteContents objectAtIndex:indexPath.row];
    cell.textLabel.text = ccItem.description;
    
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
}


@end
