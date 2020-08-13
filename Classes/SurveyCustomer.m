//
//  SurveyCustomer.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyCustomer.h"
#import "SurveyAppDelegate.h"


@implementation SurveyCustomer
@synthesize custID, lastName, firstName, account, email, estimatedWeight, pricingMode, cancelled, inventoryType, lastSaveToServerDate, originCompletionDate, destinationCompletionDate;

-(NSString *)getFormattedLastSaveToServerDate:(BOOL)withTime
{
    NSMutableString *retval = [NSMutableString string];
    if ([lastSaveToServerDate length] > 0) {
        [retval appendString:@"Last Saved: "];
        if (withTime) {
            [retval appendString:lastSaveToServerDate];
        } else {
            NSArray *arr = [lastSaveToServerDate componentsSeparatedByString:@" "];
            [retval appendString:[arr firstObject]];
        }
    }
    
    return retval;
}

- (void)flushToXML:(XMLWriter*)xml
{
	[xml writeElementString:@"first_name" withData:firstName];
	[xml writeElementString:@"last_name" withData:lastName];
    [xml writeElementString:@"company_name" withData:account];
	[xml writeElementString:@"email" withData:email];
	[xml writeElementString:@"weight_override" withIntData:estimatedWeight];
    [xml writeElementString:@"origin_completion_date" withData:originCompletionDate];
    [xml writeElementString:@"destination_completion_date" withData:destinationCompletionDate];
}

- (BOOL)isCanadianGovernmentCustomer
{
    return (pricingMode == CNGOV);
}

- (BOOL)isCanadianNonGovernmentCustomer
{
    return (pricingMode == CNCIV);
}

- (BOOL)isCanadianCustomer
{
    return ([self isCanadianGovernmentCustomer] || [self isCanadianNonGovernmentCustomer]);
}

+ (BOOL)isCanadianCustomer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    BOOL retval = [cust isCanadianCustomer];
    return retval;
}

@end
