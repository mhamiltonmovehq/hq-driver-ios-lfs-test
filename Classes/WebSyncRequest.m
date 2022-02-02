//
//  WebSyncRequest.m
//  Survey
//
//  Created by Tony Brame on 7/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WebSyncRequest.h"
#import "Base64.h"
#import "WCFDataParam.h"
#import "AppFunctionality.h"
#import "Prefs.h"
#import "SurveyAppDelegate.h"

@implementation WebSyncParam

@synthesize paramName, paramValue;

@end


@implementation WebSyncRequest

@synthesize type, port, username, serverAddress, functionName, pitsDir, overrideWithFullPITSAddress;//, data;
@synthesize runAsync, delegate;


-(BOOL)getData:(NSString**)dest
{
	NSDictionary *dict = [NSDictionary dictionaryWithObject:username forKey:@"username"];
	return [self getData:dest withArguments:dict needsDecoded:TRUE];
}

-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode
{
	return [self getData:dest withArguments:args needsDecoded:decode withSSL:NO];
}

-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl
{
	return [self getData:dest withArguments:args needsDecoded:decode withSSL:ssl flushToFile:nil];
}

-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl flushToFile:(NSString*)filePath
{
    return [self getData:dest withArguments:args needsDecoded:decode  withSSL:ssl flushToFile:filePath withOrder:nil];
}

-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl flushToFile:(NSString*)filePath withOrder:(NSArray*)order
{
	BOOL success = FALSE;
	
	NSURL *url;
	
	if(!overrideWithFullPITSAddress)
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@%@", 
									ssl ? @"https" : @"http",
									serverAddress, 
									port != 80 && port != 0 ? [NSString stringWithFormat:@":%d", port] : @"",
									[self servicePath]]];
	else
		url	= [NSURL URLWithString:pitsDir];
    
    NSLog(@"REQ.ServiceURL: %@", [NSString stringWithFormat:@"%@", url]);
    NSLog(@"REQ.Function name: %@", [NSString stringWithFormat:@"%@",functionName]);
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	NSString *postData = [NSString stringWithFormat:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body>"
						  "<%@ xmlns=\"%@\">", functionName, [self serviceXMLNS]];//maybe not XMLNS here for Custom Item Lists!!!...
	
    
	
	//add all of the arguments (strings)
	NSArray *keys = [args allKeys];
    if(order != nil)
        keys = order;
	//[keys sortedArrayUsingSelector:@selector(compare:)];
	NSString *paramData;
	for(int i = 0; i < [keys count]; i++)
	{
		NSNumber *key = [keys objectAtIndex:i];
		if([[args objectForKey:key] isKindOfClass:[WCFDataParam class]])
		{
			WCFDataParam *myWCFData = [args objectForKey:key];
			postData = [postData stringByAppendingString:myWCFData.contents];
		}
		else if([[args objectForKey:key] isKindOfClass:[NSData class]])
		{
			paramData = [[NSString alloc] initWithData:[args objectForKey:key] encoding:NSUTF8StringEncoding];
			postData = [postData stringByAppendingString:[NSString stringWithFormat:@"<%@>%@</%@>", key, paramData, key]];
		}
		else
		{
			postData = [postData stringByAppendingString:[NSString stringWithFormat:@"<%@>%@</%@>", key, [args objectForKey:key], key]];
		}
		
	}
	
	postData = [postData stringByAppendingString:[NSString stringWithFormat:@"</%@></soap:Body></soap:Envelope>", functionName]];
    
    
    //NSLog(@"POST Data: %@", [NSString stringWithFormat:@"%@", postData]);
	
	[req setHTTPMethod:@"POST"];
	[req setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	
	NSString *nameSpace = [self soapActionPrefix];
	if([nameSpace characterAtIndex:[nameSpace length]-1] == '/')
		[req setValue:[NSString stringWithFormat:@"\"%@%@\"", nameSpace, functionName] forHTTPHeaderField:@"SOAPAction"];
	else
		[req setValue:[NSString stringWithFormat:@"\"%@/%@\"", nameSpace, functionName] forHTTPHeaderField:@"SOAPAction"];
	
	[req setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
	[req setValue:[url host] forHTTPHeaderField:@"Host"];
	[req setValue:[[NSNumber numberWithUnsignedInt:[postData length]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	NSMutableData *postDataArray = [NSMutableData data];
	
	[postDataArray appendData:[[NSString stringWithString:postData] dataUsingEncoding:NSUTF8StringEncoding]];
    
	[req setHTTPBody:postDataArray];
    
    if (type == PVO_SYNC || type == ATLAS_SYNC)
        [req setTimeoutInterval:[AppFunctionality webRequestTimeoutInSeconds]];
    
	NSURLResponse *response;
	NSError *error = nil;
	
    if (runAsync && delegate != nil)
    {
        //needs to be done async, and report progress to the progressDelegate
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        asyncDecode = decode;
        asyncFilePath = filePath;
        asyncConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        success = NO; //always return no, since we're running async
        [asyncConnection start];
        [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:600]];
    }
    else
    {
        //do it synchronously, don't care about progress
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        
        success = [self populateResult:dest withData:data andResponse:response andError:error needsDecoded:decode flushToFile:filePath];
    }

    return success;
}

-(BOOL)populateResult:(NSString**)result withData:(NSData*)data andResponse:(NSURLResponse*)response andError:(NSError*)error needsDecoded:(BOOL)decode flushToFile:(NSString*)filePath
{
    if(error != nil)
	{
		*result = [[NSString alloc] initWithFormat:@"ERROR Receiving Data: %@", error.localizedDescription];
		return FALSE;
	}
	
	NSString * rsltStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
	NSRange range, temp;
	temp = [rsltStr rangeOfString:[NSString stringWithFormat:@"<%@Result", functionName]];
	if(temp.location == NSNotFound)
	{
		//look for faultstring and end
		temp = [rsltStr rangeOfString:@"<faultstring"];
		if(temp.location == NSNotFound)
			*result = [NSString stringWithFormat:@"Unable to locate result in return value.  Return Value: %@", rsltStr];
		else
		{
            temp = [rsltStr rangeOfString:@">" options:0 range:NSMakeRange(temp.location, rsltStr.length - temp.location)];
            
			range.location = temp.location + temp.length;
			temp = [rsltStr rangeOfString:@"</faultstring>"];
			if(temp.location == NSNotFound)
				*result = [NSString stringWithFormat:@"Unable to locate result in return value.  Return Value: %@", rsltStr];
			else
			{
				range.length = temp.location - range.location;
				NSString *faultString = [rsltStr substringWithRange:range];
				*result = [NSString stringWithFormat:@"Sync Error: %@", faultString];
//				[faultString release];
			}
		}
        
		return FALSE;
	}
	
	//keepo the result node if not decoding 3.21.11
	if(decode)
		range.location = temp.location + temp.length;
	else
		range.location = temp.location;
    
    
	//this doesn't handle the case where the result is just a trailing />.  this needs accounted for for WCF calls
	temp = [rsltStr rangeOfString:[NSString stringWithFormat:@"</%@Result>", functionName]];
	if(temp.location == NSNotFound)
	{
		//find next ">"
		NSRange nextCarot = [rsltStr rangeOfString:@">"
										   options:NSCaseInsensitiveSearch
											 range:NSMakeRange(range.location, [rsltStr length] - range.location)];
		if(nextCarot.location != NSNotFound)
			temp = [rsltStr rangeOfString:[NSString stringWithFormat:@"/>"]
								  options:NSCaseInsensitiveSearch
									range:NSMakeRange(range.location, (nextCarot.location + 1) - range.location)];
		
		if(temp.location == NSNotFound)
		{
			*result = [NSString stringWithFormat:@"Unable to locate end result in return value.  Return Value: %@", rsltStr];
			return FALSE;
		}
	}
	
	//keep the result node if not decoding 3.21.11
	if(decode)
		range.length = temp.location - range.location;
	else
		range.length = (temp.location - range.location) + temp.length;
	
	NSString *newData = [rsltStr substringWithRange:range];
	
	if(decode)
	{
//		[newData release];
		NSData *decoded = [Base64 decode64:newData];
		if(filePath != nil)
		{//save the data as a file to the file system using passed path
			
			NSFileManager *mgr = [NSFileManager defaultManager];
			BOOL isDir;
			
			if([mgr fileExistsAtPath:filePath isDirectory:&isDir])
				[mgr removeItemAtPath:filePath error:&error];
			
			if(![mgr createFileAtPath:filePath contents:decoded attributes:nil])
				newData = @"Error saving file to device.";
			else
				newData = @"Successfully saved file.";
            
		}
		else
		{
            newData = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
//            newData = [NSString stringWithUTF8String:(const char *)[decoded bytes]];
		}
        
	}
    
    
//    NSLog(@"Result: %@", [NSString stringWithFormat:@"%@", newData]);
	
	*result = newData;
	return YES;
}

-(BOOL)sendFile:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl
{
	BOOL success = FALSE;
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", 
									   ssl ? @"https" : @"http", serverAddress, [self servicePath]]];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	NSString *postData = [NSString stringWithFormat:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body>"
						  "<%@ xmlns=\"%@\">", functionName, [self serviceXMLNS]];
	
	//add all of the arguments (strings)
	NSArray *keys = [args allKeys];
	[keys sortedArrayUsingSelector:@selector(compare:)];
	NSString *paramData;
	for(int i = 0; i < [keys count]; i++)
	{
		NSNumber *key = [keys objectAtIndex:i];
		WebSyncParam *param = [args objectForKey:key];

		paramData = [[NSString alloc] initWithString:param.paramValue];
		
		postData = [postData stringByAppendingString:[NSString stringWithFormat:@"<%@>%@</%@>", param.paramName, paramData, param.paramName]];
	}
	
	postData = [postData stringByAppendingString:[NSString stringWithFormat:@"</%@></soap:Body></soap:Envelope>", functionName]];
	
	[req setHTTPMethod:@"POST"];
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject:@"text/xml;charset=UTF-8" forKey:@"Content-Type"];
	[dict setObject:@"\"FileUtility/StoreFile\"" forKey:@"SOAPAction"];
	[dict setObject:@"ws.mobilemover.com" forKey:@"Host"];
	[dict setObject:[[NSNumber numberWithUnsignedInt:[postData length]] stringValue] forKey:@"Content-Length"];
	[dict setObject:@"100-continue" forKey:@"expect"];
	[dict setObject:@"Keep-Alive" forKey:@"Connection"];
	
	NSURLResponse *response;
	NSError *error;
	
	[req setAllHTTPHeaderFields:dict];
	
	NSMutableData *postDataArray = [NSMutableData data];
	
	[postDataArray appendData:[[NSString stringWithString:postData] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postDataArray];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;	
	NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(error != nil)
	{
		*dest = [NSString stringWithFormat:@"ERROR Receiving Data: %@", error.localizedDescription];
		return FALSE;
	}
	
	NSString * rsltStr =  [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	
	NSRange range, temp;
	temp = [rsltStr rangeOfString:[NSString stringWithFormat:@"<%@Result>", functionName]];
	if(temp.location == NSNotFound)
	{
		*dest = [NSString stringWithFormat:@"Unable to locate result in return value.  Return Value: %@", rsltStr];
		return FALSE;
	}
	
	range.location = temp.location + temp.length;
	temp = [rsltStr rangeOfString:[NSString stringWithFormat:@"</%@Result>", functionName]];
	if(temp.location == NSNotFound)
	{
		*dest = [NSString stringWithFormat:@"Unable to locate end result in return value.  Return Value: %@", rsltStr];
		return FALSE;
	}	
	
	range.length = temp.location - range.location;
	
	NSString *newData = [NSString stringWithString:[rsltStr substringWithRange:range]];
	
	if(decode)
	{
		NSData *decoded = [Base64 decode64:newData];
		newData = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
	}
	
	*dest = newData;
	
	success = TRUE;
	return success;
	
}

-(NSString*)servicePath
{
    if(type == ATLAS_SYNC)
		return ATLAS_WEB_SERVICE_PATH;
	else if(type == FILE_UPLOAD)
		return FILE_WEB_SERVICE_PATH;
	else if(type == WEB_REPORTS)
	{
		if(pitsDir == nil)
			return RPT_WEB_SERVICE_PATH;
		else 
		{
			return [NSString stringWithFormat:@"/%@%@", pitsDir, RPT_WEB_SERVICE_PATH];
		}

	}
	else if (type == CUSTOM_ITEM_LISTS)
		return ITEM_LISTS_WCF_PATH;
	else if (type == PVO_SYNC)
    {
        return PVO_WCF_PATH;
    }
	else if (type == HEARTBEAT)
		return HEARTBEAT_WCF_PATH;
    else if (type == ATLAS_SYNC_CANADA)
    {
        if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"cnbeta"].location != NSNotFound)
            return ATLAS_CANADA_WEB_SERVICE_PATH_BETA;
        else
            return ATLAS_CANADA_WEB_SERVICE_PATH;
    }
	return nil;

}

-(NSString*)serviceXMLNS
{
	if(type == ATLAS_SYNC)
		return ATLAS_WEB_SERVICE_XMLNS;
	else if(type == FILE_UPLOAD)
		return FILE_WEB_SERVICE_XMLNS;
	else if(type == WEB_REPORTS)
		return RPT_WEB_SERVICE_XMLNS;
	else if (type == CUSTOM_ITEM_LISTS)
		return ITEM_LISTS_WCF_XMLNS;
	else if (type == PVO_SYNC)
		return PVO_WCF_XMLNS;
	else if (type == ACTIVATION)
		return ACTIVATION_WCF_XMLNS;
	else if (type == HEARTBEAT)
		return HEARTBEAT_WCF_XMLNS;
    else if (type == ATLAS_SYNC_CANADA)
    {
#if defined(DEBUG) || defined(RELEASE)
        return ATLAS_CANADA_WEB_SERVICE_XMLNS;
#else
        if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"cnbeta"].location != NSNotFound)
            return ATLAS_CANADA_WEB_SERVICE_XMLNS;
        else
            return ATLAS_CANADA_WEB_SERVICE_XMLNS;
#endif
    }
	return nil;
}

-(NSString*)soapActionPrefix
{
	if(type == ATLAS_SYNC)
		return ATLAS_WEB_SERVICE_XMLNS;
	else if(type == FILE_UPLOAD)
		return FILE_WEB_SERVICE_XMLNS;
	else if(type == WEB_REPORTS)
		return RPT_WEB_SERVICE_XMLNS;
	else if (type == CUSTOM_ITEM_LISTS)
		return ITEM_LISTS_WCF_SOAP_ACTION_PREFIX;
	else if (type == PVO_SYNC)
		return PVO_WCF_SOAP_ACTION_PREFIX;
	else if (type == ACTIVATION)
		return ACTIVATION_WCF_SOAP_ACTION_PREFIX;
	else if (type == HEARTBEAT)
        return HEARTBEAT_WCF_SOAP_ACTION_PREFIX;
    else if (type == ATLAS_SYNC_CANADA)
    {
#if defined(DEBUG) || defined(RELEASE)
        return ATLAS_CANADA_WEB_SERVICE_XMLNS;
#else
        if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"cnbeta"].location != NSNotFound)
            return ATLAS_CANADA_WEB_SERVICE_XMLNS;
        else
            return ATLAS_CANADA_WEB_SERVICE_XMLNS;
#endif
    }
	return nil;
}

-(NSString*)userAgent
{
	if(type == ATLAS_SYNC || type == ATLAS_SYNC_CANADA)
		return ATLAS_USER_AGENT;
	else if(type == FILE_UPLOAD)
		return FILE_USER_AGENT;
	else if(type == WEB_REPORTS)
		return RPT_USER_AGENT;
	else if (type == CUSTOM_ITEM_LISTS)
		return ITEM_LISTS_WCF_USER_AGENT;
	else if (type == PVO_SYNC)
		return PVO_WCF_USER_AGENT;
	else if (type == HEARTBEAT)
		return HEARTBEAT_WCF_USER_AGENT;
    else if (type == ACTIVATION)
        return ACTIVATION_USER_AGENT;
    
	return nil;
}

#pragma mark NSURLConnectionDataDelegate methods

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (runAsync && delegate != nil && [delegate respondsToSelector:@selector(progressUpdate:isResponse:withBytesSent:withTotalBytes:)])
        [delegate progressUpdate:self isResponse:NO withBytesSent:totalBytesWritten withTotalBytes:totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (asyncData == nil)
        asyncData = [[NSMutableData alloc] initWithData:data];
    else
        [asyncData appendData:data];
    
    [self finishAsyncConnection];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    asyncResponse = response;
    [self finishAsyncConnection];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    asyncError = error;
    asyncIsFinished = YES;
    [self finishAsyncConnection];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    asyncIsFinished = YES;
    [self finishAsyncConnection];
}

-(void)finishAsyncConnection
{
    if (asyncIsFinished)
    {
        if (delegate != nil && [delegate respondsToSelector:@selector(completed:withSuccess:andData:)])
        {
            NSString * result;
            BOOL success = [self populateResult:&result withData:asyncData andResponse:asyncResponse andError:asyncError needsDecoded:asyncDecode flushToFile:asyncFilePath];
            [delegate completed:self withSuccess:success andData:result];
        }
        asyncData = nil;
        asyncResponse = nil;
        asyncError = nil;
        asyncFilePath = nil;
        asyncIsFinished = NO;
    }
}

//#pragma mark NSURLConnectionDownloadDelegate methods
//
//-(void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes
//{
//    if (runAsync && delegate != nil && [delegate respondsToSelector:@selector(progressUpdate:isResponse:withBytesSent:withTotalBytes:)])
//        [delegate progressUpdate:self isResponse:YES withBytesSent:totalBytesWritten withTotalBytes:expectedTotalBytes];
//}
//
//-(void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes
//{
//    if (runAsync && delegate != nil && [delegate respondsToSelector:@selector(progressUpdate:isResponse:withBytesSent:withTotalBytes:)])
//        [delegate progressUpdate:self isResponse:YES withBytesSent:totalBytesWritten withTotalBytes:expectedTotalBytes];
//}

@end


@implementation NSURLRequest(DataController)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
	return YES; // Or whatever logic
}
@end
