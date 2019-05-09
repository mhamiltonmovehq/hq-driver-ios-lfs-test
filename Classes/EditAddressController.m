//
//  EditAddressController.m
//  Survey
//
//  Created by Tony Brame on 5/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditAddressController.h"
#import "DoubleTextCell.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"
#import "ButtonCell.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"

@implementation EditAddressController

@synthesize location, tboxCurrent, newLocation, rows, saved, extraStop;
@synthesize lockFields;


- (void)viewWillAppear:(BOOL)animated {
    
    saved = FALSE;
    
    lockFields = ([AppFunctionality lockFieldsOnSourcedFromServer] && [CustomerUtilities customerSourcedFromServer]);
    
    [self initializeRows];
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)initializeRows
{
    if(rows == nil)
        rows = [[NSMutableArray alloc] init];
    
    [rows removeAllObjects];
    
    if(newLocation)
        [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_NAME]];
    
    if(extraStop)
    {
        [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_LAST_NAME]];
        [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_FIRST_NAME]];
        [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_COMPANY_NAME]];
    }
    
    [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_ADDRESS1]];
    [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_ADDRESS2]];
    [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_CITY]];
    
    [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_SZ_ROW]];

    
    [rows addObject:[NSNumber numberWithInt:EDIT_ADDRESS_TAKE_ME]];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)countySelected:(NSString*)county
{
    location.county = county;
}

-(void)stateSelected:(NSString*)state
{
    location.state = state;
}

//functions called when in the new customer view
-(IBAction)save:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
    {
        [self updateLocationValueWithField:tboxCurrent];
    }
    
    //check to make sure they entered a zip, and it is valid
    if(newLocation)//create the new location
    {
        if([location.name length] == 0)
        {
            [SurveyAppDelegate showAlert:@"Please enter a name for this location." withTitle:@"Location Name"];
            return;
        }
        location.locationID = [del.surveyDB insertLocation:location];
    }
    else
        [del.surveyDB updateLocation:location];    
    
    saved = TRUE;
    
    //call cancel to clear the view
    [self cancel:nil];
    
}


-(IBAction)cancel:(id)sender
{
    @try 
    {
        [self.view endEditing:NO]; //defect 622, prevent switching from local -> interstate and still edit
        
        [self.navigationController popViewControllerAnimated:YES];
//        self.location = nil;
    }
    @catch(NSException *exc)
    {
        [SurveyAppDelegate handleException:exc];
    }
}

-(void)updateLocationValueWithField:(UITextField*)fld
{
    if(location == nil)
        return;
    
    switch (fld.tag) 
    {
        case EDIT_ADDRESS_ADDRESS1:
            location.address1 = fld.text;
            break;
        case EDIT_ADDRESS_ADDRESS2:
            location.address2 = fld.text;
            break;
        case EDIT_ADDRESS_CITY:
            location.city = fld.text;
            break;
        case EDIT_ADDRESS_STATE:
            location.state = fld.text;
            break;
        case EDIT_ADDRESS_ZIP:
            location.zip = fld.text;
            break;
        case EDIT_ADDRESS_NAME:
            location.name = fld.text;
            break;
        case EDIT_ADDRESS_COMPANY_NAME:
            location.companyName = fld.text;
            break;
        case EDIT_ADDRESS_FIRST_NAME:
            location.firstName = fld.text;
            break;
        case EDIT_ADDRESS_LAST_NAME:
            location.lastName = fld.text;
            break;
    }
    
}

-(void)gotoAddress
{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB updateLocation:location];    
    
    NSString *query = [location buildQueryString];
    
    NSURL *url  = [NSURL URLWithString:
                   [NSString stringWithFormat:@"maps://maps.google.com/maps?t=m&q=%@", 
                    [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    if([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url];
    else
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Cannot open url provided %@", [url absoluteString]]  withTitle:@"Error"];
    
}

-(void)theyWantToGoToAddress:(id)sender
{
    
    //make sure address is complete, confirm move, save, send to maps
    
    if(tboxCurrent != nil)
    {
        [self updateLocationValueWithField:tboxCurrent];
        tboxCurrent = nil;
    }
    
    if([location.address1 length] == 0 || 
       [location.city length] == 0 || 
       [location.state length] == 0 || 
       [location.zip length] == 0)
    {
        [SurveyAppDelegate showAlert:@"Please ensure that all fields are populated before attempting to load map." withTitle:@"Information"];
    }
    else
    {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:
                                [NSString stringWithFormat:@"WARNING: This action will launch the external Maps application for this location. "
                                " %@ is not responsible for any directions provided which may not account for truck routes.", @"Mobile Mover"]
                                                           delegate:self 
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:@"Continue" 
                                                  otherButtonTitles:nil];
        
        [sheet showInView:self.view];
    }
    
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
     
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad 
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    self.preferredContentSize = CGSizeMake(320, 416);
    //if new customer view, add buttons and handlers.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    
}


- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [rows count];
}


-(int)getRowTypeFromIndex:(NSIndexPath*)path
{
    return [[rows objectAtIndex:path.row] intValue];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DoubleTextCellID = @"DoubleTextCell";
    static NSString *TextCellID = @"TextCell";
    static NSString *ButtonCellID = @"ButtonCell";
    
    UITableViewCell *cell = nil;
    DoubleTextCell *dblTextCell = nil;
    TextCell *textCell = nil;
    ButtonCell *buttonCell = nil;
    
    int row = [self getRowTypeFromIndex:indexPath];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *surveyCustomer = [del.surveyDB getCustomer:del.customerID];
    NSString *stateLabel, *zipLabel;
    BOOL isCanadian = [surveyCustomer isCanadianCustomer];
    if (isCanadian)
    {
        stateLabel = @"Prov";
        zipLabel = @"PC";
    }
    else
    {
        stateLabel = @"ST";
        zipLabel = @"ZIP";
    }
    
    if(row == EDIT_ADDRESS_ADDRESS1 || 
       row == EDIT_ADDRESS_ADDRESS2 || 
       row == EDIT_ADDRESS_CITY || 
       row == EDIT_ADDRESS_NAME || 
       row == EDIT_ADDRESS_ZIP ||
       row == EDIT_ADDRESS_COMPANY_NAME ||
       row == EDIT_ADDRESS_FIRST_NAME ||
       row == EDIT_ADDRESS_LAST_NAME)
    {
        textCell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:TextCellID];
        if (textCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
            textCell = [nib objectAtIndex:0];
            
            textCell.accessoryType = UITableViewCellAccessoryNone;
            [textCell.tboxValue setDelegate:self];
            textCell.tboxValue.returnKeyType = UIReturnKeyDone;
            [textCell.tboxValue addTarget:self 
             action:@selector(textFieldDoneEditing:) 
             forControlEvents:UIControlEventEditingDidEndOnExit];
            textCell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        }
        
        
        textCell.tboxValue.enabled = !lockFields;
        
        textCell.tboxValue.tag = row;        
        
        if(row == EDIT_ADDRESS_ADDRESS1)
        {
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textCell.tboxValue.text = location.address1;
            textCell.tboxValue.placeholder = @"Address 1";
        }
        else if(row == EDIT_ADDRESS_ADDRESS2)
        {
            textCell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textCell.tboxValue.text = location.address2;
            textCell.tboxValue.placeholder = @"Address 2";
        }
        else if(row == EDIT_ADDRESS_CITY)
        {
            textCell.tboxValue.text = location.city;
            textCell.tboxValue.placeholder = @"City";
        }
        else if(row == EDIT_ADDRESS_NAME)
        {
            textCell.tboxValue.text = location.name;
            textCell.tboxValue.placeholder = @"Location Name";
        }
        else if(row == EDIT_ADDRESS_ZIP)
        {
            textCell.tboxValue.text = location.zip;
            textCell.tboxValue.placeholder = zipLabel;
        }
        else if(row == EDIT_ADDRESS_COMPANY_NAME)
        {
            textCell.tboxValue.text = location.companyName;
            textCell.tboxValue.placeholder = @"Company Name";
        }
        else if(row == EDIT_ADDRESS_FIRST_NAME)
        {
            textCell.tboxValue.text = location.firstName;
            textCell.tboxValue.placeholder = @"First Name";
        }
        else if(row == EDIT_ADDRESS_LAST_NAME)
        {
            textCell.tboxValue.text = location.lastName;
            textCell.tboxValue.placeholder = @"Last Name";
        }
        
        
        if(tboxCurrent == textCell.tboxValue)
            tboxCurrent = nil;
        
        cell = textCell;
    
    }
    else if(row == EDIT_ADDRESS_SZ_ROW)
    {
        dblTextCell = (DoubleTextCell *)[tableView dequeueReusableCellWithIdentifier:DoubleTextCellID];
        if (dblTextCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DoubleTextCell" owner:self options:nil];
            dblTextCell = [nib objectAtIndex:0];
            
            dblTextCell.accessoryType = UITableViewCellAccessoryNone;
            [dblTextCell.tboxLeft setDelegate:self];
            dblTextCell.tboxLeft.returnKeyType = UIReturnKeyDone;
            [dblTextCell.tboxLeft addTarget:self 
             action:@selector(textFieldDoneEditing:) 
             forControlEvents:UIControlEventEditingDidEndOnExit];
            dblTextCell.tboxLeft.keyboardType = UIKeyboardTypeASCIICapable;
            dblTextCell.tboxLeft.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            
            [dblTextCell.tboxRight setDelegate:self];
            dblTextCell.tboxRight.returnKeyType = UIReturnKeyDone;
            [dblTextCell.tboxRight addTarget:self
             action:@selector(textFieldDoneEditing:) 
             forControlEvents:UIControlEventEditingDidEndOnExit];
            dblTextCell.tboxRight.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        }
        
        dblTextCell.tboxLeft.enabled = !lockFields;
        dblTextCell.tboxRight.enabled = !lockFields;
        
        
        dblTextCell.tboxLeft.placeholder = stateLabel;
        dblTextCell.tboxLeft.text = location.state;
        dblTextCell.tboxLeft.tag = EDIT_ADDRESS_STATE;
        dblTextCell.tboxRight.placeholder = zipLabel;
        dblTextCell.tboxRight.text = location.zip;
        dblTextCell.tboxRight.tag = EDIT_ADDRESS_ZIP;
        if (isCanadian)
        {//canadian zips are alphanumeric and start with a letter, and should be capital letters
            dblTextCell.tboxRight.keyboardType = UIKeyboardTypeAlphabet;
            dblTextCell.tboxRight.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        }
        
        if(tboxCurrent == dblTextCell.tboxLeft || tboxCurrent == dblTextCell.tboxRight)
            tboxCurrent = nil;
        
        cell = dblTextCell;
    }
    else
    {
        buttonCell = (ButtonCell *)[tableView dequeueReusableCellWithIdentifier:ButtonCellID];
        if (buttonCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
            buttonCell = [nib objectAtIndex:0];
            
            buttonCell.accessoryType = UITableViewCellAccessoryNone;
            buttonCell.caller = self;
            buttonCell.callback = @selector(theyWantToGoToAddress:);
        }
        
        [buttonCell.cmdButton setTitle:@"Take Me Here" forState:UIControlStateNormal];
        
        cell = buttonCell; 
        
    }
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    int row = [self getRowTypeFromIndex:indexPath];
//    
    
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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


#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateLocationValueWithField:textField];
}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        [self gotoAddress];
    }
}


@end

