//
//  PVODamageAllController.m
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import "PVODamageAllController.h"
//#import "OrderDetailController.h"
#import "PVONavigationController.h"
#import "LandscapeNavController.h"
#import "PVOWireframeDamage.h"
#import "SurveyAppDelegate.h"

@interface PVODamageAllController ()

@end

@implementation PVODamageAllController
@synthesize tableSummary/*, previewPDF*/;
@synthesize imgAll/*, order*/;
//@synthesize vehicle;
@synthesize isOrigin;
@synthesize wireframeItemID, wireframeTypeID;
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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(cmdDoneClick:)];
    
    self.title = @"Damages";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.damages = [del.surveyDB getWireframeDamages:wireframeItemID withImageID:-1 withIsVehicle:isAutoInventory];
    
    UIImage *allImage = [PVOWireframeDamage allImage:wireframeTypeID]; //get all damage image...
    
    CGSize origImgSize = [allImage size];
    
    UIGraphicsBeginImageContextWithOptions(origImgSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [allImage drawInRect:CGRectMake(0, 0, origImgSize.width, origImgSize.height)];
    CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
    int dmgNum = 1;
    //NSArray *damages = order.inspectionType == IT_DESTINATION_BOL ? [order destinationDamages] : [order originDamages];
    
    NSArray *filteredDamages = (isOrigin ? [PVOWireframeDamage originDamages:self.damages] : [PVOWireframeDamage destinationDamages:self.damages]);
    for (PVOWireframeDamage *d in filteredDamages) {
        //get the location in the image...
        //there could be 5 damages at the same location - get the location's damage number...
        CGPoint loc = [d getLocationOfDamageInAllView];
        
        //check to see if it was added
        [[NSString stringWithFormat:@"%d", dmgNum] drawInRect:CGRectMake(loc.x, loc.y, 100, 25)
                                                     withFont:[UIFont systemFontOfSize:26]
                                                lineBreakMode:NSLineBreakByClipping
                                                    alignment:NSTextAlignmentLeft];
        dmgNum++;
    }
    
    allImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    imgAll.image = allImage;
    
    [self.tableSummary reloadData];
}

- (void)viewDidUnload
{
    [self setImgAll:nil];
    [self setTableSummary:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)cmdDoneClick:(id)sender
{
    //I want to let the delegate handle this instead of popping from here. Vehicles pop back to the beginning, items would move forward to add new items
    
    //jump back to nav list
    //Vehicle damages can be accessed from "bulky inventory" and legacy auto inventory... need better handling
    if (isAutoInventory)
    {
        PVOAutoInventoryController *navController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOAutoInventoryController class]])
                navController = view;
        }
        [self.navigationController popToViewController:navController animated:YES];
    }
    else
    {
        //next item... so jump back to item list, and tap add button...
        PVOBulkyInventoryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOBulkyInventoryController class]])
                itemController = view;
        }
        
        [self.navigationController popToViewController:itemController animated:YES];
    }
    
}

- (IBAction)cmdFrontClick:(id)sender
{
    [self loadSingleImage:VT_FRONT];
}

- (IBAction)cmdRearClick:(id)sender 
{
    [self loadSingleImage:VT_REAR];
}

- (IBAction)cmdRightClick:(id)sender 
{
    [self loadSingleImage:VT_RIGHT];
}

- (IBAction)cmdLeftClick:(id)sender 
{
    [self loadSingleImage:VT_LEFT];
}

- (IBAction)cmdTopClick:(id)sender 
{
    [self loadSingleImage:VT_TOP];
}

- (IBAction)cmdPreviousClick:(id)sender 
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)loadSingleImage:(int)viewType
{
    //have to set this before the view is instantiated...
    //[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
    
    if(damageSingle == nil)
        damageSingle = [[PVODamageSingleController alloc] initWithNibName:@"PVODamageSingleView" bundle:nil];
    
    damageSingle.isOrigin = isOrigin;
    damageSingle.imageId = -1;
    
    LandscapeNavController *navCtl = [[LandscapeNavController alloc] initWithRootViewController:damageSingle];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
//    damageSingle.vehicle = vehicle;
    damageSingle.wireframeTypeID = wireframeTypeID;
    damageSingle.wireframeItemID = wireframeItemID;
    damageSingle.viewType = viewType;
    damageSingle.isAutoInventory = isAutoInventory;
    //[self.navigationController pushViewController:damageSingle animated:YES];
    [self presentViewController:navCtl animated:YES completion:nil];
    
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
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
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
