//
//  SurveyDBUpdater.h
//  Survey
//
//  Created by Lee Zumstein on 1/16/14.
//
//

#import <Foundation/Foundation.h>

@class SurveyDB;
@class SurveyDBUpdater;

@protocol SurveyDBUpdaterDelegate <NSObject>
@optional
-(void)SurveyDBUpdaterError:(NSString*)error;
-(void)SurveyDBUpdaterCompleted:(SurveyDBUpdater*)updater;
-(void)SurveyDBUpdaterUpdateProgress:(NSNumber*)progress;
-(void)SurveyDBUpdaterStartProgress:(NSString*)progressLabel;
-(void)SurveyDBUpdaterEndProgress:(SurveyDBUpdater*)updater;
@end


@interface SurveyDBUpdater : NSOperation
{
    SurveyDB *db;
    NSObject<SurveyDBUpdaterDelegate> *delegate;
    BOOL success;
}

@property (nonatomic, strong) SurveyDB *db;
@property (nonatomic, strong) NSObject<SurveyDBUpdaterDelegate> *delegate;
@property (nonatomic) BOOL success;

+(NSString*)createBackupsSQL;
+(NSString*)createAutoBackupScheduleSQL;
+(NSString*)createAutoBackupScheduleDefaults;

-(void)flushCommandsFromFile:(NSString*)filename withProgressHeader:(NSString*)progressHeader;
-(void)flushCommandsFromArray:(NSArray*)commands withProgressHeader:(NSString*)progressHeader;

-(void)error:(NSString*)description;
-(void)completed;
-(void)updateProgress:(float)progress;
-(void)startProgress:(NSString*)progressLabel;
-(void)endProgress;

@end
