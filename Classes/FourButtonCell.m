//
//  FourButtonCell.m
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FourButtonCell.h"
#import "SurveyAppDelegate.h"

@implementation FourButtonCell

@synthesize cmd1, cmd2, cmd3, cmd4;
@synthesize imageButtons;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        imageButtons = YES;
    }
    return self;
}

-(void)setButtonReciever:(id)receiver withSelector:(SEL)sel
{
    [cmd1 addTarget:receiver action:sel forControlEvents:UIControlEventTouchUpInside];
    [cmd2 addTarget:receiver action:sel forControlEvents:UIControlEventTouchUpInside];
    [cmd3 addTarget:receiver action:sel forControlEvents:UIControlEventTouchUpInside];
    [cmd4 addTarget:receiver action:sel forControlEvents:UIControlEventTouchUpInside];
}

-(void)setNormalImages:(UIImage*)img
{
    if (imageButtons)
    {
        [cmd1 setBackgroundImage:img forState:UIControlStateNormal];
        [cmd2 setBackgroundImage:img forState:UIControlStateNormal];
        [cmd3 setBackgroundImage:img forState:UIControlStateNormal];
        [cmd4 setBackgroundImage:img forState:UIControlStateNormal];
    }
}

-(void)setNormalColor:(UIColor*)color
{
    imageButtons = NO;
    
    [cmd1.layer setBorderColor:color.CGColor];
    [cmd2.layer setBorderColor:color.CGColor];
    [cmd3.layer setBorderColor:color.CGColor];
    [cmd4.layer setBorderColor:color.CGColor];
    [cmd1.layer setBackgroundColor:color.CGColor];
    [cmd2.layer setBackgroundColor:color.CGColor];
    [cmd3.layer setBackgroundColor:color.CGColor];
    [cmd4.layer setBackgroundColor:color.CGColor];
//    [cmd1 setTitleColor:color forState:UIControlStateNormal];
//    [cmd2 setTitleColor:color forState:UIControlStateNormal];
//    [cmd3 setTitleColor:color forState:UIControlStateNormal];
//    [cmd4 setTitleColor:color forState:UIControlStateNormal];
    
    [self setNormalImages:nil];
    [self setHighlightedImages:nil];
}

-(void)setHighlightedImages:(UIImage*)img
{
    if (imageButtons)
    {
        [cmd1 setBackgroundImage:img forState:UIControlStateHighlighted];
        [cmd2 setBackgroundImage:img forState:UIControlStateHighlighted];
        [cmd3 setBackgroundImage:img forState:UIControlStateHighlighted];
        [cmd4 setBackgroundImage:img forState:UIControlStateHighlighted];
    }
}

-(void)setButtonBackgroundColor:(UIColor*)color
{
    [cmd1 setBackgroundColor:color];
    [cmd2 setBackgroundColor:color];
    [cmd3 setBackgroundColor:color];
    [cmd4 setBackgroundColor:color];
    if (!imageButtons)
    {
        [cmd1.layer setBackgroundColor:cmd1.layer.borderColor];
        [cmd2.layer setBackgroundColor:cmd2.layer.borderColor];
        [cmd3.layer setBackgroundColor:cmd3.layer.borderColor];
        [cmd4.layer setBackgroundColor:cmd4.layer.borderColor];
    }
}

//-(void)setupDualViewCmd1:(NSString*)topText withSubText:(NSString*)bottomText
//{
//    [self setupDualView:cmd1 withTopText:topText andSubText:bottomText];
//}
//-(void)setupDualViewCmd2:(NSString*)topText withSubText:(NSString*)bottomText
//{
//    [self setupDualView:cmd2 withTopText:topText andSubText:bottomText];
//}
//-(void)setupDualViewCmd3:(NSString*)topText withSubText:(NSString*)bottomText
//{
//    [self setupDualView:cmd3 withTopText:topText andSubText:bottomText];
//}
//-(void)setupDualViewCmd4:(NSString*)topText withSubText:(NSString*)bottomText
//{
//    [self setupDualView:cmd4 withTopText:topText andSubText:bottomText];
//}

-(void)setupDualView:(int)buttonTag withTopText:(NSString*)topText andSubText:(NSString*)bottomText
{
    UIButton *cmd = nil;
    
    switch (buttonTag) {
        case 1:
            cmd = cmd1;
            break;
        case 2:
            cmd = cmd2;
            break;
        case 3:
            cmd = cmd3;
            break;
        case 4:
            cmd = cmd4;
            break;
    }
    
    cmd.hidden = ((topText == nil || [topText isEqualToString:@""]) && (bottomText == nil || [bottomText isEqualToString:@""]));
    
    int padding = 3;
    UILabel *topLabel = (UILabel*)[self viewWithTag:FOUR_BUTTON_TOP_LABEL + (buttonTag * 10)];
    CGSize size = cmd.bounds.size;
    int width = [SurveyAppDelegate iPad] ? size.width * 2.4 : size.width; // cmd.bounds.size is pulling from the interface builder predefined size, as this method is being called from cellForRowAt.  Need to multiply the width by a factor of 2.4 for larger screen sizes to accommodate.  An ideal solution is probably to add text labels to the buttons themselves.
    if(topLabel == nil)
    {
        topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                             padding, 
                                                             width,
                                                             (size.height - (padding * 2)) / 2.0)];

        if (imageButtons)
            topLabel.textColor = [UIColor blackColor];
        else
            topLabel.textColor = [UIColor whiteColor];
        topLabel.backgroundColor = [UIColor clearColor];
        topLabel.textAlignment = NSTextAlignmentCenter;
        topLabel.tag = FOUR_BUTTON_TOP_LABEL + (buttonTag * 10);
        [cmd addSubview:topLabel];
    }
    topLabel.text = topText;
    
    UILabel *bottomLabel = (UILabel*)[self viewWithTag:FOUR_BUTTON_BOTTOM_LABEL + (buttonTag * 10)];
    if(bottomLabel == nil)
    {
        bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                (size.height - (padding * 2)) / 2.0,
                                                                width,
                                                                (size.height - (padding * 2)) / 2.0)];

        bottomLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 2];
        if (imageButtons)
            bottomLabel.textColor = [UIColor blackColor];
        else
            bottomLabel.textColor = [UIColor whiteColor];
        bottomLabel.backgroundColor = [UIColor clearColor];
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        bottomLabel.tag = FOUR_BUTTON_BOTTOM_LABEL + (buttonTag * 10);
        [cmd addSubview:bottomLabel];
    }
    bottomLabel.text = bottomText;
    
    if (!imageButtons)
    {
        [cmd.layer setCornerRadius:4.f];
        [cmd.layer setBorderWidth:1.5f];
        [cmd addTarget:self action:@selector(highlightButton:) forControlEvents:UIControlEventTouchDown];
        [cmd addTarget:self action:@selector(unhighlightButton:) forControlEvents:UIControlEventTouchDragExit];
        [cmd addTarget:self action:@selector(unhighlightButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //[self bringSubviewToFront:￼
}

-(void)highlightButton:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    if (btn != nil)
        btn.alpha = 0.3f;
}

-(void)unhighlightButton:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    if (btn != nil)
        btn.alpha = 1.f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
