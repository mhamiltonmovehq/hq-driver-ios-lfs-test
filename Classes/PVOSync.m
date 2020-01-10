//
//  PVOSync.m
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//#import <AdSupport/ASIdentifierManager.h>
#import "PVOSync.h"
#import "WebSyncRequest.h"
#import "Prefs.h"
#import "XMLWriter.h"
#import "Base64.h"
#import "SurveyDownloadXMLParser.h"
#import "SurveyAppDelegate.h"
#import "CancelledSurveyParser.h"
#import "CustomerListItem.h"
#import "RoomSummary.h"
#import "SuccessParser.h"
#import "SurveyImage.h"
#import "SyncGlobals.h"
#import "LoadCustomItemLists.h"
#import "GetReport.h"
#import "PVOImageParser.h"
#import "PVOInventoryParser.h"
#import "PVOTokenParser.h"
#import "WCFDataParam.h"
#import "AppFunctionality.h"
#import "OpenUDID.h"
#import "PVOPrintController.h"
#import "ReportOptionParser.h"
#import "PVOPreShipChecklistParser.h"
#import "PVONavigationListItem.h"
#import "PVOSTGBOLParser.h"

@interface PVOSync ()

@property (nonatomic, weak) SurveyAppDelegate *appDelegate;
@property (nonatomic, strong) DriverData *driverData;

@end

@implementation PVOSync

@synthesize updateCallback, updateWindow, completedCallback, errorCallback;
@synthesize orderNumber, syncAction, inventoryItemEntries, pvoReportID, mergeCustomer, downloadRequestType;
@synthesize receivedType, receivedUnloadType, loadType;
@synthesize additionalParamInfo;
@synthesize mproWeight, sproWeight, consWeight;
@synthesize delegate;
@synthesize uploadPhotosWithInventory;
@synthesize isDelivery;

-(id)init
{
    self = [super init];
    if(self)
    {
        _appDelegate = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.driverData = [_appDelegate.surveyDB getDriverData];
        
        req = [[WebSyncRequest alloc] init];
        uploadPhotosWithInventory = YES;
        
        if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"add:"].location != NSNotFound)
        {
            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"add:"];
            req.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
            ssl = req.port == 443 || [req.serverAddress rangeOfString:@":443"].location != NSNotFound;
            addpre = [req.serverAddress rangeOfString:@" "];
            if (addpre.location != NSNotFound)
                req.serverAddress = [req.serverAddress substringToIndex:addpre.location];
        }
    }
    return self;
}


-(void)dealloc
{
    _appDelegate = nil;
    
}

-(void)main
{
    BOOL success = YES;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    _appDelegate.surveyDB.runningOnSeparateThread = YES;
    @try
    {
        ssl = FALSE;
        
        
        switch ([_appDelegate.pricingDB vanline]) {
#ifdef ATLASNET
            case ATLAS:
                if (syncAction == PVO_SYNC_ACTION_SYNC_CANADA)
                {
                    //#if defined(DEBUG) || defined(RELEASE)
                    //                    req.serverAddress = @"dev.mobilemover.com";
                    //                    req.port = 8083;
                    //
                    //#else
                    req.serverAddress = @"survey.atlasvanlines.ca";
                    
                    //#endif
                }
                else
                {
                    //debug and release use the test sites
#if defined(DEBUG) || defined(RELEASE)
                    req.serverAddress = @"wsqs.atlasworldgroup.com";
#else
                    req.serverAddress = @"wsps.atlasworldgroup.com";
#endif
                    req.port = 80;
                    req.type = ATLAS_SYNC;
                }
                break;
#endif
            case ARPIN:
#if defined(DEBUG) || defined(RELEASE)
                req.serverAddress = @"dev.mobilemover.com";
                req.port = 8080;
                req.type = PVO_SYNC;
#else
                req.serverAddress = ARPIN_PVO_WCF_ADDRESS;
                req.port = 80;
                req.type = PVO_SYNC;
#endif
                break;
            case MCCOLLISTERS:
#if defined(DEBUG)
                req.serverAddress = @"dev.mobilemover.com";
                req.port = 8081;
                req.type = PVO_SYNC;
#else
                ssl = YES;
                req.serverAddress = PVO_WCF_ADDRESS;
                req.port = 443;
                req.type = PVO_SYNC;
#endif
                break;
            default:
                //debug and release use the test sites
//                req.serverAddress = @"dev.mobilemover.com";
                ssl = YES;
                req.serverAddress = @"homesafe-aisync.movehq.com";
                req.port = 443;
                req.type = PVO_SYNC;
                break;
        }
        
        if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"add:"].location != NSNotFound)
        {
            req.port = 0;
            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"add:"];
            req.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
            ssl = req.port == 443 || [req.serverAddress rangeOfString:@":443"].location != NSNotFound;
            addpre = [req.serverAddress rangeOfString:@" "];
            if (addpre.location != NSNotFound)
                req.serverAddress = [req.serverAddress substringToIndex:addpre.location];
        }
        
        
        NSLog(@"REQ.ServerAddress: %@", [NSString stringWithFormat:@"%@", req.serverAddress]);
        
        switch (syncAction) {
            case PVO_SYNC_ACTION_DOWNLOAD:
                [self downloadSurvey];
                break;
            case PVO_SYNC_ACTION_SYNC_CANADA:
            case PVO_SYNC_ACTION_UPLOAD_INVENTORY:
            case PVO_SYNC_ACTION_UPLOAD_DEL_HVI:
            case PVO_SYNC_ACTION_UPLOAD_PPI:
            case PVO_SYNC_ACTION_UPLOAD_WEIGHT_TICKET:
            case PVO_SYNC_ACTION_UPLOAD_PACK_SERVICES:
            case PVO_SYNC_ACTION_UPLOAD_BOL:
            case PVO_SYNC_ACTION_UPLOAD_DOCUMENT_WITH_REPORTTYPEID:
                success = [self uploadCurrentDoc];
                break;
            case PVO_SYNC_ACTION_UPLOAD_HVI_AND_CUST_RESP:
                success = [self uploadHVIAndCustResponsibilities];
                break;
            case PVO_SYNC_ACTION_UPLOAD_INVENTORIES:
                success = [self uploadInventories];
                break;
            case PVO_SYNC_ACTION_RECEIVE:
                [self receiveInventory];
                break;
            case PVO_SYNC_ACTION_DOWNLOAD_BOL:
                success = [self downloadBOL];
                break;
            case PVO_SYNC_ACTION_UPDATE_ACTUAL_DATES:
                success = [self updateActualDates];
                break;
            case PVO_SYNC_ACTION_GET_DATA:
                success = [self downloadExternalData];
                break;
            case PVO_SYNC_ACTION_GET_DATA_WITH_ORDER_REQUEST:
                success = [self downloadExternalDataWithRequest];
                break;
            case PVO_SYNC_ACTION_UPDATE_ORDER_STATUS:
                success = [self updateOrderStatus];
                break;
            default:
                break;
        }
        
        //        if(syncAction == PVO_SYNC_ACTION_DOWNLOAD)
        //            [self downloadSurvey];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_INVENTORY)
        //            success = [self uploadCurrentDoc];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_DEL_HVI)
        //            success = [self uploadCurrentDoc];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_PPI)
        //            success = [self uploadCurrentDoc];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_WEIGHT_TICKET)
        //            success = [self uploadCurrentDoc];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_PACK_SERVICES)
        //            success = [self uploadCurrentDoc];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_HVI_AND_CUST_RESP)
        //            success = [self uploadHVIAndCustResponsibilities];
        //        else if(syncAction == PVO_SYNC_ACTION_UPLOAD_INVENTORIES)
        //            success = [self uploadInventories];
        //        else if(syncAction == PVO_SYNC_ACTION_RECEIVE)
        //            [self receiveInventory];
        //        else if(syncAction == PVO_SYNC_ACTION_DOWNLOAD_BOL)
        //            success = [self downloadBOL];
        //        else if(syncAction == PVO_SYNC_ACTION_UPDATE_ACTUAL_DATES)
        //            success = [self updateActualDates];
        
    }
    @catch (NSException * e) {
        
        success = FALSE;
        [self updateProgress:[NSString stringWithFormat:@"Exception on Download Thread: %@", [e description]] withPercent:1.0];
        
    }
    _appDelegate.surveyDB.runningOnSeparateThread = NO;
    
exit:
    
//    [pool drain];
    
    if(success)
        [self completed];
    else
        [self error];
    
}

-(void)completed
{
    // OT 2582 - last saved date feature
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yy HH:mm a"];
    NSString *dateString = [formatter stringFromDate:now];
    [cust setLastSaveToServerDate:dateString];
    [del.surveyDB updateCustomer:cust];
    
    if (delegate != nil && [delegate respondsToSelector:@selector(syncCompleted:withSuccess:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate syncCompleted:self withSuccess:YES];
        });
    }
    else if (updateWindow != nil && [updateWindow respondsToSelector:completedCallback])
        [updateWindow performSelectorOnMainThread:completedCallback withObject:nil waitUntilDone:NO];
}

-(void)error
{
    if (delegate != nil && [delegate respondsToSelector:@selector(syncCompleted:withSuccess:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate syncCompleted:self withSuccess:NO];
        });
    }
    else if(updateWindow != nil && [updateWindow respondsToSelector:errorCallback])
        [updateWindow performSelectorOnMainThread:errorCallback withObject:nil waitUntilDone:NO];
}

-(void)updateProgress:(NSString*)updateString withPercent:(double)percent
{
    if(updateString == nil || [updateString length] == 0 || percent == 0)
        return;
    
    if (delegate != nil && [delegate respondsToSelector:@selector(syncProgressUpdate:withMessage:andPercentComplete:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate syncProgressUpdate:self withMessage:updateString andPercentComplete:percent];
        });
    }
    
    if (updateWindow != nil && [updateWindow respondsToSelector:updateCallback])
        [updateWindow performSelectorOnMainThread:updateCallback withObject:updateString waitUntilDone:NO];
}

-(void)resetProgressBar
{
    [self updateProgressBar:0.001 animated:NO];
}

-(void)updateProgressBar:(double)percent
{
    [self updateProgressBar:percent animated:YES];
}

-(void)updateProgressBar:(double)percent animated:(BOOL)animated
{//added this method for resetting the progress back to 0 when uploading images for items, then rooms, the locations
    if(percent == 0)
        return;
    
    if (delegate != nil && [delegate respondsToSelector:@selector(syncProgressUpdate:withMessage:andPercentComplete:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate syncProgressUpdate:self withMessage:NULL andPercentComplete:percent animated:animated];
        });
    }
    
}

-(BOOL)downloadExternalDataWithRequest
{
    SurveyCustomer *cust = [_appDelegate.surveyDB getCustomer:_appDelegate.customerID];
    self.downloadRequestType = cust.pricingMode;
    
    XMLWriter *ordRequest = [self getRequestXML];
    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
    requestParm.contents = ordRequest.file;
    
    NSMutableArray *parameterValues = [[NSMutableArray alloc] initWithObjects:requestParm, nil];
    [parameterValues addObjectsFromArray:self.parameterValues];
    self.parameterValues = parameterValues;
    
    NSMutableArray *parameterKeys = [[NSMutableArray alloc] initWithObjects:@"request", nil];
    [parameterKeys addObjectsFromArray:self.parameterKeys];
    self.parameterKeys = parameterKeys;
    
    return [self downloadExternalData];
}

-(BOOL)downloadExternalData
{
    BOOL success = TRUE;
    NSString *result = nil;
    NSDictionary *args = nil;
    
    req.functionName = @"GetPDFByRequest";
    
    args = [NSDictionary dictionaryWithObjects:self.parameterValues
                                       forKeys:self.parameterKeys];
    
    success = [req getData:&result withArguments:args needsDecoded:NO withSSL:ssl flushToFile:nil
                 withOrder:self.parameterKeys];
    
    
    self.resultString = result;
    
    return success;
}


-(BOOL)uploadHVIAndCustResponsibilities
{
#ifndef ATLASNET
    return NO;
#endif
    
    if ([_appDelegate.pricingDB vanline] != ATLAS)
        return NO;
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    SuccessParser *successParser = nil;
    
    NSString *result = nil;
    
    for(int i = 0; i < 2; i++)
    {
        if(i == 0)
        {
            req.functionName = @"UploadHighValueInventoryDocumentWithAgency";
            success = [self generateDocument:LOAD_HIGH_VALUE];
        }
        else if(i == 1)
        {
            req.functionName = @"UploadCustomerResponsibilitiesDocumentWithAgency";
            success = [self generateDocument:HVI_CUST_RESPONSIBILITIES];
        }
        
        if(!success)
            return FALSE;
        
        NSData *reportData = [[NSData alloc] initWithContentsOfFile:
                               [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]];
        
        NSDictionary *temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, _driverData.haulingAgent, orderNumber,
                                                                  [Base64 encode64WithData:reportData], nil]
                                                         forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"fileContents", nil]];
        
        success = [req getData:&result withArguments:temp needsDecoded:YES withSSL:ssl];
        
        parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
        successParser = [[SuccessParser alloc] init];
        
        parser.delegate = successParser;
        [parser parse];
        
        if(!successParser.success)
        {
            //error with message...
            [self updateProgress:successParser.errorString withPercent:1];
            return FALSE;
        }
    }
    
    [self updateProgress:[NSString stringWithFormat:@"Document Successfully Uploaded."] withPercent:1];
    
    return success;
}

-(BOOL)downloadBOL
{
#ifndef ATLASNET
    return NO;
#endif
    
    if ([_appDelegate.pricingDB vanline] != ATLAS)
        return NO;
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    SuccessParser *successParser = nil;
    
    NSString *result = nil;
    
    
    //    NSData *reportData = [[NSData alloc] initWithContentsOfFile:
    //                          [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]];
    //
    
    req.functionName = @"DownloadBOLByOrderNumber";
    
    BOOL showEstCharges = [additionalParamInfo boolValue];
    
    success = [req getData:&result
             withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, orderNumber, _driverData.haulingAgent,
                                                                showEstCharges ? @"false" : @"true", nil]
                                                       forKeys:[NSArray arrayWithObjects:@"driverNumber", @"orderNumber", @"agencyCode", @"showEstimatedCharges", nil]]
              needsDecoded:YES
                   withSSL:ssl
               flushToFile:[[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]];
    
    if(!success)
    {
        [self updateProgress:result withPercent:1];
        return FALSE;
    }
    
    
    //check the file to make sure it isnt an error...
    NSString *pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSDictionary *attribdict = [mgr attributesOfItemAtPath:pdfPath error:nil];
    
    if(attribdict != nil && [attribdict objectForKey:NSFileSize] != nil)
    {
        if([[attribdict objectForKey:NSFileSize] longLongValue] < (1024 * 10))
        {//less than one kb, check (prolly error string)
            NSString *results = [NSString stringWithContentsOfFile:pdfPath encoding:NSASCIIStringEncoding error:nil];
            
            //check to see if there is "PDF" in the header - if so, it is a file versus an error.
            
            if([[results substringToIndex:20] rangeOfString:@"PDF"].location == NSNotFound)
            {
                NSRange xml = [results rangeOfString:@"<?xml"];
                if(xml.location == NSNotFound)
                {
                    [self updateProgress:@"Unknown error receiving BOL" withPercent:1];
                    return FALSE;
                }
                
                parser = [[NSXMLParser alloc] initWithData:[[results substringFromIndex:xml.location] dataUsingEncoding:NSUTF8StringEncoding]];
                
                successParser = [[SuccessParser alloc] init];
                parser.delegate = successParser;
                [parser parse];
                
                if(!successParser.success)
                {
                    //error with message...
                    [self updateProgress:[successParser.errorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] withPercent:1];
                    return FALSE;
                }
            }
        }
    }
    
    
    //    [result release];
    
    return success;
}

-(BOOL)uploadCurrentDoc
{
    BOOL success = TRUE;
    NSString *result = nil;
    
    NSData *reportData = [[NSData alloc] initWithContentsOfFile:
                          [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]];
    
    NSDictionary *temp = nil;
    
    SurveyCustomer *cust = [_appDelegate.surveyDB getCustomer:_appDelegate.customerID];
    self.downloadRequestType = cust.pricingMode;
    
    if(![AppFunctionality isDemoOrder:self.orderNumber])
    {
        if ([_appDelegate.pricingDB vanline] == ATLAS)
        {
            if (syncAction == PVO_SYNC_ACTION_UPLOAD_DOCUMENT_WITH_REPORTTYPEID)
            {
                //New method to accept any report type without needing a device update to upload new docs everytime a new report is added to the pricing db. service will cast the reporttype id into a doc type and save as usual
                req.functionName = @"UploadDocumentWithAgencyForReportType";
                
                temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent,
                                                            orderNumber, [NSString stringWithFormat:@"%d",self.pvoReportID], [Base64 encode64WithData:reportData], nil]
                                                   forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"pvoReportTypeID", @"fileContents", nil]];
                
            }
            else if (syncAction == PVO_SYNC_ACTION_UPLOAD_BOL)
            {
                int pvoNavItemID = [self.additionalParamInfo intValue];
                //origin = 0, sit = 1, destination = 2
                int bolDocTypeID = pvoNavItemID == PVO_BOL_ORIGIN ? 0 : pvoNavItemID == PVO_BOL_SIT ? 1 : 2;
                
                ShipmentInfo *info = [_appDelegate.surveyDB getShipInfo:_appDelegate.customerID];
                req.functionName = @"UploadBOLDocumentWithBOLType";
                
                temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent,
                                                            orderNumber, [Base64 encode64WithData:reportData], @"false" /*info.isAtlasFastrac ? @"true" : @"false"*/, [NSNumber numberWithInt:bolDocTypeID], nil]
                                                   forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"fileContents", @"isFastrac", @"bolDocTypeID", nil]];
                
            }
            else if (syncAction == PVO_SYNC_ACTION_SYNC_CANADA)
            {
                req.functionName = @"UploadAtlasCanadaDocumentWithAgency";
                req.type = ATLAS_SYNC_CANADA;
                temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent,
                                                            orderNumber, [Base64 encode64WithData:reportData], [NSString stringWithFormat:@"%d",self.pvoReportID], nil]
                                                   forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"fileContents", @"docType", nil]];
                
            }
            else
            {
                if(syncAction == PVO_SYNC_ACTION_UPLOAD_INVENTORY)
                    req.functionName = @"UploadInventoryDocumentWithAgency";
                else if(syncAction == PVO_SYNC_ACTION_UPLOAD_DEL_HVI)
                    req.functionName = @"UploadHighValueInventoryDocumentWithAgency";
                else if(syncAction == PVO_SYNC_ACTION_UPLOAD_PPI)
                    req.functionName = @"UploadPPIDocumentWithAgency";
                else if(syncAction == PVO_SYNC_ACTION_UPLOAD_WEIGHT_TICKET)
                    req.functionName = @"UploadWeightTicketWithAgency";
                else if(syncAction == PVO_SYNC_ACTION_UPLOAD_PACK_SERVICES)
                    req.functionName = @"UploadPackServicesDocWithAgency";
                temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber, _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent,
                                                            orderNumber, [Base64 encode64WithData:reportData], nil]
                                                   forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"fileContents", nil]];
                
                
            }
            success = [req getData:&result withArguments:temp needsDecoded:YES];
        }
        else
        {
            XMLWriter *ordRequest = [self getRequestXML];
            WCFDataParam *requestParm = [[WCFDataParam alloc] init];
            requestParm.contents = ordRequest.file;
            
            req.functionName = @"UploadReportByRequest";
            
            temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:requestParm,
                                                        [NSString stringWithFormat:@"%d", pvoReportID], [Base64 encode64WithData:reportData], nil]
                                               forKeys:[NSArray arrayWithObjects:@"request", @"docType", @"reportData", nil]];
            
            success = [req getData:&result withArguments:temp needsDecoded:NO withSSL:ssl flushToFile:nil
                         withOrder:[NSArray arrayWithObjects:@"request", @"docType", @"reportData", nil]];
            
            SurveyCustomer *cust = [_appDelegate.surveyDB getCustomer:_appDelegate.customerID];
            if ([_appDelegate.pricingDB vanline] == ARPIN && cust.pricingMode == INTERSTATE)
            {
                if([result rangeOfString:[NSString stringWithFormat:@"<%@Result>", req.functionName]].location != NSNotFound &&
                   [result rangeOfString:[NSString stringWithFormat:@"</%@Result>", req.functionName]].location != NSNotFound)
                {
                    NSString *returnCode = [result substringWithRange:NSMakeRange([NSString stringWithFormat:@"<%@Result>", req.functionName].length,
                                                                                  [result rangeOfString:[NSString stringWithFormat:@"</%@Result>", req.functionName]].location -
                                                                                  [NSString stringWithFormat:@"<%@Result>", req.functionName].length)];
                    if(![returnCode isEqualToString:@"0"])
                    {
                        success = false;
                        //                        [result release];
                        result = [NSString stringWithFormat:@"Error returned from Report Upload: %@", returnCode];
                    }
                }
            }
            else if (!success && [result rangeOfString:@"Unable to load Order for Order Number provided."].location != NSNotFound)
            {
                //clean up error message for the device.  tell them they need to sync first.
                NSString *syncTitle = @"Save To Server";
#ifdef ATLASNET
                syncTitle = @"Save To Atlas";
#endif
                result = [result stringByAppendingFormat:@"  Please synchronize first by selecting \"%@\" from the Inventory screen.", syncTitle];
            }
        }
        
        if(!success)
        {
            //error with message...
            [self updateProgress:result withPercent:1];
        }
        else
        {
#ifdef ATLASNET
            NSXMLParser *parser = nil;
            SuccessParser *successParser = nil;
            
            //check for errors from the Atlas sync
            parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
            
            successParser = [[SuccessParser alloc] init];
            parser.delegate = successParser;
            [parser parse];
            
            if(!successParser.success)
            {
                //error with message...
                [self updateProgress:successParser.errorString withPercent:1];
                [successParser release];
                return FALSE;
            }
            
            [parser release];
            [successParser release];
            
            [self updateProgress:[NSString stringWithFormat:@"Document Successfully Uploaded."] withPercent:1];
#else
            //success
            [self updateProgress:@"Document Uploaded Successfully!" withPercent:1];
#endif
        }
        
        //        [result release];
        
    }
    
    return success;
}

-(BOOL)downloadPreShipCheckList
{
    //username
    if ([_driverData.crmUsername length] == 0 || [_driverData.crmPassword length] == 0 || [[self getReloCRMSyncURL] length] == 0)
    {
        return false;
    }
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOPreShipChecklistParser *checkListParser = nil;
    NSString *result = nil;
    
    if (_driverData.haulingAgent == nil || [_driverData.haulingAgent isEqualToString:@""])
        return NO;
    
    XMLWriter *reloSettings = [self getReloCRMSettingsXML];
    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
    requestParm.contents = reloSettings.file;
    
    req.functionName = @"GetPreShipChecklistWithAgencyCode";
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                              requestParm,
                                                              (_driverData == nil || _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent),
                                                              nil]
                                                     forKeys:[NSArray arrayWithObjects:@"reloSettings", @"agencyCode", nil]];
    
    
    success = [req getData:&result
             withArguments:dict
              needsDecoded:YES
                   withSSL:ssl
               flushToFile:nil
                 withOrder:[NSArray arrayWithObjects:@"reloSettings", @"agencyCode", nil]] ;
    
    //    [requestParm release];
    
    if([self isCancelled])
        return FALSE;
    
    if([result rangeOfString:@"Sync Error:"].location == 0)
    {
        //error with message...
        [self updateProgress:result withPercent:1];
        //        [result release];
        return FALSE;
    }
    
    //Create preshipchecklist parser and pull checklist items, save to db
    // we will just wipe out all the old checklist items PER AGENCY then save new ones
    //parse the survey, and demo data
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    checkListParser = [[PVOPreShipChecklistParser alloc] init];
    parser.delegate = checkListParser;
    [parser parse];
    
    //save all of the checklist items to the db, wipes out the old items per hauling agent code
    [_appDelegate.surveyDB savePVOVehicleCheckListForAgency:checkListParser.checkListItems withAgencyCode:_driverData.haulingAgent];
    
    return success;
    
}

-(BOOL)downloadSurvey
{
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    SurveyDownloadXMLParser *downloadParser = nil;
    
    NSString *result = nil;
    
    //check for a demo request...
    if(self.downloadRequestType == 0 && [AppFunctionality isDemoOrder:self.orderNumber])
    {
        result = [[NSString alloc] initWithContentsOfFile:[AppFunctionality getDemoOrderFilePath:self.orderNumber]
                                                 encoding:NSASCIIStringEncoding
                                                    error:nil];
    }
    
    //no demo found
    if(result == nil)
    {
        if ([_appDelegate.pricingDB vanline] == ATLAS)
        {
            req.functionName = @"DownloadSurveyByOrderNumberWithAgency";
            success = [req getData:&result
                     withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber == nil ? @"" : _driverData.driverNumber,
                                                                        orderNumber == nil ? @"" : orderNumber,
                                                                        _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"driverNumber", @"orderNumber", @"agencyCode", nil]]
                      needsDecoded:YES
                           withSSL:ssl
                       flushToFile:nil
                         withOrder:[NSArray arrayWithObjects:@"driverNumber", @"orderNumber", @"agencyCode", nil]] ;
        }
        else
        {
            
            
            req.functionName = @"GetIGCSyncOrderByRequest";
            
            XMLWriter *writer = [self getRequestXML];
            
            WCFDataParam *parm = [[WCFDataParam alloc] init];
            parm.contents = writer.file;
            
            
            NSLog(@"REQ.ServerAddress: %@", [NSString stringWithFormat:@"%@", req.serverAddress]);
            NSLog(@"REQ.FunctionName: %@", [NSString stringWithFormat:@"%@", req.functionName]);
            NSLog(@"REQ.RequestXML: %@", [NSString stringWithFormat:@"%@", writer.file]);
            
            
            success = [req getData:&result
                     withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                        parm,
                                                                        nil]
                                                               forKeys:[NSArray arrayWithObjects:@"request", nil]]
                      needsDecoded:YES withSSL:ssl
                       flushToFile:nil
                         withOrder:[NSArray arrayWithObjects:@"request", nil]];
        }
    }
    
    if([self isCancelled])
        return FALSE;
    
    NSLog(@"REQ.result: %@", result);
    
    if([result rangeOfString:@"Sync Error:"].location == 0)
    {
        //error with message...
        [self updateProgress:result withPercent:1];
        //        [result release];
        return FALSE;
    }
    
    //parse the survey, and demo data
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    downloadParser = [[SurveyDownloadXMLParser alloc] initWithAppDelegate:_appDelegate];
    downloadParser.atlasSync = ([_appDelegate.pricingDB vanline] == ATLAS);
    parser.delegate = downloadParser;
    [parser parse];
    
    //parse the inventory data.
    PVOInventoryParser *inventoryParser = nil;
#ifndef ATLASNET
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    inventoryParser = [[PVOInventoryParser alloc] init];
    parser.delegate = inventoryParser;
    [parser parse];
#endif
    
#if defined(ATLASNET)
    PVOSTGBOLParser *stgBolParser = [[PVOSTGBOLParser alloc] init];
    [stgBolParser parseXml:result];
#endif
    
    if([self isCancelled])
        return FALSE;
    
    if(downloadParser.error)
    {
        //error with message...
        [self updateProgress:downloadParser.errorString withPercent:1];
        return FALSE;
    }
    
    //no survey records.
    if(downloadParser.empty)
    {
        [self updateProgress:@"Order Number not found!" withPercent:1];
        return FALSE;
    }
    
    if([self isCancelled])
        return FALSE;
    
    downloadParser.info.orderNumber = orderNumber;
    
#ifdef ATLASNET
    //flag the first Phone number as the Primary
    if (downloadParser.locations != nil && [downloadParser.locations count] > 0)
    {
        for (int i=0;i<[downloadParser.locations count];i++)
        {
            SurveyLocation *loc = [downloadParser.locations objectAtIndex:i];
            if (loc != nil && loc.locationType != -1 && loc.isOrigin)
            {
                if (loc.phones != nil && [loc.phones count] > 0)
                {
                    downloadParser.primaryPhone = [loc.phones objectAtIndex:0];
                    [loc.phones removeObject:downloadParser.primaryPhone];
                    break;
                }
            }
        }
    }
#endif
    
    if (mergeCustomer)
    {
        [SyncGlobals mergeCustomerToDB:downloadParser appDelegate:_appDelegate];
    }
    else
    {
        [SyncGlobals flushCustomerToDB:downloadParser appDelegate:_appDelegate];
    }
    
#if defined(ATLASNET)
    if ([stgBolParser.stgBolXml length] > 0)
    {
        NSInteger customerID = downloadParser.customer.custID;
        [stgBolParser writeXmlToFile:customerID];
    }
#endif
    
#ifdef ATLASNET
    if ([AppFunctionality getPvoReceiveType] & PVO_RECEIVE_ON_DOWNLOAD)
        [self receiveInventory:YES];
#endif
    
    // save or update Inventory data
    PVOInventory *invData = [_appDelegate.surveyDB getPVOData:downloadParser.customer.custID];
    
#ifdef ATLASNET
    invData.loadType = self.loadType;
    invData.mproWeight = self.mproWeight;
    invData.sproWeight = self.sproWeight;
    //consweight here?
#else
    invData.loadType = inventoryParser.loadType;
    invData.mproWeight = inventoryParser.mproWeight;
    invData.sproWeight = inventoryParser.sproWeight;
    invData.consWeight = inventoryParser.consWeight;
#endif
    
    
    invData.lockLoadType = [AppFunctionality lockInventoryLoadTypeOnDownload:downloadParser.customer.pricingMode];
    [_appDelegate.surveyDB updatePVOData:invData];
    
    
    if ([AppFunctionality getPvoReceiveType] & PVO_RECEIVE_ON_DOWNLOAD)
    {
#ifdef ATLASNET
        if (self.receivedType != PACKER_INVENTORY || ![AppFunctionality disablePackersInventory])
        {
            if (self.inventoryItemEntries != nil && self.inventoryItemEntries.count > 0)
            {
                [_appDelegate.surveyDB savePVOReceivableItems:self.inventoryItemEntries forCustomer:downloadParser.customer.custID ignoreIfInventoried:mergeCustomer];
                [_appDelegate.surveyDB setPVOReceivedItemsType:self.receivedType forCustomer:downloadParser.customer.custID];
                [_appDelegate.surveyDB setPVOReceivedItemsUnloadType:self.receivedUnloadType forCustomer:downloadParser.customer.custID];
            }
        }
#else
        if (inventoryParser.receivedType != PACKER_INVENTORY || ![AppFunctionality disablePackersInventory])
        {
            //per defect 91, save with merge and new ... save the inventory too
            if(inventoryParser.entries != nil && inventoryParser.entries.count > 0)
            {
                [_appDelegate.surveyDB savePVOReceivableItems:inventoryParser.entries forCustomer:downloadParser.customer.custID ignoreIfInventoried:mergeCustomer];
                if (inventoryParser.receivedFromType > 0 && inventoryParser.receivedFromType != inventoryParser.receivedType)
                    [_appDelegate.surveyDB setPVOReceivedItemsType:inventoryParser.receivedFromType forCustomer:downloadParser.customer.custID];
                else
                    [_appDelegate.surveyDB setPVOReceivedItemsType:inventoryParser.receivedType forCustomer:downloadParser.customer.custID];
                [_appDelegate.surveyDB setPVOReceivedItemsUnloadType:inventoryParser.receivedUnloadType forCustomer:downloadParser.customer.custID];
            }
        }
#endif
    }
    
    
    //download any images...
    for (SurveyedItem *si in downloadParser.csParser.entries) {
        if(si.imageID > 0)
        {
            [self downloadMMItemImages:si.imageID forSurveyedItemID:si.siID];
        }
    }
    
    for (id key in [downloadParser.csParser.roomImages allKeys]) {
        [self downloadMMRoomImages:[[downloadParser.csParser.roomImages objectForKey:key] intValue]
                         forRoomID:[key intValue]];
    }
    
    [self downloadMMLocationImages];
    
    //download the premove checklist for auto inventory. Per tony we're doing this in the order download, but its a separate call because we'll probably separate this out from order download in the future
    //[self downloadPreShipCheckList];
    
    [self updateProgress:[NSString stringWithFormat:@"Downloaded Customer: %@, %@",
                          downloadParser.customer.lastName == nil ? @"" : downloadParser.customer.lastName,
                          downloadParser.customer.firstName == nil ? @"" : downloadParser.customer.firstName] withPercent:1];
    
    //    [result release];
    
    return success;
}

-(BOOL)generateDocument:(int)pvoDocID
{
    WebSyncRequest *reportReq = [[WebSyncRequest alloc] init];
    reportReq.type = WEB_REPORTS;
    reportReq.functionName = @"GetPVOReport";
//    reportReq.serverAddress = @"print.moverdocs.com";
    reportReq.serverAddress = @"homesafe-docs.movehq.com";

    reportReq.pitsDir = @"PVOBeta";
    
    if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"md:"].location != NSNotFound)
    {
        NSRange addpre = [[Prefs betaPassword] rangeOfString:@"md:"];
        reportReq.serverAddress = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
        addpre = [reportReq.serverAddress rangeOfString:@" "];
        if (addpre.location != NSNotFound)
            reportReq.serverAddress = [reportReq.serverAddress substringToIndex:addpre.location];
    }
    
    NSString *dest;
    ReportOption *ro = nil;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"%d", [_appDelegate.pricingDB vanline]] forKey:@"vanLineId"];
    [dict setObject:[NSString stringWithFormat:@"%d", pvoDocID] forKey:@"reportID"];
    if (([Prefs reportsPassword] == nil || [[Prefs reportsPassword] length] == 0) && [AppFunctionality defaultReportingServiceCustomReportPass] != nil)
        [dict setObject:[AppFunctionality defaultReportingServiceCustomReportPass] forKey:@"customReportsPassword"];
    else
        [dict setObject:[Prefs reportsPassword] == nil ? @"" : [Prefs reportsPassword] forKey:@"customReportsPassword"];
    if([reportReq getData:&dest withArguments:dict needsDecoded:YES withSSL:YES])
    {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[dest dataUsingEncoding:NSUTF8StringEncoding]];
        ReportOptionParser *xmlParser = [[ReportOptionParser alloc] init];
        parser.delegate = xmlParser;
        [parser parse];
        
        //now I have the option, generate the report...
        if([xmlParser.entries count] > 0)
        {
            ro = [[ReportOption alloc] init];
            ro.reportID = [[xmlParser.entries objectAtIndex:0] reportID];
            ro.reportLocation = xmlParser.address;
        }
        else
        {
            [self updateProgress:@"No report option" withPercent:1];
            return FALSE;
        }
        
    }
    else
    {
        [self updateProgress:[NSString stringWithFormat:@"Report Option Error: %@", dest] withPercent:1];
        return FALSE;
    }
    
    if(ro != nil)
    {
        //start the thread on the operation queue
        GetReport *reportObject = [[GetReport alloc] init];
        reportObject.emailReport = FALSE;
        
        reportObject.option = ro;
        
        [reportObject main];
        if(!reportObject.success)
            [self updateProgress:[NSString stringWithFormat:@"GetReport Error: %@", reportObject.errorMessage] withPercent:1];
        
        return reportObject.success;
    }
    else
    {
        [self updateProgress:[NSString stringWithFormat:@"Report Option Error: %@", dest] withPercent:1];
        return FALSE;
    }
    
    return TRUE;
    
}

-(BOOL)uploadInventories
{
    //incoming is A[shipid],[suid]
    BOOL success = TRUE;
    
    //    [self updateProgress:@"Beginning Inventory Upload..." withPercent:1];
    
    NSMutableArray *custs = [_appDelegate.surveyDB getCustomerList:nil];
    CustomerListItem *item;
    XMLWriter *writer;
    NSString *result;
    int origDelCustID = _appDelegate.customerID;
    
    int vanlineID = [_appDelegate.pricingDB vanline];
    
    for(int i = 0 ; i< [custs count]; i++)
    {
        item = [custs objectAtIndex:i];
        SurveyCustomerSync *sync = [_appDelegate.surveyDB getCustomerSync:item.custID];
        if(sync.syncToPVO)
        {
            if([self isCancelled])
            {
                success = FALSE;
                break;
            }
            
            _appDelegate.customerID = item.custID;
            
            //check for demo...
            SurveyCustomer *cust = [_appDelegate.surveyDB getCustomer:item.custID];
            ShipmentInfo *info = [_appDelegate.surveyDB getShipInfo:_appDelegate.customerID];
            BOOL demo = FALSE;
            if(cust.pricingMode == INTERSTATE)
                demo = [AppFunctionality isDemoOrder:info.orderNumber];
            
            if(demo)
            {
                [NSThread sleepForTimeInterval:2.]; //wait two seconds
            }
            else
            {
                writer = [SyncGlobals buildCustomerXML:item.custID isAtlas:(vanlineID == ATLAS)];
                
                if (vanlineID == ATLAS)
                {
                    NSDictionary *dict = [NSDictionary dictionaryWithObjects:
                                          [NSArray arrayWithObjects:
                                           (_driverData.driverNumber == nil ? @"" : _driverData.driverNumber),
                                           [Base64 encode64:writer.file], nil]
                                                                     forKeys:
                                          [NSArray arrayWithObjects:@"driverNumber", @"message", nil]];
                    
                    req.functionName = @"UploadInventory";
                    //send the post request...
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil];
                    
                    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
                    SuccessParser *failParser = [[SuccessParser alloc] init];
                    parser.delegate = failParser;
                    [parser parse];
                    
                    success = failParser.success;
                    
                    @try {
                        if(!success)
                        {
                            NSString *err = [NSString stringWithFormat:@"%@ failed to upload. Reason: %@", item.name, failParser.errorString];
                            NSLog(@"Error in Atlas uploadInventories: %@", err);
                            [self updateProgress:err withPercent:1];
                            //set sync to falce, per defect 208
                            sync.syncToPVO = FALSE;
                            [_appDelegate.surveyDB updateCustomerSync:sync];
                            //                            [result release];
                            break;
                        }
                    }
                    @finally {
                        
                    }
                }
                else
                {
                    XMLWriter *reloSettings = [self getReloCRMSettingsXML];
                    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
                    requestParm.contents = reloSettings.file;
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                              requestParm,
                                                                              [Base64 encode64:writer.file],
                                                                              (_driverData == nil || _driverData.driverNumber == nil ? @"" : _driverData.driverNumber),
                                                                              [NSString stringWithFormat:@"%d", [_appDelegate.pricingDB vanline]],
                                                                              (_driverData == nil || _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent),
                                                                              nil]
                                                                     forKeys:[NSArray arrayWithObjects:@"reloSettings", @"order", @"driverNumber", @"carrierID", @"agencyCode", nil]];
                    
                    req.functionName = @"SaveIGCSyncOrderWithReloCRMSettings";
                    
                    //send the post request...
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"reloSettings", @"order", @"driverNumber", @"carrierID", @"agencyCode", nil]];
                    
                    
                    if(!success)
                    {
                        [self updateProgress:[NSString stringWithFormat:@"%@ failed to upload. Reason: %@", item.name, result] withPercent:1];
                        //set sync to falce, per defect 208
                        sync.syncToPVO = FALSE;
                        [_appDelegate.surveyDB updateCustomerSync:sync];
                        //                        [result release];
                        break;
                    }
                }
                
                //upload photos for this customer.
                if (uploadPhotosWithInventory)
                {
                    success = [self uploadPhotos:item.custID];
                    if(!success)
                    {
                        //set sync to falce, per defect 208
                        sync.syncToPVO = FALSE;
                        [_appDelegate.surveyDB updateCustomerSync:sync];
                        break;
                    }
                    
                }
            }
            
            XMLWriter *ordRequest = [self getRequestXML];
            WCFDataParam *requestParm = [[WCFDataParam alloc] init];
            requestParm.contents = ordRequest.file;
            
            NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                      requestParm,
                                                                      nil]
                                                             forKeys:[NSArray arrayWithObjects:@"request", nil]];
            
            req.functionName = @"ProcessInventoryForOrder";
            //send the post request...
            success = [req getData:&result
                     withArguments:dict
                      needsDecoded:YES
                           withSSL:ssl
                       flushToFile:nil
                         withOrder:[NSArray arrayWithObjects:@"request", nil]];
            
            if(!success)
            {
                [self updateProgress:[NSString stringWithFormat:@"%@ failed to upload. Reason: %@", item.name, result] withPercent:1];
                //set sync to falce, per defect 208
                sync.syncToPVO = FALSE;
                [_appDelegate.surveyDB updateCustomerSync:sync];
                //                        [result release];
                break;
            }
            
            if ([[ShipmentInfo getStatusString:info.status] isEqualToString:@""])
            {
                XMLWriter *settings = [self getStatusUpdateSettingsXML];
                WCFDataParam *requestParm2 = [[WCFDataParam alloc] init];
                requestParm2.contents = settings.file;
                
                NSDictionary* dict2 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                          orderNumber, [ShipmentInfo getStatusString:info.status], requestParm2, nil]
                forKeys:[NSArray arrayWithObjects:@"orderNumber", @"orderStatus", @"settings", nil]];
                
                
                req.functionName = @"UpdateOrderStatus";
                
                success = [req getData:&result
                withArguments:dict2
                 needsDecoded:YES
                      withSSL:ssl
                  flushToFile:nil];
            }
            
            
            [self updateProgress:[[NSString alloc] initWithFormat:@"%@ uploaded successfully.", item.name]
                     withPercent:1];
            
            sync.syncToPVO = FALSE;
            [_appDelegate.surveyDB updateCustomerSync:sync];
        }
    }
    
    _appDelegate.customerID = origDelCustID;
        
    return success;
}

-(BOOL)updateOrderStatus
{
    BOOL success = TRUE;
    NSString* result;
    
    XMLWriter *reloSettings = [self getStatusUpdateSettingsXML];
    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
    requestParm.contents = reloSettings.file;
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                              orderNumber, _orderStatus,
             requestParm,
             nil]
    forKeys:[NSArray arrayWithObjects:@"orderNumber", @"orderStatus", @"settings", nil]];
    
    
    req.functionName = @"UpdateOrderStatus";
    
    success = [req getData:&result
    withArguments:dict
     needsDecoded:YES
          withSSL:ssl
      flushToFile:nil];
    
    
    // We're not parsing anything. For demo we will not display error messages.
    
    return success;
}

-(BOOL)uploadPhotos:(int)custID
{
    BOOL success = TRUE;
    NSString *result;
    //first send the notification message.
    //get all photos
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //    SurveyImage *image;
    //    UIImage *img;
    //    NSData *imgData;
    // NSString *fullPath;
    // PVOItemDetail *pvoitem;
    
    SurveyCustomer *cust = [_appDelegate.surveyDB getCustomer:custID];
    self.downloadRequestType = cust.pricingMode;
    
    self.orderNumber = [_appDelegate.surveyDB getShipInfo:custID].orderNumber;
    
    XMLWriter *ordRequest = [self getRequestXML];
    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
    requestParm.contents = ordRequest.file;
    
    ///upload item photos first
#ifdef ATLASNET
    req.functionName = @"UploadImageForInventoryItemByInterstateRegNum";
#else
    req.functionName = @"UploadImageForInventoryItemByRequest";
#endif
    
    double calculatedProgress = 0, totalImagesToUpload = 0, currentProgress = 0;
    NSArray *photoTypes = @[@IMG_PVO_ITEMS, @IMG_PVO_DESTINATION_ITEMS];
    
    NSArray *images = [_appDelegate.surveyDB getImagesList:custID withPhotoTypes:photoTypes withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
    if([images count] > 0)
    {
        [self resetProgressBar];
        
        //progress bar works better when variables are stored as a double to calculate percent
        totalImagesToUpload = [images count];

        //upload the photos
        for(int i = 0; i < [images count]; i++)
        {
            @autoreleasepool {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                SurveyImage *image = [images objectAtIndex:i];
                NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                if([fileManager fileExistsAtPath:fullPath])
                {
                    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                    NSData *imgData = [PVOSync getResizedPhotoData:img];

                    //get pvoiteminfo
                    PVOItemDetail *pvoitem = [_appDelegate.surveyDB getPVOItem:image.subID];
#ifdef ATLASNET
                    [dict setValue:self.orderNumber forKey:@"interstateRegNum"];
#else
                    [dict setValue:requestParm forKey:@"request"];
#endif
                    [dict setValue:[pvoitem displayInventoryNumber] forKey:@"barcode"];
                    [dict setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                    [dict setValue:[Base64 encode64WithData:imgData] forKey:@"imageDetails"];
                    
                    
#ifdef ATLASNET
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"interstateRegNum", @"barcode", @"fileName", @"imageDetails", nil]];
#else
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"request", @"barcode", @"fileName", @"imageDetails", nil]];
#endif
                   
                    if(!success)
                    {
                        [self updateProgress:result withPercent:1];
                        //                    [result release];
                        break;
                    }
                    else
                    {
                        currentProgress = i + 1;
                        calculatedProgress = currentProgress / totalImagesToUpload;
                    }
                    
                    [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Item %@ Image ID %d posted...", [pvoitem displayInventoryNumber], image.imageID]
                             withPercent:calculatedProgress];
                }
            }
        }
    }
    
    ///now upload room photos
#ifdef ATLASNET
    req.functionName = @"UploadImageForRoomByInterstateRegNum";
#else
    req.functionName = @"UploadImageForRoomByRequest";
#endif
    
    NSArray *roomTypes = @[@IMG_PVO_ROOMS, @IMG_PVO_DESTINATION_ROOMS];
    
    images = [_appDelegate.surveyDB getImagesList:custID withPhotoTypes:roomTypes withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
    PVORoomConditions *conditions;
    if([images count] > 0)
    {
        //progress doesn't change when you send a zero, just starting it off at .001
        [self resetProgressBar];
        
        //progress bar works better when variables are stored as a double to calculate percent
        totalImagesToUpload = [images count];
        
        //upload the photos
        for(int i = 0; i < [images count]; i++)
        {
            @autoreleasepool {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                SurveyImage *image = [images objectAtIndex:i];
                NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                if([fileManager fileExistsAtPath:fullPath])
                {
                    int photoType = image.photoType;
                    if (photoType == IMG_ROOMS || photoType == IMG_PVO_ROOMS) {
                        conditions = [_appDelegate.surveyDB getPVORoomConditions:image.subID];
                    } else if (image.photoType == IMG_PVO_DESTINATION_ROOMS) {
                        conditions = [_appDelegate.surveyDB getPVODestinationRoomConditions:image.subID];
                    }
                    
                    Room *r = [_appDelegate.surveyDB getRoom:conditions.roomID];
                    
                    if (![_appDelegate.surveyDB roomHasPVOInventoryItems:r.roomID] && image.photoType != IMG_PVO_DESTINATION_ROOMS)
                        continue; //skip if room has no items
                    
                    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                    NSData *imgData = [PVOSync getResizedPhotoData:img];
                    
#ifdef ATLASNET
                    [dict setValue:self.orderNumber forKey:@"interstateRegNum"];
#else
                    [dict setValue:requestParm forKey:@"request"];
#endif
                    [dict setValue:[r roomName] forKey:@"roomName"];
                    [dict setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                    [dict setValue:[Base64 encode64WithData:imgData] forKey:@"imageDetails"];
#ifdef ATLASNET
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"interstateRegNum", @"roomName", @"fileName", @"imageDetails", nil]];
#else
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"request", @"roomName", @"fileName", @"imageDetails", nil]];
#endif
                    
                    if(!success)
                    {
                        [self updateProgress:result withPercent:1];
                        break;
                    }
                    else
                    {
                        currentProgress = i + 1;
                        calculatedProgress = currentProgress / totalImagesToUpload;
                        
                        [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Room %@ Image ID %d posted...", [[_appDelegate.surveyDB getRoom:conditions.roomID] roomName], image.imageID]
                                 withPercent:calculatedProgress];
                    }
                }
            }
        }
    }
    ///now upload unload room photos
    
#ifdef ATLASNET
    //req.functionName = @"UploadImageForUnloadRoomByInterstateRegNum";
#else
    req.functionName = @"UploadImageForUnloadRoomByRequest";
    
    images = [_appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_PVO_DESTINATION_ROOMS withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
    PVORoomConditions *unloadConditions;
    if([images count] > 0)
    {
        //progress doesn't change when you send a zero, just starting it off at .001
        [self resetProgressBar];
        
        //progress bar works better when variables are stored as a double to calculate percent
        totalImagesToUpload = [images count];
        
        //upload the photos
        for(int i = 0; i < [images count]; i++)
        {
            @autoreleasepool {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                SurveyImage *image = [images objectAtIndex:i];
                NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                if([fileManager fileExistsAtPath:fullPath])
                {
                    unloadConditions = [_appDelegate.surveyDB getPVODestinationRoomConditions:image.subID];
                    
                    Room *r = [_appDelegate.surveyDB getRoom:unloadConditions.roomID];
                    
                    //if (![del.surveyDB roomHasPVOInventoryItems:r.roomID])
                    //  continue; //skip if room has no items
                    
                    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                    NSData *imgData = [PVOSync getResizedPhotoData:img];
                    
#ifdef ATLASNET
                    [dict setValue:self.orderNumber forKey:@"interstateRegNum"];
#else
                    [dict setValue:requestParm forKey:@"request"];
#endif
                    [dict setValue:[r roomName] forKey:@"roomName"];
                    [dict setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                    [dict setValue:[Base64 encode64WithData:imgData] forKey:@"imageDetails"];
                    
#ifdef ATLASNET
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"interstateRegNum", @"roomName", @"fileName", @"imageDetails", nil]];
#else
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"request", @"roomName", @"fileName", @"imageDetails", nil]];
#endif
                    
                    if(!success)
                    {
                        [self updateProgress:result withPercent:1];
                        //                    [result release];
                        break;
                    }
                    else
                    {
                        currentProgress = i + 1;
                        calculatedProgress = currentProgress / totalImagesToUpload;
                        
                        [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Room %@ Image ID %d posted...", [[_appDelegate.surveyDB getRoom:unloadConditions.roomID] roomName], image.imageID]
                                 withPercent:calculatedProgress];
                    }
                }
            }
        }
    }
#endif
    
    ///now upload location photos
#ifdef ATLASNET
    req.functionName = @"UploadImageForLocationByInterstateRegNum";
#else
    req.functionName = @"UploadImageForLocationByRequest";
#endif
    images = [_appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_LOCATIONS withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
    SurveyLocation *loc = nil;
    if([images count] > 0)
    {
        //progress doesn't change when you send a zero, just starting it off at .001
        [self resetProgressBar];
        
        //progress bar works better when variables are stored as a double to calculate percent
        totalImagesToUpload = [images count];
        
        //upload the photos
        for(int i = 0; i < [images count]; i++)
        {
            @autoreleasepool {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                SurveyImage *image = [images objectAtIndex:i];
                NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                if([fileManager fileExistsAtPath:fullPath])
                {
                    
                    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                    NSData *imgData = [PVOSync getResizedPhotoData:img];
                    
                    NSString *locName = @"Origin";
                    if(image.subID == ORIGIN_LOCATION_ID)
                        [dict setValue:@"Origin" forKey:@"locType"];
                    else if(image.subID == DESTINATION_LOCATION_ID)
                    {
                        [dict setValue:@"Destination" forKey:@"locType"];
                        locName = @"Destination";
                    }
                    else
                    {
                        loc = [_appDelegate.surveyDB getCustomerLocation:image.subID]; //uses locationID
                        if (loc.isOrigin)
                            [dict setValue:@"OriginExtraStop" forKey:@"locType"];
                        else
                            [dict setValue:@"DestinationExtraStop" forKey:@"locType"];
                        locName = @"Extra Stop";
                    }
#ifdef ATLASNET
                    [dict setValue:self.orderNumber forKey:@"interstateRegNum"];
#else
                    [dict setValue:requestParm forKey:@"request"];
#endif
                    [dict setValue:[NSString stringWithFormat:@"%d", (loc == nil ? 0 : loc.sequence)] forKey:@"sequence"];
                    [dict setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                    [dict setValue:[Base64 encode64WithData:imgData] forKey:@"imageDetails"];
                    
#ifdef ATLASNET
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"interstateRegNum", @"locType", @"sequence", @"fileName", @"imageDetails", nil]];
#else
                    success = [req getData:&result
                             withArguments:dict
                              needsDecoded:YES
                                   withSSL:ssl
                               flushToFile:nil
                                 withOrder:[NSArray arrayWithObjects:@"request", @"locType", @"sequence", @"fileName", @"imageDetails", nil]];
#endif
                    
                    if(!success)
                    {
                        [self updateProgress:result withPercent:1];
                        //                    [result release];
                        break;
                    }
                    else
                    {
                        currentProgress = i + 1;
                        calculatedProgress = currentProgress / totalImagesToUpload;
                        
                        [self updateProgress:[NSString stringWithFormat:@"%@ Location Image ID %d posted...", locName, image.imageID]
                                 withPercent:calculatedProgress];
                    }
                }
            }
        }
    }
        
    if ([AppFunctionality disableWeightTickets])
    {
        return success;
    }
    
    
    ///now upload po d tickets - atlasnet has a separate upload for them, not part of sync process
    req.functionName = @"UploadWeightTicketByRequest";
    
    NSArray *tickets = [_appDelegate.surveyDB getPVOWeightTickets:custID];
    for (PVOWeightTicket *ticket in tickets) {
        
        images = [_appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_PVO_WEIGHT_TICKET withSubID:ticket.weightTicketID
                                         loadAllItems:FALSE loadAllForType:FALSE];
        if([images count] > 0)
        {
            //progress doesn't change when you send a zero, just starting it off at .001
            [self resetProgressBar];
            
            //progress bar works better when variables are stored as a double to calculate percent
            totalImagesToUpload = [images count];
            
            //upload the photos
            for(int i = 0; i < [images count]; i++)
            {
                @autoreleasepool {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                    SurveyImage *image = [images objectAtIndex:i];
                    NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                    if([fileManager fileExistsAtPath:fullPath])
                    {
                        UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                        NSData *imgData = [PVOSync getResizedPhotoData:img];
                        
                        [dict setValue:requestParm forKey:@"request"];
                        
                        [dict setValue:[Base64 encode64:[ticket xmlFile].file] forKey:@"weightTicketData"];
                        [dict setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                        [dict setValue:[Base64 encode64WithData:imgData] forKey:@"imageDetails"];
                        success = [req getData:&result
                                 withArguments:dict
                                  needsDecoded:YES
                                       withSSL:ssl
                                   flushToFile:nil
                                     withOrder:[NSArray arrayWithObjects:@"request", @"weightTicketData", @"fileName", @"imageDetails", nil]];
                        
                        if(!success)
                        {
                            [self updateProgress:result withPercent:1];
                            //                        [result release];
                            break;
                        }
                        else
                        {
                            currentProgress = i + 1;
                            calculatedProgress = currentProgress / totalImagesToUpload;
                            
                            [self updateProgress:[NSString stringWithFormat:@"Weight ticket %@ posted...", ticket.description]
                                     withPercent:calculatedProgress];
                        }
                    }
                }
            }
        }
    }
    return success;
}


+(NSData*)getResizedPhotoData:(UIImage*)img
{
    NSData *data;
    //resize o 640 x 480
    int newX = 0, newY = 0;
    if(img.size.width > 640 || img.size.height > 640)
    {
        if(img.size.width > img.size.height)
        {
            newX = 640;
            newY = img.size.height * (newX / img.size.width);
        }
        else
        {
            newY = 640;
            newX = img.size.width * (newY / img.size.height);
        }
        UIImage *newimg = [SurveyAppDelegate resizeImage:img withNewSize:CGSizeMake(newX, newY)];
        data = UIImageJPEGRepresentation(newimg, 1.0f);
    }
    else
        data = UIImageJPEGRepresentation(img, 1.0f);
    
    return data;
}


-(BOOL)downloadMMItemImages:(int)imageID forSurveyedItemID:(int)siID
{
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOImageParser *imageParser = nil;
    
    NSString *result = nil;
    
    imageParser = [[PVOImageParser alloc] init];
    
    if ([_appDelegate.pricingDB vanline] == ATLAS)
    {
        req.functionName = @"DownloadSurveyImages";
        success = [req getData:&result
                 withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", imageID],
                                                                    orderNumber, @"SURVEY_ITEM", nil]
                                                           forKeys:[NSArray arrayWithObjects:@"relatedRecordID",
                                                                    @"orderNumber", @"type", nil]]
                  needsDecoded:YES withSSL:ssl
                   flushToFile:nil];
        imageParser.isWCF = NO;
    }
    else
    {
        req.functionName = @"GetIGCSyncItemImages";
        success = [req getData:&result
                 withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:orderNumber, [NSString stringWithFormat:@"%d", imageID], _driverData.haulingAgent, self.downloadRequestType == 0 ? @"true" : @"false", nil]
                                                           forKeys:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]]
                  needsDecoded:NO withSSL:ssl
                   flushToFile:nil
                     withOrder:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]];
    }
    
    if(!success)
    {
        [self updateProgress:result withPercent:1];
        return FALSE;
    }
    
    if([self isCancelled])
        return FALSE;
    
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    imageParser.surveyedItemID = siID;
    
    parser.delegate = imageParser;
    
    [parser parse];
    
    if([self isCancelled])
        return FALSE;
    
    
    //do something with the entries (should have all of the files)... probably need to flush one at a time - put the flush into the parser...
    
    
    //[self updateProgress:[NSString stringWithFormat:@"Downloaded Images for ID %d", imageID] withPercent:1];
    
    //    [result release];
    
    return success;
}

-(BOOL)downloadMMLocationImages
{
    if([_appDelegate.pricingDB vanline] != ATLAS)
        return TRUE;
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOImageParser *imageParser = nil;
    
    NSString *result = nil;
    
    for (int i = 1; i <= 4; i++) {
        
        imageParser = [[PVOImageParser alloc] init];
        
        
        
        //        if ([del.pricingDB vanline] == ATLAS)
        //        {
        req.functionName = @"DownloadSurveyImages";
        success = [req getData:&result
                 withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", i], orderNumber, @"SURVEY_LOCATION", nil]
                                                           forKeys:[NSArray arrayWithObjects:@"relatedRecordID", @"orderNumber", @"type", nil]]
                  needsDecoded:YES withSSL:ssl
                   flushToFile:nil];
        imageParser.isWCF = NO;
        imageParser.isWCF = NO;
        //        }
        //        else
        //        {
        //            req.functionName = @"GetIGCSyncLocationImages";
        //            success = [req getData:&result
        //                     withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:orderNumber, [NSString stringWithFormat:@"%d", imageID], data.haulingAgent, self.downloadRequestType == 0 ? @"true" : @"false", nil]
        //                                                               forKeys:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]]
        //                      needsDecoded:NO withSSL:ssl
        //                       flushToFile:nil
        //                         withOrder:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]];
        //            [data release];
        //        }
        
        if(!success)
        {
            [self updateProgress:result withPercent:1];
            return FALSE;
        }
        
        if([self isCancelled])
            return FALSE;
        
        parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        imageParser.locationID = i;
        
        parser.delegate = imageParser;
        
        [parser parse];
        
        if([self isCancelled])
            return FALSE;
        
        
        //do something with the entries (should have all of the files)... probably need to flush one at a time - put the flush into the parser...
        
        
        //[self updateProgress:[NSString stringWithFormat:@"Downloaded Images for ID %d", imageID] withPercent:1];
        
        //        [result release];
    }
    
    
    return success;
}

-(BOOL)downloadMMRoomImages:(int)imageID forRoomID:(int)roomID
{
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOImageParser *imageParser = nil;
    
    NSString *result = nil;
    
    imageParser = [[PVOImageParser alloc] init];
    
    if ([_appDelegate.pricingDB vanline] == ATLAS)
    {
        req.functionName = @"DownloadSurveyImages";
        success = [req getData:&result
                 withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", imageID],
                                                                    orderNumber, @"SURVEY_ROOM", nil]
                                                           forKeys:[NSArray arrayWithObjects:@"relatedRecordID", @"orderNumber", @"type", nil]]
                  needsDecoded:YES withSSL:ssl
                   flushToFile:nil];
        imageParser.isWCF = NO;
    }
    else
    {
        //probably need to add a withParamOrder argument into getData for this one...
        req.functionName = @"GetIGCSyncRoomImages";
        success = [req getData:&result
                 withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:orderNumber, [NSString stringWithFormat:@"%d", imageID], _driverData.haulingAgent, self.downloadRequestType == 0 ? @"true" : @"false", nil]
                                                           forKeys:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]]
                  needsDecoded:NO withSSL:ssl
                   flushToFile:nil
                     withOrder:[NSArray arrayWithObjects:@"regNumber", @"imageID", nil]];
    }
    
    if(!success)
    {
        [self updateProgress:result withPercent:1];
        return FALSE;
    }
    
    if([self isCancelled])
        return FALSE;
    
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    imageParser.roomID = roomID;
    
    parser.delegate = imageParser;
    
    [parser parse];
    
    if([self isCancelled])
        return FALSE;
    
    
    //do something with the entries (should have all of the files)... probably need to flush one at a time - put the flush into the parser...
    
    
    //[self updateProgress:[NSString stringWithFormat:@"Downloaded Images for ID %d", imageID] withPercent:1];
    
    //    [result release];
    
    return success;
}

-(BOOL)receiveInventory
{
    return [self receiveInventory:NO];
}

-(BOOL)receiveInventory:(BOOL)skipUpdateProgress
{
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOInventoryParser *xmlParser = nil;
    
    NSString *result = nil;
    
    req.functionName = @"GetIGCSyncLastInventoryActivity";
    success = [req getData:&result
             withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                orderNumber,
                                                                (_driverData.driverNumber == nil ? @"" : _driverData.driverNumber),
                                                                (_driverData.driverPassword == nil ? @"" : _driverData.driverPassword),
                                                                (_driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent),
                                                                [NSString stringWithFormat:@"%d", [_appDelegate.pricingDB vanline]], nil]
                                                       forKeys:[NSArray arrayWithObjects:@"regNumber", @"driverNumber", @"password", @"agencyCode", @"carrierID", nil]]
              needsDecoded:YES withSSL:ssl
               flushToFile:nil
                 withOrder:[NSArray arrayWithObjects:@"regNumber", @"driverNumber", @"password", @"agencyCode", @"carrierID", nil]];
    
    
    if(!success)
    {
        if (!skipUpdateProgress)
            [self updateProgress:result withPercent:1];
        return FALSE;
    }
    
    if([self isCancelled])
        return FALSE;
    
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    
    xmlParser = [[PVOInventoryParser alloc] init];
    
    parser.delegate = xmlParser;
    
    [parser parse];
    
    if([self isCancelled])
        return FALSE;
    
    if (xmlParser.entries != nil)
        self.inventoryItemEntries = [NSArray arrayWithArray:xmlParser.entries];
    self.receivedType = xmlParser.receivedType;
    self.receivedUnloadType = xmlParser.receivedUnloadType;
    self.loadType = xmlParser.loadType;
    self.mproWeight = xmlParser.mproWeight;
    self.sproWeight = xmlParser.sproWeight;
    self.consWeight = xmlParser.consWeight;
    
    
    if (!skipUpdateProgress)
        [self updateProgress:[NSString stringWithFormat:@"Downloaded all entries."] withPercent:1];
    
    //    [result release];
    
    return success;
}

-(BOOL)updateActualDates
{
    if ([_appDelegate.pricingDB vanline] != ATLAS)
        return YES;
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    SuccessParser *successParser = nil;
    NSString *result = nil;
    
    NSDictionary *temp = nil;
    
    req.functionName = @"UpdateActualDateWithSignatureDate";
    
    BOOL actualDateIsAtPickup = [self.additionalParamInfo boolValue];
    
    // Get signature number
    SurveyAppDelegate* del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    int custID = del.customerID;
    
    PVOInventory* p = [del.surveyDB getPVOData:custID];
    int loadType = [p loadType];
    int sigType = -1;
    
    if(loadType == SPECIAL_PRODUCTS) {
        if(actualDateIsAtPickup) {
            sigType = PVO_SIGNATURE_TYPE_SP_INVENTORY;
        } else {
            sigType = PVO_SIGNATURE_TYPE_SP_INVENTORY_DEST;
        }
    } else {
        if(actualDateIsAtPickup) {
            sigType = PVO_SIGNATURE_TYPE_ORG_INVENTORY;
        } else {
            sigType = PVO_SIGNATURE_TYPE_DEST_INVENTORY;
        }
    }
    
    NSArray* signatures = [del.surveyDB getPVOSignatures:custID];
    NSDate* sigDate = nil;
    
    for(int i = 0; i < [signatures count]; i++) {
        PVOSignature* currentSig = [signatures objectAtIndex:i];
        if(currentSig.pvoSigTypeID == sigType) {
            sigDate = currentSig.sigDate;
        }
    }
    
    if(sigDate == nil) {
        return;
    }
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SS"];
    NSString* dateTime = [dateFormatter stringFromDate:sigDate];
    
    temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_driverData.driverNumber,
                                                _driverData.haulingAgent == nil ? @"" : _driverData.haulingAgent,
                                                orderNumber,
                                                actualDateIsAtPickup ? @"true" : @"false", dateTime, nil]
                                       forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"shipmentID", @"pickup", @"date", nil]];
    
    success = [req getData:&result withArguments:temp needsDecoded:YES];
    
    if(!success)
    {
        //error with message...
        [self updateProgress:result withPercent:1];
        return FALSE;
    }
    
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    
    successParser = [[SuccessParser alloc] init];
    parser.delegate = successParser;
    [parser parse];
    
    if(!successParser.success)
    {
        //error with message...
        [self updateProgress:successParser.errorString withPercent:1];
        return FALSE;
    }
    
    
    [self updateProgress:[NSString stringWithFormat:@"Actual Date Uploaded Successfully."] withPercent:1];
    
    //    [result release];
    
    return success;
}

-(XMLWriter*)getRequestXML
{
    NSString *deviceID = nil;
    //    if ([[ASIdentifierManager sharedManager] respondsToSelector:@selector(advertisingIdentifier)])
    //        deviceID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    //    else
    deviceID = [OpenUDID value];
    
    XMLWriter *writer = [[XMLWriter alloc] init];
    [writer writeStartElement:@"request"];
    [writer writeAttribute:@"z:Id" withData:@"i1"];
    [writer writeAttribute:@"xmlns:a" withData:@"http://schemas.datacontract.org/2004/07/AISync.Model.Order"];
    [writer writeAttribute:@"xmlns:i" withData:@"http://www.w3.org/2001/XMLSchema-instance"];
    [writer writeAttribute:@"xmlns:z" withData:@"http://schemas.microsoft.com/2003/10/Serialization/"];
    
    [writer writeElementString:@"a:AddCoverSheet" withData:_appDelegate.uploadingArpinDoc ? @"true" : @"false"];
    
    BOOL printNilBookingAgencyCode = false;
    if (_driverData == nil || (_driverData.driverType != PVO_DRIVER_TYPE_PACKER && _driverData.haulingAgent == nil)) //no record for driver or no hauling agent code entered as driver
    {
        printNilBookingAgencyCode = true;
    }
    else
    {
        if (_driverData.driverType == PVO_DRIVER_TYPE_PACKER && [AppFunctionality showAgencyCodeOnDownload])
        {
            if(self.overrideAgencyCode == nil || self.overrideAgencyCode.length == 0) //packers require a hauling agent code entered manually at download time, download screen won't allow a 0 length agency code but this handles that to prevent error
            {
                printNilBookingAgencyCode = true;
            }
            else
                [writer writeElementString:@"a:BookingAgencyCode" withData:self.overrideAgencyCode];
        }
        else
            [writer writeElementString:@"a:BookingAgencyCode" withData:_driverData.haulingAgent];
    }
    
    if (printNilBookingAgencyCode)
    {
        [writer writeStartElement:@"a:BookingAgencyCode"];
        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    }
    int vanlineId = [_appDelegate.pricingDB vanline];
    [writer writeElementString:@"a:CarrierID" withIntData:vanlineId];
    
    //not going to use this, we're doing agency code instead
    //    if(data.driverType != PVO_DRIVER_TYPE_PACKER || self.customerLastName == nil || self.customerLastName.length == 0)
    //    {
    //        [writer writeStartElement:@"a:CustomerLastName"];
    //        [writer writeAttribute:@"i:nil" withData:@"true"];
    //        [writer writeEndElement];
    //    }
    //    else
    //        [writer writeElementString:@"a:CustomerLastName" withData:self.customerLastName];
    
    [writer writeElementString:@"a:DeviceID" withData:deviceID];
    [writer writeElementString:@"a:DeviceMake" withData:@"Apple"];
    [writer writeElementString:@"a:DeviceModel" withData:[NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion]];
    [writer writeElementString:@"a:DeviceVersion" withData:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    if ([_appDelegate.pricingDB vanline] == ARPIN && _driverData != nil && _driverData.syncPreference == PVO_ARPIN_SYNC_BY_DRIVER)
    {
        if (_driverData == nil || _driverData.driverNumber == nil)
        {
            [writer writeStartElement:@"a:DriverNumber"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverNumber" withData:_driverData.driverNumber];
        
        if (_driverData == nil || _driverData.driverPassword == nil)
        {
            [writer writeStartElement:@"a:DriverPassword"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverPassword" withData:_driverData.driverPassword];
    }
    else
    {
        if (_driverData == nil || _driverData.haulingAgent == nil)
        {
            [writer writeStartElement:@"a:DriverNumber"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverNumber" withData:_driverData.haulingAgent];
        
        [writer writeElementString:@"a:DriverPassword" withData:@""];
    }
    
    [writer writeStartElement:@"a:OrderID"];
    [writer writeAttribute:@"i:nil" withData:@"true"];
    [writer writeEndElement];
    
    if (self.orderNumber == nil)
    {
        [writer writeStartElement:@"a:OrderNumber"];
        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    }
    else
        [writer writeElementString:@"a:OrderNumber" withData:self.orderNumber];
    
    
    if ([AppFunctionality enableMoveHQSettings])
    {
        //add relocrmsettings
        [writer writeStartElement:@"a:ReloSettings"];
        [writer writeAttribute:@"z:Id" withData:@"i2"];
        //    [writer writeAttribute:@"xmlns:a" withData:@"http://schemas.datacontract.org/2004/07/AISync.Model.ReloCRMSettings"];
        //    [writer writeAttribute:@"xmlns:i" withData:@"http://www.w3.org/2001/XMLSchema-instance"];
        //    [writer writeAttribute:@"xmlns:z" withData:@"http://schemas.microsoft.com/2003/10/Serialization/"];
        
        //password
        if (_driverData.crmPassword == nil || [_driverData.crmPassword length] <= 0)
        {
            [writer writeStartElement:@"a:Password"];
            //            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
        {
            [writer writeElementString:@"a:Password" withData:_driverData.crmPassword];
        }
        
        //crm url
        if ([self getReloCRMSyncURL] == nil || [[self getReloCRMSyncURL] length] <= 0)
        {
            [writer writeStartElement:@"a:SyncAddress"];
            //            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
        {
            [writer writeElementString:@"a:SyncAddress" withData:[self getReloCRMSyncURL]];
        }
        
        //username
        if (_driverData.crmUsername == nil || [_driverData.crmUsername length] <= 0)
        {
            [writer writeStartElement:@"a:Username"];
            //            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
        {
            [writer writeElementString:@"a:Username" withData:_driverData.crmUsername];
        }
        
        //end reloCRMSettings
        [writer writeEndElement];
    } else {
        [writer writeStartElement:@"a:reloSettings"];
        [writer writeEndElement];
    }
    
    [writer writeElementString:@"a:RequestType" withData:self.downloadRequestType == 0 ? @"Interstate" : self.downloadRequestType == 1 ? @"Local" : self.downloadRequestType == 2 ? @"CNCIV" : @"CNGOV"];
    
    if(_driverData != nil && _driverData.driverType == PVO_DRIVER_TYPE_PACKER)
        [writer writeElementString:@"a:SystemType" withData:@"Packer"];
    else
        [writer writeElementString:@"a:SystemType" withData:@"Driver"];
    
    [writer writeEndDocument];
    
    return writer;
}

-(XMLWriter*)getReloCRMSettingsXML
{
    //
    //    NSString *deviceID = nil;
    //    deviceID = [OpenUDID value];
    
    XMLWriter *writer = [[XMLWriter alloc] init];
    
    if ([AppFunctionality enableMoveHQSettings])
    {
        [writer writeStartElement:@"reloSettings"];
        [writer writeAttribute:@"z:Id" withData:@"i1"];
        [writer writeAttribute:@"xmlns:a" withData:@"http://schemas.datacontract.org/2004/07/AISync.Model.Order"];
        [writer writeAttribute:@"xmlns:i" withData:@"http://www.w3.org/2001/XMLSchema-instance"];
        [writer writeAttribute:@"xmlns:z" withData:@"http://schemas.microsoft.com/2003/10/Serialization/"];
        
        //password
        [writer writeElementString:@"a:Password" withData:_driverData.crmPassword];
        
        //crm url
        [writer writeElementString:@"a:SyncAddress" withData:[self getReloCRMSyncURL]];
        
        //username
        [writer writeElementString:@"a:Username" withData:_driverData.crmUsername];
        
        //end reloCRMSettings
        [writer writeEndElement];
        
        //end document
        [writer writeEndDocument];
    } else {
        [writer writeStartElement:@"reloSettings"];
        //        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    }
    
    return writer;
}

-(XMLWriter*)getStatusUpdateSettingsXML
{
    //
    //    NSString *deviceID = nil;
    //    deviceID = [OpenUDID value];
    
    XMLWriter *writer = [[XMLWriter alloc] init];
    
    if ([AppFunctionality enableMoveHQSettings])
    {
        [writer writeStartElement:@"settings"];
        [writer writeAttribute:@"z:Id" withData:@"i1"];
        [writer writeAttribute:@"xmlns:a" withData:@"http://schemas.datacontract.org/2004/07/AISync.Model.Order"];
        [writer writeAttribute:@"xmlns:i" withData:@"http://www.w3.org/2001/XMLSchema-instance"];
        [writer writeAttribute:@"xmlns:z" withData:@"http://schemas.microsoft.com/2003/10/Serialization/"];
        
        //password
        [writer writeElementString:@"a:Password" withData:_driverData.crmPassword];
        
        //crm url
        [writer writeElementString:@"a:SyncAddress" withData:[self getReloCRMSyncURL]];
        
        //username
        [writer writeElementString:@"a:Username" withData:_driverData.crmUsername];
        
        //end reloCRMSettings
        [writer writeEndElement];
        
        //end document
        [writer writeEndDocument];
    } else {
        [writer writeStartElement:@"settings"];
        //        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    }
    
    return writer;
}

-(NSString*)getReloCRMSyncURL
{
    int vanlineID = [_appDelegate.pricingDB vanline];
    
    
    //until we move this url into the pricing db or web config of the service, need a aquick way to override
    if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"relourl:"].location != NSNotFound)
    {//override the default virtual directory
        NSRange addpre = [[Prefs betaPassword] rangeOfString:@"relourl:"];
        NSString *reloURL = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
        addpre = [reloURL rangeOfString:@" "];
        if (addpre.location != NSNotFound)
            reloURL = [reloURL substringToIndex:addpre.location];
        
        reloURL = [NSString stringWithFormat:@"https://%@/", reloURL];
        return reloURL;
    }
    
    NSString *retval = [_appDelegate.pricingDB getCRMSyncAddress:vanlineID withEnvironment:_driverData.crmEnvironment];
    
    return retval;
}

@end
