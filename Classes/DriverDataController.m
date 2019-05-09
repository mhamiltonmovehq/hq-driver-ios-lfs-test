//
//  DriverDataController.m
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DriverDataController.h"
#import "LabelTextCell.h"
#import "SurveyAppDelegate.h"
#import "SwitchCell.h"
#import "DoubleSwitchCell.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"
#import "FloatingLabelTextCell.h"
#import "EnterCredentialsController.h"

@implementation DriverDataController

@synthesize  data, tboxCurrent;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        rows = [[NSMutableDictionary alloc] init];
        _sections = [[NSMutableArray alloc] init];
        
        if ([AppFunctionality disableAskOnDamageView])
        {
            damageOptions = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Button", @"Wheel", nil]
                                                                 forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_DAMAGE_BUTTON],
                                                                          [NSNumber numberWithInt:PVO_DRIVER_DAMAGE_WHEEL], nil]];
        }
        else
        {
            damageOptions = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Button", @"Wheel", @"Ask", nil]
                                                                 forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_DAMAGE_BUTTON],
                                                                          [NSNumber numberWithInt:PVO_DRIVER_DAMAGE_WHEEL],
                                                                          [NSNumber numberWithInt:PVO_DRIVER_DAMAGE_ASK], nil]];
        }
        
        reportOptions = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Descriptions", @"Codes", nil]
                                                             forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_REPORT_DESCRIPTIONS],
                                                                      [NSNumber numberWithInt:PVO_DRIVER_REPORT_CODES], nil]];
        
        syncOptions = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"By Driver #/Pass", @"By Agent #", nil]
                                                           forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_ARPIN_SYNC_BY_DRIVER],
                                                                    [NSNumber numberWithInt:PVO_ARPIN_SYNC_BY_AGENT], nil]];
        
        driverTypes = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Driver", @"Packer", nil]
                                                             forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_TYPE_DRIVER],
                                                                      [NSNumber numberWithInt:PVO_DRIVER_TYPE_PACKER], nil]];
        
        emailOptions = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Off", @"CC", @"BCC", nil]
                                                           forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_EMAIL_TYPE_NONE],
                                                                    [NSNumber numberWithInt:PVO_DRIVER_EMAIL_TYPE_CC],
                                                                    [NSNumber numberWithInt:PVO_DRIVER_EMAIL_TYPE_BCC], nil]];
        
        
        editing = FALSE;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)initializeIncludedSections
{
    [_sections removeAllObjects];
    
    BOOL isDriverTypePacker = (data != nil && data.driverType == PVO_DRIVER_TYPE_PACKER);
    
    
    //Add driver section
    [_sections addObject:[NSNumber numberWithInt:DRIVER_DATA_SECTION_DRIVERPACKER]];
    
    if (!isDriverTypePacker) {
        //add hauling agent section
        [_sections addObject:[NSNumber numberWithInt:DRIVER_DATA_SECTION_HAULINGAGENT]];
    }
    
    //add app customerization section
    [_sections addObject:[NSNumber numberWithInt:DRIVER_DATA_SECTION_APPLICATION_OPTIONS]];
    
}

-(void)initializeIncludedRows
{
    [self initializeIncludedSections];
    
    [rows removeAllObjects];
    
    BOOL isDriverTypePacker = (data != nil && data.driverType == PVO_DRIVER_TYPE_PACKER);
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int vanlineID = [del.pricingDB vanline];
    
    
    
    NSMutableArray *currentRows = [[NSMutableArray alloc] init];
    
    if (![AppFunctionality disablePackersInventory])
    {//Choose Inventory Type.
        
        //Add to the driver section
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_TYPE]];
    }
    
    if (isDriverTypePacker || [AppFunctionality showPackerInitialsForDriver])
    {//Enter Packer Initials
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_PACKER_INITIALS]];
        
        if (vanlineID == ARPIN && isDriverTypePacker) {
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_SIGNATURE]];

        }
    }
    
    if (!isDriverTypePacker)
    {
        if ([AppFunctionality enableMoveHQSettings])
        {
            //Enter relo settings screen
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_MOVE_HQ_SETTINGS]];
        }
        //Enter Driver Signature
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_SIGNATURE]];
        
        if (vanlineID == ARPIN)
        {
            //Download By: Pass/Agent
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_ARPIN_SYNC_PREFERENCE]];
        
        }
        
        //Driver Name
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_NAME]];
        
        //Driver #
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_NUMBER]];
        
        if (vanlineID == ARPIN)
        {
            //Driver Password
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_PASSWORD]];
            //Safety #
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_SAFETY_NUMBER]];
        }
        
        //Driver Email
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_EMAIL]];
        
        //Driver Email Type: OFF/CC/BCC
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DRIVER_EMAIL_CC_BCC]];
    }
    //add all rows to driver / packer section
    [rows setObject:currentRows forKey:[NSNumber numberWithInt:DRIVER_DATA_SECTION_DRIVERPACKER]];
    
    if (!isDriverTypePacker)
    {
        /********************/
        //HAULING AGENT SECTION
        currentRows = [[NSMutableArray alloc] init];
        
        
        if ([AppFunctionality showTractorTrailerOptional])
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_SHOW_TRACTOR_TRAILER]];
        
        if ([AppFunctionality showTractorTrailerAlways] || ([AppFunctionality showTractorTrailerOptional] && data.showTractorTrailerOptions))
        {
            //Tractor #
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_TRACTOR_NUMBER]];
            
            //Trailer #
            [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_UNIT_NUMBER]];
        }
        
        //Hauling Agt #
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_HAULING_AGENT]];
        
        //Hauling Agt Email
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_HAULING_EMAIL]];
        
        //Hauling Email Type: OFF/CC/BCC
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_HAULING_EMAIL_CC_BCC]];
        
        [rows setObject:currentRows forKey:[NSNumber numberWithInt:DRIVER_DATA_SECTION_HAULINGAGENT]];
        
        
    }
    
    // Packer fields
    if(isDriverTypePacker) {
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_PACKER_NAME]];
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_PACKER_EMAIL]];
        [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_PACKER_EMAIL_CC_BCC]];
    }
    
    //APP CUSTOMIZATION
    currentRows = [[NSMutableArray alloc] init];
    
    //Damage View
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_DAMAGE_VIEW]];
    
    //Report Dmg View
#ifndef ATLASNET
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_REPORT_PREFERENCE]];
#endif
    //Room Conditions
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_ROOM_CONDITIONS]];
    
    //Quick Inventory
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_QUICK_INVENTORY]];
    
    //Use Scanner
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_USE_SCANNER]];
    
    //Save Images to Camera Roll
    [currentRows addObject:[NSNumber numberWithInt:DRIVER_DATA_SAVE_TO_CAM_ROLL]];
    
    
    [rows setObject:currentRows forKey:[NSNumber numberWithInt:DRIVER_DATA_SECTION_APPLICATION_OPTIONS]];

}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    
    if(sw.tag == DRIVER_DATA_SAVE_TO_CAM_ROLL)
        data.saveToCameraRoll = sw.on;
    else if(sw.tag == DRIVER_DATA_ROOM_CONDITIONS)
        data.enableRoomConditions = sw.on;
    else if(sw.tag == DRIVER_DATA_QUICK_INVENTORY)
        data.quickInventory = sw.on;
    else if(sw.tag == DRIVER_DATA_SHOW_TRACTOR_TRAILER)
    {
        data.showTractorTrailerOptions = sw.on;
        [self initializeIncludedRows];
        [self.tableView reloadData];
    }
    else if(sw.tag == DRIVER_DATA_USE_SCANNER)
        data.useScanner = sw.on;
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(IBAction)valueSelected:(id)sender
{
    if(selectingRow == DRIVER_DATA_VANLINE)
        data.vanlineID = [sender intValue];
    else if(selectingRow == DRIVER_DATA_DRIVER_TYPE)
    {
        data.driverType = [sender intValue];
        [self updateTitleByDriverType:data.driverType];
    }
    else if(selectingRow == DRIVER_DATA_REPORT_PREFERENCE)
        data.reportPreference = [sender intValue];
    else if(selectingRow == DRIVER_DATA_ARPIN_SYNC_PREFERENCE)
        data.syncPreference = [sender intValue];
    else if(selectingRow == DRIVER_DATA_DRIVER_EMAIL_CC_BCC) {
        if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_NONE) {
            data.driverEmailCC = NO;
            data.driverEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_CC) {
            data.driverEmailCC = YES;
            data.driverEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_BCC) {
            data.driverEmailCC = NO;
            data.driverEmailBCC = YES;
        }
    } else if(selectingRow == DRIVER_DATA_PACKER_EMAIL_CC_BCC) {
        if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_NONE) {
            data.packerEmailCC = NO;
            data.packerEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_CC) {
            data.packerEmailCC = YES;
            data.packerEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_BCC) {
            data.packerEmailCC = NO;
            data.packerEmailBCC = YES;
        }
    } else if(selectingRow == DRIVER_DATA_HAULING_EMAIL_CC_BCC) {
        if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_NONE) {
            data.haulingAgentEmailCC = NO;
            data.haulingAgentEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_CC) {
            data.haulingAgentEmailCC = YES;
            data.haulingAgentEmailBCC = NO;
        }
        else if ([sender intValue] == PVO_DRIVER_EMAIL_TYPE_BCC) {
            data.haulingAgentEmailCC = NO;
            data.haulingAgentEmailBCC = YES;
        }
    }
    else
        data.buttonPreference = [sender intValue];
}

-(void)languageSelected:(NSNumber *)newID
{
    data.language = [newID intValue];
    [self.tableView reloadData];
}

-(void)updateTitleByDriverType:(int)driverType
{
    if (driverType == PVO_DRIVER_TYPE_PACKER)
        self.title = @"Packer";
    else
        self.title = @"Driver";
}

-(void)updateValueWithField:(UITextField*)fld
{
    switch (fld.tag) {
        case DRIVER_DATA_HAULING_AGENT:
            data.haulingAgent = fld.text;
            break;
        case DRIVER_DATA_SAFETY_NUMBER:
            data.safetyNumber = fld.text;
            break;
        case DRIVER_DATA_DRIVER_NAME:
            data.driverName = fld.text;
            break;
        case DRIVER_DATA_DRIVER_NUMBER:
            data.driverNumber = fld.text;
            break;
        case DRIVER_DATA_HAULING_EMAIL:
            data.haulingAgentEmail = fld.text;
            break;
        case DRIVER_DATA_DRIVER_EMAIL:
            data.driverEmail = fld.text;
            break;
        case DRIVER_DATA_UNIT_NUMBER:
            data.unitNumber = fld.text;
            break;
        case DRIVER_DATA_TRACTOR_NUMBER:
            data.tractorNumber = fld.text;
            break;
        case DRIVER_DATA_DRIVER_PASSWORD:
            data.driverPassword = fld.text;
            break;
        case DRIVER_DATA_PACKER_EMAIL:
            data.packerEmail = fld.text;
            break;
        case DRIVER_DATA_PACKER_NAME:
            data.packerName = fld.text;
            break;
    }
}

-(IBAction)done:(id)sender
{
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB updateDriverData:data];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    //right item, done
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    if(!editing)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.data = [del.surveyDB getDriverData];
        [del.surveyDB updateDriverData:self.data]; //makes sure theres a driver object
        
    }
    
    editing = NO;
    
    [super viewWillAppear:animated];
    
    [self initializeIncludedRows];
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

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [_sections count];
}

-(NSString*) tableView: (UITableView*)tv titleForHeaderInSection: (NSInteger) section
{
    NSNumber *key = [_sections objectAtIndex:section];
    NSArray *driverSection = [rows objectForKey:key];
    if ([driverSection count] == 0)
        return nil;
    
    switch ([key intValue]) {
        case DRIVER_DATA_SECTION_DRIVERPACKER:
            return data.driverType == PVO_DRIVER_TYPE_PACKER? @"Packer Options" : @"Driver Options";
        case DRIVER_DATA_SECTION_HAULINGAGENT:
            return @"Hauling Agent Options";
        case DRIVER_DATA_SECTION_APPLICATION_OPTIONS:
            return @"Application Customization";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *key = [_sections objectAtIndex:section];
    NSArray *driverSection = [rows objectForKey:key];
    return [driverSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
//    static NSString *DoubleSwitchCellIdentifier = @"DoubleSwitchCell";
    
    UITableViewCell *cell = nil;
    FloatingLabelTextCell* ltCell = nil;
    SwitchCell *swCell = nil;
    DoubleSwitchCell *doubleSwCell = nil;
    
    NSNumber *key = [_sections objectAtIndex:[indexPath section]];
    NSArray *section = [rows objectForKey:key];
    int row = [[section objectAtIndex:[indexPath row]] intValue];
    
    if(row == DRIVER_DATA_ROOM_CONDITIONS ||
       row == DRIVER_DATA_QUICK_INVENTORY ||
       row == DRIVER_DATA_SHOW_TRACTOR_TRAILER ||
       row == DRIVER_DATA_USE_SCANNER ||
       row == DRIVER_DATA_SAVE_TO_CAM_ROLL)
    {
        swCell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
        
        if (swCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
            swCell = [nib objectAtIndex:0];
            
            [swCell.switchOption addTarget:self
                                    action:@selector(switchChanged:) 
                          forControlEvents:UIControlEventValueChanged];
        }
        swCell.switchOption.tag = row;
        
        if(row == DRIVER_DATA_QUICK_INVENTORY)
        {
            swCell.switchOption.on = data.quickInventory;
            swCell.labelHeader.text = @"Quick Inventory";
        }
        else if(row == DRIVER_DATA_SHOW_TRACTOR_TRAILER)
        {
            swCell.switchOption.on = data.showTractorTrailerOptions;
            swCell.labelHeader.text = @"Show Tractor/Trailer";
        }
        else if(row == DRIVER_DATA_SAVE_TO_CAM_ROLL)
        {
            swCell.switchOption.on = data.saveToCameraRoll;
            swCell.labelHeader.text = @"Save Images To Camera Roll";
        }
        else if(row == DRIVER_DATA_ROOM_CONDITIONS)
        {            
            swCell.switchOption.on = data.enableRoomConditions;
            swCell.labelHeader.text = [AppFunctionality requiresPropertyCondition] ? @"Property Conditions" : @"Room Conditions";
        }
        else if(row == DRIVER_DATA_USE_SCANNER)
        {
            swCell.switchOption.on = data.useScanner;
            swCell.labelHeader.text = @"Use Scanner";
        }
    }
    else if(row == DRIVER_DATA_VANLINE ||
            row == DRIVER_DATA_SIGNATURE ||
            row == DRIVER_DATA_DAMAGE_VIEW || 
            row == DRIVER_DATA_REPORT_PREFERENCE ||
            row == DRIVER_DATA_ARPIN_SYNC_PREFERENCE ||
            row == DRIVER_DATA_DRIVER_TYPE ||
            row == DRIVER_DATA_PACKER_INITIALS ||
            row == DRIVER_DATA_HAULING_EMAIL_CC_BCC ||
            row == DRIVER_DATA_DRIVER_EMAIL_CC_BCC ||
            row == DRIVER_DATA_MOVE_HQ_SETTINGS ||
            row == DRIVER_DATA_PACKER_EMAIL_CC_BCC)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if(row == DRIVER_DATA_VANLINE)
        {
            NSString *vl = [vanlines objectForKey:[NSNumber numberWithInt:data.vanlineID]];
            if(vl == nil)
            {
                vl = [vanlines objectForKey:[NSNumber numberWithInt:data.vanlineID]];
            }
            
            cell.textLabel.text = [NSString stringWithFormat:@"Vanline: %@", vl];
        }
        else if(row == DRIVER_DATA_DAMAGE_VIEW)
        {
            NSString *dmg = [damageOptions objectForKey:[NSNumber numberWithInt:data.buttonPreference]];
            if(dmg == nil)
                cell.textLabel.text = @"Damage View: *No Preference*";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Damage View: %@", dmg];
        }
        else if(row == DRIVER_DATA_DRIVER_TYPE)
        {
            NSString *dmg = [driverTypes objectForKey:[NSNumber numberWithInt:data.driverType]];
            if(dmg == nil)
                cell.textLabel.text = @"Inventory Type: *No Selection*";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Inventory Type: %@", dmg];
        }
        else if(row == DRIVER_DATA_MOVE_HQ_SETTINGS)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ Settings",[del.pricingDB getCRMInstanceName:[del.pricingDB vanline]]];
        }
        else if(row == DRIVER_DATA_REPORT_PREFERENCE)
        {
            NSString *dmg = [reportOptions objectForKey:[NSNumber numberWithInt:data.reportPreference]];
            if(dmg == nil)
                cell.textLabel.text = @"Report Damage View: *No Preference*";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Report Dmg View: %@", dmg];
        }
        else if(row == DRIVER_DATA_ARPIN_SYNC_PREFERENCE)
        {
            NSString *dmg = [syncOptions objectForKey:[NSNumber numberWithInt:data.syncPreference]];
            cell.textLabel.text = [NSString stringWithFormat:@"Download: %@", dmg];
        }
        else if(row == DRIVER_DATA_SIGNATURE)
        {
            if (data != nil && data.driverType == PVO_DRIVER_TYPE_PACKER)
                cell.textLabel.text = @"Enter Packer Signature";
            else
                cell.textLabel.text = @"Enter Driver Signature";
        }
        else if (row == DRIVER_DATA_PACKER_INITIALS)
        {
            cell.textLabel.text = @"Enter Packer Initials";
        }
        else if (row == DRIVER_DATA_HAULING_EMAIL_CC_BCC)
        {
            int haulingEmailIndex = PVO_DRIVER_EMAIL_TYPE_NONE;
            if (data.haulingAgentEmailCC)
                haulingEmailIndex = PVO_DRIVER_EMAIL_TYPE_CC;
            else if (data.haulingAgentEmailBCC)
                haulingEmailIndex = PVO_DRIVER_EMAIL_TYPE_BCC;
                
            NSString *email = [emailOptions objectForKey:[NSNumber numberWithInt:haulingEmailIndex]];
            if (email == nil)
                cell.textLabel.text = @"Hauling Email Type";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Hauling Email Type: %@", email];
        }
        else if (row == DRIVER_DATA_DRIVER_EMAIL_CC_BCC)
        {
            int driverEmailIndex = PVO_DRIVER_EMAIL_TYPE_NONE;
            if (data.driverEmailCC)
                driverEmailIndex = PVO_DRIVER_EMAIL_TYPE_CC;
            else if (data.driverEmailBCC)
                driverEmailIndex = PVO_DRIVER_EMAIL_TYPE_BCC;
            
            NSString *email = [emailOptions objectForKey:[NSNumber numberWithInt:driverEmailIndex]];
            if (email == nil)
                cell.textLabel.text = @"Driver Email Type";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Driver Email Type: %@", email];
        } else if (row == DRIVER_DATA_PACKER_EMAIL_CC_BCC) {
            int packerEmailIndex = PVO_DRIVER_EMAIL_TYPE_NONE;
            if (data.packerEmailCC)
                packerEmailIndex = PVO_DRIVER_EMAIL_TYPE_CC;
            else if (data.packerEmailBCC)
                packerEmailIndex = PVO_DRIVER_EMAIL_TYPE_BCC;
            
            NSString *email = [emailOptions objectForKey:[NSNumber numberWithInt:packerEmailIndex]];
            if (email == nil)
                cell.textLabel.text = @"Packer Email Type";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Packer Email Type: %@", email];
        }
    }
    else
    {
//        ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];
//        if (ltCell == nil) {
//            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
//            ltCell = [nib objectAtIndex:0];
//            [ltCell setPVOView];
//            [ltCell.tboxValue addTarget:self 
//                                 action:@selector(textFieldDoneEditing:) 
//                       forControlEvents:UIControlEventEditingDidEndOnExit];
//            ltCell.tboxValue.delegate = self;
//        }
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FloatingLabelTextCell" owner:self options:nil];
        ltCell = [nib objectAtIndex:0];
        [ltCell.tboxValue setDelegate:self];
        ltCell.tboxValue.returnKeyType = UIReturnKeyDone;
        ltCell.accessoryType = UITableViewCellAccessoryNone;
        [ltCell.tboxValue addTarget:self
                           action:@selector(textFieldDoneEditing:)
                 forControlEvents:UIControlEventEditingDidEndOnExit];
        
        ltCell.tboxValue.tag = row;
        ltCell.tboxValue.secureTextEntry = NO;
        ltCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
        ltCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        
        switch (row) {
            case DRIVER_DATA_HAULING_AGENT:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                ltCell.tboxValue.placeholder = @"Hauling Agt #";
                ltCell.tboxValue.text = data.haulingAgent;
                break;
            case DRIVER_DATA_SAFETY_NUMBER:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                ltCell.tboxValue.placeholder = @"Safety #";
                ltCell.tboxValue.text = data.safetyNumber;
                break;
            case DRIVER_DATA_DRIVER_NAME:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeAlphabet;
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                ltCell.tboxValue.placeholder = @"Driver Name";
                ltCell.tboxValue.text = data.driverName;
                break;
            case DRIVER_DATA_PACKER_NAME:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeAlphabet;
                ltCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
                ltCell.tboxValue.placeholder = @"Packer Name";
                ltCell.tboxValue.text = data.packerName;
                break;
            case DRIVER_DATA_DRIVER_NUMBER:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                ltCell.tboxValue.placeholder = @"Driver #";
                ltCell.tboxValue.text = data.driverNumber;
                break;
            case DRIVER_DATA_HAULING_EMAIL:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                ltCell.tboxValue.placeholder = @"Hauling Agt Email";
                ltCell.tboxValue.text = data.haulingAgentEmail;
                break;
            case DRIVER_DATA_DRIVER_EMAIL:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                ltCell.tboxValue.placeholder = @"Driver Email";
                ltCell.tboxValue.text = data.driverEmail;
                break;
            case DRIVER_DATA_PACKER_EMAIL:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                ltCell.tboxValue.placeholder = @"Packer Email";
                ltCell.tboxValue.text = data.packerEmail;
                break;
            case DRIVER_DATA_UNIT_NUMBER:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                ltCell.tboxValue.placeholder = @"Trailer #";
                ltCell.tboxValue.text = data.unitNumber;
                break;
            case DRIVER_DATA_TRACTOR_NUMBER:
                ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                ltCell.tboxValue.placeholder = @"Tractor #";
                ltCell.tboxValue.text = data.tractorNumber;
                break;
            case DRIVER_DATA_DRIVER_PASSWORD:
                ltCell.tboxValue.placeholder = @"Driver Password";
                ltCell.tboxValue.text = data.driverPassword;
                ltCell.tboxValue.secureTextEntry = YES;
                break;
        }
        
    }
    
    return cell != nil ? cell : ltCell != nil ? (UITableViewCell*)ltCell : swCell != nil ? (UITableViewCell*)swCell : (UITableViewCell*)doubleSwCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *key = [_sections objectAtIndex:[indexPath section]];
    NSArray *section = [rows objectForKey:key];
    int row = [[section objectAtIndex:[indexPath row]] intValue];
    
    selectingRow = row;
    if(row == DRIVER_DATA_VANLINE)
    {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Vanline" 
                          withObjects:vanlines 
                 withCurrentSelection:[NSNumber numberWithInt:data.vanlineID] 
                           withCaller:self 
                          andCallback:@selector(valueSelected:) 
                     andNavController:self.navigationController];
    }
    else if(row == DRIVER_DATA_DAMAGE_VIEW)
    {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Damage View" 
                          withObjects:damageOptions 
                 withCurrentSelection:[NSNumber numberWithInt:data.buttonPreference] 
                           withCaller:self 
                          andCallback:@selector(valueSelected:) 
                     andNavController:self.navigationController];
    }
    else if(row == DRIVER_DATA_REPORT_PREFERENCE)
    {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Damage Report View" 
                          withObjects:reportOptions 
                 withCurrentSelection:[NSNumber numberWithInt:data.reportPreference] 
                           withCaller:self 
                          andCallback:@selector(valueSelected:) 
                     andNavController:self.navigationController];
    }
    else if (row == DRIVER_DATA_MOVE_HQ_SETTINGS)
    {
        editing = YES;
        
        EnterCredentialsController *ctl = [[EnterCredentialsController alloc] initWithStyle:UITableViewStyleGrouped];
        ctl.isMoveHQSettings = YES;
        PortraitNavController *navCtl = [[PortraitNavController alloc] initWithRootViewController:ctl];
        [self presentViewController:navCtl animated:YES completion:nil];
    }
    else if(row == DRIVER_DATA_ARPIN_SYNC_PREFERENCE)
    {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Download Method"
                          withObjects:syncOptions
                 withCurrentSelection:[NSNumber numberWithInt:data.syncPreference]
                           withCaller:self
                          andCallback:@selector(valueSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == DRIVER_DATA_DRIVER_TYPE)
    {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del pushPickerViewController:@"Inventory Type"
                          withObjects:driverTypes
                 withCurrentSelection:[NSNumber numberWithInt:data.driverType]
                           withCaller:self
                          andCallback:@selector(valueSelected:)
                     andNavController:self.navigationController];
    }
    else if(row == DRIVER_DATA_SIGNATURE)
    {
        editing = YES;
        
        
        if(sigView == nil)
            sigView = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
        
        sigView.delegate = self;
        sigView.saveBeforeDismiss = NO;

        sigNav = [[LandscapeNavController alloc] initWithRootViewController:sigView];
        
        [self presentViewController:sigNav animated:YES completion:nil];
    }
    else if (row == DRIVER_DATA_PACKER_INITIALS)
    {
        editing = YES;
        
        if (packerInitialController == nil)
            packerInitialController = [[PackerInitialsController alloc] initWithStyle:UITableViewStyleGrouped];
        
        packerInitialController.isModal = NO;
        [self.navigationController pushViewController:packerInitialController animated:YES];
        
//        UINavigationController *newNav = [[UINavigationController alloc] initWithRootViewController:packerInitialController];
//        [self presentViewController:newNav animated:YES completion:nil];
    }
    // 1035 OnTime Defect
    else if (row == DRIVER_DATA_HAULING_EMAIL_CC_BCC) {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        int index = PVO_DRIVER_EMAIL_TYPE_NONE;
        if (data.haulingAgentEmailCC)
            index = PVO_DRIVER_EMAIL_TYPE_CC;
        else if (data.haulingAgentEmailBCC)
            index = PVO_DRIVER_EMAIL_TYPE_BCC;
        
        [del pushPickerViewController:@"Hauling Email Type"
                          withObjects:emailOptions
                 withCurrentSelection:[NSNumber numberWithInt:index]
                           withCaller:self
                          andCallback:@selector(valueSelected:)
                     andNavController:self.navigationController];
    } else if (row == DRIVER_DATA_DRIVER_EMAIL_CC_BCC) {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        int index = PVO_DRIVER_EMAIL_TYPE_NONE;
        if (data.driverEmailCC)
            index = PVO_DRIVER_EMAIL_TYPE_CC;
        else if (data.driverEmailBCC)
            index = PVO_DRIVER_EMAIL_TYPE_BCC;
        
        [del pushPickerViewController:@"Driver Email Type"
                          withObjects:emailOptions
                 withCurrentSelection:[NSNumber numberWithInt:index]
                           withCaller:self
                          andCallback:@selector(valueSelected:)
                     andNavController:self.navigationController];
    } else if (row == DRIVER_DATA_PACKER_EMAIL_CC_BCC) {
        editing = YES;
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        int index = PVO_DRIVER_EMAIL_TYPE_NONE;
        if (data.packerEmailCC)
            index = PVO_DRIVER_EMAIL_TYPE_CC;
        else if (data.packerEmailBCC)
            index = PVO_DRIVER_EMAIL_TYPE_BCC;
        
        [del pushPickerViewController:@"Packer Email Type"
                          withObjects:emailOptions
                 withCurrentSelection:[NSNumber numberWithInt:index]
                           withCaller:self
                          andCallback:@selector(valueSelected:)
                     andNavController:self.navigationController];
    }
}

#pragma mark - UITextFieldDelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

#pragma mark - SignatureViewControllerDelegate methods

-(UIImage*)signatureViewImage:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *retval = [del.surveyDB getPVOSignature:-1
                                            forImageType:(data.driverType == PVO_DRIVER_TYPE_PACKER ? PVO_SIGNATURE_TYPE_PACKER : PVO_SIGNATURE_TYPE_DRIVER)];
    return retval == nil ? nil : [retval signatureData];
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.surveyDB savePVOSignature:-1
                      forImageType:(data.driverType == PVO_DRIVER_TYPE_PACKER ? PVO_SIGNATURE_TYPE_PACKER : PVO_SIGNATURE_TYPE_DRIVER)
                         withImage:signature];
}

@end
