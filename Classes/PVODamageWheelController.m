    //
//  PVOItemDetailController.m
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODamageWheelController.h"
#import "SurveyAppDelegate.h"
#import "PVOConditionEntry.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "PVOItemSummaryController.h"

#define OPTIONS_MENU_LABELS     @"Ditto", @"Comments"
#define OPTIONS_MENU_DITTO      0
#define OPTIONS_MENU_COMMENTS   1

@implementation StringKey   
@synthesize object, key;
-(NSComparisonResult) compare:(StringKey*)otherObject { return [object compare:otherObject.object]; }
@end

@implementation PVODamageWheelController

@synthesize conditionsTable;
@synthesize locationsTable, delegate;
@synthesize appliedTable, currentDamage, showNextItem, segmentedControl;

@synthesize details, conditions, locations;
@synthesize menuOptions;

@synthesize pvoLoadID;
@synthesize pvoUnloadID;
@synthesize isRiderExceptions;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    maxConditions = 99;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([del.pricingDB vanline] == ATLAS)
        maxConditions = 20;
    
//    self.conditions = [PVOConditions getConditionList];
//    self.locations = [PVOConditions getLocationList];
    
    if(maxConditions > 1)
        [segmentedControl insertSegmentWithTitle:@"New Cond." atIndex:2 animated:NO];
    
    if ([SurveyAppDelegate iOS7OrNewer])
        [segmentedControl setBackgroundColor:[UIColor whiteColor]];
    
    [super viewDidLoad];
    
    
}

-(void)handleBackBtnClick:(id)sender
{
    if (showNextItem)
        [self moveToNextItem:nil];
    else
    {
        if([[currentDamage locationArray] count] != 0 && [[currentDamage conditionArray] count] != 0)
            [self saveCurrentEntry];
        [self.navigationController popViewControllerAnimated:TRUE];
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
    {//move to next item
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
            
            if (details.cartonContentID <= 0)
            {
                //next item... so jump back to item list, and tap add button...
                PVOItemSummaryController *itemController = nil;
                for (id view in [self.navigationController viewControllers]) {
                    if([view isKindOfClass:[PVOItemSummaryController class]])
                        itemController = view;
                }
                
                itemController.forceLaunchAddPopup = YES;
                [self.navigationController popToViewController:itemController animated:YES];
                
                 //addItem needs to happen after the animation is complete so thet _viewHasAppeared will be true
//                [itemController addItem:self];
//                [self.navigationController popToViewController:itemController animated:YES];
            }
            else
            {
                //next item... so jump back to item list, and tap add button...
                PVOCartonContentsSummaryController *itemController = nil;
                for (id view in [self.navigationController viewControllers]) {
                    if([view isKindOfClass:[PVOCartonContentsSummaryController class]])
                        itemController = view;
                }
                
                [self.navigationController popToViewController:itemController animated:YES];
                
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate]; //feature 401, mark parent when next item pressed on carton content
                PVOItemDetail *parentItem = [del.surveyDB getPVOItem:[del.surveyDB getPVOItemCartonContent:details.cartonContentID].pvoItemID];
                @try {
                    if(details.highValueCost > 0 && parentItem.highValueCost <= 0)
                    {
                        NSString *highValueDesc = [AppFunctionality getHighValueDescription];
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"%@"
                                                                        message:[NSString stringWithFormat: @"%@ items added to a carton require the carton to be designated as %@.  Please tap OK to add %@ details to this carton.", highValueDesc, highValueDesc, highValueDesc]
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil];
                        alert.tag = PVO_ITEM_ALERT_HIGH_VALUE;
                        [alert show];
                        return; //don't pop, handled by alert view delegate
                    }
                }
                @finally {
                    parentItem = nil;
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
        NSString *value = [AppFunctionality getHighValueDescription];
        
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Ditto unavailable with %@ Items.", value] withTitle:@"Ditto Unavailable"];
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

-(void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int loadType = [del.surveyDB getPVOData:del.customerID].loadType;
    
    if(loadType == SPECIAL_PRODUCTS && [del.pricingDB vanline] == ATLAS)
    {
        self.conditions = [del.surveyDB getSpecialProductDamageConditions];
        self.locations = [del.surveyDB getSpecialProductDamageLocations];
    }
    else
    {
        self.conditions = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
        self.locations = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
    }
    
    if (details.cartonContentID > 0)
    {
        [SurveyAppDelegate setupViewForCartonContent:self.appliedTable withTableView:nil];
        [SurveyAppDelegate setupViewForCartonContent:self.conditionsTable withTableView:nil];
        [SurveyAppDelegate setupViewForCartonContent:self.locationsTable withTableView:nil];
    }
    else
    {
        [SurveyAppDelegate removeCartonContentColorFromView:self.appliedTable];
        [SurveyAppDelegate removeCartonContentColorFromView:self.conditionsTable];
        [SurveyAppDelegate removeCartonContentColorFromView:self.locationsTable];
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
    
    [self loadItemDamages];
    
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
            barButtonItem.segmentedControlStyle = UISegmentedControlStyleBar;
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

    [self.appliedTable reloadData];
    [self.locationsTable reloadData];
    [self.conditionsTable reloadData];
    
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

-(void)viewWillDisappear:(BOOL)animated
{         
    [super viewWillDisappear:animated];
}

-(NSArray*)getSortedKeysForStringDict:(NSDictionary*)mydict
{
    NSMutableArray *myStringKeys = [[NSMutableArray alloc] init];
    StringKey *current;
    NSArray *keys = [mydict allKeys];
    NSString *currentObject;
    for (NSString *currentKey in keys) {
        currentObject = [mydict objectForKey:currentKey];
        current = [[StringKey alloc] init];
        current.object = currentObject;
        current.key = currentKey;
        [myStringKeys addObject:current];
    }
    
    NSArray *sortedStringKeys = [myStringKeys sortedArrayUsingSelector:@selector(compare:)];
    
    myStringKeys = [[NSMutableArray alloc] init];
    for (StringKey *sk in sortedStringKeys) {
        [myStringKeys addObject:sk.key];
    }
    
    return myStringKeys;
}


-(IBAction)didEndEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(IBAction)clearAction:(id)sender
{
    UISegmentedControl *control = sender;
    
    if(control.selectedSegmentIndex == PVO_DAMAGE_WHEEL_CLEAR_LAST)
        [self clearLast];
    else if(control.selectedSegmentIndex == PVO_DAMAGE_WHEEL_CLEAR_ALL)
        [self clearAll];
    else if(control.selectedSegmentIndex == PVO_DAMAGE_WHEEL_DONE)
    {
        if([[currentDamage locationArray] count] == 0 || [[currentDamage conditionArray] count] == 0)
            [SurveyAppDelegate showAlert:@"You must have location(s) and condition(s) entered to commit this record." withTitle:@"Location/Condition Required"];
        else
        {
            [self saveCurrentEntry];
            [appliedTable reloadData];
            [locationsTable reloadData];
            [conditionsTable reloadData];
            [self scrollToBottomOfApplied];
        }
    }
}

-(void)clearLast
{
    PVOConditionEntry *entry;
    if(![currentDamage isEmpty])
    {
        entry = currentDamage;
        
        if(entry.conditions != nil && ![entry.conditions isEqualToString:@""])
            [entry removeLastCondition];
        else if(entry.locations != nil && ![entry.locations isEqualToString:@""])
            [entry removeLastLocation];
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
                [entry removeLastCondition];
            else if(entry.locations != nil && ![entry.locations isEqualToString:@""])
                [entry removeLastLocation];
            
            currentDamage = entry;
            
            //delete this from the dbs so it gets out of the applied table
            PVOConditionEntry *todelete = [[PVOConditionEntry alloc] init];
            todelete.pvoDamageID = entry.pvoDamageID;
            [del.surveyDB savePVODamage:todelete];
            
            [self loadItemDamages];
            [conditionsTable reloadData];
            [locationsTable reloadData];
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
    alert.tag = PVO_DAMAGE_CONFIRM_CLEAR_ALL;
    [alert show];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(tableView == conditionsTable)
        return [conditions count];
    else if(tableView == locationsTable)
        return [locations count];
    else
        return [details.damage count] + ([currentDamage isEmpty] ? 0 : 1);
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{    
    
    if(tv == conditionsTable)
        return @"Conditions";
    else if(tv == locationsTable)
        return @"Locations";
    else
        return @"Noted Conditions";
    
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return tableView == appliedTable ? 22 : 30;
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
            if ([thisCondition length] > 0)
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
    else
        return 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ReusableCell";
    UITableViewCell *simpleCell = nil;
    
    simpleCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (simpleCell == nil) {
        simpleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        simpleCell.textLabel.numberOfLines = 0;
        
        CGRect myframe= simpleCell.frame;
        myframe.size.height = tableView == appliedTable ? 22 : 30;
        simpleCell.frame = myframe;
    }
    
    simpleCell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray *allKeys;
    
    if(tableView == conditionsTable)
    {
        allKeys = [self getSortedKeysForStringDict:conditions];
        
        simpleCell.textLabel.text = [conditions objectForKey:[allKeys objectAtIndex:indexPath.row]];
        
        //check if it exists...
        //        for (NSString *condKey in [currentDamage conditionArray]) {
        //            if([condKey isEqualToString:[allKeys objectAtIndex:indexPath.row]])
        //                simpleCell.accessoryType = UITableViewCellAccessoryCheckmark;
        //        }
    }
    else if(tableView == locationsTable)
    {
        allKeys = [self getSortedKeysForStringDict:locations];
        
        simpleCell.textLabel.text = [locations objectForKey:[allKeys objectAtIndex:indexPath.row]];
        
        //check if it exists...
        for (NSString *locKey in [currentDamage locationArray]) {
            if([[PVOConditionEntry depluralizeLocationCode:locKey] isEqualToString:[allKeys objectAtIndex:indexPath.row]])
            {
                //                simpleCell.accessoryType = UITableViewCellAccessoryCheckmark;
                simpleCell.textLabel.text = [PVOConditionEntry pluralizeLocation:locations withKey:locKey];
            }
        }
        
        if([[[currentDamage locationArray] lastObject] isEqualToString:[allKeys objectAtIndex:indexPath.row]])
            simpleCell.textLabel.text = [PVOConditionEntry pluralizeLocation:locations
                                                                     withKey:[NSString stringWithFormat:@"(%@s)", [allKeys objectAtIndex:indexPath.row]]];
        
    }
    else if(tableView == appliedTable)
    {
        
        PVOConditionEntry *entry = nil;
        
        if(indexPath.row == [details.damage count])
            entry = currentDamage;
        else
            entry = [details.damage objectAtIndex:indexPath.row];
        
        NSString *mydamage = @"";
        for (NSString *location in [entry locationArray])
        {
            //NSString *thislocation = [locations objectForKey:];
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
        
        simpleCell.textLabel.text = mydamage;
        
        if (self.isRiderExceptions && entry.damageType == DAMAGE_LOADING)
            simpleCell.textLabel.textColor = [UIColor redColor];
        else
            simpleCell.textLabel.textColor = [UIColor blackColor];
        
    }
    
    
    return simpleCell;
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *temp;
    if (tableView == conditionsTable)
    {
        temp = [self getSortedKeysForStringDict:conditions];
        //temp = [[conditions allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *thisCondition = [temp objectAtIndex:indexPath.row];
        
        if ([[currentDamage conditionArray] containsObject:thisCondition])
        {
            //already entered, remove it
            [currentDamage removeConditionFromArray:thisCondition];
        }
        else
        {
            //doesn't exist, add it
            [currentDamage addCondition:thisCondition];
        }
        
        if([[currentDamage conditionArray] count] >= maxConditions)
        {
            [self saveCurrentEntry];
            [locationsTable reloadData];
            [conditionsTable reloadData];
            [self scrollToBottomOfApplied];
        }
        
        [locationsTable reloadData];
        [appliedTable reloadData];
        [self scrollToBottomOfApplied];
    }
    else if(tableView == locationsTable)
    {//add or remove the location to selected locations
        
        temp = [self getSortedKeysForStringDict:locations];
        
        NSString *selectedKey = [temp objectAtIndex:indexPath.row];
        
        if([[[currentDamage locationArray] lastObject] isEqualToString:selectedKey])
        {
            //first click, pluralize it and remove the existing
            [currentDamage removeLastLocation];
            selectedKey = [NSString stringWithFormat:@"(%@s)", selectedKey];
            [currentDamage addLocation:selectedKey];
        }
        //        else if ([[currentDamage locationArray] containsObject:selectedKey]) //defect 4418
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
        
        [locationsTable reloadData];
        [appliedTable reloadData];
        [self scrollToBottomOfApplied];
        
    }
}




- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(alertView.tag == PVO_DAMAGE_CONFIRM_CLEAR_ALL)
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
            [conditionsTable reloadData];
            [locationsTable reloadData];
            
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
