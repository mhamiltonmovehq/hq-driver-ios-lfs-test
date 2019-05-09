//
//  AutoBackupSettingsController.m
//  Survey
//
//  Created by Tony Brame on 2/5/13.
//
//

#import "AutoBackupSettingsController.h"
#import "LabelTextCell.h"
#import "SwitchCell.h"
#import "SurveyAppDelegate.h"

@implementation AutoBackupSettingsController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.timeTypes = [NSMutableArray array];
    
    [self.timeTypes addObject:@"Minutes"];
    [self.timeTypes addObject:@"Hours"];
    [self.timeTypes addObject:@"Days"];
    
    self.times = [NSMutableArray array];
    
    for (int i = 1; i <= AUTO_BACKUP_MAX_TIME; i++)
    {
        [self.times addObject:[NSString stringWithFormat:@"%d", i]];
    }
    
    self.title = @"Auto Backup";
    
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.settings = [del.surveyDB getBackupSchedule];
    
    int mult = 0;
    for (int i = 0; i <= 2; i++) {
        mult = [self getTimeTypeMultiplier:i];
        
        if(self.settings.backupFrequency <= mult * AUTO_BACKUP_MAX_TIME)
        {
            [self.pickerInterval selectRow:i inComponent:AUTO_BACKUP_PICKER_TYPE animated:YES];
            
            //set selection
            int timeRow = ((int)round(self.settings.backupFrequency / mult)) - 1;//1 will be index zero...
            [self.pickerInterval selectRow:timeRow inComponent:AUTO_BACKUP_PICKER_TIME animated:YES];
            break;
        }
    }
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

//get mult for time type in seconds
-(int)getTimeTypeMultiplier:(int)type
{
    switch (type) {
        case AUTO_BACKUP_TIME_TYPE_MINUTES:
            return 60;
        case AUTO_BACKUP_TIME_TYPE_HOURS:
            return 60 * 60;
        case AUTO_BACKUP_TIME_TYPE_DAYS:
            return 24 * 60 * 60;
    }
    
    return 1;
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(self.tboxCurrent != nil)
    {
        [self updateValueWithField:self.tboxCurrent];
        self.tboxCurrent = nil;
    }
    
    int timeType = [self.pickerInterval selectedRowInComponent:AUTO_BACKUP_PICKER_TYPE];
    int mult = [self getTimeTypeMultiplier:timeType];
    int timeSelected = [[self.times objectAtIndex:[self.pickerInterval selectedRowInComponent:AUTO_BACKUP_PICKER_TIME]] intValue];
    self.settings.backupFrequency = mult * timeSelected;
    
    if(self.settings.numBackupsToRetain == 0)
        self.settings.numBackupsToRetain = 1;
    
    
    if(self.settings.numBackupsToRetain > 200)
    {
        [SurveyAppDelegate showAlert:@"The maximum number of backups to retain is 200.  Please adjust accordingly - 200 has been reset."
                           withTitle:@"Maximum Exceeded"];
        self.settings.numBackupsToRetain = 200;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB saveBackupSchedule:self.settings];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateValueWithField:(UITextField*)field
{
	self.settings.numBackupsToRetain = [field.text integerValue];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    if(sw.tag == 0)
    {
        self.settings.enableBackup = sw.on;
        [self.tableView reloadData];
    }
    else
        self.settings.includeImages = sw.on;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.settings.enableBackup ? 3 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    
    
	static NSString *SwitchIdentifier = @"SwitchCell";
	SwitchCell *switchCell = nil;
    LabelTextCell *ltCell = nil;
	
    if(indexPath.row == 0 || indexPath.row == 2)
    {
        switchCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchIdentifier];
        
        if (switchCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            switchCell = [nib objectAtIndex:0];
            
            [switchCell.switchOption addTarget:self
                                        action:@selector(switchChanged:)
                              forControlEvents:UIControlEventValueChanged];
        }
        
        switchCell.switchOption.tag = indexPath.row;
        
        if(indexPath.row == 0)
        {
            switchCell.labelHeader.text = @"Enable Backups";
            switchCell.switchOption.on = self.settings.enableBackup;
        }
        else if(indexPath.row == 2)
        {
            switchCell.labelHeader.text = @"Include Photos";
            switchCell.switchOption.on = self.settings.includeImages;
        }
    }
	else
    {
        ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
        if (ltCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
            ltCell = [nib objectAtIndex:0];
            [ltCell.tboxValue addTarget:self
                                 action:@selector(textFieldDoneEditing:)
                       forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        ltCell.tboxValue.delegate = self;
        ltCell.tboxValue.tag = [indexPath row];
        
        ltCell.labelHeader.text = @"Backups To Retain:";
        ltCell.tboxValue.text = [NSString stringWithFormat:@"%d",self.settings.numBackupsToRetain];
    }
	
    return ltCell != nil ? ltCell : switchCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(self.tboxCurrent != nil)
        [self.tboxCurrent resignFirstResponder];
}

- (void)viewDidUnload {
    [self setPickerInterval:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

#pragma mark - Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
}


#pragma mark - Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 2;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (component == AUTO_BACKUP_PICKER_TYPE)
		return [self.timeTypes count];
	else
        return [self.times count];
}

#pragma mark - Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (component == AUTO_BACKUP_PICKER_TYPE)
		return [self.timeTypes objectAtIndex:row];
    else
		return [self.times objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
//	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//	if (component == 0)
//	{
//		NSString *selectedState = [self.states objectAtIndex:row];
//		
//		self.currentState = selectedState;
//		
//		self.agencies = [del.pricingDB getAgentsList:currentState sortByCode:sortByControl.selectedSegmentIndex == SORT_CODE];
//		
//		[picker selectRow:0 inComponent:NAME_SECTION animated:YES];
//		[picker reloadComponent:NAME_SECTION];
//	}
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	if (component == AUTO_BACKUP_PICKER_TYPE)
		return 200;
	
	return (295-200);
}


@end
