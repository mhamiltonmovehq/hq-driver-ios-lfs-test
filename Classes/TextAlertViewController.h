//
//  TextAlertViewController.h
//  Survey
//
//  Created by Tony Brame on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextAlertViewController;
@protocol TextAlertViewControllerDelegate <NSObject>
@optional
-(void)textAlertWillDismiss:(TextAlertViewController*)controller;
@end

@interface TextAlertViewController : UIViewController
{
    IBOutlet UITextView *tboxContent;
    IBOutlet UINavigationItem *titleText;
    id<TextAlertViewControllerDelegate> delegate;
}

@property (nonatomic, retain) UITextView *tboxContent;
@property (nonatomic, retain) UINavigationItem *titleText;
@property (nonatomic, retain) id<TextAlertViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *textToView;

-(IBAction)cmdDoneClick:(id)sender;

+(id)textViewWithText:(NSString*)textToView andTitle:(NSString*)title;

@end
