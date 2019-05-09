//
//  BackupRecord.h
//  Survey
//
//  Created by Tony Brame on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@interface BackupRecord : NSObject
{
    int backupID;
    NSDate *backupDate;
    NSString *backupFolder;
}

@property (nonatomic) int backupID;
@property (nonatomic, retain) NSDate *backupDate;
@property (nonatomic, retain) NSString *backupFolder;

@end
