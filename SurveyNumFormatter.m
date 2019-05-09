//
//  SurveyNumFormatter.m
//  Survey
//
//  Created by Tony Brame on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyNumFormatter.h"


@implementation SurveyNumFormatter

-(id)init
{
	if(self = [super init])
	{
		
	}
	return self;
}

-(NSString*)stringFromDouble:(double)number
{
	return [self stringFromNumber:[NSNumber numberWithDouble:number]];
}

-(NSString*)stringFromInt:(int)number
{
	return [self stringFromNumber:[NSNumber numberWithInt:number]];
}

@end
