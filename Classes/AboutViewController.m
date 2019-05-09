//
//  AboutViewController.m
//  Survey
//
//  Created by Tony Brame on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "SurveyAppDelegate.h"

@implementation AboutViewController
@synthesize imgLogo;

@synthesize labelVersion, labelCopyright, viewHeaders, viewData;

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
    
    viewHeaders.font = labelVersion.font;
    viewData.font = labelVersion.font;
    
    labelVersion.text = [NSString stringWithFormat:@"%@ Version %@",
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"TargetName"],
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
#if defined(DEBUG)
    self.labelBuildConfiguration.text = [NSString stringWithFormat:@"DEBUG MODE"];
    self.labelBuildConfiguration.hidden = NO;
#elif defined(RELEASE)
    self.labelBuildConfiguration.text = [NSString stringWithFormat:@"RELEASE MODE"];
    self.labelBuildConfiguration.hidden = NO;
#else
    self.labelBuildConfiguration.text = @"";
    self.labelBuildConfiguration.hidden = YES;
#endif
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    labelCopyright.text = [NSString stringWithFormat:@"© %@.  All Rights Reserved.",
                           [formatter stringFromDate:[NSDate date]]];
    
    self.title = @"About";
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
#ifdef ATLASNET
    
    [imgLogo setImage:[UIImage imageNamed:@"AtlasLogo.png"]];
    
#endif
    
    [super viewDidLoad];
}


-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


/*
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
- (IBAction)goToPrivacyPolicy:(id)sender {
#ifdef ATLASNET
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.atlasvanlines.com/privacy-policy"]];
#else
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.movehq.com/privacy-policy"]];
#endif
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setLabelBuildConfiguration:nil];
    [self setImgLogo:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
