//
//  PVOEditAutoViewController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVOAutoEditViewController.h"
#import "LabelTextCell.h"

@interface PVOAutoEditViewController ()

@end

@implementation PVOAutoEditViewController

@synthesize vehicle, tboxCurrent, checkListController, isOrigin;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([SurveyAppDelegate iPad])
    {
        self.clearsSelectionOnViewWillAppear = YES;
        self.preferredContentSize = CGSizeMake(320, 416);
    }
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(save:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.title = vehicle.vehicleID == -1 ? @"New Vehicle" : @"Edit Vehicle";
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST) withReferenceID:vehicle.vehicleID];
    
    if (sig != nil)
    {
        //Remove sigs from any report that would be affected, Auto inventory, BOL and set back to dirty...
        if (isOrigin)
        {
            [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG withReferenceID:vehicle.vehicleID];
            [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_ORIG];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_ORIG forCustomer:del.customerID];
            [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_ORIG forCustomer:del.customerID];
        }

        [del.surveyDB deletePVOSignature:del.customerID forImageType: PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST withReferenceID:vehicle.vehicleID];
        [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_AUTO_INVENTORY_BOL_DEST];
        [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_INVENTORY_DEST forCustomer:del.customerID];
        [del.surveyDB pvoSetDataIsDirty:YES forType:PVO_DATA_AUTO_BOL_DEST forCustomer:del.customerID];

    }
    
    [self.tableView reloadData];
    
    [self.tableView setContentOffset:CGPointZero animated:NO];
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-(void) keyboardWillShow:(NSNotification *)note
//{
//    CGRect keyboardBounds;
//    [[note.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
//    keyboardHeight = keyboardBounds.size.height;
//    if (keyboardIsShowing == NO)
//    {
//        keyboardIsShowing = YES;
//        CGRect frame = self.view.frame;
//        frame.size.height -= keyboardHeight;
//        
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationBeginsFromCurrentState:YES];
//        [UIView setAnimationDuration:0.3f];
//        self.view.frame = frame;
//        [UIView commitAnimations];
//    }
//}
//
//-(void) keyboardWillHide:(NSNotification *)note
//{
//    if (keyboardIsShowing == YES)
//    {
//        keyboardIsShowing = NO;
//        CGRect frame = self.view.frame;
//        frame.size.height += keyboardHeight;
//        
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationBeginsFromCurrentState:YES];
//        [UIView setAnimationDuration:0.3f];
//        self.view.frame = frame;
//        [UIView commitAnimations];
//    }
//}


-(void)viewWillDisappear:(BOOL)animated
{
    
//    if(![SurveyAppDelegate iPad])
//    {
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//    }
    
    keyboardIsShowing = NO;
    
    [super viewWillDisappear:animated];
}

-(void)updateVehicleValueWithField:(UITextField*)fld
{
    if(vehicle == nil)
        return;
    
    switch (fld.tag)
    {
        case AUTO_INV_DECL_VALUE:
            vehicle.declaredValue = [fld.text doubleValue];
            break;
        case AUTO_INV_TYPE:
            vehicle.type = fld.text;
            break;
        case AUTO_INV_YEAR:
            vehicle.year = fld.text;
            break;
        case AUTO_INV_MAKE:
            vehicle.make = fld.text;
            break;
        case AUTO_INV_MODEL:
            vehicle.model = fld.text;
            break;
        case AUTO_INV_COLOR:
            vehicle.color = fld.text;
            break;
        case AUTO_INV_VIN:
            vehicle.vin = fld.text;
            break;
        case AUTO_INV_LICENSE:
            vehicle.license = fld.text;
            break;
        case AUTO_INV_LICENSE_ST:
            vehicle.licenseState = fld.text;
            break;
        case AUTO_INV_ODOMETER:
            vehicle.odometer = fld.text;
            break;

    }
    
}

#pragma mark Interface Button Methods

-(IBAction)save:(id)sender
{
    if(tboxCurrent != nil)
    {
        [self updateVehicleValueWithField:tboxCurrent];
    }
    
    if (vehicle.declaredValue == 0)
    {
        [SurveyAppDelegate showAlert:@"You must have a declared value entered to save this vehicle." withTitle:@"Declared Value Required"];
        return;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    vehicle.vehicleID = [del.surveyDB saveVehicle:vehicle];
    
    if (checkListController == nil)
        checkListController = [[PVOChecklistController alloc] initWithStyle:UITableViewStyleGrouped];
    
    checkListController.vehicle = vehicle;
    checkListController.isOrigin = isOrigin;
    
    [SurveyAppDelegate setDefaultBackButton:self];
    [self.navigationController pushViewController:checkListController animated:YES];
}


-(IBAction)cancel:(id)sender
{
    @try
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.navController popViewControllerAnimated:YES];
        
        if(tboxCurrent != nil)
        {
            [tboxCurrent resignFirstResponder];
            self.tboxCurrent = nil;
        }
    }
    @catch(NSException *exc)
    {
        [SurveyAppDelegate handleException:exc];
    }
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateVehicleValueWithField:textField];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Vehicle Details";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    LabelTextCell *ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
    if (ltCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
        ltCell = [nib objectAtIndex:0];
        
        [ltCell.tboxValue setDelegate:self];
        ltCell.tboxValue.returnKeyType = UIReturnKeyDone;
        ltCell.accessoryType = UITableViewCellAccessoryNone;
        [ltCell.tboxValue addTarget:self
                             action:@selector(textFieldDoneEditing:)
                   forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    
    ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
    ltCell.tboxValue.tag = indexPath.row;
    
    //if it wasn't created yet, go ahead and load the data to it now.
    switch (indexPath.row) {
        case AUTO_INV_DECL_VALUE:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.declaredValue == 0 ? nil : [SurveyAppDelegate formatDouble:vehicle.declaredValue withPrecision:0];
            ltCell.labelHeader.text = @"Declared Value";
            ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            [ltCell.tboxValue becomeFirstResponder];
            break;
        case AUTO_INV_TYPE:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.type;
            ltCell.labelHeader.text = @"Type";
            break;
        case AUTO_INV_YEAR:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.year;
            ltCell.labelHeader.text = @"Year";
            ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            break;
        case AUTO_INV_MAKE:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.make;
            ltCell.labelHeader.text = @"Make";
            break;
        case AUTO_INV_MODEL:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.model;
            ltCell.labelHeader.text = @"Model";
            break;
        case AUTO_INV_COLOR:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.color;
            ltCell.labelHeader.text = @"Color";
            break;
        case AUTO_INV_VIN:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.vin;
            ltCell.labelHeader.text = @"VIN";
            break;
        case AUTO_INV_LICENSE:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.license;
            ltCell.labelHeader.text = @"License";
            break;
        case AUTO_INV_LICENSE_ST:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.licenseState;
            ltCell.labelHeader.text = @"License St.";
            break;
        case AUTO_INV_ODOMETER:
            ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            ltCell.tboxValue.text = vehicle.odometer;
            ltCell.labelHeader.text = @"Odometer";
            ltCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
            break;
        default:
            break;
            
    }
    
    if(tboxCurrent == ltCell.tboxValue)
        self.tboxCurrent = nil;

    
    return (UITableViewCell*)ltCell;
}

@end
