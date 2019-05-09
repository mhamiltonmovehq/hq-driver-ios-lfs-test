//
//  CellValue.m
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "CellValue.h"
#import "SurveyAppDelegate.h"

@implementation CellValue

@synthesize label;
@synthesize cellValue, strikethrough;

-(id)initWithValue:(NSString*)val
{
    if(self = [super init])
    {
        self.cellValue = val;
        self.label = nil;
    }
    return self;
}

-(id)initWithIntValue:(int)val
{
    if(self = [super init])
    {
        self.cellValue = [NSString stringWithFormat:@"%d", val];
        self.label = nil;
    }
    return self;
}

-(id)initWithDoubleValue:(double)val
{
    if(self = [super init])
    {
        self.cellValue = [SurveyAppDelegate formatDouble:val];
        self.label = nil;
    }
    return self;
}

-(id)initWithLabel:(NSString*)lab
{
    if(self = [super init])
    {
        self.cellValue = nil;
        self.label = lab;
    }
    return self;
}

-(id)initWithValue:(NSString*)val withLabel:(NSString*)lab
{
    if(self = [super init])
    {
        self.cellValue = val;
        self.label = lab;
    }
    return self;
}


+(CellValue*)cellWithIntValue:(int)val
{
    return [[CellValue alloc] initWithIntValue:val];
}

+(CellValue*)cellWithDoubleValue:(double)val
{
    return [[CellValue alloc] initWithDoubleValue:val];
}

+(CellValue*)cellWithValue:(NSString*)val
{
    return [[CellValue alloc] initWithValue:val];
}

+(CellValue*)cellWithLabel:(NSString*)lab
{
    return [[CellValue alloc] initWithLabel:lab];
}

+(CellValue*)cellWithValue:(NSString*)val withLabel:(NSString*)lab
{
    return [[CellValue alloc] initWithValue:val withLabel:lab];
}

@end
