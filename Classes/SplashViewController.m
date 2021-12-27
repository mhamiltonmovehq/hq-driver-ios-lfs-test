//
//  SplashViewController.m
//  Survey
//
//  Created by Tony Brame on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SplashViewController.h"
#import "SurveyAppDelegate.h"
#import "Prefs.h"
#import <HQ_Driver-Swift.h>


@interface SplashViewController() <HubActivationResponseProtocol>
@end

@implementation SplashViewController

@synthesize timer, resultString, labelLoad, cmdSplashPhoto, progress;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
    }
    return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
 - (void)loadView {
 }
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 */

- (void)viewDidLoad
{
#if TARGET_IPHONE_SIMULATOR
    // where are you?
    NSString *docsDirectory = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] absoluteString];
    docsDirectory = [docsDirectory stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSLog(@"Documents Directory:\n.\n%@\n.\n", docsDirectory);
#endif
    
    dbUpdateComplete = NO;
    [super viewDidLoad];
}

-(void)tick: (NSTimer*)theTimer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(firstTimer)
    {
        firstTimer = NO;
        
        NSString *results = nil;
        
        allow = [Activation allowAccess:&results];
        
        if(allow == ACTIVATION_HUB) {
            HubActivationWrapper *hubActivationService = [[HubActivationWrapper alloc] init];
            [hubActivationService activateWithCaller:self];
            timerDone = YES;
        }
        if(allow != ACTIVATION_HUB) {
            self.resultString = results;
            
            
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(tick:)
                                                        userInfo:NULL
                                                         repeats:NO];
            
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
        labelLoad.text = @"Updating Database...";
        [del.surveyDB upgradeDBWithDelegate:self forVanline:[del.pricingDB vanline]];
    }
    else
    {
        timerDone = YES;
        [self splashPhotoClicked:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    timerDone = NO;
    
    //run short timer to draw splash...
    firstTimer = YES;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:self
                                                selector:@selector(tick:)
                                                userInfo:NULL
                                                 repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

-(IBAction)splashPhotoClicked:(id)sender
{
    if (!dbUpdateComplete)
        return;
    
    [timer invalidate];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(allow == ACTIVATION_CUSTS)
    {
        [del hideSplashShowCustomers];
    }
    else if(allow == ACTIVATION_DOWNLOAD)
    {
        [del hideSplashShowDownload];
    }
    else 
    {
        [del hideSplashShowActivationError:resultString];
    }

    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}




- (void)viewDidUnload {
    cmdSplashPhoto = nil;
    progress = nil;
    [super viewDidUnload];
}

#pragma mark - SurveyDBUpdaterDelegate methods

-(void)SurveyDBUpdaterError:(NSString*)error
{
    [SurveyAppDelegate showAlert:error withTitle:@"DB Update Error"];
    dbUpdateComplete = YES;
    if(timerDone)
        [self splashPhotoClicked:nil];
}

-(void)SurveyDBUpdaterCompleted:(SurveyDBUpdater*)updater
{
    dbUpdateComplete = YES;
    if(timerDone)
        [self splashPhotoClicked:nil];
}

-(void)SurveyDBUpdaterUpdateProgress:(NSNumber*)prog
{
    progress.progress = [prog floatValue];
}

-(void)SurveyDBUpdaterStartProgress:(NSString*)progressLabel
{
    if(progressLabel != nil)
        labelLoad.text = progressLabel;
    
    progress.progress = 0;
    progress.hidden = NO;
    
}

-(void)SurveyDBUpdaterEndProgress:(SurveyDBUpdater*)updater
{
    labelLoad.text = @"Updating Database...";
    progress.progress = 1;
    progress.hidden = YES;
}

- (void)hubActivationCompletedWithResult:(HubActivationWrapperResult * _Nonnull)result {
    SurveyAppDelegate *del = (SurveyAppDelegate*)[[UIApplication sharedApplication] delegate];
    ActivationRecord *rec = [del.surveyDB getActivation];
    
    if (result.success) {
    
        // TODO: Hub should support a vanlineID to compare to the existing vanlineID
        //   If vanlineID's don't match, delete both pricing and mileage dbs
        allow = ACTIVATION_CUSTS;
        rec.unlocked = 1;
        rec.lastOpen = rec.lastValidation = [NSDate date];
        rec.milesDLFolder = result.hubResult.milesFileLocation;
        rec.tariffDLFolder = result.hubResult.pricingFileLocation;

    }
    else {
        rec.unlocked = 0;
        rec.lastOpen = [NSDate date];
        self.resultString = result.errorMessage;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [del.surveyDB updateActivation:rec];
        [self splashPhotoClicked:nil];
    });
}

@end
