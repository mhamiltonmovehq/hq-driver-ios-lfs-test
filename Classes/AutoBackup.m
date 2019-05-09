//
//  AutoBackup.m
//  Survey
//
//  Created by Tony Brame on 1/29/13.
//
//

#import "AutoBackup.h"
#import "SurveyAppDelegate.h"
#import "CustomerUtilities.h"

//class only used by AutoBackup, do not instantiate from other
@implementation AutoBackupThread

@synthesize caller, callback, goForUpdate;

-(void)main
{
    @autoreleasepool {
        _appDelegate.surveyDB.runningOnSeparateThread = YES;
    @try
    {
            AutoBackupSchedule *sched = [_appDelegate.surveyDB getBackupSchedule];
            NSString *retval = nil;
            
            if(sched.enableBackup)
            {
                if([[NSDate date] timeIntervalSince1970] - [sched.lastBackup timeIntervalSince1970] >= sched.backupFrequency)
                {
                    [caller performSelectorOnMainThread:goForUpdate withObject:nil waitUntilDone:NO];
                    
                    //sleep for half a second - trying to get rid of error code 34.  making sure all db transactions are complete before backup...
                    [NSThread sleepForTimeInterval:.5];
                    retval = [CustomerUtilities backupDatabases:sched.includeImages withSuppress:YES appDelegate:_appDelegate];
                    [NSThread sleepForTimeInterval:.5];
                }
            }
            
            
            [caller performSelectorOnMainThread:callback withObject:retval waitUntilDone:NO];
    }
    @catch (NSException * e) {
            [caller performSelectorOnMainThread:callback withObject:[NSString stringWithFormat:@"Error Performing Backup: %@", [e description]] waitUntilDone:NO];
    }
        _appDelegate.surveyDB.runningOnSeparateThread = NO;
    
    }
}


@end

//class on main UI thread, to be called by consumer.
@implementation AutoBackup

-(void)beginBackup
{
    //check auto backup settings.  if met, back up databases.
    
    BOOL runbackup = YES;
    
    if(runbackup)
    {
        thread = [[AutoBackupThread alloc] init];
        thread.caller = self;
        thread.callback = @selector(complete:);
        thread.goForUpdate = @selector(goForUpdate);
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        thread.appDelegate = del;
        [del.operationQueue addOperation:thread];
    }
    
}

-(void)goForUpdate
{
    progressView = [[SmallProgressView alloc] initWithDefaultFrame:@"Backing Up Databases"];
}

-(void)complete:(NSString*)message
{
    [progressView removeFromSuperview];
    
    if(message != nil)
        [SurveyAppDelegate showAlert:message withTitle:@"Auto Backup"];
    
    [_caller performSelector:_finishedBackup];
}


@end
