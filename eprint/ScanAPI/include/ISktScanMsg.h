//
//  ISktScanMsg.h
//  ScanApi
//
//  Created by Jimmy Yang on 11-1-26.
//  Copyright 2011 SocketMobile. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "SktScanTypes.h"
#import "ISktScanEvent.h"
@protocol ISktScanDevice;
@protocol ISktScanMsg

-(enum ESktScanMsgID) MsgID;
-(SKTRESULT) Result;
-(NSString*) DeviceName;
-(id<ISktScanDevice>) hDevice;
-(uint32_t) DeviceType;
-(NSString*) DeviceGuid;
-(id<ISktScanEvent>) Event;

@end

