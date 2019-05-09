//
//  SBSDKMailMessageQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code
 * containing an email link (mailto: and smtp:).
 */
@interface SBSDKMailMessageQRCode : SBSDKMachineReadableCode

/**
 * An array of NSString instances containing the receivers email adresses.
 */
@property(nonatomic, strong) NSArray *recipients;

/**
 * The emails subject string.
 */
@property(nonatomic, copy) NSString *subject;

/**
 * The emails body string.
 */
@property(nonatomic, copy) NSString *body;

@end
