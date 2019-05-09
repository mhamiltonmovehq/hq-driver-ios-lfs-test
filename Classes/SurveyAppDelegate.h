//
//  SurveyAppDelegate.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyDB.h"
#import	"SplashViewController.h"
#import "SingleFieldController.h"
#import "NoteViewController.h"
#import "EditDateController.h"
#import "PickerViewController.h"
#import "PricingDB.h"
#import "SurveyNumFormatter.h"
#import "MilesDB.h"
#import "ActivationErrorController.h"
#import "DownloadController.h"
//#import "RootViewController.h"
#import "TablePickerController.h"
#import "PVODamageViewHolder.h"
#import "ScanApiHelper.h"
#import "SocketDummyReceiver.h"
#import "PortraitNavController.h"
#import "LineaDummyDelegate.h"
#import "DebugController.h"

@class SurveyViewController;
@class AppFunctionality;
@class RootViewController;

#define ONE_KB 1024
#define ONE_MB 1048576

#define MB_STRING @"MB"
#define KB_STRING @"KB"
#define BYTE_STRING @"Bytes"

#define OPTIONS_STANDARD_VIEW 0
#define OPTIONS_PVO_VIEW 1

#define BETA_PASS @"beta"

#define degreesToRadian(x) (M_PI * (x) / 180.0)

@interface SurveyAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet PortraitNavController *navController;
	SplashViewController *splashView;
	SurveyDB *surveyDB;
	PricingDB *pricingDB;
//	MilesDB *milesDB;
	ActivationErrorController *activationController;
	int customerID;
//	int locationID;
	
	NSOperationQueue *operationQueue;
	NSOperationQueue *dashCalcQueue;
	
	//double decimal number formatter (0.00)
	SurveyNumFormatter *doubleDecFormatter;
	
	//used for a display to get only one field and call back originator when saved
	SingleFieldController *singleFieldController;
	//used for a display to get notes and call back originator when saved
	NoteViewController *noteViewController;
	//used for a display to get a date and call back originator when saved
	EditDateController *singleDateController;
	//used for a display to get a selection and call back originator when saved
	PickerViewController *pickerView;
	
	DownloadController *downloadDBs;
	
	TablePickerController *tablePicker;
    
    PVODamageViewHolder *pvoDamageHolder;
    
    //flag for PVO vs. Survey
    int viewType;
    int currentPVOClaimID;
    
    id<ScanApiHelperDelegate> currentSocketListener;
    ScanApiHelper *socketScanAPI;
    NSTimer* socketTimer;
    //need this to ignore scans when no active view is present.
    SocketDummyReceiver *dummySocketReceiver;
    //need this flag as ScanApiHelper.isDeviceConnected does not work
    BOOL socketConnected;
    
    LineaDummyDelegate *lineaDel;
    
    NSString *lastPackerInitials;
    
    BOOL activationError;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) PortraitNavController *navController;
@property (nonatomic, retain) SurveyNumFormatter *doubleDecFormatter;
@property (nonatomic, retain) SplashViewController *splashView;
@property (nonatomic, retain) SurveyDB *surveyDB;
@property (nonatomic, retain) PricingDB *pricingDB;
//@property (nonatomic, retain) MilesDB *milesDB;
@property (nonatomic, retain) SingleFieldController *singleFieldController;
@property (nonatomic, retain) EditDateController *singleDateController;
@property (nonatomic, retain) PickerViewController *pickerView;
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) NSOperationQueue *dashCalcQueue;
@property (nonatomic, retain) ActivationErrorController *activationController;
@property (nonatomic, retain) DownloadController *downloadDBs;
@property (nonatomic, retain) TablePickerController *tablePicker;
@property (nonatomic, retain) PVODamageViewHolder *pvoDamageHolder;
@property (nonatomic, retain) id<ScanApiHelperDelegate> currentSocketListener;
@property (nonatomic, retain) NSTimer* socketTimer;
@property (nonatomic, retain) ScanApiHelper *socketScanAPI;
@property (nonatomic, retain) DTDevices *linea;
@property (nonatomic, retain) NSString *lastPackerInitials;
@property (nonatomic, retain) DebugController *debugController;

@property (nonatomic) int customerID;
//@property (nonatomic) int locationID;
@property (nonatomic) int viewType;
@property (nonatomic) int currentPVOClaimID;
@property (nonatomic) BOOL socketConnected;
@property (nonatomic) int hviValType;
@property (nonatomic) BOOL activationError;
@property (nonatomic) BOOL uploadingArpinDoc;
@property (nonatomic) BOOL showedReleasedValWarning;
@property (nonatomic, retain) UIApplicationShortcutItem * launchedShortcutItem;


+(BOOL)hasInternetConnection;
+(BOOL)hasInternetConnection:(BOOL)testExternal;
+(BOOL)isRetina4;
+(void)handleException:(NSException *)exc;
+(void)showAlert:(NSString *)message withTitle: (NSString*)title;
+(void)showAlert:(NSString *)message withTitle: (NSString*)title withDelegate:(NSObject*)delegate;
+(void)showAlert:(NSString *)message withTitle: (NSString*)title withDelegate:(NSObject*)delegate onSeparateThread:(BOOL)throwExc;
+(void)soundAlert;
+(void)playSound: (NSString *) fileName musicType: (NSString *) fileType;
-(void)onTimer: (NSTimer*)theTimer;
+(NSString*)getDocsDirectory;
+(NSString*)getAttachDocTempDirectory;
+(UIImage*) scaleAndRotateImage:(UIImage *)image withOrientation:(UIImageOrientation)orient;
+(NSString*)getLastTwoPathComponents:(NSString*)filePath;
+(UIImage*)resizeImage:(UIImage*)originalImage withNewSize:(CGSize)newSize;
+(UIImage*)resizeImage:(UIImage*)originalImage withNewWidth:(int)newWidth withNewImagePath:(NSString*)toPath;
+(void)resizeImageToScale:(UIImage *)originalImage scale:(CGFloat)scale withNewImagePath:(NSString*)toPath;
+(void)saveNewImageToPath:(UIImage *)image withNewImagePath:(NSString*)toPath;
+(void)scrollTableToTextField:(UITextField*) field withTable:(UITableView*)tv atRow:(int)row;
+(NSString*)formatCurrency:(double)number;
+(NSString*)formatCurrency:(double)number withCommas:(BOOL)commas;
+(NSString*)formatDouble:(double)number;
+(NSString*)formatDouble:(double)number withPrecision:(int)decimals;
+(NSDate*)prepareDate:(NSString*)passed;
+(BOOL)dateAfter:(NSDate*)date year:(int)yr month:(int)mon day:(int)dy;
+(NSString*)stringFromBytes:(long long)bytes;
+(NSString*)formatDate:(NSDate*)passed;
+(NSString*)formatTime:(NSDate*)passed;
+(NSString*)formatDateAndTime:(NSDate*)passed;
+(NSString*)formatDateAndTime:(NSDate*)passed asGMT:(BOOL)asGMT;
+(NSString*)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString*)format;
+(NSString*)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString*)format asGMT:(BOOL)asGMT;
+(BOOL)iPad;
+(BOOL)iOS7OrNewer;
+(BOOL)iOS8OrNewer;

+(BOOL)isHighRes;
+(uint64_t)getFreeDiskspace;

+(void)setupViewForCartonContent:(UIView*)view withTableView:(UITableView*)tableView;
+(UIColor*)getCartonContentBackgroundColor;
+(UIColor*)getiOSBlueButtonColor;
+(void)removeCartonContentColorFromView:(UIView*)view;

+(void)adjustTableViewForiOS7:(UITableView *)tableView;

-(BOOL)debugCodeValid;
-(void)initDBs;
-(void)initDBsWithBackups:(NSArray*)backupArray;

-(void)showAlertFromDelegate:(NSArray*)alertdata;
-(BOOL)openPricingDB;
//-(BOOL)openMilesDB;
-(void)showHideVC:(UIViewController*)show withHide:(UIViewController*)hide;
-(void)hideSplashShowCustomers;
-(void)hideDownloadShowCustomers;
-(void)hideSplashShowDownload;
-(void)hideSplashShowActivationError:(NSString*)results;
-(void)pushSingleFieldController:(NSString*)value 
					 clearOnEdit:(BOOL)clear 
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder 
					  withCaller:(NSObject*)caller 
					 andCallback:(SEL)callback 
			   dismissController:(BOOL)dismiss;

-(void)pushSingleFieldController:(NSString*)value 
					 clearOnEdit:(BOOL)clear 
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder 
					  withCaller:(NSObject*)caller 
					 andCallback:(SEL)callback 
			   dismissController:(BOOL)dismiss
				andNavController:(UINavigationController*)navctl;

-(void)pushSingleFieldController:(NSString*)value
					 clearOnEdit:(BOOL)clear
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder
					  withCaller:(NSObject*)caller
					 andCallback:(SEL)callback
			   dismissController:(BOOL)dismiss
             requireValueForSave:(BOOL)requireValue
				andNavController:(UINavigationController*)navctl;

-(void)pushSingleFieldController:(NSString*)value
					 clearOnEdit:(BOOL)clear
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder
					  withCaller:(NSObject*)caller
					 andCallback:(SEL)callback
			   dismissController:(BOOL)dismiss
             requireValueForSave:(BOOL)requireValue
           andAutoCapitalization:(UITextAutocapitalizationType)autocapitalizationType
				andNavController:(UINavigationController*)navctl;

-(void)pushNoteViewController:(NSString*)value
				 withKeyboard:(UIKeyboardType)kb
				 withNavTitle:(NSString*)navTitle
			  withDescription:(NSString*)description 
				   withCaller:(NSObject*)caller 
				  andCallback:(SEL)callback 
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType;

-(void)pushNoteViewController:(NSString*)value
				 withKeyboard:(UIKeyboardType)kb
				 withNavTitle:(NSString*)navTitle
			  withDescription:(NSString*)description
				   withCaller:(NSObject*)caller
				  andCallback:(SEL)callback
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
                maxNoteLength:(int)maxNoteLength;

-(void)pushNoteViewController:(NSString*)value
				 withKeyboard:(UIKeyboardType)kb
				 withNavTitle:(NSString*)navTitle
			  withDescription:(NSString*)description 
				   withCaller:(NSObject*)caller 
				  andCallback:(SEL)callback 
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
			 andNavController:(UINavigationController*)navctl;

-(void)pushNoteViewController:(NSString*)value
                 withKeyboard:(UIKeyboardType)kb
                 withNavTitle:(NSString*)navTitle
              withDescription:(NSString*)description
                   withCaller:(NSObject*)caller
                  andCallback:(SEL)callback
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
			 andNavController:(UINavigationController*)navctl
                maxNoteLength:(int)maxNoteLength;

-(void)pushSingleDateViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller 
						andCallback:(SEL)callback;

-(void)pushSingleDateViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller 
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl;

-(void)pushSingleDateViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl
                   usingOldCallback:(BOOL)oldCallback;

-(void)pushSingleTimeViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl;
-(void)pushSingleDateTimeViewController:(NSDate*)value
                           withNavTitle:(NSString*)navTitle
                             withCaller:(NSObject*)caller
                            andCallback:(SEL)callback
                       andNavController:(UINavigationController*)navctl
                       usingOldCallback:(BOOL)oldCallback;

-(void)pushPickerViewController:(NSString*)title
					withObjects:(NSDictionary*)objects
		   withCurrentSelection:(NSNumber*)selection
					 withCaller:(NSObject*)caller 
					andCallback:(SEL)callback;

-(void)pushPickerViewController:(NSString*)title
					withObjects:(NSDictionary*)objects
		   withCurrentSelection:(NSNumber*)selection
					 withCaller:(NSObject*)caller 
					andCallback:(SEL)callback
			   andNavController:(UINavigationController*)navctl;

//either takes in a nsnumber and nsdictionary, or a nsstring and nsarray
-(void)pushTablePickerController:(NSString*)title
					 withObjects:(id)objects
			withCurrentSelection:(id)selection
					  withCaller:(id)caller 
					 andCallback:(SEL)callback
                 dismissOnSelect:(BOOL)dismiss
				andNavController:(UINavigationController*)navctl;

-(void)popTablePickerController:(NSString*)title
                    withObjects:(id)objects
           withCurrentSelection:(id)selection
                     withCaller:(id)caller
                    andCallback:(SEL)callback
                dismissOnSelect:(BOOL)dismiss
              andViewController:(UIViewController*)view
           skipInventoryProcess:(BOOL)skipInv;

//either takes in a nsnumber and nsdictionary, or a nsstring and nsarray
-(void)popTablePickerController:(NSString*)title
                    withObjects:(id)objects
           withCurrentSelection:(id)selection
                     withCaller:(id)caller 
                    andCallback:(SEL)callback
                dismissOnSelect:(BOOL)dismiss
              andViewController:(UIViewController*)view;

-(void)showPVODamageController:(UINavigationController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID;

-(void)showPVODamageController:(UINavigationController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID
                  withDelegate:(id<PVODamageControllerDelegate>)del;

-(void)showPVODamageController:(UINavigationController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID
           withWireframeOption:(BOOL)withWireframe
                  withDelegate:(id<PVODamageControllerDelegate>)del;

-(void)showPVODamageController:(UINavigationController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                   pvoUnloadID:(int)pvoUnloadID;

-(void)setTitleForDriverOrPackerNavigationItem:(UINavigationItem*)item
                                      forTitle:(NSString*)title;
									  
+ (void)minimizeTableHeaderAndFooterViews:(UITableView *)theTable;
+ (void)eliminateTableHeaderAndFooterViews:(UITableView *)theTable;
+ (void)setTableHeaderAndFooterViewsHeight:(UITableView *)theTable withHeight:(CGFloat)h;
+ (void)setDefaultBackButton:(UIViewController*)controller;

+(BOOL) deviceHasPasscode;

+(void)setupScanbot;

@end

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

