//
//  SBSDKShortMessageQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code contianing an SMS links (sms: and SMSTO:).
 */
@interface SBSDKShortMessageQRCode : SBSDKMachineReadableCode

/**
 * The receiver of the message. Might be a phone number or email address.
 */
@property(nonatomic, copy) NSArray<NSString *> *recipients;

/**
 * The body of the message. Might be nil or empty.
 */
@property(nonatomic, copy) NSString *body;

@end
