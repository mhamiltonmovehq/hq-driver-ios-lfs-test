//
//  ReportDefaults.h
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ReportDefaults : NSObject {
	NSString *agentEmail;
	NSString *agentName;
	NSString *toEmail;
	NSString *subject;
	NSString *body;
	BOOL newRec;
    BOOL sendFromDevice;
}

@property (nonatomic) BOOL newRec;
@property (nonatomic) BOOL sendFromDevice;

@property (nonatomic, retain) NSString *agentEmail;
@property (nonatomic, retain) NSString *toEmail;
@property (nonatomic, retain) NSString *agentName;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *body;

@end
