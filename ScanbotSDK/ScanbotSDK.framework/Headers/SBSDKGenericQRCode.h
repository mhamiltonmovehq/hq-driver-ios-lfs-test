//
//  SBSDKGenericQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 21.09.17.
//  Copyright © 2017 doo GmbH. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A generic QR code class.
 * An instance of this class is returned from SBSDKMachineReadableCodeManager when no matching parser
 * for this QR code has been found.
 */
@interface SBSDKGenericQRCode : SBSDKMachineReadableCode
@end
