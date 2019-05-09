//
//  ScannerInputView.h
//  Survey
//
//  Created by Tony Brame on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScanApiHelper.h"
#import "DTDevices.h"
#import "ZBarSDK.h"

@class ScannerInputView;
@protocol ScannerInputViewDelegate <NSObject>
@optional
-(void)scannerInput:(ScannerInputView*)scannerView withValue:(NSString*)scannerValue;
@end

@interface ScannerInputView : NSObject <ScanApiHelperDelegate, DTDeviceDelegate, ZBarReaderDelegate>
{
    UIView *viewLoading;
    UIActivityIndicatorView *activity;
    UILabel *labelStatus;
    id<ScannerInputViewDelegate> delegate;
    ZBarReaderViewController *zbar;
    
    int tag;
}

@property (nonatomic) int tag;

@property (nonatomic, strong) UIView *viewLoading;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UILabel *labelStatus;
@property (nonatomic, strong) id<ScannerInputViewDelegate> delegate;

-(void)waitForInput;
-(IBAction)cmdCancel_Click:(id)sender;

@end
