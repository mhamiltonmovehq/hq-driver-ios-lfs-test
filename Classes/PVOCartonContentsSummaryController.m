//
//  PVOCartonContentsSummaryController.m
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOCartonContentsSummaryController.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "CustomerUtilities.h"
#import "PVOItemSummaryController.h"

@implementation PVOCartonContentsSummaryController

@synthesize pvoItem, tableView, wheelDamageController, buttonDamageController;
@synthesize cartonContents, selectController, toolbar, cmdContinue, hideContinueButton;
@synthesize resetVistedTags;


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
                                                                                            action:@selector(addContentItem:)];
    
}

- (void)viewDidUnload
{
    toolbar = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)addContentItem:(id)sender
{
    if (!self.viewHasAppeared)
        return;
    
    self.quickAddPopupLoaded = YES;
    
    if(selectController == nil)
        selectController = [[PVOSelectCartonContentsController alloc] initWithNibName:@"PVOSelectCartonContentsView" bundle:nil];
    selectController.title = @"Select Content";
    selectController.delegate = self;
    
    PortraitNavController *newnav = [[PortraitNavController alloc] initWithRootViewController:selectController];
    [self presentViewController:newnav animated:YES completion:nil];
}

-(IBAction)continueToDamage:(id)sender
{
    if(pvoItem.noExceptions)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB doneWorkingPVOItem:pvoItem.pvoItemID];
        //next item... so jump back to item list, and tap add button...
        PVOItemSummaryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOItemSummaryController class]])
                itemController = view;
        }
        
        itemController.forceLaunchAddPopup = YES;
        //manually calling this method results in the addItem method being called before itemController's ViewDidAppear method which causes a lot of UI errors
//        [itemController addItem:self];
        [self.navigationController popToViewController:itemController animated:YES];
    }
    else
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del showPVODamageController:self.navigationController 
                             forItem:pvoItem 
                  showNextItemButton:YES
                           pvoLoadID:pvoItem.pvoLoadID];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.cartonContents = [NSMutableArray arrayWithArray:[del.surveyDB getPVOCartonContents:pvoItem.pvoItemID withCustomerID:del.customerID]];
    
    [self.tableView reloadData];
    
    if(pvoItem.noExceptions)
        [cmdContinue setTitle:@"Next Item"];
    else
        [cmdContinue setTitle:@"Continue"];
    
       [self addContentItem:self];
    
    if (resetVistedTags)
    {
        visitedTags = [[NSMutableArray alloc] init];
    }
    resetVistedTags = NO;
    
    cmdContinue.enabled = (hideContinueButton == NO);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    contentSelected = NO;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(!self.quickAddPopupLoaded && [self.cartonContents count] == 0 && [del.surveyDB getDriverData].quickInventory) // feature 401 flow changehi
        [self addContentItem:self];
    else if (self.forceLaunchAddPopup)
        [self addContentItem:self];
    
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
    return [cartonContents count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([cartonContents count] == 0)
        return  @"Click the plus sign to add contents for this carton.";
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    }
    
    if ([AppFunctionality expandedCartonContents:[CustomerUtilities customerPricingMode]])
    {
        if (visitedTags != nil && [visitedTags containsObject:[NSNumber numberWithInt:indexPath.row]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOCartonContent *dbvalue = [cartonContents objectAtIndex:indexPath.row];
    PVOCartonContent *content = [del.surveyDB getPVOCartonContent:dbvalue.contentID withCustomerID:del.customerID];
    cell.textLabel.text = content.description;
    
    return cell;
}

#pragma mark - Table view delegate

-(BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        //remove it...
        PVOCartonContent *dbvalue = [cartonContents objectAtIndex:indexPath.row];
        SurveyAppDelegate * del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB removePVOCartonContent:dbvalue.cartonContentID withCustomerID:del.customerID];
        [cartonContents removeObject:dbvalue];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([AppFunctionality expandedCartonContents:[CustomerUtilities customerPricingMode]])
    {
        //go to the pvo item detail for this carton content...
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOCartonContent *dbvalue = [cartonContents objectAtIndex:indexPath.row];
        
        if(self.contentDetail == nil)
        {
            self.contentDetail = [[PVOItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
            self.contentDetail.title = @"Content Info";
        }
        
        self.contentDetail.item = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
        self.contentDetail.room = [del.surveyDB getRoom:pvoItem.roomID WithCustomerID:del.customerID];
        
        //add to array of visited tags used to add checkmarks to the item so the driver knows they've visited it
        if (![visitedTags containsObject:[NSNumber numberWithInt:indexPath.row]])
            [visitedTags addObject:[NSNumber numberWithInt:indexPath.row]];
        
        //get the detail for the content, if it doesn't exist, create new
        PVOItemDetail *details = [del.surveyDB getPVOCartonContentItem:dbvalue.cartonContentID];
        
        if(details == nil)
        {
            details = [[PVOItemDetail alloc] init];
            details.cartonContentID = dbvalue.cartonContentID;
            details.inventoriedAfterSignature = pvoItem.inventoriedAfterSignature;
            details.doneWorking = YES; //always flag as done
            details.pvoItemID = [del.surveyDB updatePVOItem:details];
        }
        
        //set these just for display...
        details.itemNumber = pvoItem.itemNumber;
        details.lotNumber = pvoItem.lotNumber;
        details.tagColor = pvoItem.tagColor;
        details.doneWorking = YES;
        
        self.contentDetail.pvoItem = details;
        
        
        [self.navigationController pushViewController:self.contentDetail animated:YES];
    }
}

#pragma mark  - PVOSelectCartonContentsControllerDelegate methods -

-(void)contentsController:(PVOSelectCartonContentsController*)controller selectedContent:(PVOCartonContent*)item
{
    contentSelected = YES;
    
    //[cartonContents addObject:[NSNumber numberWithInt:item.contentID]];
    SurveyAppDelegate * del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB addPVOCartonContent:item.contentID forPVOItem:pvoItem.pvoItemID];
    [self reloadData:del forPvoItem:pvoItem];
}

-(void)contentsController:(PVOSelectCartonContentsController*)controller selectedContents:(NSMutableArray *)items
{
    contentSelected = YES;
    
    SurveyAppDelegate * del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    for (NSNumber *item in items)
    {
        [del.surveyDB addPVOCartonContent:item.intValue forPVOItem:pvoItem.pvoItemID];
    }
    [self reloadData:del forPvoItem:pvoItem];
}

-(void)contentsControllerCanceled:(PVOSelectCartonContentsController*)controller
{
    contentSelected = YES;
}

#pragma mark - Helpers -
-(void)reloadData: (SurveyAppDelegate*) del forPvoItem:(PVOItemDetail*) pvoItemDetail {
    self.cartonContents = [NSMutableArray arrayWithArray:[del.surveyDB getPVOCartonContents:pvoItemDetail.pvoItemID withCustomerID:del.customerID]];
    [tableView reloadData];
}

@end
