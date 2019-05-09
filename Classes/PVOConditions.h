//
//  PVOConditions.h
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PVOConditions : NSObject {
	NSString *code;
	NSString *description;
}

@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *description;


+(NSDictionary*)getConditionList;
+(NSDictionary*)getLocationList;

@end
