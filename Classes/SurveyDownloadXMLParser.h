//
//  SurveyDownloadXMLParser.h
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SurveyDates.h"
#import "SurveyCustomer.h"
#import "SurveyLocation.h"
#import "AddressXMLParser.h"
#import "AgentXMLParser.h"
#import "SurveyCustomerSync.h"
#import "CubeSheetParser.h"
#import "ShipmentInfo.h"
#import "PVOReportNote.h"
#import "PVODynamicReportData.h"
#import "DynamicReportDataXMLParser.h"
#import "PVOVehicle.h"

#define XML_NONE 0
#define XML_LOCATION 1
#define XML_AGENT 2
#define XML_ROOT 3
#define XML_ERROR 4

#define XML_PARENT_NODE_NONE 0
#define XML_PARENT_NODE_SURVEY_DOWNLOAD 1
#define XML_PARENT_NODE_REPORT_NOTES 2
#define XML_PARENT_NODE_DYNAMIC_REPORT_ENTRIES 3
#define XML_PARNET_NODE_VEHICLES 4

@interface SurveyDownloadXMLParser : NSObject <NSXMLParserDelegate> {
	NSMutableString *currentString;
	//parsing stuff...
	int storingType;
    int parentNode;
	SurveyDates *dates;
	ShipmentInfo *info;
	SurveyCustomer *customer;
	SurveyCustomerSync *sync;
	NSMutableArray *locations;
	NSMutableArray *agents;
    NSString *note;
    NSMutableArray *reportNotes;
    NSMutableArray *vehicles;
    PVOVehicle *currentVehicle;
	AddressXMLParser *locationParser;
	AgentXMLParser *agentParser;
	NSDateFormatter *dateFormatter;
	BOOL empty;
	BOOL error;
	BOOL atlasSync;
	NSString *errorString;
	NSString *errorID;
	NSString *surveyID;
    CubeSheetParser *csParser;
    DynamicReportDataXMLParser *dynamicDataParser;
    SurveyPhone *primaryPhone;
    PVOReportNote *rptNote;
    
}

@property (nonatomic) BOOL empty;
@property (nonatomic) BOOL error;
@property (nonatomic) BOOL atlasSync;

@property (nonatomic, retain) SurveyDates *dates;
@property (nonatomic, retain) SurveyCustomer *customer;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, retain) NSMutableArray *agents;
@property (nonatomic, retain) AddressXMLParser *locationParser;
@property (nonatomic, retain) AgentXMLParser *agentParser;
@property (nonatomic, retain) NSString *errorString;
@property (nonatomic, retain) NSString *surveyID;
@property (nonatomic, retain) NSString *errorID;
@property (nonatomic, retain) SurveyCustomerSync *sync;
@property (nonatomic, retain) NSString *note;
@property (nonatomic, retain) NSMutableArray *reportNotes;
@property (nonatomic, retain) NSMutableArray *vehicles;
@property (nonatomic, retain) PVOVehicle *currentVehicle;
@property (nonatomic, retain) CubeSheetParser *csParser;
@property (nonatomic, retain) DynamicReportDataXMLParser *dynamicDataParser;
@property (nonatomic, retain) ShipmentInfo *info;
@property (nonatomic, retain) SurveyPhone *primaryPhone;
//@property (nonatomic, retain) PVOReportNote *rptNote;

-(id)initWithAppDelegate:(SurveyAppDelegate *)del;

-(void)locationDone:(SurveyLocation*)location;
-(void)agentDone:(SurveyAgent*)agent;

-(void)updateCustomerID: (int)custID;

@end
