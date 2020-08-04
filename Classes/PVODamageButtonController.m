//
//  PVODamageButtonController.m
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODamageButtonController.h"
#import "FourButtonCell.h"
#import "PVOConditions.h"
#import "PVOConditionEntry.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "PVOItemSummaryController.h"

#define OPTIONS_MENU_LABELS     @"Ditto", @"Comments"
#define OPTIONS_MENU_DITTO      0
#define OPTIONS_MENU_COMMENTS   1

@implementation PVODamageButtonController

@synthesize appliedTable, availableTable, details, segmentedControl, currentDamage, showNextItem;
@synthesize pvoLoadID, pvoUnloadID, delegate;
@synthesize isRiderExceptions;
@synthesize menuOptions;

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
/*PVO_DAMAGE_BUTTON_LOCATION 0
#define PVO_DAMAGE_BUTTON_CLEAR_LAST 1
#define PVO_DAMAGE_BUTTON_CLEAR_ALL 2
#define PVO_DAMAGE_BUTTON_DAMAGE*/
-(IBAction)switchViews:(id)sender
{
    UISegmentedControl *control = sender;
    
    
    if(control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_LOC_DAMAGE ||
       (control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_DONE && maxConditions == 1))
    {
        if(maxConditions > 1)
        {
            //switch the view...
            currentView = currentView == PVO_DAMAGE_BUTTON_VIEW_DAMAGE ? 
                PVO_DAMAGE_BUTTON_VIEW_LOCATION : 
                PVO_DAMAGE_BUTTON_VIEW_DAMAGE;
            
            //update the label of button index 0
            if(currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
                [segmentedControl setTitle:@"Damage" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
            else
                [segmentedControl setTitle:@"Location" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
            
        }
        else
        {
            if(control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_LOC_DAMAGE)
                currentView = PVO_DAMAGE_BUTTON_VIEW_LOCATION;
            else
                currentView = PVO_DAMAGE_BUTTON_VIEW_DAMAGE;
        }
        
        [availableTable reloadData];
    }
    else if(control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_DONE && maxConditions > 1)
    {
        if([[currentDamage locationArray] count] == 0 || [[currentDamage conditionArray] count] == 0)
            [SurveyAppDelegate showAlert:@"You must have location(s) and condition(s) entered to commit this record." withTitle:@"Location/Condition Required"];
        else
        {
            //commit the current entry...
            [self saveCurrentEntry];
            currentView = PVO_DAMAGE_BUTTON_VIEW_LOCATION;
            [segmentedControl setTitle:@"Damage" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
            [availableTable reloadData];
        }
    }
    else
    {
        if(control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_CLEAR_LAST)
            [self clearLast];
        else if(control.selectedSegmentIndex == PVO_DAMAGE_BUTTON_CLEAR_ALL)
            [self clearAll];
    }
    
    //non-momentary view type, be sure to set proper selection
    if(maxConditions == 1)
    {
        if(currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
            [control setSelectedSegmentIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
        else
            [control setSelectedSegmentIndex:PVO_DAMAGE_BUTTON_DONE];
    }
}

-(void)clearLast
{
    PVOConditionEntry *entry;
    if(![currentDamage isEmpty])
    {
        entry = currentDamage;
        
        if(entry.conditions != nil && ![entry.conditions isEqualToString:@""])
            [entry removeCondition:[[entry conditionArray] lastObject]];
        else if(entry.locations != nil && ![entry.locations isEqualToString:@""])
            [entry removeLocation:[[entry locationArray] lastObject]];
    }
    else if(details.damage != nil && [details.damage count] > 0)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        entry = [details.damage lastObject];
        
        //skip stuff
        if (isRiderExceptions && entry.damageType != DAMAGE_RIDER)
            return; //skip, not a rider exception
        else if (!isRiderExceptions && pvoUnloadID > 0 && entry.damageType != DAMAGE_UNLOADING)
            return; //skip it, not unloading damage
        else if (!isRiderExceptions && pvoUnloadID <= 0 && entry.damageType != DAMAGE_LOADING)
            return; //skip it, not loading damage
        
        //if(pvoUnloadID == 0 || entry.pvoLoadID == 0)
        {
            if(entry.conditions != nil && ![entry.conditions isEqualToString:@""])
                [entry removeCondition:[[entry conditionArray] lastObject]];
            else if(entry.locations != nil && ![entry.locations isEqualToString:@""])
                [entry removeLocation:[[entry locationArray] lastObject]];
            
            currentDamage = entry;
            
            //delete this from the dbs so it gets out of the applied table
            PVOConditionEntry *todelete = [[PVOConditionEntry alloc] init];
            todelete.pvoDamageID = entry.pvoDamageID;
            [del.surveyDB savePVODamage:todelete];
            
            [self loadItemDamages];
        }
    }
    
    [appliedTable reloadData];
}

-(void)clearAll
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are You Sure?" 
                                                    message:@"Are you sure you would like to remove all conditions for this item?" 
                                                   delegate:self 
                                          cancelButtonTitle:@"No" 
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = PVO_DAMAGE_BUTTON_CONFIRM_CLEAR_ALL;
    [alert show];
    
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [super viewDidLoad];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [segmentedControl insertSegmentWithTitle:@"CA" atIndex:1 animated:NO];
    [segmentedControl insertSegmentWithTitle:@"CL" atIndex:1 animated:NO];
    [segmentedControl setWidth:100 forSegmentAtIndex:0];
    [segmentedControl setWidth:50 forSegmentAtIndex:1];
    [segmentedControl setWidth:50 forSegmentAtIndex:2];
    [segmentedControl setWidth:100 forSegmentAtIndex:3];
    
    currentView = PVO_DAMAGE_BUTTON_VIEW_LOCATION;
    
    maxConditions = 99;
    maxLocations = 99;
    
    if ([del.pricingDB vanline] == ATLAS)
        maxConditions = 20;
    
    if(maxConditions == 1)
    {
        [segmentedControl setTitle:@"Damage" forSegmentAtIndex:PVO_DAMAGE_BUTTON_DONE];
        [segmentedControl setTitle:@"Location" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
    }
    else
    {
        [segmentedControl setTitle:@"New Cond." forSegmentAtIndex:PVO_DAMAGE_BUTTON_DONE];
        //set up the right button for Done rather than Damage
        [segmentedControl setTitle:@"Damage" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
        segmentedControl.momentary = TRUE;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int loadType = [del.surveyDB getPVOData:del.customerID].loadType;
    
    if(loadType == SPECIAL_PRODUCTS && [del.pricingDB vanline] == ATLAS)
    {
        locations = [del.surveyDB getSpecialProductDamageLocations];
        conditions = [del.surveyDB getSpecialProductDamageConditions];
    }
    else
    {
        locations = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
        conditions = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
    }

    
    if (details.cartonContentID > 0)
    {
        [SurveyAppDelegate setupViewForCartonContent:self.availableTable withTableView:nil];
        [SurveyAppDelegate setupViewForCartonContent:self.appliedTable withTableView:nil];
    }
    else
    {
        [self.availableTable setBackgroundColor:[UIColor whiteColor]];
        [self.appliedTable setBackgroundColor:[UIColor whiteColor]];
    }
    self.title = [NSString stringWithFormat:@"Item %@", details.itemNumber];
    
    //only mark as rider exceptions if coming from Warehouse and it's a received item
    PVOInventoryLoad *load = [del.surveyDB getPVOLoad:pvoLoadID];
    if ([AppFunctionality disableRiderExceptions])
        self.isRiderExceptions = NO;
    else
    {
        self.isRiderExceptions = (pvoUnloadID <= 0 && load.receivedFromPVOLocationID == WAREHOUSE && load.pvoLocationID != WAREHOUSE); //capturing rider exceptions
        self.isRiderExceptions = (self.isRiderExceptions && details.cartonContentID <= 0 &&
                                  [del.surveyDB pvoReceivableItemExists:del.customerID
                                                       withReceivedType:load.receivedFromPVOLocationID
                                                          andItemNumber:details.itemNumber
                                                           andLotNumber:details.lotNumber
                                                            andTagColor:details.tagColor]);
    }
    
    self.currentDamage = [[PVOConditionEntry alloc] init];
    currentDamage.pvoItemID = details.pvoItemID;
    currentDamage.pvoLoadID = pvoLoadID;
    currentDamage.pvoUnloadID = pvoUnloadID;
    if (self.isRiderExceptions)
        currentDamage.damageType = DAMAGE_RIDER;
    else if (pvoUnloadID > 0)
        currentDamage.damageType = DAMAGE_UNLOADING;
    else
        currentDamage.damageType = DAMAGE_LOADING;
    
    currentView = PVO_DAMAGE_BUTTON_VIEW_LOCATION;
    [segmentedControl setTitle:@"Damage" forSegmentAtIndex:PVO_DAMAGE_BUTTON_LOC_DAMAGE];
    [availableTable reloadData];
    
    menuOptions = [[NSMutableArray alloc] init];
    [menuOptions addObject:@"Next Item"];
    
    if(showNextItem) //feature 401
    {
        BOOL showComments = [AppFunctionality showCommentsOnExceptions],
                showDitto = [AppFunctionality showDittoFunctionOnExceptions:details isQuickScanScreen:NO];
        
        if(showComments && showDitto)
            [menuOptions insertObject:@"Options" atIndex:0];
        else if(showComments)
            [menuOptions insertObject:@"Comments" atIndex:0];
        else if(showDitto)
            [menuOptions insertObject:@"Ditto" atIndex:0];
        
        //fix back button if not already present
        self.navigationItem.leftBarButtonItem = nil;
        if (self.navigationItem.backBarButtonItem == nil)
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        if(menuOptions != nil && [menuOptions count] > 1)
        {
            UISegmentedControl *barButtonItem = [[UISegmentedControl alloc] initWithItems:menuOptions];
            barButtonItem.momentary = YES;
            barButtonItem.selectedSegmentIndex = -1;
            [barButtonItem addTarget:self
                              action:@selector(moveToNextItem:)
                    forControlEvents:UIControlEventValueChanged];
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:barButtonItem];
            self.navigationItem.rightBarButtonItem = item;
        }
        else
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next Item"
                                                                                       style:UIBarButtonItemStylePlain
                                                                                      target:self
                                                                                      action:@selector(moveToNextItem:)];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
        
        self.navigationItem.backBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
        //handle user trying to exit screen without clicking Done
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Done"
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(handleBackBtnClick:)];
        self.navigationItem.leftBarButtonItem = backBtn;
    }

    [self loadItemDamages];
    
    [self.appliedTable reloadData];
    
    [self scrollToBottomOfApplied];
}

-(void)loadItemDamages
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //grab damages, and sort em
    NSMutableArray *damageTypes = [[NSMutableArray alloc] init];
    [damageTypes addObject:[NSNumber numberWithInt:DAMAGE_LOADING]]; //always include Loading
    if (self.isRiderExceptions)
        [damageTypes addObject:[NSNumber numberWithInt:DAMAGE_RIDER]]; //only if we're doing Rider stuff
    else if (self.pvoUnloadID > 0)
        [damageTypes addObject:[NSNumber numberWithInt:DAMAGE_UNLOADING]]; //only if Unloading
    NSMutableArray *damages = [[NSMutableArray alloc] initWithArray:[del.surveyDB getPVOItemDamage:details.pvoItemID forDamageTypes:damageTypes]];
    [damages sortUsingComparator:^NSComparisonResult(id a, id b) {
        //sort in order of Load, Rider, Unload | then by ID
        if ((a == nil && b == nil) || a == b)
            return NSOrderedSame;
        else if (a == nil)
            return NSOrderedDescending;
        else if (b == nil)
            return NSOrderedAscending;
        else
        {
            PVOConditionEntry *first = nil, *second = nil;
            if ([a isKindOfClass:[PVOConditionEntry class]])
                first = (PVOConditionEntry*)a;
            if ([b isKindOfClass:[PVOConditionEntry class]])
                second = (PVOConditionEntry*)b;
            
            if ((first == nil && second == nil) || first == second)
                return NSOrderedSame;
            else if (first == nil)
                return NSOrderedDescending;
            else if (second == nil)
                return NSOrderedAscending;
            else
            {
                if (first.damageType == second.damageType)
                {
                    if (first.pvoDamageID == second.pvoDamageID)
                        return NSOrderedSame;
                    else if (first.pvoDamageID > second.pvoDamageID)
                        return NSOrderedDescending;
                    else
                        return NSOrderedAscending;
                }
                else if (first.damageType == DAMAGE_UNLOADING ||
                         (first.damageType == DAMAGE_RIDER && second.damageType == DAMAGE_LOADING) ||
                         second.damageType == DAMAGE_LOADING)
                    return NSOrderedDescending;
                else
                    return NSOrderedAscending;
            }
        }
    }];
    details.damage = damages;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)handleBackBtnClick:(id)sender
{
    if (showNextItem)
    {
        [self moveToNextItem:nil];
    }
    else
    {
        if([[currentDamage locationArray] count] != 0 && [[currentDamage conditionArray] count] != 0)
            [self saveCurrentEntry];
        [self.navigationController popViewControllerAnimated:TRUE]; //navigate back a screen
    }
}

-(IBAction)moveToNextItem:(id)sender
{
    UISegmentedControl *segctl = nil;
    UIBarButtonItem *button = nil;
    if([sender class] == [UISegmentedControl class])
        segctl = sender;
    else
        button = sender;
    
    if(sender == nil || button != nil || segctl.selectedSegmentIndex == 1)
    {
        //commit any record entered.
        if(![currentDamage isEmpty])
        {
            if([[currentDamage locationArray] count] == 0 || [[currentDamage conditionArray] count] == 0)
            {
                [SurveyAppDelegate showAlert:@"You must have location(s) and condition(s) entered to commit this record." withTitle:@"Location/Condition Required"];
                return;
            }
            else
                [self saveCurrentEntry];
        }
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB doneWorkingPVOItem:details.pvoItemID];
        
        if(delegate != nil && [delegate respondsToSelector:@selector(pvoDamageControllerContinueToNextItem:)] && details.cartonContentID <= 0)
            [delegate pvoDamageControllerContinueToNextItem:self];
        else if (sender != nil)
        {
            if(details.cartonContentID <= 0)
            {
                //next item... so jump back to item list, and tap add button...
                PVOItemSummaryController *itemController = nil;
                for (id view in [self.navigationController viewControllers]) {
                    if([view isKindOfClass:[PVOItemSummaryController class]])
                        itemController = view;
                }
                itemController.forceLaunchAddPopup = YES;
                [self.navigationController popToViewController:itemController animated:YES];
                
                 //addItem needs to happen after the animation is complete so thet _viewHasAppeared will be true Defect 13237
//                [itemController addItem:self];
//                [self.navigationController popToViewController:itemController animated:YES];
            
            }
            else
            {
                //next item... so jump back to item list...
                PVOCartonContentsSummaryController *ccController = nil;
                for (id view in [self.navigationController viewControllers]) {
                    if([view isKindOfClass:[PVOCartonContentsSummaryController class]])
                        ccController = view;
                }
                
                [self.navigationController popToViewController:ccController animated:YES];
                
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate]; //feature 401, mark parent high value when next item pressed on carton content
                PVOItemDetail *parentItem = [del.surveyDB getPVOItem:[del.surveyDB getPVOItemCartonContent:details.cartonContentID].pvoItemID];
                @try {
                    if(details.highValueCost > 0 && parentItem.highValueCost <= 0)
                    {
                        
                        NSString *highValueDesc = [AppFunctionality getHighValueDescription];
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:highValueDesc
                                                                        message:[NSString stringWithFormat:@"%@ items added to a carton require the carton to be designated as %@.  Please tap OK to add %@ details to this carton.", highValueDesc, highValueDesc, highValueDesc]
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil];
                        alert.tag = PVO_ITEM_ALERT_HIGH_VALUE;
                        [alert show];
                        return; //don't pop, handled by alert view delegate
                    }
                }
                @finally {
                }
            }
        }
    }
    else
    {
        NSString *action = [menuOptions objectAtIndex:0];
        
        if ([action isEqualToString:@"Options"])
        {
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Please select an option:"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:OPTIONS_MENU_LABELS, nil];
            [sheet showInView:self.view];
        }
        else if ([action isEqualToString:@"Ditto"])
        {
            [self processDitto];
        }
        else if ([action isEqualToString:@"Comments"])
        {
            [self processComments];
        }
    }
}

-(void)processDitto
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(details.highValueCost > 0)
    {        
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Ditto unavailable with %@ Items.", [AppFunctionality getHighValueDescription]] withTitle:@"Ditto Unavailable"];
        return;
    }
    
    //ditto function - prompt for quantity
    /*UIAlertView* dialog = [[UIAlertView alloc] init];
     [dialog setDelegate:self];
     [dialog setTitle:@"Enter Ditto (copy) Quantity"];
     [dialog setMessage:@" "];
     [dialog addButtonWithTitle:@"Cancel"];
     [dialog addButtonWithTitle:@"OK"];
     dialog.delegate = self;
     UITextField *nameField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 45.0, 245.0, 25.0)];
     [nameField setBackgroundColor:[UIColor whiteColor]];
     nameField.keyboardType = UIKeyboardTypeNumberPad;
     nameField.tag = DAMAGE_DITTO_QUANTITY_FIELD;
     [dialog addSubview:nameField];
     [dialog show];
     [dialog release];
     [nameField becomeFirstResponder];
     [nameField release];*/
    
    //commit any record entered.
    if(![currentDamage isEmpty])
    {
        if([[currentDamage locationArray] count] == 0 || [[currentDamage conditionArray] count] == 0)
        {
            [SurveyAppDelegate showAlert:@"You must have location(s) and condition(s) entered to commit this record." withTitle:@"Location/Condition Required"];
            return;
        }
        else
            [self saveCurrentEntry];
    }
    
    [del pushSingleFieldController:@""
                       clearOnEdit:NO
                      withKeyboard:UIKeyboardTypeNumberPad
                   withPlaceHolder:@"Ditto Quantity"
                        withCaller:self
                       andCallback:@selector(dittoQuantityEntered:)
                 dismissController:YES
                  andNavController:self.navigationController];
}

-(void)processComments
{
    //commit any record entered.
    if(![currentDamage isEmpty])
    {
        if([[currentDamage locationArray] count] == 0 || [[currentDamage conditionArray] count] == 0)
        {
            [SurveyAppDelegate showAlert:@"You must have location(s) and condition(s) entered to commit this record." withTitle:@"Location/Condition Required"];
            return;
        }
        else
            [self saveCurrentEntry];
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemComment *itemComment = [del.surveyDB getPVOItemComment:details.pvoItemID withCommentType:pvoLoadID > 0 ? COMMENT_TYPE_LOADING : COMMENT_TYPE_UNLOADING];
    
    [del pushNoteViewController:itemComment.comment
                   withKeyboard:UIKeyboardTypeASCIICapable
                   withNavTitle:@"Item Comments"
                withDescription:@"Item Comments"
                     withCaller:self
                    andCallback:@selector(doneEditingNote:)
              dismissController:YES
                       noteType:NOTE_TYPE_ITEM];
}

-(void)doneEditingNote:(NSString*)newValue
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL updateOK = [del.surveyDB savePVOItemComment:newValue withPVOItemID:details.pvoItemID withCommentType:pvoLoadID > 0 ? COMMENT_TYPE_LOADING : COMMENT_TYPE_UNLOADING];
    if (!updateOK)
    {
        NSLog(@"The comments update failed.");
    }
}

-(void)dittoQuantityEntered:(NSString*)quantity
{
    if (quantity == nil || [quantity isEqualToString:@""] || [quantity intValue] == 0)
    {
        [SurveyAppDelegate showAlert:@"A valid quantity must be entered." withTitle:@"Quantity"];
    }
    else
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB copyPVOItem:details withQuantity:[quantity intValue] includeDetails:YES];
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Item successfully copied %d times.", [quantity intValue]] withTitle:@"Success"];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(tableView == availableTable && currentView == PVO_DAMAGE_BUTTON_VIEW_DAMAGE)
		return (int) ceil([conditions count] / 4.);
	else if(tableView == availableTable && currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
		return (int) ceil([locations count] / 4.);
	else
    {
		return [details.damage count] + ((currentDamage.locations != nil || currentDamage.conditions != nil) ? 1 : 0);
    }
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{	
	if(tv == availableTable && currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
		return @"Location";
	else if(tv == availableTable && currentView == PVO_DAMAGE_BUTTON_VIEW_DAMAGE)
		return @"Condition";
	else
		return @"Noted Conditions";
	
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	return tableView == appliedTable ? 22 : 44;
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == appliedTable)
    {
        int rowHeight = 22;
        PVOConditionEntry *entry = nil;
        if(indexPath.row == [details.damage count])
            entry = currentDamage;
        else
            entry = [details.damage objectAtIndex:indexPath.row];
        
        NSString *mydamage = @"";
        for (NSString *location in [entry locationArray])
        {
            mydamage = [mydamage stringByAppendingFormat:@"%@,",
                        [PVOConditionEntry pluralizeLocation:locations
                                                     withKey:location]];
        }
        if([mydamage length] > 0 && [mydamage characterAtIndex:[mydamage length]-1] != ',')
            mydamage = [mydamage substringToIndex:[mydamage length]-1];
        
        for (NSNumber *condition in [entry conditionArray])
        {
            NSString *thisCondition = [conditions objectForKey:condition];
            mydamage = [mydamage stringByAppendingFormat:@"%@,", thisCondition];
        }
        if([mydamage length] > 0)
            mydamage = [mydamage substringToIndex:[mydamage length]-1];
        
        
        NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:mydamage attributes:
                                                 @{ NSFontAttributeName: [UIFont systemFontOfSize:18]}];
        
        //its not possible to get the cell label width since this method is called before cellForRow so best we can do
        //is get the table width and subtract the default extra space on either side of the label.
        CGSize constraintSize = CGSizeMake(tableView.frame.size.width - 30, MAXFLOAT);
        
        CGRect rect = [attributedString boundingRectWithSize:constraintSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        
        //Add back in the extra padding above and below label on table cell.
        //        rect.size.height = rect.size.height + 5;
        
        //get the current heigh that I've measured, then get the mod of the height and 22 so that I can round the height up to the nearest multiple of 22 to maintain consistent row heights
        int height = rect.size.height;
        int remainder = height % rowHeight;
        if (remainder > 0)
        {
            rect.size.height += (rowHeight - remainder);
        }
        
        //if height is smaller than a normal row set it to the normal cell height, otherwise return the bigger dynamic height.
        return (rect.size.height < rowHeight ? rowHeight : rect.size.height);
    }
    else {
        int rowHeight = 44;
        return [SurveyAppDelegate iPad] ? rowHeight * 2.4 : rowHeight;
    }
}

-(IBAction)handleEntryClick:(id)sender
{
    UIButton *btn = sender;
    NSArray *temp;
    
    if(currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION && btn.tag != -1)
    {//add to locations
        temp = [self getSortedLocationsKeys];
        
        //logic to single click add, two click plural, three click remove
        NSString *selectedKey = [temp objectAtIndex:btn.tag];
        
        if([[[currentDamage locationArray] lastObject] isEqualToString:selectedKey])
        {
            //first click, pluralize it and remove the existing
            [currentDamage removeLastLocation];
            selectedKey = [NSString stringWithFormat:@"(%@s)", selectedKey];
            [currentDamage addLocation:selectedKey];
        }
        //        else if ([[currentDamage locationArray] containsObject:selectedKey])  //defect 4418
        //        {
        //            //if it already exists, remove it
        //            [currentDamage removeLocationFromArray:selectedKey];
        //        }
        else if ([[currentDamage locationArray] containsObject:[NSString stringWithFormat:@"(%@s)", selectedKey]])
        {
            //if it already exists as a plural, remove it
            [currentDamage removeLocationFromArray:[NSString stringWithFormat:@"(%@s)", selectedKey]];
        }
        else
        {
            //add the location
            [currentDamage addLocation:selectedKey];
        }
        
        [appliedTable reloadData];
        [availableTable reloadData];
        [self scrollToBottomOfApplied];
    }
    else if(currentView == PVO_DAMAGE_BUTTON_VIEW_DAMAGE && btn.tag != -1)
    {//add to entries
        temp = [[conditions allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *thisCondition = [temp objectAtIndex:btn.tag];
        
        if([[currentDamage conditionArray] count] >= maxConditions)
        {
            [self saveCurrentEntry];
            currentView = PVO_DAMAGE_BUTTON_VIEW_LOCATION;
            if(maxConditions == 1)
                segmentedControl.selectedSegmentIndex = 0;
            [availableTable reloadData];
            return;
        }
        else if ([[currentDamage conditionArray] containsObject:thisCondition])
        {
            //if it already exists, remove it
            [currentDamage removeConditionFromArray:thisCondition];
        }
        else
        {
            //doesn't exist, add it
            [currentDamage addCondition:thisCondition];
        }
        
        [appliedTable reloadData];
        
    }
}


-(NSArray*)getSortedLocationsKeys
{
    return [[locations allKeys] sortedArrayUsingComparator:^(id firstObject, id secondObject) {
        return [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
    }];
}

-(void)saveCurrentEntry
{
    //[details.damage addObject:currentDamage];
    
    //add to database
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB savePVODamage:currentDamage];
    
    [self loadItemDamages];
    
    self.currentDamage = [[PVOConditionEntry alloc] init];
    currentDamage.pvoItemID = details.pvoItemID;
    currentDamage.pvoLoadID = pvoLoadID;
    currentDamage.pvoUnloadID = pvoUnloadID;
    if (self.isRiderExceptions)
        currentDamage.damageType = DAMAGE_RIDER;
    else if (pvoUnloadID > 0)
        currentDamage.damageType = DAMAGE_UNLOADING;
    else
        currentDamage.damageType = DAMAGE_LOADING;
    
    [appliedTable reloadData];
    
    [self scrollToBottomOfApplied];
}

-(void)scrollToBottomOfApplied
{
    int numRows = [appliedTable numberOfRowsInSection:0];
    if(numRows > 0)
    {
        [appliedTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numRows-1
                                                                inSection:0]
                            atScrollPosition:UITableViewScrollPositionBottom 
                                    animated:YES];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ReusableCell";
    static NSString *FourButtonCellIdentifier = @"FourButtonCell";
    UITableViewCell *simpleCell = nil;
    FourButtonCell *buttonsCell = nil;
    
    NSArray *allKeys;
    NSDictionary *dict;
    
    if(tableView == appliedTable)
    {
        simpleCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (simpleCell == nil) {
            simpleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            simpleCell.textLabel.numberOfLines = 0;
            
            CGRect myframe= simpleCell.frame;
            myframe.size.height = 22;
            simpleCell.frame = myframe;
        }
        
        simpleCell.accessoryType = UITableViewCellAccessoryNone;
        
        PVOConditionEntry *entry = nil;
        if(indexPath.row == [details.damage count])
            entry = currentDamage;
        else
            entry = [details.damage objectAtIndex:indexPath.row];
        
        NSString *mydamage = @"";
        for (NSString *location in [entry locationArray])
        {
            mydamage = [mydamage stringByAppendingFormat:@"%@,",
                        [PVOConditionEntry pluralizeLocation:locations
                                                     withKey:location]];
        }
        if([mydamage length] > 0 && [mydamage characterAtIndex:[mydamage length]-1] != ',')
            mydamage = [mydamage substringToIndex:[mydamage length]-1];
        
        for (NSNumber *condition in [entry conditionArray])
        {
            NSString *thisCondition = [conditions objectForKey:condition];
            if ([thisCondition length] > 0)
                mydamage = [mydamage stringByAppendingFormat:@"%@,", thisCondition];
        }
        if([mydamage length] > 0)
            mydamage = [mydamage substringToIndex:[mydamage length]-1];
        
        simpleCell.textLabel.text = mydamage;
        
        if (self.isRiderExceptions && entry.damageType == DAMAGE_LOADING)
            simpleCell.textLabel.textColor = [UIColor redColor];
        else
            simpleCell.textLabel.textColor = [UIColor blackColor];
        
    }
    else if(tableView == availableTable)
    {
        buttonsCell = (FourButtonCell *)[tableView dequeueReusableCellWithIdentifier:FourButtonCellIdentifier];
        
        if (buttonsCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FourButtonCell" owner:self options:nil];
            buttonsCell = [nib objectAtIndex:0];
            
            [buttonsCell setButtonReciever:self withSelector:@selector(handleEntryClick:)];
            
            if ([SurveyAppDelegate iOS7OrNewer])
                [buttonsCell setNormalColor:[UIColor lightGrayColor]];
            else
            {
                UIImage *buttonBackground = [[UIImage imageNamed:@"whiteButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.];
                UIImage *buttonBackgroundPressed = [[UIImage imageNamed:@"blueButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.];
                [buttonsCell setNormalImages:buttonBackground];
                [buttonsCell setHighlightedImages:buttonBackgroundPressed];
            }
        }
        if(details.cartonContentID > 0)
        {
            [buttonsCell setBackgroundColor:[SurveyAppDelegate getCartonContentBackgroundColor]];
            [buttonsCell setButtonBackgroundColor:[SurveyAppDelegate getCartonContentBackgroundColor]];
        }
        else
        {
            [buttonsCell setBackgroundColor:[UIColor whiteColor]];
            [buttonsCell setButtonBackgroundColor:[UIColor whiteColor]];
        }
        
        if(currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
        {
            dict = locations;
            allKeys = [self getSortedLocationsKeys];
        }
        else
        {
            dict = conditions;
            allKeys = [[conditions allKeys] sortedArrayUsingSelector:@selector(compare:)];
        }
        buttonsCell.cmd1.tag = indexPath.row * 4;
        buttonsCell.cmd2.tag = (indexPath.row * 4) + 1;
        buttonsCell.cmd3.tag = (indexPath.row * 4) + 2;
        buttonsCell.cmd4.tag = (indexPath.row * 4) + 3;
        
        NSString *description, *code;
        
        code = [allKeys objectAtIndex:buttonsCell.cmd1.tag];
        description = [dict objectForKey:code];
        
        [self setupPluralRemoveButtonText:&code withDescription:&description];
        [buttonsCell setupDualView:1 withTopText:code andSubText:description];
        
        if([allKeys count] > buttonsCell.cmd2.tag)
        {
            code = [allKeys objectAtIndex:buttonsCell.cmd2.tag];
            description = [dict objectForKey:code];
            [self setupPluralRemoveButtonText:&code withDescription:&description];
            [buttonsCell setupDualView:2 withTopText:code andSubText:description];
        }
        else
        {
            [buttonsCell setupDualView:2 withTopText:@"" andSubText:@""];
            buttonsCell.cmd2.tag = -1;
        }
        
        if([allKeys count] > buttonsCell.cmd3.tag)
        {
            code = [allKeys objectAtIndex:buttonsCell.cmd3.tag];
            description = [dict objectForKey:code];
            [self setupPluralRemoveButtonText:&code withDescription:&description];
            [buttonsCell setupDualView:3 withTopText:code andSubText:description];
        }
        else
        {
            [buttonsCell setupDualView:3 withTopText:@"" andSubText:@""];
            buttonsCell.cmd3.tag = -1;
        }
        
        if([allKeys count] > buttonsCell.cmd4.tag)
        {
            code = [allKeys objectAtIndex:buttonsCell.cmd4.tag];
            description = [dict objectForKey:code];
            [self setupPluralRemoveButtonText:&code withDescription:&description];
            [buttonsCell setupDualView:4 withTopText:code andSubText:description];
        }
        else
        {
            [buttonsCell setupDualView:4 withTopText:@"" andSubText:@""];
            buttonsCell.cmd4.tag = -1;
        }
        
        /*
         
         if(currentView == PVO_DAMAGE_BUTTON_LOCATION)
         allKeys = [self getSortedLocationsKeys];
         else
         allKeys = [[conditions allKeys] sortedArrayUsingSelector:@selector(compare:)];
         
         buttonsCell.cmd1.tag = indexPath.row * 4;
         [buttonsCell.cmd1 setTitle:[allKeys objectAtIndex:buttonsCell.cmd1.tag]
         forState:UIControlStateNormal];
         
         buttonsCell.cmd2.tag = (indexPath.row * 4) + 1;
         if([allKeys count] > buttonsCell.cmd2.tag)
         [buttonsCell.cmd2 setTitle:[allKeys objectAtIndex:buttonsCell.cmd2.tag]
         forState:UIControlStateNormal];
         else
         {
         [buttonsCell.cmd2 setTitle:@"" forState:UIControlStateNormal];
         buttonsCell.cmd2.tag = -1;
         }
         
         buttonsCell.cmd3.tag = (indexPath.row * 4) + 2;
         if([allKeys count] > buttonsCell.cmd3.tag)
         [buttonsCell.cmd3 setTitle:[allKeys objectAtIndex:buttonsCell.cmd3.tag]
         forState:UIControlStateNormal];
         else
         {
         [buttonsCell.cmd3 setTitle:@"" forState:UIControlStateNormal];
         buttonsCell.cmd3.tag = -1;
         }
         
         buttonsCell.cmd4.tag = (indexPath.row * 4) + 3;
         if([allKeys count] > buttonsCell.cmd4.tag)
         [buttonsCell.cmd4 setTitle:[allKeys objectAtIndex:buttonsCell.cmd4.tag]
         forState:UIControlStateNormal];
         else
         {
         [buttonsCell.cmd4 setTitle:@"" forState:UIControlStateNormal];
         buttonsCell.cmd4.tag = -1;
         }*/
        
    }
    
    
    return simpleCell != nil ? simpleCell : (UITableViewCell*)buttonsCell;
}

-(void)setupPluralRemoveButtonText:(NSString**)code withDescription:(NSString**)description
{

    //pluralize location code/descriptions if applied
    if(currentView == PVO_DAMAGE_BUTTON_VIEW_LOCATION)
    {
        if([[PVOConditionEntry depluralizeLocationCode:[[currentDamage locationArray] lastObject]] isEqualToString:*code])
        {
            if([[[currentDamage locationArray] lastObject] characterAtIndex:0] != '(')
            {
                *code = [NSString stringWithFormat:@"(%@s)", [[currentDamage locationArray] lastObject]];
                *description = [PVOConditionEntry pluralizeLocation:locations withKey:*code];
            }
            else
                *code = [NSString stringWithFormat:@"- %@", *code];
        }
    }
        
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(alertView.tag == PVO_DAMAGE_BUTTON_CONFIRM_CLEAR_ALL)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            self.currentDamage = [[PVOConditionEntry alloc] init];
            currentDamage.pvoItemID = details.pvoItemID;
            currentDamage.pvoLoadID = pvoLoadID;
            currentDamage.pvoUnloadID = pvoUnloadID;
            if (self.isRiderExceptions)
                currentDamage.damageType = DAMAGE_RIDER;
            else if (pvoUnloadID > 0)
                currentDamage.damageType = DAMAGE_UNLOADING;
            else
                currentDamage.damageType = DAMAGE_LOADING;
            
            NSMutableArray *toRemove = [[NSMutableArray alloc] init];
            for (PVOConditionEntry *entry in details.damage) {
                //skip stuff
                if (isRiderExceptions && entry.damageType != DAMAGE_RIDER)
                    continue; //skip, not a rider exception
                else if (!isRiderExceptions && pvoUnloadID > 0 && entry.damageType != DAMAGE_UNLOADING)
                    continue; //skip it, not unloading damage
                else if (!isRiderExceptions && pvoUnloadID <= 0 && entry.damageType != DAMAGE_LOADING)
                    continue; //skip it, not loading damage
                //if(pvoUnloadID == 0 || entry.pvoLoadID == 0)
                {
                    entry.conditions = @"";
                    entry.locations = @"";
                    [del.surveyDB savePVODamage:entry];
                    [toRemove addObject:entry];
                }
                
            }
            
            NSMutableArray *newArry = [NSMutableArray arrayWithArray:details.damage];
            [newArry removeObjectsInArray:toRemove];
            details.damage = newArry;
            
            [appliedTable reloadData];
        }
        else if(alertView.tag == PVO_ITEM_ALERT_HIGH_VALUE)
        {
            if (details.cartonContentID > 0)
            {
                if (buttonIndex != [alertView cancelButtonIndex])
                {
                    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                    PVOItemDetail *parentItem = [del.surveyDB getPVOItem:[del.surveyDB getPVOItemCartonContent:details.cartonContentID].pvoItemID];
                    parentItem.highValueCost = 1;
                    [del.surveyDB updatePVOItem:parentItem];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        }
        else
        {
            UITextField *nameField = (UITextField *)[alertView viewWithTag:DAMAGE_DITTO_QUANTITY_FIELD];
            if(nameField.text == nil || [nameField.text isEqualToString:@""] || [nameField.text intValue] == 0)
            {
                [SurveyAppDelegate showAlert:@"A valid quantity must be entered." withTitle:@"Quantity"];
                return;
            }
            
            //copy this item with all next numbers, and damages, carton contents, etc...
            
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            [del.surveyDB copyPVOItem:details withQuantity:[nameField.text intValue] includeDetails:YES];
            
            
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Item successfully copied %d times.", [nameField.text intValue]] withTitle:@"Success"];
        }
        
    }
}

#pragma mark - TextEditViewDelegate

- (void)textEditViewDone:(NSString *)newText tag:(int)theTag
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL updateOK = [del.surveyDB savePVOItemComment:newText withPVOItemID:details.pvoItemID withCommentType:pvoLoadID > 0 ? COMMENT_TYPE_LOADING : COMMENT_TYPE_UNLOADING];
    if (!updateOK)
    {
        NSLog(@"The comments update failed.");
    }
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
        if (buttonIndex == OPTIONS_MENU_DITTO)
            [self processDitto];
        else if (buttonIndex == OPTIONS_MENU_COMMENTS)
            [self processComments];
	}
}

@end
