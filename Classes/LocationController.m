//
//  LocationController.m
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyAppDelegate.h"
#import "LocationController.h"
#import "AddressSummaryCell.h"
#import "TextWithHeaderCell.h"
#import "SurveyPhone.h"
#import	"SurveyLocation.h"
#import "EditAddressController.h"
#import "EditPhoneController.h"
#import "CustomerUtilities.h"
#import "AppFunctionality.h"
#import "FloatingLabelTextCell.h"

@implementation LocationController

@synthesize custID, locationID, locations, editAddressController, phoneController, imageViewer, dirty, addRows, lockFields, originPhone1, originPhone2, destPhone1, destPhone2;

#pragma mark - Lifecycle -
- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	
	self.preferredContentSize = CGSizeMake(320, 416);
	
    [super viewDidLoad];
    

}

- (void)viewWillAppear:(BOOL)animated {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    self.isPacker = data.driverType == PVO_DRIVER_TYPE_PACKER;
    
    lockFields = [AppFunctionality lockFieldsOnSourcedFromServer] && [CustomerUtilities customerSourcedFromServer];
    
	//load the arrays with customer data
	self.locations = [del.surveyDB getCustomerLocations:custID atOrigin:locationID == ORIGIN_LOCATION_ID];
    
    SurveyLocation *l = [locations objectAtIndex:0];
    l.phones = [del.surveyDB getCustomerPhones:custID withLocationID:locationID];
    for(SurveyPhone *phone in l.phones) {
        NSInteger typeId = phone.type.phoneTypeID;
        if (typeId == ORIGIN_PHONE_1) {
            if (originPhone1 == nil) originPhone1 = phone;
        } else if (typeId == ORIGIN_PHONE_2) {
            if (originPhone2 == nil) originPhone2 = phone;
        } else if (typeId == DESTINATION_PHONE_1) {
            if (destPhone1 == nil) destPhone1 = phone;
        } else if (typeId == DESTINATION_PHONE_2) {
            if (destPhone2 == nil) destPhone2 = phone;
        }
    }
    // Initializes phones if null after attempting to load
    self.originPhone1 = [self setupPhone:originPhone1 withPhoneTypeId:ORIGIN_PHONE_1];
    self.originPhone2 = [self setupPhone:originPhone2 withPhoneTypeId:ORIGIN_PHONE_2];
    self.destPhone1 = [self setupPhone:destPhone1 withPhoneTypeId:DESTINATION_PHONE_1];
    self.destPhone2 = [self setupPhone:destPhone2 withPhoneTypeId:DESTINATION_PHONE_2];
	
	if(editAddressController != nil)
	{
		if(editAddressController.saved)
			dirty = TRUE;
		
		editAddressController.saved = FALSE;
	}
	
	[self initializeAddRows];
	
    [super viewWillAppear:animated];
	
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	
	
	dirty = FALSE;
	
	[super viewWillDisappear:animated];
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


#pragma mark - Tableview methods -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [locations count] + ([addRows count] > 0 ? 3 : 2);
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section < [locations count])
        return 2;//one for origin/dest and one for photos
    else if(section == [locations count])
        return 1;
    else if(section == [locations count] + 1)
        return 2;
    else
        return [addRows count];
    
    return 0;
}

-(CGFloat) tableView: (UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if([indexPath section] < [locations count] && 
		[indexPath row] == 0)
		return 85;
	else
		return 44;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *AddressSummaryCellID = @"AddressSummaryCell";
    static NSString *TextWithHeaderCellID = @"TextWithHeaderCell";
    static NSString *BasicIdentifier = @"BasicCellID";
    static NSString *FloatingLabelTextCellID = @"FloatingLabelTextCell";
    
	AddressSummaryCell *addCell = nil;
	TextWithHeaderCell *thCell = nil;
    FloatingLabelTextCell *fCell = nil;
    // Set up the cell...
	UITableViewCell *cell = nil;
	CGRect rect;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if([indexPath section] < [locations count])
	{
        SurveyLocation *loc = [locations objectAtIndex:[indexPath section]];
		
		if([indexPath row] == 0)
		{//the address cell
			addCell = (AddressSummaryCell *)[tableView dequeueReusableCellWithIdentifier:AddressSummaryCellID];
			if (addCell == nil) {
				NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddressSummaryCell" owner:self options:nil];
				addCell = [nib objectAtIndex:0];
				addCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			addCell.labelName.text = loc.name;
			NSString *address;
			
			if([loc.address1 length] > 0 || [loc.city length] > 0 || [loc.state length]  > 0 || [loc.zip length] > 0)
            {
				address = [[NSString alloc] initWithFormat:@"%@%@\r\n%@, %@ %@",
                           ([indexPath section] == 0 ? @"" : [self combineStrings:[NSMutableArray arrayWithObjects:loc.companyName, loc.firstName, loc.lastName, nil] withSplitter:@", "]),
                           loc.address1, loc.city, loc.state, loc.zip];
            }
			else
				address = @"no data";
		
			addCell.labelAddress.text = address;
		}
		else
        {
            NSInteger *locationType = [(SurveyLocation*)[locations objectAtIndex:[indexPath section]] locationType];
            cell = [tableView dequeueReusableCellWithIdentifier:BasicIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicIdentifier];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.text = [NSString stringWithFormat:@"Manage Photos [%lu]",
                                   (unsigned long)[[del.surveyDB getImagesList:custID
                                                                 withPhotoType:IMG_LOCATIONS
                                                                     withSubID:locationType
                                                                  loadAllItems:NO] count]];
            cell.imageView.image = [UIImage imageNamed:@"img_photo.png"];
        }
	}
	else if([indexPath section] == [locations count])
	{//add new location        
        thCell = (TextWithHeaderCell *)[tableView dequeueReusableCellWithIdentifier:TextWithHeaderCellID];
        if (thCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
            thCell = [nib objectAtIndex:0];
            thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        thCell.labelHeader.textAlignment = NSTextAlignmentCenter;
        rect = thCell.labelHeader.frame;
        rect.size.width = 270;
        thCell.labelHeader.frame = rect;
        
        if(lockFields || self.isPacker)
            thCell.accessoryType = UITableViewCellAccessoryNone;
        else
            thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        thCell.labelHeader.text = @"Add New Location";
        thCell.labelText.text = @"";
	}
    else if([indexPath section] == [locations count] + 1)
    {
        //phones
        SurveyLocation *loc = [locations objectAtIndex:0]; //retrieve origin or dest location
        fCell = (FloatingLabelTextCell *)[tableView dequeueReusableCellWithIdentifier:FloatingLabelTextCellID];
        if (fCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FloatingLabelTextCell" owner:self options:nil];
            fCell = [nib objectAtIndex:0];
        }
        
        //fCell.tboxValue.enabled = (![AppFunctionality lockFieldsOnSourcedFromServer] || !info.sourcedFromServer);
        fCell.accessoryType = UITableViewCellAccessoryDetailButton;
        fCell.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
        fCell.tboxValue.returnKeyType = UIReturnKeyDone;
        fCell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
        fCell.tboxValue.clearsOnBeginEditing = NO;
        [fCell.tboxValue setDelegate:self];
        
        int phoneTypeId;
        if ([indexPath row] == PHONE_1) {
            phoneTypeId = [self isOrigin] ? ORIGIN_PHONE_1 : DESTINATION_PHONE_1;
            fCell.tboxValue.tag = PHONE_1;
        } else if ([indexPath row] == PHONE_2) {
            phoneTypeId = [self isOrigin] ? ORIGIN_PHONE_2 : DESTINATION_PHONE_2;
            fCell.tboxValue.tag = PHONE_2;
        }
        
        for (SurveyPhone *phone in loc.phones) {
            if(phone.type.phoneTypeID == phoneTypeId) {
                fCell.tboxValue.text = phone.number;
            }
        }
        fCell.tboxValue.placeholder = [del.surveyDB getPhoneTypeNameFromId:phoneTypeId];
        
        if(lockFields) {
            fCell.accessoryType = UITableViewCellAccessoryNone;
            fCell.userInteractionEnabled = NO;
        }
    } else {//additional
		cell = [tableView dequeueReusableCellWithIdentifier:BasicIdentifier];
		if (cell == nil) {
           cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicIdentifier];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
		
		int addRow = [[addRows objectAtIndex:[indexPath row]] intValue];
		switch (addRow) {
			case LOCATIONS_ADD_ACC://acc
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Accessorials";
				cell.imageView.image = [UIImage imageNamed:@"img_survey.png"];
				break;
			case LOCATIONS_ADD_TP://third pty
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Third Party";
				cell.imageView.image = [UIImage imageNamed:@"img_third_party.png"];
				break;
			case LOCATIONS_ADD_VAN_OP://van op			
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"Van Operator";
				cell.imageView.image = [UIImage imageNamed:@"van_operator.png"];			
				break;
			case LOCATIONS_ADD_AK://ak
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = @"AK Info";
				cell.imageView.image = [UIImage imageNamed:@"alaska.png"];			
				break;
		}
		
	}
    
	if(addCell != nil)
		cell = addCell;
	else if(thCell != nil)
		cell = thCell;
    else if(fCell != nil)
        cell = fCell;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyLocation *newLoc;
	
	if([indexPath section] < [locations count]) {
        if(indexPath.row == 0) {
            if(editAddressController == nil)
                editAddressController = [[EditAddressController alloc] initWithStyle:UITableViewStyleGrouped];
            
            SurveyLocation *loc = [locations objectAtIndex:[indexPath section]];
            editAddressController.newLocation = FALSE;
            editAddressController.extraStop = (loc.locationType != ORIGIN_LOCATION_ID && loc.locationType != DESTINATION_LOCATION_ID);
            editAddressController.location = loc;
            [self.navigationController pushViewController:editAddressController	animated:YES];
        } else {
            NSInteger *locationType = [(SurveyLocation*)[locations objectAtIndex:[indexPath section]] locationType];

            if(imageViewer == nil)
                self.imageViewer = [[SurveyImageViewer alloc] init];
            
            imageViewer.photosType = IMG_LOCATIONS;
            imageViewer.customerID = custID;
            imageViewer.subID = locationType;
            imageViewer.caller = self.view;
            imageViewer.viewController = self;
            imageViewer.dismissDelegate = self;
            imageViewer.dismissCallback = @selector(reloadData);
            
            [imageViewer loadPhotos];
            
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
	} else if([indexPath section] == [locations count]) {
        //add new
        if(lockFields) {
            [SurveyAppDelegate showAlert:@"Unable to modify location data since the shipment was downloaded from the Server.  Please redownload to retrieve any new changes from registration." withTitle:@"Edit Disabled"];
            return;
        } else if (self.isPacker) {
            [SurveyAppDelegate showAlert:@"Unable to modify location in Packer Mode." withTitle:@"Edit Disabled"];
            return;
        }
        
		if(editAddressController == nil)
			editAddressController = [[EditAddressController alloc] initWithStyle:UITableViewStyleGrouped];
        
        newLoc = [[SurveyLocation alloc] init];
        newLoc.custID = del.customerID;
        newLoc.isOrigin = locationID == ORIGIN_LOCATION_ID;
        editAddressController.location = newLoc;
        editAddressController.newLocation = TRUE;
        editAddressController.extraStop = TRUE;
		[self.navigationController pushViewController:editAddressController	animated:YES];
    } else if([indexPath section] == [locations count] + 1) {
        // do nothing. no action to be taken when selected as fields are now static.
    } else {//additional row
		
	}
	
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    SurveyLocation *myLoc = [locations objectAtIndex:0];
	if([indexPath section] < [locations count])
	{
		if([indexPath section] > 0 && [indexPath row] == 0)
			return YES;
	}
		
    return NO;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    if(lockFields)
    {
        [SurveyAppDelegate showAlert:@"Unable to modify location data since the shipment was downloaded from the Server.  Please redownload to retrieve any new changes from registration." withTitle:@"Edit Disabled"];
        return;
    }
    
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		if([indexPath section] < [locations count])
		{
			SurveyLocation *removeLocation = [locations objectAtIndex:[indexPath section]];
			[del.surveyDB deleteLocation:removeLocation];
			[locations removeObjectAtIndex:[indexPath section]];
			dirty = TRUE;
            [tv deleteSections:[NSIndexSet indexSetWithIndex:[indexPath section]] 
              withRowAnimation:UITableViewRowAnimationFade];
		}
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SurveyPhone* phone;
    if ([indexPath section] == [locations count] + 1) {
        if (indexPath.row == PHONE_1) {
            if ([self isOrigin]) {
                phone = originPhone1;
            } else {
                phone = destPhone1;
            }
        } else if (indexPath.row == PHONE_2 ) {
            if ([self isOrigin]) {
                phone = originPhone2;
            } else {
                phone = destPhone2;
            }
        }
        calling = phone;
        
        //call or text the phone number...
        [self callOrTextPhone: phone];
    }
}

#pragma mark - Action Sheet Delegate -

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		NSURL *url;
		
		NSMutableString *num = [[NSMutableString alloc] initWithString:calling.number];
		[num replaceOccurrencesOfString:@"(" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
		[num replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
		[num replaceOccurrencesOfString:@")" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];
		[num replaceOccurrencesOfString:@"-" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, num.length)];		
		
		if(buttonIndex == 0)
		{
			url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", num]];
		}
		else 
		{
			url = [NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", num]];
		}
		
		if([[UIApplication sharedApplication] canOpenURL:url])
			[[UIApplication sharedApplication] openURL:url];
		else
			[SurveyAppDelegate showAlert:@"Your device does not support this type of functionality." withTitle:@"Error"];

		
	}
}

-(NSString*)combineStrings:(NSArray*)strings withSplitter:(NSString*)split
{
    if (strings == nil || split == nil)
        return @"";
    
    NSString *retval = [NSString stringWithFormat:@""];
    for (NSString *str in strings) {
        if (str != nil && str.length > 0) {
            retval = [retval stringByAppendingFormat:@"%@%@", (retval.length > 0 ? split : @""), str];
        }
    }
    
    if (retval.length > 0)
        retval = [retval stringByAppendingString:@"\r\n"];
    
    return retval;
}

#pragma mark - UITextFieldDelegate -

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    //self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateCustomerValueWithField:textField];
    if (textField.tag == PHONE_1) {
        if ([self isOrigin]) {
            [self insertOrUpdatePhone:originPhone1];
        } else {
            [self insertOrUpdatePhone:destPhone1];

        }
    } else if (textField.tag == PHONE_2) {
        if ([self isOrigin]) {
            [self insertOrUpdatePhone:originPhone2];
        } else {
            [self insertOrUpdatePhone:destPhone2];

        }
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self setPhoneNumberForTextField:textField withNumber:@""];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSInteger tag = textField.tag;
    if(tag != PHONE_1 && tag != PHONE_2)
        return YES;
    
    //get my current string...
    NSMutableString *str = [[NSMutableString alloc] initWithString:textField.text];
    
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
    [self setPhoneNumberForTextField:textField withNumber:newString];
    textField.text = newString;
    
    return NO;
}

#pragma mark - Helpers -

-(void)initializeAddRows
{
    if(addRows == nil)
        addRows = [[NSMutableArray alloc] init];
    
    [addRows removeAllObjects];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(del.viewType != OPTIONS_PVO_VIEW)
    {
        [addRows addObject:[NSNumber numberWithInt:LOCATIONS_ADD_ACC]];
        [addRows addObject:[NSNumber numberWithInt:LOCATIONS_ADD_TP]];
        
    }
}
-(BOOL)isOrigin {
    return locationID == ORIGIN_LOCATION_ID;
}

- (void)setPhoneNumberForTextField:(UITextField * _Nonnull)textField withNumber:(NSString*) number {
    if(textField.tag == PHONE_1) {
        if ([self isOrigin]) {
            originPhone1.number = number;
        } else {
            destPhone1.number = number;
        }
    } else if(textField.tag == PHONE_2) {
        if ([self isOrigin]) {
            originPhone2.number = number;
        } else {
            destPhone2.number = number;
        }
    }
}

- (void)callOrTextPhone:(SurveyPhone*) phone {
    if([phone.number length] == 0)
        [SurveyAppDelegate showAlert:@"You must have a phone number entered to call or text." withTitle:@"Number Required"];
    else
    { //ask them to perform actions - call/sms
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"What action would you like to take for this phone number?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Call", @"SMS Message", nil];
        [sheet showInView:self.view];
    }
}

-(void)updateCustomerValueWithField:(UITextField*)fld
{
    [self setPhoneNumberForTextField:fld withNumber:fld.text];
}

- (SurveyPhone*)setupPhone:(SurveyPhone*)phone withPhoneTypeId:(NSInteger)typeId {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (phone == nil) {
        phone = [[SurveyPhone alloc] init];
        phone.number = @"";
        phone.locationID = locationID;
        phone.isPrimary = 0;
        phone.type.phoneTypeID = typeId;
        phone.type.name = [del.surveyDB getPhoneTypeNameFromId:typeId];
    }
    return phone;
}

-(void)insertOrUpdatePhone:(SurveyPhone*)phone {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *phone1 = [del.surveyDB getCustomerPhone:custID withLocationID:phone.locationID andPhoneType:phone.type.name];
    if(phone1 != nil) {
        [del.surveyDB updatePhone:phone];
    } else {
        phone.custID = custID;
        [del.surveyDB insertPhone:phone];
    }
}

@end

