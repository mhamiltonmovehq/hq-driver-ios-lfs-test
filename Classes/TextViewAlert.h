//
//  TextViewAlert.h
//  Survey
//
//  Created by Tony Brame on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TextViewAlert;
@protocol TextViewAlertDelegate <NSObject>
@optional
-(void)textViewAlert:(TextViewAlert*)alert dismissedWithText:(NSString*)text;
@end

@interface TextViewAlert : NSObject <UIAlertViewDelegate>
{
    NSString *alertText;
    BOOL textRequired;
    id<TextViewAlertDelegate> delegate;
    
    UITextView *tbox;
}

@property (nonatomic, strong) NSString *alertText;
@property (nonatomic, strong) id<TextViewAlertDelegate> delegate;
@property (nonatomic) BOOL textRequired;

-(id)initWithTitle:(NSString*)title requireText:(BOOL)require;
-(id)initWithTitle:(NSString*)title requireText:(BOOL)require existingText:(NSString*)text;
-(void)showAlertView;

@end
