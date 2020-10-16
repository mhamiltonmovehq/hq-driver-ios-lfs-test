//
//  DriverData.h
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

#define PVO_DRIVER_DAMAGE_ASK 0
#define PVO_DRIVER_DAMAGE_WHEEL 1
#define PVO_DRIVER_DAMAGE_BUTTON 2

#define PVO_DRIVER_REPORT_DESCRIPTIONS 0
#define PVO_DRIVER_REPORT_CODES 1

#define PVO_ARPIN_SYNC_BY_DRIVER 0
#define PVO_ARPIN_SYNC_BY_AGENT 1

#define PVO_DRIVER_TYPE_NONE 0
#define PVO_DRIVER_TYPE_DRIVER 1
#define PVO_DRIVER_TYPE_PACKER 2

#define PVO_DRIVER_EMAIL_TYPE_NONE 0
#define PVO_DRIVER_EMAIL_TYPE_CC 1
#define PVO_DRIVER_EMAIL_TYPE_BCC 2

#define PVO_DRIVER_CRM_ENVIRONMENT_DEV 0
#define PVO_DRIVER_CRM_ENVIRONMENT_QA 1
#define PVO_DRIVER_CRM_ENVIRONMENT_PROD 2
#define PVO_DRIVER_CRM_ENVIRONMENT_UAT 3


@interface DriverData : NSObject {
    int vanlineID;
    NSString *haulingAgent;
    NSString *safetyNumber;
    NSString *driverName;
    NSString *driverNumber;
    NSString *haulingAgentEmail;
    NSString *driverEmail;
    NSString *unitNumber;
    NSString *driverPassword;
    NSString *tractorNumber;
    NSString *crmUsername;
    NSString *crmPassword;
    int crmEnvironment;
    int buttonPreference;
    int reportPreference;
    int syncPreference;
    int language;
    
    BOOL enableRoomConditions;
    BOOL quickInventory;
    BOOL saveToCameraRoll;
    
    BOOL haulingAgentEmailCC;
    BOOL haulingAgentEmailBCC;
    BOOL driverEmailCC;
    BOOL driverEmailBCC;
}

@property (nonatomic) int vanlineID;
@property (nonatomic) int buttonPreference;
@property (nonatomic) int reportPreference;
@property (nonatomic) int syncPreference;
@property (nonatomic) int language;
@property (nonatomic) int driverType;
@property (nonatomic) int crmEnvironment;
@property (nonatomic) BOOL enableRoomConditions;
@property (nonatomic) BOOL quickInventory;
@property (nonatomic) BOOL showTractorTrailerOptions;
@property (nonatomic) BOOL saveToCameraRoll;
@property (nonatomic) BOOL haulingAgentEmailCC;
@property (nonatomic) BOOL haulingAgentEmailBCC;
@property (nonatomic) BOOL driverEmailCC;
@property (nonatomic) BOOL driverEmailBCC;
@property (nonatomic) BOOL packerEmailCC;
@property (nonatomic) BOOL packerEmailBCC;
@property (nonatomic) BOOL useScanner;

@property (nonatomic, retain) NSString *crmUsername;
@property (nonatomic, retain) NSString *crmPassword;
@property (nonatomic, retain) NSString *haulingAgent;
@property (nonatomic, retain) NSString *safetyNumber;
@property (nonatomic, retain) NSString *driverName;
@property (nonatomic, retain) NSString *driverNumber;
@property (nonatomic, retain) NSString *haulingAgentEmail;
@property (nonatomic, retain) NSString *driverEmail;
@property (nonatomic, retain) NSString *unitNumber;
@property (nonatomic, retain) NSString *driverPassword;
@property (nonatomic, retain) NSString *tractorNumber;
@property (nonatomic, retain) NSString *packerName;
@property (nonatomic, retain) NSString *packerEmail;

-(void)flushToXML:(XMLWriter*)xml;

@end
