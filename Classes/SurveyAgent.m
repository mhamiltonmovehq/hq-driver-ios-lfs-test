//
//  SurveyAgent.m
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyAgent.h"


@implementation SurveyAgent

@synthesize itemID, name, code, address, city, state, zip, email, contact, phone, agencyID;

-(void)flushToXML:(XMLWriter*)xml
{
	switch (agencyID) {
		case AGENT_BOOKING:
			[xml writeStartElement:@"booking_agent"];
			break;
		case AGENT_ORIGIN:
			[xml writeStartElement:@"origin_agent"];
			break;
		case AGENT_DESTINATION:
			[xml writeStartElement:@"dest_agent"];
			break;
		default:
			break;
	}
	
	[xml writeElementString:@"code" withData:code];
	[xml writeElementString:@"name" withData:name];
	[xml writeElementString:@"add1" withData:address];
	[xml writeElementString:@"city" withData:city];
	[xml writeElementString:@"state" withData:state];
	[xml writeElementString:@"zip" withData:zip];
	[xml writeElementString:@"phone" withData:phone];
	[xml writeElementString:@"contact" withData:contact];
	[xml writeElementString:@"fax" withData:@""];
	[xml writeElementString:@"email" withData:email];
	
	[xml writeEndElement];
}

@end
