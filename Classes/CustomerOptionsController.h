//
//  CustomerOptionsController.h
//  Survey
//
//  Created by Tony Brame on 5/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import	"CustomerListItem.h"
#import "LocationController.h"
#import "SurveySummaryController.h"
#import "SurveyDatesController.h"
#import "SurveyAgentsController.h"
#import "SurveyImage.h"
#import "InfoController.h"
#import "PVOLandingController.h"
#import "PVONavigationController.h"
#import "PVOClaimsSummaryController.h"
#import "PVOReceiveController.h"
#import "ExistingImagesController.h"

#define INFO_SECTION 0
#define LOCATIONS_SECTION 1
#define SURVEY_SECTION 2

#define BASIC_INFO_ROW 0
#define DATES_ROW 1
#define AGENTS_ROW 2
#define ORIGIN_ROW 0
#define DESTINATION_ROW 1
#define SURVEY_ROW 0
#define NOTES_ROW 1
#define INFORMATION_ROW 2
#define PRICING_ROW 3
#define MISC_ROW 4
#define SUMMARY_ROW 5
#define PACK_SUMMARY_ROW 6

#define PVO_IMAGE_HOUSE_HEIGHT 50.
#define PVO_IMAGE_TRUCK_HEIGHT 25.
#define PVO_VIEW_MARGIN 20.

#define CUSTOMER_OPTIONS_ALERT_RECEIVE 99

@interface CustomerOptionsController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate> {
	CustomerListItem *selectedItem;
	SurveySummaryController *surveySummaryController;
	SurveyDatesController *datesController;
	SurveyAgentsController *agentsController;
	InfoController *infoController;
	PVONavigationController *pvoController;
    PVOClaimsSummaryController *pvoClaimsController;
    PVOReceiveController *receiveController;
    ExistingImagesController *imagesController;
    PVOLocationSummaryController *inventoryController;
    
	IBOutlet UIButton *cmd_BasicInfo;
	IBOutlet UIButton *cmd_Agents;
	IBOutlet UIButton *cmd_Dates;
	IBOutlet UIButton *cmd_Origin;
	IBOutlet UIButton *cmd_Destination;
	IBOutlet UIButton *cmd_Survey;
	IBOutlet UIButton *cmd_Notes;
	IBOutlet UIButton *cmd_MoveInfo;
	IBOutlet UIButton *cmd_Miscellaneous;
	IBOutlet UIButton *cmd_Pricing;
	IBOutlet UIButton *cmd_PriceSummary;
	IBOutlet UIButton *cmd_PackCrateSummary;
    
    UIView *pvoTruckView;
    UIImageView *pvoTruckImage;
    
    int viewType;
    
    NSDictionary *pvoNavItems;
//    int totalPVOProgress;
}

@property (nonatomic, retain) UIButton *cmd_BasicInfo;
@property (nonatomic, retain) UIButton *cmd_Agents;
@property (nonatomic, retain) UIButton *cmd_Dates;
@property (nonatomic, retain) UIButton *cmd_Origin;
@property (nonatomic, retain) UIButton *cmd_Destination;
@property (nonatomic, retain) UIButton *cmd_Survey;
@property (nonatomic, retain) UIButton *cmd_Notes;
@property (nonatomic, retain) UIButton *cmd_MoveInfo;
@property (nonatomic, retain) UIButton *cmd_Miscellaneous;
@property (nonatomic, retain) UIButton *cmd_Pricing;
@property (nonatomic, retain) UIButton *cmd_PriceSummary;
@property (nonatomic, retain) UIButton *cmd_PackCrateSummary;

@property (nonatomic, retain) CustomerListItem *selectedItem;
@property (nonatomic, retain) SurveySummaryController *surveySummaryController;
@property (nonatomic, retain) SurveyDatesController *datesController;
@property (nonatomic, retain) SurveyAgentsController *agentsController;
@property (nonatomic, retain) InfoController *infoController;
@property (nonatomic, retain) PVONavigationController *pvoController;
@property (nonatomic, retain) PVOClaimsSummaryController *pvoClaimsController;
@property (nonatomic, retain) PVOReceiveController *receiveController;
@property (nonatomic, retain) PVOLocationSummaryController *inventoryController;

-(IBAction)doneEditingNote:(NSString*)newNote;
-(IBAction)cmd_AgentsPressed:(id)sender;
-(IBAction)cmd_BasicInfoPressed:(id)sender;
-(IBAction)cmd_DatesPressed:(id)sender;
-(IBAction)cmd_OriginPressed:(id)sender;
-(IBAction)cmd_DestinationPressed:(id)sender;
-(IBAction)cmd_SurveyPressed:(id)sender;
-(IBAction)cmd_NotesPressed:(id)sender;
-(IBAction)cmd_MoveInfoPressed:(id)sender;
-(IBAction)cmd_MiscellaneousPressed:(id)sender;
-(IBAction)cmd_PricingPressed:(id)sender;
-(IBAction)cmd_PriceSummaryPressed:(id)sender;
-(IBAction)cmd_PackCrateSummaryPressed:(id)sender;
-(IBAction)cmd_DuplicatePressed:(id)sender;

-(void)setupView;
-(void)updateTruckProgress;
-(void)loadDocumentsLibrary;
-(void)loadReceivables;

@end
