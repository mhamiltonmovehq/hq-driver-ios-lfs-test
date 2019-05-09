//
//  ISktScanDevice.h
//  ScanApi
//
//  Created by Jimmy Yang on 11-1-30.
//  Copyright 2011 SocketMobile. All rights reserved.
//
#include "SktScanTypes.h"
#import "ISktScanObject.h"

@protocol ISktScanDevice
-(SKTRESULT) open: (NSString*) devicename;
-(SKTRESULT) close;
-(SKTRESULT) getProperty: (id<ISktScanObject>) pScanObj;
-(SKTRESULT) setProperty: (id<ISktScanObject>) pScanObj;

@end
