//
//  PVOReweighController.m
//  Survey
//
//  Created by Tony Brame on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOReweighController.h"
#import "SwitchCell.h"

@implementation PVOReweighController

@synthesize delegate;

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
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" 
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(continue_Click:)];

}

-(IBAction)continue_Click:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(reweighDataEntered:)])
        [delegate reweighDataEntered:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    return YES;
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == PVO_REWEIGH_REQUESTED)
        requested = sw.on;
    else if(sw.tag == PVO_REWEIGH_REQUESTED_BY_SHIPPER)
        requestedByShipper = sw.on;
    else if(sw.tag == PVO_REWEIGH_WAIVED)
        waived = sw.on;
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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
    //switch cell
    SwitchCell *swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
    if (swCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
        swCell = [nib objectAtIndex:0];
        
        [swCell.switchOption addTarget:self
                                action:@selector(switchChanged:) 
                      forControlEvents:UIControlEventValueChanged];
    }
    
    swCell.switchOption.tag = indexPath.row;
    
    if(indexPath.row == PVO_REWEIGH_REQUESTED)
    {
        swCell.labelHeader.text = @"Reweigh Requested";
        swCell.switchOption.on = requested;
    }
    else if(indexPath.row == PVO_REWEIGH_REQUESTED_BY_SHIPPER)
    {
        swCell.labelHeader.text = @"Shipper Requests Reweigh";
        swCell.switchOption.on = requestedByShipper;
    }
    else if(indexPath.row == PVO_REWEIGH_WAIVED)
    {
        swCell.labelHeader.text = @"Shipper Waives Right";
        swCell.switchOption.on = waived;
    }
    
    return swCell;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
