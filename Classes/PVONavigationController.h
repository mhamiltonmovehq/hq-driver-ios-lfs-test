//
//  PVONavigationController.h
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVORoomSummaryController.h"
#import "PVOLocationSummaryController.h"
#import "PVOValInitialController.h"
#import "PVOServicesController.h"
#import "PVOConfirmPaymentController.h"
#import "PVODamageController.h"
#import "PVOPrintController.h"
#import "PVOReweighController.h"
#import "PVOWeightTicketController.h"
#import "PVODeliverySummaryController.h"
#import "PreviewPDFController.h"
#import "PVONavigationListItem.h"
#import "PVOUploadReportView.h"
#import "SmallProgressView.h"
#import "PVOWeightTicketSummaryController.h"
#import "PVOAttachDocController.h"
#import "PVODynamicReportSectionsController.h"
#import "PVOSync.h"
#import "PVOAutoInventoryController.h"
#import "PVOAutoinventorySignController.h"
#import "PVOBulkyInventoryController.h"
#import "PVOActionItemsController.h"

#define PVO_DONE 0

#define PVO_ALERT_CONFIRM_SYNC 1001
#define PVO_ALERT_SELECT_VAL_TYPE 1002
#define PVO_ALERT_USE_DISCONNECTED 1003
#define PVO_ALERT_CONFIRMATION_DETAIL 1004
#define PVO_ALERT_CONFIRM_HIGH_VALUE 1005
#define PVO_ALERT_UPLOAD_DOCUMENTS 1006

#define IMAGES_NONE 0
#define IMAGES_INLINE 1
#define IMAGES_ATTACHMENT 2


@interface PVONavigationController : UIViewController 
<UITableViewDataSource, UITableViewDelegate, 
PVOValInitialControllerDelegate, PVOSignatureControllerDelegate,
PVOReweighControllerDelegate, PVOWeightTicketControllerDelegate,
UIAlertViewDelegate, PVOUploadReportViewDelegate, PVOSyncDelegate, HTMLReportGeneratorDelegate, PreviewPDFControllerDelegate> {
    int currentPage;
    int nextPage;
    int previousPage;
    IBOutlet UIBarButtonItem *cmdPrevious;
    IBOutlet UIBarButtonItem *cmdNext;
    IBOutlet UIBarButtonItem *cmdDone;
    IBOutlet UITableView *tableView;
	PVOLandingController *landingController;
	PVOValInitialController *valInitialsController;
    PVOServicesController *servicesController;
    PVOConfirmPaymentController *confirmPaymentController;
    PVODamageController *propertyDamageController;
    //PreviewPDFController *printController;
    PVOSignatureController *signatureController;
    PVOReweighController *reweighController;
    PVOWeightTicketSummaryController *weightsController;
    PVODeliverySummaryController *deliveryController;
    PVOAttachDocController *attachDocController;
    PVODynamicReportSectionsController *dynamicReportSections;
    PVOAutoInventoryController *autoInventoryController;
    PVOAutoInventorySignController *autoInventorySignController;
    PVOBulkyInventoryController *bulkyInventoryController;
    PVOChecklistController *checklistController;
    PVOActionItemsController *actionsController;
    DownloadFile *htmlDownloader;
    HTMLReportGenerator *htmlGenerator;
    
    PVOInventory *inventory;
    
    NSMutableArray *rows;
    
    int tareWeight;
    int grossWeight;
    
    NSString *pvoNote;
    
    NSDate *finalDelDate;
    
    NSDictionary *allNavItems;
    NSMutableDictionary *imageDisplayTypes;
    NSArray *categories;
    
    IBOutlet UIToolbar *toolbar;
    
    PVONavigationListItem *selectedItem;
    
    //for any additional information - for viewing the BOL, this is a bool NSNumber indicating whether estimated charges should show or not...
    id additionalReportData;
    
    
    
    NSMutableArray *docsToUpload;
    PVOUploadReportView *uploader;
    SmallProgressView *uploadProgress;
    
    BOOL useDisconnectedReports;    
}

@property (nonatomic, retain) UIBarButtonItem *cmdPrevious;
@property (nonatomic, retain) UIBarButtonItem *cmdNext;
@property (nonatomic, retain) UIBarButtonItem *cmdDone;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) PVOLandingController *landingController;
@property (nonatomic, retain) PVOValInitialController *valInitialsController;
@property (nonatomic, retain) PVOServicesController *servicesController;
@property (nonatomic, retain) PVOConfirmPaymentController *confirmPaymentController;
@property (nonatomic, retain) PVODamageController *propertyDamageController;
@property (nonatomic, retain) PreviewPDFController *printController;
@property (nonatomic, retain) PVOSignatureController *signatureController;
@property (nonatomic, retain) PVOReweighController *reweighController;
@property (nonatomic, retain) PVOWeightTicketSummaryController *weightsController;
@property (nonatomic, retain) PVODeliverySummaryController *deliveryController;
@property (nonatomic, retain) PVOInventory *inventory;
@property (nonatomic, retain) PVONavigationListItem *selectedItem;
@property (nonatomic, retain) NSString *pvoNote;
@property (nonatomic, retain) NSDate *finalDelDate;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic) int currentPage;
@property (nonatomic, retain) UIButton *syncButton;
@property (nonatomic, retain) NSMutableString *currentSyncMessage;

@property (nonatomic, retain) PVOAttachDocController *attachDocController;

@property (nonatomic) BOOL checklistCompleted;

-(IBAction)previous:(id)sender;
-(IBAction)next:(id)sender;
-(IBAction)done:(id)sender;
-(IBAction)sync:(id)sender;

-(void)singleValueEntered:(NSString*)newValue;
-(void)dateEntered:(NSDate*)newValue withIgnore:(NSDate*)date2;
-(void)doneEditingNote:(NSString*)newValue;

-(void)setNextAndPrevious;
-(void)setupCurrentPage;

-(void)loadSignature:(NSString*)displayText;

-(void)loadPrintScreen;

-(void)continueToSelectedItem;

-(void)askToContinue:(NSString*)continueText;


-(int)getPrintDocTypeForRow:(int)rowType;


-(void) uploadDocGenerated:(NSString*)update;


-(void)startServerSync;

-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete;

//-(IBAction)uiCatchUp:(id)timer;

@end
