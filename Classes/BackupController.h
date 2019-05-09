//
//  BackupController.h
//  Survey
//
//  Created by Tony Brame on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "AutoBackupSettingsController.h"
#import "RestoreDatabasesView.h"
#import "SmallProgressView.h"

#define BACKUP_ACTION_OPTIONS 1234

@interface BackupThread : NSOperation{
    id caller;
    SEL callback;
    SEL goForUpdate;
    BOOL withImages;
}
@property (nonatomic) SEL callback;
@property (nonatomic) SEL goForUpdate;
@property (nonatomic, retain) id caller;
@property (nonatomic) BOOL withImages;
@end

@interface BackupController : UITableViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
	NSArray *backupFolders;
	NSIndexPath *editingPath;
    AutoBackupSettingsController *settingsController;
	NSDateFormatter *formatter;
    SmallProgressView *progressView;

}

@property (nonatomic, retain) NSArray *backupFolders;
@property (nonatomic, retain) NSIndexPath *editingPath;
@property (nonatomic, retain) AutoBackupSettingsController *settingsController;
@property (nonatomic, retain) RestoreDatabasesView *restoreDBView;

-(IBAction)done:(id)sender;
//-(IBAction)backup:(id)sender;

@end
