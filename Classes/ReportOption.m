//
//  ReportOption.m
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ReportOption.h"


@implementation ReportOption

@synthesize reportName, reportID, reportLocation;

-(void)dealloc
{
    self.htmlBundleLocation = nil;
    self.htmlTargetFile = nil;
}

@end
