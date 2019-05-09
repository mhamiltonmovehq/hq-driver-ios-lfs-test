//
//  PVOSTGBOL.m
//  Survey
//
//  Created by Brian Prescott on 10/17/17.
//
//

#import "PVOSTGBOL.h"

#import "SurveyAppDelegate.h"

@implementation PVOSTGBOL

+ (void)checkForDirectory
{
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *bolDir = [docsDir stringByAppendingPathComponent:BOLDIRECTORY];
    NSError *err;
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL isDir;
    if (![mgr fileExistsAtPath:bolDir isDirectory:&isDir])
    {
        if (![mgr createDirectoryAtPath:bolDir withIntermediateDirectories:YES attributes:nil error:&err])
        {
            NSLog(@"Error creating BOL directory: %@", [err localizedDescription]);
        }
    }
}

+ (NSString *)fullPathForCustomer:(NSInteger)customerID
{
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *bolDir = [docsDir stringByAppendingPathComponent:BOLDIRECTORY];
    NSString *filename = [NSString stringWithFormat:@"%@.xml", @(customerID)];
    NSString *stgBolPath = [bolDir stringByAppendingPathComponent:filename];
    return stgBolPath;
}

@end
