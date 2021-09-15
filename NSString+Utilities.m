//
//  NSString+Utilities.m
//  Survey
//
//  Created by Brian Prescott on 10/22/16.
//
//

#import "NSString+Utilities.h"

#import <SystemConfiguration/CaptiveNetwork.h>

#import "SurveyNumFormatter.h"

#define MB_STRING @"MB"
#define KB_STRING @"KB"
#define BYTE_STRING @"Bytes"

@implementation NSString (Utilities)

+(NSString*)formatCurrency:(double)number
{
    return [NSString formatCurrency:number withCommas:FALSE];
}

+(NSString*)formatCurrency:(double)number withCommas:(BOOL)commas
{
    if(!commas)
        return [NSString stringWithFormat:@"$ %@", [NSString formatDouble:number]];
    else
    {
        NSNumber *aNumber = [NSNumber numberWithDouble:number];
        
        NSNumberFormatter *frmtr = [[NSNumberFormatter alloc] init];
        [frmtr setGroupingSize:3];
        [frmtr setGroupingSeparator:@","];
        [frmtr setUsesGroupingSeparator:YES];
        [frmtr setMinimumFractionDigits:2];
        [frmtr setMaximumFractionDigits:2];
        NSString *commaString = [frmtr stringFromNumber:aNumber];
        
        return [NSString stringWithFormat:@"$ %@", commaString];
    }
}

+(NSString*)formatDate:(NSDate*)passed
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *date = [dateFormatter stringFromDate:passed];
    return date;
}

+(NSString*)formatDouble:(double)number
{
    return [NSString formatDouble:number withPrecision:2];
}

+(NSString*)formatDouble:(double)number withPrecision:(int)decimals
{
    NSMutableString *string = [[NSMutableString alloc] initWithFormat:@"0%@", decimals > 0 ? @"." : @""];
    for(int i = 0; i < decimals; i++)
        [string appendString:@"0"];
    
    SurveyNumFormatter *formatter = [[SurveyNumFormatter alloc] init];
    [formatter setPositiveFormat:string];
    NSString *retval = [formatter stringFromDouble:number];
    
    return retval;
}

+(NSString*)formatTime:(NSDate*)passed
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    NSString *date = [dateFormatter stringFromDate:passed];

    return date;
}

+(NSString*)newDocsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    return documentsDirectory;
}

+ (NSString *)removeEmojisFromString:(NSString *)original
{
    if(original == nil)
        return @"";
    
    NSMutableString *retval = [[NSMutableString alloc] initWithString:original];
    
    //chars > 127 should be written as a number...
    unichar current;
    for(int i = 0; i < [retval length]; i++)
    {
        current = [retval characterAtIndex:i];
        if (current > 255)
        {//removes emojis. Have to make it a full space instead of an empty space because some emojis are surrogate pairs and it gets crazy cmoplicated.
            [retval replaceCharactersInRange:NSMakeRange(i, 1) withString:@" "];
        }
    }
    
    NSString *trimmedString = [retval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return trimmedString;
}

+ (NSString *)removeReservedCharactersFromFilename:(NSString *)fileName
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[|?*<\":>+\\[\\]/']+" options:0 error:nil];
    fileName = [regex stringByReplacingMatchesInString:fileName options:0 range:NSMakeRange(0, fileName.length) withTemplate:@"_"];
    
    return fileName;
}

+(NSString*)stringFromBytes:(long long)bytes
{
    NSString *retval;
    
    if(bytes > ONE_MB)
    {
        retval = [[NSString alloc] initWithFormat:@"%@ %@",
                  [NSString formatDouble:(bytes/(double)ONE_MB) withPrecision:2],
                  MB_STRING];
    }
    else if(bytes > ONE_KB)
    {
        retval = [[NSString alloc] initWithFormat:@"%lld %@", (bytes/ONE_KB), KB_STRING];
    }
    else
    {//just bytes
        retval = [[NSString alloc] initWithFormat:@"%lld %@", bytes, BYTE_STRING];
    }
    
    
    return retval;
}

+ (BOOL)stringMatchesRegex:(NSString *)string withRegex:(NSString *)regex
{
    NSError *error = NULL;
    
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [expression firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (match)
    {
        return [[string substringWithRange:[match rangeAtIndex:0]] length] == [string length];
    }
    
    
    return false;
}

+ (NSString *)pluralizedCount:(NSInteger)count rootWord:(NSString *)rootWord pluralSuffix:(NSString *)pluralSuffix
{
    return [NSString stringWithFormat:@"%@ %@%@", @(count), rootWord, (count == 1 ? @"" : pluralSuffix)];
}

+ (NSString *)pluralizedCount:(NSInteger)count rootWord:(NSString *)rootWord
{
    return [NSString pluralizedCount:count rootWord:rootWord pluralSuffix:@"s"];
}

+ (NSString *)formatDateAndTime:(NSDate *)passed
{
    return [NSString formatDateAndTime:passed asGMT:YES]; //default to YES
}

+ (NSString* )formatDateAndTime:(NSDate *)passed asGMT:(BOOL)asGMT
{
    return [NSString formatDateAndTime:passed withDateFormat:@"MM/dd/yyyy' 'hh:mm a" asGMT:asGMT];
}

+ (NSString *)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString *)format
{
    return [NSString formatDateAndTime:passed withDateFormat:format asGMT:YES]; //default to YES
}

+ (NSString *)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString *)format asGMT:(BOOL)asGMT
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (asGMT)
    {
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    [dateFormatter setDateFormat:format];
    NSString *date = [dateFormatter stringFromDate:passed];

    return date;
}

- (NSDate *)dateFromStringWithFormatAsGMT:(BOOL)asGMT
{
    return [self dateFromStringWithFormat:@"MM/dd/yyyy' 'hh:mm a" asGMT:asGMT];
}

- (NSDate *)dateFromStringWithFormat:(NSString *)format asGMT:(BOOL)asGMT
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (asGMT)
    {
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    [dateFormatter setDateFormat:format];
    NSDate *date = [dateFormatter dateFromString:self];
    
    return date;
   
}

- (CGSize)textSize:(UIFont *)font maxWidth:(CGFloat)maxWidth
{
    NSDictionary *attributes = @ { NSFontAttributeName: font };
    CGRect rect = [self boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size;
}

- (NSString *)dbSafe
{
    NSString *s = [self stringByReplacingOccurrencesOfString:@"'" withString:@"''"];    // change ' to ''
    
    return s;
}

+ (NSString *)dbString:(NSString *)originalString
{
    if (originalString == nil)
    {
        return @"";
    }
    
    return [originalString dbSafe];
}

+ (NSString *)getSSID
{
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    //NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    NSDictionary *info = nil;
    NSString *theSSID = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        //NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        if ([info valueForKey:@"SSID"])
        {
            theSSID = [NSString stringWithString:[info valueForKey:@"SSID"]];
        }
    }
    
    return theSSID;
}

static NSString *versionSeparator = @".";

-(NSComparisonResult)compareToVersion:(NSString *)version{
    NSComparisonResult result;
    
    result = NSOrderedSame;
    
    if(![self isEqualToString:version]){
        NSArray *thisVersion = [self componentsSeparatedByString:versionSeparator];
        NSArray *compareVersion = [version componentsSeparatedByString:versionSeparator];
        
        for(NSInteger index = 0; index < MAX([thisVersion count], [compareVersion count]); index++){
            NSInteger thisSegment = (index < [thisVersion count]) ? [[thisVersion objectAtIndex:index] integerValue] : 0;
            NSInteger compareSegment = (index < [compareVersion count]) ? [[compareVersion objectAtIndex:index] integerValue] : 0;
            
            if(thisSegment < compareSegment){
                result = NSOrderedAscending;
                break;
            }
            
            if(thisSegment > compareSegment){
                result = NSOrderedDescending;
                break;
            }
        }
    }
    
    return result;
}


-(BOOL)isOlderThanVersion:(NSString *)version{
    return ([self compareToVersion:version] == NSOrderedAscending);
}

-(BOOL)isNewerThanVersion:(NSString *)version{
    return ([self compareToVersion:version] == NSOrderedDescending);
}

-(BOOL)isEqualToVersion:(NSString *)version{
    return ([self compareToVersion:version] == NSOrderedSame);
}

-(BOOL)isEqualOrOlderThanVersion:(NSString *)version{
    return ([self compareToVersion:version] != NSOrderedDescending);
}

-(BOOL)isEqualOrNewerThanVersion:(NSString *)version{
    return ([self compareToVersion:version] != NSOrderedAscending);
}

- (NSString *)getMainVersionWithIntegerCount:(NSInteger)integerCount {
    NSArray *components = [self componentsSeparatedByString:versionSeparator];
    
    if((integerCount > 0) && (integerCount <= components.count)){
        return [[components subarrayWithRange:NSMakeRange(0, integerCount)] componentsJoinedByString:versionSeparator];
    }
    
    return NULL;
}

- (BOOL)needsToUpdateToVersion:(NSString *)newVersion MainVersionIntegerCount:(NSInteger)integerCount {
    NSString *myMainVersion = [self getMainVersionWithIntegerCount:integerCount];
    NSString *newMainVersion = [newVersion getMainVersionWithIntegerCount:integerCount];
    
    if ([myMainVersion isEqualToVersion:newMainVersion]) {
        return [newVersion isNewerThanVersion:self];
    }
    
    return NO;
}

- (BOOL)isValidUUID
{
    return ([[NSUUID alloc] initWithUUIDString:self] != nil);
}

+ (NSString *)prepareStringForInsert:(NSString*)src
{
    return [NSString prepareStringForInsert:src supportsNull:NO];
}

+ (NSString *)prepareStringForInsert:(NSString*)src supportsNull:(BOOL)nullable
{
    if(nullable && (src == nil || [src length] == 0))
        return @"NULL";
    else
    {
        if(src == nil)
            return @"''";
        else
            return [NSString stringWithFormat:@"'%@'", [src stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
}
@end
