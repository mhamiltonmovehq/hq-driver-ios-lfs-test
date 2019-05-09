//
//  DocumentLibraryController.h
//  Survey
//
//  Created by Tony Brame on 5/22/13.
//
//

#import <UIKit/UIKit.h>
#import "AddDocLibEntryController.h"
#import "PreviewPDFController.h"
#import "SurveyCustomer.h"
#import "TempEmail.h"

#define SEND_TO_AGENT 0
#define SEND_TO_CUSTOMER 1

@interface DocumentLibraryController : UITableViewController <UIAlertViewDelegate, DocumentLibraryEntryDelegate, UIActionSheetDelegate,
MFMailComposeViewControllerDelegate>
{
    //used to track current document being downloaded.
    int currentIdx;
    int selectedSegment;
    NSMutableArray *selectedReports;
    ReportDefaults *defaults;
    int sendee;
    
    TempEmail *tempobj;
}

@property (nonatomic, retain) NSMutableArray *docs;
@property (nonatomic, retain) NSMutableArray *selectedReports;
@property (nonatomic, retain) AddDocLibEntryController *addDocController;
@property (nonatomic, retain) NSIndexPath *deletePath;
@property (nonatomic, retain) PreviewPDFController *previewController;
@property (nonatomic) BOOL customerMode;
@property (nonatomic) int customerID;
@property (nonatomic) BOOL specialSurveyHDMode;
@property (nonatomic) BOOL emailSent;

-(IBAction)addDocument:(id)sender;
-(IBAction)cmdCancelClick:(id)sender;
-(IBAction)refreshAllDocuments:(id)sender;
-(IBAction)sendEmail:(id)sender;
-(void)processEmail;
//-(IBAction)cmdLoopClick:(id)sender;


@end
