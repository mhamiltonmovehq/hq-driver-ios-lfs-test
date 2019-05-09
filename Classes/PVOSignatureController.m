//
//  PVOSignatureController.m
//  Survey
//
//  Created by Tony Brame on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOSignatureController.h"
#import "SurveyAppDelegate.h"


@implementation PVOSignatureController

@synthesize delegate, tboxDescription;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil displayText:(NSString*)display
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        displayText = display;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(IBAction)continue_Click:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(signatureEntered:)])
        [delegate signatureEntered:self];
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
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" 
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(continue_Click:)];
    if(displayText != nil)
    {
        tboxDescription.text = displayText;
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
