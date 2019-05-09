//
//  ThirdPartyApplied.h
//  Survey
//
//  Created by Tony Brame on 8/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface ThirdPartyApplied : NSObject {
	int recID;
	int custID;
	int locationID;
	int quantity;
	double rate;
	int tpID;
	int companyServiceID;
	NSString *category;
	NSString *description;
	NSString *note;
}

@property (nonatomic) int recID;
@property (nonatomic) int custID;
@property (nonatomic) int locationID;
@property (nonatomic) int quantity;
@property (nonatomic) double rate;
@property (nonatomic) int tpID;
@property (nonatomic) int companyServiceID;

@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *note;

-(void)flushToXML:(XMLWriter*) xml;

- (NSComparisonResult)compareTPA:(ThirdPartyApplied *)aTP;


@end
