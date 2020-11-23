//
//  SurveyPhone.m
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyPhone.h"


@implementation SurveyPhone

@synthesize custID, locationTypeId, type, number, isPrimary;

-(id)init
{
    if(self = [super init])
    {
        self.type = [[PhoneType alloc] init];
    }
    return self;
}


@end
