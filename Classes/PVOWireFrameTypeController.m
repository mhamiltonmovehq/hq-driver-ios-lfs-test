//
//  PVOWireFrameTypeController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVOWireFrameTypeController.h"
#import "SurveyAppDelegate.h"
//#import "OrderDetailController.h"
#import "LandscapeNavController.h"

@interface PVOWireFrameTypeController ()

@end

@implementation PVOWireFrameTypeController
//@synthesize tableSummary/*, order*/;
//@synthesize tableWireFrameType;
@synthesize existingImagesController; //vehicle;
@synthesize isOrigin;
@synthesize delegate, wireframeItemID;
@synthesize isAutoInventory;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(cmdNextClick:)];
    
    self.title = @"Wireframe";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(getWireFrameTypes:)])
        _wireFrameTypes = [delegate getWireFrameTypes:self];
    else
        _wireFrameTypes = [[NSDictionary alloc] init];
    
    //[self.tableWireFrameType reloadData];
    //[self.tableSummary reloadData];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    //[self setTableSummary:nil];
    //[self setTableWireFrameType:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    self.picker = nil;
}

- (IBAction)cmdNextClick:(id)sender 
{
    if(_selectedWireframeTypeID == 0)
    {
        [SurveyAppDelegate showAlert:@"You must have a wireframe type selected to continue." withTitle:@"Type Required"];
        return;
    }
    
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    [del.surveyDB saveVehicle:vehicle];
    
    //call delegate method if delegate responds to Save() method to save the wireframeTypeID to that item/vehicle
    if(delegate != nil && [delegate respondsToSelector:@selector(saveWireFrameTypeIDForDelegate:)])
        [delegate saveWireFrameTypeIDForDelegate:_selectedWireframeTypeID];
    
    if(_selectedWireframeTypeID == WT_PHOTO_AUTO)
    {
        [self viewExistingPhotos];
    }
    else if (![PVOWireframeDamage wireframeTypeSupportsSingleImage:_selectedWireframeTypeID])
    {
        PVODamageSingleController *damageSingle = [[PVODamageSingleController alloc] initWithNibName:@"PVODamageSingleView" bundle:nil];
        
        damageSingle.isOrigin = isOrigin;
        damageSingle.imageId = -1;
        
        LandscapeNavController *navCtl = [[LandscapeNavController alloc] initWithRootViewController:damageSingle];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        
        //    damageSingle.vehicle = vehicle;
        damageSingle.wireframeTypeID = _selectedWireframeTypeID;
        damageSingle.wireframeItemID = wireframeItemID;
        damageSingle.isOrigin = isOrigin;
        damageSingle.isAutoInventory = isAutoInventory;
        damageSingle.viewType = -1;
        //[self.navigationController pushViewController:damageSingle animated:YES];
        
        [self presentViewController:navCtl animated:YES completion:nil];
//        [self.navigationController pushViewController:navCtl animated:YES];
    }
    else
    {
        if(damage == nil)
            damage = [[PVODamageAllController alloc] initWithNibName:@"PVODamageAllView" bundle:nil];
        
//        damage.vehicle = vehicle;
        damage.isAutoInventory = isAutoInventory;
        damage.wireframeItemID = wireframeItemID;
        damage.wireframeTypeID = _selectedWireframeTypeID;
        damage.isOrigin = isOrigin;
        
        [self.navigationController pushViewController:damage animated:YES];
    }
}

- (IBAction)cmdPreviousClick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cmdDoneClick:(id)sender
{
    
//    if(previewPDF == nil)
//        previewPDF = [[PreviewPDFController alloc] initWithNibName:@"PreviewPDF" bundle:nil];
//    previewPDF.reportTypeID = 1;
//    previewPDF.title = @"Report Preview";
//    previewPDF.order = order;
//    [self.navigationController pushViewController:previewPDF animated:YES];
    
}

-(void)viewExistingPhotos
{
    //load all images, then show dialog with them all...
    
    if(existingImagesController == nil)
        existingImagesController = [[ExistingImagesController alloc] initWithNibName:@"ExistingImagesView" bundle:nil];
    
    existingImagesController.wireframeItemID = wireframeItemID;
    existingImagesController.subID = VT_PHOTO;
    existingImagesController.photosType = IMG_PVO_VEHICLE_DAMAGES; //GET THIS FROM THE DELEGATE?
    existingImagesController.isOrigin = isOrigin;
    existingImagesController.isAutoInventory = isAutoInventory;
    
    
    [self.navigationController pushViewController:existingImagesController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if(tableView == tableSummary)
//        return 2;
//    else
        return [_wireFrameTypes count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if(tableView == tableSummary)
//        return 30;
//    else
        return 44;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    if(tableView == tableWireFrameType)
        return @"Select Wireframe Type";
//    else
//        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *RegCellIdentifier = @"RegCell";
    
    UITableViewCell *cell = nil;

    cell = [tableView dequeueReusableCellWithIdentifier:RegCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RegCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSArray *keys = [_wireFrameTypes allKeys];
    NSString *key = [keys objectAtIndex:indexPath.row];
    cell.textLabel.text = [_wireFrameTypes objectForKey:key];

    if(_selectedWireframeTypeID == [key intValue])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //uncheck fiurst, check second
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedWireframeTypeID - 1 inSection:0]];
    cell.accessoryType = UITableViewCellAccessoryNone;

    NSArray *keys = [_wireFrameTypes allKeys];
    NSString *key = [keys objectAtIndex:indexPath.row];
    _selectedWireframeTypeID = [key intValue];

    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [tableView reloadData];
    
}

#pragma mark - UIActionSheetDelegate methods


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex)
    {
        if(self.picker == nil)
        {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
        }
        BOOL show = YES;
        self.picker.allowsEditing = NO;
        
        if(buttonIndex == 0)
        {
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            else
            {
                show = NO;
                [SurveyAppDelegate showAlert:@"This device does not have a camera.  Unable to add new photo." withTitle:@"Error"];
            }
        }
        else if(buttonIndex == 1)
        {
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])// availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            else
            {
                show = NO;
                [SurveyAppDelegate showAlert:@"Unable to access photo library on this device.  Unable to add new photo." withTitle:@"Error"];
            }
        }
        
        if(show)
            [self presentViewController:self.picker animated:YES completion:nil];
        
        
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController*)imagePicker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
    
    [imagePicker dismissViewControllerAnimated:YES completion:^(void) {
        
        if(singleDamage == nil)
            singleDamage = [[PVODamageSingleController alloc] initWithNibName:@"PVODamageSingleView" bundle:nil];
        
        singleDamage.imageId = -1;
        
        LandscapeNavController *navCtl = [[LandscapeNavController alloc] initWithRootViewController:singleDamage];
        navCtl.navigationBar.barStyle = UIBarStyleBlack;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        
        singleDamage.wireframeItemID = wireframeItemID;
        singleDamage.viewType = VT_PHOTO;
        singleDamage.photo = image;
        singleDamage.isOrigin = isOrigin;
        
        [self presentViewController:navCtl animated:YES completion:nil];
        
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController*)imagePicker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

@end
