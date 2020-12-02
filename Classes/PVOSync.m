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
#import "RestSyncRequest.h"
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
@property (nonatomic) int vanlineId;

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
@synthesize appDelegate, driverData, vanlineId, restRequest;


-(id)init
{
    self = [super init];
    if(self)
    {
        appDelegate = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        vanlineId = [appDelegate.pricingDB vanline];
        driverData = [appDelegate.surveyDB getDriverData];
        
        req = [[WebSyncRequest alloc] init];
        restRequest = [[RestSyncRequest alloc] init];

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
    appDelegate = nil;
    
}

-(void)main
{
    BOOL success = YES;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    appDelegate.surveyDB.runningOnSeparateThread = YES;
    @try
    {
        ssl = FALSE;
        
        
        switch (vanlineId) {
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
#if defined(DEBUG) || defined(RELEASE)
                req.serverAddress = @"dev.mobilemover.com";
                req.port = 80;
                req.type = PVO_SYNC;
                
                restRequest.scheme = SCHEME;
                restRequest.host = [self getRestHost];
                restRequest.basePath = AICLOUD_PATH;
                
#else
                ssl = YES;
                req.serverAddress = PVO_WCF_ADDRESS;
                req.port = 443;
                req.type = PVO_SYNC;
                
                restRequest.scheme = SCHEME;
                restRequest.host = [self getRestHost];
                restRequest.basePath = AICLOUD_PATH;
#endif
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
            case PVO_SYNC_ACTION_GET_DATA:
                success = [self downloadExternalData];
                break;
            case PVO_SYNC_ACTION_GET_DATA_WITH_ORDER_REQUEST:
                success = [self downloadExternalDataWithRequest];
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
    appDelegate.surveyDB.runningOnSeparateThread = NO;
    
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
    SurveyCustomer *cust = [appDelegate.surveyDB getCustomer:appDelegate.customerID];
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
    
    if (vanlineId != ATLAS)
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
        
        NSDictionary *temp = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:driverData.driverNumber, driverData.haulingAgent, orderNumber,
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
    
    if (vanlineId != ATLAS)
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
             withArguments:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:driverData.driverNumber, orderNumber, driverData.haulingAgent,
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
    NSString *result = nil;
    NSError *error = nil;
    BOOL success = TRUE;
    
    
    NSData *reportData = [[NSData alloc] initWithContentsOfFile:
                          [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"]];
    
    NSDictionary *temp = nil;
    
    SurveyCustomer *cust = [appDelegate.surveyDB getCustomer:appDelegate.customerID];
    self.downloadRequestType = cust.pricingMode;
    
    if(![AppFunctionality isDemoOrder:self.orderNumber])
    {
        restRequest.methodPath = REPORTS_PATH;
        
        NSDictionary *queryParameters = @{@"docType" : [NSString stringWithFormat:@"%d", pvoReportID],
                                          @"actualDate" : @"",
                                          @"isOrigin" : @""
        };
        NSDictionary *bodyDictionary = @{@"Report" : [Base64 encode64WithData:reportData],
                                         @"Request" : [self getOrderRequestJson:&error]
        };
        
        NSData * bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];

        result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];
        
        if (result == nil || result.length == 0) {
            NSString *errorMessage = [self getErrorMessage:error eventText:@"uploading the current document"];
            if ([errorMessage rangeOfString:@"Unable to load Order for Order Number provided."].location != NSNotFound)
            {
                //clean up error message for the device.  tell them they need to sync first.
                result = @"Please synchronize first by selecting \"Save To Server\" from the Inventory screen.";
            } else {
                result = errorMessage;
            }
            //error with message...
            [self updateProgress:result withPercent:1];
            
            return FALSE;
        }
        //success
        [self updateProgress:@"Document Uploaded Successfully!" withPercent:1];
    }
    
    return success;
}

-(BOOL)downloadPreShipCheckList
{
    //username
    if ([driverData.crmUsername length] == 0 || [driverData.crmPassword length] == 0 || [[self getReloCRMSyncURL] length] == 0)
    {
        return false;
    }
    
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOPreShipChecklistParser *checkListParser = nil;
    NSString *result = nil;
    
    if (driverData.haulingAgent == nil || [driverData.haulingAgent isEqualToString:@""])
        return NO;
    
    XMLWriter *reloSettings = [self getReloCRMSettingsXML];
    WCFDataParam *requestParm = [[WCFDataParam alloc] init];
    requestParm.contents = reloSettings.file;
    
    req.functionName = @"GetPreShipChecklistWithAgencyCode";
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                              requestParm,
                                                              (driverData == nil || driverData.haulingAgent == nil ? @"" : driverData.haulingAgent),
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
    [appDelegate.surveyDB savePVOVehicleCheckListForAgency:checkListParser.checkListItems withAgencyCode:driverData.haulingAgent];
    
    return success;
    
}

- (NSString* _Nullable)getErrorMessage:(NSError *)error eventText:(NSString*) text {
    NSString *errorMessage = [[error userInfo] valueForKey:@"Error"];
    if ([errorMessage rangeOfString:@"One or more errors occurred"].location != NSNotFound) {
        errorMessage = [NSString stringWithFormat:@"An error has occurred when %@. Please contact Support.", text];
    }
    return errorMessage;
}

-(BOOL)downloadSurvey
{
    NSError *error = nil;
    NSString *result = nil;
    NSXMLParser *parser = nil;
    SurveyDownloadXMLParser *downloadParser = nil;
    
    BOOL success = TRUE;

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
        restRequest.methodPath = ORDERS_PATH;
        NSData *bodyData = [self getBodyDataForDictionary:[self getOrderRequestJson: &error] error:&error];
        result = [restRequest executeHttpRequest:@"POST" withQueryParameters:nil andBodyData:bodyData andError:&error shouldDecode:YES];
    }
    
    if([self isCancelled])
        return FALSE;
        
    if(result == nil || result.length == 0) {
        //error with message...
        [self updateProgress:[self getErrorMessage:error eventText:@"downloading your order"] withPercent:1];
        return FALSE;
    }
    
    //parse the survey, and demo data
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    downloadParser = [[SurveyDownloadXMLParser alloc] initWithAppDelegate:appDelegate];
    downloadParser.atlasSync = (vanlineId == ATLAS);
    parser.delegate = downloadParser;
    [parser parse];
    
    //parse the inventory data.
    PVOInventoryParser *inventoryParser = [[PVOInventoryParser alloc] init];
    parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = inventoryParser;
    [parser parse];
    
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
    
    if (mergeCustomer)
    {
        [SyncGlobals mergeCustomerToDB:downloadParser appDelegate:appDelegate];
    }
    else
    {
        [SyncGlobals flushCustomerToDB:downloadParser appDelegate:appDelegate];
    }
    
    // save or update Inventory data
    PVOInventory *invData = [appDelegate.surveyDB getPVOData:downloadParser.customer.custID];
    
    invData.loadType = inventoryParser.loadType;
    invData.mproWeight = inventoryParser.mproWeight;
    invData.sproWeight = inventoryParser.sproWeight;
    invData.consWeight = inventoryParser.consWeight;
    invData.lockLoadType = [AppFunctionality lockInventoryLoadTypeOnDownload:downloadParser.customer.pricingMode];
    [appDelegate.surveyDB updatePVOData:invData];
    
    if ([AppFunctionality getPvoReceiveType] & PVO_RECEIVE_ON_DOWNLOAD)
    {
        if (inventoryParser.receivedType != PACKER_INVENTORY || ![AppFunctionality disablePackersInventory])
        {
            //per defect 91, save with merge and new ... save the inventory too
            if(inventoryParser.entries != nil && inventoryParser.entries.count > 0)
            {
                [appDelegate.surveyDB savePVOReceivableItems:inventoryParser.entries forCustomer:downloadParser.customer.custID ignoreIfInventoried:mergeCustomer];
                if (inventoryParser.receivedFromType > 0 && inventoryParser.receivedFromType != inventoryParser.receivedType)
                    [appDelegate.surveyDB setPVOReceivedItemsType:inventoryParser.receivedFromType forCustomer:downloadParser.customer.custID];
                else
                    [appDelegate.surveyDB setPVOReceivedItemsType:inventoryParser.receivedType forCustomer:downloadParser.customer.custID];
                [appDelegate.surveyDB setPVOReceivedItemsUnloadType:inventoryParser.receivedUnloadType forCustomer:downloadParser.customer.custID];
            }
        }
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
    [self downloadPreShipCheckList];
    
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
    reportReq.serverAddress = @"print.moverdocs.com";
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
    [dict setObject:[NSString stringWithFormat:@"%d", vanlineId] forKey:@"vanLineId"];
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
    NSError *error = nil;
    //incoming is A[shipid],[suid]
    BOOL success = TRUE;
        
    NSMutableArray *custs = [appDelegate.surveyDB getCustomerList:nil];
    CustomerListItem *item;
    XMLWriter *writer;
    NSString *result;
    int origDelCustID = appDelegate.customerID;
        
    for(int i = 0 ; i< [custs count]; i++)
    {
        item = [custs objectAtIndex:i];
        SurveyCustomerSync *sync = [appDelegate.surveyDB getCustomerSync:item.custID];
        if(sync.syncToPVO)
        {
            if([self isCancelled])
            {
                success = FALSE;
                break;
            }
            
            appDelegate.customerID = item.custID;
            
            //check for demo...
            SurveyCustomer *cust = [appDelegate.surveyDB getCustomer:item.custID];
            ShipmentInfo *info = [appDelegate.surveyDB getShipInfo:appDelegate.customerID];
            BOOL demo = FALSE;
            if(cust.pricingMode == INTERSTATE)
                demo = [AppFunctionality isDemoOrder:info.orderNumber];
            
            if(demo)
            {
                [NSThread sleepForTimeInterval:2.]; //wait two seconds
            }
            else
            {
                restRequest.methodPath = ORDERS_PATH;
                writer = [SyncGlobals buildCustomerXML:item.custID isAtlas:(vanlineId == ATLAS)];
                
                NSDictionary *bodyDictionary = @{@"Order" : [Base64 encode64:writer.file],
                                                 @"ReloSettings" : [self getReloSettings]
                };
                
                NSData* body = [self getBodyDataForDictionary:bodyDictionary error:&error];

                NSDictionary *queryParameters = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                          (driverData == nil || driverData.driverNumber == nil ? @"" : driverData.driverNumber),
                                                                          (driverData == nil || driverData.haulingAgent == nil ? @"" : driverData.haulingAgent),
                                                                          [NSString stringWithFormat:@"%d", vanlineId], nil]
                                                                 forKeys:[NSArray arrayWithObjects:@"driverNumber", @"agencyCode", @"carrierID", nil]];
                
                result = [restRequest executeHttpRequest:@"PUT" withQueryParameters:queryParameters andBodyData:body andError:&error shouldDecode:NO];
                
                if(result == nil || result.length == 0) {
                    [self updateProgress:[NSString stringWithFormat:@"%@(%@) failed to upload. Reason: %@", item.name, item.orderNumber, [self getErrorMessage:error eventText:@"uploading inventory"]] withPercent:1];
                    //set sync to false, per defect 208
                    sync.syncToPVO = FALSE;
                    [appDelegate.surveyDB updateCustomerSync:sync];
                    //                        [result release];
                    break;
                }
                
                //upload photos for this customer.
                if (uploadPhotosWithInventory)
                {
                    success = [self uploadPhotos:item.custID];
                    if(!success)
                    {
                        //set sync to falce, per defect 208
                        sync.syncToPVO = FALSE;
                        [appDelegate.surveyDB updateCustomerSync:sync];
                        break;
                    }
                }
            }
            
            [self updateProgress:[[NSString alloc] initWithFormat:@"%@ uploaded successfully.", item.name]
                     withPercent:1];
            
            sync.syncToPVO = FALSE;
            [appDelegate.surveyDB updateCustomerSync:sync];
        }
    }
    
    appDelegate.customerID = origDelCustID;
    
    return success;
}

- (NSData *)getBodyDataForDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:error];
    return bodyData;
}

-(BOOL)uploadPhotos:(int)custID
{
    NSError *error = nil;
    BOOL success = TRUE;
    NSString *result;
    //first send the notification message.
    //get all photos
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    SurveyCustomer *cust = [appDelegate.surveyDB getCustomer:custID];
    self.downloadRequestType = cust.pricingMode;
    self.orderNumber = [appDelegate.surveyDB getShipInfo:custID].orderNumber;
    
    NSDictionary *orderRequestJson = [self getOrderRequestJson:&error];

    ///upload item photos first
    restRequest.methodPath = ITEM_IMAGES_PATH;
    double calculatedProgress = 0, totalImagesToUpload = 0, currentProgress = 0;
    NSArray *photoTypes = @[@IMG_PVO_ITEMS, @IMG_PVO_DESTINATION_ITEMS];
    
    NSArray *images = [appDelegate.surveyDB getImagesList:custID withPhotoTypes:photoTypes withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
    if([images count] > 0)
    {
        [self resetProgressBar];
        
        //progress bar works better when variables are stored as a double to calculate percent
        totalImagesToUpload = [images count];

        //upload the photos
        for(int i = 0; i < [images count]; i++)
        {
            NSMutableDictionary *queryParameters = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *bodyDictionary = [[NSMutableDictionary alloc] init];
            
            SurveyImage *image = [images objectAtIndex:i];
            NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
            if([fileManager fileExistsAtPath:fullPath])
            {
                UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                NSData *imgData = [PVOSync getResizedPhotoData:img];
                [bodyDictionary setValue:[Base64 encode64WithData:imgData] forKey:@"Image"];
                [bodyDictionary setValue:orderRequestJson forKey:@"Request"];
                
                //get pvoiteminfo
                PVOItemDetail *pvoitem = [appDelegate.surveyDB getPVOItem:image.subID];
                [queryParameters setValue:[pvoitem displayInventoryNumber] forKey:@"barcode"];
                [queryParameters setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                
                NSData *bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];
                result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];

                
                if(result == nil || result.length == 0)
                {
                    [self updateProgress:[self getErrorMessage:error eventText:@"uploading item photos"] withPercent:1];
                    break;
                }
                else
                {
                    currentProgress = i + 1;
                    calculatedProgress = currentProgress / totalImagesToUpload;
                    result = nil;
                }
                
                [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Item %@ Image ID %d posted...", [pvoitem displayInventoryNumber], image.imageID]
                         withPercent:calculatedProgress];
            }
            
        }
    }
    
    ///now upload room photos
    restRequest.methodPath = [NSString stringWithFormat:@"%@%@", ROOM_IMAGES_PATH, LOADS_PATH];

    NSArray *roomTypes = @[@IMG_PVO_ROOMS, @IMG_PVO_DESTINATION_ROOMS];
    
    images = [appDelegate.surveyDB getImagesList:custID withPhotoTypes:roomTypes withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
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
            NSMutableDictionary *queryParameters = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *bodyDictionary = [[NSMutableDictionary alloc] init];
            
            SurveyImage *image = [images objectAtIndex:i];
            NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
            if([fileManager fileExistsAtPath:fullPath])
            {
                int photoType = image.photoType;
                if (photoType == IMG_ROOMS || photoType == IMG_PVO_ROOMS) {
                    conditions = [appDelegate.surveyDB getPVORoomConditions:image.subID];
                } else if (image.photoType == IMG_PVO_DESTINATION_ROOMS) {
                    conditions = [appDelegate.surveyDB getPVODestinationRoomConditions:image.subID];
                }
                
                Room *r = [appDelegate.surveyDB getRoom:conditions.roomID];
                
                if (![appDelegate.surveyDB roomHasPVOInventoryItems:r.roomID] && image.photoType != IMG_PVO_DESTINATION_ROOMS)
                    continue; //skip if room has no items
                
                UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                NSData *imgData = [PVOSync getResizedPhotoData:img];
                
                [bodyDictionary setValue:[Base64 encode64WithData:imgData] forKey:@"Image"];
                [bodyDictionary setValue:orderRequestJson forKey:@"Request"];
                
                [queryParameters setValue:[r roomName] forKey:@"roomName"];
                [queryParameters setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                
                NSData *bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];
                result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];

                
                if(result == nil || result.length == 0)
                {
                    [self updateProgress:[self getErrorMessage:error eventText:@"uploading room photos"] withPercent:1];
                    break;
                }
                else
                {
                    currentProgress = i + 1;
                    calculatedProgress = currentProgress / totalImagesToUpload;
                    
                    [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Room %@ Image ID %d posted...", [[appDelegate.surveyDB getRoom:conditions.roomID] roomName], image.imageID]
                             withPercent:calculatedProgress];
                    result = nil;
                }
            }
            
        }
    }
    ///now upload unload room photos
    
    restRequest.methodPath = [NSString stringWithFormat:@"%@%@", ROOM_IMAGES_PATH, UNLOADS_PATH];

    images = [appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_PVO_DESTINATION_ROOMS withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
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
            NSMutableDictionary *queryParameters = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *bodyDictionary = [[NSMutableDictionary alloc] init];
            
            SurveyImage *image = [images objectAtIndex:i];
            NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
            if([fileManager fileExistsAtPath:fullPath])
            {
                unloadConditions = [appDelegate.surveyDB getPVODestinationRoomConditions:image.subID];
                
                Room *r = [appDelegate.surveyDB getRoom:unloadConditions.roomID];
                
                //if (![del.surveyDB roomHasPVOInventoryItems:r.roomID])
                //  continue; //skip if room has no items
                
                UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                NSData *imgData = [PVOSync getResizedPhotoData:img];
                
                [bodyDictionary setValue:[Base64 encode64WithData:imgData] forKey:@"Image"];
                [bodyDictionary setValue:orderRequestJson forKey:@"Request"];
                
                [queryParameters setValue:[r roomName] forKey:@"roomName"];
                [queryParameters setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                
                NSData *bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];
                result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];

                if(result == nil || result.length == 0)
                {
                    [self updateProgress:[self getErrorMessage:error eventText:@"uploading unload room photos"] withPercent:1];
                    break;
                }
                else
                {
                    currentProgress = i + 1;
                    calculatedProgress = currentProgress / totalImagesToUpload;
                    
                    [self updateProgress:[[NSString alloc] initWithFormat:@"PVO Room %@ Image ID %d posted...", [[appDelegate.surveyDB getRoom:unloadConditions.roomID] roomName], image.imageID]
                             withPercent:calculatedProgress];
                    result = nil;
                }
            }
        }
    }
    
    ///now upload location photos
    restRequest.methodPath = LOCATION_IMAGES_PATH;
    
    images = [appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_LOCATIONS withSubID:0 loadAllItems:FALSE loadAllForType:TRUE];
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
            NSMutableDictionary *queryParameters = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *bodyDictionary = [[NSMutableDictionary alloc] init];
            
            SurveyImage *image = [images objectAtIndex:i];
            NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
            if([fileManager fileExistsAtPath:fullPath])
            {
                
                UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                NSData *imgData = [PVOSync getResizedPhotoData:img];
                
                [bodyDictionary setValue:[Base64 encode64WithData:imgData] forKey:@"Image"];
                [bodyDictionary setValue:orderRequestJson forKey:@"Request"];
                
                NSString *locName = @"Origin";
                if(image.subID == ORIGIN_LOCATION_ID)
                    [queryParameters setValue:@"Origin" forKey:@"locType"];
                else if(image.subID == DESTINATION_LOCATION_ID)
                {
                    [queryParameters setValue:@"Destination" forKey:@"locType"];
                    locName = @"Destination";
                }
                else
                {
                    loc = [appDelegate.surveyDB getCustomerLocation:image.subID]; //uses locationID
                    if (loc.isOrigin)
                        [queryParameters setValue:@"OriginExtraStop" forKey:@"locType"];
                    else
                        [queryParameters setValue:@"DestinationExtraStop" forKey:@"locType"];
                    locName = @"Extra Stop";
                }
                
                [queryParameters setValue:[NSString stringWithFormat:@"%d", (loc == nil ? 0 : loc.sequence)] forKey:@"sequence"];
                [queryParameters setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                
                NSData *bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];
                result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];

                if(result == nil || result.length == 0)
                {
                    [self updateProgress:[self getErrorMessage:error eventText:@"uploading location photos"] withPercent:1];
                    break;
                }
                else
                {
                    currentProgress = i + 1;
                    calculatedProgress = currentProgress / totalImagesToUpload;
                    
                    [self updateProgress:[NSString stringWithFormat:@"%@ Location Image ID %d posted...", locName, image.imageID]
                             withPercent:calculatedProgress];
                    result = nil;
                }
            }
        }
    }
    
    if ([AppFunctionality disableWeightTickets])
    {
        return success;
    }
    
    ///now upload po d tickets - atlasnet has a separate upload for them, not part of sync process
    restRequest.methodPath = WEIGHT_TICKET_PATH;

    NSArray *tickets = [appDelegate.surveyDB getPVOWeightTickets:custID];
    for (PVOWeightTicket *ticket in tickets) {
        
        images = [appDelegate.surveyDB getImagesList:custID withPhotoType:IMG_PVO_WEIGHT_TICKET withSubID:ticket.weightTicketID
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
                NSMutableDictionary *queryParameters = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *bodyDictionary = [[NSMutableDictionary alloc] init];
                
                SurveyImage *image = [images objectAtIndex:i];
                NSString *fullPath = [docsDir stringByAppendingPathComponent:image.path];
                if([fileManager fileExistsAtPath:fullPath])
                {
                    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                    NSData *imgData = [PVOSync getResizedPhotoData:img];
                    
                    [bodyDictionary setValue:[Base64 encode64:[ticket xmlFile].file] forKey:@"WeightTicket"];
                    [bodyDictionary setValue:[Base64 encode64WithData:imgData] forKey:@"Image"];
                    [bodyDictionary setValue:orderRequestJson forKey:@"Request"];
                    
                    [queryParameters setValue:[XMLWriter formatString:image.path] forKey:@"fileName"];
                    
                    NSData * bodyData = [self getBodyDataForDictionary:bodyDictionary error:&error];
                    result = [restRequest executeHttpRequest:@"POST" withQueryParameters:queryParameters andBodyData:bodyData andError:&error shouldDecode:NO];

                    if(result == nil || result.length == 0)
                    {
                        [self updateProgress:[self getErrorMessage:error eventText:@"uploading weight tickets"] withPercent:1];
                        break;
                    }
                    else
                    {
                        currentProgress = i + 1;
                        calculatedProgress = currentProgress / totalImagesToUpload;
                        
                        [self updateProgress:[NSString stringWithFormat:@"Weight ticket %@ posted...", ticket.description]
                                 withPercent:calculatedProgress];
                        result = nil;
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
    NSError *error = nil;
    BOOL success = TRUE;
    
    NSString *result = nil;
    
    
    restRequest.methodPath = ITEM_IMAGES_PATH;
    
    NSDictionary *queryParameters = [NSDictionary dictionaryWithObjects:
                                [NSArray arrayWithObjects:orderNumber,
                                 [NSString stringWithFormat:@"%d", imageID],
                                 driverData.haulingAgent,
                                 self.downloadRequestType == 0 ? @"true" : @"false", nil]                                                 forKeys:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]];
    
    result = [restRequest executeHttpRequest:@"GET" withQueryParameters:queryParameters andBodyData:nil andError:&error shouldDecode:NO];
    
    if(result == nil || result.length == 0)
    {
        [self updateProgress:[self getErrorMessage:error eventText:@"downloading item images"] withPercent:1];
        return FALSE;
    }
    
    if([self isCancelled])
        return FALSE;
    
    NSDictionary *images = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    
    PVOImageParser *imageParser = [[PVOImageParser alloc] init];
    imageParser.surveyedItemID = siID;
    [imageParser parseJson:images];
    
    
    if([self isCancelled])
        return FALSE;
    
    
    //do something with the entries (should have all of the files)... probably need to flush one at a time - put the flush into the parser...
    
    return success;
}

-(BOOL)downloadMMLocationImages
{
    if(vanlineId != ATLAS)
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
    NSError *error = nil;
    BOOL success = TRUE;
    NSXMLParser *parser = nil;
    PVOImageParser *imageParser = nil;
    
    NSString *result = nil;
    
    imageParser = [[PVOImageParser alloc] init];
    
    restRequest.methodPath = ROOM_IMAGES_PATH;
    
    NSDictionary *queryParameters = [NSDictionary dictionaryWithObjects:
                                [NSArray arrayWithObjects:orderNumber,
                                 [NSString stringWithFormat:@"%d", imageID],
                                 driverData.haulingAgent,
                                 self.downloadRequestType == 0 ? @"true" : @"false", nil]                                                 forKeys:[NSArray arrayWithObjects:@"regNumber", @"imageID", @"agencyCode", @"isInterstate", nil]];
    
    result = [restRequest executeHttpRequest:@"GET" withQueryParameters:queryParameters andBodyData:nil andError:&error shouldDecode:NO];
    
    if(result == nil || result.length == 0)
    {
        [self updateProgress:[self getErrorMessage:error eventText:@"downloading room images"] withPercent:1];
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
                                                                (driverData.driverNumber == nil ? @"" : driverData.driverNumber),
                                                                (driverData.driverPassword == nil ? @"" : driverData.driverPassword),
                                                                (driverData.haulingAgent == nil ? @"" : driverData.haulingAgent),
                                                                [NSString stringWithFormat:@"%d", vanlineId], nil]
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
    
    [writer writeElementString:@"a:AddCoverSheet" withData:appDelegate.uploadingArpinDoc ? @"true" : @"false"];
    
    BOOL printNilBookingAgencyCode = false;
    if (driverData == nil || (driverData.driverType != PVO_DRIVER_TYPE_PACKER && driverData.haulingAgent == nil)) //no record for driver or no hauling agent code entered as driver
    {
        printNilBookingAgencyCode = true;
    }
    else
    {
        if (driverData.driverType == PVO_DRIVER_TYPE_PACKER && [AppFunctionality showAgencyCodeOnDownload])
        {
            if(self.overrideAgencyCode == nil || self.overrideAgencyCode.length == 0) //packers require a hauling agent code entered manually at download time, download screen won't allow a 0 length agency code but this handles that to prevent error
            {
                printNilBookingAgencyCode = true;
            }
            else
                [writer writeElementString:@"a:BookingAgencyCode" withData:self.overrideAgencyCode];
        }
        else
            [writer writeElementString:@"a:BookingAgencyCode" withData:driverData.haulingAgent];
    }
    
    if (printNilBookingAgencyCode)
    {
        [writer writeStartElement:@"a:BookingAgencyCode"];
        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    }
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
    
    if (vanlineId == ARPIN && driverData != nil && driverData.syncPreference == PVO_ARPIN_SYNC_BY_DRIVER)
    {
        if (driverData == nil || driverData.driverNumber == nil)
        {
            [writer writeStartElement:@"a:DriverNumber"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverNumber" withData:driverData.driverNumber];
        
        if (driverData == nil || driverData.driverPassword == nil)
        {
            [writer writeStartElement:@"a:DriverPassword"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverPassword" withData:driverData.driverPassword];
    }
    else
    {
        if (driverData == nil || driverData.haulingAgent == nil)
        {
            [writer writeStartElement:@"a:DriverNumber"];
            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
            [writer writeElementString:@"a:DriverNumber" withData:driverData.haulingAgent];
        
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
        if (driverData.crmPassword == nil || [driverData.crmPassword length] <= 0)
        {
            [writer writeStartElement:@"a:Password"];
            //            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
        {
            [writer writeElementString:@"a:Password" withData:driverData.crmPassword];
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
        if (driverData.crmUsername == nil || [driverData.crmUsername length] <= 0)
        {
            [writer writeStartElement:@"a:Username"];
            //            [writer writeAttribute:@"i:nil" withData:@"true"];
            [writer writeEndElement];
        }
        else
        {
            [writer writeElementString:@"a:Username" withData:driverData.crmUsername];
        }
        
        //end reloCRMSettings
        [writer writeEndElement];
    } else {
        [writer writeStartElement:@"a:reloSettings"];
        [writer writeEndElement];
    }
    
    [writer writeElementString:@"a:RequestType" withData:self.downloadRequestType == 0 ? @"Interstate" : self.downloadRequestType == 1 ? @"Local" : self.downloadRequestType == 2 ? @"CNCIV" : @"CNGOV"];
    
    if(driverData != nil && driverData.driverType == PVO_DRIVER_TYPE_PACKER)
        [writer writeElementString:@"a:SystemType" withData:@"Packer"];
    else
        [writer writeElementString:@"a:SystemType" withData:@"Driver"];
    
    [writer writeEndDocument];
    
    return writer;
}

-(NSDictionary*)getOrderRequestJson:(NSError**) error {
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *agencyCode = self.overrideAgencyCode != nil && self.overrideAgencyCode.length > 0 ? self.overrideAgencyCode : driverData.haulingAgent;
    NSString *deviceModel = [NSString stringWithFormat:@"%@ %@",
                             currentDevice.model,
                             currentDevice.systemVersion];
    id deviceVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *driverNumber = [self getValueOrEmptyString:driverData.driverNumber];
    NSString *driverPassword = [self getValueOrEmptyString:driverData.driverPassword];
    NSString *systemType = driverData.driverType == PVO_DRIVER_TYPE_PACKER ? @"Packer" : @"Driver";
    
    [jsonDictionary setObject:@NO forKey:@"AddCoverSheet"];
    [jsonDictionary setObject:[self getValueOrEmptyString:agencyCode] forKey:@"BookingAgencyCode"];
    [jsonDictionary setObject:[NSNumber numberWithInt:vanlineId] forKey:@"CarrierID"];
    [jsonDictionary setObject:[self getValueOrEmptyString:[OpenUDID value]] forKey:@"DeviceID"];
    [jsonDictionary setObject:@"Apple" forKey:@"DeviceMake"];
    [jsonDictionary setObject:deviceModel forKey:@"DeviceModel"];
    [jsonDictionary setObject:deviceVersion forKey:@"DeviceVersion"];
    [jsonDictionary setObject:driverNumber forKey:@"DriverNumber"];
    [jsonDictionary setObject:driverPassword forKey:@"DriverPassword"];
    [jsonDictionary setObject:@"" forKey:@"OrderID"];
    [jsonDictionary setObject:[self getValueOrEmptyString:self.orderNumber] forKey:@"OrderNumber"];
    [jsonDictionary setObject:[self getReloSettings] forKey:@"ReloSettings"];
    [jsonDictionary setObject:[self getPricingModeString:error] forKey:@"RequestType"];
    [jsonDictionary setObject:systemType forKey:@"SystemType"];
    
    return jsonDictionary;
}

-(NSString*)getValueOrEmptyString:(NSString*) value {
    return value == nil ? @"" : value;
}

-(NSString*)getPricingModeString:(NSError**) error {
    switch (self.downloadRequestType) {
        case 0:
            return @"Interstate";
        case 1:
            return @"Local";
        case 2:
            return @"CNCIV";
        default:
            return @"CNGOV"; // This is how the old logic functioned. Certainly bug-prone. TODO: use proper error handling
    }
}

-(NSDictionary*)getReloSettings {
    NSMutableDictionary *reloSettings = [[NSMutableDictionary alloc] init];
    
    if (driverData != nil) {
        if ([AppFunctionality enableMoveHQSettings]) {
            [reloSettings setObject:[self getValueOrEmptyString:driverData.crmUsername] forKey:@"Username"];
            [reloSettings setObject:[self getValueOrEmptyString:driverData.crmPassword] forKey:@"Password"];
            [reloSettings setObject:[self getValueOrEmptyString:[self getReloCRMSyncURL]] forKey:@"SyncAddress"];
        }
    }
    return reloSettings;
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
        [writer writeElementString:@"a:Password" withData:driverData.crmPassword];
        
        //crm url
        [writer writeElementString:@"a:SyncAddress" withData:[self getReloCRMSyncURL]];
        
        //username
        [writer writeElementString:@"a:Username" withData:driverData.crmUsername];
        
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

-(NSString*)getReloCRMSyncURL
{
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
    
    NSString *retval = [appDelegate.pricingDB getCRMSyncAddress:vanlineId withEnvironment:driverData.crmEnvironment];
    
    return retval;
}

-(NSString*)getRestHost {
    if ([[Prefs betaPassword] rangeOfString:@"crmenv:"].location != NSNotFound)
    {
        NSRange addpre = [[Prefs betaPassword] rangeOfString:@"crmenv:"];
        NSString *envStr = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
        addpre = [envStr rangeOfString:@" "];
        if (addpre.location != NSNotFound)
            envStr = [envStr substringToIndex:addpre.location];
        if ([[envStr lowercaseString] isEqualToString:@"qa"]) {
            return QA_HOST;
        } else if ([[envStr lowercaseString] isEqualToString:@"uat"]) {
            return UAT_HOST;
        }
    }
    return PROD_HOST;
}

@end
