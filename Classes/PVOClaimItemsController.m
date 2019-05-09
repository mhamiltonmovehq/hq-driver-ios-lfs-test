//
//  PVOClaimItemsController.m
//  Survey
//
//  Created by Tony Brame on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOClaimItemsController.h"
#import "SurveyAppDelegate.h"
#import "SyncGlobals.h"
#import "XMLWriter.h"
#import "PVOPrintController.h"

@implementation PVOClaimItemsController

@synthesize items, manualController, objectSelectController;
@synthesize claim, tableView, scannerView, claimItemController, printController;

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self 
                                                                                            action:@selector(cmdAdd_Click:)];
    
    self.title = @"Claim Items";
    
}

-(IBAction)cmdAdd_Click:(id)sender
{
    //SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Entry Method" 
                                                    delegate:self 
                                           cancelButtonTitle:@"Cancel" 
                                      destructiveButtonTitle:nil 
                                           otherButtonTitles:@"Pick From List", @"Manual Entry", @"External Scanner", @"Camera Scanner", nil];
    as.delegate = self;
    
    [as showInView:self.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.items = [NSMutableArray arrayWithArray:[del.surveyDB getPVOClaimItems:claim.pvoClaimID]];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(IBAction)cmdClaimComplete_Click:(id)sender
{
    //load the report...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.currentPVOClaimID = claim.pvoClaimID;

    if(printController == nil)
        printController = [[PreviewPDFController alloc] initWithNibName:@"PreviewPDF" bundle:nil];
    
    PVONavigationListItem *item = [[PVONavigationListItem alloc] init];
    item.signatureIDs = [NSString stringWithFormat:@"%d", PVO_SIGNATURE_TYPE_CLAIM];
    item.reportTypeID = CLAIMS_FORM;
    printController.pvoItem = item;
    
    printController.title = @"Report Preview";
    printController.hideActionsOptions = NO;
    [self.navigationController pushViewController:printController animated:YES];    
}

-(BOOL)checkForComplete
{
    BOOL retval = FALSE;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_CLAIM];
    retval = sig != nil;
    
    if(retval)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?" 
                                                        message:@"The customer's signature has been entered, and will need to be removed in order to continue, would you like to proceed?" 
                                                       delegate:self 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
    return retval;
}

-(void)loadClaimItem:(PVOClaimItem*)claimItem
{
    newClaimItem = claimItem;
    
    if([self checkForComplete])
        return;
    
    creatingNewItem = FALSE;
    //go to claim item detail...
    if(claimItemController == nil)
        claimItemController = [[PVOClaimItemDetailController alloc] initWithStyle:UITableViewStyleGrouped];
    claimItemController.item = claimItem;
    [self.navigationController pushViewController:claimItemController animated:YES];
}

-(void)itemNumberEntered:(NSString*)value
{
    if(value == nil || value.length != 3)
        [SurveyAppDelegate showAlert:@"An invalid item number has been entered, a three digit item number is required." withTitle:@"Invalid Number"];
    else
        [self itemNumberEntered:value withLotNumber:nil];
}

-(BOOL)itemNumberEntered:(NSString*)value withLotNumber:(NSString*)lotNumber
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOItemDetail *pid = [del.surveyDB getPVOItemForCustID:del.customerID forLotNumber:lotNumber withItemNumber:value];
    
    if(pid == nil)
    {
        [SurveyAppDelegate showAlert:@"Unable to find item." withTitle:@"Item Not Found"];
        return FALSE;
    }
    else
        [self addItemToClaim:pid];
    
    return TRUE;
}

-(void)addItemToClaim:(PVOItemDetail*)pvoItem
{
    //there is a dif view controller on the stack (currently this only applies to manual entry (single view controller)
    if([self.navigationController topViewController] != self)
        [self.navigationController popViewControllerAnimated:NO];
    
    for (PVOClaimItem *pci in items) {
        if(pci.pvoItemID == pvoItem.pvoItemID)
        {
            [SurveyAppDelegate showAlert:@"Item already exists in claim." withTitle:@"Item Exists"];
            return;
        }
    }
    
    creatingNewItem = TRUE;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOClaimItem *newItem = [[PVOClaimItem alloc] init];
    newItem.pvoClaimID = claim.pvoClaimID;
    newItem.pvoItemID = pvoItem.pvoItemID;
	Item *i = [del.surveyDB getItem:pvoItem.itemID WithCustomer:del.customerID];
    newItem.estimatedWeight = (int)(i.cube * 7.0);
    newItem.pvoClaimItemID = [del.surveyDB savePVOClaimItem:newItem];
    [items addObject:newItem];
    
    [self loadClaimItem:newItem];
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
    return [items count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([items count] == 0)
        return @"Tap the plus button to add an item to this claim.";
    else 
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOClaimItem *claimItem = [items objectAtIndex:indexPath.row];
	PVOItemDetail *pid = [del.surveyDB getPVOItem:claimItem.pvoItemID];
	Item *i = [del.surveyDB getItem:pid.itemID WithCustomer:del.customerID];
    
	cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", 
                           pid.itemNumber == nil ? @" - no tag - " : pid.itemNumber, 
                           i.name];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOClaimItem *claimItem = [items objectAtIndex:indexPath.row];
        [del.surveyDB deletePVOClaimItem:claimItem.pvoClaimItemID];
        [items removeObject:claimItem];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PVOClaimItem *claimItem = [items objectAtIndex:indexPath.row];
    [self loadClaimItem:claimItem];
}

#pragma mark - UIActionSheetDelegate methods

//@"Pick From List", @"Manual Entry", @"Scanner"
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if(buttonIndex == 0)
        {//pick list
            //load up all in a select item controller?  order by item number, display lot/item number, description
            if(objectSelectController == nil)
                objectSelectController = [[SelectObjectController alloc] initWithStyle:UITableViewStylePlain];
            objectSelectController.delegate = self;
            objectSelectController.multipleSelection = NO;
            
            NSArray *allitems = [del.surveyDB getPVOAllItems:del.customerID];
            if([allitems count] == 0)
            {
                [SurveyAppDelegate showAlert:@"No Items Found" withTitle:@"No Items"];
                return;
            }
            
            objectSelectController.choices = [allitems sortedArrayUsingSelector:@selector(compareWithItemNumberAndLot:)];
            objectSelectController.title = @"Select Item";
            objectSelectController.displayMethod = @selector(displayInventoryNumberAndItemName);
            newNav = [[PortraitNavController alloc] initWithRootViewController:objectSelectController];
            [self presentViewController:newNav animated:YES completion:nil];
        }
        else if(buttonIndex == 1)
        {//manual entry
            if(manualController == nil)
                manualController = [[SingleFieldController alloc] initWithStyle:UITableViewStyleGrouped];
            
            manualController.caller = self;
            manualController.callback = @selector(itemNumberEntered:);
            manualController.destString = @"";
            manualController.placeholder = @"Item Number (NNN)";
            manualController.keyboard = UIKeyboardTypeNumberPad;
            manualController.dismiss = NO;
            
            [self.navigationController pushViewController:manualController animated:YES];
        }
        else if(buttonIndex == 2)
        {//scanner
            //wait screen for scan/and a cancel button
            if(scannerView == nil)
                scannerView = [[ScannerInputView alloc] init];
            scannerView.delegate = self;
            [scannerView waitForInput];
        }
        else if(buttonIndex == 3)
        {//camera
            //wait screen for scan/and a cancel button
            if(zbar == nil)
                zbar = [ZBarReaderViewController new];
            zbar.readerDelegate = self;
            [self presentViewController:zbar animated:YES completion:nil];
        }
    }
}

#pragma mark - ScannerInputViewDelegate methods

-(void)scannerInput:(ScannerInputView *)scannerView withValue:(NSString *)scannerValue
{
    if([scannerValue length] >= 6)
    {
        NSString *lotNumber = [scannerValue substringToIndex:[scannerValue length]-3];
        NSString *itemNumber = [scannerValue substringToIndex:[scannerValue length]-3];
        [self itemNumberEntered:itemNumber withLotNumber:lotNumber];
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
}

#pragma mark - SelectObjectControllerDelegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    [self addItemToClaim:(PVOItemDetail*)[collection objectAtIndex:0]];
}

-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller
{
    return YES;
}

#pragma mark - ZBarReaderDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    NSString *barcode = nil;
    for(ZBarSymbol *symbol in results)
    {
        if(barcode != nil)
            barcode = nil;
        else
            barcode = [NSString stringWithString:symbol.data];
        
    }
    
    if(barcode != nil && [barcode length] >= 6)
    {
        NSString *lotNumber = [barcode substringToIndex:[barcode length]-3];
        NSString *itemNumber = [barcode substringToIndex:[barcode length]-3];
        [self itemNumberEntered:itemNumber withLotNumber:lotNumber];
    }
    else if(barcode == nil)
        [SurveyAppDelegate showAlert:@"Invalid or more than one barcode received, please re-scan, and be sure to only scan one barcode." withTitle:@"Invalid Barcode"];
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    zbar = nil;
}

#pragma mark - UIAlertViewDelegate methods


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        //load it up and delete sig
        [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_CLAIM];
        [self loadClaimItem:newClaimItem];
    }
    else if(creatingNewItem)
    {
        //delete and remove
        [del.surveyDB deletePVOClaimItem:newClaimItem.pvoClaimItemID];
        self.items = [NSMutableArray arrayWithArray:[del.surveyDB getPVOClaimItems:claim.pvoClaimID]];
        [self.tableView reloadData];
        creatingNewItem = FALSE;
    }
}

@end
