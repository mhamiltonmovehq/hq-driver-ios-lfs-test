

//
//  PreviewPDFController.m
//  Survey
//
//  Created by Tony Brame on 4/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreviewPDFController.h"
#import <BRPtouchPrinterKit/BRPtouchPrinter.h>
#import "SurveyAppDelegate.h"
#import "Prefs.h"
#import "GetReport.h"
#import "PVOSignature.h"
#import "PVOUploadReportView.h"
#import "SurveyCustomer.h"
#import "MBProgressHUD.h"
#import "CustomerUtilities.h"
#import "PVOPrintController.h"
#import "PVONavigationListItem.h"

#import "MMPDFWriter.h"
#import "PVODrawer.h"
#import "ArpinPVODrawer.h"
#import "AtlasNetPVODrawer.h"
#import "PVOAutoInventorySignController.h"
#import "PVOBulkyInventorySignController.h"
#import "PDFXMLParser.h"
#import "AppFunctionality.h"
#import "CustomerListItem.h"
#ifdef ATLASNET
#import "CNGOVSignatureValidation.h"
#endif

@implementation PreviewPDFController

@synthesize pdfView, pdfPath, signatureController, option, delegate, viewProgress, uploader, esignView, disconnectedDrawer, additionalReportInfo, signedReport, docsToUpload;
@synthesize pj673PrintSettings;
@synthesize useDisconnectedReports;
@synthesize hideActionsOptions;
@synthesize signatureName;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


- (NSString *)fetchSSID
{
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    //NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    NSDictionary *info = nil;
    NSString *theSSID = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        //NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        if ([info valueForKey:@"SSID"])
        {
            theSSID = [NSString stringWithString:[info valueForKey:@"SSID"]];
        }
        
        if (info && [info count]) {
            break;
        }
    }
    return theSSID;
}

- (size_t)getPDFPageCount: (NSURL *)pdfURL
{
    
    // Open PDF File to get page count
    CGPDFDocumentRef pdfDocRef;
    size_t pdfPageCount=0;
    pdfDocRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    if (pdfDocRef != NULL)
    {
        pdfPageCount = CGPDFDocumentGetNumberOfPages(pdfDocRef);
        CGPDFDocumentRelease(pdfDocRef);
    }
    
    return pdfPageCount;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.title = @"Preview";
    
    actionSheetOptions = nil;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(optionsClick:)];
    
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    viewHasDisappeared = NO;
    
    if(movingFromEsignToSignature)
    {
        [super viewWillAppear:animated];
        return;
    }
    
    //    [self.pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    [pdfView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
    
    UIBarButtonItem *signButton;
    if (self.noSignatureAllowed || [self.pvoItem hasSignatureType:-1])
    {
        signButton = nil;
    }
    else
    {
        signButton = [[UIBarButtonItem alloc] initWithTitle:@"Sign"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(sign:)];
    }
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithTitle:@"Actions"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(optionsClick:)];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                  target:self
                                                                                  action:@selector(share:)];
    
    if ([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)])
    {
        if (hideActionsOptions)
        {
            self.navigationItem.rightBarButtonItems = nil;
            self.navigationItem.rightBarButtonItem = shareButton;
        }
        else if (signButton == nil)
        {
            self.navigationItem.rightBarButtonItems = @ [ actionButton, shareButton ];
        }
        else
        {
            self.navigationItem.rightBarButtonItems = @ [ actionButton, signButton, shareButton ];
        }
    }
    else
    {
        if (hideActionsOptions)
        {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else
        {
            UIToolbar *tools = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 133, 44.01)];
            NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:2];
            if (signButton != nil)
            {
                [buttons addObject:signButton];
            }
            
            [buttons addObject:actionButton];
            [tools setItems:buttons animated:NO];
            tools.barStyle = -1;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tools];
        }
    }
    
    //need to clear this out, always re-pull when we load the screen.
    if (self.pvoItem.reportTypeID == VIEW_BOL)
        pdfPath = nil;
    
    if(pdfPath == nil || [pdfPath length] == 0 ||
       (signatureController != nil && signatureController.confirmedSignature))
    {//reload the document
        pdfView.hidden = YES;
        viewProgress.hidden = NO;
        loadingReport = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    else
    {
        viewProgress.hidden = YES;
        pdfView.hidden = NO;
        [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
    }
    
    [super viewWillAppear:animated];
    
    [del.window bringSubviewToFront:self.navigationController.view];
    
    //[del.operationQueue cancelAllOperations];
    if(reportObject != nil)
    {
        [reportObject cancel];
        reportObject = nil;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(movingFromEsignToSignature)
    {
        [self sign:nil];
        [super viewDidAppear:animated];
        movingFromEsignToSignature = FALSE;
        return;
    }
    
    if(!self.pvoItem.hasRequiredSignatures) {
        [self.pvoItem setReportWasUploaded:NO forCustomer:del.customerID];
    }
    
    bool uploadBulkyReport = false;
    
    if(_uploadAfterSigning || uploadBulkyReport) {
        [self beginDocUpload];
    } else {
        [self beginGatheringReport:self.pvoItem.reportTypeID withIsForUpload:NO];
    }
    
    
    [super viewDidAppear:animated];
}

-(void)beginGatheringReport:(int)reportTypeID withIsForUpload:(BOOL)generatingForUpload
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL generateReportWithOption = FALSE;
    if(pdfPath == nil || [pdfPath length] == 0)
    {
        if (!generatingForUpload)
        {
            disconnectedReports = FALSE;
            supportsDisconnected = FALSE;
            switch ([del.pricingDB vanline]) {
                case ARPIN:
                    self.disconnectedDrawer = [[ArpinPVODrawer alloc] init];
                    break;
                case ATLAS:
                    self.disconnectedDrawer = [[AtlasNetPVODrawer alloc] init];
                    break;
                default:
                    self.disconnectedDrawer = [[PVODrawer alloc] init];
                    break;
            }
            if(disconnectedDrawer != nil)
                supportsDisconnected = [[disconnectedDrawer availableReports] objectForKey:[NSNumber numberWithInt:reportTypeID]] != nil;
        }
        
        //[pdfView loadRequest:nil];
        //[pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [pdfView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
        
        if([del.pricingDB vanline] == ATLAS && reportTypeID == VIEW_BOL)
        {
            PVOSync *sync = [[PVOSync alloc] init];
            
            DriverData *driverInfo = [del.surveyDB getDriverData];
            ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:del.customerID];
            if(((driverInfo.driverNumber == nil || [driverInfo.driverNumber length] == 0) &&
                (driverInfo.haulingAgent == nil || [driverInfo.haulingAgent length] == 0)) ||
               shipInfo.orderNumber == nil || [shipInfo.orderNumber length] == 0)
            {
                [SurveyAppDelegate showAlert:@"A driver number and order number are required for downloading the BOL." withTitle:@"Required Fields"];
                [self.navigationController popViewControllerAnimated:YES];
                return;
            }
            sync.additionalParamInfo = additionalReportInfo;
            sync.orderNumber = shipInfo.orderNumber;
            sync.syncAction = PVO_SYNC_ACTION_DOWNLOAD_BOL;
            sync.updateWindow = self;
            sync.updateCallback = @selector(bolUpdateProgress:);
            sync.completedCallback = @selector(bolSuccess);
            sync.errorCallback = @selector(bolError);
            
            [del.operationQueue addOperation:sync];
            
        }
        else if (reportTypeID >= 9000) { // this is Gypsy moth
            [self loadReadonlyPDFReport:reportTypeID];
        }
        else
        {
            WebSyncRequest *req = [[WebSyncRequest alloc] init];
            req.type = WEB_REPORTS;
            req.functionName = @"GetPVOReport";
            //req.serverAddress = @"print.moverdocs.com";
            req.serverAddress = @"homesafe-win.movehq.com";

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
            
            NSString *dest;
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSString stringWithFormat:@"%d", [del.pricingDB vanline]] forKey:@"vanLineId"];
            [dict setObject:[NSString stringWithFormat:@"%d", reportTypeID] forKey:@"reportID"];
            if (([Prefs reportsPassword] == nil || [[Prefs reportsPassword] length] == 0) && [AppFunctionality defaultReportingServiceCustomReportPass] != nil)
                [dict setObject:[AppFunctionality defaultReportingServiceCustomReportPass] forKey:@"customReportsPassword"];
            else
                [dict setObject:[Prefs reportsPassword] == nil ? @"" : [Prefs reportsPassword] forKey:@"customReportsPassword"];
            if([req getData:&dest withArguments:dict needsDecoded:YES withSSL:YES])
            {
                NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[dest dataUsingEncoding:NSUTF8StringEncoding]];
                ReportOptionParser *xmlParser = [[ReportOptionParser alloc] init];
                parser.delegate = xmlParser;
                [parser parse];
                
                //now I have the option, generate the report...
                if([xmlParser.entries count] > 0)
                {
                    self.option = [xmlParser.entries objectAtIndex:0];
                    self.option.reportTypeID = reportTypeID;
                    option.reportLocation = xmlParser.address;
                    
                    generateReportWithOption = TRUE;
                }
                else
                {
                    disconnectedReports = YES;
                }
            }
            else
            {
                //need to pull the reportID for the type
                ReportOption *html = [del.surveyDB getHTMLReportDataForReportType:reportTypeID];
                if(html != nil && [del.surveyDB htmlReportExists:html])
                {//found file previously downloaded
                    self.option = html;
                    self.option.htmlSupported = YES;
                }
                else//continue with legacy method
                    disconnectedReports = TRUE;
                
            }
            //test code to force disconnected...
            if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcedisc?"].location != NSNotFound && useDisconnectedReports)
            {
                generateReportWithOption = FALSE;
                disconnectedReports = TRUE;
            }
            if([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"forcedisc"].location != NSNotFound)
            {
                generateReportWithOption = !useDisconnectedReports;
                disconnectedReports = useDisconnectedReports;
            }
            BOOL isAtlas = [del.pricingDB vanline] == ATLAS;
            BOOL isInventory = self.option.reportTypeID == 1 || self.option.reportTypeID == 6;
            BOOL isBetween113and120 = [[[UIDevice currentDevice] systemVersion] compare:@"11.3" options:NSNumericSearch] != NSOrderedAscending && [[[UIDevice currentDevice] systemVersion] compare:@"12.0" options:NSNumericSearch] == NSOrderedAscending;
            BOOL htmlSupported = self.option.htmlSupported;
            
            if(disconnectedReports && supportsDisconnected)
            {
                self.pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
                
                MMPDFWriter *writer = [[MMPDFWriter alloc] init];
                [disconnectedDrawer setReportID:reportTypeID];
                [writer createPDF:pdfPath withDrawer:disconnectedDrawer];
                
                viewProgress.hidden = YES;
                pdfView.hidden = NO;
                
                [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
                
                //be sure to clear this flag only used for connceted upload currently...
                signedReport = NO;
            }
            else if(disconnectedReports && !supportsDisconnected)
            {
                self.pdfPath = nil;
                //[SurveyAppDelegate showAlert:dest withTitle:@"Reports currently unavailable"];
                [SurveyAppDelegate showAlert:@"An error occurred trying to generate online reports.  "
                 "Please verify your network connection and try again."
                                   withTitle:@"Error"];
                //[pdfView loadRequest:nil];
                //[pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
                [pdfView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
            }
            else if(htmlSupported && (!isAtlas || (!isInventory || !isBetween113and120)))
            //only run HTML version if not atlas, or atlas non-inventory.  Also run if Atlas Inventory, but below iOS version 11.3 or above iOS version 12.0
            {//connected, check the HTML version
                generateReportWithOption = NO;
                if(!generatingForUpload && (![del.surveyDB htmlReportIsCurrent:self.option] || ![del.surveyDB htmlReportExists:self.option]))
                {//download the latest and update databases, files
                    if(htmlDownloader == nil)
                        htmlDownloader = [[DownloadFile alloc] init];
                    htmlDownloader.unzipFile = NO;
                    htmlDownloader.downloadURL = self.option.htmlBundleLocation;
                    htmlDownloader.caller = self;
                    htmlDownloader.messageCallback = @selector(updateFromDownload:);
                    [htmlDownloader start];
                }
                else
                    [self loadHTMLReport:reportTypeID withIsForUpload:generatingForUpload];
            }
        }
        //            
            
        loadingReport = NO;
    }
    else if(signatureController != nil && signatureController.confirmedSignature)
    {
        //regenerate the document, don't close the window...
        if(delegate != nil && [delegate respondsToSelector:@selector(finishedShowingPreview:withAction:)])
            [delegate finishedShowingPreview:self withAction:PREVIEW_PDF_ACTION_RELOAD_DOC];
        
        generateReportWithOption = TRUE;
    }
    
    if(generateReportWithOption)
    {
        //start the thread on the operation queue
        reportObject = [[GetReport alloc] init];
        reportObject.emailReport = FALSE;
        
        reportObject.caller = self;
        if (generatingForUpload)
            reportObject.updateCallback = @selector(uploadDocGenerated:);
        else
            reportObject.updateCallback = @selector(updateFromGetReport:);
        reportObject.option = option;
        reportObject.pvoNavItemID = self.pvoItem.navItemID;
        [del.operationQueue addOperation:reportObject];
    }
}

-(void)updateFromDownload:(NSString*)message
{
    
    if([message rangeOfString:@"Completed Download!"].location != NSNotFound)
    {
        //copy to the correct destination.
        NSFileManager *mgr = [NSFileManager defaultManager];
        
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        NSString *reportsDir = [docsDir stringByAppendingPathComponent:HTML_FILES_LOCATION];
        NSString *thisReportDir = [reportsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", self.option.reportTypeID]];
        
        //make sure the dir exists
        if(![mgr fileExistsAtPath:thisReportDir])
            [mgr createDirectoryAtPath:thisReportDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *destFileLocation = [thisReportDir stringByAppendingPathComponent:[htmlDownloader.fullFilePath lastPathComponent]];
        
        //delete the existing file if it exists
        if([mgr fileExistsAtPath:destFileLocation])
            [mgr removeItemAtPath:destFileLocation error:nil];
        
        //copy file to new path
        [mgr copyItemAtPath:htmlDownloader.fullFilePath toPath:destFileLocation error:nil];
        
        //delete original file
        [mgr removeItemAtPath:htmlDownloader.fullFilePath error:nil];
        
        //save current revision to databases
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB saveHTMLReport:self.option];
        
        [self loadHTMLReport];
    }
    else if([message rangeOfString:@"Error"].location != NSNotFound)
    {
        [SurveyAppDelegate showAlert:message withTitle:@"Error Downloading HTML Bundle"];
    }
}

-(void)loadHTMLReport
{
    [self loadHTMLReport:self.pvoItem.reportTypeID withIsForUpload:NO];
}

-(void)loadHTMLReport:(int)reportTypeID withIsForUpload:(BOOL)generatingForUpload
{
    int nID = self.pvoItem.navItemID;
    if(self.uploadingDirtyReports){
        nID = [docsToUpload[0] intValue];
    }
    
    //get the latest info for the report from the database
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.option = [del.surveyDB getHTMLReportDataForReportType:reportTypeID];
    
    // TODO: Fix this eventually.  Releasing here breaks multiple doc upload.
    //[htmlGenerator release];
    htmlGenerator = [[HTMLReportGenerator alloc] init];
    htmlGenerator.delegate = self;
    htmlGenerator.pvoReportTypeID = reportTypeID;
    htmlGenerator.pvoReportID = self.option.reportID;
    htmlGenerator.generatingReportForUpload = generatingForUpload;
    htmlGenerator.pageSize = self.option.pageSize;
    
    
    [htmlGenerator generateReportWithZipBundle:self.option.htmlBundleLocation
                                containingHTML:self.option.htmlTargetFile
                                   forCustomer:del.customerID
                               forPVONavItemID:nID
                          withImageDisplayType:self.pvoItem.imageDisplayType];
    
}

-(void)updateFromGetReport:(NSString*)result
{
    if (!viewHasDisappeared)
    {
        self.pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        if(![result isEqualToString:@"start printing disconnected"] &&
           ![result isEqualToString:@"Successfully saved file."])
        {
            [SurveyAppDelegate showAlert:@"An error occurred trying to generate online reports.  "
             "Please verify your network connection and try again."
                               withTitle:@"Error"];
            //[SurveyAppDelegate showAlert:result withTitle:@"Get Report Error"];
        }
        else
        {
            loadingReport = FALSE;
            
            viewProgress.hidden = YES;
            pdfView.hidden = NO;
            
            [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
            
            if ([AppFunctionality autoUploadInventoryReportOnSign])
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
                if(signedReport &&
                   ([self.pvoItem hasSignatureType:PVO_SIGNATURE_TYPE_DEST_INVENTORY] ||
                    ([self.pvoItem hasSignatureType:PVO_SIGNATURE_TYPE_ORG_INVENTORY] && inv.inventoryCompleted)))
                {
                    saveToServerAfterLoad = YES;
                }
                //[inv release];
            }
            signedReport = NO;
            
        }
        
        if (saveToServerAfterLoad && !disconnectedReports)
        {
            [self beginDocUpload];
        }
    }
}

-(void)beginDocUpload
{
    [self beginActualDateUploadForSignedReport];
    
    saveToServerAfterLoad = NO;
    
    NSString *syncTitle = @"Uploading Report";
    
    self.uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:syncTitle];
    
    uploader = [[PVOUploadReportView alloc] init];
    
    uploader.delegate = self;
    uploader.suppressLoadingScreen = YES;
    
    docsToUpload = [[NSMutableArray alloc] init];
    
    currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    //if the user ran the inventory report, also upload the pack per inventory. I'm uploading PPI first so that the current report is last, and the report.pdf file is the current report
    if ([AppFunctionality autoUploadPPIAfterInventory] && self.pvoItem.reportTypeID == INVENTORY)
        [docsToUpload addObject:[NSNumber numberWithInt:PACK_PER_INVENTORY]];
    
    
    [docsToUpload addObject:[NSNumber numberWithInt:self.pvoItem.reportTypeID]];
    
    [self uploadNextDoc];
}

-(void)uploadAllDirtyReports
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    while([docsToUpload count] == 0){
        
        if([self.customers count] == 0 && [docsToUpload count] == 0){
            if (delegate != nil && [delegate respondsToSelector:_allDirtyReportsFinishedUploading]){
                [delegate performSelector:_allDirtyReportsFinishedUploading];
            }
            return;
        }
        
        self.pvoItem = [[PVONavigationListItem alloc] init];
        self.pvoItem.custID = [(CustomerListItem*)[self.customers objectAtIndex:0] custID];
        docsToUpload = [del.surveyDB getAllDirtyReportsForCustomer:self.pvoItem.custID];
        [self.customers removeObjectAtIndex:0];
    }
    
#ifdef SIRVA_QPD
    // SIRVA FEATURE REQUEST 4373
    if([[docsToUpload objectAtIndex:0] intValue] == INVENTORY) {
        if ([[del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_ITEMS withSubID:-1 loadAllItems:NO loadAllForType:YES] count] > 0) {
            [docsToUpload addObject:[NSNumber numberWithInt:INVENTORY_SIRVA_NO_IMAGES]];
        }
    }
#endif
    
    del.customerID = self.pvoItem.custID;
    self.pvoItem.reportTypeID = [del.pricingDB getReportIDFromNavID:[docsToUpload[0] intValue]];
    self.pvoItem.navItemID = [docsToUpload[0] intValue];
    [self beginGatheringReport:self.pvoItem.reportTypeID withIsForUpload:YES];
}

-(void)uploadNextDoc
{
    if(self.uploadingDirtyReports){
        pdfPath = nil;
        
        if (delegate != nil && [delegate respondsToSelector:self.dirtyReportUploadFinished]){
            [delegate performSelector:self.dirtyReportUploadFinished];
        }
        
        [self uploadAllDirtyReports];
        return;
    }
    
    if([docsToUpload count] == 0)
    {
        [self.uploadProgress removeFromSuperview];
        
        viewProgress.hidden = YES;
        pdfView.hidden = NO;
        [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
        
        
        if (currentSyncMessage != nil && ![currentSyncMessage isEqualToString:@""])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Reports"
                                                            message:currentSyncMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            alert.tag = PREVIEW_PDF_ALERT_IMAGEUPLOADFINISHED;
            [alert show];
        }
        
        return;
    }
    
    
    int reportToGenerate = [[docsToUpload objectAtIndex:0] intValue];
    
    pdfPath = nil;
    [self beginGatheringReport:reportToGenerate withIsForUpload:YES];
    
}

-(void)uploadDocGenerated:(NSString*)update
{
    if (!viewHasDisappeared)
    {
        self.pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        if(update != nil && ![update isEqualToString:@"start printing disconnected"] &&
           ![update isEqualToString:@"Successfully saved file."])
        {
            [SurveyAppDelegate showAlert:update withTitle:@"Upload Generate Error"];
            [self.uploadProgress removeFromSuperview];
        }
        else
        {
            int additionalParamInfo = self.pvoItem.navItemID;
            //        [uploader release];
            //im showing my own loading screen.
            currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
            uploader = [[PVOUploadReportView alloc] init];
            uploader.suppressLoadingScreen = YES;
            uploader.delegate = self;
            uploader.updateCallback = @selector(updateProgress:);
            
            // Code from here to bottom of method fixes an issue where non-HTML reports were being uploaded with the wrong report ID
            
            // Set up report number
            int reportID;
            
            // To support non-HTML reports, check if the latest report is not an HTML report
            BOOL lastReportWasNotHTMLReport = htmlGenerator.pvoReportID == -1 ? YES : NO;
            // The || htmlGenerator == nil was added to resolve OT 20774
            // Without the or clause, if the user uploads a non-html report first it will think
            // that it is an HTML report
            if(lastReportWasNotHTMLReport || htmlGenerator == nil) {
                // Show latest non-HTML report
                reportID = self.pvoItem.reportTypeID;
            } else {
                // Show HTML generator's last generated report number
                reportID = htmlGenerator.pvoReportTypeID;
            }
            
            // Upload the report with the specified ID
            [uploader uploadDocument:reportID withAdditionalInfo:additionalParamInfo];
            
            // Reset the HTML generator's last generated report id so there is not a latent value
            htmlGenerator.pvoReportID = -1;
            
        }
    }
}




/*-(void)didRotate:(NSNotification *)notification
 {
 [pdfView reload];
 
 if([SurveyAppDelegate iPad])
 {
 UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
 CGAffineTransform transform;
 if(orientation == UIInterfaceOrientationLandscapeRight)
 transform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
 else
 transform = CGAffineTransformMakeRotation(M_PI/2);
 self.view.transform = transform;
 CGRect contentRect;
 
 // Repositions and resizes the view.
 if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
 contentRect = CGRectMake(0, 20, 768, 1004);
 else
 contentRect = CGRectMake(0, 20, 1024, 748);
 
 self.view.frame = contentRect;
 }
 }*/


-(IBAction)share:(id)sender
{
    if(self.pdfPath == nil)
    {
        [SurveyAppDelegate showAlert:@"Report must load prior to performing actions." withTitle:@"Report Loading"];
        return;
    }
    
    NSData *pdfData = [NSData dataWithContentsOfFile:self.pdfPath];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[pdfData] applicationActivities:nil];
    //    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard];
    
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    //[self presentViewController:activityViewController animated:YES completion:nil];
    //[self presentViewController:activityViewController animated:YES completion:nil];
}

-(IBAction)sign:(id)sender
{
    
    //if pvo, check to see if esign agreement is required first.
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!movingFromEsignToSignature)
    {
        NSString *esignText = [del.pricingDB pvoEsignAlertRequired];
        if(![self.pvoItem hasSignatureType:-1] && esignText && ![self.pvoItem hasSignatureType:PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT])
        {
            //check to see if esign doc exists, and has been signed...
            if([del.pricingDB pvoContainsNavItem:PVO_P_ESIGN_AGREEMENT])
            {
                PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ESIGN_AGREEMENT];
                if(sig == nil)
                {
                    [SurveyAppDelegate showAlert:@"You must have the E-Sign agreement signed prior to applying any electronic signatures." withTitle:@"E-Sign Required"];
                    return;
                }
            }
            
            //present the user with the esign info
            if(esignView == nil)
            {
                esignView = [[TextAlertViewController alloc] initWithNibName:@"TextAlertView" bundle:nil];
                esignView.delegate = self;
            }
            
            
            esignView.title = @"ESign Agreement";
            esignView.textToView = esignText;
            
            //this didn't display correctly, the title and done button were smashed up into the status bar
            //            [self presentViewController:esignView animated:YES completion:nil];
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:esignView];
            [self presentViewController:newNav animated:YES completion:nil];
            
            
            return;
        }
    }
    
    BOOL continu = TRUE;
    if(self.pvoItem.reportTypeID == INVENTORY)
    {
#ifdef ATLASNET
        // if the order is Canadian government, check to make sure all surveyed items are inventoried
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        if (cust.pricingMode == CNGOV)
        {
            CNGOVSignatureValidation *signatureValidation = [[CNGOVSignatureValidation alloc] init];
            BOOL isOK = [signatureValidation validate:del.customerID];
            [signatureValidation release];
            if (!isOK)
            {
                [SurveyAppDelegate showAlert:@"Not all Non-CP/PBO items on the survey have been inventoried.  You must inventory all Non-CP/PBO items prior to gathering a customer signature." withTitle:@"Missing Items"];
                return;
            }
        }
#endif
        
        //check to see if the inventory is completed.
        PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
        PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
        
        if([del.surveyDB getPVOReceivedItemsType:del.customerID] == PACKER_INVENTORY &&
           [del.surveyDB getPVOReceivableItems:del.customerID].count > 0)
        {
            continu = FALSE;
            [SurveyAppDelegate showAlert:@"You have receivable Packer's Inventory Items.  All Packer's Inventory items must be received prior to capturing customer signature." withTitle:@"Packer's Inventory"];
        }
        
        if(continu && [AppFunctionality mustEnterMilitaryItemWeights:inv])
        {
            NSMutableArray *missingWeightTypes = [[NSMutableArray alloc] init];
            if (inv.mproWeight <= 0 && [del.surveyDB getPVOItemCountMpro:del.customerID] > 0)
            {
                [missingWeightTypes addObject:@"MPRO"];
            }
            if (inv.sproWeight <= 0 && [del.surveyDB getPVOItemCountSpro:del.customerID] > 0)
            {
                [missingWeightTypes addObject:@"SPRO"];
            }
            if (inv.consWeight <= 0 && [del.surveyDB getPVOItemCountCons:del.customerID] > 0)
            {
                [missingWeightTypes addObject:@"CONS"];
            }
            
            if ([missingWeightTypes count] > 0)
            {
                continu = FALSE;
                [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"You have %1$@ Inventory Items.  The %1$@ items weight must be populated on the Item Detail screen prior to capturing customer signature.",
                                              [missingWeightTypes componentsJoinedByString:@", "]] withTitle:@"Military Items"];
                return;
            }
        }
        
        if(continu && !inv.inventoryCompleted)
        {
            continu = FALSE;
            
            BOOL includeContinueOption = YES;
            NSString *message = @"This inventory is not yet completed, would you like to complete the inventory and gather customer signature, or continue with the inventory and gather signature now?";
            
            if ([AppFunctionality removeSignatureOnNavigateIntoCompletedInv])
            {
                includeContinueOption = NO;
                message = @"This inventory has not yet been completed, would you like to complete the inventory and gather customer signature now, or continue with the inventory?";
            }
            
            if(sig != nil)
                message = [message stringByAppendingString:@" NOTE: Existing signature will be removed!"];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mark as Complete?"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Complete", (includeContinueOption ? @"Continue" : nil), nil];
            alert.tag = PREVIEW_PDF_ALERT_COMPLETE;
            [alert show];
        }
        
        if(continu && sig != nil)
        {
            continu = FALSE;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Remove Signature?"
                                                            message:@"A signature for this document already exists. By continuing, you will remove the signature. Would you like to continue?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Continue", nil];
            alert.tag = PREVIEW_PDF_ALERT_REMOVESIG;
            [alert show];
        }
    }
    else
    {
        
    }
    
    if(continu)
    {
        [self promptForOrShowSignatureView];
    }
}

-(void)promptForOrShowSignatureView
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([self.pvoItem.signatureIDs componentsSeparatedByString:@","].count > 1)
    {///ask what kind they want to capture (if there's more than 1...)
        NSMutableArray *sigOptions = [NSMutableArray array];
        
        for (NSString *sigid in [self.pvoItem.signatureIDs componentsSeparatedByString:@","]) {
            [sigOptions addObject:[del.pricingDB getPVOSignatureDescription:[sigid intValue]]];
        }
        
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Please select which signature to enter"
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:nil];
        
        for (NSString *str in sigOptions) {
            [as addButtonWithTitle:str];
        }
        
        [as addButtonWithTitle:@"Cancel"];
        as.cancelButtonIndex = [sigOptions count];
        as.tag = PREVIEW_PDF_ACTION_SHEET_SIG_TYPE;
        [as showInView:self.view];
    }
    else if (self.pvoItem.reportTypeID == BULKY_INVENTORY_ORIG || self.pvoItem.reportTypeID == BULKY_INVENTORY_DEST)
    {
        PVOBulkyInventorySignController *bulkySignatureController = [[PVOBulkyInventorySignController alloc] initWithStyle:UITableViewStyleGrouped];
        bulkySignatureController.pvoNavItem = self.pvoItem;
        
        [SurveyAppDelegate setDefaultBackButton:self];
        [self.navigationController pushViewController:bulkySignatureController animated:YES];
    }
    else
    {
        capturingSignatureID = [[[self.pvoItem.signatureIDs componentsSeparatedByString:@","] objectAtIndex:0] intValue];
        [self continueToSignatureCapture];
    }
}

-(void)continueToSignatureCapture
{
    if ([PVONavigationListItem signatureRequiresTypedFullName:capturingSignatureID])
    {
        [self showTypeFullNameForSignature];
    }
    else
    {
        [self showSignatureView];
    }
}

-(void)showTypeFullNameForSignature
{
    //need to reload this each time. This will cause the first customer name thats loaded to show on every customer
    if (self.singleFieldController != nil)
    {
        self.singleFieldController = nil;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    NSString *customerName = [NSString stringWithFormat:@"%@ %@", cust.firstName, cust.lastName];
    
    self.singleFieldController = [[SingleFieldController alloc] initWithStyle:UITableViewStyleGrouped];
    self.singleFieldController.caller = self;
    self.singleFieldController.callback = @selector(doneEditing:);
    self.singleFieldController.placeholder = @"Type Full Name Here";
    self.singleFieldController.title = customerName;
    
    [self.navigationController pushViewController:self.singleFieldController animated:YES];
    
}

-(void) doneEditing:(NSString*)newValue
{
    signatureName = newValue;
    if (signatureName == nil || [signatureName length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printed Name Required"
                                                        message:@"A Printed Name is required to enter a signature for the signature."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    [self showSignatureView];
}

-(void)showSignatureView
{
    
    if(self.pvoItem.reportTypeID == INVENTORY)
    {
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        //clear out any items marked as inventoried after signature... if the customer is signing now, then all items are verified (this covers the case where the shipper comes back)...
        [del.surveyDB setPVOItemsInventoriedBeforeSignature:del.customerID];
        
        [del.surveyDB deletePVOSignature:del.customerID forImageType:PVO_SIGNATURE_TYPE_ORG_INVENTORY];
        
    }
    
    if(signatureController == nil)
        signatureController = [[SignatureViewController alloc] initWithNibName:@"SignatureView" bundle:nil];
    
    signatureController.delegate = self;
    signatureController.requireSignatureBeforeSave = self.pvoItem.reportTypeID == ESIGN_AGREEMENT;
    signatureController.saveBeforeDismiss = YES;
    signatureController.sigType = capturingSignatureID;
    
    if (self.pvoItem.navItemID == PREVIEW_PDF_E_VERIFY) { // OnTime Defect: 11796
        signatureController.requireSignatureBeforeSave = YES;
    }
    
    sigNav = [[LandscapeNavController alloc] initWithRootViewController:signatureController];
    
    [self presentViewController:sigNav animated:YES completion:nil];
    
}

-(void)reportNotesEntered:(NSString*)reportNotes
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PVOReportNote *r = [[PVOReportNote alloc] init];
    r.reportNote = reportNotes;
    r.pvoReportNoteTypeID = self.pvoItem.reportNoteType;
    
    [del.surveyDB saveReportNotes:r forCustomer:del.customerID];
}

-(IBAction)optionsClick:(id)sender
{
    if(self.pdfPath == nil)
    {
        [SurveyAppDelegate showAlert:@"Report must load prior to performing actions." withTitle:@"Report Loading"];
        return;
    }
    
    UIActionSheet *as = nil;
    
    actionSheetOptions = [[NSMutableArray alloc] init];
    
    [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_EMAIL]];
    
    if (!self.noSaveOptionsAllowed && ![AppFunctionality disableDocumentsLibrary])
        [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_EMAIL_SAVE]];
    
    [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_PRINT]];
    
    if (self.pvoItem.reportNoteType > 0)
        [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_REPORT_NOTES]];
    
    if(!self.noSaveOptionsAllowed && ![AppFunctionality disableDocumentsLibrary])
        [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_PRINT_SAVE]];
    
    if ([AppFunctionality allowReportUploadFromPreview:[CustomerUtilities customerPricingMode]])
        [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_UPLOAD]];
    
    if(!self.noSaveOptionsAllowed && ![AppFunctionality disableDocumentsLibrary])
        [actionSheetOptions addObject:[NSNumber numberWithInt:PREVIEW_PDF_ACTION_SAVE_TO_LIB]];
    
    NSMutableArray *optionText = [NSMutableArray array];
    
    for (NSNumber *choice in actionSheetOptions) {
        switch ([choice intValue]) {
            case PREVIEW_PDF_ACTION_SIGN:
                [optionText addObject:@"Sign"];
                break;
            case PREVIEW_PDF_ACTION_EMAIL:
                [optionText addObject:@"Email"];
                break;
            case PREVIEW_PDF_ACTION_PRINT:
                [optionText addObject:@"Print"];
                break;
            case PREVIEW_PDF_ACTION_REPORT_NOTES:
                [optionText addObject:@"Report Notes"];
                break;
            case PREVIEW_PDF_ACTION_UPLOAD:
                [optionText addObject:@"Upload"];
                break;
            case PREVIEW_PDF_ACTION_EMAIL_SAVE:
                [optionText addObject:@"Email & Save"];
                break;
            case PREVIEW_PDF_ACTION_PRINT_SAVE:
                [optionText addObject:@"Print & Save"];
                break;
            case PREVIEW_PDF_ACTION_SAVE_TO_LIB:
                [optionText addObject:@"Save To Library"];
                break;
        }
    }
    
    as = [[UIActionSheet alloc] initWithTitle:@"Action to perform with report?"
                                     delegate:self
                            cancelButtonTitle:nil
                       destructiveButtonTitle:nil
                            otherButtonTitles:nil];
    
    for (NSString *str in optionText) {
        [as addButtonWithTitle:str];
    }
    
    [as addButtonWithTitle:@"Cancel"];
    as.cancelButtonIndex = [optionText count];
    as.tag = PREVIEW_PDF_ACTION_SHEET_OPTIONS;
    [as showInView:self.view];
}

-(void)viewWillDisappear:(BOOL)animated
{
    viewHasDisappeared = YES;
    //not sure why were doing this, just always regenerate. else you get stuck with the last disconnected report you ran.
    //    if (self.option != nil)//causes it to regenerate on return...
    self.pdfPath = nil;
    
    //[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [super viewWillDisappear:animated];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)savePDFToCustomerDocuments:(NSString *)path
{
    NSData *pdfData = [NSData dataWithContentsOfFile:path];
    [self savePDFDataToCustomerDocuments:pdfData];
    
}

- (NSString *)savePDFDataToCustomerDocuments:(NSData *)pdfData
{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DocLibraryEntry *current = [[DocLibraryEntry alloc] init];
    
    current.docEntryType = DOC_LIB_TYPE_CUST;
    current.customerID = del.customerID;
    current.url = @"";
    //for disconnected, need to get the report name...
    if (disconnectedReports && self.disconnectedDrawer != nil)
    {
        NSDictionary *options = [self.disconnectedDrawer availableReports];
        for (NSString *name in [options allKeys]) {
            if([[options objectForKey:name] intValue] == [self.disconnectedDrawer reportID])
                current.docName = name;
        }
    }
    else
        current.docName = [[self.navOptionText stringByReplacingOccurrencesOfString:@"View " withString:@""]
                           stringByReplacingOccurrencesOfString:@"Print " withString:@""];
    
    [current saveDocument:pdfData withCustomerID:del.customerID];
    return [[current fullDocPath] copy];
}

-(void)startServerSync
{
    [self startServerSync:YES];
}

-(void)startServerSync:(BOOL)withImages
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB removeAllCustomerSyncFlags];
    int vanline = [del.pricingDB vanline];
    
    NSString *syncTitle;
    if (vanline == ARPIN) {
        syncTitle = @"Saving To Arpin";
    } else if (vanline == ATLAS) {
        syncTitle = @"Saving To Atlas";
    } else {
        syncTitle = @"Saving To Server";
    }
    self.uploadProgress = [[SmallProgressView alloc] initWithDefaultFrame:syncTitle];
    
    PVOSync *sync = [[PVOSync alloc] init];
    
    SurveyCustomerSync *custSync = [del.surveyDB getCustomerSync:del.customerID];
    custSync.syncToPVO = YES;
    [del.surveyDB updateCustomerSync:custSync];
    
    sync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORIES;
    
    sync.updateWindow = self;
    sync.uploadPhotosWithInventory = withImages;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncError);
    
    currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    [del.operationQueue addOperation:sync];
}

-(void)updateProgress:(NSString*)textToAdd
{
    //allocate this if zombie
    if (currentSyncMessage == nil)
        currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    if([currentSyncMessage isEqualToString:@""])
        [currentSyncMessage appendString:textToAdd];
    else
        [currentSyncMessage appendString:[NSString stringWithFormat:@"\r\n%@", textToAdd]];
}

-(void)syncCompleted
{
    [_uploadProgress removeFromSuperview];
    
    NSString *syncTitle = @"Save To Server";
#ifdef ATLASNET
    syncTitle = @"Save To Atlas";
#endif
    [SurveyAppDelegate showAlert:currentSyncMessage withTitle:syncTitle];
    //    [currentSyncMessage release];
    
}

-(void)startPrint
{
    [PJ673PrintSettings hasBrotherAttachedWithDelegate:self];
}

-(void)continueToPrint
{
    processReport.delegate = self;
    processReport.printType = PRINT_HARD_COPY;
    processReport.uploadAfterEmail = NO;
    
    if (brotherPrinterMode)
    {
        NSString *printPdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
        if (self.pdfPath != nil)
            printPdfPath = self.pdfPath;
        
        NSURL *pdfUrl = [NSURL fileURLWithPath:printPdfPath];
        NSLog(@"PDF is ready for Brother print");
        
        NSLog(@"Beginning the manual print");
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.labelText = @"Printing report";
        hud.detailsLabelText = @"Please wait...";
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        [self printPDFManually:pdfUrl progressView:hud];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        NSLog(@"Ending the manual print");
    }
    else
    {
        if ([AppFunctionality useAirPrintForPrinting])
        {
            UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
            printController.showsPageRange = YES;
            
            if([UIPrintInteractionController canPrintURL:[NSURL fileURLWithPath:self.pdfPath]])
            {
                printController.printingItem = [NSURL fileURLWithPath:self.pdfPath];
                [printController presentAnimated:YES completionHandler:nil];
            }
            else
                [SurveyAppDelegate showAlert:@"Cannot print document." withTitle:@"Print Error"];
        }
        else
        {
            processReport.reportOption = option;
            processReport.pvoNavItemID = self.pvoItem.navItemID;
            processReport.pdfPath = self.pdfPath;
            processReport.uploader = nil;
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:processReport];
            
            [self presentViewController:newNav animated:YES completion:nil];
        }
    }
}

-(void)emailFinishedSending:(ProcessReportController *)processReportController withUpdate:(NSString*)textToAdd
{
    currentSyncMessage = [[NSMutableString alloc] initWithString:@""];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([del.pricingDB vanline] == ATLAS)
    {
        [self updateProgress:textToAdd];
        if ( processReportController.uploadAfterEmail) {
            saveToServerAfterLoad = YES;
        }
    }
}

-(void)syncError
{
    [currentSyncMessage appendString:@"Error during upload."];
    
    [_uploadProgress removeFromSuperview];
    
    NSString *syncTitle = @"Save To Server";
#ifdef ATLASNET
    syncTitle = @"Save To Atlas";
#endif
    [SurveyAppDelegate showAlert:currentSyncMessage withTitle:syncTitle];
}

- (void)dealloc {
    currentSyncMessage = nil;
    self.pvoItem = nil;
}

#pragma mark - PVOUploadReportViewDelegate methods

-(void)uploadCompleted:(PVOUploadReportView*)uploadReportView
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self.pvoItem setReportWasUploaded:YES forCustomer:del.customerID];
    self.uploadAfterSigning = NO;
    
    int reportToGenerate = [[docsToUpload objectAtIndex:0] intValue];
    
    //found; reset dirty flags for current doc...
    int data = PVO_DATA_LOAD_ITEMS;
    if(reportToGenerate == LOAD_HIGH_VALUE)
        data = PVO_DATA_LOAD_HIGH_VALE;
    else if(reportToGenerate == DELIVERY_INVENTORY)
        data = PVO_DATA_DELIVER_ITEMS;
    else if(reportToGenerate == DEL_HIGH_VALUE)
        data = PVO_DATA_DELIVER_HIGH_VALUE;
    else if(reportToGenerate == ROOM_CONDITIONS)
        data = PVO_DATA_ROOM_CONDITIONS;
    
    [del.surveyDB pvoSetDataIsDirty:NO forType:data forCustomer:del.customerID];
    
    [docsToUpload removeObjectAtIndex:0];
    
    ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
    
    PVOSync* sync = [[PVOSync alloc] init];
    sync.syncAction = PVO_SYNC_ACTION_UPDATE_ORDER_STATUS;
    sync.orderStatus = [ShipmentInfo getStatusString:info.status];
    sync.orderNumber = info.orderNumber;
    [del.operationQueue addOperation:sync];
    
    [self uploadNextDoc];
    //[self done:nil];
}

-(void)uploadError:(PVOUploadReportView *)uploadReportView
{
    saveToServerAfterLoad = NO;
    _uploadAfterSigning = NO;
    [docsToUpload removeObjectAtIndex:0];
    
    [self uploadNextDoc];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex != buttonIndex && actionSheet.tag == PREVIEW_PDF_ACTION_SHEET_SIG_TYPE)
    {
        capturingSignatureID = [[[self.pvoItem.signatureIDs componentsSeparatedByString:@","] objectAtIndex:buttonIndex] intValue];
        [self continueToSignatureCapture];
    }
    else if(actionSheet.cancelButtonIndex != buttonIndex && actionSheet.tag == PREVIEW_PDF_ACTION_SHEET_OPTIONS)
    {
        int selectedOption = [[actionSheetOptions objectAtIndex:buttonIndex] intValue];
        
        if(delegate != nil && [delegate respondsToSelector:@selector(finishedShowingPreview:withAction:)])
            [delegate finishedShowingPreview:self withAction:buttonIndex];
        
        if(selectedOption == PREVIEW_PDF_ACTION_SIGN)
        {
            [self sign:nil];
        }
        else if(selectedOption == PREVIEW_PDF_ACTION_UPLOAD)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Document?"
                                                            message:@"Are you sure you would like to Upload this document?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            [alert show];
        }
        else if(selectedOption == PREVIEW_PDF_ACTION_REPORT_NOTES)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            PVOReportNote *reportNotes = [del.surveyDB getReportNotes:del.customerID forType:self.pvoItem.reportNoteType];
            
            if(noteController == nil)
                noteController = [[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped];
            
            noteController.caller = self;
            noteController.callback = @selector(reportNotesEntered:);
            noteController.destString = (reportNotes == nil ? @"" : reportNotes.reportNote);
            noteController.description = @"Report Notes";
            noteController.navTitle = @"Report Notes";
            noteController.keyboard = UIKeyboardTypeASCIICapable;
            noteController.dismiss = YES;
            noteController.modalView = YES;
            noteController.noteType = NOTE_TYPE_CUSTOMER;
            noteController.maxLength = -1;
            
            newNav = [[PortraitNavController alloc] initWithRootViewController:noteController];
            
            [self.navigationController presentViewController:newNav animated:YES completion:nil];
        }
        else
        {//load process report
            
            if (selectedOption == PREVIEW_PDF_ACTION_EMAIL_SAVE || selectedOption == PREVIEW_PDF_ACTION_PRINT_SAVE ||
                selectedOption == PREVIEW_PDF_ACTION_SAVE_TO_LIB)
            {
                // save the PDF to the customer library
                [self savePDFToCustomerDocuments:self.pdfPath];
                
                if (selectedOption == PREVIEW_PDF_ACTION_SAVE_TO_LIB)
                {
                    [SurveyAppDelegate showAlert:@"Document successfuly saved." withTitle:@"Saved"];
                    return;
                }
            }
            
            if(processReport == nil) {
                processReport = [[ProcessReportController alloc] initWithNibName:@"ProcessReportView" bundle:nil];
            }
            processReport.uploadAfterEmail = YES;
            
            
            if(selectedOption == PREVIEW_PDF_ACTION_EMAIL || selectedOption == PREVIEW_PDF_ACTION_EMAIL_SAVE)
            {
                [self handleEmailAndSaveClick:(selectedOption == PREVIEW_PDF_ACTION_EMAIL_SAVE)];
            }
            else
            {
                //check if a brother printer is attached, then the delegate will continue to print
                [self startPrint];
            }
            
        }
    }
}

-(void)handleEmailAndSaveClick:(bool)save
{
    if(processReport == nil)
        processReport = [[ProcessReportController alloc] initWithNibName:@"ProcessReportView" bundle:nil];
    
    // Cannot send anything larger than 4mb.
    // Filesize increases after encoding...
    // Serve up error message if filesize before encoding > 3mb
    double fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:pdfPath error:nil] fileSize];
    if(fileSize > MAX_FILE_SIZE){
        
        double maxFileSize = MAX_FILE_SIZE/1000000;
        NSString *dfs = [NSString stringWithFormat:@"%.2f", fileSize/1000000];
        NSString *mfs = [NSString stringWithFormat:@"%.2f", maxFileSize];
        
        
        NSString *msg = [NSString stringWithFormat: @"Cannot email files larger than %@%@%@%@", mfs, @"MB. Your file is currently ", dfs, @"MB large."];
        
        [SurveyAppDelegate showAlert:msg withTitle:@"File Too Large"];
        return;
    }
    else if(disconnectedReports)
    {
        [SurveyAppDelegate showAlert:@"Emailing is disabled with disconnected printing.  Please connect to the internet to email documents." withTitle:@"Internet Required"];
        return;
    }
    
    
    processReport.delegate = self;
    processReport.printType = PRINT_EMAIL;
    
    processReport.pvoReportTypeID = self.pvoItem.reportTypeID;
    processReport.pvoNavItemID = self.pvoItem.navItemID;
    processReport.uploadAfterEmail = save;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get all the signatures, make sure it's all completed before it is uploaded.
    BOOL completed = save;
    /*
     for (NSString *sigid in [self.pvoItem.signatureIDs componentsSeparatedByString:@","]) {
     PVOSignature *retval = [del.surveyDB getPVOSignature:del.customerID forImageType:[sigid intValue]];
     
     // If no signature break
     if(retval == nil)
     {
     completed = NO;
     [SurveyAppDelegate showAlert:@"Document will not be uploaded without all necessary signatures." withTitle:@""];
     break;
     }
     else
     
     }
     */
    
    //used to flag the Process Report controller that the upload is required for Arpin
    //if disconnectedDrawer is nil, then it means we were passed a PDF to browse (such as a Doc Library entry)
    if(disconnectedDrawer != nil && completed)
        processReport.uploader = [[PVOUploadReportView alloc] init];
    else
        processReport.uploader = nil;
    
#ifdef SIRVA_QPD
    if(self.pvoItem.reportTypeID == INVENTORY)
    {
        processReport.uploader = nil;
    }
#endif
    processReport.reportOption = option;
    
                DriverData *data = [del.surveyDB getDriverData];
                if(data.driverType == PVO_DRIVER_TYPE_DRIVER) {
    processReport.ccEmails = [[del.surveyDB getDriverDataCCEmails] mutableCopy];
    processReport.bccEmails = [[del.surveyDB getDriverDataBCCEmails] mutableCopy];
                } else if(data.driverType == PVO_DRIVER_TYPE_PACKER){
                    processReport.ccEmails = [[del.surveyDB getDriverDataPackerCCEmails] mutableCopy];
                    processReport.bccEmails = [[del.surveyDB getDriverDataPackerBCCEmails] mutableCopy];
                }
    
    newNav = [[PortraitNavController alloc] initWithRootViewController:processReport];
    
    [self presentViewController:newNav animated:YES completion:nil];
}

#pragma mark - Brother printer methods

-(void) printPDFUsingProgressView: (NSURL *)pdfURL
{
    //    int iRet;
    //
    //    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    //
    //    if (pdfPageCount > 0)
    //    {
    //        // print using the Progress View.
    //        BMSPrinterDriver *brotherPrinter = [[BMSPrinterDriver alloc] initWithModel:kPrinterModelPJ673
    //                                                                     printSettings:pj673PrintSettings];
    //
    //        // Specify page range if desired, otherwise this will print ALL pages.
    //        iRet = [brotherPrinter printPDFFileWithProgressView:pdfURL
    //                                                  firstPage:1
    //                                                   lastPage:pdfPageCount
    //                                            usingParentView:self];
    //
    //        [brotherPrinter release];
    //    }
    
    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    
    if (pdfPageCount > 0)
    {
        // print using the Progress View.
        if(pj673PrintSettings.IPAddress == nil || pj673PrintSettings.IPAddress.length == 0)
        {
            [SurveyAppDelegate showAlert:@"Please enter the IP Address for your printer from the Maintenance menu on the Customers screen." withTitle:@"IP Address Required"];
            return;
        }
        
        BRPtouchPrinter *ptp = [[BRPtouchPrinter alloc] initWithPrinterName:@"Brother PJ-673"];
        
        [ptp setIPAddress:pj673PrintSettings.IPAddress];
        
        [ptp setPrintInfo:[PJ673PrintSettings defaultPrintInfo]];
        
        NSUInteger pageIndexes[] = {0};
        if ([ptp isPrinterReady])
            [ptp printPDFAtPath:pdfURL.path pages:pageIndexes length:0 copy:1 timeout:500];
        else
            [SurveyAppDelegate showAlert:@"Please check network settings, and connection with printer." withTitle:@"Printer Not Ready"];
        
    }
}

-(void) printPDFManually:(NSURL *)pdfURL progressView:(MBProgressHUD *)hud
{
    //    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    //
    //    // If the pdfURL is valid, pdfPageCount should be > 0
    //    if (pdfPageCount > 0)
    //    {
    //        int iRet=RET_TRUE; // init for success
    //
    //        // Initialize the printer driver
    //        BMSPrinterDriver *brotherPrinter = [[BMSPrinterDriver alloc] initWithModel:kPrinterModelPJ673
    //                                                                     printSettings:pj673PrintSettings];
    //
    //        // Open the WIFI channel
    //        if ((iRet = [brotherPrinter openWIFIChannel:[pj673PrintSettings IPAddress]
    //                                            timeout:10.0]) != RET_TRUE)
    //        {
    //            // Channel failed to open within timeout
    //            // Clean up and exit
    //            [brotherPrinter release];
    //
    //            // Optional, show error if timeout occurrred when opening the channel
    //            // NOTE: Other errors may be applicable.
    //            if (iRet == ERROR_TIMEOUT)
    //            {
    //                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
    //                                                                message:@"Timeout"
    //                                                               delegate:nil
    //                                                      cancelButtonTitle:@"OK"
    //                                                      otherButtonTitles:nil];
    //                [alert show];
    //                
    //            }
    //            return;
    //        }
    //
    //        //*** Open PDF File, needed to get each CGPDFPageRef
    //        CGPDFDocumentRef pdfDocRef;
    //        pdfDocRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    //        int pageToPrint;
    //        NSMutableData *printData = [[NSMutableData alloc] init];
    //
    //        // This will print each page of the file.
    //        // If desired, you can use a page range instead.
    //        for (pageToPrint = 1; pageToPrint <= pdfPageCount && (iRet == RET_TRUE); pageToPrint++)
    //        {
    //            if (hud != nil)
    //            {
    //                hud.progress = 0.0;
    //                hud.detailsLabelText = [NSString stringWithFormat:@"Page %d of %zd", pageToPrint, pdfPageCount];
    //                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    //            }
    //
    //            CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdfDocRef, pageToPrint);
    //
    //            // DO NOT call CGPDFPageRelease below unless you also call CGPDFPageRetain here.
    //            CGPDFPageRetain(pdfPageRef);
    //
    //            // Set whether this is firstPage and/or last page
    //            [brotherPrinter setIsFirstPage:(pageToPrint == 1) ? YES : NO];
    //            [brotherPrinter setIsLastPage:(pageToPrint == pdfPageCount) ? YES : NO];
    //
    //            // reset length of printData back to 0 for each page
    //            [printData setLength:0];
    //
    //            // get the print data for this page
    //            iRet = [brotherPrinter generatePrintData:printData fromPDFPageRef:pdfPageRef];
    //
    //            // if printData is valid
    //            if (iRet == RET_TRUE)
    //            {
    //                // get a pointer to the data to send and get the size in bytes
    //                const uint8_t *bytes = (const uint8_t *)[printData bytes];
    //                int size = [printData length];
    //
    //                // send data in bands, if desired
    //                int totalBytesWritten=0;
    //                while (totalBytesWritten < size)
    //                {
    //                    int error;
    //                    int maxWriteSize = 4096; // set to desired size for each data band
    //                    int bytesWritten;
    //                    int bytesToWrite = ((size - totalBytesWritten) < maxWriteSize) ? (size - totalBytesWritten) : maxWriteSize;
    //                    // NOTE: Timeout needs to be large enough to send all the data
    //                    // It also must be large enough to handle cases where the printer
    //                    // may not be accepting data, such as when it is printing a page
    //                    // or if the printer runs out of paper.
    //                    bytesWritten = [brotherPrinter sendDataToWIFIChannel:&bytes[totalBytesWritten]
    //                                                                  length:bytesToWrite
    //                                                                 timeout:45.0
    //                                                               errorCode:&error];
    //                    // NOTE: error will contain 0 if success, otherwise an error occurred.
    //                    // If there was an error, break out of while loop
    //                    if (error != 0)
    //                    {
    //                        // handle error by retrying, or just kill the job.
    //                        // Most likely it will be a timeout error, see above.
    //                        iRet = error;
    //                        break;
    //                    }
    //                    else // update total
    //                    {
    //                        totalBytesWritten += bytesWritten;
    //                    }
    //
    //                    // NOTE: Now would be a good time to update your custom progress view
    //                    // if you have one.
    //                    float pct = (size == 0 ? 0.0 : totalBytesWritten * 1.0 / size);
    //                    //NSLog(@"Sent %d of %d bytes (%.2f %%)", totalBytesWritten, size, pct * 100.0);
    //                    if (hud != nil)
    //                    {
    //                        hud.progress = pct;
    //                        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    //                    }
    //
    //                } // while
    //
    //                // NOTE: If an error occurred, then the iRet will cause this
    //                // to break out of the for loop.
    //
    //                // Optional: check for timeout (or any other error) and post an alert.
    //                if (iRet == ERROR_TIMEOUT)
    //                {
    //                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
    //                                                                    message:@"Timeout"
    //                                                                   delegate:nil
    //                                                          cancelButtonTitle:@"OK"
    //                                                          otherButtonTitles:nil];
    //                    [alert show];
    //                    
    //                }
    //
    //            } // if (iRet == RET_TRUE), i.e. if printData is valid
    //
    //            // release PDF page ref AFTER using it for generating the printData
    //            // IMPORTANT: See note above related to CGPDFPageRetain!!
    //            CGPDFPageRelease(pdfPageRef);
    //
    //        } // for each page in PDF file
    //
    //
    //        // close the channel
    //        [brotherPrinter closeWIFIChannel];
    //
    //        // Release the printData
    //        [printData release];
    //
    //        // release the printer driver
    //        [brotherPrinter release];
    //
    //        // Release the PDF Document - this is REQUIRED.
    //        // Beware of doing this after CGPDFPageRelease unless the page was retained first!
    //        CGPDFDocumentRelease(pdfDocRef);
    //
    //    } // if pdfPageCount > 0
    
    size_t pdfPageCount = [self getPDFPageCount:pdfURL];
    
    if (pdfPageCount > 0)
    {
        // print using the Progress View.
        if(pj673PrintSettings.IPAddress == nil || pj673PrintSettings.IPAddress.length == 0)
        {
            [SurveyAppDelegate showAlert:@"Please enter the IP Address for your printer from the Maintenance menu on the Customers screen." withTitle:@"IP Address Required"];
            return;
        }
        
        BRPtouchPrinter *ptp = [[BRPtouchPrinter alloc] initWithPrinterName:@"Brother PJ-673"];
        
        [ptp setIPAddress:pj673PrintSettings.IPAddress];
        
        [ptp setPrintInfo:[PJ673PrintSettings defaultPrintInfo]];
        
        NSUInteger pageIndexes[] = {0};
        if ([ptp isPrinterReady])
            [ptp printPDFAtPath:pdfURL.path pages:pageIndexes length:0 copy:1 timeout:500];
        else
            [SurveyAppDelegate showAlert:@"Please check network settings, and connection with printer." withTitle:@"Printer Not Ready"];
        }
}


#pragma mark - SignatureViewControllerDelegate methods

-(UIImage*)signatureViewImage:(SignatureViewController*)sigController
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOSignature *retval = [del.surveyDB getPVOSignature:del.customerID forImageType:capturingSignatureID];
    return retval == nil ? nil : [retval signatureData];
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature
{
    [self signatureView:sigController confirmedSignature:signature withPrintedName:signatureName];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    // Set Load status for next sync
    if(self.pvoItem.reportTypeID == INVENTORY)
    {
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = LOAD;
        [del.surveyDB updateShipInfo:info];
    }
    else if(self.pvoItem.reportTypeID == DELIVERY_INVENTORY)
    {
        ShipmentInfo* info = [del.surveyDB getShipInfo:del.customerID];
        info.status = DELIVERED;
        [del.surveyDB updateShipInfo:info];
    }
}

-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature withPrintedName:(NSString*)printedName
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    int pvoSignatureID = [del.surveyDB savePVOSignature:del.customerID forImageType:capturingSignatureID withImage:signature];
    
    if (printedName != nil && [printedName length] > 0)
        [del.surveyDB savePVOSignaturePrintedName:printedName withPVOSignatureID:pvoSignatureID];
    
    signedReport = YES;
    
    sigViewText = nil;
    
    self.uploadAfterSigning = [AppFunctionality uploadReportAfterSigning] && [self.pvoItem hasRequiredSignatures];
    [self.pvoItem setReportWasUploaded:NO forCustomer:del.customerID];
    
    //set dirty flags for new signature
    //found; reset dirty flags for current doc...
    int data = [self.pvoItem getPVOChangeDataToCheck];
    [del.surveyDB pvoSetDataIsDirty:(cust.pricingMode == INTERSTATE)/*only mark dirty if Interstate*/ forType:data forCustomer:del.customerID];
    if ([del.pricingDB vanline] == ATLAS) {
        [self beginActualDateUploadForSignedReport];
    }    
}

-(NSString*)signatureViewTextForDisplay:(SignatureViewController*)sigController
{
    return sigViewText;
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == PREVIEW_PDF_ALERT_UPLOADIMAGES)
    {
        [self startServerSync:alertView.cancelButtonIndex != buttonIndex];
    }
    else if(alertView.tag == PREVIEW_PDF_ALERT_IMAGEUPLOADFINISHED)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        BOOL isCanadian = [SurveyCustomer isCanadianCustomer];
        if ([del.pricingDB vanline] == ATLAS && self.pvoItem.reportTypeID == INVENTORY && !isCanadian)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Include Images?"
                                                            message:@"Inventory data will be uploaded now. Do you want to upload images with Inventory data?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = PREVIEW_PDF_ALERT_UPLOADIMAGES;
            [alert show];
        }
    }
    else if (alertView.tag == PREVIEW_PDF_ALERT_DELIVERY_INCOMPLETE)
    {
        NSLog(@"Clicked pdf alert");
    }
    else if(alertView.cancelButtonIndex != buttonIndex)
    {
        if(alertView.tag == PREVIEW_PDF_ALERT_COMPLETE)
        {//asking the user to complete the inventory or not...  if not completed, the sig needs to read a line to the user that "I acknowledge my departure prior to inventory completion."
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            if(buttonIndex == 1)
            {
                PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
                inv.inventoryCompleted = YES;
                [del.surveyDB updatePVOData:inv];
                
                [del.surveyDB setCompletionDate:del.customerID isOrigin:YES];
                
                //[inv release];
            }
            else
            {
                sigViewText = [[NSString alloc] initWithString:@"I acknowledge my departure prior to inventory completion."];
            }
            capturingSignatureID = [[[self.pvoItem.signatureIDs componentsSeparatedByString:@","] objectAtIndex:0] intValue];
            [self continueToSignatureCapture];
        }
        else if(alertView.tag == PREVIEW_PDF_ALERT_REMOVESIG)
        {
            [self promptForOrShowSignatureView];
        }
        else
        {
            if(disconnectedReports)
            {
                [SurveyAppDelegate showAlert:@"You must be using web reports to upload the document." withTitle:@"Web Reports Required"];
                return;
            }
            
            //upload using the multi upload methods now. if its inventory, upload the PPI automatically
            [self beginDocUpload];
            
            //load upload view...
            //            uploader = [[PVOUploadReportView alloc] init];
            //
            //            [uploader uploadDocument:self.pvoItem.reportID];
        }
    }
    
}

-(void)beginActualDateUploadForSignedReport {
    // Atlas Actual Dates SOW
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([del.pricingDB vanline] == ATLAS && (self.option.reportTypeID == 1 || self.option.reportTypeID == 6 || self.option.reportTypeID == 3059 || self.option.reportTypeID == 3060)) {
        BOOL isOrigin = self.option.reportTypeID == 1 || self.option.reportTypeID == 3059 ? true : false;
        PVOUploadReportView* uploaderActualDates = [[PVOUploadReportView alloc] init];
        [uploaderActualDates updateActualDate:isOrigin];
    }
}

#pragma mark - TextAlertViewControllerDelegate methods

-(void)textAlertWillDismiss:(TextAlertViewController *)controller
{
    //confirmed, show signature...
    movingFromEsignToSignature = YES;
    
}

#pragma makr - PVOSync callback methods

-(void)bolError
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)bolSuccess
{
    self.pdfPath = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
    loadingReport = FALSE;
    
    viewProgress.hidden = YES;
    pdfView.hidden = NO;
    
    [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
}

-(void)bolUpdateProgress:(NSString*)error
{
    [SurveyAppDelegate showAlert:error withTitle:@"BOL Error"];
}


#pragma mark - HTMLReportGeneratorDelegate methods

- (void)htmlReportGenerator:(HTMLReportGenerator*)generator fileSaved:(NSString*)filepath
{
    
    if (htmlGenerator.generatingReportForUpload)
    {//used in the scenario where multiple docs needed to be generated at once and uploaded, not necessarily the current doc being previewed
        htmlGenerator.generatingReportForUpload = NO;
        saveToServerAfterLoad = NO;
        [self uploadDocGenerated:nil];
        return;
    }
    
    self.pdfPath = filepath;
    
    loadingReport = FALSE;
    
    viewProgress.hidden = YES;
    pdfView.hidden = NO;
    
    //    NSString *htmlDir = [SurveyAppDelegate getDocsDirectory];
    //    htmlDir = [htmlDir stringByAppendingPathComponent:@"WorkingHTMLTemp"];
    //    htmlDir = [htmlDir stringByAppendingPathComponent:@"auto_inventory.html?id=31&xmlloc=3DC32EF6-1015-4BDF-BF30-D408BFEBB6A4.xml"];
    //
    //    NSString* webStringURL = [htmlDir stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //    NSURL *url = [NSURL URLWithString:webStringURL];
    //    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    //    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:requestObj];
    //    [pdfView loadRequest:requestObj];
    
    [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
    
    if (signedReport)
        [self savePDFToCustomerDocuments:self.pdfPath];
    
    
    if ([AppFunctionality autoUploadInventoryReportOnSign])
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        PVOInventory *inv = [del.surveyDB getPVOData:del.customerID];
        if(signedReport &&
           ([self.pvoItem hasSignatureType:PVO_SIGNATURE_TYPE_DEST_INVENTORY] ||
            ([self.pvoItem hasSignatureType:PVO_SIGNATURE_TYPE_ORG_INVENTORY] && inv.inventoryCompleted)))
        {
            saveToServerAfterLoad = YES;
        }
        //[inv release];
    }
    signedReport = NO;
    
    if (saveToServerAfterLoad)
    {
        [self beginDocUpload];
    }
    
    if(!htmlGenerator.generatingReportForUpload) {
        htmlGenerator.pvoReportID = -1;
    }
    
}

- (void)htmlReportGenerator:(HTMLReportGenerator*)generator failedToGenerate:(NSString*)error
{
    [SurveyAppDelegate showAlert:error withTitle:@"Error Generating HTML Report"];
}

#pragma mark - PJ673PrintSettingsDelegate methods

-(void)pj673SettingsFoundReadyPrinter:(NSNumber*)printerFound
{
    brotherPrinterMode = [printerFound boolValue];
    
    if (brotherPrinterMode)
    {
        NSLog(@"brother mode");
        self.pj673PrintSettings = [[PJ673PrintSettings alloc] init];
        [pj673PrintSettings loadPreferences];
    }
    
    [self continueToPrint];
}


#pragma mark - External PDF Load
- (void)loadReadonlyPDFReport:(NSInteger)reportTypeID {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:del.customerID];
    
    PVOSync *sync = [[PVOSync alloc] init];
    sync.orderNumber = shipInfo.orderNumber;
    sync.syncAction = PVO_SYNC_ACTION_GET_DATA_WITH_ORDER_REQUEST;
    sync.delegate = self;
    //sync.pvoReportID = self.orderReportID;
    //sync.functionName = @"GetReportDataByRequest";
    sync.parameterKeys = [NSArray arrayWithObjects:@"orderReportID", nil];
    sync.parameterValues = [NSArray arrayWithObjects:[NSNumber numberWithInteger:reportTypeID], nil];
    
    [del.operationQueue addOperation:sync];
    
}

-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete {
    NSLog(@"syncProgressUpdate1");
}
-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete animated:(BOOL)animated {
    NSLog(@"syncProgressUpdate2");
}
-(void)syncProgressBarUpdate:(double)percentComplete {
    NSLog(@"syncProgressBarUpdate");
}
-(void)syncCompleted:(PVOSync*)sync withSuccess:(BOOL)success {
    
    //parse the survey, and demo data
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[sync.resultString dataUsingEncoding:NSUTF8StringEncoding]];
    PDFXMLParser *downloadParser = [[PDFXMLParser alloc] init];
    parser.delegate = downloadParser;
    [parser parse];
    
    if (downloadParser.parseIsSuccessful) {
        if (downloadParser.success) {
            NSData *pdfData = [[NSData alloc] initWithBase64EncodedString:downloadParser.output options:0];
            pdfPath = [self savePDFDataToCustomerDocuments:pdfData];
            viewProgress.hidden = YES;
            pdfView.hidden = NO;
            [pdfView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfPath]]];
        } else {
            viewProgress.hidden = YES;
            pdfView.hidden = NO;
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:downloadParser.output options:0];
            NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            
            [self messageAlert:@"PDF Download Error" message:decodedString];
        }
    } else {
        viewProgress.hidden = YES;
        pdfView.hidden = NO;
        [self messageAlert:@"PDF Download Error" message:@"Parser Error"];
    }
    
}

-(void)messageAlert:(NSString *)title message:(NSString *)message {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle: title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

@end
