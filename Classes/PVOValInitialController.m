//
//  PVOValInitialController.m
//  Survey
//
//  Created by Tony Brame on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOValInitialController.h"


@implementation PVOValInitialController

@synthesize labelValAmountDed;
@synthesize labelValCost;
@synthesize switchExValue;
@synthesize segmentValType, delegate;


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


-(IBAction)continue_Clicked:(id)sender
{
    if(delegate != nil && [delegate respondsToSelector:@selector(initialsEntered:)])
        [delegate initialsEntered:self];
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
                                                                             action:@selector(continue_Clicked:)];
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
