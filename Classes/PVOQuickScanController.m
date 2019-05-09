//
//  PVOQuickScanController.m
//  Survey
//
//  Created by Tony Brame on 9/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOQuickScanController.h"
#import "SurveyAppDelegate.h"
#import "TextCell.h"
#import "PVOBarcodeValidation.h"
#import "PVOItemSummaryController.h"

@implementation PVOQuickScanController

@synthesize addedTags, exceptionsController, currentLoad;
@synthesize inventory, tboxCurrent, pvoItem, quantity, managingPhotos;
@synthesize updatePvoItemAfterQuantity;
@synthesize hideBackButtonWithScanner;

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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue"
                                                                               style:UIBarButtonItemStylePlain 
                                                                              target:self 
                                                                              action:@selector(cmdContinueSelected:)];
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!managingPhotos)
    {
        if(!inventory.usingScanner && quantity == 0)
            askingForQuantity = TRUE;
        else
            askingForQuantity = FALSE;
    }
    
    self.navigationItem.hidesBackButton = managingPhotos || (!askingForQuantity && (!inventory.usingScanner || hideBackButtonWithScanner));
    
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:self];
    [del.linea addDelegate:self];
    
    if(inventory.usingScanner && !del.socketConnected && [del.linea connstate] != CONN_CONNECTED)
        self.navigationItem.prompt = @"Scanner is not connected";
    else
        self.navigationItem.prompt = nil;
    
    if(!managingPhotos)
    {
        self.addedTags = [NSMutableArray array];
        
        visitedTags = [[NSMutableArray alloc] init];
        
        if([pvoItem.itemNumber length] != 0)
            [addedTags addObject:pvoItem];
    }
    
    managingPhotos = NO;
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(IBAction)cmdContinueSelected:(id)sender
{
    if(askingForQuantity)
    {
        quantity = [tboxCurrent.text intValue];
        if(quantity < 2)
            [SurveyAppDelegate showAlert:@"You must enter a quantity greater than one to continue." withTitle:@"Quantity Required!"];
        else
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (updatePvoItemAfterQuantity)
            {
                self.navigationItem.hidesBackButton = YES;
                pvoItem.doneWorking = YES; //done working the item
                pvoItem.pvoItemID = [del.surveyDB updatePVOItem:pvoItem];
            }
            
            for(int i = 1; i < quantity; i++)
            {
                //add all of the items, and save them
                PVOItemDetail *newItem = [self getQuickScanCopy:pvoItem];
                newItem.lotNumber = pvoItem.lotNumber;
                newItem.itemNumber = [del.surveyDB nextPVOItemNumber:del.customerID forLot:pvoItem.lotNumber];
                newItem.pvoItemID = [del.surveyDB updatePVOItem:newItem];
                if(newItem.pvoItemID != -1)
                {
                    //copy the descriptive symbols
                    [del.surveyDB duplicatePVODescriptionsForQuickScan:newItem.pvoItemID forPVOItem:pvoItem.pvoItemID];
                    [addedTags addObject:newItem];
                }
            }
            
            askingForQuantity = FALSE;
            
            [self.tableView reloadData];
        }
    }
    else
    {
        if([addedTags count] < 2)
        {
            [SurveyAppDelegate showAlert:@"You must have more than one item entered to continue." withTitle:@"Enter Items"];
            return;
        }
        
        //load up exceptions summary controller
        NSMutableArray *strings = [[NSMutableArray alloc] init];
        for (PVOItemDetail *item in addedTags)
            [strings addObject:[NSString stringWithFormat:@"%@%@", item.lotNumber, [item fullItemNumber]]];
        
        if (!inventory.noConditionsInventory)
        {
            if(exceptionsController == nil)
                exceptionsController = [[PVODelBatchExcController alloc] initWithStyle:UITableViewStylePlain];
            exceptionsController.excType = EXC_CONTROLLER_QUICK_SCAN;
            exceptionsController.title = @"Exceptions";
            exceptionsController.duplicatedTags = strings;
            exceptionsController.moveToNextItem = YES;
            exceptionsController.hideBackButton = YES;
            
            exceptionsController.currentLoad = currentLoad;
            
            
            
            [self.navigationController pushViewController:exceptionsController animated:YES];
        }
        else
        {
            [self moveToNextItem];
        }
    }
}

-(void)moveToNextItem
{
    PVOItemSummaryController *itemController = nil;
    for (id view in [self.navigationController viewControllers]) {
        if([view isKindOfClass:[PVOItemSummaryController class]])
            itemController = view;
    }
    
    if(itemController != nil)
    {
        [itemController addItem:self];
        [self.navigationController popToViewController:itemController animated:YES];
    }
}

-(PVOItemDetail*)getQuickScanCopy:(PVOItemDetail*)fromItem
{
    PVOItemDetail *newItem = [[PVOItemDetail alloc] init];
    newItem.pvoItemID = 0;
    newItem.itemID = fromItem.itemID;
    newItem.roomID = fromItem.roomID;
    newItem.pvoLoadID = fromItem.pvoLoadID;
    newItem.quantity = 1;
    newItem.itemIsDeleted = fromItem.itemIsDeleted;
    newItem.itemIsDelivered = fromItem.itemIsDelivered;
    newItem.cartonContents = fromItem.cartonContents;
    newItem.doneWorking = YES; //always flag as done
    newItem.tagColor = fromItem.tagColor;
    newItem.lotNumber = fromItem.lotNumber;
    newItem.itemNumber = fromItem.itemNumber;
    return newItem;
}

- (void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:nil];
    [del.linea removeDelegate:self];
    
    self.navigationItem.prompt = nil;
    
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
    return askingForQuantity ? 1 : [addedTags count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(askingForQuantity)
        return @"Please Enter Quantity";
    else if(inventory.usingScanner)
        return @"Please Scan Tags (tap tag to add photos)";
    else
        return @"Added Tags (tap to add photos)";
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(inventory.usingScanner)
        return @"Scan all tags to add, then tap Continue.";
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextCellIdentifier = @"TextCell";
    TextCell *textCell = nil;
    UITableViewCell *cell = nil;
    
    if(askingForQuantity)
    {
		textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
		if (textCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
			textCell = [nib objectAtIndex:0];
			[textCell.tboxValue addTarget:self 
								 action:@selector(textFieldDoneEditing:) 
					   forControlEvents:UIControlEventEditingDidEndOnExit];
            textCell.tboxValue.returnKeyType = UIReturnKeyDone;
            textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            textCell.tboxValue.font = [UIFont systemFontOfSize:17.];
		}
        
        textCell.tboxValue.placeholder = @"Quantity";
        textCell.tboxValue.text = quantity == 0 ? @"" : [[NSNumber numberWithInt:quantity] stringValue];
        self.tboxCurrent = textCell.tboxValue;
        [textCell.tboxValue becomeFirstResponder];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (visitedTags != nil && [visitedTags containsObject:[NSNumber numberWithInt:indexPath.row]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        PVOItemDetail *item = [addedTags objectAtIndex:indexPath.row];
        cell.textLabel.text = [item displayInventoryNumber];
        
    }
    
    return cell != nil ? cell : textCell;
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
    
    if (![visitedTags containsObject:[NSNumber numberWithInt:indexPath.row]])
        [visitedTags addObject:[NSNumber numberWithInt:indexPath.row]];
    
    //ask them to add photos for this item...
    PVOItemDetail *myItem = [addedTags objectAtIndex:indexPath.row];
    
    if(imageViewer == nil)
        imageViewer = [[SurveyImageViewer alloc] init];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    imageViewer.photosType = IMG_PVO_ITEMS;
    
    imageViewer.customerID = del.customerID;
    imageViewer.subID = myItem.pvoItemID;
    imageViewer.caller = self.view;
    imageViewer.viewController = self;
    [imageViewer loadPhotos];
    
    managingPhotos = YES;
}


#pragma mark - Socket Scanner delegate methods

-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = TRUE;
    self.navigationItem.prompt = nil;
}

-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = FALSE;
    self.navigationItem.prompt = @"Scanner is not connected";
}

-(void) onError:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"ScanAPI is reporting an error: %ld",result] withTitle:@"Scanner Error"];
}

-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(id<ISktScanDecodedData>) decodedData{
    
    NSString *data = [[NSString stringWithUTF8String:(const char *)[decodedData getData]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([data length] >= 6)
    {
        NSString *err = nil;
        if (![PVOBarcodeValidation validateBarcode:data outError:&err])
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid Barcode received, %@", err] withTitle:@"Invalid Barcode"];
        else
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOItemDetail *newItem = [self getQuickScanCopy:pvoItem];
            newItem.lotNumber = [data substringToIndex:[data length]-3];
            newItem.itemNumber = [data substringFromIndex:[data length]-3];
            newItem.tagColor = pvoItem.tagColor;
            newItem.pvoItemID = [del.surveyDB updatePVOItem:newItem];
            if(newItem.pvoItemID != -1)
                [addedTags addObject:newItem];
            
            //only hide back button on first successful scan
            self.navigationItem.hidesBackButton = YES;
            self.hideBackButtonWithScanner = YES;
            
            [self.tableView reloadData];
        }
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
    
}

-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(!SKTSUCCESS(result))
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error initializing ScanAPI: %ld",result] withTitle:@"Scanner Error"];
    } else {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving ScanObject:%ld",result] withTitle:@"Scanner Error"];
}


#pragma mark - LineaDelegate methods

-(void)connectionState:(int)state {
    
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
            self.navigationItem.prompt = @"Scanner is not connected";
			break;
		case CONN_CONNECTED:
            self.navigationItem.prompt = nil;
			break;
	}
}//?

-(void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
    [self barcodeData:barcode type:-1];//dont care about type...
}

-(void)barcodeData:(NSString *)barcode type:(int)type 
{
    NSString *data = barcode;
    
    if([data length] >= 6)
    {
        NSString *err = nil;
        if (![PVOBarcodeValidation validateBarcode:data outError:&err])
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid Barcode received, %@", err] withTitle:@"Invalid Barcode"];
        else
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOItemDetail *newItem = [self getQuickScanCopy:pvoItem];
            newItem.lotNumber = [data substringToIndex:[data length]-3];
            newItem.itemNumber = [data substringFromIndex:[data length]-3];
            newItem.tagColor = pvoItem.tagColor;
            newItem.pvoItemID = [del.surveyDB updatePVOItem:newItem];
            if(newItem.pvoItemID != -1)
                [addedTags addObject:newItem];
            
            //only hide back button on first successful scan
            self.navigationItem.hidesBackButton = YES;
            self.hideBackButtonWithScanner = YES;
            
            [self.tableView reloadData];
        }
    }
    else
        [SurveyAppDelegate showAlert:@"Invalid Barcode received, expected minimum of 6 characters" withTitle:@"Invalid Barcode"];
    
}

@end
