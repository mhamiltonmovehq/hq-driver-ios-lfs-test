//
//  DownloadController.h
//  Survey
//
//  Created by Tony Brame on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadFile.h"
#import "DownloadAllHTMLReports.h"

#define DOWNLOAD_NUM_FILES 1
#define DOWNLOAD_TARIFF_URL @"https://update.igcsoftware.com/jBa96LP1v/iphone/tariff/"
#define DOWNLOAD_TARIFF_NAME @"Pricing.zip"
#define DOWNLOAD_PVO_CONTROL_NAME @"pvo_control.zip"
//#define DOWNLOAD_MILEAGE_URL @"https://update.igcsoftware.com/jBa96LP1v/iphone/mileage/"
//#define DOWNLOAD_MILEAGE_NAME @"Miles.zip"

@interface DownloadController : UIViewController <DownloadAllHTMLReportsDelegate> {
	IBOutlet UILabel *labelReceived;
	IBOutlet UILabel *labelRemainingTime;
	IBOutlet UILabel *labelFileNumber;
	IBOutlet UITextView *tboxInformation;
	IBOutlet UIProgressView *progress;
	IBOutlet UIView *infoView;
	IBOutlet UIBarButtonItem *cmdContinue;
    IBOutlet UIImageView *img_logo;
	DownloadFile *download;
	NSURLConnection *conn;
	NSTimeInterval start;
	int currentFile;
	BOOL processing;
    BOOL dismiss;
    BOOL downloadHTMLReportsOnly;
	IBOutlet UINavigationBar *navBar;
}

@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) UILabel *labelRemainingTime;
@property (nonatomic, retain) UILabel *labelReceived;
@property (nonatomic, retain) UILabel *labelFileNumber;
@property (nonatomic, retain) UIProgressView *progress;
@property (nonatomic, retain) UITextView *tboxInformation;
@property (nonatomic, retain) UIView *infoView;
@property (nonatomic, retain) DownloadFile *download;
@property (nonatomic, retain) NSURLConnection *conn;
@property (nonatomic, retain) UIBarButtonItem *cmdContinue;
@property (retain, nonatomic) UIImageView *img_logo;

@property (nonatomic) BOOL dismiss;
@property (nonatomic) BOOL downloadHTMLReportsOnly;

-(IBAction)done:(id)sender;
-(IBAction)start:(id)sender;

-(void)fileSize:(NSNumber*)fileSize;
-(void)updateProgress:(double)progressValue;
-(void)receivedData;
-(void)updateMessage:(NSString*)updateString;

-(void)completed;
-(void)error;

@end
