//
//  ThirdPartyApplied.m
//  Survey
//
//  Created by Tony Brame on 8/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ThirdPartyApplied.h"
#import "SurveyLocation.h"

@implementation ThirdPartyApplied

@synthesize recID,locationID, quantity, rate, tpID, companyServiceID, category, description, note, custID;

-(void)flushToXML:(XMLWriter*) xml
{
	[xml writeStartElement:@"third_party_item"];
	
	if(locationID == ORIGIN_LOCATION_ID)
		[xml writeAttribute:@"location" withData:@"Origin"];
	else
		[xml writeAttribute:@"location" withData:@"Destination"];
	
	[xml writeElementString:@"description" withData:description];
	
	if([note length] > 0)
		[xml writeElementString:@"third_party_note" withData:note];
	
	[xml writeElementString:@"quantity" withIntData:quantity];
	[xml writeElementString:@"qm_id" withIntData:tpID];
	[xml writeElementString:@"alt_id" withIntData:companyServiceID];
	
	[xml writeElementString:@"rate" withData:[[NSNumber numberWithDouble:rate] stringValue]];
	
	[xml writeEndElement];
	
	[note compare:@""];
}

- (NSComparisonResult)compareTPA:(ThirdPartyApplied *)aTP
{
	return [description compare:aTP.description];
}

@end
