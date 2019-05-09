//
//  BrotherPrinterSettingsController.m
//  Survey
//
//  Created by Tony Brame on 7/15/15.
//
//

#import "BrotherPrinterSettingsController.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"

@interface BrotherPrinterSettingsController ()

@end

@implementation BrotherPrinterSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.settings = [[PJ673PrintSettings alloc] init];
    
    self.title = @"Brother Settings";
    
    self.paperTypes = @[@"LETTER_CutSheet", @"LETTER_Roll", @"LETTER_PerforatedRoll", @"LETTER_PerforatedRollRetract"];
    
    if(![SurveyAppDelegate iPad])
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(done:)];
    }
}

-(void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.settings loadPreferences];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(self.tboxCurrent != nil)
        [self updateValueWithField:self.tboxCurrent];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateValueWithField:(UITextField*)current
{
    [self.settings saveIPAddress:current.text];
}

-(IBAction)didEndEditing:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    static NSString *CellIdentifier = @"SimpleCell";
    LabelTextCell *ltcell = nil;;
    UITableViewCell *simpleCell = nil;
    
    int row = [indexPath row];
    if(row == 0)
    {
        ltcell = (LabelTextCell *)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
        
        if (ltcell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
            ltcell = [nib objectAtIndex:0];
            [ltcell.tboxValue addTarget:self
                                 action:@selector(didEndEditing:)
                       forControlEvents:UIControlEventEditingDidEndOnExit];
            ltcell.tboxValue.delegate = self;
            ltcell.tboxValue.returnKeyType = UIReturnKeyDone;
        }
        
        ltcell.labelHeader.text = @"IP Address:";
        ltcell.tboxValue.text = self.settings.IPAddress;
    }
    else
    {
        simpleCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(simpleCell == nil)
        {
            simpleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            simpleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        simpleCell.textLabel.text = [NSString stringWithFormat:@"Paper Type: %@", self.settings.strPaperType];
    }
    
    return ltcell != nil ? ltcell : simpleCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 1)
    {
        SelectObjectController *ctl = [[SelectObjectController alloc] initWithStyle:UITableViewStylePlain];
        ctl.multipleSelection = NO;
        ctl.choices = self.paperTypes;
        ctl.displayMethod = @selector(stringByDeletingPathExtension);
        ctl.title = @"Select Province";
        ctl.delegate = self;
        ctl.controllerPushed = YES;
        
        [self.navigationController pushViewController:ctl animated:YES];
    }
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)dealloc
{
    self.settings = nil;
}

#pragma mark - SelectObjectControllerDelegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    if(collection != nil && collection.count > 0)
        [self.settings savePaperType:[collection objectAtIndex:0]];
}

-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller
{
    return YES;
}

-(NSMutableArray *)selectObjectControllerPreSelectedItems:(SelectObjectController *)controller
{
    for (NSString* type in self.paperTypes) {
        if([type isEqualToString:self.settings.strPaperType])
            return [NSMutableArray arrayWithObject:type];
    }
    return [NSMutableArray array];
}

#pragma mark - UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateValueWithField:textField];
}

@end
