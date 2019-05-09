//
//  PVOConfirmPaymentController.m
//  Survey
//
//  Created by Tony Brame on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOConfirmPaymentController.h"
#import "SwitchCell.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"

@implementation PVOConfirmPaymentController

@synthesize tboxCurrent, paymentMethod;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        paymentOptions = [[NSMutableDictionary alloc] init];
        [paymentOptions setObject:@"COD" forKey:[NSNumber numberWithInt:COD]];
        [paymentOptions setObject:@"Prepaid" forKey:[NSNumber numberWithInt:PREPAID]];
        [paymentOptions setObject:@"NATL Account/Invoice" forKey:[NSNumber numberWithInt:NATL_ACCOUNT]];
        
        prepaid = FALSE;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)updateValueWithField:(UITextField*)fld
{
    amount = [fld.text doubleValue];
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    prepaid = sw.on;
    
    [self.tableView reloadData];
}

-(void)paymentMethodSelected:(NSNumber*)newValue
{
    paymentMethod = [newValue intValue];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    
    [self.tableView reloadData];
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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return prepaid ? 3 : 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Payment Information";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    
    UITableViewCell *cell = nil;
    SwitchCell *swCell = nil;
    LabelTextCell *ltCell = nil;
    
    if(indexPath.row == PVO_CONFIRM_PAY_METHOD)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *method = [paymentOptions objectForKey:[NSNumber numberWithInt:paymentMethod]];
        if(method == nil)
            cell.textLabel.text = @"< Select Payment Method >";
        else
            cell.textLabel.text = method;
        
    }
    else if(indexPath.row == PVO_CONFIRM_PAY_PREPAID)
    {
        //switch cell
        swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        if (swCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            swCell = [nib objectAtIndex:0];
            
            [swCell.switchOption addTarget:self
                                    action:@selector(switchChanged:) 
                          forControlEvents:UIControlEventValueChanged];
        }
        
        swCell.labelHeader.text = @"Prepaid";
        swCell.switchOption.on = prepaid;
    }
    else
    {
        //text field
        ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
        if (ltCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
            ltCell = [nib objectAtIndex:0];
            [ltCell setPVOView];
            [ltCell.tboxValue addTarget:self 
                                 action:@selector(textFieldDoneEditing:) 
                       forControlEvents:UIControlEventEditingDidEndOnExit];
            ltCell.tboxValue.delegate = self;
        }
        
        ltCell.labelHeader.text = @"Amount Paid";
        ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:amount];
    }
    
    return cell != nil ? cell : ltCell != nil ? (UITableViewCell*)ltCell : (UITableViewCell*) swCell;
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
    
    if(indexPath.row == PVO_CONFIRM_PAY_METHOD)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Payment" 
                          withObjects:paymentOptions 
                 withCurrentSelection:[NSNumber numberWithInt:paymentMethod] 
                           withCaller:self 
                          andCallback:@selector(paymentMethodSelected:) 
                     andNavController:self.navigationController];
    }
    
}

#pragma UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

@end
