//
//  SBSDKGenericBarcode.h
//  QRCodes
//
//  Created by Constantine Fry on 16.05.17.
//  Copyright © 2017 Constantine Fry. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A generic bar code class.
 * An instance of this class is returned from SBSDKMachineReadableCodeManager when no matching parser
 * for this bar code has been found.
 */
@interface SBSDKGenericBarcode : SBSDKMachineReadableCode
@end
