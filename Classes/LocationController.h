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

#define PHONE_1_ROW 0
#define PHONE_2_ROW 1

#define PHONE_1 5
#define PHONE_2 6

@interface LocationController : PVOBaseTableViewController <UIActionSheetDelegate, UITextFieldDelegate> {
	int imagesCount;
	UIImage *locationImage;
	BOOL goingToLocation;
	SurveyPhone *calling;
}

@property (nonatomic) BOOL dirty;
@property (nonatomic) NSInteger custID;
@property (nonatomic) NSInteger locationID;
@property (nonatomic, strong) NSMutableArray *addRows;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) EditAddressController *editAddressController;
@property (nonatomic, strong) EditPhoneController *phoneController;
@property (nonatomic, strong) SurveyImageViewer *imageViewer;
@property (nonatomic) BOOL lockFields;
@property (nonatomic) BOOL isPacker;
@property (nonatomic, strong) SurveyPhone *phone1;
@property (nonatomic, strong) SurveyPhone *phone2;


-(void)initializeAddRows;
-(NSString*)combineStrings:(NSArray*)strings withSplitter:(NSString*)split;
-(BOOL)isOrigin;

@end
