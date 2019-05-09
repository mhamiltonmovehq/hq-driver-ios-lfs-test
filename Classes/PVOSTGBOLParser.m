//
//  PVOSTGBOLParser.m
//  Survey
//
//  Created by Brian Prescott on 10/13/17.
//
//

#import "PVOSTGBOLParser.h"

#import "PVOSTGBOL.h"
#import "SurveyAppDelegate.h"

@implementation PVOSTGBOLParser

- (id)init
{
    self = [super init];
    if (self)
    {
        self.stgBolXml = @"";
    }

    return self;
}

- (void)parseXml:(NSString *)xml
{
    self.stgBolXml = @"";
    
    NSString *startTag = @"<STGBOLData>";
    NSString *endTag = @"</STGBOLData>";
    
    NSRange startRange = [xml rangeOfString:startTag];
    if (startRange.location == NSNotFound)
    {
        return;
    }
    
    NSRange endRange = [xml rangeOfString:endTag];
    if (endRange.location == NSNotFound)
    {
        return;
    }
    
    NSRange newRange = NSMakeRange(startRange.location, (endRange.location + endRange.length) - startRange.location);
    NSString *str = [xml substringWithRange:newRange];
    self.stgBolXml = str;
}

- (void)writeXmlToFile:(NSInteger)customerID
{
    [PVOSTGBOL checkForDirectory];
    NSString *fullPath = [PVOSTGBOL fullPathForCustomer:customerID];
    [_stgBolXml writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
