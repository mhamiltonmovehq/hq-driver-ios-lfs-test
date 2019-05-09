//
//  LineaDummyDelegate.h
//  Survey
//
//  Created by Tony Brame on 4/24/13.
//
//

#import <Foundation/Foundation.h>

#define Printer DT_Printer
#import "DTDevices.h"
#undef Printer

@interface LineaDummyDelegate : NSObject <DTDeviceDelegate>

@end
