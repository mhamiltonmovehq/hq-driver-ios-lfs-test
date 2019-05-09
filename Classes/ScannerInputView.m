//
//  ScannerInputView.m
//  Survey
//
//  Created by Tony Brame on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScannerInputView.h"
#import "SurveyAppDelegate.h"

@implementation ScannerInputView

@synthesize viewLoading;
@synthesize activity, delegate;
@synthesize labelStatus, tag;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        
        CGRect viewFrame = appwindow.frame;
        
        viewLoading = [[UIView alloc] initWithFrame:appwindow.frame];
        viewLoading.backgroundColor = [UIColor blackColor];
        viewLoading.alpha = .75;
        
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGSize activitysize = activity.frame.size;
        activity.frame = CGRectMake(20, (viewFrame.size.height / 2) - (activitysize.height / 2), 
                                    activitysize.width, activitysize.height);
        [activity startAnimating];
        [viewLoading addSubview:activity];
        
        CGSize textSize = [@"Waiting For Scan" sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}];
        labelStatus = [[UILabel alloc] initWithFrame:
                       CGRectMake(30 + activitysize.width, (viewFrame.size.height / 2) - (textSize.height / 2), 
                                  300, textSize.height)];
        labelStatus.font = [UIFont systemFontOfSize:22];
        labelStatus.text = @"Waiting For Scan";
        labelStatus.textColor = [UIColor whiteColor];
        labelStatus.backgroundColor = [UIColor clearColor];
        [viewLoading addSubview:labelStatus];
        
        UIButton *cmdCancel = [[UIButton alloc] initWithFrame:
                               CGRectMake(50, viewFrame.size.height - 100, 220, 44)];
        [cmdCancel setBackgroundImage:[[UIImage imageNamed:@"whiteButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.]
                        forState:UIControlStateNormal];
        [cmdCancel setBackgroundImage:[[UIImage imageNamed:@"blueButton.png"] stretchableImageWithLeftCapWidth:12. topCapHeight:0.]
                             forState:UIControlStateHighlighted];
        [cmdCancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [cmdCancel addTarget:self action:@selector(cmdCancel_Click:) forControlEvents:UIControlEventTouchUpInside];
        [viewLoading addSubview:cmdCancel];
        
    }
    
    return self;
}

-(IBAction)cmdCancel_Click:(id)sender
{
    [viewLoading removeFromSuperview];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del setCurrentSocketListener:nil];
    [del.linea removeDelegate:self];
}

-(void)waitForInput
{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [del setCurrentSocketListener:self];
    [del.linea addDelegate:self];
    
    BOOL canUseCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if(!del.socketConnected && [del.linea connstate] != CONN_CONNECTED &&
       !canUseCamera)
    {
        [SurveyAppDelegate showAlert:@"Please Connect Scanner." withTitle:@"Not Connected"];
        return;
    }
    
    if(!del.socketConnected && [del.linea connstate] != CONN_CONNECTED &&
       canUseCamera)
    {
        //use the camera...
        if(zbar == nil)
            zbar = [ZBarReaderViewController new];
        zbar.readerDelegate = self;
        [del.window.rootViewController presentViewController:zbar animated:YES completion:nil];
        //grabbingBarcodeImage = YES;
    }
    else
    {
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        [appwindow addSubview:viewLoading];
        [appwindow bringSubviewToFront:viewLoading];
    }
}



#pragma mark - Socket Scanner delegate methods

-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo{
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = TRUE;
}

-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = FALSE;
    [SurveyAppDelegate showAlert:@"Scanner disconnected.  Please Connect Scanner." withTitle:@"Not Connected"];
    [self cmdCancel_Click:nil];
}

-(void) onError:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"ScanAPI is reporting an error: %d",result] withTitle:@"Scanner Error"];
}

-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(id<ISktScanDecodedData>) decodedData{
    
    NSString *data = [[NSString stringWithUTF8String:(const char *)[decodedData getData]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(delegate != nil && [delegate respondsToSelector:@selector(scannerInput:withValue:)])
    {
        [delegate scannerInput:self withValue:data];
    }
    
    [self cmdCancel_Click:nil];
    
}

-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(!SKTSUCCESS(result))
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error initializing ScanAPI: %d",result] withTitle:@"Scanner Error"];
    } else {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving ScanObject:%d",result] withTitle:@"Scanner Error"];
}


#pragma mark - LineaDelegate methods

-(void)connectionState:(int)state {
    
    [SurveyAppDelegate showAlert:@"Scanner disconnected.  Please Connect Scanner." withTitle:@"Not Connected"];
    [self cmdCancel_Click:nil];

}

-(void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
    [self barcodeData:barcode type:-1];//dont care about type...
}

-(void)barcodeData:(NSString *)barcode type:(int)type 
{
    
    NSString *data = barcode;
    
    if(delegate != nil && [delegate respondsToSelector:@selector(scannerInput:withValue:)])
    {
        [delegate scannerInput:self withValue:data];
    }
    
    [self cmdCancel_Click:nil];
    
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    NSString *barcode = nil;
    for(ZBarSymbol *symbol in results)
    {
        if(barcode != nil)
            barcode = nil;
        else
            barcode = [NSString stringWithString:symbol.data];
        
    }
    
    [delegate scannerInput:self withValue:barcode];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    zbar = nil;
}

@end
