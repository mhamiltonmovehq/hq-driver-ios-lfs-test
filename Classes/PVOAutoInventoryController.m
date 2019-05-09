//
//  PVOAutoInventoryController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVOAutoInventoryController.h"
#import "PVOBulkyDetailsController.h"
#import "SurveyAppDelegate.h"

@interface PVOAutoInventoryController ()

@end

@implementation PVOAutoInventoryController

@synthesize vehicles, vehicleEditController, wireframe, selectedVehicle, isOrigin;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addVehicle:)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"Vehicles";
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.vehicles = [del.surveyDB getAllVehicles:del.customerID];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)continueToAddVehicle
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOVehicle *newVehicle = [[PVOVehicle alloc] init];
    newVehicle.customerID = del.customerID;
    
    if (vehicleEditController == nil)
        vehicleEditController = [[PVOAutoEditViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    vehicleEditController.vehicle = newVehicle;
    vehicleEditController.isOrigin = isOrigin;
    
    [self.navigationController pushViewController:vehicleEditController animated:YES];
}

-(void)deleteVehicle:(NSIndexPath*)indexPath
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOVehicle *veh = [vehicles objectAtIndex:[indexPath row]];
    [del.surveyDB deleteVehicle:veh];
    
    self.vehicles = [del.surveyDB getAllVehicles:del.customerID];
    
    // Animate the deletion from the table.
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark Interface Button Methods

-(IBAction)addVehicle:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //check for BOL signature, ask to remove before continuing
    if ([del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG] != NULL || [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST] != NULL)
    {
        [self showRemoveBOLSignaturesAlert:AUTO_INVENTORY_ADD_VEHICLE_ALERT];
    }
    else
    {
        [self continueToAddVehicle];
    }
}

#pragma mark - Table view data source

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if([vehicles count] == 0)
        return @"Tap the plus button to add a vehicle to this auto inventory.";
    else
        return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [vehicles count];
}

//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 44;
//}

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
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %@", veh.make, veh.model, veh.year];
    cell.detailTextLabel.text = [veh.vin length] == 0 ? @"(no VIN entered)" : veh.vin;
    
    return cell;
}

-(void)showRemoveBOLSignaturesAlert:(int)tag
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"If you choose to continue, any Auto Inventory BOL signatures will be removed. Would you like to continue?"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Remove Signatures", nil];
    
    as.tag = tag;
    [as showInView:self.view];
    
}

-(void)showSignatureAppliedAlert
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"A signature has already been applied to this vehicle, if you continue to the edit vehicle screen it will remove the signature and any BOL signatures."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Remove Signature", nil];
    as.tag = AUTO_INVENTORY_SHOW_VEHICLE_SIGNATURE_ALERT;
    [as showInView:self.view];
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PVOVehicle *veh = vehicles[indexPath.row];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST) withReferenceID:veh.vehicleID];
    
    if (sig != nil)
    {
        self.selectedVehicle = veh;
        [self showSignatureAppliedAlert];
    }
    else
    {
        if (isOrigin)
        {
            if (vehicleEditController == nil)
                vehicleEditController = [[PVOAutoEditViewController alloc] initWithStyle:UITableViewStyleGrouped];
            
            vehicleEditController.vehicle = veh;
            vehicleEditController.isOrigin = isOrigin;
            
            [self.navigationController pushViewController:vehicleEditController animated:YES];
        }
        else
        {
            if(wireframe == nil)
                wireframe = [[PVOWireFrameTypeController alloc] initWithStyle:UITableViewStyleGrouped];
            
//            wireframe.vehicle = veh;
            wireframe.wireframeItemID = veh.vehicleID;
            wireframe.selectedWireframeTypeID = veh.wireframeType;
            wireframe.isOrigin = isOrigin;
            wireframe.isAutoInventory = YES;
            wireframe.delegate = self;
            
            [SurveyAppDelegate setDefaultBackButton:self];
            [self.navigationController pushViewController:wireframe animated:YES];
        }
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        deleteIndex = indexPath;
        
        //BOL signature will be removed if they delete / add a vehicle, confirm first
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG] != NULL || [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST] != NULL)
        {
            [self showRemoveBOLSignaturesAlert:AUTO_INVENTORY_DELETE_VEHICLE_ALERT];
        }
        else
        {
            [self deleteVehicle:indexPath];
        }
    }
}

#pragma mark - UIActionSheetDelegate methods


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == AUTO_INVENTORY_SHOW_VEHICLE_SIGNATURE_ALERT)
    {
        if(actionSheet.cancelButtonIndex != buttonIndex)
        {
            if (vehicleEditController == nil)
                vehicleEditController = [[PVOAutoEditViewController alloc] initWithStyle:UITableViewStyleGrouped];
            
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            selectedVehicle.damages = [NSMutableArray arrayWithArray:[del.surveyDB getVehicleDamages:selectedVehicle.vehicleID]];
            
            vehicleEditController.vehicle = selectedVehicle;
            vehicleEditController.isOrigin = isOrigin;
            
            [self.navigationController pushViewController:vehicleEditController animated:YES];
        }
    }
    else if (actionSheet.tag == AUTO_INVENTORY_ADD_VEHICLE_ALERT)
    {
        if(actionSheet.cancelButtonIndex != buttonIndex)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            //Remove sigs from any report that would be affected, Auto inventory, both BOLs and set back to dirty...
            //[del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE]; //NO NEED to delete individual vehicle signatures when one is added
            
            if (isOrigin)
            {
                [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG];
            
                //sigs were removed, so set back to dirty
                [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_ORIG forCustomer:del.customerID];
                [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_ORIG forCustomer:del.customerID];
            }
            
            [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_DEST forCustomer:del.customerID];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_DEST forCustomer:del.customerID];

            [self continueToAddVehicle];
        }
    }
    else if (actionSheet.tag == AUTO_INVENTORY_DELETE_VEHICLE_ALERT)
    {
        if(actionSheet.cancelButtonIndex != buttonIndex)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            //Remove sigs from any report that would be affected, Auto inventory, both BOLs and set back to dirty...
            //[del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE]; //NO NEED to delete individual vehicle signatures when one is added
            
            if (isOrigin)
            {
                [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG];
                [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_ORIG forCustomer:del.customerID];
                [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_ORIG forCustomer:del.customerID];
            }
            
            [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_DEST forCustomer:del.customerID];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_DEST forCustomer:del.customerID];
            
            [self deleteVehicle:deleteIndex];
        }
    }
    
    if(deleteIndex != nil)
    {
        deleteIndex = nil;
    }
}

#pragma mark - PVOWiretypeControllerDelegate methods

-(NSDictionary*)getWireFrameTypes:(id)controller
{
    //        if(indexPath.row == 0)
    //            cell.textLabel.text = @"Car";
    //        else if(indexPath.row == 1)
    //            cell.textLabel.text = @"Truck";
    //        else if(indexPath.row == 2)
    //            cell.textLabel.text = @"SUV";
    //        else if(indexPath.row == 3)
    //            cell.textLabel.text = @"Photo";

    
    //PUT THIS IN THE DB OR SOMETHING
        return [[NSDictionary alloc] initWithObjects:@[@"Car", @"Truck", @"SUV", @"Photo"]
                                             forKeys:@[[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],[NSNumber numberWithInt:3],[NSNumber numberWithInt:4]]];

}

-(void)saveWireFrameTypeIDForDelegate:(int)selectedWireframeType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    selectedVehicle.wireframeType = selectedWireframeType;
    [del.surveyDB saveVehicle:selectedVehicle];
    
}

@end
