//
//  PVOWeightTicketSummaryController.h
//  Survey
//
//  Created by Tony Brame on 6/5/13.
//
//

#import <UIKit/UIKit.h>
#import "PVOWeightTicket.h"
#import "PVOWeightTicketController.h"

@interface PVOWeightTicketSummaryController : UITableViewController

@property (nonatomic, retain) NSMutableArray *weightTickets;
@property (nonatomic, retain) PVOWeightTicketController *ticketController;

-(IBAction)addWeightTicket:(id)sender;

-(void)loadWeightTicket:(PVOWeightTicket*)ticket;

@end
