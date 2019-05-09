//
//  SmallProgressView.m
//  Survey
//
//  Created by Tony Brame on 1/29/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "SmallProgressView.h"
#import "SurveyAppDelegate.h"


@implementation SmallProgressView

@synthesize activityView, progressBar;

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame withWaitLabel:@""];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithDefaultFrame:(NSString*)waitLabel
{
    self = [self initWithDefaultFrame:waitLabel andProgressBar:NO];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithDefaultFrame:(NSString*)waitLabel andProgressBar:(BOOL)showProgressBar
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = del.window;
    float y = (window.bounds.size.height - self.bounds.size.height)/2;
    
    self = [self initWithFrame:CGRectMake(0, y, 320, 120) withWaitLabel:waitLabel andProgressBar:showProgressBar];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame withWaitLabel:(NSString*)waitLabel
{
    self = [self initWithFrame:frame withWaitLabel:waitLabel andProgressBar:NO];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame withWaitLabel:(NSString*)waitLabel andProgressBar:(BOOL)showProgressBar
{
    BOOL upsideDown = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown);
    UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
    self = [super initWithFrame:appwindow.frame];
    if (self) {
        // Initialization code
        //make this a clear view for entire screen, and add bottom black view for progress...  this way user interaction is blocked...
        self.backgroundColor = [UIColor clearColor];
        
        if (upsideDown)
            frame = CGRectMake(0, 0, frame.size.width, frame.size.height); //place at top, since we'll be flipping 180
        
        UIView *progressView = [[UIView alloc] initWithFrame:frame];
        progressView.backgroundColor = [UIColor blackColor];
        progressView.alpha = .75;
        if (upsideDown)
            progressView.transform = CGAffineTransformMakeRotation((180 +
                                                                    (atan2f(progressView.transform.b, progressView.transform.a) *
                                                                     (180 / M_PI)))
                                                                   * M_PI/180); //flip-er 180
        progressView.layer.cornerRadius = 10;
        
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGSize activitysize = activityView.frame.size;
        activityView.frame = CGRectMake(20, (frame.size.height / 2) - (activitysize.height / 2),
                                    activitysize.width, activitysize.height);
        [activityView startAnimating];
        [progressView addSubview:activityView];
        
        CGSize textSize = [waitLabel sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}];
        UILabel *labelStatus = [[UILabel alloc] initWithFrame:
                       CGRectMake(30 + activitysize.width, (frame.size.height / 2) - (textSize.height / 2),
                                  300, textSize.height)];
        labelStatus.font = [UIFont systemFontOfSize:22];
        labelStatus.text = waitLabel;
        labelStatus.textColor = [UIColor whiteColor];
        labelStatus.backgroundColor = [UIColor clearColor];
        [progressView addSubview:labelStatus];
        
        if (showProgressBar)
        {
            progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            [progressBar setFrame:CGRectMake(10, frame.size.height - progressBar.frame.size.height - 25,
                                             frame.size.width - 20, progressBar.frame.size.height)];
            [progressView addSubview:progressBar];
            [progressBar setHidden:YES];
        }
        
        [self addSubview:progressView];
        
        [appwindow addSubview:self];
        [appwindow bringSubviewToFront:self];
    }
    return self;
}

-(void)updateProgressBar:(double)percent
{
    [self updateProgressBar:percent animated:NO];
}

-(void)updateProgressBar:(double)percent animated:(BOOL)animated
{
    if (progressBar != nil)
    {
        if (percent < 0) percent = 0;
        if (percent > 1) percent = 1;
        if ([progressBar isHidden])
            [progressBar setHidden:NO];
        [progressBar setProgress:percent animated:animated];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
