//
//  SurveyLocation.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "XMLWriter.h"
#import "SurveyPhone.h"

#define ORIGIN_LOCATION_ID 1
#define DESTINATION_LOCATION_ID 2

@interface SurveyLocation : NSObject {
    //this is the primary key...
    int locationID;
    //this is the location type.  will need to update this 
	NSInteger locationType;
	NSInteger custID;
	NSString *name;
	NSString *companyName;
	NSString *firstName;
	NSString *lastName;
	NSString *address1;
	NSString *address2;
	NSString *city;
	NSString *state;
	NSString *zip;
	NSString *county;
	BOOL isOrigin;
	int sequence;
	NSMutableArray *phones;
}

@property (nonatomic) int locationID;
@property (nonatomic) NSInteger locationType;
@property (nonatomic) NSInteger custID;
@property (nonatomic) BOOL isOrigin;
@property (nonatomic) int sequence;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *companyName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *address1;
@property (nonatomic, strong) NSString *address2;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *county;
@property (nonatomic, strong) NSMutableArray *phones;

-(NSString*)buildQueryString;
-(void)flushToXML:(XMLWriter*)xml withPhones:(NSArray*)fones;
-(BOOL)isAlaska;
-(BOOL)isCanadian;

-(SurveyLocation*)initWithStatement:(sqlite3_stmt*)stmnt;

@end
