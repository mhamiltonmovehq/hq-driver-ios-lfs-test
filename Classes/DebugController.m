//
//  DebugController.m
//  Survey
//
//  Created by Tony Brame on 5/14/14.
//
//

#import "DebugController.h"
#import "SurveyAppDelegate.h"
#import "PortraitNavController.h"
#import "SurveyDBUpdater.h"
#import "CustomerUtilities.h"
#import "BackupController.h"

@interface DebugController ()

@end

@implementation DebugController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.frame = [[UIScreen mainScreen] bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cmdContinue:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del initDBs];
    [del showHideVC:del.splashView withHide:del.debugController];
}

- (IBAction)cmdCleanInstall:(id)sender
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Clean Install"
                                                 message:@"Are you sure you would like to remove the data from your installation, and start with clean databases?  "
                       "You will LOSE all current data in the app.  Any existing backups will be retained."
                                                delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"Yes", nil];//backup current too?
    av.tag = DEBUG_CLEAN_INSTALL;
    [av show];
}

- (IBAction)cmdRestoreFromBackup:(id)sender
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Restore Backup"
                                                 message:@"Are you sure you would like to restore from a backup?  "
                       "You will LOSE all current data in the app.  Any backups will be retained."
                                                delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"Yes", nil];//backup current too?
    av.tag = DEBUG_RESTORE_FROM_BACKUP;
    [av show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(alertView.tag == DEBUG_RESTORE_FROM_BACKUP)
        {
            [del initDBs];
            
            //now recreate the entire backup table (and make sure it exists - the current db could be blown)
            
            if(![del.surveyDB tableExists:@"Backups"])
                [del.surveyDB updateDB:[SurveyDBUpdater createBackupsSQL]];
            
            if(![del.surveyDB tableExists:@"AutoBackupSchedule"])
            {
                [del.surveyDB updateDB:[SurveyDBUpdater createAutoBackupScheduleSQL]];
                [del.surveyDB updateDB:[SurveyDBUpdater createAutoBackupScheduleDefaults]];
            }
            
            NSArray *backups = [CustomerUtilities allBackupFolders];
            if(backups.count == 0)
            {
                [SurveyAppDelegate showAlert:@"No backups found!" withTitle:@"No Backups"];
                return;
            }
            
            //rebuild backups table based off of folder structure...
            [del.surveyDB updateDB:@"DELETE FROM Backups"];
            //get backups and set up existing records...
            for (NSString *folder in backups) {
                [del.surveyDB updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate,BackupFolder) VALUES(%f,'%@')",
                              [[CustomerUtilities dateFromString:folder] timeIntervalSince1970], folder]];
            }
            
            //reset backup date...
            AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
            sched.lastBackup = [NSDate date];
            [del.surveyDB saveBackupSchedule:sched];
            
            
            BackupController *backupController = [[BackupController alloc] initWithStyle:UITableViewStyleGrouped];
            backupController.title = @"Backup";
            
            //recreate it each time...
            PortraitNavController *newNavController = [[PortraitNavController alloc] initWithRootViewController:backupController];
            [self presentViewController:newNavController animated:YES completion:nil];
            
        }
        else if(alertView.tag == DEBUG_CLEAN_INSTALL)
        {
            // ensure we still have our backups after wiping db
            [del initDBs];
            NSArray *backupArray = [del.surveyDB getAllBackups];
            
            //reset backup date...
            AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
            sched.lastBackup = [NSDate date];
            [del.surveyDB saveBackupSchedule:sched];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docsDir = [paths objectAtIndex:0];
            NSString *fullPath = [docsDir stringByAppendingPathComponent:SURVEY_DB_NAME];
            
            //delete the survey database, and let it be recreated...
            NSFileManager *mgr = [NSFileManager defaultManager];
            NSError *test;
            [mgr removeItemAtPath:fullPath error:&test];
            [del initDBsWithBackups:backupArray];
            [self cmdContinue:nil];
        }
    }
}

@end
