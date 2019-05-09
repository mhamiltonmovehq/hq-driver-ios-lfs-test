//
//  PreviewPDFController.h
//  Survey
//
//  Created by Tony Brame on 4/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignatureViewController.h"
#import "BrotherOldSDKStructs.h"
#import "ReportOption.h"
#import "ProcessReportController.h"
#import "TextAlertViewController.h"
#import "LandscapeNavController.h"
#import "GetReport.h"
#import "PortraitNavController.h"
#import "NoteViewController.h"
#import "BrotherOldSDKStructs.h"
#import "HTMLReportGenerator.h"
#import "PVONavigationListItem.h"
#import "PVOSync.h"

#define PRINT_EMAIL 0
#define PRINT_HARD_COPY 1

#define PREVIEW_PDF_ACTION_SIGN 0
#define PREVIEW_PDF_ACTION_EMAIL 1
#define PREVIEW_PDF_ACTION_PRINT 2
#define PREVIEW_PDF_ACTION_REPORT_NOTES 3
#define PREVIEW_PDF_ACTION_UPLOAD 4
#define PREVIEW_PDF_ACTION_EMAIL_SAVE 5
#define PREVIEW_PDF_ACTION_PRINT_SAVE 6
#define PREVIEW_PDF_ACTION_SAVE_TO_LIB 7

#define PREVIEW_PDF_ACTION_RELOAD_DOC 100

#define PREVIEW_PDF_ALERT_COMPLETE 1000
#define PREVIEW_PDF_ALERT_REMOVESIG 1001
#define PREVIEW_PDF_ALERT_UPLOADIMAGES 1002
#define PREVIEW_PDF_ALERT_IMAGEUPLOADFINISHED 1003
#define PREVIEW_PDF_ALERT_DELIVERY_INCOMPLETE 1004

#define PREVIEW_PDF_ACTION_SHEET_OPTIONS 1000
#define PREVIEW_PDF_ACTION_SHEET_SIG_TYPE 1001

#define PREVIEW_PDF_E_VERIFY 34

@class PVOUploadReportView;

//creating a delegate for ipad to know when agent sig is about to be called
@class PreviewPDFController;
@protocol PreviewPDFControllerDelegate <NSObject>
@optional
-(void)finishedShowingPreview:(PreviewPDFController*)pdfController withAction:(int)docAction;
-(void)emailPreviewDoc:(PreviewPDFController*)pdfController;
-(void)printPreviewDoc:(PreviewPDFController*)pdfController;
@end

@interface PreviewPDFController : UIViewController <UIActionSheetDelegate, SignatureViewControllerDelegate, UIAlertViewDelegate, TextAlertViewControllerDelegate, HTMLReportGeneratorDelegate, ProcessReportControllerDelegate, PVOUploadReportViewDelegate, PJ673PrintSettingsDelegate, UIWebViewDelegate, PVOSyncDelegate> {
    IBOutlet UIWebView *pdfView;
    IBOutlet UIView *viewProgress;
    NSString *pdfPath;
    SignatureViewController *signatureController;
    ReportOption *option;
    
    ProcessReportController *processReport;
    
    id<PreviewPDFControllerDelegate> delegate;
    
    BOOL loadingReport;
    
    PortraitNavController *newNav;
    
    PVOUploadReportView *uploader;
    
    TextAlertViewController *esignView;
    
    BOOL movingFromEsignToSignature;
    BOOL saveToServerAfterLoad;
    BOOL uploadPPIAfterInventory;
    BOOL disconnectedReports;
    BOOL supportsDisconnected;
    
    id disconnectedDrawer;
    
    //used to say the view disappeared, and the pdf loaded ater the view was gone.  In which case, don't show the old pdf.
    BOOL viewHasDisappeared;
    
    NSMutableArray *actionSheetOptions;
    
    NSString *sigViewText;
    NSString *signatureName;
    
    LandscapeNavController *sigNav;
    
    GetReport *reportObject;
    
    BOOL signedReport;
    
    NoteViewController *noteController;
    
    bool brotherPrinterMode;
    BOOL useDisconnectedReports;
    
    DownloadFile *htmlDownloader;
    HTMLReportGenerator *htmlGenerator;
    
    //the signature id currently being captured.
    int capturingSignatureID;
    NSMutableString *currentSyncMessage;
    NSMutableArray *docsToUpload;
    
}

@property (nonatomic, retain) PVONavigationListItem *pvoItem;
@property (nonatomic) BOOL signedReport;

//added for the doc lib to restrict signature option from being displayed
@property (nonatomic) BOOL noSignatureAllowed;
@property (nonatomic) BOOL noSaveOptionsAllowed;
@property (nonatomic) BOOL uploadingDirtyReports;
@property (nonatomic) BOOL hideActionsOptions;
@property (nonatomic) BOOL uploadAfterSigning;

@property (nonatomic, retain) SmallProgressView *uploadProgress;

@property (nonatomic, retain) UIWebView *pdfView;
@property (nonatomic, retain) id additionalReportInfo;
@property (nonatomic, retain) UIView *viewProgress;
@property (nonatomic, retain) NSString *pdfPath;
@property (nonatomic, retain) ReportOption *option;
@property (nonatomic, retain) id disconnectedDrawer;
@property (nonatomic, retain) SignatureViewController *signatureController;
@property (nonatomic, retain) id<PreviewPDFControllerDelegate> delegate;
@property (nonatomic, retain) PVOUploadReportView *uploader;
@property (nonatomic, retain) TextAlertViewController *esignView;
@property (nonatomic, retain) SingleFieldController *singleFieldController;
@property (nonatomic, retain) NSString *signatureName;
@property (nonatomic, retain) NSMutableArray *docsToUpload;
@property (nonatomic, retain) NSMutableArray *customers;
@property (nonatomic) SEL dirtyReportUploadFinished;
@property (nonatomic) SEL allDirtyReportsFinishedUploading;
//used for saving to the doc library, to ge tthe report name
@property (nonatomic, retain) NSString *navOptionText;

@property (nonatomic, retain) PJ673PrintSettings *pj673PrintSettings;
@property (nonatomic) BOOL useDisconnectedReports;

-(IBAction)optionsClick:(id)sender;
-(IBAction)sign:(id)sender;

-(void)updateFromGetReport:(NSString*)result;

-(void)showSignatureView;

-(void)bolError;
-(void)bolSuccess;
-(void)bolUpdateProgress:(NSString*)error;
-(IBAction)share:(id)sender;
-(void)savePDFToCustomerDocuments:(NSString *)path;

-(void)reportNotesEntered:(NSString*)reportNotes;

-(void)updateFromDownload:(NSString*)message;
-(void)uploadAllDirtyReports;

-(void)beginActualDateUploadForSignedReport;

@end
