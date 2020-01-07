//
//  ShipmentInfo.m
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ShipmentInfo.h"


@implementation ShipmentInfo

@synthesize miles, status, type, leadSource, orderNumber, customerID, cancelled, subLeadSource, isOA, gblNumber, sourcedFromServer, isAtlasFastrac, language, itemListID;

-(void)flushToXML:(XMLWriter*)xml
{
	
	[xml writeElementString:@"lead_source" withData:leadSource];
	[xml writeElementString:@"sub_lead_source" withData:subLeadSource];
	
	if(isOA)
	{
		[xml writeElementString:@"job_status" withData:@"OA"];
	}
	else
	{
		switch (status) {
			case ESTIMATE:
				[xml writeElementString:@"job_status" withData:@"Estimate"];
				break;
			case BOOKED:
				[xml writeElementString:@"job_status" withData:@"Booked"];
				break;
			case CLOSED:
				[xml writeElementString:@"job_status" withData:@"Closed"];
				break;
			case LOST:
				[xml writeElementString:@"job_status" withData:@"Lost"];
				break;
			case OA:
				[xml writeElementString:@"job_status" withData:@"OA"];
				break;
            case PACKED:
                [xml writeElementString:@"job_status" withData:@"Pack"];
                break;
            case LOAD:
                [xml writeElementString:@"job_status" withData:@"Load"];
                break;
            case IN_TRANSIT:
                [xml writeElementString:@"job_status" withData:@"In Transit"];
                break;
            case IN_STORAGE:
                [xml writeElementString:@"job_status" withData:@"In Storage"];
                break;
            case OUT_FOR_DELIVERY:
                [xml writeElementString:@"job_status" withData:@"Out for Delivery"];
                break;
            case DELIVERED:
                [xml writeElementString:@"job_status" withData:@"Delivered"];
                break;
		}
	}
	
	[xml writeElementString:@"order_number" withData:orderNumber];
	[xml writeElementString:@"gbl_number" withData:gblNumber];
	
	[xml writeElementString:@"is_OA" withData:isOA ? @"true" : @"false"];
    
    [xml writeElementString:@"language_code" withIntData:language];
    
    [xml writeElementString:@"sourced_from_server" withData:sourcedFromServer ? @"true" : @"false"];
    
//    if (isAtlasFastrac) //don't need this in the XML right now so i'm not including it. Only using it in the document upload method
//        [xml writeElementString:@"is_fastrac" withData: @"true"];
}

@end
