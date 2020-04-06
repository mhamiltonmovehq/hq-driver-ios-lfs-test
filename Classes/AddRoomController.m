//
//  AddRoomController.m
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AddRoomController.h"
#import "SurveyAppDelegate.h"
#import "Room.h"

@implementation AddRoomController

@synthesize keys, rooms, caller, callback, pushed, popover, delegate, tableView, pvoLocationID;


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
//    if (self = [super init]) {
//		pushed = FALSE;
//		self.popover = nil;
//        
//        UIView *myView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)];
//        
//        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416) style:style];
//        tableView.dataSource = self;
//        tableView.delegate = self;
//        [myView addSubview:tableView];
//        
//        self.view = myView;
//        
//        //removed this because viewDidLoad was getting hit before a consumer could init variables (i.e. pushed)
//        [self viewDidLoad];
//    }
    return [self initWithStyle:style andPushed:FALSE];
}

- (id)initWithStyle:(UITableViewStyle)style andPushed:(BOOL)pushedOntoNavCtl {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super init]) {
		pushed = pushedOntoNavCtl;
		self.popover = nil;
        
//        CGRect window = CGRectMake(0, 0, 320, 416);
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        
        UIView *myView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appwindow.frame.size.width, appwindow.frame.size.height - 64)];
        
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appwindow.frame.size.width, appwindow.frame.size.height - 64) style:style];
        tableView.dataSource = self;
        tableView.delegate = self;
        [tableView setBackgroundColor:[UIColor whiteColor]];
        [myView addSubview:tableView];
        
        self.view = myView;
        
        //removed this because viewDidLoad was getting hit before a consumer could init variables (i.e. pushed)
        [self viewDidLoad];
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
	
    if([self supportCustomRoomSelection])
    {
        if([self.view viewWithTag:999] == nil)
        {
            UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:
                                           [NSArray arrayWithObjects:@"All Rooms",[delegate addRoomControllerCustomRoomsHeader:self], nil]];
            [segment addTarget:self action:@selector(viewChanged:) forControlEvents:UIControlEventValueChanged];
            [segment setBackgroundColor:[UIColor whiteColor]];
            
            //some reason, it is too wide...
            CGRect frame = segment.frame;
            frame.size.width = tableView.frame.size.width;
            segment.frame = frame;
            segment.selectedSegmentIndex = currentView;
            segment.tag = 999;
            [self.view addSubview:segment];
            
            //resize table view
            frame = self.tableView.frame;
            frame.origin.y += (segment.frame.size.height - 1);
            frame.size.height -= (segment.frame.size.height - 1);
            self.tableView.frame = frame;
        }
    }
    else if([self.view viewWithTag:999] != nil)
    {//remove it...
        UISegmentedControl *segment = (UISegmentedControl *)[self.view viewWithTag:999];
        [segment removeFromSuperview];
        //resize table view
        CGRect frame = self.tableView.frame;
        frame.origin.y -= (segment.frame.size.height - 1);
        frame.size.height += (segment.frame.size.height - 1);
        self.tableView.frame = frame;
    }
    
    [self loadRoomsList];
	
    
    [super viewWillAppear:animated];
}

-(void)loadRoomsList
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *allrooms;
    
    if(currentView == 0 || ![self supportCustomRoomSelection])
        //allrooms = [del.surveyDB getAllRoomsListWithPVOLocationID:self.pvoLocationID];
        allrooms = [del.surveyDB getAllRoomsList:del.customerID withCheckInclude:NO limitToCustomer:NO withPVOLocationID:self.pvoLocationID withHidden:NO];
    else
        allrooms = [[NSMutableArray alloc] initWithArray:[delegate addRoomControllerCustomRoomsList:self]];
    
    self.rooms = [Room getDictionaryFromRoomList:allrooms];
    
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[rooms allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
	[self.tableView reloadData];
}

-(IBAction)viewChanged:(id)sender
{
    currentView = [sender selectedSegmentIndex];
    [self loadRoomsList];
}

- (void)viewDidLoad {
	
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
	if(!pushed)
	{
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							   target:self
																							   action:@selector(cancel:)];
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self
																						   action:@selector(newRoom:)];
	
	self.title = @"Add Room";
	
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    BOOL dismiss = YES;
    if(delegate != nil && [delegate respondsToSelector:@selector(addRoomControllerShouldDismiss:)])
        dismiss = [delegate addRoomControllerShouldDismiss:self];
    
    if(dismiss)
    {
        if(popover != nil)
        {
            [popover dismissPopoverAnimated:YES];
            [popover.delegate popoverControllerDidDismissPopover:popover];
        }
        else if(!pushed)
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        else
            [self.navigationController popViewControllerAnimated:YES];
    }
}

-(IBAction)newRoom:(id)sender
{
    if (newRoomController == nil)
    {
        newRoomController = [[NewRoomController alloc] initWithStyle:UITableViewStyleGrouped];
        newRoomController.caller = self;
        newRoomController.callback = @selector(roomAdded:);
    }
    
    Room *newRoom = [[Room alloc] init];
    newRoom.roomName = @"";
    newRoomController.room = newRoom;
    newRoomController.pvoLocationID = pvoLocationID;
    
    
    [self.navigationController pushViewController:newRoomController animated:YES];
    
}

-(void)roomAdded:(Room*)room
{
    
    if(room == nil)
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat: @"Room %@ already exists. Please enter a different name.", room.roomName] withTitle:@"Error"];
        return;
    }
    else
    {
        BOOL animate = YES;
        if(delegate != nil && [delegate respondsToSelector:@selector(addRoomControllerShouldDismiss:)])
            animate = [delegate addRoomControllerShouldDismiss:self];
    }
    
    [self cancel:nil];
    
    
    if([caller respondsToSelector:callback])
    {
        [caller performSelector:callback withObject:room];
    }
    
}

-(BOOL)supportCustomRoomSelection
{
    BOOL retval = FALSE;
    
    if(delegate != nil && [delegate respondsToSelector:@selector(addRoomControllerCustomRoomsList:)])
    {
        if([delegate addRoomControllerCustomRoomsList:self] != nil)
            retval = [[delegate addRoomControllerCustomRoomsList:self] count] > 0;
    }
    
    return retval;
}


/*
*/

/*
*/

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
	
    if([self supportCustomRoomSelection])
        return [keys count];// + 1;
    else
        return [keys count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
//    int index = section;//hmmm this index thing?
    NSString *key = [keys objectAtIndex:section];
    NSArray *letterSection = [rooms objectForKey:key];
    return [letterSection count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *letterSection = [rooms objectForKey:key];
	
	Room *r = [letterSection objectAtIndex:[indexPath row]];
    cell.textLabel.text = r.roomName;
	
    return cell;
}

-(NSString*) tableView: (UITableView*)tv titleForHeaderInSection: (NSInteger) section
{
	NSString *key = [keys objectAtIndex:section];
	return key;
}

-(NSArray*) sectionIndexTitlesForTableView:(UITableView*)tv
{
	return keys;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *letterSection = [rooms objectForKey:key];
	
	Room *r = [letterSection objectAtIndex:[indexPath row]];
	
	if([caller respondsToSelector:callback])
	{
		[caller performSelector:callback withObject:r];
	}
	
	[self cancel:nil];
	
	//call cancel to clear the view
	
	
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end

