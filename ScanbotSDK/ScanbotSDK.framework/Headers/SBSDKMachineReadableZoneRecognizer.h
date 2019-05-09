//
//  SBSDKMRZRecognizer.h
//  ScanbotSDK
//
//  Created by Andrew Petrus on 28.09.16.
//  Copyright © 2016 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SBSDKMachineReadableZoneRecognizerResult.h"

/**
 * Wrapper class for machine-readable zones recognition. Recognition is performed on still UIImage
 * or SampleBufferRef, result is incapsulated in SBSDKMRZRecognizerResult instance.
 * NOTE: In order to operate, this class requires tesseract languages and trained data to be present
 * in application bundle
 */
@interface SBSDKMachineReadableZoneRecognizer : NSObject

/**
 * Acquire all available information from UIImage instance containing machine-readable zone.
 * @param image The image where machine-readable zone is to be detected.
 * @return Recognizer result.
 */
- (nonnull SBSDKMachineReadableZoneRecognizerResult *)recognizePersonalIdentityFromImage:(nonnull UIImage *)image;

/**
 * Acquire all available information from sample buffer reference containing machine-readable zone.
 * @param sampleBufferRef The sample buffer reference containing machine-readable zone.
 * @param videoOrientation Video frame orientation.
 * @param searchMachineReadableZone Set to YES to automatically search machine-readable zone in provided sample buffer reference.
 * Set to NO to manually provide the rectangle where machine-readable zone is present.
 * @param machineReadableZoneRect Rectangle in frame containing machine-readable zone. Used only when searchMachineReadableZone
 * is set to NO.
 * @return Recognizer result.
 */
- (nonnull SBSDKMachineReadableZoneRecognizerResult *)recognizePersonalIdentityFromSampleBuffer:(nonnull CMSampleBufferRef)sampleBufferRef
                                                                                    orientation:(AVCaptureVideoOrientation)videoOrientation
                                                                      searchMachineReadableZone:(BOOL)searchMachineReadableZone
                                                                        machineReadableZoneRect:(CGRect)machineReadableZoneRect;

@end
