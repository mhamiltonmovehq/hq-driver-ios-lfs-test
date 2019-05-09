//
//  PVOHighValueController.m
//  Survey
//
//  Created by Tony Brame on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOHighValueController.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"

@implementation PVOHighValueController

@synthesize tboxValue, shipperInitials, packerInitials, pvoItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [super viewDidLoad];
    
    self.title = [AppFunctionality getHighValueDescription];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(done:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                               style:UIBarButtonItemStylePlain 
                                                                              target:self 
                                                                              action:@selector(clearSignature:)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //packer
    PVOHighValueInitial *initial = [del.surveyDB getPVOHighValueInitial:pvoItem.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_PACKER];
    if (initial != nil && [initial signatureData] != nil)
        packerInitials.image = [initial signatureData];
    else
        packerInitials.image = nil;
    
    //customer
    initial = [del.surveyDB getPVOHighValueInitial:pvoItem.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_CUSTOMER];
    if (initial != nil && [initial signatureData] != nil)
        shipperInitials.image = [initial signatureData];
    else
        shipperInitials.image = nil;
    
    if (pvoItem.highValueCost > 0)
        tboxValue.text = [SurveyAppDelegate formatDouble:pvoItem.highValueCost];
    else
        tboxValue.text = @"";
    [tboxValue becomeFirstResponder];
}

-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (tboxValue.text != nil && [tboxValue.text length] > 0)
        pvoItem.highValueCost = [tboxValue.text doubleValue];
    else
        pvoItem.highValueCost = 0;
    [del.surveyDB updatePVOItem:pvoItem];
    
    [del.surveyDB savePVOHighValueInitial:pvoItem.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_CUSTOMER 
                                withImage:[[UIImage alloc] initWithCGImage:[shipperInitials.image CGImage]]];
    [del.surveyDB savePVOHighValueInitial:pvoItem.pvoItemID forInitialType:PVO_HV_INITIAL_TYPE_PACKER 
                                withImage:[[UIImage alloc] initWithCGImage:[packerInitials.image CGImage]]];
    
    [super viewWillDisappear:animated];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(IBAction)clearSignature:(id)sender
{
    [packerInitials clearSignature:sender];
    [shipperInitials clearSignature:sender];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
