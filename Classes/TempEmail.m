//
//  TempEmail.m
//  Survey
//
//  Created by DThomas on 8/12/14.
//
//

#import "TempEmail.h"

@implementation TempEmail

@synthesize toEmail, toName, custID, EmailID;

-(void)dealloc
{
    toEmail = nil;
    toName = nil;
}

@end
