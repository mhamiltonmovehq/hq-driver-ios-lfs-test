//
//  EditPhoneController.m
//  Survey
//
//  Created by Tony Brame on 5/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditPhoneController.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"
#import "PhoneTypeController.h"
#import "SwitchCell.h"

@implementation EditPhoneController

@synthesize phone, tboxCurrent, newPhone, phoneTypeController, originalPhoneTypeID, locationID, primaryChanged, oldPhone;

- (void)viewWillAppear:(BOOL)animated {
        if(phoneTypeController == nil)
        {
            phoneTypeController = [[PhoneTypeController alloc] initWithStyle:UITableViewStyleGrouped];
            phoneTypeController.preferredContentSize = self.preferredContentSize;
            
        }
    
    phoneTypeController.originalTypeID = originalPhoneTypeID;
    primaryChanged = false;
    
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}


-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
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


- (void)viewDidLoad 
{
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	
	//if new customer view, add buttons and handlers.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self
																						   action:@selector(save:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
}

//functions called when in the new customer view
-(IBAction)save:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if(tboxCurrent != nil)
	{
		phone.number = tboxCurrent.text;
		tboxCurrent = nil;
	}
	
	if(newPhone == YES)
	{
		if(phone.type == nil)
		{//user must select a type to continue
			[SurveyAppDelegate showAlert:@"You must select a phone type to Save." withTitle:@"Type"];
			return;
		}
		[del.surveyDB insertPhone:phone];
        if (primaryChanged) {
            [self updatePrimaryPhones];
        }
	}
	else
	{
		if(originalPhoneTypeID != phone.type.phoneTypeID)
		{
			[del.surveyDB updatePhoneType:phone.type.phoneTypeID 
			 withOldPhoneTypeID:originalPhoneTypeID 
			 withCustomerID:del.customerID 
			 andLocationID:phone.locationID];
		}
        
        if (primaryChanged) {
            [self updatePrimaryPhones];
        } else {
            [del.surveyDB updatePhone:phone];
        }
	}
	
	//call cancel to clear the view
	[self cancel:nil];
	
}


-(IBAction)cancel:(id)sender
{
	@try 
	{
		[self.navigationController popViewControllerAnimated:YES];
		
		phone = nil;
		
	}
	@catch(NSException *exc)
	{
		[SurveyAppDelegate handleException:exc];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(BOOL)viewHasCriticalDataToSave
{
    return YES;
}
-(void)updatePrimaryPhones {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    oldPhone = [del.surveyDB getPrimaryPhone:del.customerID];
    
    oldPhone.isPrimary = 0;
    phone.isPrimary = 1;
    
    [del.surveyDB updatePhone:oldPhone];
    [del.surveyDB updatePhone:phone];
    
    primaryChanged = false;
}

-(IBAction)switchChanged:(id)sender
{
    UISwitch *sw = sender;
    
    if (sw.on) {
        primaryChanged = true;
       
    } else {
        [SurveyAppDelegate showAlert:@"To change primary number, enable primary on another phone." withTitle:@"Cannot Disable Primary Number"];
        sw.on = YES;
    }
}
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return phone.locationID == -1 ? 1 : EDIT_PHONE_SECTIONS;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *TextCellID = @"TextCellID";
    static NSString *SimpleCellID = @"SimpleCellID";
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    
    UITableViewCell *cell;
	TextCell *textCell;
    SwitchCell *swCell = nil;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    if([indexPath section] == EDIT_PHONE_NUMBER) {
		textCell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:TextCellID];
		if (textCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
			textCell = [nib objectAtIndex:0];
			
			[textCell.tboxValue setDelegate:self];
			textCell.tboxValue.returnKeyType = UIReturnKeyDone;
			[textCell.tboxValue addTarget:self
			 action:@selector(textFieldDoneEditing:)
			 forControlEvents:UIControlEventEditingDidEndOnExit];
			textCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
			textCell.tboxValue.placeholder = @"Phone";
		}
		
		textCell.tboxValue.text = phone.number;
		
		cell = textCell;
	}
    else {
        

        int row = indexPath.row;
        if(row == 0) {
            
            swCell =  (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];
            
            if (swCell == nil) {
                NSArray *nib = [[NSBundle mainBundle]
                                loadNibNamed:@"SwitchCell" owner:self options:nil];
                swCell = [nib objectAtIndex:0];
                [swCell.switchOption addTarget:self
                                        action:@selector(switchChanged:)
                              forControlEvents:UIControlEventValueChanged];
            }
            swCell.labelHeader.text = @"Primary Number";
            
            swCell.switchOption.on = phone.isPrimary == 1;
            
            if([del.surveyDB getPrimaryPhone:del.customerID] == nil) {
                swCell.switchOption.on = YES;
                phone.isPrimary = 1;
            }
            
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:SimpleCellID];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleCellID];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            if(phone.type == nil || phone.type.phoneTypeID == 0) {
                if(phone.type.phoneTypeID == 0)
                    self.title = @"Select Phone Type";
                cell.textLabel.text = @"Select Phone Type";
            }
            else
                cell.textLabel.text = phone.type.name;
        }
    }
    return swCell != nil ? swCell : cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath section] == EDIT_PHONE_NUMBER)
		return nil;	
	else
		return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (indexPath.row > 0) {
//        if(phoneTypeController == nil)
//        {
//            phoneTypeController = [[PhoneTypeController alloc] initWithStyle:UITableViewStyleGrouped];
//            phoneTypeController.preferredContentSize = self.preferredContentSize;
//        }
        
        phoneTypeController.locationID = phone.locationID;
        
        if(phone.type != nil)
        {
            phoneTypeController.selectedType = phone.type;
            //phoneTypeController.originalTypeID = phone.type.phoneTypeID;
        }
        else
        {
            phoneTypeController.selectedType = nil;
            phoneTypeController.originalTypeID = -1;
        }
        [self.navigationController pushViewController:phoneTypeController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
	phone.number = textField.text;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	phone.number = @"";
	
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	//get my current string...
	NSMutableString *str = [[NSMutableString alloc] initWithString:phone.number];
	
	//they are deleting the number before the dash, delete both...
	if(range.location == 4 && range.length == 1)
	{
		range.location = 3;
		range.length = 2;
	}
	//insert string
	[str replaceCharactersInRange:range withString:string];
	
	
	[str replaceOccurrencesOfString:@"(" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
	[str replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
	[str replaceOccurrencesOfString:@")" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
	[str replaceOccurrencesOfString:@"-" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, str.length)];
	
	NSMutableString *newString = [[NSMutableString alloc] init];
	if([str length] > 10)
	{
		//do nothing
		[newString appendString:str];
	}
	else if([str length] > 7)
	{//(xxx) xxx-xxxx format
		[newString appendString:@"("];
		for(int i = 0; i < 3; i++)
		{
			[newString appendFormat:@"%C", [str characterAtIndex:i]];
		}
		[newString appendString:@") "];
		for(int i = 3; i < 6; i++)
		{
			[newString appendFormat:@"%C", [str characterAtIndex:i]];
		}
		[newString appendString:@"-"];
		for(int i = 6; i < [str length]; i++)
		{
			[newString appendFormat:@"%C", [str characterAtIndex:i]];
		}
	}
	else 
	{//xxx-xxxx format
		for(int i = 0; i < 3; i++)
		{
			if([str length] > i)
				[newString appendFormat:@"%C", [str characterAtIndex:i]];
		}
		if([str length] > 3)
			[newString appendString:@"-"];
		for(int i = 3; i < [str length]; i++)
		{
			[newString appendFormat:@"%C", [str characterAtIndex:i]];
		}
	}

	
	phone.number = newString;
	
	textField.text = phone.number;
	
	return NO;
}

@end

