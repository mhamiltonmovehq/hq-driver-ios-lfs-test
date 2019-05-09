//
//  SBSDKUIMachineCodeScannerBehaviorConfiguration.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 5/16/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSDKOrientationLock.h"

/**
 * Subconfiguration for the behavior of  bar codes, QR codes
 * and machine readable zones scanners.
 */
@interface SBSDKUIMachineCodeScannerBehaviorConfiguration : NSObject

/** Whether flash is toggled on or off. */
@property (nonatomic, assign, getter=isFlashEnabled) BOOL flashEnabled;

/** Whether scanner screen should make a sound on successful barcode or MRZ detection. */
@property (nonatomic, assign, getter=isSuccessBeepEnabled) BOOL successBeepEnabled;

@end
