//
//  PVODelBatchExcController.m
//  Survey
//
//  Created by Tony Brame on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODelBatchExcController.h"
#import "SurveyAppDelegate.h"
#import "PVOItemSummaryController.h"

@implementation PVODelBatchExcController

@synthesize duplicatedTags, wheelDamageController, currentLoad;
@synthesize buttonDamageController, moveToNextItem, currentUnload, signatureController;
@synthesize hideBackButton;
@synthesize excType;

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

    visitedTags = [[NSMutableArray alloc] init];
    
    self.navigationItem.hidesBackButton = hideBackButton;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    if(moveToNextItem)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next Item"
                                                                                   style:UIBarButtonItemStylePlain 
                                                                                  target:self 
                                                                                  action:@selector(moveToNextItem:)];
    }
    
    self.navigationItem.hidesBackButton = hideBackButton;
    
    [super viewWillAppear:animated];
    
    if(!editing)
        [visitedTags removeAllObjects];
    
    [self.tableView reloadData];
    editing = FALSE;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(IBAction)moveToNextItem:(id)sender
{
    //next item... so jump back to item list, and tap add button...
    PVOItemSummaryController *itemController = nil;
    for (id view in [self.navigationController viewControllers]) {
        if([view isKindOfClass:[PVOItemSummaryController class]])
            itemController = view;
    }
    
    if(itemController != nil)
    {
        itemController.forceLaunchAddPopup = YES;
        //manually calling this method results in the addItem method being called before itemController's ViewDidAppear method which causes a lot of UI errors
        //        [itemController addItem:self];
        [self.navigationController popToViewController:itemController animated:YES];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [duplicatedTags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *tag = [duplicatedTags objectAtIndex:indexPath.row];
    
    NSString *currentLotNumber = [tag substringToIndex:[tag length]-3];
    NSString *currentItemNumber = [tag substringFromIndex:[tag length]-3];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOItemDetail *item = nil;
    if(currentLoad != nil)
        item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID 
                           forLotNumber:currentLotNumber 
                         withItemNumber:currentItemNumber];
    else
        item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                    forLotNumber:currentLotNumber 
                                  withItemNumber:currentItemNumber];
    
    if(item != nil)
    {
        if([visitedTags containsObject:tag])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
        Item *i = [del.surveyDB getItem:item.itemID WithCustomer:del.customerID];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", tag, i.name];
        
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"%@: NOT FOUND", tag];
    }
    
    
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
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType != UITableViewCellAccessoryNone)
    {
        editing = TRUE;
        
        currentTag = [duplicatedTags objectAtIndex:indexPath.row];
        
        NSString *currentLotNumber = [currentTag substringToIndex:[currentTag length]-3];
        NSString *currentItemNumber = [currentTag substringFromIndex:[currentTag length]-3];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOItemDetail *item = nil;
        if(currentLoad != nil)
            item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID 
                               forLotNumber:currentLotNumber 
                             withItemNumber:currentItemNumber];
        else
            item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                        forLotNumber:currentLotNumber 
                                      withItemNumber:currentItemNumber];
        
        
        //        if(item.highValueCost > 0)
        //        {
        //            [currentTag retain];
        //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"High Value/Exceptions"
        //                                                            message:@"Would you like to enter high value initials, or enter exceptions?"
        //                                                           delegate:self
        //                                                  cancelButtonTitle:@"Cancel"
        //                                                  otherButtonTitles:@"Exceptions", @"HVI Initials", nil];
        //            [alert show];
        //            
        //        }
        //        else
        {
            if(![visitedTags containsObject:currentTag])
                [visitedTags addObject:currentTag];
            
            if(currentLoad != nil)
                [del showPVODamageController:self.navigationController 
                                     forItem:item
                          showNextItemButton:NO
                                   pvoLoadID:currentLoad.pvoLoadID];
            else
                [del showPVODamageController:self.navigationController 
                                     forItem:item
                          showNextItemButton:NO
                                 pvoUnloadID:currentUnload.pvoLoadID];
        }
    }
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        if(![visitedTags containsObject:currentTag])
            [visitedTags addObject:currentTag];
        
        NSString *currentLotNumber = [currentTag substringToIndex:[currentTag length]-3];
        NSString *currentItemNumber = [currentTag substringFromIndex:[currentTag length]-3];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOItemDetail *item = nil;
        if(currentLoad != nil)
            item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID 
                               forLotNumber:currentLotNumber 
                             withItemNumber:currentItemNumber];
        else
            item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                        forLotNumber:currentLotNumber 
                                      withItemNumber:currentItemNumber];
        
        if(buttonIndex == 1)
        {
            [del showPVODamageController:self.navigationController 
                                 forItem:item
                      showNextItemButton:NO
                             pvoUnloadID:currentUnload.pvoLoadID];
        }
        else if(buttonIndex == 2)
        {
            
            if(signatureController == nil)
                signatureController = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
            
            signatureController.delegate = self;
            signatureController.saveBeforeDismiss = NO;
            
            
            sigNav = [[LandscapeNavController alloc] initWithRootViewController:signatureController];
            //sigNav.navigationBarHidden = YES;

            [self presentViewController:sigNav animated:YES completion:nil];
        }
    }
}

#pragma mark - SignatureViewControllerDelegate methods

-(UIImage*)signatureViewImage:(SignatureViewController*)sigController
{
    NSString *currentLotNumber = [currentTag substringToIndex:[currentTag length]-3];
    NSString *currentItemNumber = [currentTag substringFromIndex:[currentTag length]-3];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemDetail *item = nil;
    if(currentLoad != nil)
        item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID 
                           forLotNumber:currentLotNumber 
                         withItemNumber:currentItemNumber];
    else
        item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                    forLotNumber:currentLotNumber 
                                  withItemNumber:currentItemNumber];
    PVOHighValueInitial *pvoHVI = [del.surveyDB getPVOHighValueInitial:item.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_DEST_CUSTOMER];
    
    UIImage *img = nil;
    if(pvoHVI != nil)
    {
        img = [pvoHVI signatureData];
    }
    
    return img;
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature
{
    NSString *currentLotNumber = [currentTag substringToIndex:[currentTag length]-3];
    NSString *currentItemNumber = [currentTag substringFromIndex:[currentTag length]-3];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemDetail *item = nil;
    if(currentLoad != nil)
        item = [del.surveyDB getPVOItem:currentLoad.pvoLoadID 
                           forLotNumber:currentLotNumber 
                         withItemNumber:currentItemNumber];
    else
        item = [del.surveyDB getPVOItemForUnload:currentUnload.pvoLoadID 
                                    forLotNumber:currentLotNumber 
                                  withItemNumber:currentItemNumber];
    [del.surveyDB savePVOHighValueInitial:item.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_DEST_CUSTOMER withImage:signature];
    
    
}

@end
