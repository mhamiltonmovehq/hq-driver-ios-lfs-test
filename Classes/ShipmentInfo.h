//
//  ShipmentInfo.h
//  Survey
//
//  Created by Tony Brame on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLWriter.h"

enum JOB_STATUS {
	ESTIMATE,
	BOOKED,
	LOST,
	CLOSED,
	OA
};

enum ESTIMATE_TYPE {
	EST_NONE,
	BINDING,
	NOT_TO_EXCEED,
	WEIGHT_ALLOWANCE,
	NO_WEIGHT_ALLOWANCE,
	NON_BINDING,
	ACTUAL,
	EITHER_OR,
	GUARANTEED
};

@interface ShipmentInfo : NSObject {
	int customerID;
	NSString *leadSource;
	int miles;
	NSString *orderNumber;
	int status;
	int type;
	BOOL cancelled;
	NSString *subLeadSource;
	NSString *gblNumber;
	BOOL isOA;
    BOOL sourcedFromServer;
    BOOL isAtlasFastrac;
    int language;
    int itemListID;
}

@property (nonatomic) int customerID;
@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL sourcedFromServer;
@property (nonatomic) BOOL isAtlasFastrac;
@property (nonatomic) BOOL isOA;
@property (nonatomic) int miles;
@property (nonatomic) int status;
@property (nonatomic) int type;
@property (nonatomic) int language;
@property (nonatomic) int itemListID;

@property (nonatomic, retain) NSString *leadSource;
@property (nonatomic, retain) NSString *orderNumber;
@property (nonatomic, retain) NSString *subLeadSource;
@property (nonatomic, retain) NSString *gblNumber;

-(void)flushToXML:(XMLWriter*)xml;

@end
