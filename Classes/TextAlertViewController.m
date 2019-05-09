//
//  TextAlertViewController.m
//  Survey
//
//  Created by Tony Brame on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TextAlertViewController.h"

@implementation TextAlertViewController

@synthesize tboxContent, delegate, titleText, textToView;

+(id)textViewWithText:(NSString*)textToView andTitle:(NSString*)title
{
    TextAlertViewController *retval = [[TextAlertViewController alloc] initWithNibName:@"TextAlertView" bundle:nil];
    retval.titleText.title = title;
    retval.tboxContent.text = textToView;
    return retval;
}

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
    [super viewDidLoad];
    
    self.tboxContent.text = textToView;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cmdDoneClick:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)cmdDoneClick:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if(delegate != nil && [delegate respondsToSelector:@selector(textAlertWillDismiss:)])
        [delegate textAlertWillDismiss:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
