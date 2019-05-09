//
//  SBSDKUIMachineCodesCollection.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 5/16/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 * Factory class for machine readable code types.
 */
@interface SBSDKUIMachineCodesCollection : NSObject

/**
 * All machine readable code types for barcodes.
 * @return An array of barcode types.
 */
+ (NSArray<AVMetadataObjectType> *)oneDimensionalBarcodes;

/**
 * All machine readable code types for QR codes.
 * @return An array of QR code types.
 */
+ (NSArray<AVMetadataObjectType> *)twoDimensionalBarcodes;

@end
