//
//  AddFavoriteItemRoomController.m
//  Survey
//
//  Created by Jason Gorringe on 8/24/18.
//

#import "AddFavoriteItemRoomController.h"
#import "SurveyAppDelegate.h"
#import "Room.h"

@implementation AddFavoriteItemRoomController

@synthesize keys, rooms, delegate, tableView;

- (id)initWithStyle:(UITableViewStyle)style {
    UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
    
    UIView *myView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, appwindow.frame.size.height - 64)];
    
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, appwindow.frame.size.height - 64) style:style];
    
    [tableView setBackgroundColor:[UIColor whiteColor]];
    [myView addSubview:tableView];
    
    self.view = myView;
    
    [self viewDidLoad];
    
    tableView.dataSource = self;
    tableView.delegate = self;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadRoomsList];
    [super viewWillAppear:animated];
}

-(void)loadRoomsList
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *allrooms;
    
    // Include rooms for all customers, including hidden and custom rooms
    allrooms = [del.surveyDB getAllRoomsList:-1 withHidden:TRUE];
    
    self.rooms = [Room getDictionaryFromRoomList:allrooms];
    
    NSMutableArray *keysArray = [[NSMutableArray alloc] init];
    
    [keysArray addObjectsFromArray:[[rooms allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    self.keys = keysArray;
    
    keysArray = nil;
    
    allrooms = nil;
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    
    self.title = @"Select Room";
    
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return [keys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *key = [keys objectAtIndex:section];
    NSArray *letterSection = [rooms objectForKey:key];
    return [letterSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] init];
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
    
    [self cancel:nil];
    
    // Pass the room back to the delegate for item selection
    [delegate roomChosen:r];
}


@end

