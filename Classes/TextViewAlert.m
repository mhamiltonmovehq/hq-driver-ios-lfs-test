//
//  TextViewAlert.m
//  Survey
//
//  Created by Tony Brame on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextViewAlert.h"
#import "SurveyAppDelegate.h"

@implementation TextViewAlert

@synthesize alertText;
@synthesize textRequired;
@synthesize delegate;


-(id)initWithTitle:(NSString*)title requireText:(BOOL)require
{
    self = [super init];
    if(self != nil)
    {
        self.alertText = title;
        textRequired = require;
        [self showAlertView];
    }
    
    return self;
}

-(id)initWithTitle:(NSString*)title requireText:(BOOL)require existingText:(NSString*)text
{
    self = [super init];
    if(self != nil)
    {
        self.alertText = title;
        textRequired = require;
        [self showAlertView];
        tbox.text = text;
    }
    
    return self;
}

-(void)showAlertView
{
    UIAlertView* dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:alertText];
    [dialog setMessage:@" \r\n \r\n "];
    [dialog addButtonWithTitle:@"OK"];
    dialog.delegate = self;
    tbox = [[UITextView alloc] initWithFrame:CGRectMake(20.0, 65.0, 245.0, 75.0)];
    [tbox setBackgroundColor:[UIColor whiteColor]];
    tbox.keyboardType = UIKeyboardTypeASCIICapable;
    [dialog addSubview:tbox];
    [dialog show];
    //[tbox becomeFirstResponder];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        if(textRequired && (tbox.text == nil || [tbox.text isEqualToString:@""]))
        {
            [tbox resignFirstResponder];
            [self showAlertView];
            [SurveyAppDelegate showAlert:@"Text is required in this field to continue." withTitle:@"Text Required"];
        }
        else 
        {
            if(delegate != nil && [delegate respondsToSelector:@selector(textViewAlert:dismissedWithText:)])
                [delegate textViewAlert:self dismissedWithText:tbox.text];
        }
    }
}

@end
