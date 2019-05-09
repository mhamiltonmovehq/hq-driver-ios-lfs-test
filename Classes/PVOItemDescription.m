//
//  PVOItemDescription.m
//  Survey
//
//  Created by Tony Brame on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOItemDescription.h"

@implementation PVOItemDescription

@synthesize pvoItemDescriptionID;
@synthesize pvoItemID;
@synthesize descriptionCode;
@synthesize description;

-(NSString*)listItemDisplay
{
    return [NSString stringWithFormat:@"%@ - %@", descriptionCode, description];
}


@end
