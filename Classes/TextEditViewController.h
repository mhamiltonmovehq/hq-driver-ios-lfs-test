//
//  TextEditViewController.h
//

@protocol TextEditViewDelegate < NSObject >

- (void)textEditViewDone:(NSString *)newText tag:(int)theTag;

@end

#import <UIKit/UIKit.h>

@class Jobs;

@interface TextEditViewController : UIViewController  < UITextViewDelegate > 
{    
    BOOL keyboardVisible;
}

@property (nonatomic, retain) IBOutlet UITextView *theTextView;
@property (nonatomic, retain) IBOutlet UIView *accessoryView;

@property (nonatomic, retain) NSString *viewTitle;
@property (nonatomic, retain) NSString *viewSubtitle;
@property (nonatomic, retain) NSString *theText;
@property (nonatomic, assign) id < TextEditViewDelegate > delegate;
@property (nonatomic) int viewTag;

@end
