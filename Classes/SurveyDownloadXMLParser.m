//
//  CustomerXMLParser.m
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyDownloadXMLParser.h"
#import "AddressXMLParser.h"
#import "AgentXMLParser.h"
#import "SurveyAppDelegate.h"

@interface SurveyDownloadXMLParser ()

@property (nonatomic, assign) SurveyAppDelegate *appDelegate;

@end

@implementation SurveyDownloadXMLParser

@synthesize locationParser, agentParser, dates, customer, locations, agents, empty;
@synthesize errorString, errorID, error, sync, note, atlasSync, reportNotes, vehicles, currentVehicle, surveyID, csParser, info;
@synthesize primaryPhone;
@synthesize dynamicDataParser;

-(void)dealloc
{
    _appDelegate = nil;
}

-(id)initWithAppDelegate:(SurveyAppDelegate *)del
{
    if(self = [super init])
    {
        _appDelegate = del;
        customer = [[SurveyCustomer alloc] init];
        sync = [[SurveyCustomerSync alloc] init];
        dates = [[SurveyDates alloc] init];
        info = [[ShipmentInfo alloc] init];
        [dates setToToday:NO]; // leave pack/load/deliver at null
        dates.noPack = YES;
        dates.noLoad = YES;
        dates.noDeliver = YES;
        currentString = [[NSMutableString alloc] init];
        locations = [[NSMutableArray alloc] init];
        agents = [[NSMutableArray alloc] init];
        locationParser = [[AddressXMLParser alloc] init];
        locationParser.parent = self;
        locationParser.callback = @selector(locationDone:);
        agentParser = [[AgentXMLParser alloc] init];
        agentParser.parent = self;
        agentParser.callback = @selector(agentDone:);
        
        csParser = [[CubeSheetParser alloc] initWithAppDelegate:_appDelegate];
        csParser.parent = self;
        dynamicDataParser = [[DynamicReportDataXMLParser alloc] init];
        dynamicDataParser.parent = self;
        
        reportNotes = [[NSMutableArray alloc] init];
        
        vehicles = [[NSMutableArray alloc] init];
        
        primaryPhone = [[SurveyPhone alloc] init];
        primaryPhone.locationID = 1;
        primaryPhone.type = [[PhoneType alloc] init];
        primaryPhone.type.name = @"Primary";
        
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        empty = TRUE;
        error = FALSE;
    
    }
    return self;
}

-(void)updateCustomerID: (int)custID
{
    info.customerID = custID;
    sync.custID = custID;
    customer.custID = custID;
    dates.custID = custID;
    
    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [locations count]; i++)
    {
        SurveyLocation *loc = [locations objectAtIndex:i];
        loc.custID = custID;
        [tempArr addObject:loc];
    }
    
    self.locations = tempArr;
    
    tempArr = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [agents count]; i++)
    {
        SurveyAgent *agent = [agents objectAtIndex:i];
        agent.itemID = custID;
        [tempArr addObject:agent];
    }
    
    self.agents = tempArr;
}

-(void)locationDone:(SurveyLocation*)location
{
    [locations addObject:location];
}

-(void)agentDone:(SurveyAgent*)agent;
{
    [agents addObject:agent];
}


#pragma mark NSXMLParser Parsing Callbacks

// Constants for the XML element names that will be considered during the parse. 
// Declaring these as static constants reduces the number of objects created during the run
// and is less prone to programmer error.


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
    if([elementName isEqualToString:@"error"]){
        error = TRUE;
        storingType = XML_ERROR;		
    }
    else if([elementName isEqualToString:@"error_survey"]){ 
        error = TRUE;
        storingType = XML_ERROR;		
    }
    else if([elementName isEqualToString:@"survey_download"]){ 
//		empty = FALSE;
        parentNode = XML_PARENT_NODE_SURVEY_DOWNLOAD;
    }
    else if ([elementName isEqualToString:@"pvo_vehicles"]) {
        parentNode = XML_PARNET_NODE_VEHICLES;
    }
    else if ([elementName isEqualToString:@"vehicle"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle = [[PVOVehicle alloc] init];
    }
    else if ([elementName isEqualToString:@"origin_info"] || 
             [elementName isEqualToString:@"dest_info"] || 
             [elementName isEqualToString:@"location"])
    {
        SurveyLocation *loc = [[SurveyLocation alloc] init];
        loc.isOrigin = [elementName isEqualToString:@"origin_info"];//if it is an ex stop, isOrigin will be set in parser
        loc.phones = [[NSMutableArray alloc] init];
        locationParser.location = loc;
        locationParser.nodeName = elementName;
        [parser setDelegate:locationParser];
    }
    else if([elementName isEqualToString:@"origin_agent"] || 
            [elementName isEqualToString:@"dest_agent"] ||
            [elementName isEqualToString:@"booking_agent"])
    {
        agentParser.agent = [[SurveyAgent alloc] init];
        agentParser.nodeName = elementName;
        [parser setDelegate:agentParser];
    }
    else if([elementName isEqualToString:@"cube_sheet"]){
        [parser setDelegate:csParser];
    }
	else if([elementName isEqualToString:@"local_data"]){
		customer.pricingMode = LOCAL;
    }
	else if([elementName isEqualToString:@"interstate_data"]){
		customer.pricingMode = INTERSTATE;
    }
    else if([elementName isEqualToString:@"report_notes"]){
        parentNode = XML_PARENT_NODE_REPORT_NOTES;
    }
    else if(parentNode == XML_PARENT_NODE_REPORT_NOTES && [elementName isEqualToString:@"report_note"]) {
        if (attributeDict != nil && [attributeDict count] > 0) {
            rptNote = [[PVOReportNote alloc] init];
            if ([attributeDict objectForKey:@"type"] != nil)
                rptNote.pvoReportNoteTypeID = [[attributeDict objectForKey:@"type"] intValue];
            if ([attributeDict objectForKey:@"note"] != nil)
                rptNote.reportNote = [NSString stringWithString:[attributeDict objectForKey:@"note"]];
            
        }
    }
    else if ([elementName isEqualToString:@"dynamic_report_entries"])
    {
        [parser setDelegate:dynamicDataParser];
    }
    else if([elementName isEqualToString:@"sync_field"] ||
            [elementName isEqualToString:@"first_name"] || 
            [elementName isEqualToString:@"last_name"] ||
            [elementName isEqualToString:@"company_name"] ||
            [elementName isEqualToString:@"email_address"] ||
            [elementName isEqualToString:@"email"] || //backwards compatible with older XML
            [elementName isEqualToString:@"primary_phone"] || 
            [elementName isEqualToString:@"weight_factor"] ||
            [elementName isEqualToString:@"total_weight"] ||
            [elementName isEqualToString:@"weight_override"] ||
			[elementName isEqualToString:@"pricing_mode"] || 
			[elementName isEqualToString:@"pack_from"] || 
			[elementName isEqualToString:@"pack_to"] ||
			[elementName isEqualToString:@"pack_prefer"] ||
			[elementName isEqualToString:@"load_from"] || 
			[elementName isEqualToString:@"load_to"] ||
			[elementName isEqualToString:@"load_prefer"] ||
			[elementName isEqualToString:@"deliver_from"] || 
			[elementName isEqualToString:@"deliver_to"] ||
			[elementName isEqualToString:@"deliver_prefer"] ||
			[elementName isEqualToString:@"survey_date"] || 
			[elementName isEqualToString:@"survey_time"] ||
            ([elementName isEqualToString:@"notes"] && parentNode == XML_PARENT_NODE_SURVEY_DOWNLOAD) ||
			[elementName isEqualToString:@"lead_source"] || 
			[elementName isEqualToString:@"sub_lead_source"] || 
			[elementName isEqualToString:@"fuel_surcharge"] || 
			[elementName isEqualToString:@"irr"] || 
			[elementName isEqualToString:@"miles"] || 
			[elementName isEqualToString:@"is_OA"] ||
			[elementName isEqualToString:@"order_number"] ||
            [elementName isEqualToString:@"sourced_from_server"] ||
            [elementName isEqualToString:@"is_fastrac"] ||
			[elementName isEqualToString:@"inventory_date"] ||
            [elementName isEqualToString:@"gbl_number"] ||
            ([elementName isEqualToString:@"VIN"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"Make"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"Model"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"Year"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"Color"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"Odometer"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"LicenseState"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"License"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"VehicleType"] && parentNode == XML_PARNET_NODE_VEHICLES) ||
            ([elementName isEqualToString:@"ServerID"] && parentNode == XML_PARNET_NODE_VEHICLES)
            )
    {
        //all root data
        empty = FALSE;
        [currentString setString:@""];
        storingType = XML_ROOT;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    //check to see that it was opened properly, and not in another node (with same name)
    //i dont have to worry about locations or agents as they are handled in their parsers.
    
    /*if (storingType == XML_LOCATION && [elementName isEqualToString:@"origin_info"]){
        //parse the location using a location parser...
        
        //NSLog(currentString);
        
        storingType = XML_NONE;
    }else if(storingType == XML_LOCATION && [elementName isEqualToString:@"dest_info"]){
        storingType = XML_NONE;
    }else if(storingType == XML_AGENT && [elementName isEqualToString:@"origin_info"]){
        //parse the agent using an agent parser...
        
        storingType = XML_NONE;
    }else if(storingType == XML_AGENT && [elementName isEqualToString:@"origin_agent"]){
        storingType = XML_NONE;
    }else if(storingType == XML_AGENT && [elementName isEqualToString:@"dest_agent"]){
        storingType = XML_NONE;
    }else if(storingType == XML_AGENT && [elementName isEqualToString:@"booking_agent"]){
        storingType = XML_NONE;
    }else */
    
    NSString *temp = [[NSString alloc] initWithString:currentString];
    NSDate *date = [[NSDate alloc] init];
    
    if([elementName isEqualToString:@"error"]){
        self.errorString = temp;
    }else if([elementName isEqualToString:@"error_survey"]){
        self.errorID = temp;
    }else if([elementName isEqualToString:@"survey_download"]){
        //we dont care!  if it downloaded, it was a success!(maybe empty)... crud...
//		if([sync.generalSyncID length] == 0 && [info.orderNumber length] == 0)
//		{
//			//got to the end of the record, and didnt have a sync id
//			empty = TRUE;
//		}
        parentNode = XML_PARENT_NODE_NONE;
    }else if(parentNode == XML_PARENT_NODE_REPORT_NOTES && [elementName isEqualToString:@"report_note"]){
        [reportNotes addObject:rptNote];
        rptNote = nil;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"sync_field"]){
        empty = FALSE;
        //split values
        NSRange commaLoc = [temp rangeOfString:@","];
        if(commaLoc.location == NSNotFound && !atlasSync)
            sync.generalSyncID = temp;
        else if (atlasSync)
        {
            if(commaLoc.location != NSNotFound)
            {
                sync.atlasShipID = [temp substringWithRange:NSMakeRange(1, commaLoc.location-1)];
                sync.atlasSurveyID = [temp substringFromIndex:commaLoc.location+1];
            }
            else
                sync.atlasShipID = temp;
        }
        else
        {
            sync.generalSyncID = [temp substringWithRange:NSMakeRange(0, commaLoc.location)];
            self.surveyID = [temp substringFromIndex:commaLoc.location+1];
        }
        
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"first_name"]){
        customer.firstName = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"last_name"]){
        customer.lastName = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"company_name"]){
        customer.companyName = temp;
    }else if(storingType == XML_ROOT && ([elementName isEqualToString:@"email_address"] || [elementName isEqualToString:@"email"])){
        if(customer.email == nil || [customer.email length] == 0)
            customer.email = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"primary_phone"]){
        primaryPhone.number = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"notes"]){
        self.note = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"weight_factor"]){
        //no need as wf will always be 7
    }else if (storingType == XML_ROOT && ([elementName isEqualToString:@"total_weight"] || [elementName isEqualToString:@"weight_override"])) {
        customer.estimatedWeight = [temp integerValue];
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"pricing_mode"]){
		if([temp isEqualToString:@"Local"])
			customer.pricingMode = LOCAL;
		else
			customer.pricingMode = INTERSTATE;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"pack_from"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        //i am honestly not sure why date needs retained wwhen assigning to these propeties, but it took me forever to find this bug
        dates.packFrom = date;
        dates.noPack = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"pack_to"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.packTo = date;
        dates.noPack = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"pack_prefer"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.packPrefer = date;
        dates.noPack = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"load_from"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.loadFrom = date;
        dates.noLoad = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"load_to"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.loadTo = date;
        dates.noLoad = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"load_prefer"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.loadPrefer = date;
        dates.noLoad = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"inventory_date"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.inventory = date;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"deliver_from"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.deliverFrom = date;
        dates.noDeliver = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"deliver_to"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.deliverTo = date;
        dates.noDeliver = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"deliver_prefer"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.deliverPrefer = date;
        dates.noDeliver = NO;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"survey_date"]){
        [dateFormatter getObjectValue:&date forString:temp errorDescription:nil];
        dates.survey = date;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"survey_time"]){
        
        NSDateFormatter *time = [[NSDateFormatter alloc] init];
        [time setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [time setDateFormat:@"hh:mm a"];
        NSDate *tempdate = [time dateFromString:temp];
        tempdate = [dates.survey dateByAddingTimeInterval:[tempdate timeIntervalSince1970]];
//        tempdate = [dates.survey addTimeInterval:[tempdate timeIntervalSince1970]]; //deprecated
        dates.survey = tempdate;
        
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"lead_source"]){
        info.leadSource = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"sub_lead_source"]){
        info.subLeadSource = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"miles"]){
        info.miles = [temp intValue];
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"is_OA"]){
        info.isOA = [temp isEqualToString:@"true"];
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"order_number"]){
        info.orderNumber = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"sourced_from_server"]){
		info.sourcedFromServer = [temp isEqualToString:@"true"];
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"gbl_number"]){
        info.gblNumber = temp;
    }else if(storingType == XML_ROOT && [elementName isEqualToString:@"is_fastrac"]){
        info.isAtlasFastrac = [temp isEqualToString:@"true"];
    }else if ([elementName isEqualToString:@"vehicle"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        [vehicles addObject:currentVehicle];
        currentVehicle = nil;
    } else if ([elementName isEqualToString:@"VIN"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.vin = temp;
    } else if ([elementName isEqualToString:@"Make"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.make = temp;
    } else if ([elementName isEqualToString:@"Model"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.model = temp;
    } else if ([elementName isEqualToString:@"Year"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.year = temp;
    } else if ([elementName isEqualToString:@"Color"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.color = temp;
    } else if ([elementName isEqualToString:@"Odometer"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.odometer = temp;
    } else if ([elementName isEqualToString:@"LicenseState"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.licenseState = temp;
    } else if ([elementName isEqualToString:@"License"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.license = temp;
    } else if ([elementName isEqualToString:@"VehicleType"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.type = temp;
        
        NSString *vehType = [temp lowercaseString];
        if ([vehType isEqualToString:@"car"]) {
            currentVehicle.wireframeType = WT_CAR;
        } else if ([vehType isEqualToString:@"suv"]) {
            currentVehicle.wireframeType = WT_SUV;
        } else if ([vehType isEqualToString:@"truck"]) {
            currentVehicle.wireframeType = WT_TRUCK;
        }

    } else if ([elementName isEqualToString:@"ServerID"] && parentNode == XML_PARNET_NODE_VEHICLES) {
        currentVehicle.serverID = [temp intValue];
    }
    
    
    
    
    storingType = XML_NONE;
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if(storingType != XML_NONE) 
        [currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
