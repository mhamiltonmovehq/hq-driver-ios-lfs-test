//
//  SurveyLocation.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyLocation.h"
#import "SurveyImage.h"
#import "AppFunctionality.h"
#import "SurveyAppDelegate.h"
#import "SurveyDB.h"

@implementation SurveyLocation

@synthesize custID, locationType, name, companyName, firstName, lastName, address1, address2, city, state, zip, phones, isOrigin, sequence, county;
@synthesize locationID;

-(id)init
{
	if( (self = [super init]) )
	{
		phones = [[NSMutableArray alloc] init];
	}
	return self;
}

//expects CustomerID,LocationType,Name,Address1,Address2,City,State,Zip,County,IsOrigin,Sequence,Lat,Long,LocationID
-(SurveyLocation*)initWithStatement:(sqlite3_stmt*)stmnt
{
	if( (self = [super init]) )
	{
		phones = [[NSMutableArray alloc] init];
        self.custID = sqlite3_column_int(stmnt, 0);
        self.locationType = sqlite3_column_int(stmnt, 1);
        self.name = [SurveyDB stringFromStatement:stmnt columnID:2];
        self.address1 = [SurveyDB stringFromStatement:stmnt columnID:3];
        self.address2 = [SurveyDB stringFromStatement:stmnt columnID:4];
        self.city = [SurveyDB stringFromStatement:stmnt columnID:5];
        self.state = [SurveyDB stringFromStatement:stmnt columnID:6];
        self.zip = [SurveyDB stringFromStatement:stmnt columnID:7];
        self.county = [SurveyDB stringFromStatement:stmnt columnID:8];
        self.isOrigin = sqlite3_column_int(stmnt, 9) > 0;
        self.sequence = sqlite3_column_int(stmnt, 10);
        self.locationID = sqlite3_column_double(stmnt, 11);
        self.companyName = [SurveyDB stringFromStatement:stmnt columnID:12];
        self.firstName = [SurveyDB stringFromStatement:stmnt columnID:13];
        self.lastName = [SurveyDB stringFromStatement:stmnt columnID:14];
	}
	return self;
}

-(BOOL)isAlaska
{
	BOOL isAK = FALSE;
	NSString *zip3;
	if(zip != nil && [zip length] >= 3)
	{
		zip3 = [zip substringToIndex:3];
		if([zip3 isEqualToString:@"995"] || 
		   [zip3 isEqualToString:@"996"] || 
		   [zip3 isEqualToString:@"997"] || 
		   [zip3 isEqualToString:@"998"] || 
		   [zip3 isEqualToString:@"999"])
			isAK = TRUE;
	}
	
	return isAK;
}

-(NSString*)buildQueryString
{
	return [[NSString alloc] initWithFormat:@"%@, %@ %@ %@", address1, city, state, zip];	
}

-(void)flushToXML:(XMLWriter*)xml withPhones:(NSArray*)fones
{
	if(locationType == ORIGIN_LOCATION_ID)
		[xml writeStartElement:@"origin_info"];
	else if(locationType == DESTINATION_LOCATION_ID)
		[xml writeStartElement:@"dest_info"];
	else
	{
		[xml writeStartElement:@"location"];
		
		[xml writeElementString:@"id" withData:name];
		[xml writeElementString:@"orig_dest" withData:isOrigin ? @"Origin" : @"Destination"];
		[xml writeElementString:@"sequence" withIntData:sequence];
		
		[xml writeStartElement:@"address"];
	}
	
    [xml writeElementString:@"company_name" withData:companyName];
    [xml writeElementString:@"first_name" withData:firstName];
    [xml writeElementString:@"last_name" withData:lastName];
	[xml writeElementString:@"add1" withData:address1];
	[xml writeElementString:@"add2" withData:address2];
	[xml writeElementString:@"city" withData:city];
	[xml writeElementString:@"state" withData:state];
	[xml writeElementString:@"zip" withData:zip];
	[xml writeElementString:@"county" withData:county];
	
	//add in phones
	SurveyPhone *phone;
	for(int i = 0; fones != nil && i < [fones count]; i++)
	{
		phone = [fones objectAtIndex:i];
		if([phone.type.name isEqualToString:@"Home"]){
			[xml writeElementString:@"home_phone" withData:phone.number];
		}
		else if([phone.type.name isEqualToString:@"Work"]){
			[xml writeElementString:@"work_phone" withData:phone.number];
		}
		else if([phone.type.name isEqualToString:@"Mobile"]){
			[xml writeElementString:@"mobile_phone" withData:phone.number];
		}
		else{
			[xml writeElementString:@"other_phone" withData:phone.number];
		}
	}
    if(locationType == ORIGIN_LOCATION_ID || locationType == DESTINATION_LOCATION_ID)
        [self addImagesToLocation:xml];
    
	[xml writeEndElement];
	
	if(locationType != ORIGIN_LOCATION_ID && locationType != DESTINATION_LOCATION_ID)
    {
        [self addImagesToLocation:xml];
		[xml writeEndElement];
    }
    
}

-(void)addImagesToLocation:(XMLWriter*)xml
{
    if ([AppFunctionality addImageLocationsToXML])
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray *locationImages = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_LOCATIONS withSubID:locationType loadAllItems:NO];
        
        [xml writeStartElement:@"images"];
        
        for (SurveyImage *surveyImage in locationImages)
        {
            NSFileManager *mgr = [NSFileManager defaultManager];
            
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            if([mgr fileExistsAtPath:[docsDir stringByAppendingString:surveyImage.path]])
            {
                [xml writeStartElement:@"image"];
                [xml writeAttribute:@"location" withData:[NSString stringWithFormat:@"%@",[SurveyAppDelegate getLastTwoPathComponents:surveyImage.path]]];
                [xml writeAttribute:@"photoType" withIntData:surveyImage.photoType];
                [xml writeAttribute:@"description" withData:[NSString stringWithFormat:@"%@ %@ %@", self.name, self.address1, self.zip]];
                [xml writeEndElement]; //end image
            }
        }
        [xml writeEndElement]; //end images
    
    }
}

-(BOOL)isCanadian
{
	if(zip != nil && [zip length] > 0)
	{
		if([zip characterAtIndex:0] < 48 ||
		   [zip characterAtIndex:0] > 57)
			return TRUE;
	}
	return FALSE;
}

@end
