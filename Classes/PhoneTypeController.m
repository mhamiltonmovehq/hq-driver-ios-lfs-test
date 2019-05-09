//
//  PhoneTypeController.m
//  Survey
//
//  Created by Tony Brame on 5/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhoneTypeController.h"
#import "SurveyAppDelegate.h"
#import "PhoneType.h"
#import "EditPhoneController.h"

@implementation PhoneTypeController

@synthesize types, lastIndexPath, selectedType, originalTypeID, locationID;

-(void)viewDidLoad {
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    types = [del.surveyDB getPhoneTypeList];
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    
    EditPhoneController *ctl = [[self.navigationController viewControllers] objectAtIndex:[[self.navigationController viewControllers] count]-1];
    
    if([ctl isMemberOfClass:[EditPhoneController class]])
        ctl.phone.type = selectedType;
    
    [super viewWillDisappear:animated];
}

-(void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)newPhoneTypeEntered: (NSString*)newType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([del.surveyDB insertNewPhoneType:newType] == NO)
    {
        [SurveyAppDelegate showAlert:@"Unable to save new phone type.  Phone Type either already exists, or an empty string was passed" withTitle:@"New Type"];
    }
    
}


#pragma mark Table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [types count] + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if([types count] == 0 || [types count] == [indexPath row])
    {//new phone
        cell.textLabel.text = @"Add New";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        PhoneType *type = (PhoneType *)[types objectAtIndex:[indexPath row]];
        if(selectedType != nil && type.phoneTypeID == selectedType.phoneTypeID)
        {
            self.lastIndexPath = indexPath;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.text = type.name;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if([indexPath row] == [types count])
    {//this is the new selection, load form to get name
        
        [del pushSingleFieldController:@""
                           clearOnEdit:NO 
                          withKeyboard:UIKeyboardTypeASCIICapable 
                       withPlaceHolder:@"New Phone Type"
                            withCaller:self 
                           andCallback:@selector(newPhoneTypeEntered:)
                     dismissController:YES
                      andNavController:self.navigationController];
                
    }
    else
    {
        int newRow = [indexPath row];
        
        PhoneType *type = (PhoneType*)[types objectAtIndex:newRow];
        
        if([del.surveyDB phoneExists:del.customerID withLocationID:locationID withPhoneType:type.phoneTypeID] == YES
            && type.phoneTypeID != originalTypeID)
        {//phone type already exists
            [SurveyAppDelegate showAlert:@"Phone type already exists for this location, please choose another or create a new type." withTitle:@"Type exists"];
        }
        else
        {
            //if (lastIndexPath == nil || newRow != oldRow)
            //{
                
                UITableViewCell *oldCell = [tableView cellForRowAtIndexPath: lastIndexPath];
                oldCell.accessoryType = UITableViewCellAccessoryNone;
                
                UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
                newCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                self.lastIndexPath = indexPath;
                
                selectedType = (PhoneType *)[types objectAtIndex:[indexPath row]];
                [self.navigationController popViewControllerAnimated:YES];
            //}
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString* cellText = cell.textLabel.text;
    
    if (![cellText isEqualToString:@"Home"] &&
        ![cellText isEqualToString:@"Mobile"] &&
        ![cellText isEqualToString:@"Other"] &&
        ![cellText isEqualToString:@"Work"]) {
        // Return NO if you do not want the specified item to be editable.
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        PhoneType *type = (PhoneType *)[types objectAtIndex:[indexPath row]];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        [del.surveyDB hidePhoneType:type.phoneTypeID];
        [types removeObject:type];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}


@end

