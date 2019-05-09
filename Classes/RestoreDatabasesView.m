//
//  PVOUploadReportView.m
//  Survey
//
//  Created by Tony Brame on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <sqlite3.h>

#import "RestoreDatabasesView.h"
#import "PVOSync.h"
#import "SurveyAppDelegate.h"
#import "ZipArchive.h"
#import "CustomerUtilities.h"

@implementation RestoreDatabasesView

@synthesize rootController;
@synthesize viewLoading;
@synthesize labelStatus, file;
@synthesize updater;
@synthesize isRestoreFromBackupFolder;
@synthesize caller, callback;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        
        CGRect viewFrame = appwindow.frame;
        
        viewLoading = [[UIView alloc] initWithFrame:appwindow.frame];
        viewLoading.backgroundColor = [UIColor blackColor];
        viewLoading.alpha = .75;
            
        CGSize textSize = [@"Restoring Databases" sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}];
        labelStatus = [[UILabel alloc] initWithFrame:
                       CGRectMake(30, (viewFrame.size.height / 2) - (textSize.height / 2), 
                                  300, textSize.height)];
        labelStatus.font = [UIFont systemFontOfSize:22];
        labelStatus.text = @"Restoring Databases";
        labelStatus.textColor = [UIColor whiteColor];
        labelStatus.backgroundColor = [UIColor clearColor];
        [viewLoading addSubview:labelStatus];
        
    }
    
    return self;
}

-(void)restoreDatabases:(NSURL*)fileLocation
{
    self.file = fileLocation;
    
    NSString *appName = @"Mobile Mover";
#ifdef ATLASNET
    appName = @"AtlasNet";
#endif
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Restore Databases" 
                                                 message:[NSString stringWithFormat:@"Would you like to restore these databases to %@? "
                                                          " All existing data will be backed up, and replaced. "
                                                          " In the case that an error occurs, you will be able to recover your existing data.", appName]
                                                delegate:self 
                                       cancelButtonTitle:@"No" 
                                       otherButtonTitles:@"Yes", nil];
    
    [av show];
    
    
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *sourceFilePath = [file path];
    
    NSString *appName = @"Mobile Mover";
#ifdef ATLASNET
    appName = @"AtlasNet";
#endif
    
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        
        //first, unzip file, and check to see it is a mobile mover backup...
        //move to a different location
        
        BOOL dir = YES;
        NSString *temp = nil;
        ZipArchive *zipper = nil;
        
        if (isRestoreFromBackupFolder)
        {
            temp = [sourceFilePath stringByAppendingPathComponent:SURVEY_DB_NAME];
        }
        else
        {
            temp = [docsDir stringByAppendingPathComponent:RESTORE_TEMP_FOLDER];
            
            if([mgr fileExistsAtPath:temp isDirectory:&dir])
                [mgr removeItemAtPath:temp error:nil];
            
            if(![mgr createDirectoryAtPath:temp withIntermediateDirectories:NO attributes:nil error:nil])
                goto genericError;
            
            temp = [temp stringByAppendingPathComponent:RESTORE_TEMP_FILE];
            if(![mgr copyItemAtPath:sourceFilePath toPath:temp error:nil])
                goto genericError;
            
            //now unzip...
            
            zipper = [[ZipArchive alloc] init];
            
            if(![zipper UnzipOpenFile:temp])
                goto genericError;
            
            temp = [docsDir stringByAppendingPathComponent:RESTORE_TEMP_FOLDER];
            if(![zipper UnzipFileTo:temp overWrite:YES])
                goto genericError;
            
            [zipper UnzipCloseFile];
            
            //look for and open survey.sqlite3 from the temp dir andverify it is a pvo db...
            temp = [temp stringByAppendingPathComponent:SURVEY_DB_NAME];
        }
        
        if(![mgr fileExistsAtPath:temp])
            goto invalidError;
        
        sqlite3    *db;
        if(sqlite3_open([temp UTF8String], &db) != SQLITE_OK)
        {
            sqlite3_close(db);
            goto invalidError;
        }
        
        //check for PVODriverData table
        sqlite3_stmt *stmnt;
        NSInteger retval = sqlite3_prepare_v2(db, [@"SELECT * FROM PVODriverData LIMIT 1" UTF8String], -1, &stmnt, nil);
        sqlite3_finalize(stmnt);
        sqlite3_close(db);
        if(retval != SQLITE_OK)
            goto invalidError;
        
        //confirmed it is valid, make backup of existing data...
        BOOL backupSuccess = NO;
        NSString *backupErr = [CustomerUtilities backupDatabases:YES withSuppress:YES success:&backupSuccess appDelegate:del];
        if (!backupSuccess)
        {
            [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"There has been an error making backup prior to restore: %@. "
                                          "New file restore has been aborted.", backupErr]
                               withTitle:@"Error"];
            [self exit];
            return;
        }
        
        //now, delete data and restore.
        
        //close dbs
        [del.surveyDB closeDB];
        
        if (isRestoreFromBackupFolder)
        {
            NSArray *backupContents = [mgr contentsOfDirectoryAtPath:sourceFilePath error:nil];
            if (backupContents != nil && [backupContents count] > 0)
            {
                for (int i=0;i<[backupContents count];i++)
                {
                    NSString *backupFile = [backupContents objectAtIndex:i];
                    temp = [docsDir stringByAppendingPathComponent:backupFile];
                    if ([mgr fileExistsAtPath:temp isDirectory:nil])
                        [mgr removeItemAtPath:temp error:nil];
                    if (![mgr copyItemAtPath:[sourceFilePath stringByAppendingPathComponent:backupFile] toPath:temp error:nil])
                        goto restoreError;
                }
            }
        }
        else
        {
            if(![mgr removeItemAtPath:[del.surveyDB fullDBPath] error:nil])
                goto genericError;
            
            zipper = [[ZipArchive alloc] init];
            if(![zipper UnzipOpenFile:sourceFilePath])
                goto restoreError;
            
            if(![zipper UnzipFileTo:docsDir overWrite:YES])
                goto restoreError;
            
            [zipper UnzipCloseFile];
        }
        
        [del.surveyDB openDB:[del.pricingDB vanline]];
        
        
        //update it in case it was an older version...
        updater = [[SurveyDBUpdater alloc] init];
        updater.db = del.surveyDB;
        updater.delegate = self;
        
        [del.operationQueue addOperation:updater];
        
        return;
    }
    else
    {//TFS 24324 - Database restore was showing all error messages and restoring when selecting 'NO'
        [self exit];
        return;
    }
    
restoreError:
    
    //restore databases...
    
    [CustomerUtilities restoreBackup:[[CustomerUtilities allBackupFolders] objectAtIndex:0]];
    
    [SurveyAppDelegate showAlert:@"There has been an error Copying the File. New file restore has been aborted, and existing databases restored." 
                       withTitle:@"Error"];
    [self exit];
    
invalidError:
    
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"This archive is not a valid %1$@ backup file. "
                                  " Please ensure you are restoring from a %1$@ generated backup email.", appName]
                       withTitle:@"Error"];
    
    [self exit];
    
genericError:
    
    [SurveyAppDelegate showAlert:@"There has been an error Copying the File. New file restore has been aborted, and existing databases restored." 
                       withTitle:@"Error"];
    
    [self exit];
}

-(void)exit
{
    if (!isRestoreFromBackupFolder)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        //referesh list...
        [del.navController viewWillAppear:YES];
        
        //delete any extracted files in temp dir
        NSFileManager *mgr = [NSFileManager defaultManager];
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        [mgr removeItemAtPath:[docsDir stringByAppendingPathComponent:RESTORE_TEMP_FOLDER] error:nil];
    }
    
    [viewLoading removeFromSuperview];
    
    SplashViewController *splashView = [[SplashViewController alloc] initWithNibName:@"SplashView" bundle:nil];
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.window setRootViewController:splashView];
    
    [del.window makeKeyAndVisible];
    
    [del.navController presentViewController:splashView animated:YES completion:nil];
}

#pragma mark - SurveyDBUpdaterDelegate methods

-(void)SurveyDBUpdaterError:(NSString*)error
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [SurveyAppDelegate showAlert:error withTitle:@"DB Update Error"];
    
    //restore databases...
    
    NSString *restoreBackup = [[CustomerUtilities allBackupFolders] objectAtIndex:0];
    [CustomerUtilities restoreBackup:restoreBackup];
    
    //remove last backup, we used this as a restore point in case of catastrophic failure
    [CustomerUtilities deleteBackup:restoreBackup];
    
    //rebuild backups table based off of folder structure...
    //haveto do this since the restore won't list all backups,
    //and I don't want just pulling folders for the backup list (to retain database integrity)....
    
    [del.surveyDB updateDB:@"DELETE FROM Backups"];
    
    NSArray *backups = [CustomerUtilities allBackupFolders];
    //11-19-2009 12:51 PM
    for (NSString *folder in backups) {
        [del.surveyDB updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate,BackupFolder) VALUES(%f,'%@')", [[CustomerUtilities dateFromString:folder] timeIntervalSince1970], folder]];
    }
    
    
    //reset backup date...
    AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
    sched.lastBackup = [NSDate date];
    [del.surveyDB saveBackupSchedule:sched];
    
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"There has been an error updating the backup. New file restore has been "
                                  "aborted, and existing databases restored. Error: %@", error]
                       withTitle:@"Error"];
    
    [self exit];
}

-(void)SurveyDBUpdaterCompleted:(SurveyDBUpdater*)updater
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del.surveyDB upgradeDBForVanline:[del.pricingDB vanline]];
    
    //rebuild backups table based off of folder structure...
    //haveto do this since the restore won't list all backups,
    //and I don't want just pulling folders for the backup list (to retain database integrity)....
    
    [del.surveyDB updateDB:@"DELETE FROM Backups"];
    
    // delete the temp backup that was just made
    NSArray *backups = [CustomerUtilities allBackupFolders];
    if([backups count] > 0) {
        [CustomerUtilities deleteBackup:[backups lastObject]];
    }
    
    // reload backups
    backups = [CustomerUtilities allBackupFolders];
    for (NSString *folder in backups) {
        [del.surveyDB updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate,BackupFolder) VALUES(%f,'%@')", [[CustomerUtilities dateFromString:folder] timeIntervalSince1970], folder]];
    }
    
    //reset backup date...
    AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
    sched.lastBackup = [NSDate date];
    [del.surveyDB saveBackupSchedule:sched];
    
    [del.surveyDB upgradeDBForVanline:[del.pricingDB vanline]];
    
    [SurveyAppDelegate showAlert:@"Databases have been successfully restored."
                       withTitle:@"Success"];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    [mgr removeItemAtPath:[docsDir stringByAppendingPathComponent:@"/Inbox"] error:nil];
    
    [self exit];
}

-(void)SurveyDBUpdaterUpdateProgress:(NSNumber*)prog
{
    
}

-(void)SurveyDBUpdaterStartProgress:(NSString*)progressLabel
{
    
}

-(void)SurveyDBUpdaterEndProgress:(SurveyDBUpdater*)updater
{
    
}

@end
