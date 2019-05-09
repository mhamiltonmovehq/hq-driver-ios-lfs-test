//
//  PVODamageSingleController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVODamageSingleController.h"
#import "SurveyAppDelegate.h"
#import "SurveyImageViewer.h"
#import "PVOAutoInventoryController.h"
#import "PVOBulkyInventoryController.h"

@interface PVODamageSingleController ()

@end

@implementation PVODamageSingleController
@synthesize tableDamages;
@synthesize viewDamage;
@synthesize switchHighPriority;
@synthesize labelCurrentDamages;
@synthesize viewDamageDetails;

@synthesize tableSummary, viewType, imageId;
@synthesize imgSingle;
//@synthesize vehicle;
@synthesize photo;
@synthesize isOrigin;
@synthesize wireframeItemID;
@synthesize wireframeTypeID;
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain
                                                                             target:self 
                                                                             action:@selector(cmdBackClick:)];


    if (viewType != VT_PHOTO)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Images"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(cmdImagesClick:)];
    }

    self.title = @"Damages";
    allDamages = [PVOWireframeDamage getAllDamages];
    
    [SurveyAppDelegate minimizeTableHeaderAndFooterViews:self.tableDamages];
    [SurveyAppDelegate minimizeTableHeaderAndFooterViews:self.tableSummary];
}

-(IBAction)segmentIndexChanged:(id)sender
{
    UISegmentedControl *ctl = sender;
    
    if(ctl.selectedSegmentIndex == 0)
        [self cmdImagesClick:sender];
    else
    {
        //enter commetns
        if(comments == nil)
            comments = [[PVOCommentsController alloc] initWithNibName:@"PVOCommentsView" bundle:nil];
        
        PVOWireframeDamage *d = [PVOWireframeDamage getDamageAtLocation:damageLocation withDamageList:self.damages forType:viewType andVehicleID:wireframeItemID withImageID:imageId];
        
        comments.delegate = self;
        comments.title = @"Comments";
        comments.tboxComments.text = d.comments;
        
        [self.navigationController pushViewController:comments animated:YES];
    }
}

-(IBAction)commentsClicked:(id)sender
{
    //enter commetns
    if(comments == nil)
        comments = [[PVOCommentsController alloc] initWithNibName:@"PVOCommentsView" bundle:nil];
    
    PVOWireframeDamage *d = [PVOWireframeDamage getDamageAtLocation:damageLocation withDamageList:self.damages forType:viewType andVehicleID:wireframeItemID withImageID:imageId];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    NoteViewController *noteController = [[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped];
    noteController.caller = self;
    noteController.callback = @selector(commentEntered:);
    noteController.destString = (d.comments == nil ? @"" : d.comments);
    noteController.description = @"Comments";
    noteController.navTitle = @"Comments";
    noteController.keyboard = UIKeyboardTypeASCIICapable;
    noteController.dismiss = YES;
    noteController.modalView = YES;
    noteController.noteType = NOTE_TYPE_NONE;
    noteController.maxLength = -1;
    
    PortraitNavController *navCtl = [[PortraitNavController alloc] initWithRootViewController:noteController];
    
    [self presentViewController:navCtl animated:YES completion:nil];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //see if we are in the image...  app it always is
    if(!pickingDamage)
    {
        
        UITouch *touch = [touches anyObject];
        
        //translate touch to location on image...
        damageLocation = [PVOWireframeDamage translateLocationInViewToLocationInImage:[touch locationInView:self.imgSingle]
                                                                    withViewSize:imgSingle.frame.size 
                                                                         andImage:imgSingle.image];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Comments"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(commentsClicked:)];
        pickingDamage = YES;
        tableDamages.hidden = NO;
        viewDamage.hidden = YES;
        viewDamageDetails.hidden = NO;
        [tableSummary reloadData];
        [tableDamages reloadData];
        
        [self updateCurrentDamagesLabel];
    }
    
    [super touchesEnded:touches withEvent:event];
}

-(NSString*)descriptionForCode:(NSString*)code
{
    for (PVOWireframeDamage *d in allDamages) {
        if([d.damageAlphaCodes isEqualToString:code])
            return d.description;
    }
    
    return @"";
}

-(void)updateCurrentDamagesLabel
{
    labelCurrentDamages.text = @" - No Damages -";
    
    if([self.damages count] > 0)
    {
        for (PVOWireframeDamage *d in self.damages)
        {
            float xDiff = fabs(d.damageLocation.x - damageLocation.x);
            float yDiff = fabs(d.damageLocation.y - damageLocation.y);
            
            //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
            if(xDiff < 0.001 && yDiff < 0.001 && d.locationType == viewType)
            {
                for (NSString *dmg in [d.damageAlphaCodes componentsSeparatedByString:@","])
                {
                    if(![labelCurrentDamages.text isEqualToString:@" - No Damages -"])
                        labelCurrentDamages.text = [labelCurrentDamages.text stringByAppendingFormat:@", %@", [self descriptionForCode:dmg]];
                    else
                        labelCurrentDamages.text = [self descriptionForCode:dmg];
                }
                break;
            }
        }
    }
}

-(void)removeDamageButtons
{
    for (id sv in viewDamage.subviews) {
        if([sv isKindOfClass:[UIButton class]])
            [sv removeFromSuperview];
    }
}

-(void)loadDamageButtons
{
    //loop through all, add only unique locations
    //show all damages, not just the working set....
    //NSArray *damages = order.inspectionType == IT_DESTINATION_BOL ? [order destinationDamages] : [order originDamages];
//    PVOVehicle *deleteThis = [[PVOVehicle alloc] init];
//    deleteThis.wireframeType = 1;
    NSArray *damages = (isOrigin ? [PVOWireframeDamage originDamages:self.damages] : [PVOWireframeDamage destinationDamages:self.damages]);
    for (PVOWireframeDamage *d in damages) {
        
        if(d.locationType == viewType)
        {
            //create button at location...
            //UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            //CGRect myframe = btn.frame;
         
            
            UIImage *image = [UIImage imageNamed:@"dmg_indicator.png"];
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect myframe = CGRectMake(44.0, 44.0, image.size.width, image.size.height);
            btn.frame = myframe;
            [btn setBackgroundImage:image forState:UIControlStateNormal];
            
            
            
            
            //show it at the view's location rather than in image location...
            myframe.origin = [PVOWireframeDamage translateLocationInImageToLocationInView:d.damageLocation
                                                                        withViewSize:imgSingle.frame.size 
                                                                             andImage:imgSingle.image];
            
            btn.frame = myframe;//add action and id button?  loc ids.
            
            [btn addTarget:self action:@selector(cmdDamageClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [viewDamage addSubview:btn];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //make this generic so it can just call getWireframeDamages and send the itemID(vehicleid) and hte wireframe typeid
    self.damages =  [NSMutableArray arrayWithArray:[del.surveyDB getWireframeDamages:wireframeItemID withImageID:imageId withIsVehicle:isAutoInventory]];
    
    //may need to happen after?
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
//    PVOVehicle *deleteThis = [[PVOVehicle alloc] init];
//    deleteThis.wireframeType = 1;
    if(photo != nil)
        imgSingle.image = photo;
    else if (![PVOWireframeDamage wireframeTypeSupportsSingleImage:wireframeTypeID])
        //These items dont have All/Single images that follow the exact format required to go from the all image to the "zoomed" image
        imgSingle.image = [PVOWireframeDamage allImage:wireframeTypeID];
    else if(viewType == VT_FRONT)
        imgSingle.image = [PVOWireframeDamage frontImage:wireframeTypeID];
    else if(viewType == VT_TOP)
        imgSingle.image = [PVOWireframeDamage topImage:wireframeTypeID];
    else if(viewType == VT_LEFT)
        imgSingle.image = [PVOWireframeDamage leftImage:wireframeTypeID];
    else if(viewType == VT_RIGHT)
        imgSingle.image = [PVOWireframeDamage rightImage:wireframeTypeID];
    else if(viewType == VT_REAR)
        imgSingle.image = [PVOWireframeDamage rearImage:wireframeTypeID];
    
    [tableSummary reloadData];
    [self removeDamageButtons];
    
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadDamageButtons];
}


-(void)viewWillDisappear:(BOOL)animated
{    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    //make this generic so it can just call getWireframeDamages and send the itemID(vehicleid) and hte wireframe typeid
    [del.surveyDB savePVOWireframeDamages:self.damages forWireframeItemID:wireframeItemID withImageID:imageId withIsVehicle:isAutoInventory];
    
    [super viewWillDisappear:animated];
}

-(IBAction)cmdBackClick:(id)sender
{
    if(pickingDamage)
    {
        pickingDamage = NO;
        tableDamages.hidden = YES;
        viewDamage.hidden = NO;
        viewDamageDetails.hidden = YES;
        
        if (viewType != VT_PHOTO)
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Images"
                                                                                       style:UIBarButtonItemStylePlain 
                                                                                      target:self 
                                                                                      action:@selector(cmdImagesClick:)];
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil;
        }
        
        [self removeDamageButtons];
        [self loadDamageButtons];
        [tableSummary reloadData];
    }
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

//-(IBAction)cmdDoneClick:(id)sender
//{ //couldn't get this working, the view is in a different controller at this point
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    //jump back to nav list
//    //Vehicle damages can be accessed from "bulky inventory" and legacy auto inventory... need better handling
//    if (isAutoInventory)
//    {
//        PVOAutoInventoryController *navController = nil;
//        for (id view in [self.navigationController viewControllers]) {
//            if([view isKindOfClass:[PVOAutoInventoryController class]])
//                navController = view;
//        }
//        [self.navigationController popToViewController:navController animated:YES];
//    }
//    else
//    {
//        //next item... so jump back to item list, and tap add button...
//        PVOBulkyInventoryController *itemController = nil;
//        for (id view in [self.navigationController viewControllers]) {
//            if([view isKindOfClass:[PVOBulkyInventoryController class]])
//                itemController = view;
//        }
//        
//        [self.navigationController popToViewController:itemController animated:YES];
//    }
//}


-(IBAction)cmdImagesClick:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(imageViewer == nil)
        imageViewer = [[SurveyImageViewer alloc] init];
    
    imageViewer.photosType = IMG_PVO_VEHICLE_DAMAGES;
//    imageViewer.vehicle = vehicle;
    imageViewer.subID = viewType;
    imageViewer.customerID = del.customerID;
    
    imageViewer.caller = self.view;
    
    imageViewer.viewController = self;
    
    [imageViewer loadPhotos];
    
}

-(IBAction)cmdDamageClick:(id)sender
{
    if(!pickingDamage)
    {
        UIButton *dmg = sender;
        
//        PVOVehicle *deleteThis = [[PVOVehicle alloc] init];
//        deleteThis.wireframeType = 1;
        //need the location in the image...
        damageLocation = [PVOWireframeDamage translateLocationInViewToLocationInImage:dmg.frame.origin
                                                                    withViewSize:imgSingle.frame.size
                                                                        andImage:imgSingle.image];
        
        pickingDamage = YES;
        tableDamages.hidden = NO;
        viewDamage.hidden = YES;
        viewDamageDetails.hidden = NO;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Comments"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(commentsClicked:)];
        [tableDamages reloadData];
        [tableSummary reloadData];
        
        [self updateCurrentDamagesLabel];
    }
}

- (void)viewDidUnload
{
    [self setTableSummary:nil];
    [self setImgSingle:nil];
    [self setTableDamages:nil];
    [self setViewDamage:nil];
    [self setSwitchHighPriority:nil];
    [self setLabelCurrentDamages:nil];
    [self setViewDamageDetails:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == tableSummary && pickingDamage)
        return 0;
    else if(tableView == tableSummary)
        return 2;
    else
        return [allDamages count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if(tableView == tableSummary)
    {
        if(indexPath.row == 0)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            SurveyCustomer *customer = [del.surveyDB getCustomer:del.customerID];
            
            cell.textLabel.text = @"Owner";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", customer.lastName, customer.firstName];
        }
        else
        {
            cell.textLabel.text = @"Service Status";
            cell.detailTextLabel.text = @"Service Type Description Goes Here?"; //[order serviceTypeDescrition];
        }
    }
    else 
    {
        PVOWireframeDamage *d = [allDamages objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", d.damageAlphaCodes, d.description];
        
        if([PVOWireframeDamage hasDamage:d withDamageList:self.damages atLocation:damageLocation forType:viewType])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(tableView != self.tableSummary)
    {
        PVOWireframeDamage *d = [allDamages objectAtIndex:indexPath.row];
        UITableViewCell *cell = [self.tableDamages cellForRowAtIndexPath:indexPath];
        if([PVOWireframeDamage hasDamage:d withDamageList:self.damages atLocation:damageLocation forType:viewType])
        {//remove it, clear check
            cell.accessoryType = UITableViewCellAccessoryNone;
            [PVOWireframeDamage removeDamage:d withDamageList:self.damages atLocation:damageLocation forType:viewType];
        }
        else 
        {//add and check
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [PVOWireframeDamage addDamage:d withDamageList:self.damages atLocation:damageLocation forType:viewType andVehicleID:wireframeItemID withImageID:imageId withIsOrigin:isOrigin];
            
        }
        
        [self updateCurrentDamagesLabel];
        
    }
}

#pragma mark - CommentControllerDelegate


//-(void)commentControllerWillDisappear:(PVOCommentsController*)controller
//{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    vehicle.damages = [NSMutableArray arrayWithArray:[del.surveyDB getVehicleDamages:vehicle.vehicleID]];
//    
//    PVOWireframeDamage *d = [vehicle getDamageAtLocation:damageLocation forType:viewType andVehicleID:vehicle.vehicleID];
//    d.comments = controller.tboxComments.text;
//    
//    [del.surveyDB saveVehicleDamages:vehicle.damages forVehicle:vehicle.vehicleID];
//}

-(void)commentEntered:(NSString*)text
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.damages = [NSMutableArray arrayWithArray:[del.surveyDB getVehicleDamages:wireframeItemID withImageID:imageId]];
    
    PVOWireframeDamage *d = [PVOWireframeDamage getDamageAtLocation:damageLocation withDamageList:self.damages forType:viewType andVehicleID:wireframeItemID withImageID:imageId];
    d.comments = text;
    
    //make this generic so it can just call getWireframeDamages and send the itemID(vehicleid) and hte wireframe typeid
    [del.surveyDB savePVOWireframeDamages:self.damages forWireframeItemID:wireframeItemID withImageID:imageId withIsVehicle:isAutoInventory];
}

@end
