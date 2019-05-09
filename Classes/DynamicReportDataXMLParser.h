//
//  DynamicReportDataXMLParser.h
//  Survey
//
//  Created by Justin on 7/14/15.
//
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

#define XML_NONE 0
#define XML_LOCATION 1
#define XML_AGENT 2
#define XML_ROOT 3
#define XML_ERROR 4

#define XML_PARENT_NODE_NONE 0
#define XML_PARENT_NODE_SURVEY_DOWNLOAD 1
#define XML_PARENT_NODE_REPORT_NOTES 2
#define XML_PARENT_NODE_DYNAMIC_REPORT_ENTRIES 3

@interface DynamicReportDataXMLParser : NSObject <NSXMLParserDelegate> {

    NSObject *parent;
    NSMutableString *currentString;
//    SEL callback;
    BOOL storingData;
    
    NSDateFormatter *dateFormatter;
    
    NSMutableArray *dynamicData;
    PVODynamicReportData *rptData;
}

//@property (nonatomic) SEL callback;

@property (nonatomic, strong) NSObject *parent;

@property (nonatomic, strong) NSMutableArray *dynamicData;
@property (nonatomic, strong) PVODynamicReportData *rptData;

@end
