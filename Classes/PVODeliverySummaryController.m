//
//  PVODeliverySummaryController.m
//  Survey
//
//  Created by Tony Brame on 10/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODeliverySummaryController.h"
#import "SurveyAppDelegate.h"

@implementation PVODeliveryLoadSelectItem
@synthesize load, display;
@end

@implementation PVODeliverySummaryController

@synthesize deliveries, loads, locations, selectLocation, deliveryController, selectLoads;

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
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.locations = [del.surveyDB getPVOLocations:NO isLoading:NO];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addDelivery:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driver = [del.surveyDB getDriverData];
    
    self.loads = [del.surveyDB getPVOLocationsForCust:del.customerID withDriverType:driver.driverType];
    self.deliveries = [del.surveyDB getPVOUnloads:del.customerID];
        
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

-(void)pickerValueSelected:(NSNumber*)newValue
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    newDelivery.pvoLocationID = [newValue intValue];
    
    //check to see if location selection is required...
    if([del.surveyDB pvoLocationRequiresLocationSelection:[newValue intValue]])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        
        //load the location select form.
        if(selectLocation == nil)
            selectLocation = [[SelectLocationController alloc] initWithStyle:UITableViewStyleGrouped];
        selectLocation.title = @"Select Location";
        selectLocation.delegate = self;
        selectLocation.locationID = DESTINATION_LOCATION_ID;
        
        newNav = [[PortraitNavController alloc] initWithRootViewController:selectLocation];
        [self presentViewController:newNav animated:YES completion:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        newDelivery.pvoLoadID = [del.surveyDB savePVOUnload:newDelivery];
        [self loadDeliveryPage:newDelivery];
    }
}

-(void)loadDeliveryPage:(PVOInventoryUnload*)unload
{
    if(deliveryController == nil)
        deliveryController = [[PVODeliveryController alloc] initWithNibName:@"PVODeliveryView" bundle:nil];
    deliveryController.title = @"Unloading";
    deliveryController.currentUnload = unload;
    //reset lot number...
    deliveryController.currentLotNumber = nil;
    [self.navigationController pushViewController:deliveryController animated:YES];
}

-(IBAction)addDelivery:(id)sender
{
    //prompt for loads to deliver.
    //create the new pvo load...
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    newDelivery = [[PVOInventoryUnload alloc] init];
    newDelivery.custID = del.customerID;
    newDelivery.loadIDs = [NSMutableArray array];
    
    if(selectLoads == nil)
        selectLoads = [[SelectObjectController alloc] initWithStyle:UITableViewStylePlain];
    
    
    selectLoads.title = @"Select Load(s)";
    selectLoads.multipleSelection = YES;
    selectLoads.delegate = self;
    
    NSMutableArray *choices = [[NSMutableArray alloc] init];
    for (PVOInventoryLoad *ld in loads) {
        if([del.surveyDB pvoLoadAvailableForUnload:ld.pvoLoadID])
        {
            PVODeliveryLoadSelectItem *item = [[PVODeliveryLoadSelectItem alloc] init];
            item.load = ld;
            
            if([del.surveyDB pvoLocationRequiresLocationSelection:ld.pvoLocationID])
            {
                SurveyLocation *loc = [del.surveyDB getCustomerLocation:ld.locationID];
                item.display = [NSString stringWithFormat:@"%@: %@", loc.name,
                                           [locations objectForKey:[NSNumber numberWithInt:ld.pvoLocationID]]];
            }
            else
            {
                item.display = [NSString stringWithFormat:@"%@",
                                           [locations objectForKey:[NSNumber numberWithInt:ld.pvoLocationID]]];
            }
            
            [choices addObject:item];
        }
    }
    
    if([choices count] > 0)
    {
        selectLoads.choices = choices;
        selectLoads.displayMethod = @selector(display);
        
        newNav = [[PortraitNavController alloc] initWithRootViewController:selectLoads];
        
        [self presentViewController:newNav animated:YES completion:nil];
    }
    else
        [SurveyAppDelegate showAlert:@"No Loads are available for delivery." withTitle:@"No Loads Available"];
    
}

-(PVOInventoryLoad*)getLoad:(int)loadID
{
    for (PVOInventoryLoad *load in loads) {
        if(load.pvoLoadID == loadID)
            return load;
    }
    return nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [deliveries count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([deliveries count] == 0)
        return @"Tap the plus to add a delivery for this inventory.";
    else
        return  nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    //show the PVO location, and associated loads, and location?...
    PVOInventoryUnload *unload = [deliveries objectAtIndex:indexPath.row];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.surveyDB pvoLocationRequiresLocationSelection:unload.pvoLocationID])
    {
        SurveyLocation *loc = [del.surveyDB getCustomerLocation:unload.locationID];
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", loc.name,
                               [locations objectForKey:[NSNumber numberWithInt:unload.pvoLocationID]]];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@",
                               [locations objectForKey:[NSNumber numberWithInt:unload.pvoLocationID]]];
    }
    
    
    return cell;
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
    PVOInventoryUnload *unload = [deliveries objectAtIndex:indexPath.row];
    [self loadDeliveryPage:unload];
}


#pragma mark - SelectLocationControllerDelegate methods

-(void)locationSelected:(SelectLocationController*)controller withLocation:(SurveyLocation*)location
{
    //check to see if this one is already assigned..
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.surveyDB locationAvailableForPVOLoad:location.locationID])
    {
        newDelivery.locationID = location.locationID;
        
        newDelivery.pvoLoadID = [del.surveyDB savePVOUnload:newDelivery];
        
        [self loadDeliveryPage:newDelivery];
    }
    else
        [SurveyAppDelegate showAlert:@"This location has already been selected for a Delivery, please select a different location, or add a new location." withTitle:@"Location Selected"];
}

-(BOOL)shouldDismiss:(SelectLocationController*)controller
{
    return newDelivery.locationID != 0;
}

#pragma mark - SelectObjectControllerDelegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    //load up the selected ids, then present unload type controller.
    [self dismissViewControllerAnimated:YES completion:nil];
    
    for (PVODeliveryLoadSelectItem *item in collection) {
        [newDelivery.loadIDs addObject:[NSNumber numberWithInt:item.load.pvoLoadID]];
    } 
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del popTablePickerController:@"Select Unload Type" 
                      withObjects:locations 
             withCurrentSelection:nil
                       withCaller:self 
                      andCallback:@selector(pickerValueSelected:) 
                  dismissOnSelect:FALSE
                andViewController:self];
}

-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller
{
    return NO;
}

@end
