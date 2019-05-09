//
//  DummyReceiver.m
//  Survey
//
//  Created by Tony Brame on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocketDummyReceiver.h"
#import "SurveyAppDelegate.h"
#import "ScanAPI.h"

@implementation SocketDummyReceiver


#pragma mark - Socket Scanner delegate methods

-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = TRUE;
}

-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    del.socketConnected = FALSE;
}

-(void) onError:(SKTRESULT) result{
    
}
-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(id<ISktScanDecodedData>) decodedData {
    
}

-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    if(SKTSUCCESS(result)) {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        [del.socketScanAPI postSetSoftScanStatus:kSktScanSoftScanNotSupported Target:nil Response:nil];
    }
}

-(void) onScanApiTerminated{
    
}

-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    
}

@end
