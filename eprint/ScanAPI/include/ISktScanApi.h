//
//  ISktScanApi.h
//  ScanApi
//
//  Created by Jimmy Yang on 11-1-27.
//  Copyright 2011 SocketMobile. All rights reserved.
//
#import "ISktScanObject.h"

@protocol ISktScanApi <ISktScanDevice>
-(SKTRESULT) waitForScanObject: (id<ISktScanObject>) scanObj TimeOut: (unsigned long) ulTimeOut ;
-(SKTRESULT) releaseScanObject: (id<ISktScanObject>) scanObj;
@end

@protocol ScanAPIObjectDelegate
    -(id)startController;
@end


