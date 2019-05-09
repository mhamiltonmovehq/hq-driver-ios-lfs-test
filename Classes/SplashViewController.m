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
    
#ifdef ATLASNET
    [cmdSplashPhoto setImage:[UIImage imageNamed:@"AtlasNetSplash.png"] forState:UIControlStateNormal];
    [cmdSplashPhoto setImage:[UIImage imageNamed:@"AtlasNetSplash.png"] forState:UIControlStateHighlighted];
#endif
    
    //labelLoad.hidden = TRUE;
    
//    if([SurveyAppDelegate isHighRes])
//    {
//        CGRect rect = labelLoad.frame;
//        rect.origin.y += 100;
//        labelLoad.frame = rect;
//    }
}

-(void)tick: (NSTimer*)theTimer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(firstTimer)
    {
        firstTimer = NO;
        
        NSString *results = nil;
        
        allow = [Activation allowAccess:&results];
        
        self.resultString = results;
        
        labelLoad.text = @"Updating Database...";
        [del.surveyDB upgradeDBWithDelegate:self forVanline:[del.pricingDB vanline]];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(tick:)
                                                    userInfo:NULL
                                                     repeats:NO];
        
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
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

@end
