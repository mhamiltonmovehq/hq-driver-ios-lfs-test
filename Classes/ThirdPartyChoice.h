//
//  ThirdPartyChoice.h
//  Survey
//
//  Created by Tony Brame on 8/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ThirdPartyChoice : NSObject {
	int tpID;
	int companyServiceID;
	NSString *description;
	NSString *category;
	double rate;
}

@property (nonatomic) int tpID;
@property (nonatomic) int companyServiceID;
@property (nonatomic) double rate;

@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *category;

@end
