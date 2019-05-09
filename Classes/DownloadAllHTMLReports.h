//
//  DownloadAllHTMLReports.h
//  Survey
//
//  Created by Tony Brame on 2/17/15.
//
//

#import <Foundation/Foundation.h>

@protocol DownloadAllHTMLReportsDelegate <NSObject>

-(void)downloadHTMLReportsUpdateProgess:(NSNumber*)progress;
-(void)downloadHTMLReportsCompleted;
-(void)downloadHTMLReportsError:(NSString*)error;

@end

@class DownloadFile, SurveyAppDelegate;

@interface DownloadAllHTMLReports : NSOperation
{
    double totalProgress;
    double currentProgress;
    DownloadFile *htmlDownloader;
    NSMutableArray *htmlReports;
    id<DownloadAllHTMLReportsDelegate> delegate;
}

@property (nonatomic, retain) NSObject<DownloadAllHTMLReportsDelegate> *delegate;
@property (nonatomic, assign) SurveyAppDelegate *appDelegate;

-(void)updateProgress:(double)myprogress;
-(void)updateFromDownload:(NSString*)message;
-(void)updateError:(NSString*)message;
-(void)downloadNextDoc;

@end
