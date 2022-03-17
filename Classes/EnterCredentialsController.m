//
//  EnterCredentialsController.m
//  Survey
//
//  Created by Tony Brame on 4/14/15.
//
//

#import "EnterCredentialsController.h"
#import "Prefs.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"
#import "FloatingLabelTextCell.h"

@interface EnterCredentialsController ()

@end

@implementation EnterCredentialsController

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
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Add "Save" button in top right
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                            target:self
                                                                                            action:@selector(cmdSaveClick:)];
    
    // Add "Cancel" button in top left
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cmdDoneClick:)];
    
    self.environments = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Dev", @"QA", @"UAT", @"PROD", nil]
                                                        forKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:PVO_DRIVER_CRM_ENVIRONMENT_DEV],
                                                                 [NSNumber numberWithInt:PVO_DRIVER_CRM_ENVIRONMENT_QA],
                                                                 [NSNumber numberWithInt:PVO_DRIVER_CRM_ENVIRONMENT_UAT],
                                                                 [NSNumber numberWithInt:PVO_DRIVER_CRM_ENVIRONMENT_PROD], nil]];
    
    // Change title based on version of application being run
    if (self.isMoveHQSettings)
        self.title = [NSString stringWithFormat:@"%@ Settings", [del.pricingDB getCRMInstanceName:[del.pricingDB vanline]]];
    else
        self.title = @"Enter Credentials";
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initializeIncludedRows];
    
    if (_isMoveHQSettings)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *data = [del.surveyDB getDriverData];
        
        self.reloCRMUsername = data.crmUsername;
        self.reloCRMPassword = data.crmPassword;
        self.selectedEnvironment = data.crmEnvironment;
        
        if(self.reloCRMUsername == nil)
            self.reloCRMUsername = @"";
        
        if(self.reloCRMPassword == nil)
            self.reloCRMPassword = @"";
    }
    else
    {
        self.username = [Prefs username];
        self.password = [Prefs password];
        self.betaPassword = [Prefs betaPassword];
        
        if(self.username == nil)
            self.username = @"";
        
        if(self.password == nil)
            self.password = @"";
        if(self.betaPassword == nil)
            self.betaPassword = @"";
    }
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)initializeIncludedRows
{
    _rows = [[NSMutableArray alloc] init];
    
    if (_isMoveHQSettings)
    {
        [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_RELOCRMUSERNAME]];
        [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_RELOCRMPASSWORD]];
        if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"crmenv"].location != NSNotFound) {
            [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_RELOCRMENVIRONMENT]];
        }
    }
    else
    {
        [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_USERNAME]];
        [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_PASSWORD]];
#if TARGET_IPHONE_SIMULATOR
        [_rows addObject:[NSNumber numberWithInt:ENTER_CREDENTIALS_BETAPASSWORD]];
#endif
    }
}

-(void)updateValueWithField:(UITextField*)tbox
{
    if(tbox.tag == ENTER_CREDENTIALS_USERNAME)
        self.username = tbox.text;
    else if(tbox.tag == ENTER_CREDENTIALS_PASSWORD)
        self.password = tbox.text;
    else if(tbox.tag == ENTER_CREDENTIALS_RELOCRMUSERNAME)
        self.reloCRMUsername = tbox.text;
    else if(tbox.tag == ENTER_CREDENTIALS_RELOCRMPASSWORD)
        self.reloCRMPassword = tbox.text;
    else if(tbox.tag == ENTER_CREDENTIALS_BETAPASSWORD)
        self.betaPassword = tbox.text;
    
}

// Action to be taken when "Save" is clicked in the top right
-(IBAction)cmdSaveClick:(id)sender
{
    if(self.tboxCurrent != nil)
        [self updateValueWithField:self.tboxCurrent];
    
    
    if (_isMoveHQSettings)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *data = [del.surveyDB getDriverData];
        [del.surveyDB saveCRMSettings:self.reloCRMUsername password:self.reloCRMPassword syncEnvironment:self.selectedEnvironment];
    }
    else
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setObject:self.username forKey:USERNAME_KEY];
        [defaults setObject:self.password forKey:PASSWORD_KEY];
#if TARGET_IPHONE_SIMULATOR
        [defaults setObject:self.betaPassword forKey:BETA_PASS_KEY];
#endif
        [defaults synchronize];
    }
    
    
    if (_isMoveHQSettings)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        [del showHideVC:del.splashView withHide:del.activationController];
        del.activationError = NO;
    }
    
    self.isMoveHQSettings = NO;
}

-(IBAction)cmdDoneClick:(id)sende
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)environmentSelected:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DriverData *data = [del.surveyDB getDriverData];
    int newValue = [sender intValue];
    data.crmEnvironment = newValue;
    
    [del.surveyDB saveCRMSettings:self.reloCRMUsername password:self.reloCRMPassword syncEnvironment:data.crmEnvironment];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_rows count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 100)];
    
    UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [footerText setTextAlignment:NSTextAlignmentCenter];
    footerText.font = [UIFont systemFontOfSize:12.0];
    footerText.numberOfLines = 0;
    if (!_isMoveHQSettings) {
        [footerText setText:@"Please enter your MoveHQ activation credentials."];
    }
    
    UIButton *privacyPolicy=[UIButton buttonWithType:UIButtonTypeCustom];
    privacyPolicy.frame = CGRectMake(0, 60, 320, 40);
    privacyPolicy.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [privacyPolicy.titleLabel setTextAlignment: NSTextAlignmentCenter];
    [privacyPolicy setTitle:@"View Privacy Policy" forState:UIControlStateNormal];
    [privacyPolicy addTarget:self action:@selector(goToPrivacyPolicy) forControlEvents:UIControlEventTouchUpInside];
    [privacyPolicy setTitleColor:[UIColor redColor] forState:UIControlStateNormal];  //Set the color this is may be different for iOS 7
    
    [footerView addSubview:footerText];
    [footerView addSubview:privacyPolicy];

    return footerView;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    int height = 20;
    for (UIView *subview in footer.subviews) {
        subview.center = CGPointMake(self.view.frame.size.width / 2, height);
        height += 60;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 100;
}

#define TEXT_CELL_ID @"TextCellID"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    FloatingLabelTextCell* textCell = nil;
    UITableViewCell *cell = nil;
    

    
    
    if (_isMoveHQSettings) {
        if(indexPath.row == 0 || indexPath.row == 1)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FloatingLabelTextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            [textCell.tboxValue addTarget:self
                                   action:@selector(textFieldDoneEditing:)
                         forControlEvents:UIControlEventEditingDidEndOnExit];
            textCell.tboxValue.delegate = self;
            
            textCell.tboxValue.tag = indexPath.row;
            textCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
            
            if(indexPath.row == 0)
            {//username
                textCell.tboxValue.tag = ENTER_CREDENTIALS_RELOCRMUSERNAME;
                
                textCell.tboxValue.placeholder = @"Username";
                textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textCell.tboxValue.text = self.reloCRMUsername;
            }
            else if (indexPath.row == 1)
            {
                textCell.tboxValue.tag = ENTER_CREDENTIALS_RELOCRMPASSWORD;
                
                textCell.tboxValue.placeholder = @"Password";
                textCell.tboxValue.secureTextEntry = YES;
                textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
                textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textCell.tboxValue.text = self.reloCRMPassword;
            }
        }
        else if (indexPath.row == 2)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            NSString *site = [_environments objectForKey:[NSNumber numberWithInt:self.selectedEnvironment]];
            if(site == nil)
                cell.textLabel.text = @"Environment: *No Preference*";
            else
                cell.textLabel.text = [NSString stringWithFormat:@"Environment: %@", site];
        }
        
    }
    else
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FloatingLabelTextCell" owner:self options:nil];
        textCell = [nib objectAtIndex:0];
        [textCell.tboxValue addTarget:self
                               action:@selector(textFieldDoneEditing:)
                     forControlEvents:UIControlEventEditingDidEndOnExit];
        textCell.tboxValue.delegate = self;
        
        textCell.tboxValue.tag = indexPath.row;
        textCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
        
        if(indexPath.row == 0)
        {//username
            textCell.tboxValue.tag = ENTER_CREDENTIALS_USERNAME;
            
            textCell.tboxValue.placeholder = @"Username";
            textCell.tboxValue.keyboardType = UIKeyboardTypeEmailAddress;
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textCell.tboxValue.text = self.username;
        }
        else if (indexPath.row == 1)
        {
            textCell.tboxValue.tag = ENTER_CREDENTIALS_PASSWORD;
            
            textCell.tboxValue.placeholder = @"Password";
            textCell.tboxValue.secureTextEntry = YES;
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textCell.tboxValue.text = self.password;
        }
        else
        {
            textCell.tboxValue.tag = ENTER_CREDENTIALS_BETAPASSWORD;
            
            textCell.tboxValue.placeholder = @"Config Code";
            textCell.tboxValue.secureTextEntry = NO;
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textCell.tboxValue.text = self.betaPassword;
        }
    }
    return textCell != nil ? textCell : cell;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"did select");
    
    if (self.isMoveHQSettings)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *data = [del.surveyDB getDriverData];
        
        [del pushPickerViewController:@"Select Environment"
                          withObjects:self.environments
                 withCurrentSelection:[NSNumber numberWithInt:data.crmEnvironment]
                           withCaller:self
                          andCallback:@selector(environmentSelected:)
                     andNavController:self.navigationController];
    }
}

#pragma mark - textfielddelegate methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateValueWithField:textField];
}
-(void)goToPrivacyPolicy
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.movehq.com/privacy-policy"]];
}

@end
