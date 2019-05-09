//
//  AutoBackupSchedule.h
//  Survey
//
//  Created by Tony Brame on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@interface AutoBackupSchedule : NSObject
{//LastBackup, BackupFrequency, NumBackupsToRetain
    NSDate *lastBackup;
    double backupFrequency;
    int numBackupsToRetain;
    BOOL backupEnabled;
}

@property (nonatomic) double backupFrequency;
@property (nonatomic) int numBackupsToRetain;
@property (nonatomic) BOOL enableBackup;
@property (nonatomic) BOOL includeImages;

@property (nonatomic, strong) NSDate *lastBackup;

@end
