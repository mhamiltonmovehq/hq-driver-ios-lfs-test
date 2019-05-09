//
//  PVOAutoInventorySignController.m
//  MobileMover
//
//  Created by David Yost on 9/17/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVOAutoInventorySignController.h"
#import "SurveyAppDelegate.h"

@interface PVOAutoInventorySignController ()

@end

@implementation PVOAutoInventorySignController

@synthesize vehicles, selectedVehicle, sigView, sigNav, selectedItem, singleFieldController, signatureName, isOrigin, printController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(cmdNextClick:)];
    
    self.title = @"Signatures";
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.vehicles = [del.surveyDB getAllVehicles:del.customerID];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cmdNextClick:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //moved signature validation into a static method on the PVOVehicle class for use in report upload tracking
    if (![PVOVehicle verifyAllVehiclesAreSigned:del.customerID withVehicles:vehicles withIsOrigin:isOrigin])
    {
        [SurveyAppDelegate showAlert:@"All vehicles must be signed before you can generate a report." withTitle:@"Signatures Missing"];
        return;
    }
    
    if(![self verifyAllVehiclesHaveDeclaredValue])
    {
        [SurveyAppDelegate showAlert:@"You must have a declared value entered for all vehicles before you can generate a report." withTitle:@"Declared Value Missing"];
        return;
    }

    [self loadPrintScreen];
}

-(void)loadPrintScreen
{    
    if(printController == nil)
        printController = [[PreviewPDFController alloc] initWithNibName:@"PreviewPDF" bundle:nil];
    printController.pvoItem = selectedItem;
    printController.navOptionText = selectedItem.display;
    printController.useDisconnectedReports = NO;
    printController.title = @"Report Preview";
    printController.hideActionsOptions = NO;
    printController.noSignatureAllowed = YES;
    printController.pdfPath = nil;
    
    [self.navigationController pushViewController:printController animated:YES];
}

-(BOOL)verifyAllVehiclesHaveDeclaredValue
{
    for (PVOVehicle *vehicle in vehicles)
    {
        if (vehicle.declaredValue == 0)
        {
            return FALSE;
        }
    }
    
    return TRUE;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [vehicles count];
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
    
    PVOVehicle *veh = vehicles[indexPath.row];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST) withReferenceID:veh.vehicleID];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %@", veh.make, veh.model, veh.year];
    cell.detailTextLabel.text = [veh.vin length] == 0 ? @"(no VIN entered)" : veh.vin;
    cell.accessoryType = sig == nil ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryCheckmark;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    selectedVehicle = vehicles[indexPath.row];
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
                                            forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG :PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST)
                                         withReferenceID:selectedVehicle.vehicleID];
    
    return retval == nil ? nil : [retval signatureData];
}

-(void) doneEditing:(NSString*)newValue
{
    self.signatureName = newValue;
    if (signatureName == nil || [signatureName length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printed Name Required"
                                                        message:@"A Printed Name is required to enter a signature for the vehicle."
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
    sigView.sigType = (isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST);
    sigView.saveBeforeDismiss = NO;
   
    
    sigNav = [[LandscapeNavController alloc] initWithRootViewController:sigView];
    
    [self presentViewController:sigNav animated:YES completion:nil];
}

-(NSString*)signatureViewPrintedName:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *pvoSignature = [del.surveyDB getPVOSignature:del.customerID
                                                  forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST)
                                         withReferenceID:selectedVehicle.vehicleID];
    
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
                      forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST)
                         withImage:signature
                   withReferenceID:selectedVehicle.vehicleID];
    
    if (printedName != nil && [printedName length] > 0)
        [del.surveyDB savePVOSignaturePrintedName:printedName withPVOSignatureID:pvoSignatureID];
    
    [self.tableView reloadData];
}

@end
