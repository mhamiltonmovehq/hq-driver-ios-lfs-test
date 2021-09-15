//
//  NSString+Utilities.h
//  Survey
//
//  Created by Brian Prescott on 10/22/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

+ (NSString *)formatCurrency:(double)number;
+ (NSString *)formatCurrency:(double)number withCommas:(BOOL)commas;
+ (NSString *)formatDate:(NSDate *)passed;
+ (NSString *)formatDouble:(double)number;
+ (NSString *)formatDouble:(double)number withPrecision:(int)decimals;
+ (NSString *)formatTime:(NSDate *)passed;
+ (NSString *)newDocsDirectory;
+ (NSString *)documentsDirectory;
+ (NSString *)removeEmojisFromString:(NSString *)original;
+ (NSString *)removeReservedCharactersFromFilename:(NSString *)fileName;
+ (BOOL)stringMatchesRegex:(NSString *)string withRegex:(NSString *)regex;
+ (NSString *)stringFromBytes:(long long)bytes;
+ (NSString *)pluralizedCount:(NSInteger)count rootWord:(NSString *)rootWord pluralSuffix:(NSString *)pluralSuffix;
+ (NSString *)pluralizedCount:(NSInteger)count rootWord:(NSString *)rootWord;
+ (NSString *)formatDateAndTime:(NSDate *)passed;
+ (NSString* )formatDateAndTime:(NSDate *)passed asGMT:(BOOL)asGMT;
+ (NSString *)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString *)format;
+ (NSString *)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString *)format asGMT:(BOOL)asGMT;
- (NSDate *)dateFromStringWithFormatAsGMT:(BOOL)asGMT;
- (NSDate *)dateFromStringWithFormat:(NSString *)format asGMT:(BOOL)asGMT;

- (CGSize)textSize:(UIFont *)font maxWidth:(CGFloat)maxWidth;
- (NSString *)dbSafe;
+ (NSString *)dbString:(NSString *)originalString;
+ (NSString *)getSSID;

-(NSComparisonResult)compareToVersion:(NSString *)version;

-(BOOL)isOlderThanVersion:(NSString *)version;
-(BOOL)isNewerThanVersion:(NSString *)version;
-(BOOL)isEqualToVersion:(NSString *)version;
-(BOOL)isEqualOrOlderThanVersion:(NSString *)version;
-(BOOL)isEqualOrNewerThanVersion:(NSString *)version;

- (NSString *)getMainVersionWithIntegerCount:(NSInteger)integerCount;
- (BOOL)needsToUpdateToVersion:(NSString *)newVersion MainVersionIntegerCount:(NSInteger)integerCount;

#define DBSAFE(x) [NSString dbString:x]

- (BOOL)isValidUUID;

+ (NSString *)prepareStringForInsert:(NSString*)src;
+ (NSString *)prepareStringForInsert:(NSString*)src supportsNull:(BOOL)nullable;

@end
