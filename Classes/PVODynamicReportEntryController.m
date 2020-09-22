#import "PVODynamicReportEntryController.h"
#import "SurveyAppDelegate.h"
#import "LabelTextCell.h"
#import "SwitchCell.h"
#import "PVODynamicReportData.h"

@interface PVODynamicReportEntryController ()

@end

@implementation PVODynamicReportEntryController
@synthesize entries, data, section, editingEntry, currentTextBox;

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
    
    self.editingEntry = nil;
    self.entries = nil;
    self.data = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = self.section.sectionName;
    
    if(self.editingEntry == nil)
    {
        self.entries = [del.pricingDB getPVOReportEntries:self.section.reportID forSection:self.section.reportSectonID];
        self.data = [del.surveyDB getPVODynamicReportData:del.customerID forReport:self.section.reportID sectionID:self.section.reportSectonID];
    }
    
    self.editingEntry = nil;
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];//reload the table
}

-(IBAction)updateValueWithField:(UITextField*)sender
{
    PVODynamicReportEntry *thisEntry = nil;
    
    for (PVODynamicReportEntry *entry in self.entries) {
        if(entry.dataEntryID == sender.tag)
            thisEntry = entry;
    }
    
    if(thisEntry == nil)
        return;
    
    PVODynamicReportData *data = [self getReportDataForEntry:thisEntry];
    
    if(thisEntry.entryDataType == RDT_TEXT || thisEntry.entryDataType == RDT_TEXT_LONG || thisEntry.entryDataType == RDT_TEXT_CAPS){
        data.textValue = sender.text;
    }
    else if(thisEntry.entryDataType == RDT_INTEGER){
        data.intValue = [sender.text intValue];
    }
    else if(thisEntry.entryDataType == RDT_DOUBLE){
        data.doubleValue = [sender.text doubleValue];
    }
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    
    //save on/off for sender.tag
    PVODynamicReportEntry *thisEntry = nil;
    
    for (PVODynamicReportEntry *entry in self.entries) {
        if(entry.dataEntryID == sw.tag)
            thisEntry = entry;
    }
    
    if(thisEntry == nil)
        return;
    
    PVODynamicReportData *data = [self getReportDataForEntry:thisEntry];
    data.intValue = sw.on ? 1 : 0;
}

-(void)pickerValueSelected:(NSNumber*)newValue
{
    
}

-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}

//get the customer data from the customer database for the entry from the PVO Control tables
-(PVODynamicReportData*)getReportDataForEntry:(PVODynamicReportEntry*)controlEntry
{
    for (PVODynamicReportData *data in self.data) {
        if(data.reportID == controlEntry.reportID &&
           data.dataSectionID == controlEntry.dataSectionID &&
           data.dataEntryID == controlEntry.dataEntryID)
            return data;
    }
    
    //create a new one
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVODynamicReportData *retval = [[PVODynamicReportData alloc] init];
    retval.custID = del.customerID;
    retval.reportID = controlEntry.reportID;
    retval.dataSectionID = controlEntry.dataSectionID;
    retval.dataEntryID = controlEntry.dataEntryID;
    
    [self.data addObject:retval];
    
    if(controlEntry.defaultValue == nil || controlEntry.defaultValue.length == 0)
        return retval;
    
    if(controlEntry.entryDataType == RDT_DATE ||
       controlEntry.entryDataType == RDT_DATE_TIME ||
       controlEntry.entryDataType == RDT_TIME)
    {
        if(controlEntry.defaultValue != nil && [[controlEntry.defaultValue lowercaseString] isEqualToString:@"today"])
            retval.dateValue = [NSDate date];
    }
    else if(controlEntry.entryDataType == RDT_INTEGER)
    {
        retval.intValue = [controlEntry.defaultValue intValue];
    }
    else if(controlEntry.entryDataType == RDT_DOUBLE)
    {
        retval.doubleValue = [controlEntry.defaultValue doubleValue];
    }
    else if(controlEntry.entryDataType == RDT_TEXT || controlEntry.entryDataType == RDT_TEXT_LONG || controlEntry.entryDataType == RDT_TEXT_CAPS)
    {
        retval.textValue = controlEntry.defaultValue;
    }
    
    return retval;
}

-(void)viewWillDisappear:(BOOL)animated{
    
    if(self.currentTextBox != nil) {
        [self updateValueWithField:self.currentTextBox];
        self.currentTextBox = nil;
    }
    
    if(self.editingEntry == nil)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB savePVODynamicReportData:self.data];
    }
    
    [super viewWillDisappear:animated];
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
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *DateCellIdentifier = @"DateCell";
    static NSString *SimpleCellIdentifier = @"SimpleCell";
    
    UITableViewCell *cell = nil;
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    LabelTextCell* ltCell = nil;
    
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    SwitchCell* swCell = nil;
    
    PVODynamicReportEntry *thisEntry = [self.entries objectAtIndex:indexPath.row];
    PVODynamicReportData *thisData = [self getReportDataForEntry:thisEntry];
    
    if(thisEntry.entryDataType == RDT_TEXT ||
       thisEntry.entryDataType == RDT_TEXT_NUMERIC ||
       thisEntry.entryDataType == RDT_INTEGER ||
       thisEntry.entryDataType == RDT_DOUBLE ||
       thisEntry.entryDataType == RDT_TEXT_CAPS){
        ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];//point cell to label textview class and identifier
        
        //populate items in the label text cell
        if (ltCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
            ltCell = [nib objectAtIndex:0];
            [ltCell setPVOView];
            ltCell.tboxValue.delegate = self;
            [ltCell.tboxValue addTarget:self action:@selector(textFieldDoneEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        ltCell.tboxValue.tag = thisEntry.dataEntryID;
        ltCell.labelHeader.text = thisEntry.entryName;
        
        switch (thisEntry.entryDataType) {
            case RDT_TEXT:
            case RDT_TEXT_LONG:
                ltCell.tboxValue.text = thisData.textValue;
                ltCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                [ltCell.tboxValue setKeyboardType:UIKeyboardTypeASCIICapable];
                break;
            case RDT_TEXT_CAPS:
                ltCell.tboxValue.text = thisData.textValue;
                [ltCell.tboxValue setKeyboardType:UIKeyboardTypeDefault];
                ltCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                break;
            case RDT_INTEGER:
                ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", thisData.intValue];
                [ltCell.tboxValue setKeyboardType:UIKeyboardTypeNumberPad];
                break;
            case RDT_DOUBLE:
                ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:thisData.doubleValue];
                [ltCell.tboxValue setKeyboardType:UIKeyboardTypeDecimalPad];
                break;
            case RDT_TEXT_NUMERIC:
                ltCell.tboxValue.text = thisData.textValue;
                [ltCell.tboxValue setKeyboardType:UIKeyboardTypeNumberPad];
                break;
            default:
                break;
        }
    }
    else if(thisEntry.entryDataType == RDT_ON_OFF)
    {
        swCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        
        //populate items in the switch cell
        if (ltCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            swCell = [nib objectAtIndex:0];
            
            [swCell.switchOption addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        swCell.switchOption.tag = thisEntry.dataEntryID;
        swCell.labelHeader.text = thisEntry.entryName;
        swCell.switchOption.on = thisData.intValue == 1 ? YES : NO;
    }
    else if(thisEntry.entryDataType == RDT_TEXT_LONG)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SimpleCellIdentifier];//use default cell structure
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = [NSString stringWithFormat:@"%@:", thisEntry.entryName];
    }
    else if(thisEntry.entryDataType == RDT_MULTIPLE_CHOICE)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SimpleCellIdentifier];//use default cell structure
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", thisEntry.entryName,
                                     thisData.textValue == nil || thisData.textValue.length == 0 ? @"<Select>" : thisData.textValue];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:DateCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DateCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [[self view] tintColor];
        cell.textLabel.text = thisEntry.entryName;
        
        NSDate *myDate = thisData.dateValue;
        
        if(myDate == nil || [myDate timeIntervalSince1970] == 0)
            cell.detailTextLabel.text = @"";
        else if(thisEntry.entryDataType == RDT_DATE_TIME) {
            // OT 20185 fix - Time is being stored correctly by time zone, but was being displayed in GMT
            cell.detailTextLabel.text = [SurveyAppDelegate formatDateAndTime:myDate asGMT:FALSE];
        }
        else if(thisEntry.entryDataType == RDT_DATE)
            cell.detailTextLabel.text = [SurveyAppDelegate formatDate:myDate];
        else if(thisEntry.entryDataType == RDT_TIME)
            cell.detailTextLabel.text = [SurveyAppDelegate formatTime:myDate];
    }

    return cell != nil ? cell : ltCell != nil ? ltCell : swCell;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.editingEntry = [self.entries objectAtIndex:indexPath.row];
    
    PVODynamicReportData *thisData = [self getReportDataForEntry:self.editingEntry];
    NSDate *myDate = thisData.dateValue;
    
    if(self.editingEntry.entryDataType == RDT_MULTIPLE_CHOICE){
        
        //load up the options, and the picker control
        SelectObjectController *selectObjectControl = [[SelectObjectController alloc] initWithStyle:UITableViewStylePlain];
        selectObjectControl.delegate = self;
        selectObjectControl.choices = [del.pricingDB getPVOMultipleChoiceOptions:self.editingEntry.reportID
                                                                       inSection:self.editingEntry.dataSectionID
                                                                        forEntry:self.editingEntry.dataEntryID];
        selectObjectControl.selectedItems = [NSMutableArray array];
        selectObjectControl.multipleSelection = NO;
        selectObjectControl.allowsNoSelection = NO;
        selectObjectControl.controllerPushed = YES;
        selectObjectControl.displayMethod = @selector(stringByStandardizingPath);
        selectObjectControl.title = self.editingEntry.entryName;
        
        [self.navigationController pushViewController:selectObjectControl animated:YES];
        
    }
    else if(self.editingEntry.entryDataType == RDT_DATE_TIME){
        
        if(myDate == nil || myDate.timeIntervalSince1970 == 0)
            myDate = [NSDate date];
        
        [del pushSingleDateTimeViewController:myDate
                                 withNavTitle:self.editingEntry.entryName
                                   withCaller:self
                                  andCallback:@selector(datesSaved:withToDate:)
                             andNavController:self.navigationController
                             usingOldCallback:YES];
        
    }
    else if(self.editingEntry.entryDataType == RDT_DATE){
        
        if(myDate == nil || myDate.timeIntervalSince1970 == 0)
            myDate = [NSDate date];
        
        [del pushSingleDateViewController:myDate
                                 withNavTitle:self.editingEntry.entryName
                                   withCaller:self
                                  andCallback:@selector(datesSaved:withToDate:)
                             andNavController:self.navigationController
                             usingOldCallback:YES];
        
    }
    else if(self.editingEntry.entryDataType == RDT_TIME){
        
        if(myDate == nil || myDate.timeIntervalSince1970 == 0)
            myDate = [NSDate date];
        
        [del pushSingleTimeViewController:myDate
                                 withNavTitle:self.editingEntry.entryName
                                   withCaller:self
                                  andCallback:@selector(datesSaved:withToDate:)
                             andNavController:self.navigationController];
        
    }
    else if (self.editingEntry.entryDataType == RDT_TEXT_LONG) {
        
        NSString *note = thisData.textValue;
        
        [del pushNoteViewController:note
                       withKeyboard:UIKeyboardTypeASCIICapable
                       withNavTitle:@"Enter Note"
                    withDescription:self.editingEntry.entryName
                         withCaller:self
                        andCallback:@selector(doneEditingNote:)
                  dismissController:YES
                           noteType:NOTE_TYPE_NONE];
        
    }
    else if(self.editingEntry.entryDataType == RDT_ON_OFF){
        
        [SurveyAppDelegate showAlert:self.editingEntry.entryName withTitle:self.section.sectionName];
        self.editingEntry = nil;
        
    }
}

-(IBAction)doneEditingNote:(NSString*)newNote
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVODynamicReportData *thisData = [self getReportDataForEntry:self.editingEntry];
    thisData.textValue = newNote;
}

-(void)datesSaved:(NSDate*)fromDate withToDate:(NSDate*)toDate{
    //    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //set the target date
    PVODynamicReportData *thisData = [self getReportDataForEntry:self.editingEntry];
    thisData.dateValue = fromDate;
    
    //check for matching group...
    PVODynamicReportEntry *matcher = nil;
    
    for (PVODynamicReportEntry *entry in self.entries) {
        //have to match dates with dates, times with times... there could be a group of four (two dates, two times)
        //there should only ever be one match
        if(entry.dateTimeGroup == self.editingEntry.dateTimeGroup &&
           entry.entryDataType == self.editingEntry.entryDataType &&
           entry.dataEntryID != self.editingEntry.dataEntryID)
            matcher = entry;
    }
    
    if(matcher != nil)
    {
        PVODynamicReportData *otherData = [self getReportDataForEntry:matcher];
        
        if(matcher.dataEntryID > self.editingEntry.dataEntryID)
        {//the date changed was the from
            if(otherData.dateValue == nil ||
               [fromDate timeIntervalSince1970] > [otherData.dateValue timeIntervalSince1970])
                otherData.dateValue = fromDate;
        }
        else
        {//the date changed was the to
            if(otherData.dateValue == nil ||
               [fromDate timeIntervalSince1970] < [otherData.dateValue timeIntervalSince1970])
            {
                otherData.dateValue = fromDate;
            }
        }
    }
    
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.currentTextBox = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
}

#pragma mark - SelectObjectControllerDelegate methods

-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection
{
    if(collection.count > 0)
    {
        PVODynamicReportData *thisData = [self getReportDataForEntry:self.editingEntry];
        thisData.textValue = [collection objectAtIndex:0];
    }
}

-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller
{
    return YES;
}

@end
