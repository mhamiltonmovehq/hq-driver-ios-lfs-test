//
//  HTMLReportGenerator.h
//  Survey
//
//  Created by Tony Brame on 10/23/14.
//
//

#import <Foundation/Foundation.h>
#import "BNHtmlPdfKit.h"

@class HTMLReportGenerator;
@protocol HTMLReportGeneratorDelegate < NSObject >
- (void)htmlReportGenerator:(HTMLReportGenerator*)generator fileSaved:(NSString*)filepath;
- (void)htmlReportGenerator:(HTMLReportGenerator*)generator failedToGenerate:(NSString*)error;
@end

#define HTML_REPORTS_TEMP_DIR @"/WorkingHTML"

@interface HTMLReportGenerator : NSObject <BNHtmlPdfKitDelegate, UIWebViewDelegate>
{
    BNHtmlPdfKit *htmlKit;
    UIWebView *webView;
    
    int custID;
}

@property (nonatomic, strong) id<HTMLReportGeneratorDelegate> delegate;
@property (nonatomic) int pvoReportTypeID;
@property (nonatomic) int pvoReportID; //ID from moverdocs server, this is the name of the folder the zip is in
@property (nonatomic) int pageSize;
@property (nonatomic) BOOL generatingReportForUpload; //ID from moverdocs server, this is the name of the folder the zip is in

-(void)generateReportWithHTML:(NSString*)htmlFilePath forCustomer:(int)customerID forPVONavItemID:(int)pvoNavItemID;
-(void)generateReportWithZipBundle:(NSString*)filePath
                    containingHTML:(NSString*)targetHTMLFile
                       forCustomer:(int)customerID
                   forPVONavItemID:(int)pvoNavItemID
              withImageDisplayType:(int)imagesType;

@end
