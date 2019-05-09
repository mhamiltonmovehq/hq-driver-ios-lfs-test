//
//  SBSDKWebURLQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code containing http or https links.
 */
@interface SBSDKWebURLQRCode : SBSDKMachineReadableCode

/**
 * The URL to the web link.
 */
@property(nonatomic, strong) NSURL *webURL;

@end
