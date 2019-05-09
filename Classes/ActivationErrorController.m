//
//  ActivationErrorController.m
//  Survey
//
//  Created by Tony Brame on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ActivationErrorController.h"
#import "SurveyAppDelegate.h"
#import "EnterCredentialsController.h"


@implementation ActivationErrorController

@synthesize imgLogo;

@synthesize tv, tboxMessage, message;

- (void)viewWillAppear:(BOOL)animated {
	
	if(message != nil)
		tboxMessage.text = message;
    
//    if ([SurveyAppDelegate iOS8OrNewer])
//    {
//        [_btnEnter_Credentials.layer setBorderWidth:1.0];
//        [_btnEnter_Credentials.layer setBackgroundColor:[[SurveyAppDelegate getiOSBlueButtonColor] CGColor]];
//        [_btnEnter_Credentials.layer setBorderColor:[[UIColor grayColor] CGColor]];
//        [_btnEnter_Credentials.layer setCornerRadius:3.0];
//        _btnEnter_Credentials.hidden = NO;
//    }
//    else
//    {
//        _btnEnter_Credentials.hidden = YES;
//    }
    
    
    if ([SurveyAppDelegate iOS7OrNewer])
    {
        [_btnEnter_Credentials.layer setCornerRadius:4.f];
        [_btnEnter_Credentials.layer setBorderWidth:1.5f];
        [_btnEnter_Credentials.layer setBorderColor:[[SurveyAppDelegate getiOSBlueButtonColor] CGColor]];
        [_btnEnter_Credentials setBackgroundColor:[SurveyAppDelegate getiOSBlueButtonColor]];
        [_btnEnter_Credentials addTarget:self action:@selector(setSyncButtonHighlighted) forControlEvents:UIControlEventTouchDown];
        [_btnEnter_Credentials addTarget:self action:@selector(setSyncButtonUnhighlighted) forControlEvents:UIControlEventTouchDragExit];
        [_btnEnter_Credentials setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else
    {
        [_btnEnter_Credentials setBackgroundImage:[[UIImage imageNamed:@"blueButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.]
                              forState:UIControlStateNormal];
        [_btnEnter_Credentials setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
	
    [super viewWillAppear:animated];
}

-(void)setSyncButtonHighlighted
{
    _btnEnter_Credentials.alpha = 0.3f;
}

-(void)setSyncButtonUnhighlighted
{
    _btnEnter_Credentials.alpha = 1.f;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Activation";
    
#ifdef ATLASNET
    [imgLogo setImage:[UIImage imageNamed:@"AtlasLogo.png"]];
#endif
}


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

- (void)viewDidUnload {
    [self setBtnEnter_Credentials:nil];
    imgLogo = nil;
    [self setImgLogo:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (IBAction)cmdEnter_Credentials:(id)sender {
    if ([SurveyAppDelegate iOS7OrNewer])
        [self setSyncButtonUnhighlighted];
    
    //    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    
    EnterCredentialsController *ctl = [[EnterCredentialsController alloc] initWithStyle:UITableViewStyleGrouped];
    PortraitNavController *navCtl = [[PortraitNavController alloc] initWithRootViewController:ctl];
    [self presentViewController:navCtl animated:YES completion:nil];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	if([indexPath row] == 0)
		cell.textLabel.text = @"Sign Up For Account";
	else
		cell.textLabel.text = @"Enter Credentials";
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
	return @"Will Open In Safari...";
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if([indexPath row] == 0)
	{
		//load sign up in web browser
		 [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"signupurl"]];
	}
	else
	{
		//go to settings app
		
	}
	
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
- (IBAction)goToPrivacyPolicy:(id)sender {
#ifdef ATLASNET
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.atlasvanlines.com/privacy-policy"]];
#else
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.movehq.com/privacy-policy"]];
#endif
}

@end

