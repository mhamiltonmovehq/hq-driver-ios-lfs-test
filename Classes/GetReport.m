//
//  EmailReport.m
//  Survey
//
//  Created by Tony Brame on 1/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GetReport.h"
#import "SyncGlobals.h"
#import "Base64.h"
#import "SurveyAppDelegate.h"
#import "Prefs.h"
#import "ZipArchive.h"

@implementation GetReport

@synthesize defaults, caller, updateCallback, option, emailReport, download, success, errorMessage, additionalEmails, tag;
@synthesize ccEmails, bccEmails;
@synthesize pdfFilesToSend, requestDelegate;
@synthesize pvoNavItemID;

-(void)main
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try 
	{
		
		//[self updateProgress:@"Successfully saved file."];
		//return;
		
        BOOL async = NO;
        success = TRUE;
        
		//write out emails param
		XMLWriter *emails = [[XMLWriter alloc] init];
		[emails writeStartDocument];
		[emails writeStartElement:@"email"];
		
		if([Prefs useCustomServer])
		{
			[emails writeStartElement:@"custom_server"];
			[emails writeElementString:@"address" withData:[Prefs mailServer]];
			[emails writeElementString:@"username" withData:[Prefs mailUsername]];
			[emails writeElementString:@"password" withData:[Prefs mailPassword]];
			[emails writeElementString:@"port" withIntData:[Prefs mailPort]];
			[emails writeElementString:@"ssl" withData:[Prefs useSSL] ? @"true" : @"false"];
			[emails writeEndElement];
		}
		
		[emails writeStartElement:@"sender"];
		[emails writeElementString:@"name" withData:defaults.agentName];
		[emails writeElementString:@"email_address" withData:defaults.agentEmail];
		[emails writeEndElement];
		[emails writeStartElement:@"receivers"];
		[emails writeStartElement:@"receiver"];
		[emails writeElementString:@"email_address" withData:defaults.toEmail];
		[emails writeEndElement];
        
        if(additionalEmails != nil)
        {
            for (NSString *em in additionalEmails) {
                [emails writeStartElement:@"receiver"];
                [emails writeElementString:@"email_address" withData:em];
                [emails writeEndElement];
            }
        }
        if (ccEmails != nil && [ccEmails count] > 0)
        {
            for (NSString *ccEm in ccEmails) {
                [emails writeStartElement:@"receiver"];
                [emails writeAttribute:@"cc" withData:@"true"];
                [emails writeElementString:@"email_address" withData:ccEm];
                [emails writeEndElement];
            }
        }
        if (bccEmails  != nil && [bccEmails count] > 0)
        {
            for (NSString *bccEm in bccEmails) {
                [emails writeStartElement:@"receiver"];
                [emails writeAttribute:@"bcc" withData:@"true"];
                [emails writeElementString:@"email_address" withData:bccEm];
                [emails writeEndElement];
            }
        }
		
		if([Prefs bccSender])
		{
			[emails writeStartElement:@"receiver"];
			[emails writeAttribute:@"bcc" withData:@"true"];
			[emails writeElementString:@"email_address" withData:defaults.agentEmail];
		}
		
		[emails writeEndDocument];
		
		WebSyncRequest *req = [[WebSyncRequest alloc] init];
		req.type = WEB_REPORTS;
		req.functionName = @"EmailReport";
		req.serverAddress = @"print.moverdocs.com";
        if (emailReport && option.htmlSupported)
        {
            req.pitsDir = @"PVOReports";
            req.overrideWithFullPITSAddress = NO;
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
        }
        else
        {
            req.pitsDir = option.reportLocation;
            req.overrideWithFullPITSAddress = YES;
        }
		
        
		//get the customer xml
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        XMLWriter *cust = [SyncGlobals buildCustomerXML:del.customerID withNavItemID:pvoNavItemID isAtlas:NO];
        
		
		NSString *dest;
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if (emailReport && pdfFilesToSend != nil && [pdfFilesToSend count] > 0)
        {
            XMLWriter *reports = [[XMLWriter alloc] init];
            [reports writeElementString:@"int" withIntData:option.reportID];
            [dict setObject:reports.file forKey:@"reportIDs"];
            [dict setObject:[Base64 encode64:cust.file] forKey:@"byteArray"];
            
            req.functionName = @"EmailReportPDFs";
            
            NSError *err;
            NSString *errMsg = @"Error creating Zip Archive to send to Reporting Service.";
            ZipArchive *zipFiles = [[ZipArchive alloc] init];
            @try {
                //delete temp Zip file if it somehow already exists
                if ([[NSFileManager defaultManager] fileExistsAtPath:TEMP_ZIP_FILE])
                {
                    if (![[NSFileManager defaultManager] removeItemAtPath:TEMP_ZIP_FILE error:&err])
                    {
                        NSLog(@"Error deleting %@.", TEMP_ZIP_FILE);
                        [self updateProgress:errMsg];
                        return;
                    }
                }
                //create a new empty zip file
                if (![zipFiles CreateZipFile2:TEMP_ZIP_FILE])
                {
                    NSLog(@"Error creating %@.", TEMP_ZIP_FILE);
                    [self updateProgress:errMsg];
                    return;
                }
                //zip the stuff up
                for (NSString *filename in [pdfFilesToSend keyEnumerator])
                {
                    if (![zipFiles addFileToZip:[pdfFilesToSend objectForKey:filename] newname:filename])
                    {
                        [zipFiles CloseZipFile2];
                        NSLog(@"Error adding %@ to %@.", filename, TEMP_ZIP_FILE);
                        [self updateProgress:errMsg];
                        return;
                    }
                }
                
                //close the file, we're done!
                [zipFiles CloseZipFile2];
                
                //add it to the stuff we're sending up
                [dict setObject:[Base64 encode64WithData:[NSData dataWithContentsOfFile:TEMP_ZIP_FILE]] forKey:@"pdfs"];
            }
            @finally {
                //release and remove the temp file, always
#ifndef DEBUG
                [[NSFileManager defaultManager] removeItemAtPath:TEMP_ZIP_FILE error:&err];
#endif
            }
        }
        else
        {
            [dict setObject:[NSString stringWithFormat:@"%d", option.reportID] forKey:@"reportID"];
            [dict setObject:[Base64 encode64:cust.file] forKey:@"byteArray"];
        }
		
		NSString *file;
		if(emailReport)
		{
			[dict setObject:[Base64 encode64:emails.file] forKey:@"emailAddresses"];
            [dict setObject:[XMLWriter formatString:defaults.subject] forKey:@"subject"];
            [dict setObject:[XMLWriter formatString:defaults.body] forKey:@"body"];
			file = nil;
		}
		else
		{
            //add timer to use this method.
            //            NSURLConnection *conn;
            //            [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@""];
            //            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
            req.functionName = @"GetReport";
			file = nil;//[[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
		}
        
        if (emailReport && requestDelegate != nil)
        {
            async = YES;
            req.runAsync = YES;
            req.delegate = self;
        }
        
        [req getData:&dest withArguments:dict needsDecoded:YES withSSL:YES];
        
        if (async)
            [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:600]];
		
		if(emailReport && !async)
        {
            [self updateProgress:dest];
        }
        else if (!emailReport)
        {
            //look for a url in the dest.
            //if it is not a url, show progress, and exit.
            //otherwise, start the download process (may need to add params to get run loop to continue going)...
            if(![[dest substringToIndex:4] isEqualToString:@"http"])
            {
                [self updateProgress:dest];
            }
            else
            {
                NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:
                                            [NSURL URLWithString:dest]];
                
                [req setHTTPMethod:@"GET"];
                [req setValue:@"iPhone Survey" forHTTPHeaderField:@"User-Agent"];
                
                self.download = [[NSURLConnection alloc] initWithRequest:req delegate:self];
                
                totalLength = 0;
                received = 0;
                writ = 0;
                
                if([NSURLConnection canHandleRequest:req])
                {
                    //begin receiving
                    NSFileManager *mgr = [NSFileManager defaultManager];
                    BOOL isDir;
                    if([mgr fileExistsAtPath:REPORT_SAVE_FILE isDirectory:&isDir])
                        [mgr removeItemAtPath:REPORT_SAVE_FILE error:nil];
                    
                    fileRef = fopen([REPORT_SAVE_FILE UTF8String], "a+");
                    if(fileRef == NULL)
                        [self updateProgress:@"Unable to create output file. Please try again later."];
                    else 
                    {
                        fileRef = NULL;
                        fclose(fileRef);
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                        [download start];			
                        [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:600]];
                    }
                    
                }
                else 
                {
                    success = FALSE;
                    [self updateProgress:@"Receiver was unable to process the file request. Please try again later."];
                }
                
                
            }
        }

        if (!async)
            doneExecuting = YES;
		
	}
	@catch (NSException * e) {
		doneExecuting = YES;
		success = FALSE;
		[self updateProgress:[NSString stringWithFormat:@"Exception on Email Thread: %@", [e description]]];
		
	}
	
	
	
    //exit:
    
    //i may not want to do this?
    //	[pool drain];
    //	[pool release];
	
}

-(BOOL)isFinished
{
    if (emailReport && option.htmlSupported && pdfFilesToSend != nil && [pdfFilesToSend count] > 0)
        return doneExecuting;
    return [super isFinished];
}

-(void)updateProgress:(NSString*)updateString
{
    self.errorMessage = updateString;
	if(updateString == nil || [updateString length] == 0)
		return;
	
	if(caller != nil && [caller respondsToSelector:updateCallback] && !self.isCancelled)
	{
		[caller performSelectorOnMainThread:updateCallback withObject:updateString waitUntilDone:NO];
	}
}

#pragma mark WebSyncRequestDelegate methods

-(void)progressUpdate:(WebSyncRequest *)request isResponse:(BOOL)isResponse withBytesSent:(NSInteger)sent withTotalBytes:(NSInteger)total
{
    if (requestDelegate != nil && [requestDelegate respondsToSelector:@selector(progressUpdate:isResponse:withBytesSent:withTotalBytes:)])
        [requestDelegate progressUpdate:request isResponse:isResponse withBytesSent:sent withTotalBytes:total];
}

-(void)completed:(WebSyncRequest *)request withSuccess:(BOOL)requestSuccess andData:(NSString *)response
{
    if (requestDelegate != nil && [requestDelegate respondsToSelector:@selector(completed:withSuccess:andData:)])
        [requestDelegate completed:request withSuccess:requestSuccess andData:response];
    [self updateProgress:response];
    doneExecuting = YES;
}

#pragma mark URL COnnection Delegate methods

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if([challenge previousFailureCount] > 1)
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    else
    {
        NSURLCredential *creds = [NSURLCredential credentialWithUser:@"netuser" password:@"MMHn8%age34" persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:creds forAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(fileRef != NULL)
		fclose(fileRef);
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	[self updateProgress:[NSString stringWithFormat:@"Error Receiving Data.  Please try again later.\r\n\r\n%@", [error description]]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{	
    fileRef = fopen([REPORT_SAVE_FILE UTF8String], "a+");
	fwrite([data bytes], 1, [data length], fileRef);
    fflush(fileRef);
    fclose(fileRef);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	totalLength = [response expectedContentLength];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	/*if(fileRef != NULL)
     {
     fflush(fileRef);
     fclose(fileRef);
     }*/
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSDictionary *dict = [mgr attributesOfItemAtPath:REPORT_SAVE_FILE error:nil];
	
	if(dict != nil && [dict	objectForKey:NSFileSize] != nil)
	{
		if([[dict objectForKey:NSFileSize] longLongValue] < (1 * 1024))
		{//less than 1 kb, error out. (prolly didnt exist at path on site)
			[self updateProgress:@"Error receiving document. Code 72"];
			return;
		}
	}
	
    [self updateProgress:@"Successfully saved file."];
    
}

@end
