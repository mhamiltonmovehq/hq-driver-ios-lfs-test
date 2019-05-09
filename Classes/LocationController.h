//
//  LocationController.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EditAddressController.h"
#import "EditPhoneController.h"
#import "SurveyImage.h"
#import "SurveyImageViewer.h"

#define LOCATIONS_ADDRESS_SECTION 0
#define LOCATIONS_PHONES_SECTION 1
#define LOCATIONS_ADD_SECTION 2
#define LOCATIONS_SECTIONS 3

#define LOCATIONS_ADD_ACC 0
#define LOCATIONS_ADD_TP 1
#define LOCATIONS_ADD_VAN_OP 2
#define LOCATIONS_ADD_AK 3

@interface LocationController : UITableViewController <UIActionSheetDelegate> {
	NSInteger custID;
	NSInteger locationID;
	NSMutableArray *locations;
	NSMutableArray *addRows;
	EditAddressController *editAddressController;
	EditPhoneController *phoneController;
	int imagesCount;
	UIImage *locationImage;
	SurveyImageViewer *imageViewer;
	BOOL dirty;
	BOOL goingToLocation;
	SurveyPhone *calling;
	
    BOOL lockFields;
}

@property (nonatomic) BOOL dirty;
@property (nonatomic) NSInteger custID;
@property (nonatomic) NSInteger locationID;
@property (nonatomic, retain) NSMutableArray *addRows;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, retain) EditAddressController *editAddressController;
@property (nonatomic, retain) EditPhoneController *phoneController;
@property (nonatomic, retain) SurveyImageViewer *imageViewer;
@property (nonatomic) BOOL lockFields;
@property (nonatomic) BOOL isPacker;

-(void)initializeAddRows;
-(NSString*)combineStrings:(NSArray*)strings withSplitter:(NSString*)split;

@end
