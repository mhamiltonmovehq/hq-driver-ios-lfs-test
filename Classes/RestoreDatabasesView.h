//
//  PVOUploadReportView.h
//  Survey
//
//  Created by Tony Brame on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SurveyDBUpdater.h"

@class PVOSync;
@class RootViewController;

#define RESTORE_TEMP_FOLDER @"/tempfolder"
#define RESTORE_TEMP_FILE @"temp.zip"

@interface RestoreDatabasesView : NSObject <UIAlertViewDelegate, SurveyDBUpdaterDelegate>
{
    RootViewController *rootController;
    UIView *viewLoading;
    UILabel *labelStatus;
    
    NSURL *file;
    
    SurveyDBUpdater *updater;
    BOOL isRestoreFromBackupFolder;
    NSObject *caller;
    SEL callback;
}

@property (nonatomic, strong) RootViewController *rootController;
@property (nonatomic, strong) UIView *viewLoading;
@property (nonatomic, strong) UILabel *labelStatus;
@property (nonatomic, strong) NSURL *file;

@property (nonatomic, strong) SurveyDBUpdater *updater;
@property (nonatomic) BOOL isRestoreFromBackupFolder;
@property (nonatomic, strong) NSObject *caller;
@property (nonatomic) SEL callback;

-(void)restoreDatabases:(NSURL*)fileLocation;

-(void)exit;

@end
