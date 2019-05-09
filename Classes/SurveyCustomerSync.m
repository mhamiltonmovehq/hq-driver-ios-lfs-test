//
//  SurveyCustomerSync.m
//  Survey
//
//  Created by Tony Brame on 8/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyCustomerSync.h"


@implementation SurveyCustomerSync

@synthesize createdOnDevice, sync, syncToQM, generalSyncID, atlasShipID, atlasSurveyID, custID, syncToPVO;

-(void)flushToXML:(XMLWriter*)xml sendToQM:(BOOL)toQM
{
    if (toQM)
        [xml writeElementString:@"sync_field" withData:generalSyncID];
    else
    {
		NSString *toWrite = [NSString stringWithFormat:@"%@,%@", atlasShipID, atlasSurveyID];
		[xml writeElementString:@"sync_field" withData:toWrite];
    }
}

@end
