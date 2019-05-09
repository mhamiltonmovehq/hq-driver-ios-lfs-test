//
//  SBSDKPhoneNumberQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code with call-a-number links (tel:).
 */
@interface SBSDKPhoneNumberQRCode : SBSDKMachineReadableCode

/** The phone number string. */
@property(nonatomic, copy) NSString *phoneNumber;

@end
