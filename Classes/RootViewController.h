//
//  RootViewController.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrotherOldSDKStructs.h"
#import	"CustomerOptionsController.h"
#import "SyncViewController.h"
#import "AboutViewController.h"
#import "PurgeController.h"
#import "BackupController.h"
#import "ChangeFiltersController.h"
#import "PVOSyncController.h"
#import "PVOVerifyHolder.h"
#import "PackerInitialsController.h"

#import "DeleteItemController.h"
#import "DeleteRoomController.h"
#import "PVODeleteCCController.h"
#import "PVOFavoriteItemsController.h"
#import "PVOFavoriteCartonContentsController.h"
#import "BrotherPrinterSettingsController.h"
#import "SmallProgressView.h"

#import "PVOFavoriteItemsByRoomController.h"

#define OPTIONS_LIST_MAINTENANCE 0
#define OPTIONS_BACKUP 1
#define OPTIONS_PURGE 2
#define OPTIONS_ABOUT 3
#define OPTIONS_TARIFF_REFRESH 4
//#define OPTIONS_HTML_REPORTS_REFRESH 4
#define OPTIONS_VIEW_FILTERS 5
#define OPTIONS_VIEW_PREFERENCES 6
#define OPTIONS_DEMO_ORDERS 7
#define OPTIONS_BROTHER_PJ673_SETTINGS 8

#define ACTION_SHEET_DELETE 7
#define ACTION_SHEET_DUPLICATE 10
#define ACTION_SHEET_CREATE 77
#define ACTION_SHEET_LIST_MAINTENANCE 94
#define ACTION_SHEET_ITEM_LIST_SETTINGS 95

@interface RootViewController : PVOBaseViewController
<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, PreviewPDFControllerDelegate>  {
    IBOutlet UITableView *tblView;
	NSMutableArray *customers;
	CustomerOptionsController *optionsController;
	PortraitNavController *newNavController;
    SyncViewController *syncViewController;
    PurgeController *purgeController;
    AboutViewController *aboutView;
    IBOutlet UIBarButtonItem *cmdSort;
    CustomerFilterOptions *filters;
    BackupController *backupController;
    ChangeFiltersController *filterController;
    PVOSyncController *pvoDownload;
    
    DeleteItemController *itemDelete;
    DeleteRoomController *roomDelete;
    PVODeleteCCController *contentsDelete;
    PVOFavoriteItemsController *favorites;
    PVOFavoriteItemsByRoomController *favoritesByRoom;
    PVOFavoriteCartonContentsController *favoritesCartonContents;
    
    IBOutlet UIToolbar *toolbarOptions;
    PVOVerifyHolder *verifyHolder;
    
    PackerInitialsController *packerInitialController;
}

@property (nonatomic, retain) UITableView *tblView;
@property (nonatomic, retain) UIBarButtonItem *cmdSort;
@property (nonatomic, retain) NSMutableArray *customers;
@property (nonatomic, retain) CustomerOptionsController *optionsController;
@property (nonatomic, retain) PortraitNavController *navController;
@property (nonatomic, retain) SyncViewController *syncViewController;
@property (nonatomic, retain) AboutViewController *aboutView;
@property (nonatomic, retain) PurgeController *purgeController;
@property (nonatomic, retain) BackupController *backupController;
@property (nonatomic, retain) ChangeFiltersController *filterController;
@property (nonatomic, retain) UIToolbar *toolbarOptions;
@property (nonatomic, retain) PVOSyncController *pvoDownload;
@property (nonatomic, retain) PJ673PrintSettings *pj673PrintSettings;
@property (nonatomic, retain) SmallProgressView *dirtyReportProgress;
@property (nonatomic) int numDirtyReports;

-(IBAction) addCustomer:(id)sender;
-(IBAction) cmdSync_Click:(id)sender;
-(IBAction) cmdMaintenance_Click:(id)sender;
-(IBAction) cmdSort_Click:(id)sender;
-(IBAction) cmdDriver_Click:(id)sender;
-(IBAction) cmdPackers_Click:(id)sender;
-(IBAction) cmdDocuments_Click:(id)sender;

-(void)createNewCustomer;
-(void)handleDownloadCustomer;
-(void)loadFiltersScreen;

-(void)brotherIPUpdated:(NSString*)address;
//-(void)goToCustomerByID:(int)customerID;

@end
