//
//  EmailReport.h
//  Survey
//
//  Created by Tony Brame on 1/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReportDefaults.h"
#import "ReportOption.h"
#import "WebSyncRequest.h"
//#import "DownloadFile.h"

#define TEMP_ZIP_FILE [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"EmailReportPDFs.zip"]
#define REPORT_SAVE_FILE [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]

@class DownloadFile;

@interface GetReport : NSOperation<WebSyncRequestDelegate> {
	ReportDefaults *defaults;
	ReportOption *option;
	NSObject *caller;
	SEL updateCallback;
	BOOL emailReport;
    NSArray *additionalEmails;
    NSArray *ccEmails;
    NSArray *bccEmails;
    
    NSURLConnection *download;
	long long totalLength;
	long long received;
	long long writ;
	FILE *fileRef;
    
    BOOL success;
    
    NSString *errorMessage;
    
    int tag;
    int pvoNavItemID;
    
    BOOL doneExecuting;
}

@property (nonatomic) SEL updateCallback;
@property (nonatomic) BOOL emailReport;
@property (nonatomic) BOOL success;
@property (nonatomic) int tag;
@property (nonatomic) int pvoNavItemID;

@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) ReportOption *option;
@property (nonatomic, retain) ReportDefaults *defaults;
@property (nonatomic, retain) NSURLConnection *download;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSArray *additionalEmails;
@property (nonatomic, retain) NSArray *ccEmails;
@property (nonatomic, retain) NSArray *bccEmails;

@property (nonatomic, retain) NSDictionary *pdfFilesToSend;
@property (nonatomic, retain) NSObject<WebSyncRequestDelegate>* requestDelegate;

-(void)updateProgress:(NSString*)updateString;

@end
