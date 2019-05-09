//
//  PVOWeightTicketSummaryController.m
//  Survey
//
//  Created by Tony Brame on 6/5/13.
//
//

#import "PVOWeightTicketSummaryController.h"
#import "SurveyAppDelegate.h"

@interface PVOWeightTicketSummaryController ()

@end

@implementation PVOWeightTicketSummaryController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = @"Weight Tickets";
 
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addWeightTicket:)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.weightTickets = [NSMutableArray arrayWithArray:[del.surveyDB getPVOWeightTickets:del.customerID]];
    
    
    
    [self.tableView reloadData];
}


-(IBAction)addWeightTicket:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOWeightTicket *newTicket = [[PVOWeightTicket alloc] init];
    newTicket.ticketDate = [NSDate date];
    newTicket.custID = del.customerID;
    newTicket.newRecord = TRUE;
    [self loadWeightTicket:newTicket];
}

-(void)loadWeightTicket:(PVOWeightTicket*)ticket
{
    if(self.ticketController == nil)
        self.ticketController = [[PVOWeightTicketController alloc] initWithStyle:UITableViewStyleGrouped];
    
    self.ticketController.weightTicket = ticket;
    
    [self.navigationController pushViewController:self.ticketController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    self.ticketController = nil;
    self.weightTickets = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.weightTickets count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.weightTickets.count == 0)
        return @"Tap the \"+\" button to add a new Weight Ticket.";
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    PVOWeightTicket *wt = [self.weightTickets objectAtIndex:indexPath.row];
    
    cell.textLabel.text = wt.description;
    cell.detailTextLabel.text = [SurveyAppDelegate formatDate:wt.ticketDate];
    
    UIImage *myimage = [SurveyImageViewer getDefaultImage:IMG_PVO_WEIGHT_TICKET forItem:wt.weightTicketID];
    if(myimage == nil)
        myimage = [UIImage imageNamed:@"img_photo.png"];
    cell.imageView.image = myimage;
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOWeightTicket *wt = [self.weightTickets objectAtIndex:indexPath.row];
        [del.surveyDB deletePVOWeightTicket:wt.weightTicketID forCustomer:del.customerID];
        [self.weightTickets removeObject:wt];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
}


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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self loadWeightTicket:[self.weightTickets objectAtIndex:indexPath.row]];
}

@end
