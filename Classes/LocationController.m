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

@implementation LocationController

@synthesize custID, locationID, locations, editAddressController, phoneController, imageViewer;
@synthesize dirty;
@synthesize addRows;
@synthesize lockFields;


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
	
	self.preferredContentSize = CGSizeMake(320, 416);
	
    [super viewDidLoad];
}


/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
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

- (void)viewWillAppear:(BOOL)animated {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    self.isPacker = data.driverType == PVO_DRIVER_TYPE_PACKER;
    
    lockFields = [AppFunctionality lockFieldsOnSourcedFromServer] && [CustomerUtilities customerSourcedFromServer];
    
	//load the arrays with customer data
	self.locations = [del.surveyDB getCustomerLocations:custID atOrigin:locationID == ORIGIN_LOCATION_ID];
    SurveyLocation *l = [locations objectAtIndex:0];
    l.phones = [del.surveyDB getCustomerPhones:custID withLocationID:locationID];
    SurveyPhone* primaryPhone = [del.surveyDB getPrimaryPhone:del.customerID];
    
    if (primaryPhone != nil) {
        [l.phones insertObject:primaryPhone atIndex:0];
    }
    
    //this gets the primary phone number and shows it at both origin and destination
//    NSArray *uhThisVariableHoldsTheArrayThatHoldsThePrimaryNumber;
//    uhThisVariableHoldsTheArrayThatHoldsThePrimaryNumber = [del.surveyDB getCustomerPhones:custID withLocationID:-1];
//    if([uhThisVariableHoldsTheArrayThatHoldsThePrimaryNumber count] > 0)
//        [l.phones insertObject:[uhThisVariableHoldsTheArrayThatHoldsThePrimaryNumber objectAtIndex:0] 
//                     atIndex:0];
    
    
    
    
    
    
	//load image if it has one.
	/*NSMutableArray *arr = [del.surveyDB getImagesList:custID withPhotoType:IMG_LOCATIONS 
						   withSubID:[[locations objectAtIndex:0] locationID] loadAllItems:NO];
	if(locationImage != nil)
	{
		[Image release];
		locationImage = nil;
	}
	imagesCount = 0;
	if(arr != nil && [arr count] > 0)
	{
		NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
		SurveyImage *image = [arr objectAtIndex:0];
		NSString *filePath = image.path;
		NSString *fullPath = [docsDir stringByAppendingPathComponent:filePath];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if([fileManager fileExistsAtPath:fullPath])
		{
			UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
			locationImage = [SurveyAppDelegate resizeImage:img withNewSize:CGSizeMake(30, 30)];
		}
		
		
		imagesCount = [arr count];
    }
     
    [arr release];*/
	
	if(editAddressController != nil)
	{
		if(editAddressController.saved)
			dirty = TRUE;
		
		editAddressController.saved = FALSE;
	}
	
	[self initializeAddRows];
	
    [super viewWillAppear:animated];
	
	[self.tableView reloadData];
}

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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [locations count] + ([addRows count] > 0 ? 3 : 2);
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section < [locations count])
    {
        return 2;//once for location and one for photos
        /*SurveyLocation *loc = [locations objectAtIndex:section];
        return [loc.phones count] + 2;*/
    }
    else if(section == [locations count])
        return 1;
    else if(section == [locations count] + 1)
        return [[[locations objectAtIndex:0] phones] count] + 1;
    else
        return [addRows count];
    
    return 0;
}

-(CGFloat) tableView: (UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
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
    
	AddressSummaryCell *addCell = nil;
	TextWithHeaderCell *thCell = nil;
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
    {//phones
        //always use origin/destination (for now)
        SurveyLocation *loc = [locations objectAtIndex:0];
        
        thCell = (TextWithHeaderCell *)[tableView dequeueReusableCellWithIdentifier:TextWithHeaderCellID];
        if (thCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
            thCell = [nib objectAtIndex:0];
        }
        
        rect = thCell.labelHeader.frame;
        if([loc.phones count] != 0 && [indexPath row] < [loc.phones count])//edit phone...
        {
            rect.size.width = 94;
            thCell.labelHeader.textAlignment = NSTextAlignmentRight;
            
            SurveyPhone *phone = [loc.phones objectAtIndex:[indexPath row]];
            if ([indexPath row] == 0) {
                thCell.labelHeader.text = @"Primary";
            } else {
                thCell.labelHeader.text = phone.type.name;
            }
            thCell.labelText.text = phone.number;
            
#if TARGET_IPHONE_SIMULATOR
            if ([thCell.labelHeader.text  isEqual: @"Primary"] && [thCell.labelText.text isEqualToString: @""]) {
                [SurveyAppDelegate showAlert:@"A primary phone number must be chosen." withTitle:@"Primary Number Required"];
                
                // If it is preferred, we could pull the first phone from the non-primary list in this instance.
                // (That is, that the user simply clears out the phone number manually)
                // For Example:
                //        //get all the phones for this locaitonid and mark the first one as primary
                //        NSArray *phones = [del.surveyDB getCustomerPhones:del.customerID withLocationID:locationID];
                //        if ([phones count] > 0) {
                //            SurveyPhone *p = [phones objectAtIndex:0];
                //            p.isPrimary = 1;
                //            [del.surveyDB updatePhone:p];
                //
                //        } else {
                //            #if TARGET_IPHONE_SIMULATOR
                //            [SurveyAppDelegate showAlert:@"No other phones to make primary." withTitle:@"No phone numbers"];
                //            #endif
                //        }

            }
#endif
            if(lockFields)
                thCell.accessoryType = UITableViewCellAccessoryNone;
            else
            {
                if ([SurveyAppDelegate iOS7OrNewer])
                    thCell.accessoryType = UITableViewCellAccessoryDetailButton;
                else
                    thCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
        }
        else
        {
            rect.size.width = 270;
            thCell.labelHeader.textAlignment = NSTextAlignmentCenter;
            thCell.labelHeader.text = @"Add New Phone";
            thCell.labelText.text = @"";
            
            if(lockFields)
                thCell.accessoryType = UITableViewCellAccessoryNone;
            else
                thCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        thCell.labelHeader.frame = rect;
    }
	else
	{//additional
		
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
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyLocation *newLoc;
	
	if([indexPath section] < [locations count])
	{
        if(indexPath.row == 0)
        {
            if(editAddressController == nil)
                editAddressController = [[EditAddressController alloc] initWithStyle:UITableViewStyleGrouped];
            
            SurveyLocation *loc = [locations objectAtIndex:[indexPath section]];
            editAddressController.newLocation = FALSE;
            editAddressController.extraStop = (loc.locationType != ORIGIN_LOCATION_ID && loc.locationType != DESTINATION_LOCATION_ID);
            editAddressController.location = loc;
            [self.navigationController pushViewController:editAddressController	animated:YES];
        }
        else
        {
            NSInteger *locationType = [(SurveyLocation*)[locations objectAtIndex:[indexPath section]] locationType];

            if(imageViewer == nil)
                self.imageViewer = [[SurveyImageViewer alloc] init];
            
            imageViewer.photosType = IMG_LOCATIONS;
            imageViewer.customerID = custID;
            imageViewer.subID = locationType;
            
            imageViewer.caller = self.view;
            
            imageViewer.viewController = self;
            
            [imageViewer loadPhotos];
            
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
	}
    else if([indexPath section] == [locations count])
    {//add new
        
        if(lockFields)
        {
            [SurveyAppDelegate showAlert:@"Unable to modify location data since the shipment was downloaded from the Server.  Please redownload to retrieve any new changes from registration." withTitle:@"Edit Disabled"];
            return;
        }
        else if (self.isPacker)
        {
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
    }
    else if([indexPath section] == [locations count] + 1)
	{//phones 
        newLoc = [locations objectAtIndex:0];
		if([newLoc.phones count] == 0 || [indexPath row] == [newLoc.phones count])
		{
            if(lockFields)
            {
                [SurveyAppDelegate showAlert:@"Unable to modify location data since the shipment was downloaded from the Server.  Please redownload to retrieve any new changes from registration." withTitle:@"Edit Disabled"];
                return;
            }
            else if (self.isPacker)
            {
                [SurveyAppDelegate showAlert:@"Unable to modify location in Packer Mode." withTitle:@"Edit Disabled"];
                return;
            }
            
			if(phoneController == nil)
			{
				phoneController = [[EditPhoneController alloc] initWithStyle:UITableViewStyleGrouped];
				phoneController.preferredContentSize = self.preferredContentSize;
			}
			
			SurveyPhone *edit;
			phoneController.originalPhoneTypeID = -1;
			phoneController.newPhone = YES;
			phoneController.title = @"New Phone";
			edit = [[SurveyPhone alloc] init];
			edit.type = nil;//force select
			edit.custID = custID;
			edit.locationID = locationID;
			edit.number = @"";
			phoneController.phone = edit;
						
			[self.navigationController pushViewController:phoneController animated:YES];
		}
		else
		{
			calling = [newLoc.phones objectAtIndex:[indexPath row]];
						
			//ask them to perform actions - call/sms
			UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"What action would you like to take for this phone number?"
															   delegate:self 
													  cancelButtonTitle:@"Cancel" 
												 destructiveButtonTitle:nil
													  otherButtonTitles:@"Call", @"SMS Message", nil];
			
			[sheet showInView:self.view];
		}
		
		
	}
	else
	{//additional row
		
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
	else if([indexPath section] == [locations count] + 1 &&
            [indexPath row] != [myLoc.phones count] && 
            [myLoc.phones count] > 0)
	{
        SurveyPhone *phone = [myLoc.phones objectAtIndex:[indexPath row]];
        return phone.isPrimary != 1;
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
		else if([indexPath section] == [locations count] + 1)
		{
            SurveyLocation *myLoc = [locations objectAtIndex:0];
			SurveyPhone *removePhone = [myLoc.phones objectAtIndex:[indexPath row]];
			[del.surveyDB deletePhone:removePhone];
			[myLoc.phones removeObjectAtIndex:[indexPath row]];
            [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                      withRowAnimation:UITableViewRowAnimationFade];
		}
		
    }
}

- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath section] == [locations count] + 1)
	{
		if(phoneController == nil)
		{
			phoneController = [[EditPhoneController alloc] initWithStyle:UITableViewStyleGrouped];
			phoneController.preferredContentSize = self.preferredContentSize;
		}
		
		SurveyPhone *edit;
		
        SurveyLocation *myLoc = [locations objectAtIndex:0];
        
		if([myLoc.phones count] == 0 || [indexPath row] == [myLoc.phones count])
		{
			phoneController.originalPhoneTypeID = -1;
			phoneController.newPhone = YES;
			phoneController.title = @"New Phone";
			edit = [[SurveyPhone alloc] init];
			edit.type = nil;//force select
			edit.custID = custID;
			edit.locationID = locationID;
			edit.number = @"";
			phoneController.phone = edit;
			
		}
		else
		{
			edit = (SurveyPhone *)[myLoc.phones objectAtIndex:[indexPath row]];
			phoneController.newPhone = NO;
			phoneController.title = edit.type.name;
			phoneController.phone = edit;
			phoneController.originalPhoneTypeID = edit.type.phoneTypeID;
		}
        
        phoneController.locationID = locationID;
		
		[self.navigationController pushViewController:phoneController animated:YES];
	}	
}


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

#pragma mark action sheet stuff

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


@end

