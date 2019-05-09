//
//  DownloadFile.m
//  Survey
//
//  Created by Tony Brame on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DownloadFile.h"
#import "SurveyAppDelegate.h"
//#include <iostream>
#import "ZipArchive.h"

@implementation DownloadFile

@synthesize receivedDataCallback, messageCallback, sizeCallback,errorCallback, completedCallback, caller, conn;
@synthesize received, totalLength, fileName, downloadURL, fullFilePath, downloadLocationFolder;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.unzipFile = YES;
    }
    return self;
}


-(void)start
{    
    //with url?
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:
                                [NSURL URLWithString:
                                 downloadURL]];
    
    [req setHTTPMethod:@"GET"];
    //[req setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"iPhone Survey" forHTTPHeaderField:@"User-Agent"];
    //[req setValue:[[NSNumber numberWithUnsignedInt:[postData length]] stringValue] forHTTPHeaderField:@"Content-Length"];
    
    NSURLConnection *tempConn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    
    self.conn = tempConn;
    
    totalLength = 0;
    received = 0;
    writ = 0;
    
    NSRange range = [downloadURL rangeOfString:@"/" options:NSBackwardsSearch];
    self.fileName = [downloadURL substringFromIndex:range.location+1];
    
    if([NSURLConnection canHandleRequest:req])
    {
        //begin receiving
        //changing text for Mobile Mover
        [self updateMessage:@"Downloading Application Data"];/* [NSString stringWithFormat:
                             @"Downloading File: %@", fileName]];*/
        
        self.fullFilePath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:fileName];
        NSFileManager *mgr = [NSFileManager defaultManager];
        BOOL isDir;
        
        if([mgr fileExistsAtPath:fullFilePath isDirectory:&isDir])
        {
            [mgr removeItemAtPath:fullFilePath error:nil];
        }
        
        fileRef = NULL;
        fileRef = fopen([fullFilePath UTF8String], "a+");
        if(fileRef == NULL)
        {
            [self updateMessage:@"Error: Unable to create output file. Please try again later."];
        }
        else 
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [conn start];            
        }

        
    }
    else 
    {
        [self updateMessage:@"Error: Receiver was unable to process the file request. Please try again later."];
    }

    
}

-(void)completed
{
    if([caller respondsToSelector:completedCallback])
    {
        [caller performSelectorOnMainThread:completedCallback withObject:nil waitUntilDone:NO];
    }
}

-(void)error
{
    if([caller respondsToSelector:errorCallback])
    {
        [caller performSelectorOnMainThread:errorCallback withObject:nil waitUntilDone:NO];
    }
}

-(void)updateMessage:(NSString*)updateString
{
    if(updateString == nil || [updateString length] == 0)
        return;
    
    if([caller respondsToSelector:messageCallback])
    {
        [caller performSelectorOnMainThread:messageCallback withObject:updateString waitUntilDone:NO];
    }
}

-(void)receivedData
{
    if([caller respondsToSelector:receivedDataCallback])
    {
        [caller performSelectorOnMainThread:receivedDataCallback withObject:nil waitUntilDone:NO];
    }
}

-(void)updateSize:(long long)size
{
    if([caller respondsToSelector:sizeCallback])
    {
        [caller performSelectorOnMainThread:sizeCallback withObject:[NSNumber numberWithLongLong:size] waitUntilDone:NO];
    }
}


-(void)cancel
{    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;    
    [conn cancel];
}


#pragma mark URL COnnection Delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(fileRef != NULL)
        fclose(fileRef);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;    
    [self updateMessage:[NSString stringWithFormat:@"Error Receiving Data.  Please try again later.\r\n\r\n%@", [error description]]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{    
    
    fwrite([data bytes], 1, [data length], fileRef);
    
    writ += [data length];
    if(writ >= ONE_MB)
    {
        fflush(fileRef);
        writ = 0;
    }
    
    received += [data length];
    
    [self receivedData];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    totalLength = [response expectedContentLength];
    [self updateSize:totalLength];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(fileRef != NULL)
    {
        fflush(fileRef);
        fclose(fileRef);
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;    
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSDictionary *dict = [mgr attributesOfItemAtPath:fullFilePath error:nil];
    
    if(dict != nil && [dict    objectForKey:NSFileSize] != nil)
    {
        if([[dict objectForKey:NSFileSize] longLongValue] < (10 * 1024))
        {//less than ten kb, error out. (prolly didnt exist at path on site)
            [self updateMessage:[NSString stringWithFormat:
                                 @"Error receiving file provided by Site.  Code 34, location %@",
                                 downloadLocationFolder]];
            return;
        }
    }
    
    //check for zip, then 
    //unzip using lib from http://www.iphonedevsdk.com/forum/iphone-sdk-development/7615-simple-objective-c-class-zip-unzip-zip-format-files.html
    if(self.unzipFile && [fileName rangeOfString:@".zip"].location != NSNotFound)
    {
        [self updateMessage:[NSString stringWithFormat:@"Unzipping %@", fileName]];
        ZipArchive *zipper = [[ZipArchive alloc] init];
        
        if(![zipper     UnzipOpenFile:fullFilePath])
        {
            [self updateMessage:@"Error: Unable to extract zip file to Documents Directory."];
            return;
        }
        else 
        {
            if([zipper UnzipFileTo:[SurveyAppDelegate getDocsDirectory] overWrite:YES])
            {
                [self updateMessage:@"Completed Download!"];
                [zipper UnzipCloseFile];
            }
            else
            {
                [self updateMessage:@"Error: Unable to extract zip file to Documents Directory."];
                [zipper UnzipCloseFile];
                return;
            }
            
        }

        [mgr removeItemAtPath:fullFilePath error:nil];
        
    }
    else
        [self updateMessage:@"Completed Download!"];
    
    [self completed];
}
@end
