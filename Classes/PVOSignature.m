//
//  PVOSignature.m
//  Survey
//
//  Created by Tony Brame on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOSignature.h"

@implementation PVOSignature

@synthesize pvoSigID, custID;
@synthesize pvoSigTypeID;
@synthesize referenceID;
@synthesize fileName;
@synthesize sigDate;

- (id)init
{
    self = [super init];
    if (self) {
        referenceID = -1;
    }
    
    return self;
}

-(NSString*)fullFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingString:fileName];
}

-(UIImage*)signatureData
{
    UIImage *retval = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if([fileManager fileExistsAtPath:[self fullFilePath] isDirectory:&isDir])
    {
        retval = [[UIImage alloc] initWithContentsOfFile:[self fullFilePath]];
    }
    
    return retval == nil ? nil : retval;
}


@end
