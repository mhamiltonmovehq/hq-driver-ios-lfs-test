//
//  PackerInitialsController.m
//  Survey
//
//  Created by Tony Brame on 4/15/13.
//
//

#import "PackerInitialsController.h"
#import "SurveyAppDelegate.h"

@interface PackerInitialsController ()

@end

@implementation PackerInitialsController

@synthesize isModal;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        isModal = YES; //default to true
    }
    return self;
}

- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = @"Packer Initials";
}

-(IBAction)done:(id)sender
{
    if (isModal)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)addPackerInitials:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del pushSingleFieldController:@""
                       clearOnEdit:NO
                      withKeyboard:UIKeyboardTypeASCIICapable
                   withPlaceHolder:@"Packer Initials"
                        withCaller:self
                       andCallback:@selector(valueEntered:)
                 dismissController:YES
               requireValueForSave:YES
             andAutoCapitalization:UITextAutocapitalizationTypeAllCharacters //put it in all caps
                  andNavController:self.navigationController];
}

-(void)valueEntered:(NSString*)newValue
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *newValueTrimmed = nil;
    if (newValue != nil)
        newValueTrimmed = [[newValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
    if (newValueTrimmed == nil || [newValueTrimmed length] == 0)
        [SurveyAppDelegate showAlert:@"Invalid Packer Initials entered. Record not saved." withTitle:@"Invalid Data"];
    else
    {
        if ([del.surveyDB packersInitialsExists:newValueTrimmed])
            [SurveyAppDelegate showAlert:@"Packer Initials already present. Record not saved." withTitle:@"Invalid Data"];
        else
            [del.surveyDB savePackersInitials:newValueTrimmed];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    initials = [del.surveyDB getAllPackersInitials];
    
    [self.tableView reloadData];
    
    if (isModal)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(done:)];
    }
    else
    {
        //show back button
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addPackerInitials:)];
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [initials count];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [initials count] == 0 ? @"Tap the Plus button to add a packer's initials." : @"Swipe to delete.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [initials objectAtIndex:indexPath.row];
    
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
        // Delete the row from the data source
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB deletePackersInitials:[initials objectAtIndex:indexPath.row]];
        [initials removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if ([initials count] == 0)
            [self.tableView reloadData];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
