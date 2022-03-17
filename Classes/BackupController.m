//
//  BackupController.m
//  Survey
//
//  Created by Tony Brame on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BackupController.h"
#import "CustomerUtilities.h"
#import "SurveyAppDelegate.h"
#import "ZipArchive.h"
#import "RestoreDatabasesView.h"
#import "AppFunctionality.h"
#import "Prefs.h"
#import "AutoBackup.h"


@implementation BackupThread

@synthesize caller, callback, goForUpdate, withImages;

-(void)main
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.surveyDB.runningOnSeparateThread = YES;
    NSString *retval = nil;
    @try
    {
        [caller performSelectorOnMainThread:goForUpdate withObject:nil waitUntilDone:NO];
        retval = [CustomerUtilities backupDatabases:withImages withSuppress:NO appDelegate:del];
        [caller performSelectorOnMainThread:callback withObject:retval waitUntilDone:NO];
    }
    @catch (NSException * e) {
        [caller performSelectorOnMainThread:callback withObject:[NSString stringWithFormat:@"Error Performing Backup: %@", [e description]] waitUntilDone:NO];
    }
    del.surveyDB.runningOnSeparateThread = NO;
    
}


@end

@implementation BackupController

@synthesize backupFolders, editingPath, settingsController;
@synthesize restoreDBView;


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];
	
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Options"
															style:UIBarButtonItemStylePlain
														   target:self
														   action:@selector(options:)];
	self.navigationItem.rightBarButtonItem = btn;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						  target:self
																						  action:@selector(done:)];
    
    formatter = [[NSDateFormatter alloc] init];
//	[formatter setDateFormat:@"MM-dd-yyyy h:mm a"];
    [formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss a"];
}

- (void)viewWillAppear:(BOOL)animated {
	
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSArray *temp = [del.surveyDB getAllBackups];
	self.backupFolders = temp;
	
	[self.tableView reloadData];
	
    [super viewWillAppear:animated];
}

-(IBAction)done:(id)sender
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)options:(id)sender
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Please Select Action"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Backup Now", @"Auto Backup Settings", nil];
    as.tag = BACKUP_ACTION_OPTIONS;
    [as showInView:self.view];
    
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;//blank section for footer text to be at top of view...
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 1)
        return [backupFolders count];
    else
        return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    BackupRecord *rec = [backupFolders objectAtIndex:[indexPath row]];
	cell.textLabel.text = [formatter stringFromDate:rec.backupDate];
	
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
/*
 */


//header was formatted too weird, so just added a blank section to get the footer at the top :)
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
    if(section == 0)
        return @"Tap Options to back up current Inventory databases.\r\nTap a Time to Restore that Backup.\r\nSwipe to delete a backup.";
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        BackupRecord *rec = [backupFolders objectAtIndex:[indexPath row]];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.surveyDB deleteBackup:rec];
		self.backupFolders = [del.surveyDB getAllBackups];
		[self.tableView reloadData];
		
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	self.editingPath = indexPath;
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"What would you like to do with this backup?"
													   delegate:self
											  cancelButtonTitle:@"Cancel"
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Restore", @"Email to Support", nil];
	
	[sheet showInView:self.view];
	
    
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
        if(actionSheet.tag == BACKUP_ACTION_OPTIONS)
        {
            if(buttonIndex == 0)
            {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Backup" message:@"Would you like to include images with your backup? If so, images will be compressed when emailed to reduce size." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                
                [av show];
                
            }
            else
            {
                if(settingsController == nil)
                    settingsController = [[AutoBackupSettingsController alloc] initWithNibName:@"AutoBackupSettingsView" bundle:nil];
                [self.navigationController pushViewController:settingsController animated:YES];
            }
        }
        else
        {
            if(buttonIndex == 0)
            {
                BackupRecord *rec = [backupFolders objectAtIndex:[editingPath row]];
//                [CustomerUtilities restoreBackup:rec.backupFolder];
//                
//                //reload list...
//                self.backupFolders = [del.surveyDB getAllBackups];
//                [self.tableView reloadData];
                
                NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
                NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
                
                NSString *fullDir = [backupDir stringByAppendingPathComponent:rec.backupFolder];
                
                if (restoreDBView == nil)
                    restoreDBView = [[RestoreDatabasesView alloc] init];
                restoreDBView.isRestoreFromBackupFolder = YES;
                restoreDBView.caller = self;
                restoreDBView.callback = @selector(done:);
                [restoreDBView restoreDatabases:[NSURL fileURLWithPath:fullDir]];                
            }
            else
            {
                //email
                
                if ([MFMailComposeViewController canSendMail])
                {
                    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                    
                    mailer.mailComposeDelegate = self;
                    
                    [mailer setSubject:@"Inventory Database"];
                    
                    //                NSArray *toRecipients = [NSArray arrayWithObjects:@"a@a.com", @"b@b.com", nil];
                    //                [mailer setToRecipients:toRecipients];
                    
                    //get the current docs directory
                    
                    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
                    NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
                    
                    BackupRecord *rec = [backupFolders objectAtIndex:[editingPath row]];
                    NSString *fullDir = [backupDir stringByAppendingPathComponent:rec.backupFolder]; // [backupFolder stringByReplacingOccurrencesOfString:@":" withString:@"/"]];
                    
                    NSString *zipPath = [fullDir stringByAppendingPathComponent:@"inventory.zip"];
                    
                    //get survey db, and folders...
                    NSString *fullPath = [fullDir stringByAppendingPathComponent:SURVEY_DB_NAME];
                    
                    
                    NSFileManager *mgr = [NSFileManager defaultManager];
                    [mgr removeItemAtPath:zipPath error:nil];
                    
                    
                    ZipArchive *zipper = [[ZipArchive alloc] init];
                    
                    if(![zipper CreateZipFile2:zipPath])
                    {
                        [SurveyAppDelegate showAlert:@"Unable to create zip file." withTitle:@"Error"];
                        return;
                    }
                    else
                    {
                        if(![zipper addFileToZip:fullPath newname:@"survey.sqlite3"])
                        {
                            [zipper UnzipCloseFile];
                            [SurveyAppDelegate showAlert:@"Unable to add to zip file." withTitle:@"Error"];
                            return;
                        }
                        
                        if([mgr fileExistsAtPath:[fullDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY]])
                        {
                            if(![zipper addFolderToZip:[fullDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY] pathPrefix:IMG_ROOT_DIRECTORY compressImages:YES])
                            {
                                [zipper UnzipCloseFile];
                                [SurveyAppDelegate showAlert:@"Unable to add to zip file." withTitle:@"Error"];
                                return;
                            }
                        }
                        
                        if([mgr fileExistsAtPath:[fullDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY]])
                        {
                            if(![zipper addFolderToZip:[fullDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY] pathPrefix:IMG_PVO_DIRECTORY compressImages:NO])
                            {
                                [zipper UnzipCloseFile];
                                [SurveyAppDelegate showAlert:@"Unable to add to zip file." withTitle:@"Error"];
                                return;
                            }
                        }
                        
                        [zipper UnzipCloseFile];
                    }
                    zipper = nil;
          
                    NSData *fileData = [NSData dataWithContentsOfFile:zipPath];
                    [mailer addAttachmentData:fileData mimeType:@"application/zip" fileName:@"inventory.zip"];
                    
                    NSMutableString *emailBody = [[NSMutableString alloc] init];
                    [emailBody appendString:@"Please send this email to the technical support representative you were working with."];
                    
                    if ([AppFunctionality enableAddSettingsToBackupEmail])
                    {
                        [emailBody appendString:[NSString stringWithFormat:@"\r\n\r\nActivation Settings"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nIGC Username: %@", [[Prefs username] length] > 0 ? [Prefs username] : @"<NONE>"]];
                         
                        if ([AppFunctionality enableMoveHQSettings])
                        {
                            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                            DriverData *data = [del.surveyDB getDriverData];
                            [emailBody appendString:[NSString stringWithFormat:@"\r\nCRM Username: %@", [data.crmUsername length] > 0 ? data.crmUsername : @"<NONE>"]];
                            
                        }
                        
                        [emailBody appendString:[NSString stringWithFormat:@"\r\n\r\nCustom Mail Settings"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nBCC: %@", [Prefs bccSender] ? @"ON" : @"OFF"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nCustom Mail Server: %@", [Prefs useCustomServer] ? @"ON" : @"OFF"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nServer Address: %@", [[Prefs mailServer] length] > 0 ? [Prefs mailServer] : @"<NONE>"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nUsername: %@", [[Prefs mailUsername] length] > 0 ? [Prefs mailUsername] : @"<NONE>"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nUse SSL: %@", [Prefs useSSL] ? @"ON" : @"OFF"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nPort: %@", ([Prefs mailPort] > 0 ? [NSString stringWithFormat:@"%d", [Prefs mailPort]] : @"<NONE>")]];
                        
                        
                        [emailBody appendString:[NSString stringWithFormat:@"\r\n\r\nConfig Code"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nCustom Reports: %@", [[Prefs reportsPassword] length] > 0 ? [Prefs reportsPassword] : @"<NONE>"]];
                        [emailBody appendString:[NSString stringWithFormat:@"\r\nBeta: %@", [[Prefs betaPassword] length] > 0 ? [Prefs betaPassword] : @"<NONE>"]];
                    }
                    
                    [mailer setMessageBody:emailBody isHTML:NO];
                    
                    [self presentViewController:mailer animated:YES completion:nil];
                    
                    
                }
                else
                    [SurveyAppDelegate showAlert:@"Your device doesn't support this functionality." withTitle:@"Unable To Email"];
            }
		}
        
	}
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL images = buttonIndex != alertView.cancelButtonIndex;
    
    NSString *result = [CustomerUtilities backupDatabases:images withSuppress:NO appDelegate:del];
    [self complete:result];
    
    //reload list...
    //BackupThread *thread = [[BackupThread alloc] init];
    //thread.withImages = images;
    //thread.caller = self;
    //thread.callback = @selector(complete:);
    //thread.goForUpdate = @selector(goForUpdate);
    //[del.operationQueue addOperation:thread];

}


#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultFailed)
        [SurveyAppDelegate showAlert:@"Send Failed, unable to send email." withTitle:@"Unable To Email"];
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)goForUpdate
{
    progressView = [[SmallProgressView alloc] initWithDefaultFrame:@"Backing Up Databases"];
}

-(void)complete:(NSString*)message
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    bool success = message == nil;
    [progressView removeFromSuperview];
    
    [SurveyAppDelegate showAlert:success ? @"Successfully backed up databases." : message withTitle:success ? @"Success!" : @"Error"];
    
    //reload list...
    self.backupFolders = [del.surveyDB getAllBackups];
    [self.tableView reloadData];
}

@end

