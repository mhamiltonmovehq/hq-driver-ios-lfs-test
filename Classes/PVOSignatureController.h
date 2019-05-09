//
//  PVOSignatureController.h
//  Survey
//
//  Created by Tony Brame on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

//creating a delegate for ipad to know when sig is completed
@class PVOSignatureController;
@protocol PVOSignatureControllerDelegate <NSObject>
@optional
-(void)signatureEntered:(PVOSignatureController*)sigController;
@end


@interface PVOSignatureController : UIViewController {
    id<PVOSignatureControllerDelegate> delegate;
    IBOutlet UITextView *tboxDescription;
    NSString *displayText;
}

@property (nonatomic, strong) id<PVOSignatureControllerDelegate> delegate;
@property (nonatomic, strong) UITextView *tboxDescription;

-(IBAction)continue_Click:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil displayText:(NSString*)display;

@end
