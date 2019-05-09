//
//  SplashViewController.h
//  Survey
//
//  Created by Tony Brame on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activation.h"
#import "SurveyDBUpdater.h"

@interface SplashViewController : UIViewController <SurveyDBUpdaterDelegate> {
    NSTimer *timer;
    int allow;
    NSString *resultString;
    BOOL firstTimer;
    
    IBOutlet UILabel *labelLoad;
    IBOutlet UIButton *cmdSplashPhoto;
    IBOutlet UIProgressView *progress;
    
    BOOL dbUpdateComplete;
    BOOL timerDone;
}

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *resultString;
@property (nonatomic, strong) UILabel *labelLoad;
@property (nonatomic, strong) UIButton *cmdSplashPhoto;
@property (nonatomic, strong) UIProgressView *progress;

-(IBAction)splashPhotoClicked:(id)sender;
-(void)tick: (NSTimer*)theTimer;

@end
