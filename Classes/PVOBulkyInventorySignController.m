//
//  PVOBulkyInventorySignController.m
//  Survey
//
//  Created by Justin on 7/12/16.
//
//

#import "PVOBulkyInventorySignController.h"
#import "SurveyAppDelegate.h"

@interface PVOBulkyInventorySignController ()

@end

@implementation PVOBulkyInventorySignController

@synthesize bulkyItems, selectedbulkyItem, sigView, sigNav, pvoNavItem, singleFieldController, signatureName;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(cmdNextClick:)];
    
    self.title = @"Signatures";
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.bulkyItems = [del.surveyDB getPVOBulkyInventoryItems:del.customerID];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [bulkyItems count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SubHeaderCell";
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOBulkyInventoryItem *item = [bulkyItems objectAtIndex:indexPath.row];
    NSString *bulkyName = [del.pricingDB getPVOBulkyTypeDescription:item.pvoBulkyItemTypeID];
    NSString *subText = [item getFormattedDetails];
    
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:(pvoNavItem.reportTypeID == PVO_BULKY_INVENTORY_REPORT_ORIG ? PVO_SIGNATURE_TYPE_BULKY_INVENTORY_ORIG : PVO_SIGNATURE_TYPE_BULKY_INVENTORY_DEST) withReferenceID:item.pvoBulkyItemID];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", bulkyName];
    cell.detailTextLabel.text = subText;
    
    cell.accessoryType = sig == nil ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryCheckmark;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    selectedbulkyItem = bulkyItems[indexPath.row];
    //NSString *displayText = [NSString stringWithFormat:@"Sign for %@%@%@.",selectedVehicle.year,selectedVehicle.make,selectedVehicle.model];
    
    //need to reload this each time. This will cause the first customer name thats loaded to show on every customer
    if (singleFieldController != nil)
    {
        singleFieldController = nil;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *customerName = [NSString stringWithFormat:@"%@ %@", cust.firstName, cust.lastName];
    
    singleFieldController = [[SingleFieldController alloc] initWithStyle:UITableViewStyleGrouped];
    singleFieldController.caller = self;
    singleFieldController.callback = @selector(doneEditing:);
    singleFieldController.placeholder = @"Type Full Name Here";
    singleFieldController.title = customerName;
        
    [self.navigationController pushViewController:singleFieldController animated:YES];
}

#pragma mark - SignatureViewControllerDelegate methods

-(UIImage*)signatureViewImage:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOSignature *retval = [del.surveyDB getPVOSignature:del.customerID
                                            forImageType:(pvoNavItem.reportTypeID == PVO_BULKY_INVENTORY_REPORT_ORIG ? PVO_SIGNATURE_TYPE_BULKY_INVENTORY_ORIG : PVO_SIGNATURE_TYPE_BULKY_INVENTORY_DEST)
                                         withReferenceID:selectedbulkyItem.pvoBulkyItemID];
    
    return retval == nil ? nil : [retval signatureData];
}

-(void) doneEditing:(NSString*)newValue
{
    self.signatureName = newValue;
    if (signatureName == nil || [signatureName length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printed Name Required"
                                                        message:@"A Printed Name is required to enter a signature for the bulky item."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    if(sigView == nil)
        sigView = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
    
    sigView.title = [NSString stringWithFormat:@"Signature for %@",signatureName];
    sigView.delegate = self;
    sigView.requireSignatureBeforeSave = YES;
    sigView.sigType = (pvoNavItem.reportTypeID == PVO_BULKY_INVENTORY_REPORT_ORIG ? PVO_SIGNATURE_TYPE_BULKY_INVENTORY_ORIG : PVO_SIGNATURE_TYPE_BULKY_INVENTORY_DEST);
    sigView.saveBeforeDismiss = NO;

    sigNav = [[LandscapeNavController alloc] initWithRootViewController:sigView];
    
    [self presentViewController:sigNav animated:YES completion:nil];
}

-(NSString*)signatureViewPrintedName:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *pvoSignature = [del.surveyDB getPVOSignature:del.customerID
                                                  forImageType:(pvoNavItem.reportTypeID == PVO_BULKY_INVENTORY_REPORT_ORIG ? PVO_SIGNATURE_TYPE_BULKY_INVENTORY_ORIG : PVO_SIGNATURE_TYPE_BULKY_INVENTORY_DEST)
                                               withReferenceID:selectedbulkyItem.pvoBulkyItemID];
    
    NSString *retval = [del.surveyDB getPVOSignaturePrintedName:pvoSignature.pvoSigID];
    
    return retval;
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature
{
    [self signatureView:sigController confirmedSignature:signature withPrintedName:signatureName];
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature withPrintedName:(NSString*)printedName
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int pvoSignatureID = [del.surveyDB savePVOSignature:del.customerID
                                           forImageType:(pvoNavItem.reportTypeID == PVO_BULKY_INVENTORY_REPORT_ORIG ? PVO_SIGNATURE_TYPE_BULKY_INVENTORY_ORIG : PVO_SIGNATURE_TYPE_BULKY_INVENTORY_DEST)
                                              withImage:signature
                                        withReferenceID:selectedbulkyItem.pvoBulkyItemID];
    
    if (printedName != nil && [printedName length] > 0)
        [del.surveyDB savePVOSignaturePrintedName:printedName withPVOSignatureID:pvoSignatureID];
    
    [self.tableView reloadData];
}

@end
