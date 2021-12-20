//
//  DownloadController.m
//  Survey
//
//  Created by Tony Brame on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#include <sys/xattr.h>
#import "DownloadController.h"
#import "SurveyAppDelegate.h"
#import "PVOPricingSync.h"
#import "XMLDictionary.h"
#import "Prefs.h"

@implementation DownloadController

@synthesize download, labelRemainingTime, labelReceived, progress, tboxInformation, conn;
@synthesize infoView, labelFileNumber, cmdContinue, dismiss, navBar, img_logo;
@synthesize downloadHTMLReportsOnly, webPricingDBVersion;

-(void)viewDidLoad
{
    self.title = @"Initializing";
    
    cmdContinue = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(start:)];
    //self.navigationItem.leftBarButtonItem = cmdContinue;
    
	[super viewDidLoad];
	
    progress.progressViewStyle = UIProgressViewStyleDefault;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
}

-(void)viewWillAppear:(BOOL)animated
{
	processing = NO;
	[super viewWillAppear:animated];
    [self checkForNewPricingDBVersion];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)start:(id)sender
{
    // No longer used
}

-(void)completed
{
	// no longer used
}

-(void)downloadAllHTMLReports
{
    if (!processing)
    {
        processing = YES;
        
        SurveyAppDelegate *del = SURVEY_APP_DELEGATE;
        
        //check the reports, and download any HTML reports.
        dispatch_async(dispatch_get_main_queue(), ^{
            labelFileNumber.text = @"";
            labelReceived.text = @"";
            labelRemainingTime.text = @"";
            
            infoView.hidden = NO;
            tboxInformation.text = @"Downloading Report Options";
        });
        
        DownloadAllHTMLReports *reportDownload = [[DownloadAllHTMLReports alloc] init];
        reportDownload.appDelegate = del;
        reportDownload.delegate = self;
        [del.operationQueue addOperation:reportDownload];
                
        return;
    }
}

-(void)error
{
	
}

-(void)updateMessage:(NSString*)updateString
{
	tboxInformation.text = updateString;
}

-(void)fileSize:(NSNumber*)fileSize
{
    labelReceived.text =
    [NSString stringWithFormat:@"0 of %@",
     [SurveyAppDelegate stringFromBytes:[fileSize longLongValue]]];
}

-(void)receivedData
{
    labelReceived.text =
    [NSString stringWithFormat:@"%@ of %@",
     [SurveyAppDelegate stringFromBytes:download.received],
     [SurveyAppDelegate stringFromBytes:download.totalLength]];
    
    double percentDone = (download.received / (double)download.totalLength);
    [self updateProgress:percentDone];
    
    //time calc
    if(percentDone > 0)
    {
        int secs = [[NSDate date] timeIntervalSince1970] - start;
        int remainingSecs = (secs * (download.totalLength-download.received))/download.received;
        labelRemainingTime.text = [NSString stringWithFormat:@"%d seconds", remainingSecs];
    }
}

-(void)updateProgress:(double)progressValue
{
	progress.progress = progressValue;
}

- (void)viewDidUnload {
    [self setImg_logo:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark - DownloadAllHTMLReportsDelegate methods

-(void)downloadHTMLReportsUpdateProgess:(NSNumber*)progressValue
{
	progress.progress = [progressValue doubleValue];
}

-(void)downloadHTMLReportsCompleted
{
    processing = NO;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(!dismiss)
        [del hideDownloadShowCustomers];
    else
        [self done:nil];
}

-(void)downloadHTMLReportsError:(NSString*)error
{
    tboxInformation.text = error;
}

#pragma mark - PricingDB downloads

- (void)checkForNewPricingDBVersion
{
    NSError *error = nil;
    NSString *pricingVersion = [PVOPricingSync getPVODatabaseVersion: &error];
    BOOL downloadReportsImmediately = YES;
    if (error == nil)
    {
        webPricingDBVersion = [pricingVersion integerValue];
        NSInteger currentPricingDBVersion = [Prefs currentPricingDBVersion];
        if (![PricingDB dbExists] || webPricingDBVersion > currentPricingDBVersion ||
            ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcepricingdbupdate"].location != NSNotFound))
        {
            downloadReportsImmediately = NO;
            NSLog(@"Updating pricing DB: currentPricingDBVersion: %@; webPricingDBVersion: %@", @(currentPricingDBVersion), @(webPricingDBVersion));
            [self downloadNewPricingDB];
            return;
        }
    }
    else
    {
        NSLog(@"DownloadController checkForNewPricingDBVersion error: %@", error.localizedDescription);
    }
    
    if (downloadReportsImmediately) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self downloadAllHTMLReports];
        });
    }
}

- (void)downloadNewPricingDB
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _progressContainerView.hidden = NO;
//        [MBProgressHUD showHUDAddedTo:_progressContainerView animated:YES];
//    });
    NSError *error = nil;

    start = [[NSDate date] timeIntervalSince1970];
    [self updateFileNumberLabel:@"Downloading update..."];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        tboxInformation.text = @"Processing update.\n\nPlease keep your device connected to the internet, this could take a few minutes.";
    });
    
    NSString *pricingDatabaseXml = [PVOPricingSync getPVODatabaseData: &error];
    if (error == nil)
        {
            SurveyAppDelegate *del = SURVEY_APP_DELEGATE;
            [del.pricingDB recreatePVODatabaseTables:pricingDatabaseXml];
            
            [Prefs setCurrentPricingDBVersion:webPricingDBVersion];
        }
        else
        {
            NSLog(@"DownloadController checkForNewPricingDBVersion error: %@", error.localizedDescription);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideHUDForView:_progressContainerView animated:YES];
//            _progressContainerView.hidden = YES;
            [self downloadAllHTMLReports];
        });

}

- (void)updateFileNumberLabel:(NSString *)str
{
    dispatch_async(dispatch_get_main_queue(), ^{
        labelFileNumber.text = str;
    });
}

@end
