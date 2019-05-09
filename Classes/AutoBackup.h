//
//  AutoBackup.h
//  Survey
//
//  Created by Tony Brame on 1/29/13.
//
//

#import <Foundation/Foundation.h>
#import "SmallProgressView.h"

@class SurveyAppDelegate;

@interface AutoBackupThread : NSOperation{
    id caller;
    SEL callback;
    SEL goForUpdate;
}
@property (nonatomic) SEL callback;
@property (nonatomic) SEL goForUpdate;
@property (nonatomic, strong) id caller;
@property (nonatomic, weak) SurveyAppDelegate *appDelegate;

@end

@interface AutoBackup : NSObject
{
    SmallProgressView *progressView;
    AutoBackupThread *thread;
}

@property (nonatomic, strong) id caller;
@property (nonatomic) SEL finishedBackup;

-(void)beginBackup;
-(void)complete:(NSString*)message;

@end
