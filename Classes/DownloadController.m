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

-(IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)start:(id)sender
{	
	if(!processing)
	{
		processing = TRUE;
		
		cmdContinue.title = @"Cancel";
		
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

        
//        self.img_logo.frame = CGRectMake(63, 154, 190, 130);
		
		infoView.hidden = FALSE;
		
        if (downloadHTMLReportsOnly)
        {
            [self downloadAllHTMLReports];
            return;
        }
        else
        {
            [del.pricingDB closeDB];
//            [del.milesDB closeDB];
            
            //start the thread on the operation queue
            DownloadFile *mydownload = [[DownloadFile alloc] init];
            
            mydownload.caller = self;
            mydownload.receivedDataCallback = @selector(receivedData);
            mydownload.completedCallback = @selector(completed);
            mydownload.errorCallback = @selector(error);
            mydownload.sizeCallback = @selector(fileSize:);
            mydownload.messageCallback = @selector(updateMessage:);
            
            self.download = mydownload;
            
        }
		
		[self completed];
	}
	else 
	{//cancel the download...
		processing = FALSE;
		
		currentFile--;
		cmdContinue.title = @"Restart";
		
		[download cancel];
		
		tboxInformation.text = @"Download Cancelled.  This download must be completed prior to accessing the application.";
	}

}

-(void)completed
{
	currentFile++;
	if(currentFile > DOWNLOAD_NUM_FILES)
	{
		//finished...
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		[del openPricingDB];
//		[del openMilesDB];
        
        //exclude from iCloud backups
        for (int i = 0; i < 1; i++)
        {
            NSURL *url = nil;
            
//            if(i == 0)
                url = [NSURL fileURLWithPath:[del.pricingDB fullDBPath]];
//            else
//                url = [NSURL fileURLWithPath:[del.milesDB fullDBPath]];
            
            const char* filePath = [[url path] fileSystemRepresentation];
            const char* attrName = "com.apple.MobileBackup";
            if (&NSURLIsExcludedFromBackupKey == nil) {
                // iOS 5.0.1 and lower
                u_int8_t attrValue = 1;
                int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
                
                if(result != 0)
                    [self updateMessage:@"Unable to set the no backup flag on file."];
            }
            else {
                // First try and remove the extended attribute if it is present
                int result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
                if (result != -1) {
                    // The attribute exists, we need to remove it
                    int removeResult = removexattr(filePath, attrName, 0);
                    if (removeResult != 0) {
                        NSLog(@"Unable to remove extended attribute on file %@", url);
                    }
                }
                
                // Set the new key
                NSError *error = nil;
                [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
                
                if(error != nil)
                {
                    NSLog(@"Couldn't set attribute on file %@, because: %@", url, [error localizedDescription]);
                    [self updateMessage:@"Unable to set the no backup flag on file."];
                }
            }
        }
		
        [self downloadAllHTMLReports];
		return;
	}
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	ActivationRecord *rec = [del.surveyDB getActivation];
//	if(currentFile == 1)
//	{
//		//mileage
//		download.downloadURL = [NSString stringWithFormat:@"%@%@/%@", 
//								DOWNLOAD_MILEAGE_URL, rec.milesDLFolder, DOWNLOAD_MILEAGE_NAME];
//		download.downloadLocationFolder = rec.milesDLFolder;
//	}
//	else 
//	{
		//tariff
		download.downloadURL = [NSString stringWithFormat:@"%@%@/%@", 
								DOWNLOAD_TARIFF_URL, rec.tariffDLFolder, DOWNLOAD_TARIFF_NAME];
		download.downloadLocationFolder = rec.tariffDLFolder;
//	}
	
	labelReceived.text = @"unknown";
	labelRemainingTime.text = @"unknown";
	
	labelFileNumber.text = [NSString stringWithFormat:@"File %d of %d", currentFile, DOWNLOAD_NUM_FILES];
	
	progress.progress = 0;
	
	start = [[NSDate date] timeIntervalSince1970];
	
	[download start];
	
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
    if (error == nil)
    {
        webPricingDBVersion = [pricingVersion integerValue];
        NSInteger currentPricingDBVersion = [Prefs currentPricingDBVersion];
        if ((webPricingDBVersion != -1 && webPricingDBVersion > currentPricingDBVersion) ||
            ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcepricingdbupdate"].location != NSNotFound))
        {
            NSLog(@"Updating pricing DB: currentPricingDBVersion: %@; webPricingDBVersion: %@", @(currentPricingDBVersion), @(webPricingDBVersion));
            [self downloadNewPricingDB];
            return;
        }
    }
    else
    {
        NSLog(@"DownloadController checkForNewPricingDBVersion error: %@", error.localizedDescription);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self downloadAllHTMLReports];
    });
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
