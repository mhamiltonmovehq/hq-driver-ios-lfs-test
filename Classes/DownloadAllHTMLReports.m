//
//  DownloadAllHTMLReports.m
//  Survey
//
//  Created by Tony Brame on 2/17/15.
//
//

#import "DownloadAllHTMLReports.h"
#import "SurveyAppDelegate.h"
#import "WebSyncRequest.h"
#import "Prefs.h"
#import "AppFunctionality.h"
#import "ReportOptionParser.h"
#import "PVONavigationListItem.h"

@implementation DownloadAllHTMLReports

@synthesize delegate;

-(void)main
{
    @try
    {
        [self updateProgress:0];
        
        NSDictionary *navDict = [_appDelegate.pricingDB getPVOListItems];
        
//        if (navDict == nil)
//        {
////            [SurveyAppDelegate showAlert:@"This tariff is not supported by Mobile Mover. Please contact Support" withTitle:@"Unsupported Tariff"];
//            [self updateError:[NSString stringWithFormat:@"This tariff is not supported by Mobile Mover. Please contact Support"]];
//            return;
//        }
        
        NSArray *navKeys = [navDict allKeys];
        totalProgress = 0;
        for (NSNumber* key in navKeys) {
            totalProgress += 2;//one for the call to see if HTML exists, and another for the potential HTML download.
        }
        
        htmlReports = [[NSMutableArray alloc] init];
        
        WebSyncRequest *req = [[WebSyncRequest alloc] init];
        req.type = WEB_REPORTS;
        req.functionName = @"GetPVOReport";
        req.serverAddress = @"print.moverdocs.com";
        req.pitsDir = @"PVOReports";
        
        if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"webdir:"].location != NSNotFound)
        {//override the default virtual directory
            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"webdir:"];
            req.pitsDir = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
            addpre = [req.pitsDir rangeOfString:@" "];
            if (addpre.location != NSNotFound)
                req.pitsDir = [req.pitsDir substringToIndex:addpre.location];
        }
        
        if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"md:"].location != NSNotFound)
        {
            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"md:"];
            req.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
            addpre = [req.serverAddress rangeOfString:@" "];
            if (addpre.location != NSNotFound)
                req.serverAddress = [req.serverAddress substringToIndex:addpre.location];
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSString stringWithFormat:@"%d", [_appDelegate.pricingDB vanline]] forKey:@"vanLineId"];
        if (([Prefs reportsPassword] == nil || [[Prefs reportsPassword] length] == 0) && [AppFunctionality defaultReportingServiceCustomReportPass] != nil)
            [dict setObject:[AppFunctionality defaultReportingServiceCustomReportPass] forKey:@"customReportsPassword"];
        else
            [dict setObject:[Prefs reportsPassword] == nil ? @"" : [Prefs reportsPassword] forKey:@"customReportsPassword"];
        
        currentProgress = 0;
        
        for (NSNumber* key in navKeys)
        {
                [self updateProgress:currentProgress / totalProgress];
                currentProgress += 1;
                 
                NSString *dest;
                [dict setObject:[NSString stringWithFormat:@"%@", key] forKey:@"reportID"];
                
                if([req getData:&dest withArguments:dict needsDecoded:YES withSSL:YES])
                {
                    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[dest dataUsingEncoding:NSUTF8StringEncoding]];
                    ReportOptionParser *xmlParser = [[ReportOptionParser alloc] init];
                    parser.delegate = xmlParser;
                    [parser parse];
                    
                    if([xmlParser.entries count] > 0)
                    {
                        ReportOption *current = [xmlParser.entries objectAtIndex:0];
                        current.reportTypeID = [key integerValue];
                        current.reportLocation = xmlParser.address;
                        
                        if(current.htmlSupported)
                            [htmlReports addObject:current];
                        else
                            totalProgress -= 1;//since there will be no HTML download for this one
                    }
                    else
                    {
                        //not found on server - for now, ignoring since this is only used as a maintenance utility (and at initial app load)
                        [self updateError:[NSString stringWithFormat:@"Report Type ID %@ not found on server", key]];
                    }
                }
                else
                {
                    //error loading from server - for now, ignoring since this is only used as a maintenance utility (and at initial app load)
                    [self updateError:[NSString stringWithFormat:@"Unable to call service for Report Type ID %@", key]];
                }
            
            
        }
        
        
        
        
        for (ReportOption *opt in htmlReports) {
            
            [self updateProgress:currentProgress / totalProgress];
            currentProgress += 1;
            
            //we found out the hard way that if theres a space at the end of the url the file wont download
            NSData *fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[opt.htmlBundleLocation stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
            
            NSFileManager *mgr = [NSFileManager defaultManager];
            
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            NSString *reportsDir = [docsDir stringByAppendingPathComponent:HTML_FILES_LOCATION];
            NSString *thisReportDir = [reportsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", opt.reportTypeID]];
            
            //make sure the dir exists
            if(![mgr fileExistsAtPath:thisReportDir])
                [mgr createDirectoryAtPath:thisReportDir withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *destFileLocation = [thisReportDir stringByAppendingPathComponent:[opt.htmlBundleLocation lastPathComponent]];
            
            //delete the existing file if it exists
            if([mgr fileExistsAtPath:destFileLocation])
                [mgr removeItemAtPath:destFileLocation error:nil];
            
            //copy file to new path
            [mgr createFileAtPath:destFileLocation contents:fileData attributes:nil];
            
            
                        
            //save current revision to databases
            [_appDelegate.surveyDB saveHTMLReport:opt];
        }
        
        [self updateProgress:1.];
        
        if(self.delegate != nil && [self.delegate respondsToSelector:@selector(downloadHTMLReportsCompleted)])
            [self.delegate performSelectorOnMainThread:@selector(downloadHTMLReportsCompleted) withObject:nil waitUntilDone:YES];
    }
    @catch (NSException *exception)
    {
        [self updateError:[NSString stringWithFormat:@"%@", [exception description]]];
    }
}

-(void)dealloc
{
    self.delegate = nil;
}

-(void)updateProgress:(double)myprogress
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(downloadHTMLReportsUpdateProgess:)])
        [self.delegate performSelectorOnMainThread:@selector(downloadHTMLReportsUpdateProgess:) withObject:[NSNumber numberWithDouble:myprogress] waitUntilDone:YES];
//        [self.delegate downloadHTMLReportsUpdateProgess:myprogress];
}


-(void)updateError:(NSString*)message
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(downloadHTMLReportsError:)])
        [self.delegate performSelectorOnMainThread:@selector(downloadHTMLReportsError:) withObject:message waitUntilDone:YES];
}

@end
