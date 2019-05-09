//
//  ProcessReportController.h
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <MessageUI/MessageUI.h>
#import "BrotherOldSDKStructs.h"

#import "ReportDefaults.h"
#import "ReportOption.h"
#import "ReportOptionParser.h"
//#define Printer ePrint_Printer
#import "ePrint.h"
//#undef Printer
#import "MMDrawer.h"
#import "PVOUploadReportView.h"
#import "SmallProgressView.h"
#import "PDFDraw.h"
#import "GetPrinterController.h"
#import "WebSyncRequest.h"

#define REPORT_SEND_FROM_DEVICE 1
#define REPORT_EMAIL 2
#define REPORT_NAME 3
#define REPORT_TO 4
#define REPORT_SUBJECT 5
#define REPORT_BODY 6

#define REPORT_ADDL_EMAIL_ROW 7
#define REPORT_CC_EMAIL_ROW 8
#define REPORT_BCC_EMAIL_ROW 9

#define MAX_FILE_SIZE 10000000


@class PJ673PrintSettings;

//creating a delegate for ipad to know when agent sig is about to be called
@class ProcessReportController;
@protocol ProcessReportControllerDelegate <NSObject>
@optional
-(void)emailFinishedSending:(ProcessReportController*)processReportController withUpdate:(NSString*)textToAdd;
@end

@interface ProcessReportController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, PVOUploadReportViewDelegate, MFMailComposeViewControllerDelegate, WebSyncRequestDelegate, PJ673PrintSettingsDelegate> {
    IBOutlet UIActivityIndicatorView *activity;
    IBOutlet UILabel *labelLoading;
    IBOutlet UITableView *tableView;
    IBOutlet UIView *viewPrintProgress;
    IBOutlet UILabel *labelPrintPage;
    IBOutlet UIProgressView *progressPage;
    IBOutlet UIProgressView *progressJob;
    
    NSMutableArray *additionalEmails;
    
    NSMutableArray *ccEmails;
    NSMutableArray *bccEmails;
    
    ReportDefaults *defaults;
    int editingField;
    BOOL keyboardIsShowing;
    int    keyboardHeight;
    id tboxCurrent;
    int printType;
    NSString *reportAddress;
    NSMutableArray *rows;
    PDFDraw *pdfDrawer;
    
    ePrint *printer;
    GetPrinterController *getPrinter;
    BOOL gettingAPrinter;
    
    int quality;
    BOOL color;
    
    NSTimer    *timer;
    
    ReportOption *reportOption;
    
    PVOUploadReportView *uploader;
    SmallProgressView *uploadProgress;
    id<ProcessReportControllerDelegate> delegate;
    
    int pvoReportTypeID;
    int pvoNavItemID;

    BOOL docAlreadyFinishedProcessing;
    
    bool brotherPrinterMode;
    
    BOOL comingFromMailer;
}

@property (nonatomic) int printType;
@property (nonatomic) int pvoReportTypeID;
@property (nonatomic) int pvoNavItemID;

@property (nonatomic, strong) UIView *viewPrintProgress;
@property (nonatomic, strong) UILabel *labelPrintPage;
@property (nonatomic, strong) UIProgressView *progressPage;
@property (nonatomic, strong) UIProgressView *progressJob;

@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) ReportDefaults *defaults;
@property (nonatomic, strong) id tboxCurrent;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UILabel *labelLoading;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *reportAddress;
@property (nonatomic, strong) GetPrinterController *getPrinter;
@property (nonatomic, strong) ReportOption *reportOption;
@property (nonatomic, strong) NSString *pdfPath;
@property (nonatomic, strong) PVOUploadReportView *uploader;
@property (nonatomic, strong) SmallProgressView *uploadProgress;
@property (nonatomic, strong) id<ProcessReportControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *ccEmails;
@property (nonatomic, strong) NSMutableArray *bccEmails;
@property (nonatomic) BOOL uploadAfterEmail;


@property (nonatomic, strong) PJ673PrintSettings *pj673PrintSettings;

@property (nonatomic, strong) NSString *agentEmailPlaceholder;
@property (nonatomic, strong) NSString *agentNamePlaceholder;

-(IBAction)done:(id)sender;
-(IBAction)cancelPrint:(id)sender;
-(IBAction)saveAsDefault:(id)sender;

-(void)updateValueWithField:(id)fld;

-(void)initializeRows;

-(IBAction)doneEditingText:(id)sender;
-(IBAction)printTypeChanged:(id)sender;
-(IBAction)printQualityChanged:(id)sender;
-(IBAction)switchChanged:(id)sender;

-(void) keyboardWillShow:(NSNotification *)note;
-(void) keyboardWillHide:(NSNotification *)note;

-(void) updateEmailProgress:(NSString*)update;

-(void)documentProcessed;

- (void)print_PrintComplete:(NSNotification *)notification;
- (void)print_SetProgressNumber;

@end

