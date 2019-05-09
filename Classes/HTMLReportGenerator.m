//
//  HTMLReportGenerator.m
//  Survey
//
//  Created by Tony Brame on 10/23/14.
//
//

#import "HTMLReportGenerator.h"
#import "SurveyAppDelegate.h"
#import "Base64.h"
#import "ZipArchive.h"
#import "SyncGlobals.h"
#import "SurveyImage.h"
#import "PVOPrintController.h"
#import "PVOVehicle.h"

@implementation HTMLReportGenerator

-(id)init
{
    if(self = [super init])
    {
        webView = [[UIWebView alloc] init];
        htmlKit = [[BNHtmlPdfKit alloc] init];
        
        webView.delegate = self;
        htmlKit.delegate = self;
    }
    
    return self;
}

-(void)generateReportWithHTML:(NSString*)htmlFilePath
                  forCustomer:(int)customerID
              forPVONavItemID:(int)pvoNavItemID
{
    custID = customerID;
    NSURL *url = [NSURL fileURLWithPath:htmlFilePath];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
}

-(void)generateReportWithZipBundle:(NSString*)filePath
                    containingHTML:(NSString*)targetHTMLFile
                       forCustomer:(int)customerID
                   forPVONavItemID:(int)pvoNavItemID
              withImageDisplayType:(int)imagesType
{
    custID = customerID;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    //file path is now only the zip name, build the location and append the string
    NSString *reportBundlePath = [SurveyAppDelegate getDocsDirectory];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:HTML_FILES_LOCATION];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", self.pvoReportTypeID]];
    reportBundlePath = [reportBundlePath stringByAppendingPathComponent:filePath];
    
    
    ZipArchive *unzip = [[ZipArchive alloc] init];
    NSString *htmlDir = [SurveyAppDelegate getDocsDirectory];
    htmlDir = [htmlDir stringByAppendingPathComponent:HTML_REPORTS_TEMP_DIR];
    if([mgr fileExistsAtPath:htmlDir])
        [mgr removeItemAtPath:htmlDir error:nil];
    
    [unzip UnzipOpenFile:reportBundlePath];
    [unzip UnzipFileTo:htmlDir overWrite:YES];
    
    NSString *xml = [SyncGlobals buildCustomerXML:custID withNavItemID:pvoNavItemID isAtlas:NO].file;
    
    CFUUIDRef udid = CFUUIDCreate(NULL);
    NSString *udidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, udid));
    
    udidString = [udidString stringByAppendingPathExtension:@"xml"];
    NSString *xmlPath = [htmlDir stringByAppendingPathComponent:udidString];
    if([mgr fileExistsAtPath:xmlPath])
        [mgr removeItemAtPath:xmlPath error:nil];
    
    [mgr createFileAtPath:xmlPath contents:[xml dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    NSString *fullpath = [htmlDir stringByAppendingPathComponent:targetHTMLFile];
    
    fullpath = [fullpath stringByAppendingFormat:@"?id=%d&xmlloc=%@", self.pvoReportTypeID, [udidString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if (imagesType > 0) //passing in to determine which type of images get displayed on the inventory report
    {
        fullpath = [fullpath stringByAppendingFormat:@"&withimages=%d", imagesType];
        
        //need to compress teh images, pdfs were getting way too big
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSMutableArray *images = [del.surveyDB getImagesList:del.customerID withPhotoType:0 withSubID:0 loadAllItems:YES];
        for (SurveyImage* surveyImage in images)
        {
            //get the current docs directory
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            
            NSString *inDocsPath = surveyImage.path;
            NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
            
            UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
            
            //iOS uses a very generic naming convention for images, which results in the items, rooms, and locaitons having overlapping names. I wanted reports to work for older jobs still, so I am putting the images in folders inside the WorkignHTML folder, and I'm going to change the image naming convention to match Android, -- Time.ToMillis.JPEG
            NSString *outPath = [htmlDir stringByAppendingPathComponent:[SurveyAppDelegate getLastTwoPathComponents:surveyImage.path]];
            NSString *parentDirectory = [outPath stringByDeletingLastPathComponent];
            //make sure image directory exists
            if(![mgr fileExistsAtPath:parentDirectory])
                [mgr createDirectoryAtPath:parentDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            
            [SurveyAppDelegate resizeImage:img withNewWidth:200 withNewImagePath:outPath];
        }
    }
    
#ifndef DEBUG //this report option didn't exist in MoverDocs when i was testing. This macro wrapper can be removed once its in MD. I was running origin inventory to test.
    if (self.pvoReportTypeID == BULKY_INVENTORY_ORIG || self.pvoReportTypeID == BULKY_INVENTORY_DEST)
    {
#endif
        //get the current docs directory
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        
        //check for bulky inventory items, if they exist add them to the workingHTML wireframes
        //get the photo wireframes and copy them into the working HTML folder
        NSArray *imagePaths = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_VEHICLE_DAMAGES withSubID:VT_PHOTO loadAllItems:NO];
        for (SurveyImage *surveyImage in imagePaths)
        {
            NSString *inDocsPath = surveyImage.path;
            NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
            
            UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
            
            //copy the image to the working html folder
            NSString *outPath = [htmlDir stringByAppendingPathComponent:[surveyImage.path lastPathComponent]];
            [SurveyAppDelegate saveNewImageToPath:img withNewImagePath:outPath];
            
        }
        
        
        //check for which standard wireframes were used and copy them over as well
        NSArray *bulkyWireFrameTypes = [del.surveyDB getPVOBulkyWireframeTypesForCustomer:custID];
        for (int i = 0; i < [bulkyWireFrameTypes count]; i++)
        {
            int wireFrameTypeID = [[bulkyWireFrameTypes objectAtIndex:i] intValue];
            
            //skip it if its a photo, we already copied it above
            if (wireFrameTypeID <= 0 || wireFrameTypeID == WT_PHOTO_AUTO)
                continue;
            
            UIImage *allImage = [PVOWireframeDamage allImage:wireFrameTypeID]; //get images for vehicle...
            
            //copy the image to the working html folder
            NSString *outPath = [htmlDir stringByAppendingPathComponent:[PVOWireframeDamage allImageFilename:wireFrameTypeID]];
            [SurveyAppDelegate saveNewImageToPath:allImage withNewImagePath:outPath];
            
        }
        
#ifndef DEBUG
    }
#endif
    
    
    if (self.pvoReportTypeID == AUTO_INVENTORY_ORIG || self.pvoReportTypeID == AUTO_INVENTORY_DEST)
    {
        /*
         For the auto inventory report, we are not supporting running this report on the moverdocs server for any reason. Photo wireframes and standard wireframes are copied into the WorkingHTML folder. The XML will pass the filename and the height and width, so do not alter the photo here. Get all the photos that were used and copy them over, then get the wireframes and copy those over.
         */
        
        //get the current docs directory
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        
        //get the photo wireframes and copy them into the working HTML folder
        NSArray *imagePaths = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_VEHICLE_DAMAGES withSubID:VT_PHOTO loadAllItems:NO];
        for (SurveyImage *surveyImage in imagePaths)
        {
            NSString *inDocsPath = surveyImage.path;
            NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
            
            UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
            
            //copy the image to the working html folder
            NSString *outPath = [htmlDir stringByAppendingPathComponent:[surveyImage.path lastPathComponent]];
            [SurveyAppDelegate saveNewImageToPath:img withNewImagePath:outPath];
            
        }
        
        
        //check for which standard wireframes were used and copy them over as well
        NSArray *wireFrameTypes = [del.surveyDB getPVOVehicleWireframeTypes:custID];
        for (int i = 0; i < [wireFrameTypes count]; i++)
        {
            int wireFrameTypeID = [[wireFrameTypes objectAtIndex:i] intValue];
            
            //skip it if its a photo, we already copied it above
            if (wireFrameTypeID <= 0 || wireFrameTypeID == WT_PHOTO_AUTO)
                continue;
            
            UIImage *allImage = [PVOWireframeDamage allImage:wireFrameTypeID]; //get images for vehicle...
            
            //copy the image to the working html folder
            NSString *outPath = [htmlDir stringByAppendingPathComponent:[PVOWireframeDamage allImageFilename:wireFrameTypeID]];
            [SurveyAppDelegate saveNewImageToPath:allImage withNewImagePath:outPath];
            
        }
    }
    
    
    NSString* webStringURL = [fullpath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:webStringURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:requestObj];
    [webView loadRequest:requestObj];
    
}


#pragma mark - UIWebViewDelegate methods

-(void)webViewDidStartLoad:(UIWebView *)webView
{
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(htmlReportGenerator:failedToGenerate:)])
        [self.delegate htmlReportGenerator:self failedToGenerate:error.description];
}

-(void)webViewDidFinishLoad:(UIWebView *)thisWebView
{
    
    //    NSString *xml = [SyncGlobals buildCustomerXML:custID isAtlas:NO].file;
    //    NSString *base64 =[Base64 encode64:xml];
    //    NSString *jsCall = [NSString stringWithFormat:@"PopulateReport('{\"id\":\"%d\",\"xml\":\"%@\"}')", self.pvoReportTypeID, base64];
    //
    //    [webView stringByEvaluatingJavaScriptFromString:jsCall];
    //
    //
    //    NSLog(@"save");
    
    NSString *documentsPath = [SurveyAppDelegate getDocsDirectory];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"temp.pdf"];
    
    [htmlKit saveWebViewAsPdf:webView toFile:filePath withPageSize:self.pageSize];
    
    //NSString *htmlDir = [SurveyAppDelegate getDocsDirectory];
    //htmlDir = [htmlDir stringByAppendingPathComponent:HTML_REPORTS_TEMP_DIR];
    //NSFileManager *mgr = [NSFileManager defaultManager];
    //[mgr removeItemAtPath:htmlDir error:nil];
}

#pragma mark - BNHtmlPdfKitDelegate methods

- (void)htmlPdfKit:(BNHtmlPdfKit *)htmlPdfKit didSavePdfFile:(NSString *)file {
    
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(htmlReportGenerator:fileSaved:)])
        [self.delegate htmlReportGenerator:self fileSaved:file];
    
}

- (void)htmlPdfKit:(BNHtmlPdfKit *)htmlPdfKit didFailWithError:(NSError *)error {
    
    if(self.delegate != nil && [self.delegate respondsToSelector:@selector(htmlReportGenerator:failedToGenerate:)])
        [self.delegate htmlReportGenerator:self failedToGenerate:error.description];
    
    
}

@end
