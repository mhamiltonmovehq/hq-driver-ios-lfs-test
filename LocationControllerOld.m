//
//  LocationController.m
//  Survey
//
//  Created by Tony Brame on 5/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LocationController.h"
#import	"SurveyLocation.h"
#import "SurveyAppDelegate.h"

@implementation LocationController

@synthesize tboxZip, tboxWorkPhone, tboxState, tboxHomePhone, tboxCity, tboxAddress, custID, locationID, location;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)viewDidLoad {
}

-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}

-(IBAction)backgroundClicked:(id)sender
{
	[tboxState resignFirstResponder];
	[tboxAddress resignFirstResponder];
	[tboxCity resignFirstResponder];
	[tboxZip resignFirstResponder];
	[tboxHomePhone resignFirstResponder];
	[tboxWorkPhone resignFirstResponder];
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 */


-(void)viewWillAppear:(BOOL)animated
{
	//load the customer data
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	location = [del.surveyDB getCustomerLocation: custID withLocationID: locationID];
	
	tboxAddress.text = location.address;
	tboxCity.text = location.city;
	tboxState.text = location.state;
	tboxZip.text = location.zip;
	tboxHomePhone.text = location.homePhone;
	tboxWorkPhone.text = location.workPhone;
	
	//location = [del.surveyDB getCustomer:custID];
	
	/*tboxEmail.text = cust.email;
	tboxFirstName.text = cust.firstName;
	tboxLastName.text = cust.lastName;
	
	NSString *wt = [[NSString alloc] initWithFormat:@"%d", cust.weight];
	
	tboxWeight.text = wt;
	
	[wt release];*/
	
}

-(void)viewWillDisappear:(BOOL)animated
{
	//save the location data, release the location
	[location.address release];
	location.address = tboxAddress.text;
	[location.city release];
	location.city = tboxCity.text;
	[location.state release];
	location.state = tboxState.text;
	[location.zip release];
	location.zip = tboxZip.text;
	[location.homePhone release];
	location.homePhone = tboxHomePhone.text;
	[location.workPhone release];
	location.workPhone = tboxWorkPhone.text;
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	[del.surveyDB updateLocation:location];
	
	[location release];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	
	[tboxState release];
	[tboxAddress release];
	[tboxCity release];
	[tboxZip release];
	[tboxHomePhone release];
	[tboxWorkPhone release];
	
	[super dealloc];
}


@end
