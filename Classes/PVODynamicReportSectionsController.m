//
//  PVODynamicReportSectionsController.m
//  Survey
//
//  Created by Tony Brame on 5/1/14.
//
//

#import "PVODynamicReportSectionsController.h"
#import "PVODynamicReportSection.h"
#import "SurveyAppDelegate.h"
#import "PVONavigationListItem.h"
#import "PVODynamicReportEntryController.h"

@interface PVODynamicReportSectionsController ()

@end

@implementation PVODynamicReportSectionsController

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
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.sections = [del.pricingDB getPVOReportSections:self.navItem.navItemID];
    self.title = self.navItem.display;
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)promptToRemoveSignatures:(int)row
{
    //only necessary for BOL details right now
    if (self.navItem.navItemID != PVO_BOL_DETAILS)
        return false;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVODynamicReportSection *section = [self.sections objectAtIndex:row];
    
    BOOL removeSigs = NO;
    NSMutableArray *sigIDs = [[NSMutableArray alloc] init];
    if (section.reportSectonID == 1)
    {
        //get the signature Ids for Origin BOL, check if any signatures exist
        [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_ORIGIN]];
        [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_O_MILITARY]];
        [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_O_SPECIAL_SERVICES]];
        
    }
    else if (section.reportSectonID == 2)
    {
        //get the signature Ids for SIT BOL, check if any signatures exist
        [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_SIT]];
    }
    
    PVOSignature *sig;
    for (NSNumber *sigid in sigIDs) {
        sig = [del.surveyDB getPVOSignature:del.customerID forImageType:[sigid intValue]];
        if(sig != nil)
        {
            removeSigs = YES;
        }
    }
    
    if(removeSigs)
    {
        [self askToContinue:@"A signature for this report exists.  If you choose to continue, the signature for this report will be removed.  Would you like to continue?" withIndexrow:row];
        return TRUE;
    }
    else
        return false;
}

-(void)askToContinue:(NSString*)continueText withIndexrow:(int)row
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Continue?"
                                                    message:continueText
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = row;
    [alert show];
    
}

-(void)continueToSelection:(int)row
{
    PVODynamicReportSection *section = [self.sections objectAtIndex:row];
    
    if(self.entryController == nil)
        _entryController = [[PVODynamicReportEntryController alloc] initWithStyle:UITableViewStyleGrouped];
    self.entryController.section = section;
    
    [self.navigationController pushViewController:self.entryController animated:YES];
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
    return self.sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";//identifier for regular cell
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    PVODynamicReportSection *section = [self.sections objectAtIndex:indexPath.row];
    
    cell.textLabel.text = section.sectionName;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    PVODynamicReportSection *section = [self.sections objectAtIndex:indexPath.row];
    
    if ([self promptToRemoveSignatures:indexPath.row])
        return;
    else
        [self continueToSelection:indexPath.row];
    
//    if(self.entryController == nil)
//        _entryController = [[PVODynamicReportEntryController alloc] initWithStyle:UITableViewStyleGrouped];
//    self.entryController.section = section;
//    
//    [self.navigationController pushViewController:self.entryController animated:YES];
    
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        //i assigned the row to the tag, get the correct section
        PVODynamicReportSection *section = [self.sections objectAtIndex:alertView.tag];
        
        NSMutableArray *sigIDs = [[NSMutableArray alloc] init];
        if (section.reportSectonID == 1)//Origin BOL
        {
            //get the signature Ids for Origin BOL, check if any signatures exist
            [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_ORIGIN]];
            [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_O_MILITARY]];
            [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_O_SPECIAL_SERVICES]];
            
        }
        else if (section.reportSectonID == 2)//SIT BoL
        {
            //get the signature Ids for SIT BOL, check if any signatures exist
            [sigIDs addObject:[NSNumber numberWithInt:PVO_SIGNATURE_TYPE_BOL_SIT]];
        }
        
        for (NSNumber *sigid in sigIDs) {
            [del.surveyDB deletePVOSignature:del.customerID forImageType:[sigid intValue]];
        }
        
        //continue to the section, pass in the row/tag. continue to selection gets the PVODynamicReportSection using the row
        [self continueToSelection:alertView.tag];
    }
}

-(void)dealloc
{
    self.entryController = nil;
    self.navItem = nil;
    self.sections = nil;
}

@end
