//
//  SmallProgressView.h
//  Survey
//
//  Created by Tony Brame on 1/29/13.
//
//

#import <UIKit/UIKit.h>

@interface SmallProgressView : UIView

@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, retain) UIProgressView *progressBar;

- (id)initWithDefaultFrame:(NSString*)waitLabel;
- (id)initWithDefaultFrame:(NSString*)waitLabel andProgressBar:(BOOL)showProgressBar;
- (id)initWithFrame:(CGRect)frame withWaitLabel:(NSString*)waitLabel;
- (id)initWithFrame:(CGRect)frame withWaitLabel:(NSString*)waitLabel andProgressBar:(BOOL)showProgressBar;

-(void)updateProgressBar:(double)percent;
-(void)updateProgressBar:(double)percent animated:(BOOL)animated;

@end
