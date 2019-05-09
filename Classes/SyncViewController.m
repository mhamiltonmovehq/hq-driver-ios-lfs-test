//
//  SyncViewController.m
//  Survey
//
//  Created by Tony Brame on 7/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SyncViewController.h"
#import "SurveyAppDelegate.h"
#import "ProcessSync.h"
#import "Prefs.h"

@implementation SyncViewController

@synthesize tboxProgress, synchronization, activity, cmdOK, cmdCancel, downloadCustomItemLists, pvoSync;


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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	
	[super viewWillAppear:animated];
    
    tboxProgress.text = @"";
	
	cmdOK.enabled = NO;
	cmdCancel.enabled = YES;
}


- (void)viewDidAppear:(BOOL) animated {
	
	
    [super viewDidAppear:YES];
	
	if(![self validateSettings])
		return;
	
	[activity startAnimating];
    
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(del.viewType == OPTIONS_PVO_VIEW)
    {
        self.pvoSync = [[PVOSync alloc] init];
        pvoSync.updateWindow = self;
        pvoSync.updateCallback = @selector(updateProgress:);
        pvoSync.completedCallback = @selector(syncCompleted);
        pvoSync.errorCallback = @selector(syncError);
        pvoSync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORIES;
        
        [del.operationQueue addOperation:pvoSync];
	}
    else
    {
        //start the thread on the operation queue
        self.synchronization = [[ProcessSync alloc] init];
        synchronization.updateWindow = self;
        synchronization.updateCallback = @selector(updateProgress:);
        synchronization.completedCallback = @selector(syncCompleted);
        synchronization.errorCallback = @selector(syncError);
        synchronization.downloadCustomItemLists = downloadCustomItemLists;
        
        [del.operationQueue addOperation:synchronization];
        //[synchronization release];
    }
	
}
		
-(BOOL)validateSettings
{
	BOOL continu = TRUE;
	return continu;
}

-(IBAction)okPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancelSync:(id)sender
{
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[del.operationQueue cancelAllOperations];
	
	[activity stopAnimating];
	
    [self dismissViewControllerAnimated:YES completion:nil];
	
}
	
-(void)syncCompleted
{
	
	[self updateProgress:@"Sync Completed..."];	
	
	cmdOK.enabled = YES;
	cmdCancel.enabled = NO;
	
	[activity stopAnimating];
}

-(void)syncError
{
	[activity stopAnimating];
}

-(void)updateProgress:(NSString*)textToAdd
{
	NSString *toAdd;
	
	if(textToAdd == nil)
		return;
	
	if([tboxProgress.text length] == 0)
		toAdd = textToAdd;
	else
		toAdd = [@"\r\n" stringByAppendingString:textToAdd];
	
	tboxProgress.text = [tboxProgress.text stringByAppendingString:toAdd];
	
	NSRange range = [tboxProgress.text rangeOfString:textToAdd];
	if(range.location != NSNotFound)
		[tboxProgress scrollRangeToVisible:[tboxProgress.text rangeOfString:textToAdd]];
	
}

- (void)didReceiveMemoryWarning {
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end
