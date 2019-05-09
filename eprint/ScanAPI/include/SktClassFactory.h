//
//  SktClassFactory.h
//  ScanApi
//
//  Created by Jimmy Yang on 11-1-26.
//  Copyright 2011 SocketMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISktScanApi.h"
#import "ISktScanDevice.h"

@interface SktClassFactory : NSObject {

}
+ (id<ISktScanObject>) createScanObject;
+(void)releaseScanObject: (id<ISktScanObject>)scanObj;

+ (id <ISktScanApi>) createScanApiInstance;
+(void)releaseScanApiInstance: (id<ISktScanApi>) scanApi;

+ (id<ISktScanDevice>) createDeviceInstance: (id<ISktScanApi>) scanApi;
+(void)releaseDeviceInstance:(id<ISktScanDevice>)deviceInstance; 
@end
