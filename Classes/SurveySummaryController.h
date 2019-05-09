//
//  SurveySummaryController.h
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import	"AddRoomController.h"
#import "Room.h"
#import "CubeSheet.h"
#import "ItemViewController.h"
#import "SurveyImageViewer.h"
#import "DeleteItemController.h"
#import "DeleteRoomController.h"
#import "SurveyFAQViewController.h"
#import "SyncViewController.h"

#define DELETE_ITEMS 0
#define DELETE_ROOMS 1
#define MANAGE_SMART_ITEMS 2
#define SURVEY_FAQ 3
#define SURVEY_DOWNLOAD_CUSTOM_ITEM_LISTS 3
#define SURVEY_VIEW_ALL_PHOTOS 4

#define WEIGHT_FACTOR_INCREMENT 0.25f
#define WEIGHT_FACTOR_MIN 3
#define WEIGHT_FACTOR_MAX 10

@class SurveyAppDelegate;

@interface SurveySummaryController : UIViewController 
<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, 
UIPickerViewDataSource, UIActionSheetDelegate>
{
    SurveyAppDelegate *del;
    
    AddRoomController *addRoomController;
	ItemViewController *itemView;
	NSMutableArray *summaries;
	CubeSheet *cubesheet;
	NSMutableArray *weightFactors;
	
	IBOutlet UIPickerView *pickerWeightFactor;
	IBOutlet UITableView *tblView;
	IBOutlet UIBarButtonItem *cmdWeightFactor;
	IBOutlet UIToolbar *toolbar;
	SurveyImageViewer *imageViewer;
	
	PortraitNavController *addRoomNav;
	PortraitNavController *deleteNav;
	UIPopoverController *popover;
	
	DeleteItemController *itemDelete;
	DeleteRoomController *roomDelete;
	
	SyncViewController *syncController;
	
	SurveyFAQViewController *surveyFAQ;
	
	//ipad stuff
	id caller;
	SEL roomChanged;
}

@property (nonatomic) SEL roomChanged;

@property (nonatomic, retain) id caller;

@property (nonatomic, retain) PortraitNavController *addRoomNav;
@property (nonatomic, retain) AddRoomController *addRoomController;
@property (nonatomic, retain) CubeSheet *cubesheet;
@property (nonatomic, retain) ItemViewController *itemView;
@property (nonatomic, retain) SurveyImageViewer *imageViewer;
@property (nonatomic, retain) NSMutableArray *summaries;
@property (nonatomic, retain) UIPickerView *pickerWeightFactor;
@property (nonatomic, retain) UITableView *tblView;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) NSMutableArray *weightFactors;
@property (nonatomic, retain) UIBarButtonItem *cmdWeightFactor;
@property (nonatomic, retain) DeleteItemController *itemDelete;
@property (nonatomic, retain) DeleteRoomController *roomDelete;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) SurveyFAQViewController *surveyFAQ;
@property (nonatomic, retain) SyncViewController *syncController;
@property (nonatomic) NSInteger customerID;

-(void)loadWeightFactors;
-(void)setWeightFactor;

-(IBAction) addRoom:(id)sender;

-(IBAction) changeWeightFactor:(id)sender;
-(IBAction) cancelWFChange:(id)sender;
-(IBAction) saveWFChange:(id)sender;

-(IBAction) maintenanceClick:(id)sender;

-(IBAction)roomSelected:(Room*)selection;

-(IBAction)addPhotosToRoom:(id)sender;

@end
