//
//  SignatureViewController.h
//  Survey
//
//  Created by Tony Brame on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignatureView.h"
#import "SingleFieldController.h"

#define AGENT_SIG_FILE @"MMAgentSignature.png"
#define CUST_SIG_FILE @"MMCustomerSignature.png"


#define SIGNATURE_AGENT 0
#define SIGNATURE_CUSTOMER 1


//creating a delegate for ipad to know when sig is completed
@class SignatureViewController;
@protocol SignatureViewControllerDelegate <NSObject>
@optional
-(void)signatureApplied:(SignatureViewController*)sigController;
-(UIImage*)signatureViewImage:(SignatureViewController*)sigController;
-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature;
-(void)signatureView:(SignatureViewController*)sigController confirmedSignature:(UIImage*)signature withPrintedName:(NSString*)printedName;
-(NSString*)signatureViewPrintedName:(SignatureViewController*)sigController;
-(NSString*)signatureViewTextForDisplay:(SignatureViewController*)sigController;
@end



@interface SignatureViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate> {
    IBOutlet SignatureView *sigView;
    int sigType;
    BOOL confirmedSignature;
    id<SignatureViewControllerDelegate> delegate;
    int tag;
    BOOL requireSignatureBeforeSave;
    
    SingleFieldController *singleFieldController;
}

@property (nonatomic) int sigType;
@property (nonatomic) int tag;
@property (nonatomic) BOOL confirmedSignature;
@property (nonatomic) BOOL requireSignatureBeforeSave;
@property (nonatomic) BOOL saveBeforeDismiss;
@property (nonatomic) BOOL signatureRemoved;

@property (nonatomic, strong) SignatureView *sigView;
@property (nonatomic, strong) id<SignatureViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UILabel *labelDisplayText;

@property (nonatomic, strong) SingleFieldController *singleFieldController;


-(IBAction)done:(id)sender;

@end
