//
//  SurveyAgent.h
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

#define AGENT_BOOKING 0
#define AGENT_ORIGIN 1
#define AGENT_DESTINATION 2

@interface SurveyAgent : NSObject {
	int	itemID;
	int	agencyID;
	NSString *code;
	NSString *name;
	NSString *address;
	NSString *city;
	NSString *state;
	NSString *zip;
	NSString *phone;
	NSString *email;
	NSString *contact;
}

@property (nonatomic) int itemID;
@property (nonatomic) int agencyID;

@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *contact;

-(void)flushToXML:(XMLWriter*)xml;

@end
