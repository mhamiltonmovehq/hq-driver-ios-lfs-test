//
//  DriverData.m
//  Survey
//
//  Created by Tony Brame on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DriverData.h"
#import "AppFunctionality.h"

@implementation DriverData

@synthesize vanlineID;
@synthesize haulingAgent;
@synthesize safetyNumber;
@synthesize driverName;
@synthesize driverNumber;
@synthesize haulingAgentEmail;
@synthesize driverEmail, driverPassword, reportPreference, syncPreference;
@synthesize unitNumber, buttonPreference, enableRoomConditions, tractorNumber, quickInventory, saveToCameraRoll;
@synthesize driverType, haulingAgentEmailCC, haulingAgentEmailBCC, driverEmailCC, driverEmailBCC;
@synthesize packerName, packerEmail, packerEmailCC, packerEmailBCC;
@synthesize showTractorTrailerOptions, language;
@synthesize crmUsername, crmPassword, crmEnvironment;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.haulingAgent = @"";
        self.safetyNumber = @"";
        self.driverName = @"";
        self.driverNumber = @"";
        self.haulingAgentEmail = @"";
        self.driverEmail = @"";
        self.unitNumber = @"";
        self.driverPassword = @"";
        self.crmUsername = @"";
        self.crmPassword = @"";
        self.packerName = @"";
        self.packerEmail = @"";
        
        enableRoomConditions = TRUE;
        quickInventory = FALSE;
        showTractorTrailerOptions = FALSE;
    }
    return self;
}

-(void)flushToXML:(XMLWriter*)xml
{
	[xml writeStartElement:@"pvo_driver_data"];
    
	[xml writeElementString:@"van_line_id" withIntData:vanlineID];
	[xml writeElementString:@"hauling_agent" withData:haulingAgent];
	[xml writeElementString:@"safety_number" withData:safetyNumber];
	[xml writeElementString:@"driver_number" withData:driverNumber];
	[xml writeElementString:@"driver_password" withData:driverPassword];
	[xml writeElementString:@"hauling_agent_email" withData:haulingAgentEmail];
    
    if(self.driverType == PVO_DRIVER_TYPE_DRIVER) {
        [xml writeElementString:@"driver_name" withData:driverName];
        [xml writeElementString:@"driver_email" withData:driverEmail];
    } else if(self.driverType == PVO_DRIVER_TYPE_PACKER) {
        [xml writeElementString:@"driver_name" withData:packerName];
        [xml writeElementString:@"driver_email" withData:packerEmail];
    } else {
        [xml writeElementString:@"driver_name" withData:@""];
        [xml writeElementString:@"driver_email" withData:@""];
    }
    
    if ([AppFunctionality showTractorTrailerAlways] || ![AppFunctionality showTractorTrailerOptional] || self.showTractorTrailerOptions)
    {
        [xml writeElementString:@"unit_number" withData:unitNumber];
        [xml writeElementString:@"tractor_number" withData:tractorNumber];
    }
    else
    {
        [xml writeElementString:@"unit_number" withData:@""];
        [xml writeElementString:@"tractor_number" withData:@""];
    }
    
#ifdef ATLASNET
    [xml writeElementString:@"damages_report_view" withData:@"Descriptions"];
#else
    if(reportPreference == PVO_DRIVER_REPORT_DESCRIPTIONS)
        [xml writeElementString:@"damages_report_view" withData:@"Descriptions"];
    else
        [xml writeElementString:@"damages_report_view" withData:@"Codes"];
#endif
	
    if(self.driverType == PVO_DRIVER_TYPE_NONE)
        [xml writeElementString:@"driver_type" withData:@"None"];
    else if(self.driverType == PVO_DRIVER_TYPE_DRIVER)
        [xml writeElementString:@"driver_type" withData:@"Driver"];
    else if(self.driverType == PVO_DRIVER_TYPE_PACKER)
        [xml writeElementString:@"driver_type" withData:@"Packer"];
    
	[xml writeEndElement];
}

@end
