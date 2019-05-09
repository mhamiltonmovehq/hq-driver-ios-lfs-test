//
//  FourButtonCell.h
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FOUR_BUTTON_TOP_LABEL 100
#define FOUR_BUTTON_BOTTOM_LABEL 200

@interface FourButtonCell : UITableViewCell {
    IBOutlet UIButton *cmd1;
    IBOutlet UIButton *cmd2;
    IBOutlet UIButton *cmd3;
    IBOutlet UIButton *cmd4;
}

@property (nonatomic, retain) UIButton *cmd1;
@property (nonatomic, retain) UIButton *cmd2;
@property (nonatomic, retain) UIButton *cmd3;
@property (nonatomic, retain) UIButton *cmd4;
@property (nonatomic) BOOL imageButtons;

-(void)setButtonReciever:(id)receiver withSelector:(SEL)sel;
-(void)setNormalImages:(UIImage*)img;
-(void)setNormalColor:(UIColor*)color;
-(void)setHighlightedImages:(UIImage*)img;

-(void)setupDualView:(int)buttonTag withTopText:(NSString*)topText andSubText:(NSString*)bottomText;

-(void)setButtonBackgroundColor:(UIColor*)color;

@end
