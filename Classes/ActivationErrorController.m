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

@synthesize tv, tboxMessage, message;

#pragma mark - Lifecycle

-(void)viewWillAppear:(BOOL)animated {
	
	if(message != nil)
		tboxMessage.text = message;
    
    tboxMessage.attributedText = [self replaceTextWithLink:tboxMessage.attributedText textToReplace:@"MoveHQ Privacy Policy" linkToAdd:@"https://www.movehq.com/privacy-policy"];
    
    tboxMessage.attributedText = [self replaceTextWithLink:tboxMessage.attributedText textToReplace:@"MoveHQ Master Service Agreement" linkToAdd:@"https://www.movehq.com/msa"];
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Activation";
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - IBActions
- (IBAction)cmdEnter_Credentials:(id)sender {
    if ([SurveyAppDelegate iOS7OrNewer])
        [self setSyncButtonUnhighlighted];
    
    //    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    
    EnterCredentialsController *ctl = [[EnterCredentialsController alloc] initWithStyle:UITableViewStyleGrouped];
    PortraitNavController *navCtl = [[PortraitNavController alloc] initWithRootViewController:ctl];
    [self presentViewController:navCtl animated:YES completion:nil];
}


#pragma mark - Table view methods

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

#pragma mark - Helpers

-(NSMutableAttributedString*)replaceTextWithLink:(NSAttributedString*)textBlock
                                   textToReplace:(NSString*) textToReplace
                                       linkToAdd:(NSString*) linkToAdd {
    
    NSMutableAttributedString *attribText = [[NSMutableAttributedString alloc]
                                             initWithAttributedString: textBlock];
    
    NSRange range = [attribText.mutableString rangeOfString:textToReplace];
    if (range.location != NSNotFound) {
        [attribText addAttribute:NSLinkAttributeName value:linkToAdd range:range];
    }
    return attribText;
}

-(void)setSyncButtonHighlighted
{
    _btnEnter_Credentials.alpha = 0.3f;
}

-(void)setSyncButtonUnhighlighted
{
    _btnEnter_Credentials.alpha = 1.f;
}

@end

