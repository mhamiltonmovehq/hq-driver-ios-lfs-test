    //
//  SignatureViewController.m
//  Survey
//
//  Created by Tony Brame on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SignatureViewController.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"

@implementation SignatureViewController

@synthesize sigView, sigType, confirmedSignature, delegate, tag, requireSignatureBeforeSave, singleFieldController;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
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

-(void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [super viewDidLoad];
    
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearSignature)];
    self.navigationItem.leftBarButtonItem = clearButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    //self.navigationItem.rightBarButtonItem = doneButton;
    //[doneButton release];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    if([del.pricingDB vanline] == ARPIN){
        self.navigationItem.leftBarButtonItems = @[clearButton, cancelButton];
    }
    
    //self.navigationItem.rightBarButtonItem = cancelButton;
    //[cancelButton release];
    
    if([del.pricingDB vanline] == ARPIN){
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
      self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects: doneButton, cancelButton, nil];
    }
    
}

-(void)clearSignature
{
    sigView.image = nil;
    sigView.touchEventOccurred = NO;
    _signatureRemoved = YES;
}

-(void)viewWillAppear:(BOOL)animated
{    
    UIImage *toapply = nil;
    if(delegate != nil && [delegate respondsToSelector:@selector(signatureViewImage:)])
        toapply = [delegate signatureViewImage:self];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(signatureViewTextForDisplay:)] && [delegate signatureViewTextForDisplay:self] != nil)
        self.labelDisplayText.text = [delegate signatureViewTextForDisplay:self];
    else
        self.labelDisplayText.text = @"Please Use Finger To Sign Here";
    
    sigView.image = toapply;
    
    //moved this out of view did load, because viewDidLoad doesn't always fire, and i needed to be able to change the title
    if (sigType == PVO_HV_INITIAL_TYPE_DEST_CUSTOMER)
        self.navigationItem.title = @"Please Initial Below";
    else
        self.navigationItem.title = @"Please Sign Below";
    
    [super viewWillAppear:animated];
}

- (void)saveTheStuff
{
    self.sigView.touchEventOccurred = NO;
    
    if(delegate != nil && [delegate respondsToSelector:@selector(signatureApplied:)])
        [delegate signatureApplied:self];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(signatureView:confirmedSignature:)])
        [delegate signatureView:self confirmedSignature:[UIImage imageWithCGImage:[sigView.image CGImage]]];
    
    confirmedSignature = YES;
}

-(IBAction)done:(id)sender
{
    if (_signatureRemoved && sigView.touchEventOccurred == NO) {
        SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [del.surveyDB deletePVOSignature:del.customerID forImageType:sigType];
        [self cancel:nil];
        return;
    }
    
    if (requireSignatureBeforeSave && sigView.image == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Signature Required"
                                                        message:@"A Signature is required to Save. Cancel Signature capture?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
        return;
    }
    
    if(sigView.touchEventOccurred == NO){
        [self cancel:nil];
        return;
    }
    
    if (_saveBeforeDismiss)
    {
        [self saveTheStuff];
    }
    
    [self dismissViewControllerAnimated:NO completion:^{
        if (!_saveBeforeDismiss)
        {
            [self saveTheStuff];
        }
    }];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setLabelDisplayText:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex)
    {
        //exit view
        self.sigView.touchEventOccurred = NO;
        confirmedSignature = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
